import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/time/local_date.dart';
import '../../../ui/icons/app_icons.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/money_widgets.dart';
import '../../../ui/widgets/recurrence_editor.dart';
import '../data/bill_repository.dart';
import 'bill_providers.dart';
import 'bills_tab.dart';
import 'pay_bill_sheet.dart';

class BillDetailScreen extends ConsumerWidget {
  const BillDetailScreen({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bill = ref.watch(billByIdProvider(billId)).value;
    final payments = ref.watch(billPaymentsProvider(billId)).value ?? const [];
    final formatter = ref.watch(dateFormatterProvider);
    final today = ref.watch(todayProvider);
    if (bill == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final view = BillView(bill, payments.firstOrNull);
    final currency = Currencies.byCode(bill.currencyCode);
    final state = view.state(today);
    return Scaffold(
      appBar: AppBar(
        title: Text(bill.name),
        actions: [
          IconButton(
            tooltip: l10n.actionEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.editBill(bill.id)),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              final repo = ref.read(billRepositoryProvider);
              if (v == 'toggle') {
                await repo.setActive(bill.id, active: !bill.isActive);
              } else if (v == 'delete') {
                final ok = await confirmDialog(
                  context,
                  title: l10n.confirmDeleteTitle,
                  message: l10n.confirmDeleteMessage,
                  confirmLabel: l10n.actionDelete,
                  destructive: true,
                );
                if (ok) {
                  await repo.delete(bill.id);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Text(bill.isActive ? l10n.billStop : l10n.billResume),
              ),
              PopupMenuItem(value: 'delete', child: Text(l10n.actionDelete)),
            ],
          ),
        ],
      ),
      body: PageBody(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconBadge(
                      icon: AppIcons.forBillCategory(bill.category),
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: Text(
                        l10n.billCategoryLabel(bill.category),
                        style: context.textTheme.labelLarge,
                      ),
                    ),
                    StatusChip(
                      label: l10n.billDueLabel(view, today),
                      color: billStateColor(context, state),
                      background: billStateColor(
                        context,
                        state,
                      ).withValues(alpha: 0.12),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.md),
                MoneyText(
                  bill.amountMinor,
                  currency: currency,
                  sensitive: false,
                  style: context.textTheme.headlineSmall,
                ),
                const SizedBox(height: Gap.xs),
                if (bill.isActive)
                  Text(
                    '${l10n.billDueDate}: ${formatter.fullDay(bill.nextDueDate)}',
                  ),
                Text(
                  view.rule == null
                      ? l10n.billOneTime
                      : describeRecurrence(view.rule, l10n, formatter),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                if (bill.note != null) ...[
                  const SizedBox(height: Gap.sm),
                  Text(bill.note!),
                ],
                if (bill.isActive) ...[
                  const SizedBox(height: Gap.lg),
                  FilledButton.icon(
                    onPressed: () => showPayBillSheet(context, view),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l10n.billMarkPaid),
                  ),
                ],
              ],
            ),
          ),
          SectionHeader(title: l10n.billHistory),
          if (payments.isEmpty)
            AppCard(
              child: Text(
                l10n.billNoHistory,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: Gap.xs),
              child: Column(
                children: [
                  for (final p in payments)
                    ListTile(
                      leading: Icon(
                        Icons.check_circle_rounded,
                        color: context.semantic.success,
                      ),
                      title: Text(formatter.date(p.dueDate)),
                      subtitle: Text(
                        [
                          '${l10n.billPaidOn} ${formatter.date(LocalDate.fromDateTime(p.paidAt))}',
                          if (p.transactionId != null) l10n.billExpenseLinked,
                        ].join(' · '),
                      ),
                      onTap: p.transactionId == null
                          ? null
                          : () => context.push(
                              Routes.transaction(p.transactionId!),
                            ),
                      trailing: PopupMenuButton<String>(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'undo',
                            child: Text(l10n.billUndoPayment),
                          ),
                        ],
                        onSelected: (_) async {
                          final ok = await confirmDialog(
                            context,
                            title: l10n.billUndoPayment,
                            message: l10n.billUndoPaymentBody,
                          );
                          if (ok) {
                            await ref
                                .read(billRepositoryProvider)
                                .undoPayment(p.id);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(Gap.sm),
                          child: Text(
                            Money.format(p.amountMinor, currency),
                            style: context.textTheme.titleSmall,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
