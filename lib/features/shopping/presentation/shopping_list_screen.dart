import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/form_widgets.dart';
import '../../../ui/widgets/money_widgets.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../budgets/presentation/budget_alerts.dart';
import '../../transactions/presentation/widgets/pickers.dart';
import '../data/shopping_repository.dart';
import 'shopping_providers.dart';
import 'shopping_tab.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(shoppingListProvider(listId)).value;
    final items = ref.watch(shoppingItemsProvider(listId)).value;
    final currency = ref.watch(currencyProvider);
    if (list == null || items == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final totals = ShoppingTotals.of(items);
    final toBuy = items.where((i) => !i.isPurchased).toList();
    final bought = items.where((i) => i.isPurchased).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(list.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              final repo = ref.read(shoppingRepositoryProvider);
              switch (v) {
                case 'complete':
                  await repo.setListCompleted(
                    listId,
                    completed: !list.isCompleted,
                  );
                case 'delete':
                  final ok = await confirmDialog(
                    context,
                    title: l10n.shoppingDeleteList,
                    message: l10n.shoppingDeleteListBody,
                    confirmLabel: l10n.actionDelete,
                    destructive: true,
                  );
                  if (ok) {
                    await repo.deleteList(listId);
                    if (context.mounted) context.pop();
                  }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'complete',
                child: Text(
                  list.isCompleted
                      ? l10n.shoppingReopenList
                      : l10n.shoppingCompleteList,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(l10n.shoppingDeleteList),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: list.isCompleted
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showItemEditor(context, listId: listId),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.shoppingAddItem),
            ),
      body: PageBody(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Total(
                        label: l10n.shoppingEstimatedTotal,
                        amount: totals.estimatedMinor,
                        muted: true,
                      ),
                    ),
                    Expanded(
                      child: _Total(
                        label: l10n.shoppingActualTotal,
                        amount: totals.actualMinor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.sm),
                Text(
                  l10n.shoppingEstimateNote,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                if (totals.unrecordedCount > 0) ...[
                  const SizedBox(height: Gap.md),
                  Text(
                    l10n.shoppingRecordExpenseBody(
                      totals.unrecordedCount,
                      Money.format(totals.unrecordedActualMinor, currency),
                    ),
                  ),
                  const SizedBox(height: Gap.sm),
                  SubmitButton(
                    label: l10n.shoppingRecordExpense,
                    icon: Icons.receipt_long_rounded,
                    tonal: true,
                    onSubmit: () => _record(context, ref, totals),
                  ),
                ] else if (bought.isNotEmpty) ...[
                  const SizedBox(height: Gap.md),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: context.semantic.success,
                        size: 18,
                      ),
                      const SizedBox(width: Gap.sm),
                      Expanded(child: Text(l10n.shoppingAllRecorded)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (items.isEmpty)
            EmptyState(
              icon: Icons.add_shopping_cart_rounded,
              message: l10n.shoppingEmptyItems,
            ),
          if (toBuy.isNotEmpty) ...[
            SectionHeader(title: l10n.shoppingToBuy),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: Gap.xs),
              child: Column(
                children: [for (final i in toBuy) _ItemTile(item: i)],
              ),
            ),
          ],
          if (bought.isNotEmpty) ...[
            SectionHeader(title: l10n.shoppingPurchased),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: Gap.xs),
              child: Column(
                children: [for (final i in bought) _ItemTile(item: i)],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _record(
    BuildContext context,
    WidgetRef ref,
    ShoppingTotals totals,
  ) async {
    final l10n = context.l10n;
    if (totals.missingPriceCount > 0) {
      showAppSnackBar(context, l10n.shoppingMissingPrices);
      return;
    }
    final accounts = await ref.read(accountRepositoryProvider).accounts();
    if (!context.mounted) return;
    if (accounts.isEmpty) {
      showAppSnackBar(context, l10n.txErrorNoAccount);
      return;
    }
    final accountId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AccountChooser(initial: accounts.first.id),
    );
    if (accountId == null || !context.mounted) return;
    final account = accounts.firstWhere((a) => a.id == accountId);
    try {
      await ref
          .read(shoppingRepositoryProvider)
          .recordPurchases(
            listId: listId,
            transactionId: newId(),
            accountId: accountId,
            occurredAt: ref.read(clockProvider)(),
            currencyCode: account.currencyCode,
          );
      await ref.read(budgetAlertServiceProvider).checkAfterSpending();
      if (context.mounted) showAppSnackBar(context, l10n.shoppingRecorded);
    } on MissingActualPriceException {
      if (context.mounted) showAppSnackBar(context, l10n.shoppingMissingPrices);
    } on NothingToRecordException {
      if (context.mounted) showAppSnackBar(context, l10n.shoppingAllRecorded);
    }
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.amount, this.muted = false});

  final String label;
  final int amount;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.textTheme.labelSmall),
        MoneyText(
          amount,
          sensitive: false,
          style: context.textTheme.titleMedium,
          color: muted ? context.colors.onSurfaceVariant : null,
        ),
      ],
    );
  }
}

class _AccountChooser extends StatefulWidget {
  const _AccountChooser({required this.initial});

  final String initial;

  @override
  State<_AccountChooser> createState() => _AccountChooserState();
}

class _AccountChooserState extends State<_AccountChooser> {
  late String? _accountId = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.shoppingRecordExpense,
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: Gap.lg),
            AccountPickerField(
              label: l10n.txPaidFrom,
              value: _accountId,
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: Gap.lg),
            FilledButton(
              onPressed: _accountId == null
                  ? null
                  : () => Navigator.of(context).pop(_accountId),
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.item});

  final ShoppingItemRow item;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(shoppingRepositoryProvider);
    if (item.isPurchased) {
      await repo.setPurchased(item.id, purchased: false);
      return;
    }
    // Ask for the actual price (prefilled with the estimate for convenience;
    // the user confirms it, so the estimate itself never becomes a record).
    final currency = ref.read(currencyProvider);
    final price = await _askPrice(
      context,
      currency,
      item.actualPriceMinor ?? item.estimatedPriceMinor,
    );
    if (price == null) return;
    await repo.setPurchased(
      item.id,
      purchased: true,
      actualPriceMinor: price.$2,
    );
  }

  Future<(bool, int?)?> _askPrice(
    BuildContext context,
    Currency currency,
    int? initial,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(
      text: initial == null
          ? ''
          : Money.formatForInput(
              initial,
              decimalDigits: currency.decimalDigits,
            ),
    );
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<(bool, int?)>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Form(
          key: formKey,
          child: MoneyField(
            controller: controller,
            currency: currency,
            label: l10n.shoppingActual,
            helperText: l10n.shoppingPriceHelp,
            required: false,
            allowZero: true,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(context)
                  .pop((true, parseMoneyField(controller.text, currency)));
            },
            child: Text(l10n.shoppingPurchased),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final recorded = item.transactionId != null;
    final price = item.isPurchased
        ? item.actualPriceMinor
        : item.estimatedPriceMinor;
    return ListTile(
      onTap: recorded
          ? null
          : () => showItemEditor(context, listId: item.listId, existing: item),
      leading: Checkbox(
        value: item.isPurchased,
        onChanged: recorded ? null : (_) => _toggle(context, ref),
        semanticLabel: l10n.shoppingPurchased,
      ),
      title: Text(
        item.name,
        style: TextStyle(
          decoration: item.isPurchased ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        [
          '${formatQuantity(item.quantityMilli)} ${l10n.unitLabel(item.unit)}',
          if (recorded) l10n.shoppingItemRecorded,
        ].join(' · '),
      ),
      trailing: price == null
          ? null
          : MoneyText(
              price,
              sensitive: false,
              style: context.textTheme.titleSmall,
              color: item.isPurchased ? null : context.colors.onSurfaceVariant,
            ),
    );
  }
}

/// Bottom sheet to add or edit an item.
Future<void> showItemEditor(
  BuildContext context, {
  required String listId,
  ShoppingItemRow? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ItemEditor(listId: listId, existing: existing),
  );
}

class _ItemEditor extends ConsumerStatefulWidget {
  const _ItemEditor({required this.listId, this.existing});

  final String listId;
  final ShoppingItemRow? existing;

  @override
  ConsumerState<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends ConsumerState<_ItemEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _quantity = TextEditingController(
    text: formatQuantity(widget.existing?.quantityMilli ?? 1000),
  );
  late final _estimated = TextEditingController(
    text: _price(widget.existing?.estimatedPriceMinor),
  );
  late final _actual = TextEditingController(
    text: _price(widget.existing?.actualPriceMinor),
  );
  late String _unit = widget.existing?.unit ?? 'pcs';
  late String _id = widget.existing?.id ?? newId();

  String _price(int? v) => v == null
      ? ''
      : Money.formatForInput(
          v,
          decimalDigits: ref.read(currencyProvider).decimalDigits,
        );

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _estimated.dispose();
    _actual.dispose();
    super.dispose();
  }

  Future<void> _save({required bool addAnother}) async {
    if (!_formKey.currentState!.validate()) return;
    final currency = ref.read(currencyProvider);
    await ref
        .read(shoppingRepositoryProvider)
        .saveItem(
          ShoppingItemDraft(
            id: _id,
            listId: widget.listId,
            name: _name.text,
            quantityMilli:
                Money.tryParse(_quantity.text, decimalDigits: 3) ?? 1000,
            unit: _unit,
            estimatedPriceMinor: parseMoneyField(_estimated.text, currency),
            actualPriceMinor: parseMoneyField(_actual.text, currency),
          ),
        );
    if (!mounted) return;
    if (addAnother) {
      setState(() {
        _id = newId();
        _name.clear();
        _quantity.text = '1';
        _estimated.clear();
        _actual.clear();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = ref.watch(currencyProvider);
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
                widget.existing == null
                    ? l10n.shoppingAddItem
                    : l10n.shoppingEditItem,
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: Gap.md),
              TextFormField(
                controller: _name,
                autofocus: true,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.shoppingItemName),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.validationRequired
                    : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantity,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.shoppingQuantity,
                      ),
                      validator: (v) {
                        final q = Money.tryParse(v ?? '', decimalDigits: 3);
                        return q == null || q <= 0
                            ? l10n.validationNumberInvalid
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: InputDecoration(labelText: l10n.shoppingUnit),
                      items: [
                        for (final u in kShoppingUnits)
                          DropdownMenuItem(
                            value: u,
                            child: Text(l10n.unitLabel(u)),
                          ),
                      ],
                      onChanged: (u) => setState(() => _unit = u ?? 'pcs'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              MoneyField(
                controller: _estimated,
                currency: currency,
                label: l10n.shoppingEstimated,
                helperText: l10n.shoppingPriceHelp,
                required: false,
                allowZero: true,
              ),
              const SizedBox(height: Gap.md),
              MoneyField(
                controller: _actual,
                currency: currency,
                label: l10n.shoppingActual,
                required: false,
                allowZero: true,
              ),
              const SizedBox(height: Gap.lg),
              Row(
                children: [
                  if (widget.existing == null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _save(addAnother: true),
                        child: Text(l10n.actionAdd),
                      ),
                    ),
                  if (widget.existing == null) const SizedBox(width: Gap.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _save(addAnother: false),
                      child: Text(l10n.actionDone),
                    ),
                  ),
                ],
              ),
              if (widget.existing != null)
                TextButton.icon(
                  onPressed: () async {
                    await ref
                        .read(shoppingRepositoryProvider)
                        .deleteItem(widget.existing!.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(l10n.actionDelete),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
