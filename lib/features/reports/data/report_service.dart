import '../../../core/database/app_database.dart';
import '../../../core/time/date_range.dart';
import '../../../core/time/local_date.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_models.dart';

/// One bucket (day or month) of income and spending.
class CashFlowPoint {
  const CashFlowPoint(this.start, this.incomeMinor, this.expenseMinor);

  final LocalDate start;
  final int incomeMinor;
  final int expenseMinor;
}

enum ReportGranularity { day, month }

class ReportData {
  const ReportData({
    required this.range,
    required this.totals,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.granularity,
    required this.cashFlow,
    required this.monthlyTrend,
  });

  final DateRange range;
  final PeriodTotals totals;
  final List<CategoryTotal> expenseByCategory;
  final List<CategoryTotal> incomeByCategory;
  final ReportGranularity granularity;

  /// Income vs expenses per day (short ranges) or month (long ranges).
  final List<CashFlowPoint> cashFlow;

  /// Spending of the six months ending with the range's end month.
  final List<CashFlowPoint> monthlyTrend;

  bool get isEmpty =>
      totals.incomeMinor == 0 &&
      totals.expenseMinor == 0 &&
      totals.otherInMinor == 0 &&
      totals.otherOutMinor == 0;
}

/// Builds report aggregates using SQL grouping, so large histories stay
/// fast (no full table scans in Dart).
class ReportService {
  ReportService(this._transactions);

  final TransactionRepository _transactions;

  static const int dailyLimitDays = 62;

  Future<ReportData> build(DateRange range, String currencyCode) async {
    final totals = await _transactions.totals(
      range,
      currencyCode: currencyCode,
    );
    final expenses = await _transactions.categoryTotals(
      range,
      type: TransactionType.expense,
      currencyCode: currencyCode,
    );
    final income = await _transactions.categoryTotals(
      range,
      type: TransactionType.income,
      currencyCode: currencyCode,
    );
    final granularity = range.lengthInDays <= dailyLimitDays
        ? ReportGranularity.day
        : ReportGranularity.month;

    List<CashFlowPoint> cashFlow;
    if (granularity == ReportGranularity.day) {
      final exp = await _transactions.dailyTotals(
        range,
        currencyCode: currencyCode,
      );
      final inc = await _transactions.dailyTotals(
        range,
        type: TransactionType.income,
        currencyCode: currencyCode,
      );
      cashFlow = [
        for (final d in range.days) CashFlowPoint(d, inc[d] ?? 0, exp[d] ?? 0),
      ];
    } else {
      cashFlow = await _months(
        range.start.firstDayOfMonth,
        range.end,
        currencyCode,
      );
    }

    final trendEnd = range.end;
    final trendStart = trendEnd.firstDayOfMonth.addMonths(-5);
    final trend = await _months(
      trendStart,
      trendEnd.lastDayOfMonth,
      currencyCode,
    );

    return ReportData(
      range: range,
      totals: totals,
      expenseByCategory: expenses,
      incomeByCategory: income,
      granularity: granularity,
      cashFlow: cashFlow,
      monthlyTrend: trend,
    );
  }

  Future<List<CashFlowPoint>> _months(
    LocalDate firstMonth,
    LocalDate end,
    String currencyCode,
  ) async {
    final points = <CashFlowPoint>[];
    for (var m = firstMonth; !m.isAfter(end); m = m.addMonths(1)) {
      final t = await _transactions.totals(
        DateRange.monthOf(m),
        currencyCode: currencyCode,
      );
      points.add(CashFlowPoint(m, t.incomeMinor, t.expenseMinor));
    }
    return points;
  }
}
