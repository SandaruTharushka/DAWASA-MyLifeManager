import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/l10n/l10n.dart';
import '../../core/providers.dart';
import '../../core/security/biometrics.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/form_widgets.dart';
import '../settings/widgets/settings_widgets.dart';
import 'app_lock.dart';
import 'pin_setup_screen.dart';

final biometricAvailableProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(biometricAuthenticatorProvider).isAvailable(),
);

/// Choices for "Lock after", in seconds.
const List<int> lockTimeoutChoices = [0, 30, 60, 300, 900];

String lockTimeoutLabel(AppLocalizations l10n, int seconds) =>
    switch (seconds) {
      0 => l10n.securityLockImmediately,
      < 60 => l10n.securityLockAfterSeconds(seconds),
      _ => l10n.securityLockAfterMinutes(seconds ~/ 60),
    };

class SecuritySettingsSection extends ConsumerWidget {
  const SecuritySettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lock = ref.watch(appLockProvider);
    final prefs = ref.watch(preferencesProvider);
    final prefsCtrl = ref.read(preferencesProvider.notifier);
    final biometricAvailable =
        ref.watch(biometricAvailableProvider).value ?? false;

    Future<void> openPin(PinSetupMode mode) =>
        context.push<bool>(Routes.pinSetup(mode.name));

    return SettingsSection(
      title: l10n.settingsSecurity,
      footer: lock.pinEnabled ? l10n.securityLockNote : null,
      children: [
        SettingsSwitch(
          key: const ValueKey('settings-pin-lock'),
          icon: Icons.pin_outlined,
          title: l10n.securityPin,
          subtitle: l10n.securityPinDesc,
          value: lock.pinEnabled,
          onChanged: lock.phase == LockPhase.loading
              ? null
              : (on) => openPin(on ? PinSetupMode.create : PinSetupMode.remove),
        ),
        if (lock.pinEnabled) ...[
          SettingsTile(
            icon: Icons.password_rounded,
            title: l10n.securityChangePin,
            onTap: () => openPin(PinSetupMode.change),
          ),
          SettingsSwitch(
            icon: Icons.fingerprint_rounded,
            title: l10n.securityBiometric,
            subtitle: biometricAvailable
                ? null
                : l10n.securityBiometricUnavailable,
            value: lock.biometricEnabled && biometricAvailable,
            onChanged: biometricAvailable
                ? (on) => _setBiometric(context, ref, on)
                : null,
          ),
          SettingsTile(
            icon: Icons.timer_outlined,
            title: l10n.securityLockTimeout,
            subtitle: lockTimeoutLabel(l10n, prefs.lockTimeoutSeconds),
            onTap: () async {
              final seconds = await showOptionsSheet<int>(
                context,
                title: l10n.securityLockTimeout,
                selected: prefs.lockTimeoutSeconds,
                options: [
                  for (final s in lockTimeoutChoices)
                    (s, lockTimeoutLabel(l10n, s)),
                ],
              );
              if (seconds != null) {
                await prefsCtrl.update(
                  (p) => p.copyWith(lockTimeoutSeconds: seconds),
                );
              }
            },
          ),
        ],
        SettingsSwitch(
          icon: Icons.visibility_off_outlined,
          title: l10n.settingsPrivacyMode,
          subtitle: l10n.settingsPrivacyModeDesc,
          value: prefs.hideBalancesOnStart,
          onChanged: (on) =>
              prefsCtrl.update((p) => p.copyWith(hideBalancesOnStart: on)),
        ),
        SettingsSwitch(
          icon: Icons.screenshot_monitor_outlined,
          title: l10n.settingsScreenProtection,
          subtitle: l10n.settingsScreenProtectionDesc,
          value: prefs.screenProtection,
          onChanged: (on) =>
              prefsCtrl.update((p) => p.copyWith(screenProtection: on)),
        ),
      ],
    );
  }

  Future<void> _setBiometric(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final controller = ref.read(appLockProvider.notifier);
    if (!enabled) {
      await controller.setBiometricEnabled(false);
      return;
    }
    // Confirm once that the sensor works before relying on it.
    final reason = context.l10n.securityBiometricReason;
    final ok = await controller.whileExternal(
      () => ref.read(biometricAuthenticatorProvider).authenticate(reason),
    );
    if (ok) {
      await controller.setBiometricEnabled(true);
    } else if (context.mounted) {
      showAppSnackBar(context, context.l10n.securityBiometricFailed);
    }
  }
}
