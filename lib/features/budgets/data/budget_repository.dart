import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../../../core/time/local_date.dart';
import '../../transactions/data/transaction_repository.dart';
import '../domain/budget_logic.dart';

class BudgetDraft {
  const BudgetDraft({
    required this.id,
    required this.name,
    required this.period,
    required this.amountMinor,
    required this.currencyCode,
    this.startDate,
    this.endDate,
    this.warnPercent = 80,
    this.notify = true,
    this.categoryIds = const {},
  });

  final String id;
  final String name;
  final BudgetPeriod period;
  final int amountMinor;
  final String currencyCode;
  final LocalDate? startDate;
  final LocalDate? endDate;
  final int warnPercent;
  final bool notify;
  final Set<String> categoryIds;
}

class BudgetRepository {
  BudgetRepository(this._db, this._transactions);

  final AppDatabase _db;
  final TransactionRepository _transactions;

  Future<Map<String, Set<String>>> _categoryMap() async {
    final rows = await _db.select(_db.budgetCategories).get();
    final map = <String, Set<String>>{};
    for (final r in rows) {
      map.putIfAbsent(r.budgetId, () => {}).add(r.categoryId);
    }
    return map;
  }

  Future<List<BudgetRow>> budgets({bool activeOnly = false}) {
    final q = _db.select(_db.budgets)
      ..orderBy([(b) => OrderingTerm.asc(b.createdAt)]);
    if (activeOnly) q.where((b) => b.isActive.equals(true));
    return q.get();
  }

  Future<BudgetRow?> byId(String id) => (_db.select(
    _db.budgets,
  )..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<Set<String>> categoriesOf(String budgetId) async {
    final rows = await (_db.select(
      _db.budgetCategories,
    )..where((c) => c.budgetId.equals(budgetId))).get();
    return rows.map((r) => r.categoryId).toSet();
  }

  Future<void> save(BudgetDraft d) async {
    await _db.transaction(() async {
      final companion = BudgetsCompanion.insert(
        id: Value(d.id),
        name: d.name.trim(),
        period: d.period,
        amountMinor: d.amountMinor,
        currencyCode: Value(d.currencyCode),
        startDate: Value(d.period == BudgetPeriod.custom ? d.startDate : null),
        endDate: Value(d.period == BudgetPeriod.custom ? d.endDate : null),
        warnPercent: Value(d.warnPercent.clamp(1, 100)),
        notify: Value(d.notify),
        updatedAt: Value(nowUtc()),
      );
      final existing = await byId(d.id);
      if (existing == null) {
        await _db.into(_db.budgets).insert(companion);
      } else {
        await (_db.update(_db.budgets)..where((b) => b.id.equals(d.id))).write(
          companion.copyWith(
            createdAt: const Value.absent(),
            // Changing the budget should allow fresh alerts.
            lastAlert: const Value(null),
          ),
        );
      }
      await (_db.delete(
        _db.budgetCategories,
      )..where((c) => c.budgetId.equals(d.id))).go();
      for (final categoryId in d.categoryIds) {
        await _db
            .into(_db.budgetCategories)
            .insert(
              BudgetCategoriesCompanion.insert(
                budgetId: d.id,
                categoryId: categoryId,
              ),
            );
      }
    });
  }

  Future<void> delete(String id) =>
      (_db.delete(_db.budgets)..where((b) => b.id.equals(id))).go();

  Future<void> setLastAlert(String id, String key) =>
      (_db.update(_db.budgets)..where((b) => b.id.equals(id))).write(
        BudgetsCompanion(lastAlert: Value(key)),
      );

  Future<BudgetProgress> progressOf(
    BudgetRow budget,
    Set<String> categoryIds,
    LocalDate today,
    int firstWeekday,
  ) async {
    final window = budgetWindow(
      budget.period,
      today,
      firstWeekday: firstWeekday,
      customStart: budget.startDate,
      customEnd: budget.endDate,
    );
    final spent = await _transactions.spending(
      window.range,
      categoryIds: categoryIds.isEmpty ? null : categoryIds,
      currencyCode: budget.currencyCode,
    );
    return BudgetProgress(
      budget: budget,
      categoryIds: categoryIds,
      window: window,
      spentMinor: spent,
      today: today,
    );
  }

  Future<List<BudgetProgress>> progress(
    LocalDate today,
    int firstWeekday, {
    bool activeOnly = true,
  }) async {
    final all = await budgets(activeOnly: activeOnly);
    final categories = await _categoryMap();
    return [
      for (final b in all)
        await progressOf(b, categories[b.id] ?? const {}, today, firstWeekday),
    ];
  }

  /// Emits fresh progress whenever budgets or transactions change.
  Stream<List<BudgetProgress>> watchProgress(
    LocalDate today,
    int firstWeekday,
  ) async* {
    yield await progress(today, firstWeekday);
    await for (final _ in _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.budgets,
        _db.budgetCategories,
        _db.transactions,
      ]),
    )) {
      yield await progress(today, firstWeekday);
    }
  }

  /// The overall monthly budget in [currencyCode] used for the dashboard's
  /// daily allowance, with spending before [today] in the current month.
  Future<({int amount, int spentBeforeToday})?> monthlyOverall(
    LocalDate today,
    String currencyCode,
  ) async {
    final categories = await _categoryMap();
    final monthly = (await budgets(activeOnly: true)).where(
      (b) =>
          b.period == BudgetPeriod.monthly &&
          b.currencyCode == currencyCode &&
          (categories[b.id]?.isEmpty ?? true),
    );
    final budget = monthly.firstOrNull;
    if (budget == null) return null;
    final first = today.firstDayOfMonth;
    final spentBefore = today == first
        ? 0
        : await _transactions.spending(
            DateRange(first, today.addDays(-1)),
            currencyCode: currencyCode,
          );
    return (amount: budget.amountMinor, spentBeforeToday: spentBefore);
  }
}
