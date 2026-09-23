import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/recurrence.dart';
import '../../transactions/data/category_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_models.dart';

enum BillDueState { overdue, dueToday, dueSoon, upcoming, inactive }

class BillDraft {
  const BillDraft({
    required this.id,
    required this.name,
    required this.category,
    required this.amountMinor,
    required this.currencyCode,
    required this.nextDueDate,
    this.recurrence,
    this.remindDaysBefore = 2,
    this.remindAtMinutes = 9 * 60,
    this.remindersEnabled = true,
    this.accountId,
    this.note,
  });

  final String id;
  final String name;
  final BillCategory category;
  final int amountMinor;
  final String currencyCode;
  final LocalDate nextDueDate;
  final RecurrenceRule? recurrence;
  final int remindDaysBefore;
  final int remindAtMinutes;
  final bool remindersEnabled;
  final String? accountId;
  final String? note;
}

class BillView {
  const BillView(this.bill, this.lastPayment);

  final BillRow bill;
  final BillPaymentRow? lastPayment;

  RecurrenceRule? get rule => RecurrenceRule.decode(bill.recurrence);

  BillDueState state(LocalDate today) {
    if (!bill.isActive) return BillDueState.inactive;
    final days = today.daysUntil(bill.nextDueDate);
    if (days < 0) return BillDueState.overdue;
    if (days == 0) return BillDueState.dueToday;
    if (days <= 7) return BillDueState.dueSoon;
    return BillDueState.upcoming;
  }
}

/// How the payment should appear in the user's transactions.
sealed class PaymentRecording {
  const PaymentRecording();
}

/// Create a new expense (in the bills/rent category).
class RecordNewExpense extends PaymentRecording {
  const RecordNewExpense({
    required this.transactionId,
    required this.accountId,
  });

  final String transactionId;
  final String accountId;
}

/// Link an expense the user already recorded, avoiding a duplicate.
class LinkExistingExpense extends PaymentRecording {
  const LinkExistingExpense(this.transactionId);

  final String transactionId;
}

/// Only mark the bill as paid (e.g. loan instalments tracked in Loans).
class NoExpense extends PaymentRecording {
  const NoExpense();
}

class BillAlreadyPaidException implements Exception {
  const BillAlreadyPaidException();
}

class ExpenseAlreadyLinkedException implements Exception {
  const ExpenseAlreadyLinkedException();
}

class BillRepository {
  BillRepository(this._db, this._transactions, this._categories);

  final AppDatabase _db;
  final TransactionRepository _transactions;
  final CategoryRepository _categories;

  /// Loan instalments contain principal, which is not spending.
  static bool recordsAsExpenseByDefault(BillCategory c) =>
      c != BillCategory.loan;

  static String expenseCategoryKey(BillCategory c) =>
      c == BillCategory.rent ? 'rent' : 'bills';

  Future<List<BillView>> _views(List<BillRow> bills) async {
    if (bills.isEmpty) return const [];
    final payments =
        await (_db.select(_db.billPayments)
              ..where((p) => p.billId.isIn(bills.map((b) => b.id)))
              ..orderBy([(p) => OrderingTerm.desc(p.dueDate)]))
            .get();
    final last = <String, BillPaymentRow>{};
    for (final p in payments) {
      last.putIfAbsent(p.billId, () => p);
    }
    return [for (final b in bills) BillView(b, last[b.id])];
  }

  Stream<List<BillView>> watchAll() {
    final q = _db.select(_db.bills)
      ..orderBy([
        (b) => OrderingTerm.desc(b.isActive),
        (b) => OrderingTerm.asc(b.nextDueDate),
      ]);
    return q.watch().asyncMap(_views);
  }

  Future<List<BillView>> all() async {
    final q = _db.select(_db.bills)
      ..orderBy([(b) => OrderingTerm.asc(b.nextDueDate)]);
    return _views(await q.get());
  }

  Future<BillRow?> byId(String id) =>
      (_db.select(_db.bills)..where((b) => b.id.equals(id))).getSingleOrNull();

  Stream<BillRow?> watchById(String id) => (_db.select(
    _db.bills,
  )..where((b) => b.id.equals(id))).watchSingleOrNull();

  Stream<List<BillPaymentRow>> watchPayments(String billId) =>
      (_db.select(_db.billPayments)
            ..where((p) => p.billId.equals(billId))
            ..orderBy([(p) => OrderingTerm.desc(p.dueDate)]))
          .watch();

  Future<void> save(BillDraft d) async {
    final existing = await byId(d.id);
    final companion = BillsCompanion.insert(
      id: Value(d.id),
      name: d.name.trim(),
      category: d.category,
      amountMinor: d.amountMinor,
      currencyCode: Value(d.currencyCode),
      nextDueDate: d.nextDueDate,
      recurrence: Value(d.recurrence?.encode()),
      startDate: existing?.startDate ?? d.nextDueDate,
      remindDaysBefore: Value(d.remindDaysBefore),
      remindAtMinutes: Value(d.remindAtMinutes),
      remindersEnabled: Value(d.remindersEnabled),
      accountId: Value(d.accountId),
      note: Value((d.note?.trim().isEmpty ?? true) ? null : d.note!.trim()),
      updatedAt: Value(nowUtc()),
    );
    if (existing == null) {
      await _db.into(_db.bills).insert(companion);
    } else {
      // Changing the schedule restarts the series from the new due date.
      final restart =
          existing.recurrence != d.recurrence?.encode() ||
          existing.nextDueDate != d.nextDueDate;
      await (_db.update(_db.bills)..where((b) => b.id.equals(d.id))).write(
        companion.copyWith(
          createdAt: const Value.absent(),
          startDate: restart ? Value(d.nextDueDate) : const Value.absent(),
          isActive: const Value(true),
        ),
      );
    }
  }

  Future<void> delete(String id) =>
      (_db.delete(_db.bills)..where((b) => b.id.equals(id))).go();

  Future<void> setActive(String id, {required bool active}) =>
      (_db.update(_db.bills)..where((b) => b.id.equals(id))).write(
        BillsCompanion(isActive: Value(active), updatedAt: Value(nowUtc())),
      );

  /// Expenses that look like this bill's payment and are not linked to any
  /// other bill payment yet.
  Future<List<TransactionView>> duplicateCandidates({
    required int amountMinor,
    required LocalDate around,
  }) async {
    final candidates = await _transactions.findSimilarExpenses(
      amountMinor: amountMinor,
      around: around,
    );
    if (candidates.isEmpty) return const [];
    final linked =
        await (_db.select(_db.billPayments)..where(
              (p) =>
                  p.transactionId.isIn(candidates.map((c) => c.transaction.id)),
            ))
            .get();
    final linkedIds = linked.map((p) => p.transactionId).toSet();
    return candidates
        .where((c) => !linkedIds.contains(c.transaction.id))
        .toList();
  }

  /// Records a payment of the bill's current cycle ([dueDate]) and moves the
  /// bill to its next due date. Everything happens in one database
  /// transaction, and each cycle can be paid only once.
  Future<BillPaymentRow> recordPayment({
    required String paymentId,
    required String billId,
    required LocalDate dueDate,
    required DateTime paidAt,
    required int amountMinor,
    required PaymentRecording recording,
    String? note,
  }) {
    return _db.transaction(() async {
      final bill = await byId(billId);
      if (bill == null) throw StateError('Unknown bill $billId');
      final existing =
          await (_db.select(_db.billPayments)..where(
                (p) => p.billId.equals(billId) & p.dueDate.equalsValue(dueDate),
              ))
              .getSingleOrNull();
      if (existing != null) {
        if (existing.id == paymentId) return existing;
        throw const BillAlreadyPaidException();
      }

      String? linkedTransaction;
      switch (recording) {
        case RecordNewExpense(transactionId: final txId, :final accountId):
          final category = await _categories.bySystemKey(
            CategoryKind.expense,
            expenseCategoryKey(bill.category),
          );
          await _transactions.insertWithinTransaction(
            TransactionDraft(
              id: txId,
              type: TransactionType.expense,
              amountMinor: amountMinor,
              currencyCode: bill.currencyCode,
              accountId: accountId,
              categoryId: category?.id,
              occurredAt: paidAt,
              description: bill.name,
              note: note,
              source: TransactionSource.bill,
              sourceRefId: paymentId,
            ),
          );
          linkedTransaction = txId;
        case LinkExistingExpense(transactionId: final txId):
          final alreadyLinked = await (_db.select(
            _db.billPayments,
          )..where((p) => p.transactionId.equals(txId))).get();
          if (alreadyLinked.isNotEmpty) {
            throw const ExpenseAlreadyLinkedException();
          }
          linkedTransaction = txId;
        case NoExpense():
          linkedTransaction = null;
      }
      return _finish(
        bill,
        paymentId,
        dueDate,
        paidAt,
        amountMinor,
        linkedTransaction,
        note,
      );
    });
  }

  Future<BillPaymentRow> _finish(
    BillRow bill,
    String paymentId,
    LocalDate dueDate,
    DateTime paidAt,
    int amountMinor,
    String? transactionId,
    String? note,
  ) async {
    await _db
        .into(_db.billPayments)
        .insert(
          BillPaymentsCompanion.insert(
            id: Value(paymentId),
            billId: bill.id,
            dueDate: dueDate,
            paidAt: paidAt.toUtc(),
            amountMinor: amountMinor,
            transactionId: Value(transactionId),
            note: Value(note),
          ),
        );
    // Advance to the next unpaid cycle (only if the paid cycle is current).
    if (!bill.nextDueDate.isAfter(dueDate)) {
      final rule = RecurrenceRule.decode(bill.recurrence);
      final next = rule?.nextAfter(bill.startDate, dueDate);
      await (_db.update(_db.bills)..where((b) => b.id.equals(bill.id))).write(
        BillsCompanion(
          nextDueDate: next == null ? const Value.absent() : Value(next),
          isActive: Value(next != null),
          updatedAt: Value(nowUtc()),
        ),
      );
    }
    return (_db.select(
      _db.billPayments,
    )..where((p) => p.id.equals(paymentId))).getSingle();
  }

  /// Removes a payment and, when it was the latest one, makes that cycle due
  /// again. A linked expense is kept.
  Future<void> undoPayment(String paymentId) {
    return _db.transaction(() async {
      final payment = await (_db.select(
        _db.billPayments,
      )..where((p) => p.id.equals(paymentId))).getSingleOrNull();
      if (payment == null) return;
      final bill = await byId(payment.billId);
      await (_db.delete(
        _db.billPayments,
      )..where((p) => p.id.equals(paymentId))).go();
      if (bill == null) return;
      final later =
          await (_db.select(_db.billPayments)..where(
                (p) =>
                    p.billId.equals(bill.id) &
                    p.dueDate.isBiggerThanValue(payment.dueDate.toIso()),
              ))
              .get();
      if (later.isEmpty) {
        await (_db.update(_db.bills)..where((b) => b.id.equals(bill.id))).write(
          BillsCompanion(
            nextDueDate: Value(payment.dueDate),
            isActive: const Value(true),
            updatedAt: Value(nowUtc()),
          ),
        );
      }
    });
  }
}
