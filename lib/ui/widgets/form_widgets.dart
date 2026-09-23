import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/providers.dart';
import '../../core/time/local_date.dart';
import '../format/formatters.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A primary button that runs an async action and ignores further taps until
/// the action completes. This is the first line of defence against duplicate
/// records caused by repeated taps on "Save".
class SubmitButton extends StatefulWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.onSubmit,
    this.icon,
    this.expand = true,
    this.tonal = false,
  });

  final String label;
  final Future<void> Function()? onSubmit;
  final IconData? icon;
  final bool expand;
  final bool tonal;

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy || widget.onSubmit == null) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _busy
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Text(widget.label);
    final onPressed = (_busy || widget.onSubmit == null) ? null : _run;
    Widget button;
    if (widget.icon != null && !_busy) {
      button = widget.tonal
          ? FilledButton.tonalIcon(
              onPressed: onPressed,
              icon: Icon(widget.icon),
              label: child,
            )
          : FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(widget.icon),
              label: child,
            );
    } else {
      button = widget.tonal
          ? FilledButton.tonal(onPressed: onPressed, child: child)
          : FilledButton(onPressed: onPressed, child: child);
    }
    return widget.expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// Read-only field that opens a date picker.
class DateField extends ConsumerWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.clearable = false,
    this.icon = Icons.calendar_today_rounded,
  });

  final String label;
  final LocalDate? value;
  final ValueChanged<LocalDate?> onChanged;
  final LocalDate? firstDate;
  final LocalDate? lastDate;
  final bool clearable;
  final IconData icon;

  static String _label(
    LocalDate? value,
    LocalDate today,
    AppDateFormatter formatter,
    AppLocalizations l10n,
  ) {
    if (value == null) return l10n.commonNoDate;
    final relative = switch (today.daysUntil(value)) {
      0 => l10n.commonToday,
      -1 => l10n.commonYesterday,
      1 => l10n.commonTomorrow,
      _ => null,
    };
    final formatted = formatter.date(value);
    return relative == null ? formatted : '$relative · $formatted';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.watch(dateFormatterProvider);
    final today = ref.watch(todayProvider);
    final l10n = context.l10n;
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.field),
      onTap: () async {
        final initial = value ?? today;
        final picked = await showDatePicker(
          context: context,
          initialDate: initial.startOfDayLocal,
          firstDate: (firstDate ?? LocalDate(2000, 1, 1)).startOfDayLocal,
          lastDate: (lastDate ?? LocalDate(2100, 12, 31)).startOfDayLocal,
        );
        if (picked != null) onChanged(LocalDate.fromDateTime(picked));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: clearable && value != null
              ? IconButton(
                  tooltip: l10n.actionClear,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        child: Text(_label(value, today, formatter, l10n)),
      ),
    );
  }
}

/// Read-only field that opens a time picker; value is minutes since midnight.
class TimeField extends ConsumerWidget {
  const TimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.clearable = false,
  });

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  final bool clearable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.watch(dateFormatterProvider);
    final l10n = context.l10n;
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.field),
      onTap: () async {
        final initial = value ?? 9 * 60;
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
        );
        if (picked != null) onChanged(picked.hour * 60 + picked.minute);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.schedule_rounded),
          suffixIcon: clearable && value != null
              ? IconButton(
                  tooltip: l10n.actionClear,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        child: Text(
          value == null ? l10n.commonNoTime : formatter.timeOfDay(value!),
        ),
      ),
    );
  }
}

/// A selectable tile used in option pickers (language, currency, ...).
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.field),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.field),
          onTap: onTap,
          child: Semantics(
            selected: selected,
            button: true,
            child: Padding(
              padding: const EdgeInsets.all(Gap.lg),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: Gap.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.textTheme.titleMedium),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected ? colors.primary : colors.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing options; returns the chosen value.
Future<T?> showOptionsSheet<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: Text(title, style: context.textTheme.titleLarge),
            ),
            for (final (value, label) in options)
              ChoiceTile(
                title: label,
                selected: value == selected,
                onTap: () => Navigator.of(context).pop(value),
              ),
          ],
        ),
      ),
    ),
  );
}
