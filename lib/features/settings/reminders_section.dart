import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/notifications/notification_providers.dart';
import '../../core/providers.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_theme.dart';
import '../security/app_lock.dart';
import 'widgets/settings_widgets.dart';

final _systemNotificationsProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(notificationGatewayProvider).areNotificationsEnabled(),
);

class RemindersSettingsSection extends ConsumerWidget {
  const RemindersSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(preferencesProvider);
    final ctrl = ref.read(preferencesProvider.notifier);
    final systemEnabled = ref.watch(_systemNotificationsProvider).value ?? true;
    final formatter = ref.watch(dateFormatterProvider);
    final enabled = prefs.notificationsEnabled;

    Future<void> setMaster(bool on) async {
      if (on) {
        final granted = await ref
            .read(appLockProvider.notifier)
            .whileExternal(
              ref.read(notificationGatewayProvider).requestPermission,
            );
        ref.invalidate(_systemNotificationsProvider);
        await ctrl.update((p) => p.copyWith(notificationsEnabled: granted));
      } else {
        await ctrl.update((p) => p.copyWith(notificationsEnabled: false));
      }
    }

    return SettingsSection(
      title: l10n.settingsReminders,
      footer: l10n.settingsBatteryNote,
      children: [
        SettingsSwitch(
          icon: Icons.notifications_outlined,
          title: l10n.settingsNotificationsEnabled,
          value: enabled && systemEnabled,
          onChanged: setMaster,
        ),
        if (enabled && !systemEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            child: Text(
              l10n.settingsNotificationsBlocked,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.semantic.warning,
              ),
            ),
          ),
        SettingsSwitch(
          icon: Icons.task_alt_rounded,
          title: l10n.settingsNotifyTasks,
          value: prefs.notifyTasks,
          onChanged: enabled
              ? (v) => ctrl.update((p) => p.copyWith(notifyTasks: v))
              : null,
        ),
        SettingsSwitch(
          icon: Icons.receipt_long_outlined,
          title: l10n.settingsNotifyBills,
          value: prefs.notifyBills,
          onChanged: enabled
              ? (v) => ctrl.update((p) => p.copyWith(notifyBills: v))
              : null,
        ),
        SettingsSwitch(
          icon: Icons.pie_chart_outline_rounded,
          title: l10n.settingsNotifyBudgets,
          value: prefs.notifyBudgets,
          onChanged: enabled
              ? (v) => ctrl.update((p) => p.copyWith(notifyBudgets: v))
              : null,
        ),
        SettingsSwitch(
          icon: Icons.event_outlined,
          title: l10n.settingsNotifyEvents,
          value: prefs.notifyEvents,
          onChanged: enabled
              ? (v) => ctrl.update((p) => p.copyWith(notifyEvents: v))
              : null,
        ),
        SettingsSwitch(
          icon: Icons.handshake_outlined,
          title: l10n.settingsNotifyLoans,
          value: prefs.notifyLoans,
          onChanged: enabled
              ? (v) => ctrl.update((p) => p.copyWith(notifyLoans: v))
              : null,
        ),
        SettingsSwitch(
          icon: Icons.savings_outlined,
          title: l10n.settingsNotifySavings,
          value: prefs.notifySavings,
          onChanged: enabled
              ? (v) => ctrl.update((p) => p.copyWith(notifySavings: v))
              : null,
        ),
        SettingsSwitch(
          icon: Icons.self_improvement_rounded,
          title: l10n.settingsNotifyHabits,
          value: prefs.notifyHabits,
          onChanged: enabled
              ? (v) => ctrl.update((p) => p.copyWith(notifyHabits: v))
              : null,
        ),
        SettingsSwitch(
          icon: Icons.wb_twilight_rounded,
          title: l10n.settingsDailyPlanning,
          subtitle: l10n.settingsDailyPlanningDesc,
          value: prefs.dailyPlanningEnabled,
          onChanged: enabled
              ? (v) => ctrl.update((p) => p.copyWith(dailyPlanningEnabled: v))
              : null,
        ),
        if (prefs.dailyPlanningEnabled)
          SettingsTile(
            icon: Icons.schedule_rounded,
            title: l10n.settingsDailyPlanningTime,
            subtitle: formatter.timeOfDay(prefs.dailyPlanningMinutes),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: prefs.dailyPlanningMinutes ~/ 60,
                  minute: prefs.dailyPlanningMinutes % 60,
                ),
              );
              if (picked != null) {
                await ctrl.update(
                  (p) => p.copyWith(
                    dailyPlanningMinutes: picked.hour * 60 + picked.minute,
                  ),
                );
              }
            },
          ),
      ],
    );
  }
}
