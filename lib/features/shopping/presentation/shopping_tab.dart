import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/money_widgets.dart';
import 'shopping_providers.dart';

extension ShoppingUnitLabels on AppLocalizations {
  String unitLabel(String unit) => switch (unit) {
    'kg' => unitKg,
    'g' => unitG,
    'l' => unitL,
    'ml' => unitMl,
    'pack' => unitPack,
    'bottle' => unitBottle,
    'dozen' => unitDozen,
    _ => unitPcs,
  };
}

const kShoppingUnits = ['pcs', 'kg', 'g', 'l', 'ml', 'pack', 'bottle', 'dozen'];

/// Formats a quantity stored in thousandths (1500 -> "1.5").
String formatQuantity(int milli) {
  final whole = milli ~/ 1000;
  final frac = milli % 1000;
  if (frac == 0) return '$whole';
  final digits = frac.toString().padLeft(3, '0').replaceAll(RegExp(r'0+$'), '');
  return '$whole.$digits';
}

/// Asks for a list name and creates the list.
Future<void> createShoppingList(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final controller = TextEditingController();
  final id = newId();
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.shoppingNewList),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 60,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.shoppingListName,
          hintText: l10n.shoppingListNameHint,
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(l10n.actionSave),
        ),
      ],
    ),
  );
  controller.dispose();
  if (name == null || name.trim().isEmpty) return;
  await ref.read(shoppingRepositoryProvider).createList(name, id: id);
  if (context.mounted) await context.push(Routes.shoppingList(id));
}

class ShoppingTab extends ConsumerWidget {
  const ShoppingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AsyncValueView(
      value: ref.watch(shoppingListsProvider),
      data: (lists) {
        if (lists.isEmpty) {
          return EmptyState(
            icon: Icons.shopping_cart_outlined,
            message: l10n.shoppingEmptyLists,
            actionLabel: l10n.shoppingNewList,
            onAction: () => createShoppingList(context, ref),
          );
        }
        return PageBody(
          children: [
            for (final s in lists)
              Padding(
                padding: const EdgeInsets.only(top: Gap.md),
                child: AppCard(
                  onTap: () => context.push(Routes.shoppingList(s.list.id)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            s.list.isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.shopping_cart_rounded,
                            color: s.list.isCompleted
                                ? context.semantic.success
                                : context.colors.primary,
                          ),
                          const SizedBox(width: Gap.md),
                          Expanded(
                            child: Text(
                              s.list.name,
                              style: context.textTheme.titleMedium?.copyWith(
                                decoration: s.list.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (s.list.isCompleted)
                            StatusChip(
                              label: l10n.shoppingListDone,
                              color: context.semantic.success,
                              background: context.semantic.successContainer,
                            ),
                        ],
                      ),
                      const SizedBox(height: Gap.sm),
                      if (s.itemCount > 0) ...[
                        AppProgressBar(
                          value: s.purchasedCount / s.itemCount,
                          height: 6,
                        ),
                        const SizedBox(height: Gap.sm),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.itemCount == 0
                                  ? l10n.shoppingEmptyItems
                                  : l10n.shoppingProgress(
                                      s.purchasedCount,
                                      s.itemCount,
                                    ),
                              style: context.textTheme.bodySmall,
                            ),
                          ),
                          if (s.estimatedTotalMinor > 0)
                            MoneyText(
                              s.estimatedTotalMinor,
                              sensitive: false,
                              style: context.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
