import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/recurrence.dart';
import '../../../ui/icons/app_icons.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/form_widgets.dart';
import '../../../ui/widgets/money_widgets.dart';
import '../../../ui/widgets/recurrence_editor.dart';
import '../data/event_repository.dart';

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.watch(databaseProvider)),
);

final eventsProvider = StreamProvider<List<PersonalEventRow>>(
  (ref) => ref.watch(eventRepositoryProvider).watchAll(),
);

/// Events with their next occurrence, soonest first.
final eventViewsProvider = Provider<AsyncValue<List<EventView>>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(eventsProvider).whenData((events) {
    final views = [for (final e in events) EventView.of(e, today)];
    views.sort((a, b) {
      if (a.next == null && b.next == null) {
        return b.event.date.compareTo(a.event.date);
      }
      if (a.next == null) return 1;
      if (b.next == null) return -1;
      return a.next!.compareTo(b.next!);
    });
    return views;
  });
});

extension EventLabels on AppLocalizations {
  String eventTypeLabel(EventType t) => switch (t) {
    EventType.birthday => eventBirthday,
    EventType.anniversary => eventAnniversary,
    EventType.appointment => eventAppointment,
    EventType.exam => eventExam,
    EventType.other => eventOther,
  };
}

Color eventColor(BuildContext context, EventType t) => switch (t) {
  EventType.birthday => const Color(0xFFEC4899),
  EventType.anniversary => const Color(0xFFEF4444),
  EventType.appointment => context.semantic.transfer,
  EventType.exam => const Color(0xFF8B5CF6),
  EventType.other => context.semantic.neutral,
};

class EventsTab extends ConsumerStatefulWidget {
  const EventsTab({super.key});

  @override
  ConsumerState<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<EventsTab> {
  bool _calendar = false;
  late LocalDate _month = ref.read(todayProvider).firstDayOfMonth;
  LocalDate? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AsyncValueView(
      value: ref.watch(eventViewsProvider),
      data: (views) {
        if (views.isEmpty) {
          return EmptyState(
            icon: Icons.cake_outlined,
            message: l10n.eventEmpty,
            actionLabel: l10n.eventAdd,
            onAction: () => context.push(Routes.newEvent),
          );
        }
        final upcoming = views.where((v) => v.next != null).toList();
        final past = views.where((v) => v.next == null).toList();
        return PageBody(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.list_rounded),
                    label: Text(l10n.eventList),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text(l10n.eventCalendar),
                  ),
                ],
                selected: {_calendar},
                onSelectionChanged: (s) => setState(() => _calendar = s.first),
              ),
            ),
            if (_calendar)
              ..._calendarView(context, views)
            else ...[
              if (upcoming.isNotEmpty) ...[
                SectionHeader(title: l10n.eventUpcoming),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                  child: Column(
                    children: [for (final v in upcoming) EventTile(view: v)],
                  ),
                ),
              ],
              if (past.isNotEmpty) ...[
                SectionHeader(title: l10n.eventPast),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                  child: Column(
                    children: [for (final v in past) EventTile(view: v)],
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  List<Widget> _calendarView(BuildContext context, List<EventView> views) {
    final l10n = context.l10n;
    final formatter = ref.watch(dateFormatterProvider);
    final today = ref.watch(todayProvider);
    final firstWeekday = ref.watch(
      userSettingsProvider.select((s) => s.firstDayOfWeek),
    );
    final byDay = <LocalDate, List<EventView>>{};
    for (final v in views) {
      for (final d in v.occurrencesIn(_month.year, _month.month)) {
        byDay.putIfAbsent(d, () => []).add(v);
      }
    }
    final gridStart = _month.startOfWeek(firstWeekday);
    final cells = [for (var i = 0; i < 42; i++) gridStart.addDays(i)];
    final selected = _selected;
    return [
      const SizedBox(height: Gap.md),
      AppCard(
        padding: const EdgeInsets.all(Gap.sm),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: l10n.actionBack,
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () =>
                      setState(() => _month = _month.addMonths(-1)),
                ),
                Expanded(
                  child: Text(
                    formatter.monthYear(_month),
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.actionNext,
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => setState(() => _month = _month.addMonths(1)),
                ),
              ],
            ),
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        formatter.weekdayShort(gridStart.addDays(i)),
                        style: context.textTheme.labelSmall,
                      ),
                    ),
                  ),
              ],
            ),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final d in cells)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _selected = d),
                    child: Semantics(
                      label:
                          '${formatter.fullDay(d)}${byDay[d] == null ? '' : ', ${byDay[d]!.map((v) => v.event.title).join(', ')}'}',
                      button: true,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: d == selected
                              ? context.colors.primaryContainer
                              : null,
                          borderRadius: BorderRadius.circular(10),
                          border: d == today
                              ? Border.all(
                                  color: context.colors.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${d.day}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: d.month == _month.month
                                    ? null
                                    : context.colors.outline,
                              ),
                            ),
                            if (byDay[d] != null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final v in byDay[d]!.take(3))
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                        color: eventColor(
                                          context,
                                          v.event.type,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      if (selected != null) ...[
        SectionHeader(title: formatter.fullDay(selected)),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: Gap.xs),
          child: (byDay[selected] ?? const []).isEmpty
              ? ListTile(
                  title: Text(l10n.eventNoneThisDay),
                  trailing: TextButton(
                    onPressed: () => context.push(
                      '${Routes.newEvent}?date=${selected.toIso()}',
                    ),
                    child: Text(l10n.actionAdd),
                  ),
                )
              : Column(
                  children: [
                    for (final v in byDay[selected]!) EventTile(view: v),
                  ],
                ),
        ),
      ],
    ];
  }
}

class EventTile extends ConsumerWidget {
  const EventTile({super.key, required this.view});

  final EventView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final e = view.event;
    final formatter = ref.watch(dateFormatterProvider);
    final today = ref.watch(todayProvider);
    final next = view.next;
    final parts = <String>[
      l10n.eventTypeLabel(e.type),
      if (next != null) ...[
        formatter.date(next),
        l10n.eventInDays(today.daysUntil(next)),
      ] else
        formatter.date(e.date),
      if (view.yearsAtNext != null)
        e.type == EventType.birthday
            ? l10n.eventTurns(view.yearsAtNext!)
            : l10n.eventYears(view.yearsAtNext!),
    ];
    return ListTile(
      onTap: () => context.push(Routes.editEvent(e.id)),
      leading: IconBadge(
        icon: AppIcons.forEventType(e.type),
        color: eventColor(context, e.type),
      ),
      title: Text(e.title),
      subtitle: Text(parts.join(' · ')),
      trailing: e.budgetMinor == null
          ? null
          : MoneyText(
              e.budgetMinor!,
              sensitive: false,
              style: context.textTheme.bodySmall,
            ),
    );
  }
}

class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.eventId, this.initialDate});

  final String? eventId;
  final LocalDate? initialDate;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _budget = TextEditingController();
  final _note = TextEditingController();
  final _remindDays = TextEditingController(text: '1');
  late final String _id = widget.eventId ?? newId();
  EventType _type = EventType.birthday;
  late LocalDate _date = widget.initialDate ?? ref.read(todayProvider);
  int? _time;
  RecurrenceRule? _repeat = RecurrenceRule.yearly();
  bool _remind = true;
  int _remindAt = 9 * 60;
  bool _loading = false;

  bool get _isEdit => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loading = true;
      ref.read(eventRepositoryProvider).byId(widget.eventId!).then((e) {
        if (!mounted || e == null) return;
        final currency = ref.read(currencyProvider);
        setState(() {
          _title.text = e.title;
          _type = e.type;
          _date = e.date;
          _time = e.timeMinutes;
          _repeat = RecurrenceRule.decode(e.recurrence);
          _remind = e.remindDaysBefore != null;
          _remindDays.text = '${e.remindDaysBefore ?? 1}';
          _remindAt = e.remindAtMinutes;
          _budget.text = e.budgetMinor == null
              ? ''
              : Money.formatForInput(
                  e.budgetMinor!,
                  decimalDigits: currency.decimalDigits,
                );
          _note.text = e.note ?? '';
          _loading = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _budget.dispose();
    _note.dispose();
    _remindDays.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(eventRepositoryProvider)
        .save(
          EventDraft(
            id: _id,
            title: _title.text,
            type: _type,
            date: _date,
            timeMinutes: _time,
            recurrence: _repeat,
            remindDaysBefore: _remind
                ? (int.tryParse(_remindDays.text) ?? 0)
                : null,
            remindAtMinutes: _remindAt,
            budgetMinor: parseMoneyField(
              _budget.text,
              ref.read(currencyProvider),
            ),
            note: _note.text,
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.eventEdit : l10n.eventAdd),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: l10n.actionDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: l10n.confirmDeleteTitle,
                  message: l10n.confirmDeleteMessage,
                  confirmLabel: l10n.actionDelete,
                  destructive: true,
                );
                if (!ok) return;
                await ref.read(eventRepositoryProvider).delete(_id);
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
                  Wrap(
                    spacing: Gap.sm,
                    runSpacing: Gap.sm,
                    children: [
                      for (final t in EventType.values)
                        ChoiceChip(
                          avatar: Icon(AppIcons.forEventType(t), size: 18),
                          label: Text(l10n.eventTypeLabel(t)),
                          selected: _type == t,
                          onSelected: (_) => setState(() {
                            _type = t;
                            if (!_isEdit) {
                              _repeat =
                                  (t == EventType.birthday ||
                                      t == EventType.anniversary)
                                  ? RecurrenceRule.yearly()
                                  : null;
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: Gap.lg),
                  TextFormField(
                    controller: _title,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.eventTitle,
                      hintText: l10n.eventTitleHint,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DateField(
                          label: l10n.eventDate,
                          value: _date,
                          firstDate: LocalDate(1900, 1, 1),
                          onChanged: (d) {
                            if (d != null) setState(() => _date = d);
                          },
                        ),
                      ),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        flex: 2,
                        child: TimeField(
                          label: l10n.commonTime,
                          value: _time,
                          clearable: true,
                          onChanged: (m) => setState(() => _time = m),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.lg),
                  Text(l10n.commonRepeat, style: context.textTheme.labelLarge),
                  const SizedBox(height: Gap.sm),
                  RecurrenceEditor(
                    value: _repeat,
                    startDate: _date,
                    onChanged: (r) => setState(() => _repeat = r),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.eventRemind),
                    value: _remind,
                    onChanged: (v) => setState(() => _remind = v),
                  ),
                  if (_remind)
                    Row(
                      children: [
                        SizedBox(
                          width: 140,
                          child: TextFormField(
                            controller: _remindDays,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.billRemindDaysBefore(
                                int.tryParse(_remindDays.text) ?? 0,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: TimeField(
                            label: l10n.commonTime,
                            value: _remindAt,
                            onChanged: (m) {
                              if (m != null) setState(() => _remindAt = m);
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: Gap.lg),
                  MoneyField(
                    controller: _budget,
                    currency: ref.watch(currencyProvider),
                    label: l10n.eventBudget,
                    helperText: l10n.eventBudgetHelp,
                    required: false,
                    allowZero: true,
                  ),
                  const SizedBox(height: Gap.md),
                  TextFormField(
                    controller: _note,
                    maxLength: 300,
                    decoration: InputDecoration(
                      labelText: l10n.commonNote,
                      counterText: '',
                    ),
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
