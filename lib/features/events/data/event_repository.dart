import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/recurrence.dart';

class EventDraft {
  const EventDraft({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    this.timeMinutes,
    this.recurrence,
    this.remindDaysBefore,
    this.remindAtMinutes = 9 * 60,
    this.budgetMinor,
    this.note,
  });

  final String id;
  final String title;
  final EventType type;
  final LocalDate date;
  final int? timeMinutes;
  final RecurrenceRule? recurrence;
  final int? remindDaysBefore;
  final int remindAtMinutes;
  final int? budgetMinor;
  final String? note;
}

/// An event with its next occurrence.
class EventView {
  const EventView(this.event, this.next);

  final PersonalEventRow event;

  /// Next occurrence on/after today, or null when the event is over.
  final LocalDate? next;

  RecurrenceRule? get rule => RecurrenceRule.decode(event.recurrence);

  /// Years since the first date at the next occurrence (birthdays,
  /// anniversaries).
  int? get yearsAtNext {
    if (next == null || rule?.frequency != RecurrenceFrequency.yearly) {
      return null;
    }
    final years = next!.year - event.date.year;
    return years > 0 ? years : null;
  }

  static EventView of(PersonalEventRow e, LocalDate today) {
    final rule = RecurrenceRule.decode(e.recurrence);
    final next = rule == null
        ? (e.date.isBefore(today) ? null : e.date)
        : rule.nextOnOrAfter(e.date, today);
    return EventView(e, next);
  }

  /// Occurrences within a month (for the calendar).
  List<LocalDate> occurrencesIn(int year, int month) {
    final first = LocalDate(year, month, 1);
    final last = first.lastDayOfMonth;
    final r = rule;
    if (r == null) {
      return (!event.date.isBefore(first) && !event.date.isAfter(last))
          ? [event.date]
          : const [];
    }
    return r.between(event.date, first, last);
  }
}

class EventRepository {
  EventRepository(this._db);

  final AppDatabase _db;

  Stream<List<PersonalEventRow>> watchAll() => (_db.select(
    _db.personalEvents,
  )..orderBy([(e) => OrderingTerm.asc(e.date)])).watch();

  Future<List<PersonalEventRow>> all() => _db.select(_db.personalEvents).get();

  Future<PersonalEventRow?> byId(String id) => (_db.select(
    _db.personalEvents,
  )..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<void> save(EventDraft d) async {
    final companion = PersonalEventsCompanion.insert(
      id: Value(d.id),
      title: d.title.trim(),
      type: d.type,
      date: d.date,
      timeMinutes: Value(d.timeMinutes),
      recurrence: Value(d.recurrence?.encode()),
      remindDaysBefore: Value(d.remindDaysBefore),
      remindAtMinutes: Value(d.remindAtMinutes),
      budgetMinor: Value(d.budgetMinor),
      note: Value((d.note?.trim().isEmpty ?? true) ? null : d.note!.trim()),
      updatedAt: Value(nowUtc()),
    );
    if (await byId(d.id) == null) {
      await _db.into(_db.personalEvents).insert(companion);
    } else {
      await (_db.update(_db.personalEvents)..where((e) => e.id.equals(d.id)))
          .write(companion.copyWith(createdAt: const Value.absent()));
    }
  }

  Future<void> delete(String id) =>
      (_db.delete(_db.personalEvents)..where((e) => e.id.equals(id))).go();
}
