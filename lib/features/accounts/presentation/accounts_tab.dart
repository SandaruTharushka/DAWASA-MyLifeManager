import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/providers.dart';
import '../../../ui/icons/app_icons.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/money_widgets.dart';
import '../data/account_repository.dart';
import 'account_providers.dart';

class AccountsTab extends ConsumerWidget {
  const AccountsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(accountBalancesProvider);
    final summary = ref.watch(balanceSummaryProvider);
    final currency = ref.watch(currencyProvider);
    return AsyncValueView(
      value: async,
      data: (balances) {
        final active = balances.where((b) => !b.account.isArchived).toList();
        final archived = balances.where((b) => b.account.isArchived).toList();
        return PageBody(
          children: [
            const SizedBox(height: Gap.sm),
            AppCard(
              color: context.colors.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.accountTotalBalance(currency.code),
                    style: context.textTheme.labelLarge?.copyWith(
                      color: context.colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: Gap.xs),
                  MoneyText(
                    summary.value?.totalMinor ?? 0,
                    style: context.textTheme.headlineMedium?.copyWith(
                      color: context.colors.onPrimaryContainer,
                    ),
                  ),
                  if (summary.value?.hasOtherCurrencies ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: Gap.xs),
                      child: Text(
                        l10n.accountOtherCurrencies,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SectionHeader(
              title: l10n.accountsTitle,
              actionLabel: l10n.accountAdd,
              onAction: () => context.push(Routes.newAccount),
            ),
            if (active.isEmpty)
              EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                message: l10n.accountEmpty,
                actionLabel: l10n.accountAdd,
                onAction: () => context.push(Routes.newAccount),
              )
            else
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                child: Column(
                  children: [for (final b in active) AccountTile(balance: b)],
                ),
              ),
            if (archived.isNotEmpty) ...[
              SectionHeader(title: l10n.accountArchivedSection),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                child: Column(
                  children: [for (final b in archived) AccountTile(balance: b)],
                ),
              ),
            ],
            const SizedBox(height: Gap.md),
            Text(
              l10n.txSplitNote,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}

class AccountTile extends StatelessWidget {
  const AccountTile({super.key, required this.balance});

  final AccountBalance balance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = balance.account;
    final color = a.colorValue != null
        ? Color(a.colorValue!)
        : context.colors.primary;
    return ListTile(
      onTap: () => context.push(Routes.account(a.id)),
      leading: IconBadge(icon: AppIcons.forAccountType(a.type), color: color),
      title: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          l10n.accountTypeLabel(a.type),
          if (a.currencyCode != 'LKR' || !a.includeInTotal) a.currencyCode,
        ].join(' · '),
      ),
      trailing: MoneyText(
        balance.balanceMinor,
        currency: Currencies.byCode(a.currencyCode),
        style: context.textTheme.titleSmall,
        color: balance.balanceMinor < 0 ? context.semantic.expense : null,
      ),
    );
  }
}
