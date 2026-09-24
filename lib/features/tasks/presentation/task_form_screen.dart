import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/providers.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/recurrence.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/form_widgets.dart';
import '../../../ui/widgets/recurrence_editor.dart';
import '../../security/app_lock.dart';
import '../data/task_repository.dart';
import 'task_providers.dart';
import 'tasks_tab.dart';

const _reminderChoices = [0, 10, 30, 60, 120, 24 * 60];

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.taskId, this.initialDate});

  final String? taskId;
  final LocalDate? initialDate;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  late final String _id = widget.taskId ?? newId();
  late LocalDate? _dueDate = widget.initialDate ?? ref.read(todayProvider);
  int? _dueTime;
  TaskPriority _priority = TaskPriority.medium;
  RecurrenceRule? _repeat;
  Set<int> _reminders = {};
  bool _loading = false;
  bool _completed = false;

  bool get _isEdit => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final item = await ref.read(taskRepositoryProvider).byId(widget.taskId!);
    if (!mounted) return;
    if (item == null) {
      context.pop();
      return;
    }
    final t = item.task;
    setState(() {
      _title.text = t.title;
      _description.text = t.description ?? '';
      _dueDate = t.dueDate;
      _dueTime = t.dueTimeMinutes;
      _priority = t.priority;
      _repeat = RecurrenceRule.decode(t.recurrence);
      _reminders = item.reminders.toSet();
      _completed = t.isCompleted;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reminders.isNotEmpty) {
      // Ask for notification permission only when a reminder is used.
      final gateway = ref.read(notificationGatewayProvider);
      if (!await gateway.areNotificationsEnabled()) {
        final granted = await ref
            .read(appLockProvider.notifier)
            .whileExternal(gateway.requestPermission);
        await ref
            .read(preferencesProvider.notifier)
            .update((p) => p.copyWith(notificationsEnabled: granted));
      }
    }
    await ref
        .read(taskRepositoryProvider)
        .save(
          TaskDraft(
            id: _id,
            title: _title.text,
            description: _description.text,
            dueDate: _dueDate,
            dueTimeMinutes: _dueTime,
            priority: _priority,
            recurrence: _repeat,
            reminderMinutesBefore: _reminders.toList(),
          ),
        );
    if (!mounted) return;
    showAppSnackBar(context, context.l10n.feedbackSaved);
    context.pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l10n.taskDeleteTitle,
      message: l10n.confirmDeleteMessage,
      confirmLabel: l10n.actionDelete,
      destructive: true,
    );
    if (!ok) return;
    await ref.read(taskRepositoryProvider).delete(_id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.taskEdit : l10n.taskAdd),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: l10n.actionDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: PageBody(
                children: [
                  TextFormField(
                    controller: _title,
                    autofocus: !_isEdit,
                    maxLength: 120,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.taskTitle,
                      hintText: l10n.taskTitleHint,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : null,
                  ),
                  TextFormField(
                    controller: _description,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.taskDescription,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: Gap.md),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DateField(
                          label: l10n.taskDueDate,
                          value: _dueDate,
                          clearable: true,
                          onChanged: (d) => setState(() {
                            _dueDate = d;
                            if (d == null) {
                              _dueTime = null;
                              _repeat = null;
                              _reminders = {};
                            }
                          }),
                        ),
                      ),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        flex: 2,
                        child: TimeField(
                          label: l10n.taskDueTime,
                          value: _dueTime,
                          clearable: true,
                          onChanged: (m) => setState(() {
                            _dueTime = m;
                            if (_dueDate == null && m != null) {
                              _dueDate = ref.read(todayProvider);
                            }
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.lg),
                  Text(l10n.taskPriority, style: context.textTheme.labelLarge),
                  const SizedBox(height: Gap.sm),
                  SegmentedButton<TaskPriority>(
                    segments: [
                      for (final p in TaskPriority.values)
                        ButtonSegment(
                          value: p,
                          label: Text(l10n.priorityLabel(p)),
                          icon: Icon(
                            Icons.flag_rounded,
                            color: priorityColor(context, p),
                          ),
                        ),
                    ],
                    selected: {_priority},
                    onSelectionChanged: (s) =>
                        setState(() => _priority = s.first),
                  ),
                  const SizedBox(height: Gap.lg),
                  Text(l10n.taskReminder, style: context.textTheme.labelLarge),
                  const SizedBox(height: Gap.sm),
                  if (_dueDate == null)
                    Text(
                      l10n.taskReminderNeedsDate,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    )
                  else
                    Wrap(
                      spacing: Gap.sm,
                      runSpacing: Gap.sm,
                      children: [
                        for (final m in _reminderChoices)
                          FilterChip(
                            label: Text(reminderLabel(m, l10n)),
                            selected: _reminders.contains(m),
                            onSelected: (on) => setState(() {
                              _reminders = {..._reminders};
                              on ? _reminders.add(m) : _reminders.remove(m);
                            }),
                          ),
                      ],
                    ),
                  if (_dueDate != null) ...[
                    const SizedBox(height: Gap.lg),
                    Text(
                      l10n.commonRepeat,
                      style: context.textTheme.labelLarge,
                    ),
                    const SizedBox(height: Gap.sm),
                    RecurrenceEditor(
                      value: _repeat,
                      startDate: _dueDate!,
                      onChanged: (r) => setState(() => _repeat = r),
                    ),
                  ],
                  const SizedBox(height: Gap.xl),
                  SubmitButton(
                    label: l10n.actionSave,
                    icon: Icons.check_rounded,
                    onSubmit: _save,
                  ),
                  if (_isEdit && !_completed) ...[
                    const SizedBox(height: Gap.sm),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final item = await ref
                            .read(taskRepositoryProvider)
                            .byId(_id);
                        if (item == null || !context.mounted) return;
                        await completeTask(context, ref, item);
                        if (context.mounted) context.pop();
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text(l10n.taskMarkDone),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
