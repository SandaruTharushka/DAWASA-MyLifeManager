import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/time/local_date.dart';
import '../../../ui/icons/app_icons.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/form_widgets.dart';
import '../data/habit_repository.dart';

final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => HabitRepository(ref.watch(databaseProvider)),
);

final habitsProvider = StreamProvider<List<HabitView>>(
  (ref) => ref.watch(habitRepositoryProvider).watchHabits(),
);

class HabitsTab extends ConsumerWidget {
  const HabitsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AsyncValueView(
      value: ref.watch(habitsProvider),
      data: (habits) {
        if (habits.isEmpty) {
          return EmptyState(
            icon: Icons.self_improvement_rounded,
            message: l10n.habitEmpty,
            actionLabel: l10n.habitAdd,
            onAction: () => context.push(Routes.newHabit),
          );
        }
        return PageBody(
          children: [
            for (final h in habits)
              Padding(
                padding: const EdgeInsets.only(top: Gap.md),
                child: HabitCard(view: h),
              ),
          ],
        );
      },
    );
  }
}

class HabitCard extends ConsumerWidget {
  const HabitCard({super.key, required this.view});

  final HabitView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final today = ref.watch(todayProvider);
    final firstWeekday = ref.watch(
      userSettingsProvider.select((s) => s.firstDayOfWeek),
    );
    final h = view.habit;
    final stats = view.stats(today, firstWeekday);
    final color = Color(h.colorValue);
    final daily = h.frequency == HabitFrequency.daily;
    final repo = ref.read(habitRepositoryProvider);
    final todayCount = view.counts[today] ?? 0;
    final formatter = ref.watch(dateFormatterProvider);

    // Last 5 weeks, aligned to the first weekday.
    final start = today.startOfWeek(firstWeekday).addDays(-28);
    final days = [for (var i = 0; i < 35; i++) start.addDays(i)];

    return AppCard(
      onTap: () => context.push(Routes.editHabit(h.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: AppIcons.forKey(h.iconKey),
                color: color,
                size: 40,
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name, style: context.textTheme.titleSmall),
                    Text(
                      daily
                          ? l10n.habitProgressToday(
                              stats.doneInPeriod,
                              h.targetCount,
                            )
                          : l10n.habitProgressWeek(
                              stats.doneInPeriod,
                              h.targetCount,
                            ),
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (todayCount > 0)
                IconButton(
                  tooltip: l10n.habitUndo,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  onPressed: () => repo.setCount(h.id, today, todayCount - 1),
                ),
              IconButton.filled(
                tooltip: l10n.habitMarkDone,
                style: IconButton.styleFrom(
                  backgroundColor: stats.completedToday
                      ? color
                      : context.colors.surfaceContainerHigh,
                  foregroundColor: stats.completedToday ? Colors.white : color,
                ),
                icon: Icon(
                  stats.completedToday
                      ? Icons.check_rounded
                      : Icons.add_rounded,
                ),
                onPressed: () => repo.setCount(h.id, today, todayCount + 1),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: context.semantic.warning,
                size: 18,
              ),
              const SizedBox(width: Gap.xs),
              Text(
                daily
                    ? l10n.habitStreak(stats.current)
                    : l10n.habitWeekStreak(stats.current),
                style: context.textTheme.labelLarge,
              ),
              const Spacer(),
              Text(
                l10n.habitBestStreak(stats.best),
                style: context.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Semantics(
            label:
                '${l10n.habitCalendar}: ${days.where((d) => (view.counts[d] ?? 0) > 0).map(formatter.dayMonth).join(', ')}',
            child: ExcludeSemantics(
              child: GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.6,
                children: [
                  for (final d in days)
                    _DayCell(
                      date: d,
                      count: view.counts[d] ?? 0,
                      target: daily ? h.targetCount : 1,
                      color: color,
                      isToday: d == today,
                      isFuture: d.isAfter(today),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.count,
    required this.target,
    required this.color,
    required this.isToday,
    required this.isFuture,
  });

  final LocalDate date;
  final int count;
  final int target;
  final Color color;
  final bool isToday;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final fill = count <= 0 ? 0.0 : (count / target).clamp(0.25, 1.0);
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isFuture
            ? Colors.transparent
            : count > 0
            ? color.withValues(alpha: fill)
            : context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: isToday ? Border.all(color: color, width: 2) : null,
      ),
      child: Text(
        '${date.day}',
        style: context.textTheme.labelSmall?.copyWith(
          color: count > 0 && fill > 0.5
              ? Colors.white
              : context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class HabitFormScreen extends ConsumerStatefulWidget {
  const HabitFormScreen({super.key, this.habitId});

  final String? habitId;

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final String _id = widget.habitId ?? newId();
  HabitFrequency _frequency = HabitFrequency.daily;
  int _target = 1;
  int? _reminder;
  String _icon = 'star';
  int _color = AppIcons.colorChoices[2];
  bool _loading = false;

  bool get _isEdit => widget.habitId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loading = true;
      ref.read(habitRepositoryProvider).byId(widget.habitId!).then((h) {
        if (!mounted || h == null) return;
        setState(() {
          _name.text = h.name;
          _frequency = h.frequency;
          _target = h.targetCount;
          _reminder = h.reminderMinutes;
          _icon = h.iconKey;
          _color = h.colorValue;
          _loading = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(habitRepositoryProvider)
        .save(
          HabitDraft(
            id: _id,
            name: _name.text,
            frequency: _frequency,
            targetCount: _target,
            reminderMinutes: _reminder,
            iconKey: _icon,
            colorValue: _color,
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const icons = [
      'water',
      'sports',
      'school',
      'star',
      'health',
      'temple',
      'coffee',
      'home',
      'bike',
      'beauty',
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.habitEdit : l10n.habitAdd),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: l10n.actionDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: l10n.confirmDeleteTitle,
                  message: l10n.habitDeleteBody,
                  confirmLabel: l10n.actionDelete,
                  destructive: true,
                );
                if (!ok) return;
                await ref.read(habitRepositoryProvider).delete(_id);
                if (context.mounted) context.pop();
              },
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
                    controller: _name,
                    autofocus: !_isEdit,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.habitName,
                      hintText: l10n.habitNameHint,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : null,
                  ),
                  Text(
                    l10n.habitFrequency,
                    style: context.textTheme.labelLarge,
                  ),
                  const SizedBox(height: Gap.sm),
                  SegmentedButton<HabitFrequency>(
                    segments: [
                      ButtonSegment(
                        value: HabitFrequency.daily,
                        label: Text(l10n.habitDaily),
                      ),
                      ButtonSegment(
                        value: HabitFrequency.weekly,
                        label: Text(l10n.habitWeekly),
                      ),
                    ],
                    selected: {_frequency},
                    onSelectionChanged: (s) =>
                        setState(() => _frequency = s.first),
                  ),
                  const SizedBox(height: Gap.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _frequency == HabitFrequency.daily
                              ? l10n.habitTimesPerDay(_target)
                              : l10n.habitTimesPerWeek(_target),
                          style: context.textTheme.bodyLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: '-',
                        onPressed: _target <= 1
                            ? null
                            : () => setState(() => _target--),
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Text('$_target', style: context.textTheme.titleMedium),
                      IconButton(
                        tooltip: '+',
                        onPressed: _target >= 99
                            ? null
                            : () => setState(() => _target++),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.md),
                  TimeField(
                    label: l10n.habitReminder,
                    value: _reminder,
                    clearable: true,
                    onChanged: (m) => setState(() => _reminder = m),
                  ),
                  const SizedBox(height: Gap.lg),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final key in icons)
                        ChoiceChip(
                          label: Icon(
                            AppIcons.forKey(key),
                            size: 20,
                            color: Color(_color),
                          ),
                          selected: _icon == key,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _icon = key),
                        ),
                    ],
                  ),
                  const SizedBox(height: Gap.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in AppIcons.colorChoices.take(10))
                        InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => setState(() => _color = c),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: c == _color
                                    ? context.colors.onSurface
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Gap.xl),
                  SubmitButton(
                    label: l10n.actionSave,
                    icon: Icons.check_rounded,
                    onSubmit: _save,
                  ),
                ],
              ),
            ),
    );
  }
}
