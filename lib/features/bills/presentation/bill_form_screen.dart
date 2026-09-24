import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/providers.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/recurrence.dart';
import '../../../ui/icons/app_icons.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/form_widgets.dart';
import '../../../ui/widgets/money_widgets.dart';
import '../../../ui/widgets/recurrence_editor.dart';
import '../../security/app_lock.dart';
import '../../transactions/presentation/widgets/pickers.dart';
import '../data/bill_repository.dart';
import 'bill_providers.dart';
import 'bills_tab.dart';

class BillFormScreen extends ConsumerStatefulWidget {
  const BillFormScreen({super.key, this.billId});

  final String? billId;

  @override
  ConsumerState<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends ConsumerState<BillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _remindDays = TextEditingController(text: '2');
  late final String _id = widget.billId ?? newId();
  BillCategory _category = BillCategory.electricity;
  late LocalDate _dueDate = ref.read(todayProvider).addDays(7);
  RecurrenceRule? _repeat = RecurrenceRule.monthly();
  bool _reminders = true;
  int _remindAt = 9 * 60;
  String? _accountId;
  late String _currencyCode = ref.read(currencyProvider).code;
  bool _loading = false;

  bool get _isEdit => widget.billId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final b = await ref.read(billRepositoryProvider).byId(widget.billId!);
    if (!mounted || b == null) return;
    final currency = Currencies.byCode(b.currencyCode);
    setState(() {
      _name.text = b.name;
      _amount.text = Money.formatForInput(
        b.amountMinor,
        decimalDigits: currency.decimalDigits,
      );
      _note.text = b.note ?? '';
      _remindDays.text = '${b.remindDaysBefore}';
      _category = b.category;
      _dueDate = b.nextDueDate;
      _repeat = RecurrenceRule.decode(b.recurrence);
      _reminders = b.remindersEnabled;
      _remindAt = b.remindAtMinutes;
      _accountId = b.accountId;
      _currencyCode = b.currencyCode;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    _remindDays.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reminders) {
      final gateway = ref.read(notificationGatewayProvider);
      if (!await gateway.areNotificationsEnabled()) {
        final granted = await ref
            .read(appLockProvider.notifier)
            .whileExternal(gateway.requestPermission);
        await ref
            .read(preferencesProvider.notifier)
            .update((p) => p.copyWith(notificationsEnabled: granted));
      }
    }
    final currency = Currencies.byCode(_currencyCode);
    await ref
        .read(billRepositoryProvider)
        .save(
          BillDraft(
            id: _id,
            name: _name.text,
            category: _category,
            amountMinor: parseMoneyField(_amount.text, currency)!,
            currencyCode: _currencyCode,
            nextDueDate: _dueDate,
            recurrence: _repeat,
            remindDaysBefore: int.tryParse(_remindDays.text) ?? 0,
            remindAtMinutes: _remindAt,
            remindersEnabled: _reminders,
            accountId: _accountId,
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
      appBar: AppBar(title: Text(_isEdit ? l10n.billEdit : l10n.billAdd)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: PageBody(
                children: [
                  Text(l10n.billCategory, style: context.textTheme.labelLarge),
                  const SizedBox(height: Gap.sm),
                  Wrap(
                    spacing: Gap.sm,
                    runSpacing: Gap.sm,
                    children: [
                      for (final c in BillCategory.values)
                        ChoiceChip(
                          avatar: Icon(AppIcons.forBillCategory(c), size: 18),
                          label: Text(l10n.billCategoryLabel(c)),
                          selected: _category == c,
                          onSelected: (_) => setState(() {
                            _category = c;
                            if (_name.text.trim().isEmpty ||
                                BillCategory.values.any(
                                  (x) =>
                                      l10n.billCategoryLabel(x) == _name.text,
                                )) {
                              _name.text = l10n.billCategoryLabel(c);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: Gap.lg),
                  TextFormField(
                    controller: _name,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.billName,
                      hintText: l10n.billNameHint,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : null,
                  ),
                  MoneyField(
                    controller: _amount,
                    currency: currency,
                    label: l10n.billAmount,
                  ),
                  const SizedBox(height: Gap.md),
                  DateField(
                    label: l10n.billDueDate,
                    value: _dueDate,
                    onChanged: (d) {
                      if (d != null) setState(() => _dueDate = d);
                    },
                  ),
                  const SizedBox(height: Gap.lg),
                  Text(l10n.billRepeat, style: context.textTheme.labelLarge),
                  const SizedBox(height: Gap.sm),
                  RecurrenceEditor(
                    value: _repeat,
                    startDate: _dueDate,
                    onChanged: (r) => setState(() => _repeat = r),
                  ),
                  if (_repeat == null)
                    Padding(
                      padding: const EdgeInsets.only(top: Gap.xs),
                      child: Text(
                        l10n.billOneTime,
                        style: context.textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: Gap.lg),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.billRemind),
                    value: _reminders,
                    onChanged: (v) => setState(() => _reminders = v),
                  ),
                  if (_reminders)
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: _remindDays,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.billRemindDaysBefore(
                                int.tryParse(_remindDays.text) ?? 0,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: TimeField(
                            label: l10n.commonTime,
                            value: _remindAt,
                            onChanged: (m) {
                              if (m != null) setState(() => _remindAt = m);
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: Gap.lg),
                  AccountPickerField(
                    label: l10n.billPaymentAccount,
                    value: _accountId,
                    allowNone: true,
                    currencyCode: _currencyCode,
                    onChanged: (id) => setState(() => _accountId = id),
                  ),
                  const SizedBox(height: Gap.md),
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
                  if (_category == BillCategory.loan)
                    Padding(
                      padding: const EdgeInsets.only(top: Gap.md),
                      child: Text(
                        l10n.billLoanNote,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
