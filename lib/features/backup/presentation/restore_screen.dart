import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backup/backup_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/platform/data_paths.dart';
import '../../../core/providers.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/form_widgets.dart';
import '../../security/app_lock.dart';
import '../data/backup_service.dart';
import 'backup_providers.dart';
import 'backup_screen.dart';

/// Notices shown once after the app reloaded.
abstract final class AppNotices {
  static const restored = 'restored';
  static const restoreFailed = 'restoreFailed';
}

/// Largest file accepted for a restore (backups are usually a few MB).
const int kMaxBackupBytes = 1024 * 1024 * 1024;

String backupErrorMessage(AppLocalizations l10n, Object error) {
  if (error is! BackupException) return l10n.restoreErrorCorrupted;
  return switch (error.kind) {
    BackupErrorKind.notABackup => l10n.restoreErrorNotBackup,
    BackupErrorKind.unsupportedFormat => l10n.restoreErrorNewer,
    BackupErrorKind.newerSchema => l10n.restoreErrorNewer,
    BackupErrorKind.wrongPasswordOrCorrupted => l10n.restoreErrorWrongPassword,
    BackupErrorKind.corruptedPayload ||
    BackupErrorKind.missingDatabase => l10n.restoreErrorCorrupted,
  };
}

/// Wraps [reload] so that the app shows the right message after it reopens
/// and, during first-time setup, skips the welcome guide.
AppReloader _withNotice(
  WidgetRef ref,
  AppReloader reload, {
  required bool completeOnboarding,
}) {
  final store = ref.read(preferencesStoreProvider);
  return ({whileClosed}) => reload(
    whileClosed: () async {
      try {
        await whileClosed?.call();
      } on Object {
        await store.setNotice(AppNotices.restoreFailed);
        rethrow;
      }
      if (completeOnboarding) {
        await store.save(store.load().copyWith(onboardingComplete: true));
      }
      await store.setNotice(AppNotices.restored);
    },
  );
}

/// Puts back the data that the last restore replaced.
Future<void> restorePreviousData(WidgetRef ref) {
  final reload = _withNotice(
    ref,
    ref.read(appReloaderProvider),
    completeOnboarding: false,
  );
  return ref.read(backupServiceProvider).restoreSafetyCopy(reload);
}

enum _Step { choose, password, confirm }

class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  final _password = TextEditingController();
  late final BackupService _service;
  _Step _step = _Step.choose;
  Uint8List? _bytes;
  String? _fileName;
  BackupHeader? _header;
  PreparedRestore? _prepared;
  String? _error;
  bool _working = false;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _service = ref.read(backupServiceProvider);
  }

  @override
  void dispose() {
    _password.dispose();
    final prepared = _prepared;
    if (prepared != null && !_applying) {
      _service.cancelRestore(prepared).ignore();
    }
    super.dispose();
  }

  Future<void> _choose() async {
    final l10n = context.l10n;
    setState(() => _error = null);
    final file = await ref
        .read(appLockProvider.notifier)
        .whileExternal(() => FilePicker.pickFile());
    if (file == null || !mounted) return;
    final size = await file.length();
    if (size != null && size > kMaxBackupBytes) {
      setState(() => _error = l10n.restoreErrorNotBackup);
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    try {
      final header = _service.inspect(bytes);
      setState(() {
        _bytes = bytes;
        _fileName = file.name;
        _header = header;
        _step = _Step.password;
        _password.clear();
      });
    } on Object catch (e) {
      setState(() => _error = backupErrorMessage(l10n, e));
    }
  }

  Future<void> _check() async {
    final l10n = context.l10n;
    final bytes = _bytes;
    if (bytes == null || _password.text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final prepared = await _service.prepareRestore(bytes, _password.text);
      if (!mounted) {
        await _service.cancelRestore(prepared);
        return;
      }
      setState(() {
        _prepared = prepared;
        _step = _Step.confirm;
        _password.clear();
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = backupErrorMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _apply() async {
    final l10n = context.l10n;
    final prepared = _prepared;
    if (prepared == null) return;
    final ok = await confirmDialog(
      context,
      title: l10n.restoreConfirmTitle,
      message: l10n.restoreConfirmBody,
      confirmLabel: l10n.restoreAction,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _applying = true);
    final reload = _withNotice(
      ref,
      ref.read(appReloaderProvider),
      completeOnboarding: !ref.read(preferencesProvider).onboardingComplete,
    );
    try {
      // The app reloads with the restored data; this screen goes away.
      await _service.applyRestore(prepared, reload);
    } on Object catch (e) {
      debugPrint('Restore failed: $e');
      if (mounted) {
        setState(() {
          _applying = false;
          _error = backupErrorMessage(l10n, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatter = ref.watch(dateFormatterProvider);
    final header = _header;
    final prepared = _prepared;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsRestore)),
      body: PageBody(
        children: [
          AppCard(
            color: context.semantic.warningContainer,
            child: Text(l10n.restoreIntro),
          ),
          const SizedBox(height: Gap.lg),
          if (_error != null) ...[
            AppCard(
              color: context.colors.errorContainer,
              child: Text(
                _error!,
                key: const ValueKey('restore-error'),
                style: TextStyle(color: context.colors.onErrorContainer),
              ),
            ),
            const SizedBox(height: Gap.md),
          ],
          if (header != null) ...[
            AppCard(
              child: Row(
                children: [
                  IconBadge(
                    icon: Icons.inventory_2_outlined,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fileName ?? '',
                          style: context.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          l10n.restoreBackupInfo(
                            formatter.dateTime(header.createdAt.toLocal()),
                            header.appVersion,
                          ),
                          style: context.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.md),
          ],
          switch (_step) {
            _Step.choose => SubmitButton(
              icon: Icons.folder_open_rounded,
              label: l10n.restoreChooseFile,
              onSubmit: _choose,
            ),
            _Step.password => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PasswordField(
                  key: const ValueKey('restore-password'),
                  controller: _password,
                  label: l10n.backupPassword,
                  helperText: l10n.restoreEnterPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _check(),
                ),
                const SizedBox(height: Gap.lg),
                if (_working)
                  Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: Gap.md),
                      Expanded(child: Text(l10n.restoreVerifying)),
                    ],
                  )
                else ...[
                  SubmitButton(
                    icon: Icons.lock_open_rounded,
                    label: l10n.restoreCheck,
                    onSubmit: _check,
                  ),
                  TextButton(
                    onPressed: _choose,
                    child: Text(l10n.restoreChooseOther),
                  ),
                ],
              ],
            ),
            _Step.confirm => _Summary(
              summary: prepared!.summary,
              applying: _applying,
              onApply: _apply,
            ),
          },
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.summary,
    required this.applying,
    required this.onApply,
  });

  final RestoreSummary summary;
  final bool applying;
  final Future<void> Function() onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <(IconData, String, int)>[
      (
        Icons.account_balance_wallet_outlined,
        l10n.restoreCountAccounts,
        summary.count('accounts'),
      ),
      (
        Icons.receipt_long_outlined,
        l10n.restoreCountTransactions,
        summary.count('transactions'),
      ),
      (
        Icons.pie_chart_outline_rounded,
        l10n.restoreCountBudgets,
        summary.count('budgets'),
      ),
      (Icons.receipt_outlined, l10n.restoreCountBills, summary.count('bills')),
      (Icons.task_alt_rounded, l10n.restoreCountTasks, summary.count('tasks')),
      (
        Icons.savings_outlined,
        l10n.restoreCountSavings,
        summary.count('savings_goals'),
      ),
      (
        Icons.handshake_outlined,
        l10n.restoreCountLoans,
        summary.count('loans'),
      ),
      (Icons.image_outlined, l10n.restoreCountPhotos, summary.attachmentCount),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_rounded, color: context.semantic.success),
                  const SizedBox(width: Gap.sm),
                  Expanded(
                    child: Text(
                      l10n.restoreVerified,
                      style: context.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              for (final (icon, label, count) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: Gap.md),
                      Expanded(child: Text(label)),
                      Text('$count', style: context.textTheme.titleSmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        Text(l10n.restoreConfirmBody),
        const SizedBox(height: Gap.lg),
        if (applying)
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: Gap.md),
              Expanded(child: Text(l10n.restoreInProgress)),
            ],
          )
        else
          FilledButton.icon(
            key: const ValueKey('restore-apply'),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.restore_rounded),
            label: Text(l10n.restoreAction),
            onPressed: onApply,
          ),
      ],
    );
  }
}
