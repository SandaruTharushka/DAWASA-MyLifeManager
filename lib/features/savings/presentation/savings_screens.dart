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
import '../../../ui/icons/app_icons.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/form_widgets.dart';
import '../../../ui/widgets/money_widgets.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../transactions/presentation/widgets/pickers.dart';
import '../data/savings_repository.dart';
import 'savings_providers.dart';

class SavingsTab extends ConsumerWidget {
  const SavingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AsyncValueView(
      value: ref.watch(savingsGoalsProvider),
      data: (goals) {
        if (goals.isEmpty) {
          return EmptyState(
            icon: Icons.savings_outlined,
            message: l10n.savingsEmpty,
            actionLabel: l10n.savingsAdd,
            onAction: () => context.push(Routes.newSavingsGoal),
          );
        }
        final currency = ref.watch(currencyProvider);
        final total = goals
            .where((g) => g.goal.currencyCode == currency.code)
            .fold<int>(0, (s, g) => s + g.savedMinor);
        return PageBody(
          children: [
            const SizedBox(height: Gap.sm),
            AppCard(
              color: context.colors.primaryContainer,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.savingsTotalSaved,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: context.colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  MoneyText(
                    total,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: context.colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            for (final g in goals)
              Padding(
                padding: const EdgeInsets.only(top: Gap.md),
                child: SavingsGoalCard(view: g),
              ),
          ],
        );
      },
    );
  }
}

class SavingsGoalCard extends ConsumerWidget {
  const SavingsGoalCard({super.key, required this.view, this.compact = false});

  final SavingsGoalView view;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final g = view.goal;
    final currency = Currencies.byCode(g.currencyCode);
    final color = Color(g.colorValue);
    final formatter = ref.watch(dateFormatterProvider);
    return AppCard(
      onTap: () => context.push(Routes.savingsGoal(g.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: AppIcons.forKey(g.iconKey),
                color: color,
                size: 40,
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.name, style: context.textTheme.titleSmall),
                    if (g.targetDate != null)
                      Text(
                        formatter.date(g.targetDate!),
                        style: context.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (view.reached)
                StatusChip(
                  label: l10n.savingsReached,
                  icon: Icons.emoji_events_rounded,
                  color: context.semantic.success,
                  background: context.semantic.successContainer,
                )
              else
                Text(
                  '${view.percent}%',
                  style: context.textTheme.titleSmall?.copyWith(color: color),
                ),
            ],
          ),
          const SizedBox(height: Gap.md),
          AppProgressBar(
            value: view.fraction,
            color: color,
            semanticsLabel: g.name,
          ),
          const SizedBox(height: Gap.sm),
          Row(
            children: [
              Expanded(
                child: MoneyText(
                  view.savedMinor,
                  currency: currency,
                  style: context.textTheme.bodyMedium,
                ),
              ),
              Text(
                '${l10n.savingsTarget}: ${Money.format(g.targetAmountMinor, currency)}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SavingsGoalFormScreen extends ConsumerStatefulWidget {
  const SavingsGoalFormScreen({super.key, this.goalId});

  final String? goalId;

  @override
  ConsumerState<SavingsGoalFormScreen> createState() =>
      _SavingsGoalFormScreenState();
}

class _SavingsGoalFormScreenState extends ConsumerState<SavingsGoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _target = TextEditingController();
  late final String _id = widget.goalId ?? newId();
  LocalDate? _targetDate;
  String? _linkedAccountId;
  String _icon = 'savings';
  int _color = AppIcons.colorChoices.first;
  bool _remind = false;
  late String _currencyCode = ref.read(currencyProvider).code;
  bool _loading = false;

  bool get _isEdit => widget.goalId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final view = await ref.read(savingsRepositoryProvider).goal(widget.goalId!);
    if (!mounted || view == null) return;
    final g = view.goal;
    setState(() {
      _name.text = g.name;
      _target.text = Money.formatForInput(
        g.targetAmountMinor,
        decimalDigits: Currencies.byCode(g.currencyCode).decimalDigits,
      );
      _targetDate = g.targetDate;
      _linkedAccountId = g.linkedAccountId;
      _icon = g.iconKey;
      _color = g.colorValue;
      _remind = g.remindMonthly;
      _currencyCode = g.currencyCode;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(savingsRepositoryProvider)
        .saveGoal(
          SavingsGoalDraft(
            id: _id,
            name: _name.text,
            targetAmountMinor: parseMoneyField(
              _target.text,
              Currencies.byCode(_currencyCode),
            )!,
            currencyCode: _currencyCode,
            targetDate: _targetDate,
            linkedAccountId: _linkedAccountId,
            iconKey: _icon,
            colorValue: _color,
            remindMonthly: _remind,
          ),
        );
    if (!mounted) return;
    showAppSnackBar(context, context.l10n.feedbackSaved);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const icons = [
      'savings',
      'phone',
      'car',
      'bike',
      'home',
      'travel',
      'school',
      'health',
      'gift',
      'laptop',
      'star',
      'shield',
    ];
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.savingsEdit : l10n.savingsAdd)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: PageBody(
                children: [
                  TextFormField(
                    controller: _name,
                    autofocus: !_isEdit,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.savingsName,
                      hintText: l10n.savingsNameHint,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : null,
                  ),
                  MoneyField(
                    controller: _target,
                    currency: Currencies.byCode(_currencyCode),
                    label: l10n.savingsTarget,
                    large: true,
                  ),
                  const SizedBox(height: Gap.md),
                  DateField(
                    label: l10n.savingsTargetDate,
                    value: _targetDate,
                    clearable: true,
                    firstDate: ref.read(todayProvider),
                    onChanged: (d) => setState(() => _targetDate = d),
                  ),
                  const SizedBox(height: Gap.md),
                  AccountPickerField(
                    label: l10n.savingsLinkedAccount,
                    value: _linkedAccountId,
                    allowNone: true,
                    noneLabel: l10n.savingsNoLinkedAccount,
                    currencyCode: _currencyCode,
                    onChanged: (id) => setState(() => _linkedAccountId = id),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.sm,
                      Gap.xs,
                      Gap.sm,
                      0,
                    ),
                    child: Text(
                      l10n.savingsLinkedAccountHelp,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: Gap.lg),
                  Text(l10n.categoryIcon, style: context.textTheme.labelLarge),
                  const SizedBox(height: Gap.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final key in icons)
                        ChoiceChip(
                          label: Icon(
                            AppIcons.forKey(key),
                            color: Color(_color),
                            size: 20,
                          ),
                          selected: _icon == key,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _icon = key),
                        ),
                    ],
                  ),
                  const SizedBox(height: Gap.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in AppIcons.colorChoices.take(10))
                        InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => setState(() => _color = c),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: c == _color
                                    ? context.colors.onSurface
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Gap.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.savingsRemindMonthly),
                    value: _remind,
                    onChanged: (v) => setState(() => _remind = v),
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

class SavingsGoalDetailScreen extends ConsumerWidget {
  const SavingsGoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(savingsGoalProvider(goalId)).value;
    final movements =
        ref.watch(savingsMovementsProvider(goalId)).value ?? const [];
    final formatter = ref.watch(dateFormatterProvider);
    final today = ref.watch(todayProvider);
    if (view == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final g = view.goal;
    final currency = Currencies.byCode(g.currencyCode);
    final color = Color(g.colorValue);
    final monthly = view.monthlyNeededMinor(today);
    return Scaffold(
      appBar: AppBar(
        title: Text(g.name),
        actions: [
          IconButton(
            tooltip: l10n.actionEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.editSavingsGoal(g.id)),
          ),
          IconButton(
            tooltip: l10n.actionDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                title: l10n.confirmDeleteTitle,
                message: l10n.savingsDeleteBody,
                confirmLabel: l10n.actionDelete,
                destructive: true,
              );
              if (!ok) return;
              await ref.read(savingsRepositoryProvider).deleteGoal(g.id);
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
      body: PageBody(
        children: [
          AppCard(
            child: Column(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: view.fraction,
                          strokeWidth: 12,
                          color: color,
                          backgroundColor: context.colors.surfaceContainerHigh,
                          semanticsLabel: g.name,
                          semanticsValue: '${view.percent}%',
                        ),
                      ),
                      Text(
                        '${view.percent}%',
                        style: context.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Gap.lg),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            l10n.savingsSaved,
                            style: context.textTheme.labelSmall,
                          ),
                          MoneyText(
                            view.savedMinor,
                            currency: currency,
                            style: context.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            l10n.savingsToGo,
                            style: context.textTheme.labelSmall,
                          ),
                          MoneyText(
                            view.remainingMinor,
                            currency: currency,
                            style: context.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (monthly != null) ...[
                  const SizedBox(height: Gap.md),
                  Text(
                    l10n.savingsMonthlyNeeded(Money.format(monthly, currency)),
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: Gap.lg),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            _openMove(context, view, deposit: true),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l10n.savingsDeposit),
                      ),
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: view.savedMinor <= 0
                            ? null
                            : () => _openMove(context, view, deposit: false),
                        icon: const Icon(Icons.remove_rounded),
                        label: Text(l10n.savingsWithdraw),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionHeader(title: l10n.savingsHistory),
          if (movements.isEmpty)
            AppCard(child: Text(l10n.emptyGeneric))
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: Gap.xs),
              child: Column(
                children: [
                  for (final m in movements)
                    ListTile(
                      leading: Icon(
                        m.type == SavingsMovementType.deposit
                            ? Icons.south_rounded
                            : Icons.north_rounded,
                        color: m.type == SavingsMovementType.deposit
                            ? context.semantic.income
                            : context.semantic.warning,
                      ),
                      title: Text(
                        m.type == SavingsMovementType.deposit
                            ? l10n.savingsDeposit
                            : l10n.savingsWithdraw,
                      ),
                      subtitle: Text(
                        [
                          formatter.date(m.localDate),
                          if (m.transactionId != null) l10n.txTypeTransfer,
                          if (m.note != null) m.note!,
                        ].join(' · '),
                      ),
                      trailing: Text(
                        Money.format(m.amountMinor, currency),
                        style: context.textTheme.titleSmall,
                      ),
                      onLongPress: () async {
                        final ok = await confirmDialog(
                          context,
                          title: l10n.confirmDeleteTitle,
                          message: l10n.confirmDeleteMessage,
                          confirmLabel: l10n.actionDelete,
                          destructive: true,
                        );
                        if (ok) {
                          await ref
                              .read(savingsRepositoryProvider)
                              .deleteMovement(m.id);
                        }
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openMove(
    BuildContext context,
    SavingsGoalView view, {
    required bool deposit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MoveSheet(view: view, deposit: deposit),
    );
  }
}

class _MoveSheet extends ConsumerStatefulWidget {
  const _MoveSheet({required this.view, required this.deposit});

  final SavingsGoalView view;
  final bool deposit;

  @override
  ConsumerState<_MoveSheet> createState() => _MoveSheetState();
}

class _MoveSheetState extends ConsumerState<_MoveSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  late final String _movementId = newId();
  String? _accountId;
  late LocalDate _date = ref.read(todayProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final accounts = await ref.read(accountRepositoryProvider).accounts();
      final linked = widget.view.goal.linkedAccountId;
      final other = accounts
          .where(
            (a) =>
                a.id != linked &&
                a.currencyCode == widget.view.goal.currencyCode,
          )
          .firstOrNull;
      if (mounted) setState(() => _accountId = other?.id);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    final currency = Currencies.byCode(widget.view.goal.currencyCode);
    final amount = parseMoneyField(_amount.text, currency)!;
    final repo = ref.read(savingsRepositoryProvider);
    final now = ref.read(clockProvider)();
    final at = _date.atMinutes(now.hour * 60 + now.minute);
    try {
      if (widget.deposit) {
        await repo.deposit(
          movementId: _movementId,
          goalId: widget.view.goal.id,
          amountMinor: amount,
          occurredAt: at,
          fromAccountId: _accountId,
        );
      } else {
        await repo.withdraw(
          movementId: _movementId,
          goalId: widget.view.goal.id,
          amountMinor: amount,
          occurredAt: at,
          toAccountId: _accountId,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on InsufficientSavingsException {
      if (mounted) showAppSnackBar(context, l10n.savingsWithdrawTooMuch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final g = widget.view.goal;
    final currency = Currencies.byCode(g.currencyCode);
    final accounts = ref.watch(activeAccountsProvider).value ?? const [];
    final linked = accounts.where((a) => a.id == g.linkedAccountId).firstOrNull;
    final other = accounts.where((a) => a.id == _accountId).firstOrNull;
    final moves = linked != null && other != null && other.id != linked.id;
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
                widget.deposit ? l10n.savingsDeposit : l10n.savingsWithdraw,
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: Gap.lg),
              MoneyField(
                controller: _amount,
                currency: currency,
                autofocus: true,
              ),
              const SizedBox(height: Gap.md),
              DateField(
                label: l10n.commonDate,
                value: _date,
                onChanged: (d) {
                  if (d != null) setState(() => _date = d);
                },
              ),
              if (linked != null) ...[
                const SizedBox(height: Gap.md),
                AccountPickerField(
                  label: widget.deposit
                      ? l10n.savingsFromAccount
                      : l10n.savingsToAccount,
                  value: _accountId,
                  excludeId: linked.id,
                  allowNone: true,
                  noneLabel: l10n.savingsNoLinkedAccount,
                  currencyCode: g.currencyCode,
                  onChanged: (id) => setState(() => _accountId = id),
                ),
              ],
              const SizedBox(height: Gap.sm),
              Text(
                moves
                    ? l10n.savingsDepositNote(
                        widget.deposit ? other.name : linked.name,
                        widget.deposit ? linked.name : other.name,
                      )
                    : l10n.savingsTrackOnlyNote,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
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
