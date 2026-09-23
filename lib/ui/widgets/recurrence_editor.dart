import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/l10n.dart';
import '../../core/time/local_date.dart';
import '../../core/time/recurrence.dart';
import '../format/formatters.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'form_widgets.dart';

/// Human readable summary such as "Every 2 weeks · Mon, Thu · until …".
String describeRecurrence(
  RecurrenceRule? rule,
  AppLocalizations l10n,
  AppDateFormatter formatter,
) {
  if (rule == null) return l10n.repeatNever;
  final base = switch (rule.frequency) {
    RecurrenceFrequency.daily => l10n.repeatEveryDays(rule.interval),
    RecurrenceFrequency.weekly => l10n.repeatEveryWeeks(rule.interval),
    RecurrenceFrequency.monthly => l10n.repeatEveryMonths(rule.interval),
    RecurrenceFrequency.yearly => l10n.repeatEveryYears(rule.interval),
  };
  final parts = [base];
  if (rule.frequency == RecurrenceFrequency.weekly &&
      rule.weekdays.isNotEmpty) {
    final days = rule.weekdays.toList()..sort();
    parts.add(
      days.map((d) => formatter.weekdayShort(LocalDate(2024, 1, d))).join(', '),
    );
  }
  if (rule.until != null) {
    parts.add(l10n.repeatUntilDate(formatter.date(rule.until!)));
  }
  if (rule.count != null) parts.add(l10n.repeatTimesCount(rule.count!));
  return parts.join(' · ');
}

enum _Preset { never, daily, weekly, monthly, yearly, custom }

enum _EndMode { never, onDate, afterCount }

/// Lets the user choose a repeat schedule. Emits `null` for "does not
/// repeat".
class RecurrenceEditor extends StatefulWidget {
  const RecurrenceEditor({
    super.key,
    required this.value,
    required this.onChanged,
    required this.startDate,
    this.allowNever = true,
    this.presets = const [
      RecurrenceFrequency.daily,
      RecurrenceFrequency.weekly,
      RecurrenceFrequency.monthly,
      RecurrenceFrequency.yearly,
    ],
  });

  final RecurrenceRule? value;
  final ValueChanged<RecurrenceRule?> onChanged;
  final LocalDate startDate;
  final bool allowNever;
  final List<RecurrenceFrequency> presets;

  @override
  State<RecurrenceEditor> createState() => _RecurrenceEditorState();
}

class _RecurrenceEditorState extends State<RecurrenceEditor> {
  late final TextEditingController _interval;
  late final TextEditingController _count;

  @override
  void initState() {
    super.initState();
    _interval = TextEditingController(text: '${widget.value?.interval ?? 1}');
    _count = TextEditingController(text: '${widget.value?.count ?? 10}');
  }

  @override
  void dispose() {
    _interval.dispose();
    _count.dispose();
    super.dispose();
  }

  _Preset get _preset {
    final v = widget.value;
    if (v == null) return _Preset.never;
    final simple =
        v.interval == 1 &&
        v.until == null &&
        v.count == null &&
        (v.frequency != RecurrenceFrequency.weekly || v.weekdays.isEmpty);
    if (!simple) return _Preset.custom;
    return switch (v.frequency) {
      RecurrenceFrequency.daily => _Preset.daily,
      RecurrenceFrequency.weekly => _Preset.weekly,
      RecurrenceFrequency.monthly => _Preset.monthly,
      RecurrenceFrequency.yearly => _Preset.yearly,
    };
  }

  bool _customExpanded = false;

  void _selectPreset(_Preset p) {
    setState(() => _customExpanded = p == _Preset.custom);
    switch (p) {
      case _Preset.never:
        widget.onChanged(null);
      case _Preset.daily:
        widget.onChanged(RecurrenceRule.daily());
      case _Preset.weekly:
        widget.onChanged(RecurrenceRule.weekly());
      case _Preset.monthly:
        widget.onChanged(RecurrenceRule.monthly());
      case _Preset.yearly:
        widget.onChanged(RecurrenceRule.yearly());
      case _Preset.custom:
        widget.onChanged(
          widget.value ??
              RecurrenceRule.weekly(weekdays: {widget.startDate.weekday}),
        );
    }
  }

  _EndMode get _endMode {
    final v = widget.value;
    if (v?.until != null) return _EndMode.onDate;
    if (v?.count != null) return _EndMode.afterCount;
    return _EndMode.never;
  }

  void _emit(RecurrenceRule rule) => widget.onChanged(rule);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preset = _preset;
    final showCustom = _customExpanded || preset == _Preset.custom;
    final rule = widget.value;
    String label(_Preset p) => switch (p) {
      _Preset.never => l10n.repeatNever,
      _Preset.daily => l10n.repeatDaily,
      _Preset.weekly => l10n.repeatWeekly,
      _Preset.monthly => l10n.repeatMonthly,
      _Preset.yearly => l10n.repeatYearly,
      _Preset.custom => l10n.repeatCustom,
    };
    final presetFreqs = {
      RecurrenceFrequency.daily: _Preset.daily,
      RecurrenceFrequency.weekly: _Preset.weekly,
      RecurrenceFrequency.monthly: _Preset.monthly,
      RecurrenceFrequency.yearly: _Preset.yearly,
    };
    final choices = [
      if (widget.allowNever) _Preset.never,
      for (final f in widget.presets) presetFreqs[f]!,
      _Preset.custom,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            for (final p in choices)
              ChoiceChip(
                label: Text(label(p)),
                selected: showCustom ? p == _Preset.custom : p == preset,
                onSelected: (_) => _selectPreset(p),
              ),
          ],
        ),
        if (showCustom && rule != null) ...[
          const SizedBox(height: Gap.lg),
          Row(
            children: [
              SizedBox(
                width: 88,
                child: TextField(
                  controller: _interval,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: InputDecoration(labelText: l10n.repeatEvery),
                  onChanged: (text) {
                    final n = int.tryParse(text);
                    if (n != null && n >= 1) _emit(rule.copyWith(interval: n));
                  },
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: DropdownButtonFormField<RecurrenceFrequency>(
                  initialValue: rule.frequency,
                  items: [
                    DropdownMenuItem(
                      value: RecurrenceFrequency.daily,
                      child: Text(l10n.repeatUnitDays),
                    ),
                    DropdownMenuItem(
                      value: RecurrenceFrequency.weekly,
                      child: Text(l10n.repeatUnitWeeks),
                    ),
                    DropdownMenuItem(
                      value: RecurrenceFrequency.monthly,
                      child: Text(l10n.repeatUnitMonths),
                    ),
                    DropdownMenuItem(
                      value: RecurrenceFrequency.yearly,
                      child: Text(l10n.repeatUnitYears),
                    ),
                  ],
                  onChanged: (f) {
                    if (f != null) {
                      _emit(
                        rule.copyWith(
                          frequency: f,
                          weekdays: f == RecurrenceFrequency.weekly
                              ? {widget.startDate.weekday}
                              : <int>{},
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          if (rule.frequency == RecurrenceFrequency.weekly) ...[
            const SizedBox(height: Gap.md),
            Text(l10n.repeatOnDays, style: context.textTheme.labelLarge),
            const SizedBox(height: Gap.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var d = 1; d <= 7; d++)
                  FilterChip(
                    label: Text(
                      l10n.weekdayName(d).characters.take(3).toString(),
                    ),
                    tooltip: l10n.weekdayName(d),
                    selected: rule.weekdays.contains(d),
                    onSelected: (on) {
                      final days = {...rule.weekdays};
                      on ? days.add(d) : days.remove(d);
                      if (days.isEmpty) days.add(widget.startDate.weekday);
                      _emit(rule.copyWith(weekdays: days));
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: Gap.lg),
          Text(l10n.repeatEnds, style: context.textTheme.labelLarge),
          const SizedBox(height: Gap.sm),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              ChoiceChip(
                label: Text(l10n.repeatEndsNever),
                selected: _endMode == _EndMode.never,
                onSelected: (_) =>
                    _emit(rule.copyWith(clearUntil: true, clearCount: true)),
              ),
              ChoiceChip(
                label: Text(l10n.repeatEndsOnDate),
                selected: _endMode == _EndMode.onDate,
                onSelected: (_) => _emit(
                  rule.copyWith(
                    until: widget.startDate.addMonths(3),
                    clearCount: true,
                  ),
                ),
              ),
              ChoiceChip(
                label: Text(l10n.repeatEndsAfter),
                selected: _endMode == _EndMode.afterCount,
                onSelected: (_) => _emit(
                  rule.copyWith(
                    count: int.tryParse(_count.text) ?? 10,
                    clearUntil: true,
                  ),
                ),
              ),
            ],
          ),
          if (_endMode == _EndMode.onDate) ...[
            const SizedBox(height: Gap.md),
            DateField(
              label: l10n.commonEndDate,
              value: rule.until,
              firstDate: widget.startDate,
              onChanged: (d) {
                if (d != null) _emit(rule.copyWith(until: d));
              },
            ),
          ],
          if (_endMode == _EndMode.afterCount) ...[
            const SizedBox(height: Gap.md),
            TextField(
              controller: _count,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(labelText: l10n.repeatOccurrences),
              onChanged: (text) {
                final n = int.tryParse(text);
                if (n != null && n >= 1) _emit(rule.copyWith(count: n));
              },
            ),
          ],
        ],
      ],
    );
  }
}
