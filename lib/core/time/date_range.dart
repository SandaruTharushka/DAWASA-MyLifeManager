import 'local_date.dart';

/// An inclusive range of calendar dates.
class DateRange {
  DateRange(this.start, this.end)
    : assert(!end.isBefore(start), 'end must not be before start');

  factory DateRange.singleDay(LocalDate day) => DateRange(day, day);

  factory DateRange.month(int year, int month) {
    final first = LocalDate(year, month, 1);
    return DateRange(first, first.lastDayOfMonth);
  }

  factory DateRange.monthOf(LocalDate date) =>
      DateRange.month(date.year, date.month);

  factory DateRange.weekOf(LocalDate date, {int firstWeekday = 1}) {
    final start = date.startOfWeek(firstWeekday);
    return DateRange(start, start.addDays(6));
  }

  /// The last [days] days ending with [today] (inclusive).
  factory DateRange.lastDays(LocalDate today, int days) =>
      DateRange(today.addDays(-(days - 1)), today);

  final LocalDate start;
  final LocalDate end;

  int get lengthInDays => start.daysUntil(end) + 1;

  bool contains(LocalDate date) =>
      !date.isBefore(start) && !date.isAfter(end);

  Iterable<LocalDate> get days sync* {
    var d = start;
    while (!d.isAfter(end)) {
      yield d;
      d = d.addDays(1);
    }
  }

  /// Start instant (local midnight) as UTC, useful for instant queries.
  DateTime get startInstantUtc => start.startOfDayLocal.toUtc();

  /// Exclusive end instant (next local midnight) as UTC.
  DateTime get endInstantUtcExclusive => end.endOfDayLocalExclusive.toUtc();

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '$start..$end';
}

/// Preset report periods.
enum RangePreset {
  today,
  yesterday,
  last7Days,
  thisMonth,
  lastMonth,
  custom;

  DateRange resolve(LocalDate today, {DateRange? custom}) {
    switch (this) {
      case RangePreset.today:
        return DateRange.singleDay(today);
      case RangePreset.yesterday:
        return DateRange.singleDay(today.addDays(-1));
      case RangePreset.last7Days:
        return DateRange.lastDays(today, 7);
      case RangePreset.thisMonth:
        return DateRange.monthOf(today);
      case RangePreset.lastMonth:
        final prev = today.firstDayOfMonth.addMonths(-1);
        return DateRange.monthOf(prev);
      case RangePreset.custom:
        return custom ?? DateRange.monthOf(today);
    }
  }
}
