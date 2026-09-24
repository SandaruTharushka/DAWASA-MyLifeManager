import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/form_widgets.dart';
import '../../settings/widgets/settings_widgets.dart';
import 'backup_providers.dart';
import 'delete_all.dart';
import 'restore_screen.dart';

enum _SafetyAction { bringBack, delete }

class DataSettingsSection extends ConsumerWidget {
  const DataSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formatter = ref.watch(dateFormatterProvider);
    final lastBackup = ref.watch(
      preferencesProvider.select((p) => p.lastBackupAt),
    );
    final safety = ref.watch(safetyCopyProvider).value;

    return SettingsSection(
      title: l10n.settingsData,
      footer: l10n.settingsUninstallWarning,
      children: [
        SettingsTile(
          icon: Icons.backup_outlined,
          title: l10n.settingsBackup,
          subtitle: lastBackup == null
              ? l10n.backupNever
              : l10n.backupLastBackup(formatter.dateTime(lastBackup.toLocal())),
          onTap: () => context.push(Routes.backup),
        ),
        SettingsTile(
          icon: Icons.settings_backup_restore_rounded,
          title: l10n.settingsRestore,
          subtitle: l10n.settingsRestoreDesc,
          onTap: () => context.push(Routes.restore),
        ),
        if (safety != null)
          SettingsTile(
            icon: Icons.history_rounded,
            title: l10n.restorePreviousData,
            subtitle: l10n.restorePreviousDataDesc(
              formatter.dateTime(safety.createdAt.toLocal()),
            ),
            onTap: () => _safetyCopy(context, ref),
          ),
        SettingsTile(
          icon: Icons.table_view_outlined,
          title: l10n.settingsExportCsv,
          onTap: () => context.push(Routes.exportCsv),
        ),
        SettingsTile(
          icon: Icons.delete_forever_outlined,
          title: l10n.settingsDeleteAll,
          subtitle: l10n.settingsDeleteAllDesc,
          destructive: true,
          onTap: () async {
            if (!await confirmDeleteAll(context)) return;
            await deleteAllData(ref);
          },
        ),
      ],
    );
  }

  Future<void> _safetyCopy(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final action = await showOptionsSheet<_SafetyAction>(
      context,
      title: l10n.restorePreviousData,
      options: [
        (_SafetyAction.bringBack, l10n.restoreBringBack),
        (_SafetyAction.delete, l10n.restoreDeleteSafetyCopy),
      ],
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _SafetyAction.bringBack:
        final ok = await confirmDialog(
          context,
          title: l10n.restoreBringBack,
          message: l10n.restoreBringBackBody,
          confirmLabel: l10n.restoreBringBack,
          destructive: true,
        );
        if (ok) await restorePreviousData(ref);
      case _SafetyAction.delete:
        await ref.read(backupServiceProvider).deleteSafetyCopy();
        ref.invalidate(safetyCopyProvider);
    }
  }
}
