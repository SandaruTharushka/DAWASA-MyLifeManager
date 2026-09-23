import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../ui/icons/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/form_widgets.dart';
import '../../../ui/widgets/money_widgets.dart';
import 'account_providers.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.accountId});

  final String? accountId;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _opening = TextEditingController();
  late final String _id = widget.accountId ?? newId();
  AccountType _type = AccountType.cash;
  late String _currencyCode = ref.read(currencyProvider).code;
  bool _includeInTotal = true;
  bool _loading = false;
  bool _hasTransactions = false;

  bool get _isEdit => widget.accountId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final repo = ref.read(accountRepositoryProvider);
    final account = await repo.byId(widget.accountId!);
    final hasTx = await repo.hasTransactions(widget.accountId!);
    if (!mounted || account == null) return;
    final currency = Currencies.byCode(account.currencyCode);
    setState(() {
      _name.text = account.name;
      _type = account.type;
      _currencyCode = account.currencyCode;
      _includeInTotal = account.includeInTotal;
      _opening.text = account.openingBalanceMinor == 0
          ? ''
          : Money.formatForInput(
              account.openingBalanceMinor,
              decimalDigits: currency.decimalDigits,
            );
      _hasTransactions = hasTx;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final currency = Currencies.byCode(_currencyCode);
    final opening =
        parseMoneyField(_opening.text, currency, allowNegative: true) ?? 0;
    final repo = ref.read(accountRepositoryProvider);
    if (_isEdit) {
      await repo.update(
        _id,
        name: _name.text,
        type: _type,
        openingBalanceMinor: opening,
        includeInTotal: _includeInTotal,
        currencyCode: _hasTransactions ? null : _currencyCode,
      );
    } else {
      if (await repo.byId(_id) == null) {
        await repo.create(
          id: _id,
          name: _name.text,
          type: _type,
          currencyCode: _currencyCode,
          openingBalanceMinor: opening,
          openingDate: ref.read(todayProvider),
          includeInTotal: _includeInTotal,
        );
      }
    }
    if (!mounted) return;
    showAppSnackBar(context, context.l10n.feedbackSaved);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = Currencies.byCode(_currencyCode);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.accountEdit : l10n.accountAdd)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: PageBody(
                children: [
                  TextFormField(
                    controller: _name,
                    maxLength: 60,
                    autofocus: !_isEdit,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.accountName),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : null,
                  ),
                  const SizedBox(height: Gap.sm),
                  Text(
                    l10n.accountType,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: Gap.sm),
                  Wrap(
                    spacing: Gap.sm,
                    runSpacing: Gap.sm,
                    children: [
                      for (final t in AccountType.values)
                        ChoiceChip(
                          avatar: Icon(AppIcons.forAccountType(t), size: 18),
                          label: Text(l10n.accountTypeLabel(t)),
                          selected: _type == t,
                          onSelected: (_) => setState(() => _type = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: Gap.lg),
                  DropdownButtonFormField<String>(
                    initialValue: _currencyCode,
                    decoration: InputDecoration(
                      labelText: l10n.commonCurrency,
                      helperText: _hasTransactions
                          ? l10n.accountCurrencyLocked
                          : null,
                      helperMaxLines: 2,
                    ),
                    items: [
                      for (final c in Currencies.all)
                        DropdownMenuItem(
                          value: c.code,
                          child: Text('${c.code} · ${c.symbol}'),
                        ),
                    ],
                    onChanged: _hasTransactions
                        ? null
                        : (c) => setState(() => _currencyCode = c!),
                  ),
                  const SizedBox(height: Gap.lg),
                  MoneyField(
                    controller: _opening,
                    currency: currency,
                    label: l10n.accountOpeningBalance,
                    helperText: l10n.accountOpeningBalanceHelp,
                    required: false,
                    allowZero: true,
                    allowNegative: true,
                  ),
                  const SizedBox(height: Gap.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.accountIncludeInTotal),
                    value: _includeInTotal,
                    onChanged: (v) => setState(() => _includeInTotal = v),
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
