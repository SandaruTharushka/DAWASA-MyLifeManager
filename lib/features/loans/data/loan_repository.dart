import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/local_date.dart';
import '../../transactions/data/category_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_models.dart';

class LoanDraft {
  const LoanDraft({
    required this.id,
    required this.direction,
    required this.counterparty,
    required this.principalMinor,
    required this.currencyCode,
    required this.startDate,
    this.dueDate,
    this.interestRateBps,
    this.accountId,
    this.recordMovement = false,
    this.remindersEnabled = true,
    this.remindDaysBefore = 3,
    this.note,
  });

  final String id;
  final LoanDirection direction;
  final String counterparty;
  final int principalMinor;
  final String currencyCode;
  final LocalDate startDate;
  final LocalDate? dueDate;
  final int? interestRateBps;
  final String? accountId;

  /// Record the principal leaving/entering [accountId].
  final bool recordMovement;
  final bool remindersEnabled;
  final int remindDaysBefore;
  final String? note;
}

class LoanView {
  const LoanView(this.loan, this.repaidPrincipalMinor, this.interestMinor);

  final LoanRow loan;
  final int repaidPrincipalMinor;
  final int interestMinor;

  int get outstandingMinor => loan.status == LoanStatus.settled
      ? 0
      : (loan.principalMinor - repaidPrincipalMinor).clamp(
          0,
          loan.principalMinor,
        );
  bool get isLent => loan.direction == LoanDirection.lent;
  double get fractionRepaid => loan.principalMinor <= 0
      ? 0
      : (repaidPrincipalMinor / loan.principalMinor).clamp(0, 1).toDouble();
}

class OverpaymentException implements Exception {
  const OverpaymentException();
}

class LoanRepository {
  LoanRepository(this._db, this._transactions, this._categories);

  final AppDatabase _db;
  final TransactionRepository _transactions;
  final CategoryRepository _categories;

  static const _sql = '''
SELECT l.*,
  COALESCE((SELECT SUM(r.principal_minor) FROM loan_repayments r WHERE r.loan_id = l.id), 0) AS repaid,
  COALESCE((SELECT SUM(r.interest_minor) FROM loan_repayments r WHERE r.loan_id = l.id), 0) AS interest
FROM loans l''';

  List<LoanView> _map(List<QueryRow> rows) => [
    for (final r in rows)
      LoanView(
        _db.loans.map(r.data),
        r.read<int>('repaid'),
        r.read<int>('interest'),
      ),
  ];

  Selectable<QueryRow> _query(
    String suffix, [
    List<Variable<Object>> vars = const [],
  ]) => _db.customSelect(
    '$_sql $suffix',
    variables: vars,
    readsFrom: {_db.loans, _db.loanRepayments},
  );

  Stream<List<LoanView>> watchLoans() => _query(
    "ORDER BY l.status = 'settled', l.due_date IS NULL, l.due_date, l.created_at",
  ).watch().map(_map);

  Future<List<LoanView>> loans() async =>
      _map(await _query("ORDER BY l.status = 'settled', l.due_date").get());

  Future<LoanView?> loan(String id) async {
    final rows = await _query('WHERE l.id = ?', [
      Variable.withString(id),
    ]).get();
    return rows.isEmpty ? null : _map(rows).single;
  }

  Stream<LoanView?> watchLoan(String id) => _query('WHERE l.id = ?', [
    Variable.withString(id),
  ]).watch().map((rows) => rows.isEmpty ? null : _map(rows).single);

  Stream<List<LoanRepaymentRow>> watchRepayments(String loanId) =>
      (_db.select(_db.loanRepayments)
            ..where((r) => r.loanId.equals(loanId))
            ..orderBy([
              (r) => OrderingTerm.desc(r.localDate),
              (r) => OrderingTerm.desc(r.createdAt),
            ]))
          .watch();

  /// Creates or updates a loan. On creation the principal movement can be
  /// recorded (money lent leaves the account, money borrowed enters it).
  Future<void> save(LoanDraft d) {
    return _db.transaction(() async {
      final existing = await (_db.select(
        _db.loans,
      )..where((l) => l.id.equals(d.id))).getSingleOrNull();
      final companion = LoansCompanion.insert(
        id: Value(d.id),
        direction: d.direction,
        counterparty: d.counterparty.trim(),
        principalMinor: d.principalMinor,
        currencyCode: Value(d.currencyCode),
        interestRateBps: Value(d.interestRateBps),
        startDate: d.startDate,
        dueDate: Value(d.dueDate),
        accountId: Value(d.accountId),
        remindersEnabled: Value(d.remindersEnabled),
        remindDaysBefore: Value(d.remindDaysBefore),
        note: Value((d.note?.trim().isEmpty ?? true) ? null : d.note!.trim()),
        updatedAt: Value(nowUtc()),
      );
      if (existing == null) {
        String? txId;
        if (d.recordMovement && d.accountId != null) {
          txId = deterministicId('loan:${d.id}:disbursement');
          await _transactions.insertWithinTransaction(
            TransactionDraft(
              id: txId,
              type: d.direction == LoanDirection.lent
                  ? TransactionType.loanGiven
                  : TransactionType.loanReceived,
              amountMinor: d.principalMinor,
              currencyCode: d.currencyCode,
              accountId: d.accountId!,
              occurredAt: d.startDate.atMinutes(12 * 60),
              description: d.counterparty.trim(),
              source: TransactionSource.loan,
              sourceRefId: d.id,
            ),
          );
        }
        await _db
            .into(_db.loans)
            .insert(companion.copyWith(disbursementTransactionId: Value(txId)));
      } else {
        await (_db.update(_db.loans)..where((l) => l.id.equals(d.id))).write(
          companion.copyWith(
            createdAt: const Value.absent(),
            // The recorded principal movement follows the edited amount.
            accountId: existing.disbursementTransactionId != null
                ? const Value.absent()
                : Value(d.accountId),
          ),
        );
        final txId = existing.disbursementTransactionId;
        if (txId != null) {
          await (_db.update(
            _db.transactions,
          )..where((t) => t.id.equals(txId))).write(
            TransactionsCompanion(
              amountMinor: Value(d.principalMinor),
              description: Value(d.counterparty.trim()),
              updatedAt: Value(nowUtc()),
            ),
          );
        }
        await _autoSettle(d.id);
      }
    });
  }

  /// Deletes the loan with its repayments and recorded money movements.
  Future<void> delete(String id) {
    return _db.transaction(() async {
      final loan = await (_db.select(
        _db.loans,
      )..where((l) => l.id.equals(id))).getSingleOrNull();
      if (loan == null) return;
      final repayments = await (_db.select(
        _db.loanRepayments,
      )..where((r) => r.loanId.equals(id))).get();
      final txIds = <String>{
        ?loan.disbursementTransactionId,
        for (final r in repayments) ...[
          ?r.principalTransactionId,
          ?r.interestTransactionId,
        ],
      };
      await (_db.delete(_db.loans)..where((l) => l.id.equals(id))).go();
      if (txIds.isNotEmpty) {
        await (_db.delete(
          _db.transactions,
        )..where((t) => t.id.isIn(txIds))).go();
      }
    });
  }

  /// Records a repayment. Principal reduces the outstanding balance (never
  /// income/spending); interest is income for money lent and an expense for
  /// money borrowed.
  Future<void> recordRepayment({
    required String repaymentId,
    required String loanId,
    required int principalMinor,
    int interestMinor = 0,
    required DateTime paidAt,
    String? accountId,
    String? note,
  }) {
    return _db.transaction(() async {
      final exists = await (_db.select(
        _db.loanRepayments,
      )..where((r) => r.id.equals(repaymentId))).getSingleOrNull();
      if (exists != null) return;
      final view = await loan(loanId);
      if (view == null) throw StateError('Unknown loan $loanId');
      if (principalMinor > view.outstandingMinor) {
        throw const OverpaymentException();
      }
      final lent = view.isLent;
      String? principalTx;
      String? interestTx;
      if (accountId != null && principalMinor > 0) {
        principalTx = deterministicId('loan:$repaymentId:principal');
        await _transactions.insertWithinTransaction(
          TransactionDraft(
            id: principalTx,
            type: lent
                ? TransactionType.loanRepaymentReceived
                : TransactionType.loanRepaymentPaid,
            amountMinor: principalMinor,
            currencyCode: view.loan.currencyCode,
            accountId: accountId,
            occurredAt: paidAt,
            description: view.loan.counterparty,
            note: note,
            source: TransactionSource.loan,
            sourceRefId: loanId,
          ),
        );
      }
      if (accountId != null && interestMinor > 0) {
        interestTx = deterministicId('loan:$repaymentId:interest');
        final category = await _categories.bySystemKey(
          lent ? CategoryKind.income : CategoryKind.expense,
          lent ? 'interest' : 'interestFees',
        );
        await _transactions.insertWithinTransaction(
          TransactionDraft(
            id: interestTx,
            type: lent ? TransactionType.income : TransactionType.expense,
            amountMinor: interestMinor,
            currencyCode: view.loan.currencyCode,
            accountId: accountId,
            categoryId: category?.id,
            occurredAt: paidAt,
            description: view.loan.counterparty,
            source: TransactionSource.loan,
            sourceRefId: loanId,
          ),
        );
      }
      await _db
          .into(_db.loanRepayments)
          .insert(
            LoanRepaymentsCompanion.insert(
              id: Value(repaymentId),
              loanId: loanId,
              principalMinor: Value(principalMinor),
              interestMinor: Value(interestMinor),
              localDate: LocalDate.fromDateTime(paidAt),
              paidAt: paidAt.toUtc(),
              accountId: Value(accountId),
              principalTransactionId: Value(principalTx),
              interestTransactionId: Value(interestTx),
              note: Value(note),
            ),
          );
      await _autoSettle(loanId);
    });
  }

  Future<void> deleteRepayment(String repaymentId) {
    return _db.transaction(() async {
      final r = await (_db.select(
        _db.loanRepayments,
      )..where((x) => x.id.equals(repaymentId))).getSingleOrNull();
      if (r == null) return;
      await (_db.delete(
        _db.loanRepayments,
      )..where((x) => x.id.equals(repaymentId))).go();
      final txIds = {?r.principalTransactionId, ?r.interestTransactionId};
      if (txIds.isNotEmpty) {
        await (_db.delete(
          _db.transactions,
        )..where((t) => t.id.isIn(txIds))).go();
      }
      await _setStatus(r.loanId, LoanStatus.active);
      await _autoSettle(r.loanId);
    });
  }

  /// Manually closes a loan (remaining amount is written off).
  Future<void> settle(String loanId) => _setStatus(loanId, LoanStatus.settled);

  Future<void> reopen(String loanId) => _setStatus(loanId, LoanStatus.active);

  Future<void> _setStatus(String loanId, LoanStatus status) =>
      (_db.update(_db.loans)..where((l) => l.id.equals(loanId))).write(
        LoansCompanion(
          status: Value(status),
          settledAt: Value(status == LoanStatus.settled ? nowUtc() : null),
          updatedAt: Value(nowUtc()),
        ),
      );

  Future<void> _autoSettle(String loanId) async {
    final view = await loan(loanId);
    if (view == null || view.loan.status == LoanStatus.settled) return;
    if (view.repaidPrincipalMinor >= view.loan.principalMinor) {
      await _setStatus(loanId, LoanStatus.settled);
    }
  }

  /// Totals of active loans in [currencyCode].
  Future<({int owedToYou, int youOwe})> totals(String currencyCode) async {
    var owedToYou = 0, youOwe = 0;
    for (final l in await loans()) {
      if (l.loan.currencyCode != currencyCode) continue;
      if (l.isLent) {
        owedToYou += l.outstandingMinor;
      } else {
        youOwe += l.outstandingMinor;
      }
    }
    return (owedToYou: owedToYou, youOwe: youOwe);
  }
}
