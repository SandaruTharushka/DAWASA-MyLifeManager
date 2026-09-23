import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/finance/transaction_rules.dart';
import '../../../core/money/money.dart';
import '../../../core/time/date_range.dart';
import '../../../core/time/local_date.dart';
import '../domain/transaction_models.dart';

class TransactionRepository {
  TransactionRepository(this._db);

  final AppDatabase _db;

  late final $AccountsTable _toAccounts = _db.accounts.createAlias('to_acc');

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  Future<void> validate(TransactionDraft d) async {
    if (d.amountMinor <= 0 || d.amountMinor > kMaxMinorAmount) {
      throw const TransactionValidationException(
        TransactionValidationError.amountNotPositive,
      );
    }
    final account = await _account(d.accountId);
    if (account == null) {
      throw const TransactionValidationException(
        TransactionValidationError.unknownAccount,
      );
    }
    if (TransactionRules.isTransfer(d.type)) {
      if (d.toAccountId == null) {
        throw const TransactionValidationException(
          TransactionValidationError.missingToAccount,
        );
      }
      if (d.toAccountId == d.accountId) {
        throw const TransactionValidationException(
          TransactionValidationError.sameAccount,
        );
      }
      final to = await _account(d.toAccountId!);
      if (to == null) {
        throw const TransactionValidationException(
          TransactionValidationError.unknownAccount,
        );
      }
      if (to.currencyCode != account.currencyCode) {
        throw const TransactionValidationException(
          TransactionValidationError.currencyMismatch,
        );
      }
    } else if (d.toAccountId != null) {
      throw const TransactionValidationException(
        TransactionValidationError.unexpectedToAccount,
      );
    }
    if (d.currencyCode != account.currencyCode) {
      throw const TransactionValidationException(
        TransactionValidationError.currencyMismatch,
      );
    }
    if (TransactionRules.requiresCategory(d.type)) {
      if (d.categoryId == null) {
        throw const TransactionValidationException(
          TransactionValidationError.missingCategory,
        );
      }
      final category = await (_db.select(
        _db.transactionCategories,
      )..where((c) => c.id.equals(d.categoryId!))).getSingleOrNull();
      final expectedKind = d.type == TransactionType.expense
          ? CategoryKind.expense
          : CategoryKind.income;
      if (category == null || category.kind != expectedKind) {
        throw const TransactionValidationException(
          TransactionValidationError.categoryKindMismatch,
        );
      }
    }
  }

  Future<Account?> _account(String id) => (_db.select(
    _db.accounts,
  )..where((a) => a.id.equals(id))).getSingleOrNull();

  TransactionsCompanion _companion(TransactionDraft d) =>
      TransactionsCompanion.insert(
        id: Value(d.id),
        type: d.type,
        amountMinor: d.amountMinor,
        currencyCode: Value(d.currencyCode),
        accountId: d.accountId,
        toAccountId: Value(
          TransactionRules.isTransfer(d.type) ? d.toAccountId : null,
        ),
        categoryId: Value(
          TransactionRules.requiresCategory(d.type) ? d.categoryId : null,
        ),
        occurredAt: d.occurredAt.toUtc(),
        localDate: d.localDate,
        description: Value(d.description.trim()),
        note: Value((d.note?.trim().isEmpty ?? true) ? null : d.note!.trim()),
        attachmentId: Value(d.attachmentId),
        recurringRuleId: Value(d.recurringRuleId),
        source: Value(d.source),
        sourceRefId: Value(d.sourceRefId),
      );

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Inserts a new transaction. Saving the same draft id twice is a no-op
  /// that returns [SaveOutcome.alreadyExisted].
  Future<SaveOutcome> create(TransactionDraft d) async {
    await validate(d);
    return _db.transaction(() async {
      final exists = await (_db.select(
        _db.transactions,
      )..where((t) => t.id.equals(d.id))).getSingleOrNull();
      if (exists != null) return SaveOutcome.alreadyExisted;
      await _db.into(_db.transactions).insert(_companion(d));
      return SaveOutcome.created;
    });
  }

  /// Inserts without a separate transaction (used inside other repositories'
  /// database transactions).
  Future<void> insertWithinTransaction(TransactionDraft d) async {
    await validate(d);
    await _db.into(_db.transactions).insert(_companion(d));
  }

  Future<void> update(TransactionDraft d) async {
    await validate(d);
    final companion = _companion(d)
        .copyWith(createdAt: const Value.absent(), updatedAt: Value(nowUtc()));
    await (_db.update(
      _db.transactions,
    )..where((t) => t.id.equals(d.id))).write(companion);
  }

  /// Deletes a transaction. Linked records (bill payments, shopping items,
  /// savings movements, loan repayments) are unlinked or removed by the
  /// foreign-key rules, so balances are recalculated consistently.
  Future<void> delete(String id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  JoinedSelectStatement<HasResultSet, dynamic> _joined() {
    return _db.select(_db.transactions).join([
      innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.transactions.accountId),
      ),
      leftOuterJoin(
        _toAccounts,
        _toAccounts.id.equalsExp(_db.transactions.toAccountId),
      ),
      leftOuterJoin(
        _db.transactionCategories,
        _db.transactionCategories.id.equalsExp(_db.transactions.categoryId),
      ),
    ]);
  }

  TransactionView _map(TypedResult row) => TransactionView(
    transaction: row.readTable(_db.transactions),
    account: row.readTable(_db.accounts),
    toAccount: row.readTableOrNull(_toAccounts),
    category: row.readTableOrNull(_db.transactionCategories),
  );

  void _applyFilter(
    JoinedSelectStatement<HasResultSet, dynamic> q,
    TransactionFilter f,
  ) {
    final t = _db.transactions;
    Expression<bool>? where;
    void and(Expression<bool> e) => where = where == null ? e : where! & e;

    if (f.types.isNotEmpty) {
      and(t.type.isIn(f.types.map((e) => e.name)));
    }
    if (f.categoryIds.isNotEmpty) and(t.categoryId.isIn(f.categoryIds));
    if (f.accountId != null) {
      and(
        t.accountId.equals(f.accountId!) | t.toAccountId.equals(f.accountId!),
      );
    }
    if (f.range != null) {
      and(
        t.localDate.isBetweenValues(
          f.range!.start.toIso(),
          f.range!.end.toIso(),
        ),
      );
    }
    final search = f.search.trim();
    if (search.isNotEmpty) {
      final escaped = search
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      final like = '%$escaped%';
      Expression<bool> text =
          t.description.like(like, escapeChar: r'\') |
          t.note.like(like, escapeChar: r'\') |
          _db.transactionCategories.name.like(like, escapeChar: r'\');
      final amount = Money.tryParse(search);
      if (amount != null && amount > 0) {
        text = text | t.amountMinor.equals(amount);
      }
      and(text);
    }
    if (where != null) q.where(where!);
  }

  Stream<List<TransactionView>> watchFiltered(
    TransactionFilter filter, {
    int limit = 50,
    int offset = 0,
  }) {
    final q = _joined();
    _applyFilter(q, filter);
    q
      ..orderBy([
        OrderingTerm.desc(_db.transactions.localDate),
        OrderingTerm.desc(_db.transactions.occurredAt),
        OrderingTerm.desc(_db.transactions.createdAt),
      ])
      ..limit(limit, offset: offset);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  Future<List<TransactionView>> filtered(
    TransactionFilter filter, {
    int? limit,
  }) async {
    final q = _joined();
    _applyFilter(q, filter);
    q.orderBy([
      OrderingTerm.desc(_db.transactions.localDate),
      OrderingTerm.desc(_db.transactions.occurredAt),
    ]);
    if (limit != null) q.limit(limit);
    final rows = await q.get();
    return rows.map(_map).toList();
  }

  Stream<List<TransactionView>> watchRecent({int limit = 5}) =>
      watchFiltered(const TransactionFilter(), limit: limit);

  Stream<TransactionView?> watchById(String id) {
    final q = _joined()..where(_db.transactions.id.equals(id));
    return q.watchSingleOrNull().map((r) => r == null ? null : _map(r));
  }

  Future<TransactionView?> byId(String id) async {
    final q = _joined()..where(_db.transactions.id.equals(id));
    final row = await q.getSingleOrNull();
    return row == null ? null : _map(row);
  }

  /// Income / spending / other movement totals for [range] in [currencyCode].
  Stream<PeriodTotals> watchTotals(DateRange range, {String? currencyCode}) {
    return _totalsQuery(range, currencyCode).watch().map(_mapTotals);
  }

  Future<PeriodTotals> totals(DateRange range, {String? currencyCode}) async =>
      _mapTotals(await _totalsQuery(range, currencyCode).get());

  Selectable<QueryRow> _totalsQuery(DateRange range, String? currencyCode) {
    return _db.customSelect(
      '''
SELECT type, SUM(amount_minor) AS total
FROM transactions
WHERE local_date BETWEEN ? AND ?
  ${currencyCode == null ? '' : 'AND currency_code = ?'}
GROUP BY type''',
      variables: [
        Variable.withString(range.start.toIso()),
        Variable.withString(range.end.toIso()),
        if (currencyCode != null) Variable.withString(currencyCode),
      ],
      readsFrom: {_db.transactions},
    );
  }

  PeriodTotals _mapTotals(List<QueryRow> rows) {
    var income = 0, expense = 0, otherIn = 0, otherOut = 0;
    for (final row in rows) {
      final type = TransactionType.values.byName(row.read<String>('type'));
      final total = row.read<int>('total');
      if (TransactionRules.countsAsIncome(type)) {
        income += total;
      } else if (TransactionRules.countsAsSpending(type)) {
        expense += total;
      } else if (type == TransactionType.transfer) {
        // Transfers net to zero across the user's own accounts.
      } else if (TransactionRules.inflowTypes.contains(type)) {
        otherIn += total;
      } else {
        otherOut += total;
      }
    }
    return PeriodTotals(
      incomeMinor: income,
      expenseMinor: expense,
      otherInMinor: otherIn,
      otherOutMinor: otherOut,
    );
  }

  /// Spending per calendar day in [range]; days without spending are 0.
  Stream<Map<LocalDate, int>> watchDailyTotals(
    DateRange range, {
    TransactionType type = TransactionType.expense,
    String? currencyCode,
  }) {
    return _dailyQuery(
      range,
      type,
      currencyCode,
    ).watch().map((rows) => _mapDaily(range, rows));
  }

  Future<Map<LocalDate, int>> dailyTotals(
    DateRange range, {
    TransactionType type = TransactionType.expense,
    String? currencyCode,
  }) async =>
      _mapDaily(range, await _dailyQuery(range, type, currencyCode).get());

  Selectable<QueryRow> _dailyQuery(
    DateRange range,
    TransactionType type,
    String? currencyCode,
  ) {
    return _db.customSelect(
      '''
SELECT local_date, SUM(amount_minor) AS total
FROM transactions
WHERE type = ? AND local_date BETWEEN ? AND ?
  ${currencyCode == null ? '' : 'AND currency_code = ?'}
GROUP BY local_date''',
      variables: [
        Variable.withString(type.name),
        Variable.withString(range.start.toIso()),
        Variable.withString(range.end.toIso()),
        if (currencyCode != null) Variable.withString(currencyCode),
      ],
      readsFrom: {_db.transactions},
    );
  }

  Map<LocalDate, int> _mapDaily(DateRange range, List<QueryRow> rows) {
    final result = {for (final d in range.days) d: 0};
    for (final row in rows) {
      result[LocalDate.parse(row.read<String>('local_date'))] = row.read<int>(
        'total',
      );
    }
    return result;
  }

  /// Totals per category for expense or income within [range].
  Future<List<CategoryTotal>> categoryTotals(
    DateRange range, {
    required TransactionType type,
    String? currencyCode,
    Set<String>? categoryIds,
  }) async {
    final rows = await _categoryTotalsQuery(
      range,
      type,
      currencyCode,
      categoryIds,
    ).get();
    return _mapCategoryTotals(rows);
  }

  Stream<List<CategoryTotal>> watchCategoryTotals(
    DateRange range, {
    required TransactionType type,
    String? currencyCode,
  }) => _categoryTotalsQuery(
    range,
    type,
    currencyCode,
    null,
  ).watch().map(_mapCategoryTotals);

  Selectable<QueryRow> _categoryTotalsQuery(
    DateRange range,
    TransactionType type,
    String? currencyCode,
    Set<String>? categoryIds,
  ) {
    final ids = categoryIds?.toList() ?? const <String>[];
    return _db.customSelect(
      '''
SELECT c.*, t.category_id AS cat_id, SUM(t.amount_minor) AS total
FROM transactions t
LEFT JOIN transaction_categories c ON c.id = t.category_id
WHERE t.type = ? AND t.local_date BETWEEN ? AND ?
  ${currencyCode == null ? '' : 'AND t.currency_code = ?'}
  ${ids.isEmpty ? '' : 'AND t.category_id IN (${List.filled(ids.length, '?').join(', ')})'}
GROUP BY t.category_id
ORDER BY total DESC''',
      variables: [
        Variable.withString(type.name),
        Variable.withString(range.start.toIso()),
        Variable.withString(range.end.toIso()),
        if (currencyCode != null) Variable.withString(currencyCode),
        for (final id in ids) Variable.withString(id),
      ],
      readsFrom: {_db.transactions, _db.transactionCategories},
    );
  }

  List<CategoryTotal> _mapCategoryTotals(List<QueryRow> rows) => [
    for (final row in rows)
      CategoryTotal(
        category:
            row.readNullable<String>('cat_id') == null ||
                row.readNullable<String>('id') == null
            ? null
            : _db.transactionCategories.map(row.data),
        totalMinor: row.read<int>('total'),
      ),
  ];

  /// Sum of expenses in [range], optionally limited to [categoryIds].
  Future<int> spending(
    DateRange range, {
    Set<String>? categoryIds,
    String? currencyCode,
  }) async {
    final ids = categoryIds?.toList() ?? const <String>[];
    final row = await _db
        .customSelect(
          '''
SELECT COALESCE(SUM(amount_minor), 0) AS total FROM transactions
WHERE type = 'expense' AND local_date BETWEEN ? AND ?
  ${currencyCode == null ? '' : 'AND currency_code = ?'}
  ${ids.isEmpty ? '' : 'AND category_id IN (${List.filled(ids.length, '?').join(', ')})'}''',
          variables: [
            Variable.withString(range.start.toIso()),
            Variable.withString(range.end.toIso()),
            if (currencyCode != null) Variable.withString(currencyCode),
            for (final id in ids) Variable.withString(id),
          ],
          readsFrom: {_db.transactions},
        )
        .getSingle();
    return row.read<int>('total');
  }

  /// Candidate existing expenses that look like the same payment (same amount
  /// within a few days). Used to avoid recording a bill twice.
  Future<List<TransactionView>> findSimilarExpenses({
    required int amountMinor,
    required LocalDate around,
    int days = 5,
  }) async {
    final q = _joined()
      ..where(
        _db.transactions.type.equals(TransactionType.expense.name) &
            _db.transactions.amountMinor.equals(amountMinor) &
            _db.transactions.localDate.isBetweenValues(
              around.addDays(-days).toIso(),
              around.addDays(days).toIso(),
            ),
      )
      ..orderBy([OrderingTerm.desc(_db.transactions.localDate)])
      ..limit(10);
    final rows = await q.get();
    return rows.map(_map).toList();
  }

  Future<int> count() async {
    final c = _db.transactions.id.count();
    final row = await (_db.selectOnly(
      _db.transactions,
    )..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }
}
