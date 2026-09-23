import 'package:dawasa/core/time/date_range.dart';
import 'package:dawasa/core/time/local_date.dart';
import 'package:dawasa/core/time/recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> iso(Iterable<LocalDate> dates) =>
    dates.map((d) => d.toIso()).toList();

void main() {
  group('LocalDate', () {
    test('validates dates including leap years', () {
      expect(LocalDate(2024, 2, 29).toIso(), '2024-02-29');
      expect(() => LocalDate(2025, 2, 29), throwsArgumentError);
      expect(LocalDate.isLeapYear(2000), isTrue);
      expect(LocalDate.isLeapYear(1900), isFalse);
    });

    test('adds months with month-end clamping', () {
      expect(LocalDate(2026, 1, 31).addMonths(1).toIso(), '2026-02-28');
      expect(LocalDate(2028, 1, 31).addMonths(1).toIso(), '2028-02-29');
      expect(LocalDate(2026, 3, 31).addMonths(-1).toIso(), '2026-02-28');
      expect(LocalDate(2026, 12, 15).addMonths(1).toIso(), '2027-01-15');
      expect(LocalDate(2024, 2, 29).addYears(1).toIso(), '2025-02-28');
    });

    test('day arithmetic is independent of DST', () {
      // 400 days in steps never drifts by an hour.
      var d = LocalDate(2026, 1, 1);
      for (var i = 0; i < 400; i++) {
        d = d.addDays(1);
      }
      expect(d.toIso(), '2027-02-05');
      expect(LocalDate(2026, 3, 1).daysUntil(LocalDate(2026, 4, 1)), 31);
    });

    test('start of week honours the chosen first weekday', () {
      final wed = LocalDate(2026, 9, 23); // Wednesday
      expect(wed.weekday, 3);
      expect(wed.startOfWeek(1).toIso(), '2026-09-21');
      expect(wed.startOfWeek(7).toIso(), '2026-09-20');
    });

    test('parse and ordering', () {
      expect(LocalDate.parse('2026-09-23'), LocalDate(2026, 9, 23));
      expect(LocalDate.tryParse('nope'), isNull);
      expect(LocalDate(2026, 1, 2).isAfter(LocalDate(2026, 1, 1)), isTrue);
      expect('2026-01-10'.compareTo('2026-02-01') < 0, isTrue);
    });
  });

  group('DateRange', () {
    final today = LocalDate(2026, 3, 18);

    test('presets resolve to the expected ranges', () {
      expect(RangePreset.today.resolve(today), DateRange.singleDay(today));
      expect(
        RangePreset.yesterday.resolve(today),
        DateRange.singleDay(LocalDate(2026, 3, 17)),
      );
      expect(
        RangePreset.last7Days.resolve(today),
        DateRange(LocalDate(2026, 3, 12), today),
      );
      expect(
        RangePreset.thisMonth.resolve(today),
        DateRange(LocalDate(2026, 3, 1), LocalDate(2026, 3, 31)),
      );
      expect(
        RangePreset.lastMonth.resolve(today),
        DateRange(LocalDate(2026, 2, 1), LocalDate(2026, 2, 28)),
      );
    });

    test('months of different lengths', () {
      expect(DateRange.month(2026, 2).lengthInDays, 28);
      expect(DateRange.month(2028, 2).lengthInDays, 29);
      expect(DateRange.month(2026, 4).lengthInDays, 30);
      expect(DateRange.month(2026, 1).lengthInDays, 31);
    });
  });

  group('RecurrenceRule', () {
    test('monthly on the 31st clamps and recovers', () {
      final rule = RecurrenceRule.monthly();
      final dates = rule.occurrences(LocalDate(2026, 1, 31)).take(5);
      expect(iso(dates), [
        '2026-01-31',
        '2026-02-28',
        '2026-03-31',
        '2026-04-30',
        '2026-05-31',
      ]);
    });

    test('yearly on Feb 29', () {
      final dates = RecurrenceRule.yearly()
          .occurrences(LocalDate(2024, 2, 29))
          .take(5);
      expect(iso(dates), [
        '2024-02-29',
        '2025-02-28',
        '2026-02-28',
        '2027-02-28',
        '2028-02-29',
      ]);
    });

    test('weekly with selected weekdays and interval', () {
      final rule = RecurrenceRule.weekly(interval: 2, weekdays: {1, 4});
      // 2026-09-23 is a Wednesday: first match is Thursday of the same week.
      final dates = rule.occurrences(LocalDate(2026, 9, 23)).take(4);
      expect(iso(dates), [
        '2026-09-24',
        '2026-10-05',
        '2026-10-08',
        '2026-10-19',
      ]);
    });

    test('daily interval, count and until limits', () {
      final counted = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 3,
        count: 3,
      ).occurrences(LocalDate(2026, 1, 1));
      expect(iso(counted), ['2026-01-01', '2026-01-04', '2026-01-07']);

      final until = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        until: LocalDate(2026, 1, 20),
      ).occurrences(LocalDate(2026, 1, 1));
      expect(iso(until), ['2026-01-01', '2026-01-08', '2026-01-15']);
    });

    test('nextAfter and between', () {
      final rule = RecurrenceRule.monthly();
      final start = LocalDate(2026, 1, 15);
      expect(
        rule.nextAfter(start, LocalDate(2026, 3, 15)),
        LocalDate(2026, 4, 15),
      );
      expect(
        rule.nextOnOrAfter(start, LocalDate(2026, 3, 15)),
        LocalDate(2026, 3, 15),
      );
      expect(
        iso(rule.between(start, LocalDate(2026, 2, 1), LocalDate(2026, 4, 30))),
        ['2026-02-15', '2026-03-15', '2026-04-15'],
      );
    });

    test('encode/decode round trip', () {
      final rules = [
        RecurrenceRule.daily(),
        RecurrenceRule.weekly(interval: 2, weekdays: {1, 3, 5}),
        RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 3,
          until: LocalDate(2027, 1, 1),
        ),
        RecurrenceRule(frequency: RecurrenceFrequency.yearly, count: 4),
      ];
      for (final r in rules) {
        expect(RecurrenceRule.decode(r.encode()), r);
      }
      expect(
        RecurrenceRule.weekly(interval: 2, weekdays: {5, 1}).encode(),
        'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,FR',
      );
      expect(RecurrenceRule.decode(''), isNull);
      expect(RecurrenceRule.decode('FREQ=HOURLY'), isNull);
    });
  });
}
