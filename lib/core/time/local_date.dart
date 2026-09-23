/// A calendar date without a time or time zone (e.g. a due date or a
/// birthday).
///
/// Calendar arithmetic is done in UTC internally so that daylight saving
/// transitions can never shift a date by an hour and land on the wrong day.
class LocalDate implements Comparable<LocalDate> {
  LocalDate(this.year, this.month, this.day)
    : assert(month >= 1 && month <= 12),
      assert(day >= 1 && day <= 31) {
    if (day > daysInMonth(year, month)) {
      throw ArgumentError('Invalid date $year-$month-$day');
    }
  }

  /// Local calendar date of an instant, using the device time zone.
  factory LocalDate.fromDateTime(DateTime dateTime) {
    final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return LocalDate(local.year, local.month, local.day);
  }

  factory LocalDate.today([DateTime? now]) =>
      LocalDate.fromDateTime(now ?? DateTime.now());

  /// Parses `YYYY-MM-DD`.
  static LocalDate parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
    if (match == null) throw FormatException('Invalid LocalDate', value);
    return LocalDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static LocalDate? tryParse(String? value) {
    if (value == null) return null;
    try {
      return parse(value);
    } on Object {
      return null;
    }
  }

  final int year;
  final int month;
  final int day;

  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  static int daysInMonth(int year, int month) {
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && isLeapYear(year)) return 29;
    return days[month - 1];
  }

  DateTime get _utc => DateTime.utc(year, month, day);

  /// ISO weekday: Monday = 1 ... Sunday = 7.
  int get weekday => _utc.weekday;

  int get daysInThisMonth => daysInMonth(year, month);

  LocalDate addDays(int days) {
    final d = _utc.add(Duration(days: days));
    return LocalDate(d.year, d.month, d.day);
  }

  /// Adds [months] calendar months, clamping the day to the target month's
  /// length (Jan 31 + 1 month = Feb 28/29).
  LocalDate addMonths(int months) {
    final totalMonths = year * 12 + (month - 1) + months;
    final y = totalMonths ~/ 12;
    final m = totalMonths % 12 + 1;
    final d = day > daysInMonth(y, m) ? daysInMonth(y, m) : day;
    return LocalDate(y, m, d);
  }

  LocalDate addYears(int years) => addMonths(years * 12);

  /// Whole days from this date to [other] (positive when [other] is later).
  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  LocalDate get firstDayOfMonth => LocalDate(year, month, 1);

  LocalDate get lastDayOfMonth => LocalDate(year, month, daysThisMonthSafe);

  int get daysThisMonthSafe => daysInMonth(year, month);

  /// Start of the week containing this date. [firstWeekday] uses ISO numbers
  /// (1 = Monday, 7 = Sunday).
  LocalDate startOfWeek(int firstWeekday) {
    final diff = (weekday - firstWeekday + 7) % 7;
    return addDays(-diff);
  }

  /// Local midnight at the start of this date as a local [DateTime].
  DateTime get startOfDayLocal => DateTime(year, month, day);

  /// Local midnight at the start of the *next* date. Uses the calendar
  /// constructor so that 23/25 hour days around DST are handled correctly.
  DateTime get endOfDayLocalExclusive => DateTime(year, month, day + 1);

  /// Combines this date with minutes since midnight in local time.
  DateTime atMinutes(int minutesSinceMidnight) => DateTime(
    year,
    month,
    day,
    minutesSinceMidnight ~/ 60,
    minutesSinceMidnight % 60,
  );

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;
  bool isSameOrBefore(LocalDate other) => compareTo(other) <= 0;
  bool isSameOrAfter(LocalDate other) => compareTo(other) >= 0;

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// ISO-8601 `YYYY-MM-DD`; also the database storage format, so string
  /// ordering equals chronological ordering.
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  /// `YYYY-MM` month key.
  String get monthKey =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  @override
  String toString() => toIso();

  static LocalDate min(LocalDate a, LocalDate b) => a.isBefore(b) ? a : b;
  static LocalDate max(LocalDate a, LocalDate b) => a.isAfter(b) ? a : b;
}

/// Minutes since midnight helpers for "time of day" values.
class TimeOfDayMinutes {
  TimeOfDayMinutes._();

  static int of(int hour, int minute) => hour * 60 + minute;

  static String format24(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
