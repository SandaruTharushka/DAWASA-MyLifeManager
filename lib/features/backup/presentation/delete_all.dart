import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/platform/data_paths.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import 'backup_providers.dart';

/// Asks the user to type the confirmation word before erasing everything.
Future<bool> confirmDeleteAll(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => const _DeleteAllDialog(),
  );
  return result ?? false;
}

/// Erases all data and restarts the app with the welcome guide.
Future<void> deleteAllData(WidgetRef ref) =>
    ref.read(dataWiperProvider).wipe(ref.read(appReloaderProvider));

class _DeleteAllDialog extends StatefulWidget {
  const _DeleteAllDialog();

  @override
  State<_DeleteAllDialog> createState() => _DeleteAllDialogState();
}

class _DeleteAllDialogState extends State<_DeleteAllDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final word = l10n.deleteAllConfirmWord;
    final matches = _controller.text.trim().toUpperCase() == word;
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: context.colors.error),
      title: Text(l10n.deleteAllTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteAllBody),
            const SizedBox(height: Gap.sm),
            Text(
              l10n.deleteAllBackupFirst,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Gap.md),
            TextField(
              key: const ValueKey('delete-all-confirm'),
              controller: _controller,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.deleteAllTypeWord(word),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.error,
            foregroundColor: context.colors.onError,
          ),
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.deleteAllAction),
        ),
      ],
    );
  }
}
