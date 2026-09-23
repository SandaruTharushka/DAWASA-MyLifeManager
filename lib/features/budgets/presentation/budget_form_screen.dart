import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../transactions/domain/transaction_models.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../data/budget_repository.dart';
import 'budget_alerts.dart';
import 'budget_providers.dart';
import 'budgets_tab.dart';

class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({super.key, this.budgetId});

  final String? budgetId;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  late final String _id = widget.budgetId ?? newId();
  BudgetPeriod _period = BudgetPeriod.monthly;
  late LocalDate _start = ref.read(todayProvider);
  late LocalDate _end = ref.read(todayProvider).addDays(29);
  int _warn = 80;
  bool _notify = true;
  bool _limitToCategories = false;
  Set<String> _categories = {};
  bool _loading = false;
  bool _categoryError = false;

  bool get _isEdit => widget.budgetId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final repo = ref.read(budgetRepositoryProvider);
    final b = await repo.byId(widget.budgetId!);
    final cats = await repo.categoriesOf(widget.budgetId!);
    if (!mounted || b == null) return;
    final currency = Currencies.byCode(b.currencyCode);
    setState(() {
      _name.text = b.name;
      _amount.text = Money.formatForInput(
        b.amountMinor,
        decimalDigits: currency.decimalDigits,
      );
      _period = b.period;
      _start = b.startDate ?? _start;
      _end = b.endDate ?? _end;
      _warn = b.warnPercent;
      _notify = b.notify;
      _categories = cats;
      _limitToCategories = cats.isNotEmpty;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final ok = _formKey.currentState!.validate();
    setState(() => _categoryError = _limitToCategories && _categories.isEmpty);
    if (!ok || _categoryError) return;
    if (_period == BudgetPeriod.custom && _end.isBefore(_start)) {
      showAppSnackBar(context, l10n.validationEndBeforeStart);
      return;
    }
    final currency = ref.read(currencyProvider);
    await ref
        .read(budgetRepositoryProvider)
        .save(
          BudgetDraft(
            id: _id,
            name: _name.text,
            period: _period,
            amountMinor: parseMoneyField(_amount.text, currency)!,
            currencyCode: currency.code,
            startDate: _start,
            endDate: _end,
            warnPercent: _warn,
            notify: _notify,
            categoryIds: _limitToCategories ? _categories : const {},
          ),
        );
    await ref.read(budgetAlertServiceProvider).checkAfterSpending();
    if (!mounted) return;
    showAppSnackBar(context, l10n.feedbackSaved);
    context.pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l10n.budgetDeleteTitle,
      message: l10n.budgetDeleteBody,
      confirmLabel: l10n.actionDelete,
      destructive: true,
    );
    if (!ok) return;
    await ref.read(budgetRepositoryProvider).delete(_id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = ref.watch(currencyProvider);
    final categories =
        ref.watch(categoriesProvider(CategoryKind.expense)).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.budgetEdit : l10n.budgetAdd),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: l10n.actionDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: PageBody(
                children: [
                  TextFormField(
                    controller: _name,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(labelText: l10n.budgetName),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : null,
                  ),
                  const SizedBox(height: Gap.sm),
                  MoneyField(
                    controller: _amount,
                    currency: currency,
                    label: l10n.budgetAmount,
                    large: true,
                  ),
                  const SizedBox(height: Gap.lg),
                  Text(l10n.budgetPeriod, style: context.textTheme.labelLarge),
                  const SizedBox(height: Gap.sm),
                  Wrap(
                    spacing: Gap.sm,
                    runSpacing: Gap.sm,
                    children: [
                      for (final p in BudgetPeriod.values)
                        ChoiceChip(
                          label: Text(l10n.budgetPeriodLabel(p)),
                          selected: _period == p,
                          onSelected: (_) => setState(() => _period = p),
                        ),
                    ],
                  ),
                  if (_period == BudgetPeriod.custom) ...[
                    const SizedBox(height: Gap.md),
                    DateField(
                      label: l10n.commonStartDate,
                      value: _start,
                      onChanged: (d) {
                        if (d != null) setState(() => _start = d);
                      },
                    ),
                    const SizedBox(height: Gap.md),
                    DateField(
                      label: l10n.commonEndDate,
                      value: _end,
                      firstDate: _start,
                      onChanged: (d) {
                        if (d != null) setState(() => _end = d);
                      },
                    ),
                  ],
                  const SizedBox(height: Gap.lg),
                  Text(l10n.budgetScope, style: context.textTheme.labelLarge),
                  const SizedBox(height: Gap.sm),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(l10n.budgetScopeAll),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.budgetScopeCategories),
                      ),
                    ],
                    selected: {_limitToCategories},
                    onSelectionChanged: (s) =>
                        setState(() => _limitToCategories = s.first),
                  ),
                  if (_limitToCategories) ...[
                    const SizedBox(height: Gap.md),
                    Wrap(
                      spacing: Gap.sm,
                      runSpacing: Gap.sm,
                      children: [
                        for (final c in categories)
                          FilterChip(
                            avatar: Icon(
                              AppIcons.forKey(c.iconKey),
                              size: 18,
                              color: Color(c.colorValue),
                            ),
                            label: Text(c.label(l10n)),
                            selected: _categories.contains(c.id),
                            onSelected: (on) => setState(() {
                              _categories = {..._categories};
                              on
                                  ? _categories.add(c.id)
                                  : _categories.remove(c.id);
                              _categoryError = false;
                            }),
                          ),
                      ],
                    ),
                    if (_categoryError)
                      Padding(
                        padding: const EdgeInsets.only(top: Gap.sm),
                        child: Text(
                          l10n.budgetChooseCategories,
                          style: TextStyle(color: context.colors.error),
                        ),
                      ),
                  ],
                  const SizedBox(height: Gap.lg),
                  Text(
                    l10n.budgetWarnAt(_warn),
                    style: context.textTheme.labelLarge,
                  ),
                  Slider(
                    value: _warn.toDouble(),
                    min: 50,
                    max: 100,
                    divisions: 10,
                    label: '$_warn%',
                    onChanged: (v) => setState(() => _warn = v.round()),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.budgetNotify),
                    value: _notify,
                    onChanged: (v) => setState(() => _notify = v),
                  ),
                  const SizedBox(height: Gap.sm),
                  Text(
                    l10n.budgetNotCounted,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
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
