import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
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
import '../../transactions/presentation/widgets/pickers.dart';
import '../data/loan_repository.dart';
import 'loan_providers.dart';

class LoansTab extends ConsumerWidget {
  const LoansTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currency = ref.watch(currencyProvider);
    return AsyncValueView(
      value: ref.watch(loansProvider),
      data: (loans) {
        if (loans.isEmpty) {
          return EmptyState(
            icon: Icons.handshake_outlined,
            message: l10n.loanEmpty,
            actionLabel: l10n.loanAdd,
            onAction: () => context.push(Routes.newLoan),
          );
        }
        var owedToYou = 0, youOwe = 0;
        for (final l in loans.where(
          (l) => l.loan.currencyCode == currency.code,
        )) {
          if (l.isLent) {
            owedToYou += l.outstandingMinor;
          } else {
            youOwe += l.outstandingMinor;
          }
        }
        final active = loans
            .where((l) => l.loan.status == LoanStatus.active)
            .toList();
        final settled = loans
            .where((l) => l.loan.status == LoanStatus.settled)
            .toList();
        return PageBody(
          children: [
            const SizedBox(height: Gap.sm),
            Row(
              children: [
                Expanded(
                  child: _TotalCard(
                    label: l10n.loanOwedToYou,
                    amount: owedToYou,
                    color: context.semantic.income,
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: _TotalCard(
                    label: l10n.loanYouOwe,
                    amount: youOwe,
                    color: context.semantic.expense,
                  ),
                ),
              ],
            ),
            if (active.isNotEmpty) ...[
              SectionHeader(title: l10n.loanActive),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                child: Column(
                  children: [for (final l in active) LoanTile(view: l)],
                ),
              ),
            ],
            if (settled.isNotEmpty) ...[
              SectionHeader(title: l10n.loanSettled),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                child: Column(
                  children: [for (final l in settled) LoanTile(view: l)],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textTheme.labelMedium),
          const SizedBox(height: Gap.xs),
          MoneyText(amount, style: context.textTheme.titleMedium, color: color),
        ],
      ),
    );
  }
}

class LoanTile extends ConsumerWidget {
  const LoanTile({super.key, required this.view});

  final LoanView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final l = view.loan;
    final formatter = ref.watch(dateFormatterProvider);
    final today = ref.watch(todayProvider);
    final color = view.isLent
        ? context.semantic.income
        : context.semantic.expense;
    final overdue =
        l.status == LoanStatus.active &&
        l.dueDate != null &&
        l.dueDate!.isBefore(today);
    return ListTile(
      onTap: () => context.push(Routes.loan(l.id)),
      leading: IconBadge(
        icon: view.isLent ? Icons.north_east_rounded : Icons.south_west_rounded,
        color: color,
      ),
      title: Text(l.counterparty, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          view.isLent ? l10n.loanOwedToYou : l10n.loanYouOwe,
          if (l.dueDate != null && l.status == LoanStatus.active)
            l10n.loanDueOn(formatter.date(l.dueDate!)),
        ].join(' · '),
        style: TextStyle(color: overdue ? context.semantic.expense : null),
      ),
      trailing: MoneyText(
        view.outstandingMinor,
        currency: Currencies.byCode(l.currencyCode),
        style: context.textTheme.titleSmall,
        color: l.status == LoanStatus.settled
            ? context.colors.onSurfaceVariant
            : color,
      ),
    );
  }
}

class LoanFormScreen extends ConsumerStatefulWidget {
  const LoanFormScreen({super.key, this.loanId});

  final String? loanId;

  @override
  ConsumerState<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends ConsumerState<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _person = TextEditingController();
  final _principal = TextEditingController();
  final _rate = TextEditingController();
  final _note = TextEditingController();
  late final String _id = widget.loanId ?? newId();
  LoanDirection _direction = LoanDirection.lent;
  late LocalDate _start = ref.read(todayProvider);
  LocalDate? _due;
  bool _record = true;
  String? _accountId;
  bool _reminders = true;
  late String _currencyCode = ref.read(currencyProvider).code;
  bool _loading = false;
  bool _hasMovement = false;

  bool get _isEdit => widget.loanId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final view = await ref.read(loanRepositoryProvider).loan(widget.loanId!);
    if (!mounted || view == null) return;
    final l = view.loan;
    final currency = Currencies.byCode(l.currencyCode);
    setState(() {
      _direction = l.direction;
      _person.text = l.counterparty;
      _principal.text = Money.formatForInput(
        l.principalMinor,
        decimalDigits: currency.decimalDigits,
      );
      _rate.text = l.interestRateBps == null
          ? ''
          : Money.formatForInput(l.interestRateBps!, decimalDigits: 2);
      _note.text = l.note ?? '';
      _start = l.startDate;
      _due = l.dueDate;
      _accountId = l.accountId;
      _hasMovement = l.disbursementTransactionId != null;
      _record = _hasMovement;
      _reminders = l.remindersEnabled;
      _currencyCode = l.currencyCode;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _person.dispose();
    _principal.dispose();
    _rate.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final currency = Currencies.byCode(_currencyCode);
    await ref
        .read(loanRepositoryProvider)
        .save(
          LoanDraft(
            id: _id,
            direction: _direction,
            counterparty: _person.text,
            principalMinor: parseMoneyField(_principal.text, currency)!,
            currencyCode: _currencyCode,
            startDate: _start,
            dueDate: _due,
            interestRateBps: Money.tryParse(_rate.text),
            accountId: _record ? _accountId : null,
            recordMovement: _record && !_isEdit,
            remindersEnabled: _reminders,
            note: _note.text,
          ),
        );
    if (!mounted) return;
    showAppSnackBar(context, context.l10n.feedbackSaved);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = Currencies.byCode(_currencyCode);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.loanEdit : l10n.loanAdd)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: PageBody(
                children: [
                  SegmentedButton<LoanDirection>(
                    segments: [
                      ButtonSegment(
                        value: LoanDirection.lent,
                        label: Text(l10n.loanLent),
                      ),
                      ButtonSegment(
                        value: LoanDirection.borrowed,
                        label: Text(l10n.loanBorrowed),
                      ),
                    ],
                    selected: {_direction},
                    onSelectionChanged: _isEdit
                        ? null
                        : (s) => setState(() => _direction = s.first),
                  ),
                  const SizedBox(height: Gap.lg),
                  TextFormField(
                    controller: _person,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.loanPerson),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : null,
                  ),
                  MoneyField(
                    controller: _principal,
                    currency: currency,
                    label: l10n.loanPrincipal,
                    large: true,
                  ),
                  const SizedBox(height: Gap.md),
                  TextFormField(
                    controller: _rate,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.loanInterestRate,
                      suffixText: '%',
                    ),
                    validator: (v) =>
                        (v == null ||
                            v.trim().isEmpty ||
                            Money.tryParse(v) != null)
                        ? null
                        : l10n.validationNumberInvalid,
                  ),
                  const SizedBox(height: Gap.md),
                  Row(
                    children: [
                      Expanded(
                        child: DateField(
                          label: l10n.loanStartDate,
                          value: _start,
                          onChanged: (d) {
                            if (d != null) setState(() => _start = d);
                          },
                        ),
                      ),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: DateField(
                          label: l10n.loanDueDate,
                          value: _due,
                          clearable: true,
                          firstDate: _start,
                          onChanged: (d) => setState(() => _due = d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.loanRecordMovement),
                    subtitle: Text(l10n.loanRecordMovementHelp),
                    value: _record,
                    onChanged: _isEdit
                        ? null
                        : (v) => setState(() => _record = v),
                  ),
                  if (_record && !_hasMovement)
                    AccountPickerField(
                      label: _direction == LoanDirection.lent
                          ? l10n.txPaidFrom
                          : l10n.txReceivedInto,
                      value: _accountId,
                      currencyCode: _currencyCode,
                      onChanged: (id) => setState(() => _accountId = id),
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.billRemind),
                    value: _reminders,
                    onChanged: (v) => setState(() => _reminders = v),
                  ),
                  TextFormField(
                    controller: _note,
                    maxLength: 300,
                    decoration: InputDecoration(
                      labelText: l10n.commonNote,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: Gap.xl),
                  SubmitButton(
                    label: l10n.actionSave,
                    icon: Icons.check_rounded,
                    onSubmit: _save,
                  ),
                ],
              ),
            ),
    );
  }
}

class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({super.key, required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(loanProvider(loanId)).value;
    final repayments =
        ref.watch(loanRepaymentsProvider(loanId)).value ?? const [];
    final formatter = ref.watch(dateFormatterProvider);
    if (view == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final l = view.loan;
    final currency = Currencies.byCode(l.currencyCode);
    final color = view.isLent
        ? context.semantic.income
        : context.semantic.expense;
    final repo = ref.read(loanRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.counterparty),
        actions: [
          IconButton(
            tooltip: l10n.actionEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.editLoan(l.id)),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'settle':
                  final ok = await confirmDialog(
                    context,
                    title: l10n.loanSettle,
                    message: l10n.loanSettleBody,
                  );
                  if (ok) await repo.settle(l.id);
                case 'reopen':
                  await repo.reopen(l.id);
                case 'delete':
                  final ok = await confirmDialog(
                    context,
                    title: l10n.confirmDeleteTitle,
                    message: l10n.loanDeleteBody,
                    confirmLabel: l10n.actionDelete,
                    destructive: true,
                  );
                  if (ok) {
                    await repo.delete(l.id);
                    if (context.mounted) context.pop();
                  }
              }
            },
            itemBuilder: (context) => [
              if (l.status == LoanStatus.active)
                PopupMenuItem(value: 'settle', child: Text(l10n.loanSettle))
              else
                PopupMenuItem(value: 'reopen', child: Text(l10n.loanReopen)),
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
                StatusChip(
                  label: view.isLent ? l10n.loanOwedToYou : l10n.loanYouOwe,
                  color: color,
                  background: color.withValues(alpha: 0.12),
                ),
                const SizedBox(height: Gap.md),
                Text(
                  l10n.loanOutstanding,
                  style: context.textTheme.labelMedium,
                ),
                MoneyText(
                  view.outstandingMinor,
                  currency: currency,
                  style: context.textTheme.headlineMedium,
                  color: color,
                ),
                const SizedBox(height: Gap.md),
                AppProgressBar(value: view.fractionRepaid, color: color),
                const SizedBox(height: Gap.sm),
                Text(
                  '${l10n.loanRepaid}: ${Money.format(view.repaidPrincipalMinor, currency)} · '
                  '${l10n.loanPrincipal}: ${Money.format(l.principalMinor, currency)}',
                  style: context.textTheme.bodySmall,
                ),
                if (l.dueDate != null)
                  Text(
                    l10n.loanDueOn(formatter.date(l.dueDate!)),
                    style: context.textTheme.bodySmall,
                  ),
                if (l.interestRateBps != null)
                  Text(
                    '${Money.formatPlain(l.interestRateBps!)}%',
                    style: context.textTheme.bodySmall,
                  ),
                if (l.status == LoanStatus.settled) ...[
                  const SizedBox(height: Gap.sm),
                  StatusChip(
                    label: l10n.loanSettled,
                    icon: Icons.check_rounded,
                    color: context.semantic.success,
                    background: context.semantic.successContainer,
                  ),
                ],
                if (l.status == LoanStatus.active) ...[
                  const SizedBox(height: Gap.lg),
                  FilledButton.icon(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _RepaymentSheet(view: view),
                    ),
                    icon: const Icon(Icons.payments_rounded),
                    label: Text(l10n.loanRecordRepayment),
                  ),
                ],
              ],
            ),
          ),
          SectionHeader(title: l10n.loanHistory),
          if (repayments.isEmpty)
            AppCard(child: Text(l10n.loanNoRepayments))
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: Gap.xs),
              child: Column(
                children: [
                  for (final r in repayments)
                    ListTile(
                      title: Text(
                        Money.format(
                          r.principalMinor + r.interestMinor,
                          currency,
                        ),
                      ),
                      subtitle: Text(
                        [
                          formatter.date(r.localDate),
                          if (r.interestMinor > 0)
                            '${l10n.catInterest}: ${Money.format(r.interestMinor, currency)}',
                        ].join(' · '),
                      ),
                      trailing: IconButton(
                        tooltip: l10n.actionDelete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () async {
                          final ok = await confirmDialog(
                            context,
                            title: l10n.confirmDeleteTitle,
                            message: l10n.confirmDeleteMessage,
                            destructive: true,
                          );
                          if (ok) await repo.deleteRepayment(r.id);
                        },
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

class _RepaymentSheet extends ConsumerStatefulWidget {
  const _RepaymentSheet({required this.view});

  final LoanView view;

  @override
  ConsumerState<_RepaymentSheet> createState() => _RepaymentSheetState();
}

class _RepaymentSheetState extends ConsumerState<_RepaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _principal = TextEditingController(
    text: Money.formatForInput(
      widget.view.outstandingMinor,
      decimalDigits: _currency.decimalDigits,
    ),
  );
  final _interest = TextEditingController();
  late final String _id = newId();
  late String? _accountId = widget.view.loan.accountId;
  bool _record = true;
  late LocalDate _date = ref.read(todayProvider);

  Currency get _currency => Currencies.byCode(widget.view.loan.currencyCode);

  @override
  void dispose() {
    _principal.dispose();
    _interest.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    final principal = parseMoneyField(_principal.text, _currency) ?? 0;
    final interest = parseMoneyField(_interest.text, _currency) ?? 0;
    if (principal + interest <= 0) {
      showAppSnackBar(context, l10n.validationAmountPositive);
      return;
    }
    try {
      final now = ref.read(clockProvider)();
      await ref
          .read(loanRepositoryProvider)
          .recordRepayment(
            repaymentId: _id,
            loanId: widget.view.loan.id,
            principalMinor: principal,
            interestMinor: interest,
            paidAt: _date.atMinutes(now.hour * 60 + now.minute),
            accountId: _record ? _accountId : null,
          );
      if (mounted) Navigator.of(context).pop();
    } on OverpaymentException {
      if (mounted) showAppSnackBar(context, l10n.loanRepaymentTooMuch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lent = widget.view.isLent;
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
                l10n.loanRecordRepayment,
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: Gap.lg),
              MoneyField(
                controller: _principal,
                currency: _currency,
                label: l10n.loanRepaymentPrincipal,
                required: false,
                allowZero: true,
              ),
              const SizedBox(height: Gap.md),
              MoneyField(
                controller: _interest,
                currency: _currency,
                label: l10n.loanRepaymentInterest,
                helperText: l10n.loanRepaymentInterestHelp,
                required: false,
                allowZero: true,
              ),
              const SizedBox(height: Gap.md),
              DateField(
                label: l10n.commonDate,
                value: _date,
                onChanged: (d) {
                  if (d != null) setState(() => _date = d);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.loanRecordMovement),
                value: _record,
                onChanged: (v) => setState(() => _record = v),
              ),
              if (_record)
                AccountPickerField(
                  label: lent ? l10n.txReceivedInto : l10n.txPaidFrom,
                  value: _accountId,
                  currencyCode: widget.view.loan.currencyCode,
                  onChanged: (id) => setState(() => _accountId = id),
                ),
              const SizedBox(height: Gap.xl),
              SubmitButton(label: l10n.actionSave, onSubmit: _save),
            ],
          ),
        ),
      ),
    );
  }
}
