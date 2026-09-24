import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/database/app_database.dart';
import '../../core/l10n/l10n.dart';
import '../../core/money/money.dart';
import '../../core/providers.dart';
import '../../ui/charts/charts.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/money_widgets.dart';
import '../accounts/presentation/account_providers.dart';
import '../backup/presentation/backup_reminder.dart';
import '../transactions/presentation/transaction_providers.dart';
import '../transactions/presentation/widgets/transaction_tile.dart';
import '../updates/presentation/update_screen.dart';
import 'home_sections.dart';
import 'quick_add_sheet.dart';

/// Daily overview: balance, today's cash flow, budget, chart, recent items.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.actionAdd,
        onPressed: () => showQuickAddSheet(context),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: const SafeArea(
        bottom: false,
        child: PageBody(
          padding: EdgeInsets.fromLTRB(Gap.page, Gap.md, Gap.page, 120),
          children: [
            _Header(),
            UpdateBanner(),
            BackupReminderCard(),
            SizedBox(height: Gap.lg),
            _BalanceCard(),
            SizedBox(height: Gap.md),
            DailyBudgetCard(),
            SizedBox(height: Gap.md),
            _QuickActions(),
            HomeExtraSections(),
            _SpendingChartSection(),
            _RecentTransactionsSection(),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final today = ref.watch(todayProvider);
    final formatter = ref.watch(dateFormatterProvider);
    final name = ref.watch(userSettingsProvider.select((s) => s.userName));
    final hidden = ref.watch(balancesHiddenProvider);
    final hour = ref.watch(clockProvider)().hour;
    final greeting = hour < 12
        ? l10n.greetingMorning
        : hour < 17
        ? l10n.greetingAfternoon
        : l10n.greetingEvening;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatter.fullDay(today),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Semantics(
                header: true,
                child: Text(
                  name == null
                      ? greeting
                      : l10n.greetingWithName(greeting, name),
                  style: context.textTheme.headlineSmall,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: hidden ? l10n.homeShowBalances : l10n.homeHideBalances,
          onPressed: () => ref.read(balancesHiddenProvider.notifier).toggle(),
          icon: Icon(
            hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(balanceSummaryProvider).value;
    final totals = ref.watch(todayTotalsProvider).value;
    const onCard = Colors.white;
    Widget stat(String label, int value, {bool signed = false}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: onCard.withValues(alpha: 0.85),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 2),
          MoneyText(
            value,
            showSign: signed,
            compact: true,
            style: context.textTheme.titleSmall?.copyWith(color: onCard),
          ),
        ],
      ),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.card),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.green, AppPalette.darkGreen],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3316A34A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: onCard,
                size: 20,
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Text(
                  l10n.homeAvailableBalance,
                  style: context.textTheme.labelLarge?.copyWith(color: onCard),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.go(Routes.moneyTab('accounts')),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    l10n.tabAccounts,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: onCard,
                      decoration: TextDecoration.underline,
                      decorationColor: onCard,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          MoneyText(
            summary?.totalMinor ?? 0,
            style: context.textTheme.headlineMedium?.copyWith(
              color: onCard,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: Gap.lg),
          Row(
            children: [
              stat(l10n.homeTodayIncome, totals?.incomeMinor ?? 0),
              stat(l10n.homeTodayExpenses, totals?.expenseMinor ?? 0),
              stat(l10n.homeTodayNet, totals?.netMinor ?? 0, signed: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = context.semantic;
    Widget action(
      IconData icon,
      String label,
      Color color,
      VoidCallback onTap,
    ) {
      return Expanded(
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.field),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Gap.sm),
              child: Column(
                children: [
                  IconBadge(icon: icon, color: color, size: 48),
                  const SizedBox(height: Gap.xs),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: context.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Gap.xs, vertical: Gap.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          action(
            Icons.remove_circle_outline_rounded,
            l10n.quickAddExpense,
            s.expense,
            () => context.push(Routes.newTransaction()),
          ),
          action(
            Icons.add_circle_outline_rounded,
            l10n.quickAddIncome,
            s.income,
            () => context.push(
              Routes.newTransaction(type: TransactionType.income),
            ),
          ),
          action(
            Icons.task_alt_rounded,
            l10n.quickAddTask,
            s.transfer,
            () => openNewTask(context),
          ),
          action(
            Icons.insights_rounded,
            l10n.quickViewReports,
            s.warning,
            () => context.go(Routes.reports),
          ),
        ],
      ),
    );
  }
}

class _SpendingChartSection extends ConsumerWidget {
  const _SpendingChartSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(last7DaysSpendingProvider).value;
    final formatter = ref.watch(dateFormatterProvider);
    final today = ref.watch(todayProvider);
    final currency = ref.watch(currencyProvider);
    final hidden = ref.watch(balancesHiddenProvider);
    if (data == null) return const SizedBox.shrink();
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final total = entries.fold<int>(0, (s, e) => s + e.value);
    final summary = entries
        .map(
          (e) =>
              '${formatter.weekdayShort(e.key)} ${Money.format(e.value, currency)}',
        )
        .join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.homeLast7Days),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(l10n.commonTotal, style: context.textTheme.bodySmall),
                  const Spacer(),
                  MoneyText(
                    total,
                    style: context.textTheme.titleSmall,
                    color: context.semantic.expense,
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              MoneyBarChart(
                hidden: hidden,
                currency: currency,
                color: context.semantic.expense,
                semanticsLabel: hidden
                    ? l10n.homeLast7Days
                    : l10n.homeChartSemantics(summary),
                points: [
                  for (final e in entries)
                    BarPoint(
                      label: formatter.weekdayShort(e.key),
                      valueMinor: e.value,
                      highlight: e.key == today,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentTransactionsSection extends ConsumerWidget {
  const _RecentTransactionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(recentTransactionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.homeRecentTransactions,
          actionLabel: l10n.actionSeeAll,
          onAction: () => context.go(Routes.moneyTab('transactions')),
        ),
        AsyncValueView(
          value: async,
          compact: true,
          data: (items) => items.isEmpty
              ? AppCard(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: l10n.homeNoTransactions,
                    compact: true,
                  ),
                )
              : AppCard(
                  padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                  child: Column(
                    children: [
                      for (final v in items)
                        TransactionTile(view: v, showDate: true),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
