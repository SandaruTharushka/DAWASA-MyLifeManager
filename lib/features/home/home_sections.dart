import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/l10n/l10n.dart';
import '../../core/money/money.dart';
import '../../core/providers.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/money_widgets.dart';
import '../bills/presentation/bill_providers.dart';
import '../bills/presentation/bills_tab.dart';
import '../budgets/domain/daily_allowance.dart';
import '../budgets/presentation/budget_providers.dart';
import '../tasks/presentation/task_providers.dart';
import '../tasks/presentation/tasks_tab.dart';

/// "Left to spend today" card.
class DailyBudgetCard extends ConsumerWidget {
  const DailyBudgetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final allowance = ref.watch(dailyAllowanceProvider).value;
    final s = context.semantic;
    if (allowance == null) {
      return AppCard(
        onTap: () => editDailyBudget(context, ref),
        child: Row(
          children: [
            IconBadge(
              icon: Icons.savings_outlined,
              color: context.colors.primary,
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Text(
                l10n.homeNoBudget,
                style: context.textTheme.titleSmall,
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      );
    }
    final exceeded = allowance.exceeded;
    final color = exceeded
        ? s.expense
        : allowance.usedFraction >= 0.8
        ? s.warning
        : s.income;
    final currency = ref.watch(currencyProvider);
    return AppCard(
      onTap: allowance.source == AllowanceSource.dailyBudget
          ? () => editDailyBudget(context, ref)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exceeded
                      ? l10n.homeBudgetExceeded(
                          Money.format(-allowance.remainingMinor, currency),
                        )
                      : l10n.homeRemainingBudget,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: exceeded ? s.expense : null,
                  ),
                ),
              ),
              if (!exceeded)
                MoneyText(
                  allowance.remainingMinor,
                  style: context.textTheme.titleMedium,
                  color: color,
                ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          AppProgressBar(
            value: allowance.usedFraction,
            color: color,
            semanticsLabel: l10n.homeRemainingBudget,
          ),
          const SizedBox(height: Gap.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  allowance.source == AllowanceSource.monthlyBudget
                      ? l10n.homeBudgetFromMonthly
                      : l10n.settingsDailyBudget,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              MoneyText(
                allowance.allowanceMinor,
                style: context.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dialog to set or clear the daily budget.
Future<void> editDailyBudget(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final currency = ref.read(currencyProvider);
  final current = ref.read(userSettingsProvider).dailyBudgetMinor;
  final controller = TextEditingController(
    text: current == null
        ? ''
        : Money.formatForInput(current, decimalDigits: currency.decimalDigits),
  );
  final formKey = GlobalKey<FormState>();
  final result = await showDialog<(bool, int?)>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.settingsDailyBudget),
      content: Form(
        key: formKey,
        child: MoneyField(
          controller: controller,
          currency: currency,
          required: false,
          autofocus: true,
        ),
      ),
      actions: [
        if (current != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop((true, null)),
            child: Text(l10n.actionClear),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.of(context)
                .pop((true, parseMoneyField(controller.text, currency)));
          },
          child: Text(l10n.actionSave),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null || !result.$1) return;
  await ref
      .read(userSettingsProvider.notifier)
      .update(
        (s) => s.copyWith(
          dailyBudgetMinor: result.$2,
          clearDailyBudget: result.$2 == null,
        ),
      );
}

/// Sections contributed by planner, bills and savings modules.
class HomeExtraSections extends StatelessWidget {
  const HomeExtraSections({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _PendingTasksSection(),
      _UpcomingPaymentsSection(),
      ...homeMoneySections,
    ],
  );
}

/// Savings goals summary (schema v3).
const List<Widget> homeMoneySections = [];

class _PendingTasksSection extends ConsumerWidget {
  const _PendingTasksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tasks = ref.watch(todayTasksProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title:
              '${l10n.homePendingTasks} · ${l10n.taskCountToday(tasks.length)}',
          actionLabel: l10n.homeSeeTasks,
          onAction: () => context.go(Routes.plannerTab('tasks')),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: Gap.xs),
          child: tasks.isEmpty
              ? ListTile(
                  leading: Icon(
                    Icons.wb_sunny_outlined,
                    color: context.colors.primary,
                  ),
                  title: Text(l10n.homeNoPendingTasks),
                  trailing: TextButton(
                    onPressed: () => context.push(Routes.newTask),
                    child: Text(l10n.actionAdd),
                  ),
                )
              : Column(
                  children: [
                    for (final t in tasks.take(4))
                      TaskTile(item: t, compact: true),
                  ],
                ),
        ),
      ],
    );
  }
}

class _UpcomingPaymentsSection extends ConsumerWidget {
  const _UpcomingPaymentsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bills = ref.watch(upcomingBillsProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.homeUpcomingPayments,
          actionLabel: l10n.homeSeeBills,
          onAction: () => context.go(Routes.moneyTab('bills')),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: Gap.xs),
          child: bills.isEmpty
              ? ListTile(
                  leading: Icon(
                    Icons.event_available_outlined,
                    color: context.colors.primary,
                  ),
                  title: Text(l10n.homeNoUpcomingPayments),
                )
              : Column(
                  children: [for (final b in bills.take(4)) BillTile(view: b)],
                ),
        ),
      ],
    );
  }
}
