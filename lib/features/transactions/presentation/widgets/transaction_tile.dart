import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/finance/transaction_rules.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/providers.dart';
import '../../../../core/time/local_date.dart';
import '../../../../ui/icons/app_icons.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/app_theme.dart';
import '../../../../ui/widgets/common.dart';
import '../../../../ui/widgets/money_widgets.dart';
import '../../domain/transaction_models.dart';

/// Colour, sign and icon for displaying a transaction.
class TransactionAppearance {
  const TransactionAppearance(this.color, this.sign, this.icon, this.iconColor);

  final Color color;
  final int sign;
  final IconData icon;
  final Color iconColor;

  static TransactionAppearance of(
    BuildContext context,
    TransactionView view, {
    String? perspectiveAccountId,
  }) {
    final s = context.semantic;
    final type = view.type;
    final categoryColor = view.category == null
        ? null
        : Color(view.category!.colorValue);
    final categoryIcon = view.category == null
        ? null
        : AppIcons.forKey(view.category!.iconKey);
    if (TransactionRules.countsAsSpending(type)) {
      return TransactionAppearance(
        s.expense,
        -1,
        categoryIcon ?? AppIcons.forTransactionType(type),
        categoryColor ?? s.expense,
      );
    }
    if (TransactionRules.countsAsIncome(type)) {
      return TransactionAppearance(
        s.income,
        1,
        categoryIcon ?? AppIcons.forTransactionType(type),
        categoryColor ?? s.income,
      );
    }
    if (type == TransactionType.transfer) {
      var sign = 0;
      if (perspectiveAccountId != null) {
        sign = view.transaction.accountId == perspectiveAccountId ? -1 : 1;
      }
      return TransactionAppearance(
        s.transfer,
        sign,
        AppIcons.forTransactionType(type),
        s.transfer,
      );
    }
    final inflow = TransactionRules.inflowTypes.contains(type);
    return TransactionAppearance(
      s.neutral,
      inflow ? 1 : -1,
      AppIcons.forTransactionType(type),
      s.neutral,
    );
  }
}

String transactionTitle(TransactionView view, AppLocalizations l10n) {
  final description = view.transaction.description.trim();
  if (description.isNotEmpty) return description;
  if (view.category != null) return view.category!.label(l10n);
  return l10n.transactionTypeLabel(view.type);
}

String transactionSubtitle(TransactionView view, AppLocalizations l10n) {
  final parts = <String>[];
  if (view.type == TransactionType.transfer) {
    parts.add('${view.account.name} → ${view.toAccount?.name ?? '?'}');
  } else {
    if (view.category != null &&
        view.transaction.description.trim().isNotEmpty) {
      parts.add(view.category!.label(l10n));
    } else if (view.category == null) {
      parts.add(l10n.transactionTypeLabel(view.type));
    }
    parts.add(view.account.name);
  }
  final source = l10n.transactionSourceLabel(view.transaction.source);
  if (source.isNotEmpty) parts.add(source);
  return parts.join(' · ');
}

class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.view,
    this.perspectiveAccountId,
    this.showDate = false,
  });

  final TransactionView view;
  final String? perspectiveAccountId;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final look = TransactionAppearance.of(
      context,
      view,
      perspectiveAccountId: perspectiveAccountId,
    );
    final currency = Currencies.byCode(view.transaction.currencyCode);
    final subtitle = transactionSubtitle(view, l10n);
    final formatter = ref.watch(dateFormatterProvider);
    final today = ref.watch(todayProvider);
    return ListTile(
      onTap: () => context.push(Routes.transaction(view.transaction.id)),
      leading: IconBadge(icon: look.icon, color: look.iconColor),
      title: Text(
        transactionTitle(view, l10n),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.titleSmall,
      ),
      subtitle: Text(
        showDate
            ? '${formatter.relativeDay(view.transaction.localDate, today, l10n)} · $subtitle'
            : subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Large amounts or large system text shrink the amount instead of
      // pushing the title off the tile.
      trailing: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.42,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (view.transaction.attachmentId != null)
                Padding(
                  padding: const EdgeInsets.only(right: Gap.xs),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 16,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              MoneyText(
                look.sign * view.transaction.amountMinor,
                currency: currency,
                showSign: look.sign != 0,
                color: look.color,
                sensitive: false,
                style: context.textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Groups transactions under date headers.
class GroupedTransactionList extends ConsumerWidget {
  const GroupedTransactionList({
    super.key,
    required this.items,
    this.perspectiveAccountId,
  });

  final List<TransactionView> items;
  final String? perspectiveAccountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.watch(dateFormatterProvider);
    final today = ref.watch(todayProvider);
    final l10n = context.l10n;
    final children = <Widget>[];
    LocalDate? current;
    for (final view in items) {
      final date = view.transaction.localDate;
      if (date != current) {
        current = date;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.xs),
            child: Semantics(
              header: true,
              child: Text(
                formatter.relativeDay(date, today, l10n) ==
                        formatter.shortDay(date)
                    ? formatter.fullDay(date)
                    : '${formatter.relativeDay(date, today, l10n)} · ${formatter.shortDay(date)}',
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }
      children.add(
        TransactionTile(view: view, perspectiveAccountId: perspectiveAccountId),
      );
    }
    return Column(children: children);
  }
}
