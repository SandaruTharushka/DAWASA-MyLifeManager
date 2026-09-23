import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../ui/icons/app_icons.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/form_widgets.dart';
import '../../../ui/widgets/money_widgets.dart';
import '../../transactions/presentation/transactions_tab.dart';
import '../data/account_repository.dart';
import 'account_providers.dart';

class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});

  final String accountId;

  Future<void> _delete(BuildContext context, WidgetRef ref, Account a) async {
    final l10n = context.l10n;
    final repo = ref.read(accountRepositoryProvider);
    if (await repo.hasTransactions(a.id)) {
      if (!context.mounted) return;
      final archive = await confirmDialog(
        context,
        title: l10n.actionArchive,
        message: l10n.accountDeleteBlocked,
        confirmLabel: l10n.actionArchive,
      );
      if (archive) await repo.setArchived(a.id, archived: true);
      return;
    }
    if (!context.mounted) return;
    final ok = await confirmDialog(
      context,
      title: l10n.confirmDeleteTitle,
      message: l10n.confirmDeleteMessage,
      confirmLabel: l10n.actionDelete,
      destructive: true,
    );
    if (!ok) return;
    try {
      await repo.delete(a.id);
      if (context.mounted) context.pop();
    } on AccountInUseException {
      if (context.mounted) showAppSnackBar(context, l10n.accountDeleteBlocked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final balances = ref.watch(accountBalancesProvider).value ?? const [];
    final balance = balances
        .where((b) => b.account.id == accountId)
        .firstOrNull;
    if (balance == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final a = balance.account;
    final currency = Currencies.byCode(a.currencyCode);
    return Scaffold(
      appBar: AppBar(
        title: Text(a.name),
        actions: [
          IconButton(
            tooltip: l10n.actionEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.editAccount(a.id)),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              final repo = ref.read(accountRepositoryProvider);
              switch (v) {
                case 'archive':
                  await repo.setArchived(a.id, archived: !a.isArchived);
                case 'delete':
                  if (context.mounted) await _delete(context, ref, a);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(
                  a.isArchived ? l10n.actionUnarchive : l10n.actionArchive,
                ),
              ),
              PopupMenuItem(value: 'delete', child: Text(l10n.actionDelete)),
            ],
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Gap.page, Gap.sm, Gap.page, 0),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconBadge(
                          icon: AppIcons.forAccountType(a.type),
                          color: context.colors.primary,
                        ),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: Text(
                            l10n.accountTypeLabel(a.type),
                            style: context.textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.md),
                    Text(
                      l10n.accountBalance,
                      style: context.textTheme.bodySmall,
                    ),
                    MoneyText(
                      balance.balanceMinor,
                      currency: currency,
                      style: context.textTheme.headlineMedium,
                      color: balance.balanceMinor < 0
                          ? context.semantic.expense
                          : null,
                    ),
                    const SizedBox(height: Gap.xs),
                    Text(
                      '${l10n.accountOpeningBalance}: ${Money.format(a.openingBalanceMinor, currency)}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Gap.md),
                    Wrap(
                      spacing: Gap.sm,
                      runSpacing: Gap.sm,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => context.push(
                            Routes.newTransaction(
                              type: TransactionType.transfer,
                              accountId: a.id,
                            ),
                          ),
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: Text(l10n.quickAddTransfer),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => BalanceCorrectionSheet(
                              account: a,
                              currentBalance: balance.balanceMinor,
                            ),
                          ),
                          icon: const Icon(Icons.tune_rounded),
                          label: Text(l10n.accountCorrectBalance),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: l10n.accountHistory,
              padding: const EdgeInsets.fromLTRB(Gap.page + 4, Gap.lg, 0, 0),
            ),
          ),
        ],
        body: TransactionsTab(accountId: a.id),
      ),
    );
  }
}

/// Lets the user enter the real balance; the difference is recorded as an
/// explicit correction (never as income or spending).
class BalanceCorrectionSheet extends ConsumerStatefulWidget {
  const BalanceCorrectionSheet({
    super.key,
    required this.account,
    required this.currentBalance,
  });

  final Account account;
  final int currentBalance;

  @override
  ConsumerState<BalanceCorrectionSheet> createState() =>
      _BalanceCorrectionSheetState();
}

class _BalanceCorrectionSheetState
    extends ConsumerState<BalanceCorrectionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: Money.formatForInput(
      widget.currentBalance,
      decimalDigits: _currency.decimalDigits,
    ),
  );
  late final String _txId = newId();

  Currency get _currency => Currencies.byCode(widget.account.currencyCode);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _actual =>
      parseMoneyField(_controller.text, _currency, allowNegative: true);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final actual = _actual;
    if (actual == null) return;
    await ref
        .read(accountRepositoryProvider)
        .correctBalance(
          accountId: widget.account.id,
          actualBalanceMinor: actual,
          occurredAt: ref.read(clockProvider)(),
          transactionId: _txId,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actual = _actual;
    final diff = actual == null ? null : actual - widget.currentBalance;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
            children: [
              Text(
                l10n.accountCorrectBalance,
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: Gap.sm),
              Text(l10n.accountCorrectBalanceBody),
              const SizedBox(height: Gap.lg),
              MoneyField(
                controller: _controller,
                currency: _currency,
                label: l10n.accountActualBalance,
                allowZero: true,
                allowNegative: true,
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Gap.sm),
              if (diff != null)
                Text(
                  diff == 0
                      ? l10n.accountCorrectionNone
                      : l10n.accountCorrectionPreview(
                          Money.format(diff, _currency, showSign: true),
                        ),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: diff == 0
                        ? context.colors.onSurfaceVariant
                        : context.semantic.warning,
                  ),
                ),
              const SizedBox(height: Gap.lg),
              SubmitButton(
                label: l10n.actionSave,
                onSubmit: diff == null || diff == 0 ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
