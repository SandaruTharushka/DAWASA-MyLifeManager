import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/backup/backup_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/form_widgets.dart';
import '../../security/app_lock.dart';
import '../data/backup_service.dart';
import 'backup_providers.dart';

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Password field with a show/hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: widget.controller,
      obscureText: !_visible,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      autofillHints: const [AutofillHints.newPassword],
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperMaxLines: 3,
        suffixIcon: IconButton(
          tooltip: _visible ? l10n.backupHidePassword : l10n.backupShowPassword,
          icon: Icon(
            _visible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
      validator: widget.validator,
    );
  }
}

/// Creates an encrypted backup and lets the user save or share it.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final BackupService _service;
  BackupFile? _result;
  bool _creating = false;
  bool _stored = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ref.read(backupServiceProvider);
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    // The encrypted file is only needed until it was saved or shared.
    if (_result != null) _service.discardTemporaryFiles().ignore();
    super.dispose();
  }

  Future<void> _create() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final result = await _service.createBackup(_password.text);
      if (!mounted) return;
      setState(() {
        _result = result;
        _stored = false;
      });
    } on Object catch (e) {
      debugPrint('Backup failed: $e');
      if (mounted) setState(() => _error = context.l10n.backupFailed);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _markStored() async {
    await ref
        .read(preferencesProvider.notifier)
        .update((p) => p.copyWith(lastBackupAt: ref.read(clockProvider)()));
    if (!mounted) return;
    setState(() => _stored = true);
    showAppSnackBar(context, context.l10n.backupSavedTo);
  }

  Future<void> _save(BackupFile file) async {
    final bytes = await file.file.readAsBytes();
    final uri = await ref
        .read(appLockProvider.notifier)
        .whileExternal(
          () => FilePicker.saveFile(
            fileName: file.fileName,
            bytes: bytes,
            mimeType: BackupFormat.mimeType,
          ),
        );
    if (uri != null) await _markStored();
  }

  Future<void> _share(BackupFile file) async {
    final result = await ref
        .read(appLockProvider.notifier)
        .whileExternal(
          () => SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.file.path, mimeType: BackupFormat.mimeType)],
              fileNameOverrides: [file.fileName],
              subject: file.fileName,
            ),
          ),
        );
    if (result.status != ShareResultStatus.dismissed) await _markStored();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsBackup)),
      body: PageBody(
        children: [
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(
                  icon: Icons.enhanced_encryption_outlined,
                  color: context.colors.primary,
                ),
                const SizedBox(width: Gap.md),
                Expanded(child: Text(l10n.backupIntro)),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          if (result == null)
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PasswordField(
                    key: const ValueKey('backup-password'),
                    controller: _password,
                    label: l10n.backupPassword,
                    helperText: l10n.backupPasswordRules,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v ?? '').length < BackupFormat.minPasswordLength
                        ? l10n.backupPasswordTooShort
                        : null,
                  ),
                  const SizedBox(height: Gap.md),
                  PasswordField(
                    key: const ValueKey('backup-password-confirm'),
                    controller: _confirm,
                    label: l10n.backupPasswordConfirm,
                    textInputAction: TextInputAction.done,
                    validator: (v) => v != _password.text
                        ? l10n.backupPasswordMismatch
                        : null,
                  ),
                  const SizedBox(height: Gap.lg),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(color: context.colors.error),
                    ),
                    const SizedBox(height: Gap.sm),
                  ],
                  if (_creating)
                    Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        const SizedBox(width: Gap.md),
                        Expanded(child: Text(l10n.backupCreating)),
                      ],
                    )
                  else
                    SubmitButton(
                      icon: Icons.lock_outline_rounded,
                      label: l10n.settingsBackup,
                      onSubmit: _create,
                    ),
                ],
              ),
            )
          else
            _BackupReady(
              file: result,
              stored: _stored,
              onSave: () => _save(result),
              onShare: () => _share(result),
            ),
          const SizedBox(height: Gap.lg),
          AppCard(
            color: context.semantic.warningContainer,
            child: Text(l10n.backupKeepSafe),
          ),
        ],
      ),
    );
  }
}

class _BackupReady extends StatelessWidget {
  const _BackupReady({
    required this.file,
    required this.stored,
    required this.onSave,
    required this.onShare,
  });

  final BackupFile file;
  final bool stored;
  final Future<void> Function() onSave;
  final Future<void> Function() onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = context.semantic;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon: Icons.check_rounded, color: s.success),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.backupCreated,
                      style: context.textTheme.titleMedium,
                    ),
                    Text(
                      '${file.fileName} · ${formatBytes(file.sizeBytes)}',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Text(
            stored ? l10n.backupStoredHint : l10n.backupNotStoredYet,
            style: context.textTheme.bodyMedium?.copyWith(
              color: stored ? s.success : context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Gap.md),
          SubmitButton(
            icon: Icons.save_alt_rounded,
            label: l10n.backupSaveToDevice,
            onSubmit: onSave,
          ),
          const SizedBox(height: Gap.sm),
          SubmitButton(
            icon: Icons.share_rounded,
            label: l10n.backupShareFile,
            tonal: true,
            onSubmit: onShare,
          ),
        ],
      ),
    );
  }
}
