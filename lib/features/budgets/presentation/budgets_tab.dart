import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/money_widgets.dart';
import '../../transactions/domain/transaction_models.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../domain/budget_logic.dart';
import 'budget_providers.dart';

extension BudgetPeriodLabel on AppLocalizations {
  String budgetPeriodLabel(BudgetPeriod p) => switch (p) {
    BudgetPeriod.daily => budgetPeriodDaily,
    BudgetPeriod.weekly => budgetPeriodWeekly,
    BudgetPeriod.monthly => budgetPeriodMonthly,
    BudgetPeriod.custom => budgetPeriodCustom,
  };
}

class BudgetsTab extends ConsumerWidget {
  const BudgetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(budgetProgressProvider);
    return AsyncValueView(
      value: async,
      data: (items) => PageBody(
        children: [
          if (items.isEmpty)
            EmptyState(
              icon: Icons.pie_chart_outline_rounded,
              message: l10n.budgetEmpty,
              actionLabel: l10n.budgetAdd,
              onAction: () => context.push(Routes.newBudget),
            )
          else
            for (final p in items)
              Padding(
                padding: const EdgeInsets.only(top: Gap.md),
                child: BudgetCard(progress: p),
              ),
          const SizedBox(height: Gap.lg),
          Text(
            l10n.budgetNotCounted,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetCard extends ConsumerWidget {
  const BudgetCard({super.key, required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = context.semantic;
    final p = progress;
    final currency = Currencies.byCode(p.budget.currencyCode);
    final formatter = ref.watch(dateFormatterProvider);
    final color = p.exceeded
        ? s.expense
        : p.alertLevel == BudgetAlertLevel.warning
        ? s.warning
        : s.income;
    final categories = [
      ...ref.watch(allCategoriesProvider(CategoryKind.expense)).value ??
          const [],
    ].where((c) => p.categoryIds.contains(c.id)).toList();

    String statusLine() {
      switch (p.window.status) {
        case BudgetStatus.notStarted:
          return l10n.budgetNotStarted(formatter.date(p.window.range.start));
        case BudgetStatus.ended:
          return l10n.budgetEnded;
        case BudgetStatus.active:
          final perDay = p.perDayLeftMinor;
          final days = l10n.budgetDaysLeft(p.daysLeft - 1);
          return perDay == null
              ? days
              : '$days · ${l10n.budgetPerDay(Money.format(perDay, currency))}';
      }
    }

    return AppCard(
      onTap: () => context.push(Routes.editBudget(p.budget.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.budget.name, style: context.textTheme.titleMedium),
                    Text(
                      [
                        l10n.budgetPeriodLabel(p.budget.period),
                        if (categories.isEmpty)
                          l10n.budgetScopeAll
                        else
                          categories.map((c) => c.label(l10n)).join(', '),
                      ].join(' · '),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: l10n.commonPercentUsed(p.percentUsed),
                color: color,
                background: color.withValues(alpha: 0.12),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          AppProgressBar(
            value: p.fraction,
            color: color,
            semanticsLabel: p.budget.name,
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: l10n.budgetSpent,
                  child: MoneyText(
                    p.spentMinor,
                    currency: currency,
                    style: context.textTheme.titleSmall,
                  ),
                ),
              ),
              Expanded(
                child: _Stat(
                  label: p.exceeded ? l10n.commonOverdue : l10n.budgetLeft,
                  child: p.exceeded
                      ? Text(
                          l10n.budgetOverBy(
                            Money.format(-p.remainingMinor, currency),
                          ),
                          style: context.textTheme.titleSmall?.copyWith(
                            color: s.expense,
                          ),
                        )
                      : MoneyText(
                          p.remainingMinor,
                          currency: currency,
                          style: context.textTheme.titleSmall,
                          color: color,
                        ),
                ),
              ),
              Expanded(
                child: _Stat(
                  label: l10n.commonTotal,
                  child: MoneyText(
                    p.amountMinor,
                    currency: currency,
                    style: context.textTheme.titleSmall,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text(
            statusLine(),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        child,
      ],
    );
  }
}
