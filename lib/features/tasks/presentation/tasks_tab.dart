import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/recurrence.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../data/task_repository.dart';
import 'task_providers.dart';

extension TaskLabels on AppLocalizations {
  String priorityLabel(TaskPriority p) => switch (p) {
    TaskPriority.low => taskPriorityLow,
    TaskPriority.medium => taskPriorityMedium,
    TaskPriority.high => taskPriorityHigh,
  };

  String taskViewLabel(TaskView v) => switch (v) {
    TaskView.today => taskViewToday,
    TaskView.tomorrow => taskViewTomorrow,
    TaskView.upcoming => taskViewUpcoming,
    TaskView.completed => taskViewCompleted,
    TaskView.all => taskViewAll,
  };
}

Color priorityColor(BuildContext context, TaskPriority p) => switch (p) {
  TaskPriority.high => context.semantic.expense,
  TaskPriority.medium => context.semantic.warning,
  TaskPriority.low => context.semantic.neutral,
};

/// Completes a task and reports the next repeat, if any.
Future<void> completeTask(
  BuildContext context,
  WidgetRef ref,
  TaskItem item,
) async {
  final l10n = context.l10n;
  final formatter = ref.read(dateFormatterProvider);
  final repo = ref.read(taskRepositoryProvider);
  final next = await repo.complete(item.task.id, ref.read(clockProvider)());
  if (!context.mounted) return;
  showAppSnackBar(
    context,
    next?.dueDate != null
        ? l10n.taskNextCreated(formatter.date(next!.dueDate!))
        : l10n.taskCompleted,
    action: SnackBarAction(
      label: l10n.actionUndo,
      onPressed: () async {
        await repo.reopen(item.task.id);
        if (next != null) await repo.delete(next.id);
      },
    ),
  );
}

class TasksTab extends ConsumerStatefulWidget {
  const TasksTab({super.key});

  @override
  ConsumerState<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<TasksTab> {
  TaskView _view = TaskView.today;
  TaskSort _sort = TaskSort.dueDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = ref.watch(todayProvider);
    final async = ref.watch(allTasksProvider);
    return AsyncValueView(
      value: async,
      data: (all) {
        final items = TaskRepository.sort(
          all
              .where((i) => TaskRepository.matches(i.task, _view, today))
              .toList(),
          _sort,
        );
        if (_view == TaskView.all) {
          items.sort((a, b) {
            if (a.task.isCompleted == b.task.isCompleted) return 0;
            return a.task.isCompleted ? 1 : -1;
          });
        }
        final now = ref.read(clockProvider)();
        final nowMinutes = now.hour * 60 + now.minute;
        final overdue = items
            .where((i) => i.isOverdue(today, nowMinutes))
            .toList();
        final rest = items.where((i) => !overdue.contains(i)).toList();
        return PageBody(
          children: [
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final v in TaskView.values)
                          Padding(
                            padding: const EdgeInsets.only(right: Gap.sm),
                            child: ChoiceChip(
                              label: Text(l10n.taskViewLabel(v)),
                              selected: _view == v,
                              onSelected: (_) => setState(() => _view = v),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<Object>(
                  tooltip: l10n.actionFilter,
                  icon: const Icon(Icons.sort_rounded),
                  onSelected: (v) async {
                    if (v is TaskSort) {
                      setState(() => _sort = v);
                    } else if (v == 'clear') {
                      await ref.read(taskRepositoryProvider).deleteCompleted();
                    }
                  },
                  itemBuilder: (context) => [
                    CheckedPopupMenuItem(
                      value: TaskSort.dueDate,
                      checked: _sort == TaskSort.dueDate,
                      child: Text(l10n.taskSortDue),
                    ),
                    CheckedPopupMenuItem(
                      value: TaskSort.priority,
                      checked: _sort == TaskSort.priority,
                      child: Text(l10n.taskSortPriority),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'clear',
                      child: Text(l10n.taskClearCompleted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Gap.sm),
            if (items.isEmpty)
              EmptyState(
                icon: _view == TaskView.today
                    ? Icons.wb_sunny_outlined
                    : Icons.task_alt_rounded,
                message: _view == TaskView.today
                    ? l10n.taskEmptyToday
                    : l10n.taskEmpty,
                actionLabel: _view == TaskView.completed ? null : l10n.taskAdd,
                onAction: () => context.push(Routes.newTask),
              ),
            if (overdue.isNotEmpty) ...[
              SectionHeader(title: l10n.taskOverdue),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                child: Column(
                  children: [for (final i in overdue) TaskTile(item: i)],
                ),
              ),
            ],
            if (rest.isNotEmpty) ...[
              if (overdue.isNotEmpty)
                SectionHeader(title: l10n.taskViewLabel(_view)),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                child: Column(
                  children: [for (final i in rest) TaskTile(item: i)],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.item, this.compact = false});

  final TaskItem item;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = item.task;
    final today = ref.watch(todayProvider);
    final formatter = ref.watch(dateFormatterProvider);
    final now = ref.read(clockProvider)();
    final overdue = item.isOverdue(today, now.hour * 60 + now.minute);
    final subtitle = <String>[
      if (t.dueDate != null) formatter.relativeDay(t.dueDate!, today, l10n),
      if (t.dueDate != null && t.dueTimeMinutes != null)
        formatter.timeOfDay(t.dueTimeMinutes!),
      if (t.recurrence != null)
        RecurrenceRule.decode(t.recurrence) == null ? '' : '↻',
    ].where((s) => s.isNotEmpty).join(' · ');
    return ListTile(
      onTap: () => context.push(Routes.editTask(t.id)),
      leading: Checkbox(
        value: t.isCompleted,
        semanticLabel: t.isCompleted ? l10n.taskMarkNotDone : l10n.taskMarkDone,
        onChanged: (v) async {
          if (v ?? false) {
            await completeTask(context, ref, item);
          } else {
            await ref.read(taskRepositoryProvider).reopen(t.id);
          }
        },
      ),
      title: Text(
        t.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.titleSmall?.copyWith(
          decoration: t.isCompleted ? TextDecoration.lineThrough : null,
          color: t.isCompleted ? context.colors.onSurfaceVariant : null,
        ),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              style: TextStyle(
                color: overdue ? context.semantic.expense : null,
                fontWeight: overdue ? FontWeight.w600 : null,
              ),
            ),
      trailing: compact || t.isCompleted
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.reminders.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: Gap.xs),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      size: 18,
                      semanticLabel: l10n.taskReminder,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                StatusChip(
                  label: l10n.priorityLabel(t.priority),
                  color: priorityColor(context, t.priority),
                  background: priorityColor(
                    context,
                    t.priority,
                  ).withValues(alpha: 0.12),
                ),
              ],
            ),
    );
  }
}

/// Helper used by the form to label reminder offsets.
String reminderLabel(int minutes, AppLocalizations l10n) {
  if (minutes == 0) return l10n.taskReminderAtTime;
  if (minutes % (24 * 60) == 0) {
    return l10n.taskReminderDays(minutes ~/ (24 * 60));
  }
  if (minutes % 60 == 0) return l10n.taskReminderHours(minutes ~/ 60);
  return l10n.taskReminderMinutes(minutes);
}

/// For the "Today" count on the dashboard.
int pendingToday(List<TaskItem> items, LocalDate today) => items
    .where((i) => TaskRepository.matches(i.task, TaskView.today, today))
    .length;
