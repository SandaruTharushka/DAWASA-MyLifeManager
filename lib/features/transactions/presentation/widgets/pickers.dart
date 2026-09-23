import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../ui/icons/app_icons.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/app_theme.dart';
import '../../../accounts/presentation/account_providers.dart';
import '../../domain/transaction_models.dart';
import '../transaction_providers.dart';

/// Dropdown of active accounts.
class AccountPickerField extends ConsumerWidget {
  const AccountPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.excludeId,
    this.currencyCode,
    this.allowNone = false,
    this.noneLabel,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? excludeId;
  final String? currencyCode;
  final bool allowNone;
  final String? noneLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accounts = ref.watch(activeAccountsProvider).value ?? const [];
    final visible = accounts
        .where((a) => a.id != excludeId)
        .where((a) => currencyCode == null || a.currencyCode == currencyCode)
        .toList();
    final current = visible.any((a) => a.id == value) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: current,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
      ),
      items: [
        if (allowNone)
          DropdownMenuItem<String>(
            value: null,
            child: Text(noneLabel ?? l10n.commonNone),
          ),
        for (final a in visible)
          DropdownMenuItem(
            value: a.id,
            child: Row(
              children: [
                Icon(AppIcons.forAccountType(a.type), size: 20),
                const SizedBox(width: Gap.sm),
                Expanded(child: Text(a.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
      validator: (v) => (!allowNone && v == null) ? l10n.txSelectAccount : null,
      onChanged: onChanged,
    );
  }
}

/// Grid of category chips with a shortcut to category management.
class CategoryPicker extends ConsumerWidget {
  const CategoryPicker({
    super.key,
    required this.kind,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final CategoryKind kind;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider(kind)).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.commonCategory,
                style: context.textTheme.labelLarge,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push(Routes.categories),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: Text(l10n.categoriesTitle),
            ),
          ],
        ),
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            for (final c in categories)
              _CategoryChip(
                category: c,
                selected: c.id == value,
                onTap: () => onChanged(c.id),
              ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.sm, left: Gap.md),
            child: Text(
              errorText!,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final TxCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return ChoiceChip(
      avatar: Icon(
        AppIcons.forKey(category.iconKey),
        size: 18,
        color: selected ? context.colors.onPrimaryContainer : color,
      ),
      label: Text(category.label(context.l10n)),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    );
  }
}
