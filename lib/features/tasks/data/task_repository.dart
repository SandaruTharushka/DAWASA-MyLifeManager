import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/recurrence.dart';

enum TaskView { today, tomorrow, upcoming, completed, all }

enum TaskSort { dueDate, priority }

class TaskDraft {
  const TaskDraft({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTimeMinutes,
    this.priority = TaskPriority.medium,
    this.recurrence,
    this.reminderMinutesBefore = const [],
  });

  final String id;
  final String title;
  final String? description;
  final LocalDate? dueDate;
  final int? dueTimeMinutes;
  final TaskPriority priority;
  final RecurrenceRule? recurrence;

  /// Reminder offsets in minutes before the due time.
  final List<int> reminderMinutesBefore;
}

/// A task with its reminder offsets.
class TaskItem {
  const TaskItem(this.task, this.reminders);

  final TaskRow task;
  final List<int> reminders;

  bool isOverdue(LocalDate today, int nowMinutes) {
    final due = task.dueDate;
    if (task.isCompleted || due == null) return false;
    if (due.isBefore(today)) return true;
    return due == today &&
        task.dueTimeMinutes != null &&
        task.dueTimeMinutes! < nowMinutes;
  }
}

class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;

  static int _priorityRank(TaskPriority p) => switch (p) {
    TaskPriority.high => 0,
    TaskPriority.medium => 1,
    TaskPriority.low => 2,
  };

  /// Sorts tasks: overdue/earlier first (no date last), then priority.
  static List<TaskItem> sort(List<TaskItem> items, TaskSort sort) {
    int byDue(TaskItem a, TaskItem b) {
      final da = a.task.dueDate, db = b.task.dueDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      final c = da.compareTo(db);
      if (c != 0) return c;
      return (a.task.dueTimeMinutes ?? 24 * 60).compareTo(
        b.task.dueTimeMinutes ?? 24 * 60,
      );
    }

    int byPriority(TaskItem a, TaskItem b) =>
        _priorityRank(a.task.priority)
            .compareTo(_priorityRank(b.task.priority));

    final list = [...items];
    list.sort((a, b) {
      final first = sort == TaskSort.dueDate ? byDue(a, b) : byPriority(a, b);
      if (first != 0) return first;
      final second = sort == TaskSort.dueDate ? byPriority(a, b) : byDue(a, b);
      if (second != 0) return second;
      return a.task.createdAt.compareTo(b.task.createdAt);
    });
    return list;
  }

  /// Whether a task belongs to [view] on [today].
  static bool matches(TaskRow t, TaskView view, LocalDate today) {
    final due = t.dueDate;
    switch (view) {
      case TaskView.today:
        return !t.isCompleted && due != null && !due.isAfter(today);
      case TaskView.tomorrow:
        return !t.isCompleted && due == today.addDays(1);
      case TaskView.upcoming:
        return !t.isCompleted && due != null && due.isAfter(today.addDays(1));
      case TaskView.completed:
        return t.isCompleted;
      case TaskView.all:
        return true;
    }
  }

  Future<List<TaskItem>> _withReminders(List<TaskRow> rows) async {
    if (rows.isEmpty) return const [];
    final reminders = await (_db.select(
      _db.taskReminders,
    )..where((r) => r.taskId.isIn(rows.map((t) => t.id)))).get();
    final map = <String, List<int>>{};
    for (final r in reminders) {
      map.putIfAbsent(r.taskId, () => []).add(r.minutesBefore);
    }
    return [for (final t in rows) TaskItem(t, (map[t.id] ?? [])..sort())];
  }

  Stream<List<TaskItem>> watchAll() {
    final q = _db.select(_db.tasks);
    return q.watch().asyncMap(_withReminders);
  }

  Future<List<TaskItem>> all() async =>
      _withReminders(await _db.select(_db.tasks).get());

  Future<TaskItem?> byId(String id) async {
    final row = await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return (await _withReminders([row])).single;
  }

  /// Creates or updates a task. Creating the same draft twice is a no-op.
  Future<void> save(TaskDraft d) async {
    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.tasks,
      )..where((t) => t.id.equals(d.id))).getSingleOrNull();
      final companion = TasksCompanion.insert(
        id: Value(d.id),
        title: d.title.trim(),
        description: Value(
          (d.description?.trim().isEmpty ?? true)
              ? null
              : d.description!.trim(),
        ),
        dueDate: Value(d.dueDate),
        dueTimeMinutes: Value(d.dueDate == null ? null : d.dueTimeMinutes),
        priority: Value(d.priority),
        recurrence: Value(d.dueDate == null ? null : d.recurrence?.encode()),
        seriesId: Value(
          existing?.seriesId ?? (d.recurrence != null ? d.id : null),
        ),
        updatedAt: Value(nowUtc()),
      );
      if (existing == null) {
        await _db.into(_db.tasks).insert(companion);
      } else {
        await (_db.update(_db.tasks)..where((t) => t.id.equals(d.id))).write(
          companion.copyWith(
            createdAt: const Value.absent(),
            isCompleted: const Value.absent(),
            completedAt: const Value.absent(),
          ),
        );
      }
      await _replaceReminders(
        d.id,
        d.dueDate == null ? const [] : d.reminderMinutesBefore,
      );
    });
  }

  Future<void> _replaceReminders(String taskId, List<int> minutes) async {
    await (_db.delete(
      _db.taskReminders,
    )..where((r) => r.taskId.equals(taskId))).go();
    for (final m in minutes.toSet()) {
      await _db
          .into(_db.taskReminders)
          .insert(
            TaskRemindersCompanion.insert(
              taskId: taskId,
              minutesBefore: Value(m < 0 ? 0 : m),
            ),
          );
    }
  }

  /// Marks a task complete. For a recurring task the next occurrence is
  /// created (once) and returned.
  Future<TaskRow?> complete(String id, DateTime now) {
    return _db.transaction(() async {
      final item = await byId(id);
      if (item == null || item.task.isCompleted) return null;
      final t = item.task;
      await (_db.update(_db.tasks)..where((x) => x.id.equals(id))).write(
        TasksCompanion(
          isCompleted: const Value(true),
          completedAt: Value(now.toUtc()),
          updatedAt: Value(nowUtc()),
        ),
      );
      final rule = RecurrenceRule.decode(t.recurrence);
      if (rule == null || t.dueDate == null) return null;
      final seriesId = t.seriesId ?? t.id;
      // Next occurrence after the task's own due date, computed from the
      // series start so monthly tasks keep their day of month.
      final seriesStart = await _seriesStart(seriesId) ?? t.dueDate!;
      final next = rule.nextAfter(seriesStart, t.dueDate!);
      if (next == null) return null;
      final nextId = deterministicId('task:$seriesId:${next.toIso()}');
      await _db
          .into(_db.tasks)
          .insert(
            TasksCompanion.insert(
              id: Value(nextId),
              title: t.title,
              description: Value(t.description),
              dueDate: Value(next),
              dueTimeMinutes: Value(t.dueTimeMinutes),
              priority: Value(t.priority),
              recurrence: Value(t.recurrence),
              seriesId: Value(seriesId),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      final existingReminders = await (_db.select(
        _db.taskReminders,
      )..where((r) => r.taskId.equals(nextId))).get();
      if (existingReminders.isEmpty) {
        await _replaceReminders(nextId, item.reminders);
      }
      return (_db.select(
        _db.tasks,
      )..where((x) => x.id.equals(nextId))).getSingle();
    });
  }

  Future<LocalDate?> _seriesStart(String seriesId) async {
    final first =
        await (_db.select(_db.tasks)
              ..where(
                (t) => t.seriesId.equals(seriesId) | t.id.equals(seriesId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.dueDate)])
              ..limit(1))
            .getSingleOrNull();
    return first?.dueDate;
  }

  Future<void> reopen(String id) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isCompleted: const Value(false),
        completedAt: const Value(null),
        updatedAt: Value(nowUtc()),
      ),
    );
  }

  Future<void> delete(String id) =>
      (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();

  Future<int> deleteCompleted() =>
      (_db.delete(_db.tasks)..where((t) => t.isCompleted.equals(true))).go();
}
