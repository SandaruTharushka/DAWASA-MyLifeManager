import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../ui/icons/app_icons.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/form_widgets.dart';
import '../data/category_repository.dart';
import '../domain/transaction_models.dart';
import 'transaction_providers.dart';

/// Manage expense categories and income sources.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.categoriesTitle),
          bottom: TabBar(
            tabAlignment: TabAlignment.fill,
            tabs: [
              Tab(text: l10n.categoriesExpense),
              Tab(text: l10n.categoriesIncome),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CategoryList(kind: CategoryKind.expense),
            _CategoryList(kind: CategoryKind.income),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.kind});

  final CategoryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(allCategoriesProvider(kind));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-category-$kind',
        onPressed: () => showCategoryEditor(context, kind: kind),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          kind == CategoryKind.expense
              ? l10n.categoryAdd
              : l10n.categoryAddIncome,
        ),
      ),
      body: AsyncValueView(
        value: async,
        data: (categories) {
          final active = categories.where((c) => !c.isArchived).toList();
          final archived = categories.where((c) => c.isArchived).toList();
          return PageBody(
            children: [
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                child: Column(
                  children: [
                    for (final c in active) _CategoryTile(category: c),
                  ],
                ),
              ),
              if (archived.isNotEmpty) ...[
                SectionHeader(title: l10n.commonArchived),
                Text(
                  l10n.categoryArchiveHelp,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Gap.sm),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                  child: Column(
                    children: [
                      for (final c in archived) _CategoryTile(category: c),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category});

  final TxCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ListTile(
      leading: IconBadge(
        icon: AppIcons.forKey(category.iconKey),
        color: Color(category.colorValue),
        size: 40,
      ),
      title: Text(category.label(l10n)),
      onTap: () =>
          showCategoryEditor(context, kind: category.kind, existing: category),
      trailing: IconButton(
        tooltip: category.isArchived
            ? l10n.actionUnarchive
            : l10n.actionArchive,
        icon: Icon(
          category.isArchived
              ? Icons.unarchive_outlined
              : Icons.archive_outlined,
        ),
        onPressed: () => ref
            .read(categoryRepositoryProvider)
            .setArchived(category.id, archived: !category.isArchived),
      ),
    );
  }
}

/// Bottom sheet for creating or editing a category.
Future<void> showCategoryEditor(
  BuildContext context, {
  required CategoryKind kind,
  TxCategory? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CategoryEditor(kind: kind, existing: existing),
  );
}

class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor({required this.kind, this.existing});

  final CategoryKind kind;
  final TxCategory? existing;

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late String _icon = widget.existing?.iconKey ?? 'category';
  late int _color = widget.existing?.colorValue ?? AppIcons.colorChoices.first;
  late final String _id = newId();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(categoryRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.create(
          id: _id,
          kind: widget.kind,
          name: _name.text,
          iconKey: _icon,
          colorValue: _color,
        );
      } else {
        await repo.update(
          widget.existing!.id,
          name: _name.text,
          iconKey: _icon,
          colorValue: _color,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on DuplicateCategoryException {
      setState(() => _error = context.l10n.categoryDuplicateName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSystem = widget.existing?.systemKey != null;
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
                    ? (widget.kind == CategoryKind.expense
                          ? l10n.categoryAdd
                          : l10n.categoryAddIncome)
                    : l10n.categoryEdit,
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: Gap.lg),
              TextFormField(
                controller: _name,
                maxLength: 40,
                autofocus: widget.existing == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.categoryName,
                  hintText: isSystem ? widget.existing!.label(l10n) : null,
                  errorText: _error,
                ),
                validator: (v) => !isSystem && (v == null || v.trim().isEmpty)
                    ? l10n.validationRequired
                    : null,
              ),
              const SizedBox(height: Gap.md),
              Text(l10n.categoryIcon, style: context.textTheme.labelLarge),
              const SizedBox(height: Gap.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final key in AppIcons.categoryChoices)
                    Semantics(
                      selected: key == _icon,
                      button: true,
                      label: key,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _icon = key),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: key == _icon
                                  ? context.colors.primary
                                  : context.colors.outlineVariant,
                              width: key == _icon ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            AppIcons.forKey(key),
                            color: Color(_color),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Gap.md),
              Text(l10n.categoryColor, style: context.textTheme.labelLarge),
              const SizedBox(height: Gap.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in AppIcons.colorChoices)
                    Semantics(
                      selected: color == _color,
                      button: true,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _color = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color == _color
                                  ? context.colors.onSurface
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
