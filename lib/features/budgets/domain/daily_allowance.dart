import '../../../core/time/local_date.dart';

enum AllowanceSource { dailyBudget, monthlyBudget }

/// How much can still be spent today.
class DailyAllowance {
  const DailyAllowance({
    required this.allowanceMinor,
    required this.spentTodayMinor,
    required this.source,
  });

  /// Today's spending allowance.
  final int allowanceMinor;
  final int spentTodayMinor;
  final AllowanceSource source;

  int get remainingMinor => allowanceMinor - spentTodayMinor;
  bool get exceeded => remainingMinor < 0;

  /// 0..1+ share of the allowance already used.
  double get usedFraction => allowanceMinor <= 0
      ? (spentTodayMinor > 0 ? 1 : 0)
      : spentTodayMinor / allowanceMinor;
}

/// Computes today's allowance.
///
/// * With an explicit daily budget, the allowance is that amount.
/// * Otherwise, with an overall monthly budget, the money left in the month
///   (excluding today's spending) is spread evenly over the remaining days
///   including today. This automatically adapts to 28, 29, 30 and 31 day
///   months and to overspending earlier in the month.
DailyAllowance? computeDailyAllowance({
  required LocalDate today,
  required int spentTodayMinor,
  int? dailyBudgetMinor,
  int? monthlyBudgetMinor,
  int spentThisMonthBeforeTodayMinor = 0,
}) {
  if (dailyBudgetMinor != null && dailyBudgetMinor > 0) {
    return DailyAllowance(
      allowanceMinor: dailyBudgetMinor,
      spentTodayMinor: spentTodayMinor,
      source: AllowanceSource.dailyBudget,
    );
  }
  if (monthlyBudgetMinor != null && monthlyBudgetMinor > 0) {
    final daysLeft = today.daysInThisMonth - today.day + 1;
    final left = monthlyBudgetMinor - spentThisMonthBeforeTodayMinor;
    final allowance = left <= 0 ? 0 : left ~/ daysLeft;
    return DailyAllowance(
      allowanceMinor: allowance,
      spentTodayMinor: spentTodayMinor,
      source: AllowanceSource.monthlyBudget,
    );
  }
  return null;
}
