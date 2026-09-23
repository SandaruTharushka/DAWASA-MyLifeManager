import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../data/budget_repository.dart';
import '../domain/budget_logic.dart';
import '../domain/daily_allowance.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepository(
    ref.watch(databaseProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);

/// Live progress of all active budgets for the current periods.
final budgetProgressProvider = StreamProvider<List<BudgetProgress>>((ref) {
  final today = ref.watch(todayProvider);
  final firstWeekday = ref.watch(
    userSettingsProvider.select((s) => s.firstDayOfWeek),
  );
  return ref.watch(budgetRepositoryProvider).watchProgress(today, firstWeekday);
});

final _monthlyOverallProvider =
    FutureProvider<({int amount, int spentBeforeToday})?>((ref) async {
      // Recompute when budgets or today's totals change.
      ref.watch(budgetProgressProvider);
      ref.watch(todayTotalsProvider);
      return ref
          .watch(budgetRepositoryProvider)
          .monthlyOverall(
            ref.watch(todayProvider),
            ref.watch(currencyProvider).code,
          );
    });

/// Today's spending allowance: the daily budget setting, or else an even
/// share of what is left in an overall monthly budget.
final dailyAllowanceProvider = Provider<AsyncValue<DailyAllowance?>>((ref) {
  final today = ref.watch(todayProvider);
  final daily = ref.watch(
    userSettingsProvider.select((s) => s.dailyBudgetMinor),
  );
  final totals = ref.watch(todayTotalsProvider);
  final monthly = ref.watch(_monthlyOverallProvider);
  if (totals.isLoading && !totals.hasValue) return const AsyncLoading();
  final spentToday = totals.value?.expenseMinor ?? 0;
  final m = monthly.value;
  return AsyncData(
    computeDailyAllowance(
      today: today,
      spentTodayMinor: spentToday,
      dailyBudgetMinor: daily,
      monthlyBudgetMinor: m?.amount,
      spentThisMonthBeforeTodayMinor: m?.spentBeforeToday ?? 0,
    ),
  );
});
