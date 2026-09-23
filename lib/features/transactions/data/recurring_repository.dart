import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/recurrence.dart';
import '../domain/transaction_models.dart';
import 'transaction_repository.dart';

/// A recurring rule joined with display information.
class RecurringRuleView {
  const RecurringRuleView({
    required this.row,
    required this.rule,
    this.category,
    required this.account,
  });

  final RecurringRuleRow row;
  final RecurrenceRule rule;
  final TxCategory? category;
  final Account account;
}

/// Creates recurring transaction series and materialises due occurrences.
///
/// Every generated occurrence gets a deterministic id derived from the rule
/// id and date, so running the generator twice (or concurrently on app start
/// and resume) can never create duplicates.
class RecurringRepository {
  RecurringRepository(this._db, this._transactions);

  final AppDatabase _db;
  final TransactionRepository _transactions;

  /// Safety cap for catch-up generation after a long time without opening
  /// the app (e.g. a daily rule after two years offline).
  static const int maxOccurrencesPerRun = 400;

  static String occurrenceId(String ruleId, LocalDate date) =>
      deterministicId('recurring:$ruleId:${date.toIso()}');

  /// Creates a rule from [template] (the first occurrence uses the template's
  /// date) and generates any occurrences already due. Returns the number of
  /// transactions created. Idempotent for the same [ruleId].
  Future<int> createRule({
    required String ruleId,
    required TransactionDraft template,
    required RecurrenceRule rule,
    required LocalDate today,
  }) async {
    await _transactions.validate(template);
    final start = template.localDate;
    final inserted = await _db.transaction(() async {
      final exists = await (_db.select(
        _db.recurringRules,
      )..where((r) => r.id.equals(ruleId))).getSingleOrNull();
      if (exists != null) return false;
      await _db
          .into(_db.recurringRules)
          .insert(
            RecurringRulesCompanion.insert(
              id: Value(ruleId),
              rule: rule.encode(),
              startDate: start,
              nextDate: Value(rule.nextOnOrAfter(start, start)),
              type: template.type,
              amountMinor: template.amountMinor,
              currencyCode: Value(template.currencyCode),
              accountId: template.accountId,
              toAccountId: Value(template.toAccountId),
              categoryId: Value(template.categoryId),
              description: Value(template.description.trim()),
              note: Value(template.note),
              timeOfDayMinutes: Value(
                template.occurredAt.hour * 60 + template.occurredAt.minute,
              ),
            ),
          );
      return true;
    });
    if (!inserted) return 0;
    return generateDue(today, onlyRuleId: ruleId);
  }

  /// Generates all occurrences with a date on or before [today].
  Future<int> generateDue(LocalDate today, {String? onlyRuleId}) async {
    final query = _db.select(_db.recurringRules)
      ..where((r) {
        Expression<bool> e =
            r.isActive.equals(true) &
            r.nextDate.isNotNull() &
            r.nextDate.isSmallerOrEqualValue(today.toIso());
        if (onlyRuleId != null) e = e & r.id.equals(onlyRuleId);
        return e;
      });
    final due = await query.get();
    var created = 0;
    for (final row in due) {
      created += await _generateForRule(row, today);
    }
    return created;
  }

  Future<int> _generateForRule(RecurringRuleRow row, LocalDate today) async {
    final rule = RecurrenceRule.decode(row.rule);
    if (rule == null) return 0;
    return _db.transaction(() async {
      var created = 0;
      LocalDate? next = row.nextDate;
      while (next != null &&
          !next.isAfter(today) &&
          created < maxOccurrencesPerRun) {
        final id = occurrenceId(row.id, next);
        final result = await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: Value(id),
                type: row.type,
                amountMinor: row.amountMinor,
                currencyCode: Value(row.currencyCode),
                accountId: row.accountId,
                toAccountId: Value(row.toAccountId),
                categoryId: Value(row.categoryId),
                occurredAt: next.atMinutes(row.timeOfDayMinutes).toUtc(),
                localDate: next,
                description: Value(row.description),
                note: Value(row.note),
                recurringRuleId: Value(row.id),
                source: const Value(TransactionSource.recurring),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        if (result > 0) created++;
        next = rule.nextAfter(row.startDate, next);
      }
      await (_db.update(
        _db.recurringRules,
      )..where((r) => r.id.equals(row.id))).write(
        RecurringRulesCompanion(
          nextDate: Value(next),
          isActive: Value(next != null),
          updatedAt: Value(nowUtc()),
        ),
      );
      return created;
    });
  }

  Stream<List<RecurringRuleView>> watchAll() {
    final q =
        _db.select(_db.recurringRules).join([
          innerJoin(
            _db.accounts,
            _db.accounts.id.equalsExp(_db.recurringRules.accountId),
          ),
          leftOuterJoin(
            _db.transactionCategories,
            _db.transactionCategories.id.equalsExp(
              _db.recurringRules.categoryId,
            ),
          ),
        ])..orderBy([
          OrderingTerm.desc(_db.recurringRules.isActive),
          OrderingTerm.asc(_db.recurringRules.nextDate),
        ]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          RecurringRuleView(
            row: r.readTable(_db.recurringRules),
            rule:
                RecurrenceRule.decode(r.readTable(_db.recurringRules).rule) ??
                RecurrenceRule.monthly(),
            account: r.readTable(_db.accounts),
            category: r.readTableOrNull(_db.transactionCategories),
          ),
      ],
    );
  }

  /// Pauses or resumes a rule. Resuming continues from the next occurrence
  /// on or after [today] instead of back-filling the paused period.
  Future<void> setActive(
    String ruleId, {
    required bool active,
    required LocalDate today,
  }) async {
    final row = await (_db.select(
      _db.recurringRules,
    )..where((r) => r.id.equals(ruleId))).getSingleOrNull();
    if (row == null) return;
    LocalDate? next = row.nextDate;
    if (active) {
      final rule = RecurrenceRule.decode(row.rule);
      next = rule?.nextOnOrAfter(row.startDate, today);
    }
    await (_db.update(
      _db.recurringRules,
    )..where((r) => r.id.equals(ruleId))).write(
      RecurringRulesCompanion(
        isActive: Value(active && next != null),
        nextDate: Value(next),
        updatedAt: Value(nowUtc()),
      ),
    );
  }

  /// Deletes the rule; already generated transactions are kept.
  Future<void> delete(String ruleId) async {
    await (_db.delete(
      _db.recurringRules,
    )..where((r) => r.id.equals(ruleId))).go();
  }
}
