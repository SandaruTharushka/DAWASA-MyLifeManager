import 'package:intl/intl.dart';

import '../../core/l10n/l10n.dart';
import '../../core/time/local_date.dart';

/// User selectable date display formats.
enum DateDisplayFormat {
  dayMonthYear('dd/MM/yyyy'),
  monthDayYear('MM/dd/yyyy'),
  iso('yyyy-MM-dd'),
  medium('d MMM yyyy');

  const DateDisplayFormat(this.pattern);

  final String pattern;

  static DateDisplayFormat fromName(String? name) =>
      DateDisplayFormat.values.where((f) => f.name == name).firstOrNull ??
      DateDisplayFormat.medium;
}

/// Locale-aware date and time formatting.
class AppDateFormatter {
  AppDateFormatter({required this.localeName, required this.format});

  final String localeName;
  final DateDisplayFormat format;

  String date(LocalDate date) =>
      DateFormat(format.pattern, localeName).format(date.startOfDayLocal);

  String dateTime(DateTime instant) {
    final local = instant.toLocal();
    return '${date(LocalDate.fromDateTime(local))} ${time(local)}';
  }

  String time(DateTime local) => DateFormat.jm(localeName).format(local);

  String timeOfDay(int minutes) =>
      time(DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60));

  /// "Mon, 5 Jan" style short label.
  String shortDay(LocalDate date) =>
      DateFormat('EEE, d MMM', localeName).format(date.startOfDayLocal);

  /// Full "Monday, 5 January 2026" style label for headers.
  String fullDay(LocalDate date) =>
      DateFormat('EEEE, d MMMM y', localeName).format(date.startOfDayLocal);

  String weekdayShort(LocalDate date) =>
      DateFormat('EEE', localeName).format(date.startOfDayLocal);

  String monthYear(LocalDate date) =>
      DateFormat('MMMM y', localeName).format(date.startOfDayLocal);

  String monthShort(LocalDate date) =>
      DateFormat('MMM', localeName).format(date.startOfDayLocal);

  String dayMonth(LocalDate date) =>
      DateFormat('d MMM', localeName).format(date.startOfDayLocal);

  /// "Today", "Yesterday", "Tomorrow" or the formatted date.
  String relativeDay(LocalDate date, LocalDate today, AppLocalizations l10n) {
    final diff = today.daysUntil(date);
    if (diff == 0) return l10n.commonToday;
    if (diff == -1) return l10n.commonYesterday;
    if (diff == 1) return l10n.commonTomorrow;
    return shortDay(date);
  }
}
