import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/providers.dart';
import '../../../core/time/local_date.dart';
import '../../../ui/icons/app_icons.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/money_widgets.dart';
import '../data/bill_repository.dart';
import 'bill_providers.dart';
import 'pay_bill_sheet.dart';

extension BillLabels on AppLocalizations {
  String billCategoryLabel(BillCategory c) => switch (c) {
    BillCategory.electricity => billCatElectricity,
    BillCategory.water => billCatWater,
    BillCategory.internet => billCatInternet,
    BillCategory.mobile => billCatMobile,
    BillCategory.rent => billCatRent,
    BillCategory.insurance => billCatInsurance,
    BillCategory.loan => billCatLoan,
    BillCategory.other => billCatOther,
  };

  String billDueLabel(BillView v, LocalDate today) {
    final days = today.daysUntil(v.bill.nextDueDate);
    return switch (v.state(today)) {
      BillDueState.inactive => billInactive,
      BillDueState.overdue => billOverdueBy(-days),
      BillDueState.dueToday => billDueToday,
      _ => billDueIn(days),
    };
  }
}

Color billStateColor(BuildContext context, BillDueState s) => switch (s) {
  BillDueState.overdue => context.semantic.expense,
  BillDueState.dueToday => context.semantic.warning,
  BillDueState.dueSoon => context.semantic.warning,
  BillDueState.upcoming => context.semantic.neutral,
  BillDueState.inactive => context.semantic.success,
};

class BillsTab extends ConsumerWidget {
  const BillsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AsyncValueView(
      value: ref.watch(billsProvider),
      data: (bills) {
        if (bills.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            message: l10n.billEmpty,
            actionLabel: l10n.billAdd,
            onAction: () => context.push(Routes.newBill),
          );
        }
        final active = bills.where((b) => b.bill.isActive).toList();
        final inactive = bills.where((b) => !b.bill.isActive).toList();
        return PageBody(
          children: [
            if (active.isNotEmpty) ...[
              SectionHeader(title: l10n.billUpcoming),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                child: Column(
                  children: [for (final b in active) BillTile(view: b)],
                ),
              ),
            ],
            if (inactive.isNotEmpty) ...[
              SectionHeader(title: l10n.billInactive),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                child: Column(
                  children: [for (final b in inactive) BillTile(view: b)],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class BillTile extends ConsumerWidget {
  const BillTile({super.key, required this.view, this.showPayButton = true});

  final BillView view;
  final bool showPayButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final today = ref.watch(todayProvider);
    final formatter = ref.watch(dateFormatterProvider);
    final b = view.bill;
    final state = view.state(today);
    final color = billStateColor(context, state);
    return ListTile(
      onTap: () => context.push(Routes.bill(b.id)),
      leading: IconBadge(
        icon: AppIcons.forBillCategory(b.category),
        color: context.colors.primary,
      ),
      title: Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        b.isActive
            ? '${formatter.date(b.nextDueDate)} · ${l10n.billDueLabel(view, today)}'
            : l10n.billInactive,
        style: TextStyle(
          color: state == BillDueState.overdue ? color : null,
          fontWeight: state == BillDueState.overdue ? FontWeight.w600 : null,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MoneyText(
            b.amountMinor,
            currency: Currencies.byCode(b.currencyCode),
            sensitive: false,
            style: context.textTheme.titleSmall,
          ),
          if (showPayButton && b.isActive)
            InkWell(
              onTap: () => showPayBillSheet(context, view),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Text(
                  l10n.billMarkPaid,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
