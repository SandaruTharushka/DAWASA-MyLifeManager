import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/utils/streams.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../transactions/presentation/transaction_providers.dart';

/// Records needed before the reminder appears (nothing to lose before).
const int kBackupReminderMinTransactions = 20;
const Duration kBackupReminderAge = Duration(days: 30);
const Duration kBackupReminderSnooze = Duration(days: 14);

final _transactionCountProvider = StreamProvider.autoDispose<int>((ref) {
  final db = ref.watch(databaseProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return watchComputed(db, [db.transactions], repo.count);
});

/// Whether the home screen should suggest making a backup.
bool shouldRemindBackup({
  required DateTime now,
  required int transactions,
  DateTime? lastBackup,
  DateTime? dismissed,
}) {
  if (transactions < kBackupReminderMinTransactions) return false;
  if (lastBackup != null && now.difference(lastBackup) < kBackupReminderAge) {
    return false;
  }
  if (dismissed != null && now.difference(dismissed) < kBackupReminderSnooze) {
    return false;
  }
  return true;
}

/// All data lives only on this phone; this card nudges the user to keep an
/// encrypted backup somewhere else.
class BackupReminderCard extends ConsumerWidget {
  const BackupReminderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(_transactionCountProvider).value ?? 0;
    final prefs = ref.watch(preferencesProvider);
    final show = shouldRemindBackup(
      now: ref.watch(clockProvider)(),
      transactions: count,
      lastBackup: prefs.lastBackupAt,
      dismissed: prefs.backupReminderDismissedAt,
    );
    if (!show) return const SizedBox.shrink();
    final l10n = context.l10n;
    final s = context.semantic;
    return Padding(
      padding: const EdgeInsets.only(top: Gap.md),
      child: AppCard(
        color: s.warningContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup_outlined, color: s.warning),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Text(
                    prefs.lastBackupAt == null
                        ? l10n.backupReminderTitle
                        : l10n.backupReminderOldTitle,
                    style: context.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.xs),
            Text(l10n.backupReminderBody),
            const SizedBox(height: Gap.sm),
            Wrap(
              spacing: Gap.sm,
              children: [
                FilledButton(
                  onPressed: () => context.push(Routes.backup),
                  child: Text(l10n.settingsBackup),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(preferencesProvider.notifier)
                      .update(
                        (p) => p.copyWith(
                          backupReminderDismissedAt: ref.read(clockProvider)(),
                        ),
                      ),
                  child: Text(l10n.backupReminderLater),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
