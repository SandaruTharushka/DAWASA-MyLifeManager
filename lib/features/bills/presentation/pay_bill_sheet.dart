import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/time/local_date.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/form_widgets.dart';
import '../../../ui/widgets/money_widgets.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../budgets/presentation/budget_alerts.dart';
import '../../transactions/domain/transaction_models.dart';
import '../../transactions/presentation/widgets/pickers.dart';
import '../data/bill_repository.dart';
import 'bill_providers.dart';

Future<void> showPayBillSheet(BuildContext context, BillView view) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => PayBillSheet(view: view),
  );
}

/// Records the payment of a bill's current cycle and (optionally) the
/// matching expense, without ever creating a duplicate expense.
class PayBillSheet extends ConsumerStatefulWidget {
  const PayBillSheet({super.key, required this.view});

  final BillView view;

  @override
  ConsumerState<PayBillSheet> createState() => _PayBillSheetState();
}

class _PayBillSheetState extends ConsumerState<PayBillSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: Money.formatForInput(
      widget.view.bill.amountMinor,
      decimalDigits: _currency.decimalDigits,
    ),
  );
  late final String _paymentId = newId();
  late final String _transactionId = newId();
  late LocalDate _paidOn = ref.read(todayProvider);
  late String? _accountId = widget.view.bill.accountId;
  late bool _recordExpense = BillRepository.recordsAsExpenseByDefault(
    widget.view.bill.category,
  );

  Currency get _currency => Currencies.byCode(widget.view.bill.currencyCode);

  @override
  void initState() {
    super.initState();
    if (_accountId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final accounts = await ref.read(accountRepositoryProvider).accounts();
        if (mounted && accounts.isNotEmpty && _accountId == null) {
          setState(() => _accountId = accounts.first.id);
        }
      });
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<PaymentRecording?> _chooseRecording(int amount) async {
    if (!_recordExpense) return const NoExpense();
    final repo = ref.read(billRepositoryProvider);
    final candidates = await repo.duplicateCandidates(
      amountMinor: amount,
      around: _paidOn,
    );
    if (candidates.isEmpty || !mounted) {
      return RecordNewExpense(
        transactionId: _transactionId,
        accountId: _accountId!,
      );
    }
    final l10n = context.l10n;
    final formatter = ref.read(dateFormatterProvider);
    final candidate = candidates.first;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.billPossibleDuplicate),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.billPossibleDuplicateBody),
            const SizedBox(height: Gap.md),
            AppCard(
              padding: const EdgeInsets.all(Gap.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${candidate.transaction.description.isEmpty ? candidate.category?.label(l10n) ?? '' : candidate.transaction.description}\n'
                      '${formatter.date(candidate.transaction.localDate)} · ${candidate.account.name}',
                    ),
                  ),
                  Text(
                    Money.format(candidate.transaction.amountMinor, _currency),
                    style: context.textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('new'),
            child: Text(l10n.billCreateNew),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('link'),
            child: Text(l10n.billLinkExisting),
          ),
        ],
      ),
    );
    return switch (choice) {
      'link' => LinkExistingExpense(candidate.transaction.id),
      'new' => RecordNewExpense(
        transactionId: _transactionId,
        accountId: _accountId!,
      ),
      _ => null,
    };
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    final amount = parseMoneyField(_amount.text, _currency)!;
    final recording = await _chooseRecording(amount);
    if (recording == null) return;
    try {
      final now = ref.read(clockProvider)();
      await ref
          .read(billRepositoryProvider)
          .recordPayment(
            paymentId: _paymentId,
            billId: widget.view.bill.id,
            dueDate: widget.view.bill.nextDueDate,
            paidAt: _paidOn.atMinutes(now.hour * 60 + now.minute),
            amountMinor: amount,
            recording: recording,
          );
      if (recording is RecordNewExpense) {
        await ref.read(budgetAlertServiceProvider).checkAfterSpending();
      }
      if (!mounted) return;
      showAppSnackBar(context, l10n.billPaymentSaved);
      Navigator.of(context).pop();
    } on BillAlreadyPaidException {
      if (mounted) showAppSnackBar(context, l10n.billAlreadyPaid);
    } on ExpenseAlreadyLinkedException {
      if (mounted) showAppSnackBar(context, l10n.feedbackAlreadySaved);
    } on TransactionValidationException {
      if (mounted) showAppSnackBar(context, l10n.txSelectAccount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatter = ref.watch(dateFormatterProvider);
    final bill = widget.view.bill;
    final isLoan = bill.category == BillCategory.loan;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
            children: [
              Text(l10n.billPayTitle, style: context.textTheme.titleLarge),
              Text(
                '${bill.name} · ${formatter.date(bill.nextDueDate)}',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Gap.lg),
              MoneyField(
                controller: _amount,
                currency: _currency,
                label: l10n.billPaidAmount,
              ),
              const SizedBox(height: Gap.md),
              DateField(
                label: l10n.billPaidOn,
                value: _paidOn,
                onChanged: (d) {
                  if (d != null) setState(() => _paidOn = d);
                },
              ),
              const SizedBox(height: Gap.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.billRecordExpense),
                subtitle: Text(
                  isLoan ? l10n.billLoanNote : l10n.billRecordExpenseHelp,
                ),
                value: _recordExpense,
                onChanged: (v) => setState(() => _recordExpense = v),
              ),
              if (_recordExpense) ...[
                const SizedBox(height: Gap.sm),
                AccountPickerField(
                  label: l10n.txPaidFrom,
                  value: _accountId,
                  currencyCode: bill.currencyCode,
                  onChanged: (id) => setState(() => _accountId = id),
                ),
              ],
              const SizedBox(height: Gap.xl),
              SubmitButton(
                label: l10n.billMarkPaid,
                icon: Icons.check_rounded,
                onSubmit: _save,
              ),
              if (_recordExpense)
                Padding(
                  padding: const EdgeInsets.only(top: Gap.sm),
                  child: Text(
                    l10n.txSplitNote,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.semantic.mutedText,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
