import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/providers.dart';
import '../../../ui/icons/app_icons.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/money_widgets.dart';
import '../../../ui/widgets/recurrence_editor.dart';
import '../domain/transaction_models.dart';
import 'transaction_providers.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(recurringRulesProvider);
    final formatter = ref.watch(dateFormatterProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurringTitle)),
      body: AsyncValueView(
        value: async,
        data: (rules) {
          if (rules.isEmpty) {
            return EmptyState(
              icon: Icons.repeat_rounded,
              message: l10n.recurringEmpty,
            );
          }
          return PageBody(
            children: [
              for (final r in rules)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.sm),
                  child: AppCard(
                    padding: const EdgeInsets.all(Gap.md),
                    child: Row(
                      children: [
                        IconBadge(
                          icon: r.category != null
                              ? AppIcons.forKey(r.category!.iconKey)
                              : AppIcons.forTransactionType(r.row.type),
                          color: r.category != null
                              ? Color(r.category!.colorValue)
                              : context.semantic.transfer,
                        ),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.row.description.isNotEmpty
                                    ? r.row.description
                                    : r.category?.label(l10n) ??
                                          l10n.transactionTypeLabel(r.row.type),
                                style: context.textTheme.titleSmall,
                              ),
                              Text(
                                describeRecurrence(r.rule, l10n, formatter),
                                style: context.textTheme.bodySmall,
                              ),
                              Text(
                                r.row.isActive && r.row.nextDate != null
                                    ? l10n.recurringNext(
                                        formatter.date(r.row.nextDate!),
                                      )
                                    : l10n.recurringEnded,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            MoneyText(
                              r.row.amountMinor,
                              currency: Currencies.byCode(r.row.currencyCode),
                              sensitive: false,
                              style: context.textTheme.titleSmall,
                              color: r.row.type == TransactionType.expense
                                  ? context.semantic.expense
                                  : r.row.type == TransactionType.income
                                  ? context.semantic.income
                                  : context.semantic.transfer,
                            ),
                            PopupMenuButton<String>(
                              onSelected: (action) async {
                                final repo = ref.read(
                                  recurringRepositoryProvider,
                                );
                                final today = ref.read(todayProvider);
                                switch (action) {
                                  case 'pause':
                                    await repo.setActive(
                                      r.row.id,
                                      active: false,
                                      today: today,
                                    );
                                  case 'resume':
                                    await repo.setActive(
                                      r.row.id,
                                      active: true,
                                      today: today,
                                    );
                                    await repo.generateDue(
                                      today,
                                      onlyRuleId: r.row.id,
                                    );
                                  case 'stop':
                                    if (!context.mounted) return;
                                    final ok = await confirmDialog(
                                      context,
                                      title: l10n.recurringStop,
                                      message: l10n.recurringStopBody,
                                      destructive: true,
                                    );
                                    if (ok) await repo.delete(r.row.id);
                                }
                              },
                              itemBuilder: (context) => [
                                if (r.row.isActive)
                                  PopupMenuItem(
                                    value: 'pause',
                                    child: Text(l10n.recurringPause),
                                  )
                                else if (r.row.nextDate != null ||
                                    r.rule.until == null)
                                  PopupMenuItem(
                                    value: 'resume',
                                    child: Text(l10n.recurringResume),
                                  ),
                                PopupMenuItem(
                                  value: 'stop',
                                  child: Text(l10n.recurringStop),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
