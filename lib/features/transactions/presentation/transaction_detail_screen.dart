import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/providers.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/money_widgets.dart';
import '../domain/transaction_models.dart';
import 'transaction_providers.dart';
import 'widgets/transaction_tile.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.id});

  final String id;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TransactionView view,
  ) async {
    final l10n = context.l10n;
    final linked =
        view.transaction.source != TransactionSource.manual &&
        view.transaction.source != TransactionSource.recurring;
    final ok = await confirmDialog(
      context,
      title: l10n.txDeleteTitle,
      message: linked
          ? '${l10n.txDeleteLinkedWarning}\n\n${l10n.confirmDeleteMessage}'
          : l10n.confirmDeleteMessage,
      confirmLabel: l10n.actionDelete,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final attachmentId = view.transaction.attachmentId;
    await ref.read(transactionRepositoryProvider).delete(view.transaction.id);
    if (attachmentId != null) {
      await ref.read(attachmentStoreProvider).delete(attachmentId);
    }
    if (!context.mounted) return;
    showAppSnackBar(context, l10n.feedbackDeleted);
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(transactionByIdProvider(id));
    final formatter = ref.watch(dateFormatterProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.txDetails),
        actions: [
          if (async.value != null) ...[
            IconButton(
              tooltip: l10n.actionEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(Routes.editTransaction(id)),
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                final view = async.value!;
                switch (action) {
                  case 'duplicate':
                    context.pushReplacement(
                      Routes.newTransaction(
                        type: view.type,
                        duplicateOf: view.transaction.id,
                      ),
                    );
                  case 'delete':
                    _delete(context, ref, view);
                }
              },
              itemBuilder: (context) => [
                if (async.value!.transaction.source ==
                        TransactionSource.manual ||
                    async.value!.transaction.source ==
                        TransactionSource.recurring)
                  PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: const Icon(Icons.copy_rounded),
                      title: Text(l10n.actionDuplicate),
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: context.colors.error,
                    ),
                    title: Text(l10n.actionDelete),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: AsyncValueView(
        value: async,
        data: (view) {
          if (view == null) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              message: l10n.txNoResults,
            );
          }
          final t = view.transaction;
          final look = TransactionAppearance.of(context, view);
          final currency = Currencies.byCode(t.currencyCode);
          Widget row(IconData icon, String label, String value) => ListTile(
            leading: Icon(icon),
            title: Text(label, style: context.textTheme.bodySmall),
            subtitle: Text(value, style: context.textTheme.bodyLarge),
          );
          return PageBody(
            children: [
              AppCard(
                child: Column(
                  children: [
                    IconBadge(icon: look.icon, color: look.iconColor, size: 56),
                    const SizedBox(height: Gap.md),
                    Text(
                      transactionTitle(view, l10n),
                      style: context.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Gap.sm),
                    MoneyText(
                      look.sign * t.amountMinor,
                      currency: currency,
                      showSign: look.sign != 0,
                      color: look.color,
                      sensitive: false,
                      style: context.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: Gap.sm),
                    StatusChip(
                      label: l10n.transactionTypeLabel(t.type),
                      color: look.color,
                      background: look.color.withValues(alpha: 0.12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.md),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: Gap.sm),
                child: Column(
                  children: [
                    if (view.category != null)
                      row(
                        Icons.category_outlined,
                        l10n.commonCategory,
                        view.category!.label(l10n),
                      ),
                    if (t.type == TransactionType.transfer) ...[
                      row(
                        Icons.logout_rounded,
                        l10n.txFromAccount,
                        view.account.name,
                      ),
                      row(
                        Icons.login_rounded,
                        l10n.txToAccount,
                        view.toAccount?.name ?? '',
                      ),
                    ] else
                      row(
                        Icons.account_balance_wallet_outlined,
                        l10n.commonAccount,
                        view.account.name,
                      ),
                    row(
                      Icons.event_outlined,
                      l10n.commonDate,
                      '${formatter.fullDay(t.localDate)} · ${formatter.time(t.occurredAt.toLocal())}',
                    ),
                    if (t.note != null && t.note!.isNotEmpty)
                      row(Icons.notes_rounded, l10n.commonNote, t.note!),
                    if (t.source != TransactionSource.manual)
                      row(
                        Icons.link_rounded,
                        l10n.commonDetails,
                        l10n.transactionSourceLabel(t.source),
                      ),
                  ],
                ),
              ),
              if (t.attachmentId != null) ...[
                const SizedBox(height: Gap.md),
                _ReceiptImage(attachmentId: t.attachmentId!),
              ],
              if (t.recurringRuleId != null) ...[
                const SizedBox(height: Gap.md),
                OutlinedButton.icon(
                  onPressed: () => context.push(Routes.recurring),
                  icon: const Icon(Icons.repeat_rounded),
                  label: Text(l10n.recurringTitle),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReceiptImage extends ConsumerWidget {
  const _ReceiptImage({required this.attachmentId});

  final String attachmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<File?>(
      future: ref.read(attachmentStoreProvider).fileFor(attachmentId),
      builder: (context, snap) {
        final file = snap.data;
        if (file == null) return const SizedBox.shrink();
        return AppCard(
          padding: EdgeInsets.zero,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                body: InteractiveViewer(
                  maxScale: 5,
                  child: Center(child: Image.file(file)),
                ),
              ),
            ),
          ),
          child: Image.file(
            file,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            cacheWidth: 900,
            semanticLabel: context.l10n.txReceipt,
          ),
        );
      },
    );
  }
}
