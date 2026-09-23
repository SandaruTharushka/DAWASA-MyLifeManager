import 'local_date.dart';

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

/// A small, well-defined subset of RFC 5545 recurrence rules.
///
/// Stored in the database as a compact string such as
/// `FREQ=MONTHLY;INTERVAL=1` or `FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,TH`.
///
/// Occurrences are always computed from the series start date (never by
/// repeatedly adding to the previous occurrence), so a monthly series that
/// starts on the 31st clamps to Feb 28/29 and returns to the 31st in March
/// instead of drifting.
class RecurrenceRule {
  RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    Set<int>? weekdays,
    this.until,
    this.count,
  }) : weekdays = Set.unmodifiable(weekdays ?? const <int>{}) {
    if (interval < 1) throw ArgumentError.value(interval, 'interval');
    if (count != null && count! < 1) throw ArgumentError.value(count, 'count');
    for (final w in this.weekdays) {
      if (w < 1 || w > 7) throw ArgumentError.value(w, 'weekday');
    }
  }

  factory RecurrenceRule.daily({int interval = 1}) =>
      RecurrenceRule(frequency: RecurrenceFrequency.daily, interval: interval);

  factory RecurrenceRule.weekly({int interval = 1, Set<int>? weekdays}) =>
      RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: interval,
        weekdays: weekdays,
      );

  factory RecurrenceRule.monthly({int interval = 1}) => RecurrenceRule(
    frequency: RecurrenceFrequency.monthly,
    interval: interval,
  );

  factory RecurrenceRule.yearly({int interval = 1}) =>
      RecurrenceRule(frequency: RecurrenceFrequency.yearly, interval: interval);

  final RecurrenceFrequency frequency;

  /// Repeat every [interval] units of [frequency].
  final int interval;

  /// ISO weekdays (1 = Monday) for weekly rules. Empty means "same weekday as
  /// the start date".
  final Set<int> weekdays;

  /// Last allowed occurrence date (inclusive).
  final LocalDate? until;

  /// Maximum number of occurrences.
  final int? count;

  static const _dayCodes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  String encode() {
    final parts = <String>[
      'FREQ=${frequency.name.toUpperCase()}',
      'INTERVAL=$interval',
    ];
    if (weekdays.isNotEmpty && frequency == RecurrenceFrequency.weekly) {
      final sorted = weekdays.toList()..sort();
      parts.add('BYDAY=${sorted.map((d) => _dayCodes[d - 1]).join(',')}');
    }
    if (until != null) parts.add('UNTIL=${until!.toIso()}');
    if (count != null) parts.add('COUNT=$count');
    return parts.join(';');
  }

  static RecurrenceRule? decode(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final map = <String, String>{};
    for (final part in value.split(';')) {
      final idx = part.indexOf('=');
      if (idx <= 0) continue;
      map[part.substring(0, idx).trim().toUpperCase()] =
          part.substring(idx + 1).trim();
    }
    final freqName = map['FREQ']?.toLowerCase();
    final freq = RecurrenceFrequency.values
        .where((f) => f.name == freqName)
        .firstOrNull;
    if (freq == null) return null;
    final interval = int.tryParse(map['INTERVAL'] ?? '1') ?? 1;
    final days = <int>{};
    final byDay = map['BYDAY'];
    if (byDay != null && byDay.isNotEmpty) {
      for (final code in byDay.split(',')) {
        final idx = _dayCodes.indexOf(code.trim().toUpperCase());
        if (idx >= 0) days.add(idx + 1);
      }
    }
    try {
      return RecurrenceRule(
        frequency: freq,
        interval: interval < 1 ? 1 : interval,
        weekdays: days,
        until: LocalDate.tryParse(map['UNTIL']),
        count: int.tryParse(map['COUNT'] ?? ''),
      );
    } on ArgumentError {
      return null;
    }
  }

  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    Set<int>? weekdays,
    LocalDate? until,
    bool clearUntil = false,
    int? count,
    bool clearCount = false,
  }) => RecurrenceRule(
    frequency: frequency ?? this.frequency,
    interval: interval ?? this.interval,
    weekdays: weekdays ?? this.weekdays,
    until: clearUntil ? null : (until ?? this.until),
    count: clearCount ? null : (count ?? this.count),
  );

  /// Enumerates occurrences of a series starting at [start], in order.
  ///
  /// [start] itself is the first occurrence (for weekly rules with explicit
  /// [weekdays], the first matching day on/after [start]). Iteration stops at
  /// [until], after [count] occurrences, or after [maxIterations] candidates
  /// as a safety net.
  Iterable<LocalDate> occurrences(
    LocalDate start, {
    int maxIterations = 100000,
  }) sync* {
    var produced = 0;
    var iterations = 0;
    bool withinLimits(LocalDate d) {
      if (until != null && d.isAfter(until!)) return false;
      if (count != null && produced >= count!) return false;
      return true;
    }

    switch (frequency) {
      case RecurrenceFrequency.daily:
        for (var i = 0; iterations++ < maxIterations; i++) {
          final d = start.addDays(i * interval);
          if (!withinLimits(d)) return;
          produced++;
          yield d;
        }
      case RecurrenceFrequency.weekly:
        final days = weekdays.isEmpty ? {start.weekday} : weekdays;
        final sortedDays = days.toList()..sort();
        // Anchor week starts on Monday of the start week.
        final weekStart = start.startOfWeek(1);
        for (var week = 0; iterations < maxIterations; week++) {
          final base = weekStart.addDays(week * 7 * interval);
          for (final wd in sortedDays) {
            iterations++;
            final d = base.addDays(wd - 1);
            if (d.isBefore(start)) continue;
            if (!withinLimits(d)) return;
            produced++;
            yield d;
          }
        }
      case RecurrenceFrequency.monthly:
        for (var i = 0; iterations++ < maxIterations; i++) {
          final d = start.addMonths(i * interval);
          if (!withinLimits(d)) return;
          produced++;
          yield d;
        }
      case RecurrenceFrequency.yearly:
        for (var i = 0; iterations++ < maxIterations; i++) {
          final d = start.addYears(i * interval);
          if (!withinLimits(d)) return;
          produced++;
          yield d;
        }
    }
  }

  /// First occurrence strictly after [after], or `null` when the series has
  /// ended.
  LocalDate? nextAfter(LocalDate start, LocalDate after) {
    for (final d in occurrences(start)) {
      if (d.isAfter(after)) return d;
    }
    return null;
  }

  /// First occurrence on or after [date], or `null`.
  LocalDate? nextOnOrAfter(LocalDate start, LocalDate date) =>
      nextAfter(start, date.addDays(-1));

  /// Occurrences within `[from, to]` (inclusive).
  List<LocalDate> between(LocalDate start, LocalDate from, LocalDate to) {
    final result = <LocalDate>[];
    for (final d in occurrences(start)) {
      if (d.isAfter(to)) break;
      if (!d.isBefore(from)) result.add(d);
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule && other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;

  @override
  String toString() => encode();
}
