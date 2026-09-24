import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/app_database.dart';
import '../../../core/finance/transaction_rules.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/recurrence.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/form_widgets.dart';
import '../../../ui/widgets/money_widgets.dart';
import '../../../ui/widgets/recurrence_editor.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../budgets/presentation/budget_alerts.dart';
import '../../security/app_lock.dart';
import '../domain/transaction_models.dart';
import 'transaction_providers.dart';
import 'widgets/pickers.dart';

/// Types that can be chosen directly in the form. Loan and correction types
/// are created from the Loans module and the account screen.
const _formTypes = [
  TransactionType.expense,
  TransactionType.income,
  TransactionType.transfer,
];

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    super.key,
    this.editId,
    this.initialType = TransactionType.expense,
    this.initialAccountId,
    this.duplicateOf,
  });

  final String? editId;
  final TransactionType initialType;
  final String? initialAccountId;
  final String? duplicateOf;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _note = TextEditingController();

  /// Generated once per form: saving twice can never create two records.
  late final String _id = widget.editId ?? newId();
  late final String _ruleId = newId();

  bool _loading = false;
  late TransactionType _type = widget.initialType;
  String? _accountId;
  String? _toAccountId;
  String? _categoryId;
  late LocalDate _date = ref.read(todayProvider);
  late int _minutes = _nowMinutes();
  String? _existingAttachmentId;
  File? _newReceipt;
  bool _removeReceipt = false;
  RecurrenceRule? _repeat;
  bool _showCategoryError = false;
  TransactionSource _source = TransactionSource.manual;
  String? _sourceRefId;
  String? _recurringRuleId;

  bool get _isEdit => widget.editId != null;

  /// Transactions created by the savings or loan modules keep their amount
  /// and accounts in sync with those records, so only text can change here.
  bool get _lockedByModule =>
      _isEdit &&
      (_source == TransactionSource.savings ||
          _source == TransactionSource.loan);

  int _nowMinutes() {
    final now = ref.read(clockProvider)();
    return now.hour * 60 + now.minute;
  }

  @override
  void initState() {
    super.initState();
    _accountId = widget.initialAccountId;
    final sourceId = widget.editId ?? widget.duplicateOf;
    if (sourceId != null) {
      _loading = true;
      _load(sourceId);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _defaultAccount());
    }
  }

  Future<void> _defaultAccount() async {
    if (_accountId != null) return;
    final accounts = await ref.read(accountRepositoryProvider).accounts();
    if (!mounted || accounts.isEmpty) return;
    setState(() {
      _accountId = accounts.first.id;
      if (_type == TransactionType.transfer && accounts.length > 1) {
        _toAccountId = accounts[1].id;
      }
    });
  }

  Future<void> _load(String id) async {
    final view = await ref.read(transactionRepositoryProvider).byId(id);
    if (!mounted) return;
    if (view == null) {
      context.pop();
      return;
    }
    final t = view.transaction;
    final currency = Currencies.byCode(t.currencyCode);
    setState(() {
      _type = t.type;
      _amount.text = Money.formatForInput(
        t.amountMinor,
        decimalDigits: currency.decimalDigits,
      );
      _description.text = t.description;
      _note.text = t.note ?? '';
      _accountId = t.accountId;
      _toAccountId = t.toAccountId;
      _categoryId = t.categoryId;
      if (_isEdit) {
        _date = t.localDate;
        final local = t.occurredAt.toLocal();
        _minutes = local.hour * 60 + local.minute;
        _existingAttachmentId = t.attachmentId;
        _source = t.source;
        _sourceRefId = t.sourceRefId;
        _recurringRuleId = t.recurringRuleId;
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _note.dispose();
    super.dispose();
  }

  Account? _findAccount(String? id, List<Account> accounts) =>
      accounts.where((a) => a.id == id).firstOrNull;

  Future<void> _pickReceipt(ImageSource source) async {
    final picked = await ref
        .read(appLockProvider.notifier)
        .whileExternal(
          () => ImagePicker().pickImage(
            source: source,
            maxWidth: 1600,
            maxHeight: 1600,
            imageQuality: 70,
          ),
        );
    if (picked == null || !mounted) return;
    setState(() {
      _newReceipt = File(picked.path);
      _removeReceipt = false;
    });
  }

  String _errorMessage(TransactionValidationError e, AppLocalizations l10n) =>
      switch (e) {
        TransactionValidationError.amountNotPositive =>
          l10n.validationAmountPositive,
        TransactionValidationError.sameAccount => l10n.txErrorSameAccount,
        TransactionValidationError.currencyMismatch =>
          l10n.txErrorCurrencyMismatch,
        TransactionValidationError.missingCategory ||
        TransactionValidationError.categoryKindMismatch =>
          l10n.txErrorCategoryRequired,
        TransactionValidationError.unknownAccount ||
        TransactionValidationError.missingToAccount ||
        TransactionValidationError.unexpectedToAccount => l10n.txSelectAccount,
      };

  Future<void> _save() async {
    final l10n = context.l10n;
    final needsCategory = TransactionRules.requiresCategory(_type);
    final formOk = _formKey.currentState!.validate();
    setState(() => _showCategoryError = needsCategory && _categoryId == null);
    if (!formOk || _showCategoryError) return;

    final accounts = ref.read(activeAccountsProvider).value ?? const [];
    final account =
        _findAccount(_accountId, accounts) ??
        await ref.read(accountRepositoryProvider).byId(_accountId!);
    if (account == null) return;
    final currency = Currencies.byCode(account.currencyCode);
    final amount = parseMoneyField(_amount.text, currency);
    if (amount == null) return;

    final store = ref.read(attachmentStoreProvider);
    final repo = ref.read(transactionRepositoryProvider);
    String? attachmentId = _removeReceipt ? null : _existingAttachmentId;
    String? importedAttachment;
    try {
      if (_newReceipt != null && _type == TransactionType.expense) {
        importedAttachment = await store.importImage(_newReceipt!);
        attachmentId = importedAttachment;
      }
      if (_type != TransactionType.expense) attachmentId = null;

      final draft = TransactionDraft(
        id: _id,
        type: _type,
        amountMinor: amount,
        currencyCode: account.currencyCode,
        accountId: account.id,
        toAccountId: _type == TransactionType.transfer ? _toAccountId : null,
        categoryId: needsCategory ? _categoryId : null,
        occurredAt: _date.atMinutes(_minutes),
        description: _description.text,
        note: _note.text,
        attachmentId: attachmentId,
        source: _source,
        sourceRefId: _sourceRefId,
        recurringRuleId: _recurringRuleId,
      );

      var message = l10n.feedbackSaved;
      if (_isEdit) {
        await repo.update(draft);
        final old = _existingAttachmentId;
        if (old != null && old != attachmentId) await store.delete(old);
      } else if (_repeat != null) {
        await ref
            .read(recurringRepositoryProvider)
            .createRule(
              ruleId: _ruleId,
              template: draft,
              rule: _repeat!,
              today: ref.read(todayProvider),
            );
      } else {
        final outcome = await repo.create(draft);
        if (outcome == SaveOutcome.alreadyExisted) {
          message = l10n.feedbackAlreadySaved;
        }
      }
      if (_type == TransactionType.expense) {
        await ref.read(budgetAlertServiceProvider).checkAfterSpending();
      }
      if (!mounted) return;
      showAppSnackBar(context, message);
      context.pop();
    } on TransactionValidationException catch (e) {
      if (importedAttachment != null) await store.delete(importedAttachment);
      if (mounted) showAppSnackBar(context, _errorMessage(e.error, l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accounts = ref.watch(activeAccountsProvider).value ?? const [];
    final account = _findAccount(_accountId, accounts);
    final currency = account != null
        ? Currencies.byCode(account.currencyCode)
        : ref.watch(currencyProvider);
    final title = _isEdit
        ? l10n.txEdit
        : switch (_type) {
            TransactionType.income => l10n.txAddIncome,
            TransactionType.transfer => l10n.txAddTransfer,
            TransactionType.reimbursement => l10n.txAddReimbursement,
            _ => l10n.txAddExpense,
          };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: PageBody(
                children: [
                  if (!_lockedByModule) _typeSelector(l10n),
                  if (_lockedByModule)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.md),
                      child: StatusChip(
                        label: l10n.transactionTypeLabel(_type),
                        color: context.semantic.neutral,
                        background: context.colors.surfaceContainerHigh,
                      ),
                    ),
                  const SizedBox(height: Gap.lg),
                  if (accounts.isEmpty && !_isEdit)
                    EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      message: l10n.txErrorNoAccount,
                      compact: true,
                    ),
                  AbsorbPointer(
                    absorbing: _lockedByModule,
                    child: Opacity(
                      opacity: _lockedByModule ? 0.6 : 1,
                      child: MoneyField(
                        controller: _amount,
                        currency: currency,
                        autofocus: !_isEdit && widget.duplicateOf == null,
                        large: true,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ),
                  const SizedBox(height: Gap.lg),
                  if (TransactionRules.requiresCategory(_type)) ...[
                    CategoryPicker(
                      kind: _type == TransactionType.income
                          ? CategoryKind.income
                          : CategoryKind.expense,
                      value: _categoryId,
                      errorText: _showCategoryError
                          ? l10n.txErrorCategoryRequired
                          : null,
                      onChanged: (id) => setState(() {
                        _categoryId = id;
                        _showCategoryError = false;
                      }),
                    ),
                    const SizedBox(height: Gap.lg),
                  ],
                  if (_type == TransactionType.transfer) ...[
                    Text(
                      l10n.txTransferHelp,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Gap.md),
                  ],
                  if (_type == TransactionType.reimbursement) ...[
                    Text(
                      l10n.txTypeReimbursementHelp,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Gap.md),
                  ],
                  AbsorbPointer(
                    absorbing: _lockedByModule,
                    child: AccountPickerField(
                      key: ValueKey('from-$_type-$_accountId'),
                      label: switch (_type) {
                        TransactionType.transfer => l10n.txFromAccount,
                        TransactionType.expense => l10n.txPaidFrom,
                        _ when TransactionRules.inflowTypes.contains(_type) =>
                          l10n.txReceivedInto,
                        _ => l10n.commonAccount,
                      },
                      value: _accountId,
                      onChanged: (id) => setState(() {
                        _accountId = id;
                        if (_toAccountId == id) _toAccountId = null;
                      }),
                    ),
                  ),
                  if (_type == TransactionType.transfer) ...[
                    const SizedBox(height: Gap.md),
                    AbsorbPointer(
                      absorbing: _lockedByModule,
                      child: AccountPickerField(
                        key: ValueKey('to-$_accountId-$_toAccountId'),
                        label: l10n.txToAccount,
                        value: _toAccountId,
                        excludeId: _accountId,
                        currencyCode: account?.currencyCode,
                        onChanged: (id) => setState(() => _toAccountId = id),
                      ),
                    ),
                  ],
                  const SizedBox(height: Gap.md),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DateField(
                          label: l10n.commonDate,
                          value: _date,
                          onChanged: (d) {
                            if (d != null) setState(() => _date = d);
                          },
                        ),
                      ),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        flex: 2,
                        child: TimeField(
                          label: l10n.commonTime,
                          value: _minutes,
                          onChanged: (m) {
                            if (m != null) setState(() => _minutes = m);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.md),
                  TextFormField(
                    controller: _description,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.commonDescription,
                      hintText: l10n.txDescriptionHint,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: Gap.md),
                  TextFormField(
                    controller: _note,
                    maxLength: 500,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.commonNote,
                      hintText: l10n.txNoteHint,
                      counterText: '',
                    ),
                  ),
                  if (_type == TransactionType.expense) ...[
                    const SizedBox(height: Gap.md),
                    _receiptSection(l10n),
                  ],
                  if (!_isEdit && _formTypes.contains(_type)) ...[
                    const SizedBox(height: Gap.lg),
                    Text(
                      l10n.txRepeatSection,
                      style: context.textTheme.titleSmall,
                    ),
                    const SizedBox(height: Gap.xs),
                    Text(
                      l10n.txRepeatHelp,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Gap.sm),
                    RecurrenceEditor(
                      value: _repeat,
                      startDate: _date,
                      onChanged: (r) => setState(() => _repeat = r),
                    ),
                  ],
                  const SizedBox(height: Gap.xl),
                  SubmitButton(
                    label: l10n.actionSave,
                    icon: Icons.check_rounded,
                    onSubmit: accounts.isEmpty && !_isEdit ? null : _save,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _typeSelector(AppLocalizations l10n) {
    const types = [..._formTypes, TransactionType.reimbursement];
    if (!types.contains(_type)) {
      return StatusChip(
        label: l10n.transactionTypeLabel(_type),
        color: context.semantic.neutral,
        background: context.colors.surfaceContainerHigh,
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<TransactionType>(
        showSelectedIcon: false,
        segments: [
          for (final t in types)
            ButtonSegment(value: t, label: Text(l10n.transactionTypeLabel(t))),
        ],
        selected: {_type},
        onSelectionChanged: (s) => setState(() {
          final previous = _type;
          _type = s.first;
          if (TransactionRules.requiresCategory(previous) !=
                  TransactionRules.requiresCategory(_type) ||
              (previous == TransactionType.expense) !=
                  (_type == TransactionType.expense)) {
            _categoryId = null;
          }
          if (_type == TransactionType.transfer && _toAccountId == null) {
            final accounts = ref.read(activeAccountsProvider).value ?? const [];
            _toAccountId = accounts
                .where((a) => a.id != _accountId)
                .firstOrNull
                ?.id;
          }
        }),
      ),
    );
  }

  Widget _receiptSection(AppLocalizations l10n) {
    final hasExisting = _existingAttachmentId != null && !_removeReceipt;
    final hasNew = _newReceipt != null;
    if (!hasExisting && !hasNew) {
      return Wrap(
        spacing: Gap.sm,
        runSpacing: Gap.sm,
        children: [
          OutlinedButton.icon(
            onPressed: () => _pickReceipt(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(l10n.txTakePhoto),
          ),
          OutlinedButton.icon(
            onPressed: () => _pickReceipt(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(l10n.txChooseFromGallery),
          ),
        ],
      );
    }
    return AppCard(
      padding: const EdgeInsets.all(Gap.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.field),
            child: SizedBox.square(
              dimension: 72,
              child: hasNew
                  ? Image.file(_newReceipt!, fit: BoxFit.cover, cacheWidth: 216)
                  : _AttachmentThumb(id: _existingAttachmentId!),
            ),
          ),
          const SizedBox(width: Gap.md),
          Expanded(child: Text(l10n.txReceipt)),
          TextButton(
            onPressed: () => setState(() {
              _newReceipt = null;
              _removeReceipt = true;
            }),
            child: Text(l10n.txRemoveReceipt),
          ),
        ],
      ),
    );
  }
}

class _AttachmentThumb extends ConsumerWidget {
  const _AttachmentThumb({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<File?>(
      future: ref.read(attachmentStoreProvider).fileFor(id),
      builder: (context, snap) {
        final file = snap.data;
        if (file == null) return const Icon(Icons.receipt_long_rounded);
        return Image.file(file, fit: BoxFit.cover, cacheWidth: 216);
      },
    );
  }
}
