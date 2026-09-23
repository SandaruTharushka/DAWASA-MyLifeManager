import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../domain/daily_allowance.dart';

/// Today's spending allowance from the daily budget setting.
final dailyAllowanceProvider = Provider<AsyncValue<DailyAllowance?>>((ref) {
  final today = ref.watch(todayProvider);
  final daily = ref.watch(
    userSettingsProvider.select((s) => s.dailyBudgetMinor),
  );
  return ref
      .watch(todayTotalsProvider)
      .whenData(
        (totals) => computeDailyAllowance(
          today: today,
          spentTodayMinor: totals.expenseMinor,
          dailyBudgetMinor: daily,
        ),
      );
});
