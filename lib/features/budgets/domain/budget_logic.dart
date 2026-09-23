import '../../../core/database/app_database.dart';
import '../../../core/money/money.dart';
import '../../../core/time/date_range.dart';
import '../../../core/time/local_date.dart';

enum BudgetStatus { active, notStarted, ended }

enum BudgetAlertLevel { none, warning, exceeded }

/// The period a budget currently covers.
class BudgetWindow {
  const BudgetWindow(this.range, this.key, this.status);

  final DateRange range;

  /// Stable id of the period (used to alert only once per period).
  final String key;
  final BudgetStatus status;
}

/// Computes the window of [budget] that contains [today].
BudgetWindow budgetWindow(
  BudgetPeriod period,
  LocalDate today, {
  int firstWeekday = DateTime.monday,
  LocalDate? customStart,
  LocalDate? customEnd,
}) {
  switch (period) {
    case BudgetPeriod.daily:
      return BudgetWindow(
        DateRange.singleDay(today),
        'd:${today.toIso()}',
        BudgetStatus.active,
      );
    case BudgetPeriod.weekly:
      final range = DateRange.weekOf(today, firstWeekday: firstWeekday);
      return BudgetWindow(
        range,
        'w:${range.start.toIso()}',
        BudgetStatus.active,
      );
    case BudgetPeriod.monthly:
      return BudgetWindow(
        DateRange.monthOf(today),
        'm:${today.monthKey}',
        BudgetStatus.active,
      );
    case BudgetPeriod.custom:
      final start = customStart ?? today;
      final end = customEnd ?? start;
      final status = today.isBefore(start)
          ? BudgetStatus.notStarted
          : today.isAfter(end)
          ? BudgetStatus.ended
          : BudgetStatus.active;
      return BudgetWindow(DateRange(start, end), 'c:${start.toIso()}', status);
  }
}

/// A budget with its spending in the current window.
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.categoryIds,
    required this.window,
    required this.spentMinor,
    required this.today,
  });

  final BudgetRow budget;

  /// Empty = overall spending budget.
  final Set<String> categoryIds;
  final BudgetWindow window;
  final int spentMinor;
  final LocalDate today;

  int get amountMinor => budget.amountMinor;
  int get remainingMinor => amountMinor - spentMinor;
  bool get isOverall => categoryIds.isEmpty;
  bool get exceeded => spentMinor > amountMinor;
  int get percentUsed => Money.percent(spentMinor, amountMinor);
  double get fraction => amountMinor <= 0 ? 0 : spentMinor / amountMinor;

  /// Days left in the window including today (0 when not active).
  int get daysLeft => window.status == BudgetStatus.active
      ? today.daysUntil(window.range.end) + 1
      : 0;

  /// Even spread of what is left over the remaining days.
  int? get perDayLeftMinor =>
      daysLeft <= 1 || remainingMinor <= 0 ? null : remainingMinor ~/ daysLeft;

  BudgetAlertLevel get alertLevel {
    if (window.status != BudgetStatus.active) return BudgetAlertLevel.none;
    if (exceeded) return BudgetAlertLevel.exceeded;
    if (percentUsed >= budget.warnPercent) return BudgetAlertLevel.warning;
    return BudgetAlertLevel.none;
  }

  /// Alert key such as `m:2026-09:warning`.
  String get alertKey => '${window.key}:${alertLevel.name}';

  /// Whether an alert should be raised given the last one sent.
  bool shouldAlert() {
    final level = alertLevel;
    if (level == BudgetAlertLevel.none || !budget.notify) return false;
    final last = budget.lastAlert;
    if (last == alertKey) return false;
    // Never step back from "exceeded" to "warning" in the same period.
    if (level == BudgetAlertLevel.warning &&
        last == '${window.key}:${BudgetAlertLevel.exceeded.name}') {
      return false;
    }
    return true;
  }
}
