import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/local_date.dart';
import '../../../core/utils/streams.dart';

class HabitDraft {
  const HabitDraft({
    required this.id,
    required this.name,
    required this.frequency,
    this.targetCount = 1,
    this.reminderMinutes,
    this.iconKey = 'star',
    this.colorValue = 0xFF0EA5E9,
  });

  final String id;
  final String name;
  final HabitFrequency frequency;
  final int targetCount;
  final int? reminderMinutes;
  final String iconKey;
  final int colorValue;
}

/// Streak statistics of a habit.
class HabitStats {
  const HabitStats({
    required this.current,
    required this.best,
    required this.doneInPeriod,
    required this.completedToday,
  });

  /// Consecutive completed days (daily) or weeks (weekly).
  final int current;
  final int best;

  /// Count logged today (daily) or this week (weekly).
  final int doneInPeriod;
  final bool completedToday;
}

/// Pure streak computation from per-day counts.
HabitStats computeHabitStats({
  required HabitFrequency frequency,
  required int target,
  required Map<LocalDate, int> counts,
  required LocalDate today,
  int firstWeekday = DateTime.monday,
}) {
  if (frequency == HabitFrequency.daily) {
    bool done(LocalDate d) => (counts[d] ?? 0) >= target;
    final doneToday = done(today);
    // A streak stays alive until the end of today.
    var cursor = doneToday ? today : today.addDays(-1);
    var current = 0;
    while (done(cursor)) {
      current++;
      cursor = cursor.addDays(-1);
    }
    var best = 0, run = 0;
    final days = counts.keys.toList()..sort();
    if (days.isNotEmpty) {
      for (var d = days.first; !d.isAfter(today); d = d.addDays(1)) {
        if (done(d)) {
          run++;
          if (run > best) best = run;
        } else {
          run = 0;
        }
      }
    }
    return HabitStats(
      current: current,
      best: best < current ? current : best,
      doneInPeriod: counts[today] ?? 0,
      completedToday: doneToday,
    );
  }

  // Weekly.
  int weekTotal(LocalDate weekStart) {
    var total = 0;
    for (var i = 0; i < 7; i++) {
      total += counts[weekStart.addDays(i)] ?? 0;
    }
    return total;
  }

  final thisWeek = today.startOfWeek(firstWeekday);
  final doneThisWeek = weekTotal(thisWeek) >= target;
  var cursor = doneThisWeek ? thisWeek : thisWeek.addDays(-7);
  var current = 0;
  while (weekTotal(cursor) >= target) {
    current++;
    cursor = cursor.addDays(-7);
  }
  var best = 0, run = 0;
  final days = counts.keys.toList()..sort();
  if (days.isNotEmpty) {
    for (
      var w = days.first.startOfWeek(firstWeekday);
      !w.isAfter(thisWeek);
      w = w.addDays(7)
    ) {
      if (weekTotal(w) >= target) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
    }
  }
  return HabitStats(
    current: current,
    best: best < current ? current : best,
    doneInPeriod: weekTotal(thisWeek),
    completedToday: doneThisWeek,
  );
}

class HabitView {
  const HabitView(this.habit, this.counts);

  final HabitRow habit;

  /// Logged counts per day (recent history).
  final Map<LocalDate, int> counts;

  HabitStats stats(LocalDate today, int firstWeekday) => computeHabitStats(
    frequency: habit.frequency,
    target: habit.targetCount,
    counts: counts,
    today: today,
    firstWeekday: firstWeekday,
  );
}

/// Habits are fully separate from money: nothing here touches transactions.
class HabitRepository {
  HabitRepository(this._db);

  final AppDatabase _db;

  Future<List<HabitView>> _views(List<HabitRow> habits) async {
    if (habits.isEmpty) return const [];
    final logs = await (_db.select(
      _db.habitLogs,
    )..where((l) => l.habitId.isIn(habits.map((h) => h.id)))).get();
    final map = <String, Map<LocalDate, int>>{};
    for (final l in logs) {
      map.putIfAbsent(l.habitId, () => {})[l.date] = l.count;
    }
    return [for (final h in habits) HabitView(h, map[h.id] ?? const {})];
  }

  Stream<List<HabitView>> watchHabits() {
    final habits = _db.select(_db.habits)
      ..where((h) => h.isArchived.equals(false))
      ..orderBy([
        (h) => OrderingTerm.asc(h.sortOrder),
        (h) => OrderingTerm.asc(h.createdAt),
      ]);
    return watchComputed(_db, [
      _db.habits,
      _db.habitLogs,
    ], () async => _views(await habits.get()));
  }

  Future<List<HabitView>> habits() async {
    final rows = await (_db.select(
      _db.habits,
    )..where((h) => h.isArchived.equals(false))).get();
    return _views(rows);
  }

  Future<HabitRow?> byId(String id) =>
      (_db.select(_db.habits)..where((h) => h.id.equals(id))).getSingleOrNull();

  Future<void> save(HabitDraft d) async {
    final companion = HabitsCompanion.insert(
      id: Value(d.id),
      name: d.name.trim(),
      frequency: d.frequency,
      targetCount: Value(d.targetCount.clamp(1, 99)),
      reminderMinutes: Value(d.reminderMinutes),
      iconKey: Value(d.iconKey),
      colorValue: Value(d.colorValue),
      updatedAt: Value(nowUtc()),
    );
    if (await byId(d.id) == null) {
      await _db.into(_db.habits).insert(companion);
    } else {
      await (_db.update(_db.habits)..where((h) => h.id.equals(d.id))).write(
        companion.copyWith(createdAt: const Value.absent()),
      );
    }
  }

  Future<void> delete(String id) =>
      (_db.delete(_db.habits)..where((h) => h.id.equals(id))).go();

  /// Sets the count logged on [date] (0 removes the log).
  Future<void> setCount(String habitId, LocalDate date, int count) async {
    if (count <= 0) {
      await (_db.delete(
            _db.habitLogs,
          )..where((l) => l.habitId.equals(habitId) & l.date.equalsValue(date)))
          .go();
      return;
    }
    await _db
        .into(_db.habitLogs)
        .insert(
          HabitLogsCompanion.insert(
            id: Value(deterministicId('habit:$habitId:${date.toIso()}')),
            habitId: habitId,
            date: date,
            count: Value(count),
          ),
          onConflict: DoUpdate(
            (old) => HabitLogsCompanion(count: Value(count)),
            target: [_db.habitLogs.habitId, _db.habitLogs.date],
          ),
        );
  }

  Future<int> countOn(String habitId, LocalDate date) async {
    final row =
        await (_db.select(_db.habitLogs)..where(
              (l) => l.habitId.equals(habitId) & l.date.equalsValue(date),
            ))
            .getSingleOrNull();
    return row?.count ?? 0;
  }
}
