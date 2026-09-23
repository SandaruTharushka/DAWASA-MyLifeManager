import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/time/date_range.dart';
import '../../../core/time/local_date.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../accounts/presentation/account_providers.dart';
import '../domain/transaction_models.dart';
import 'transaction_providers.dart';
import 'widgets/transaction_tile.dart';

/// Searchable, filterable transaction history with incremental loading.
class TransactionsTab extends ConsumerStatefulWidget {
  const TransactionsTab({super.key, this.accountId});

  /// When set, the list is locked to this account (account history).
  final String? accountId;

  @override
  ConsumerState<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends ConsumerState<TransactionsTab> {
  static const _pageSize = 50;
  final _search = TextEditingController();
  Timer? _debounce;
  late TransactionFilter _filter = TransactionFilter(
    accountId: widget.accountId,
  );
  int _limit = _pageSize;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _filter = _filter.copyWith(search: text);
        _limit = _pageSize;
      });
    });
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<TransactionFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _FilterSheet(initial: _filter, lockAccount: widget.accountId != null),
    );
    if (result != null) {
      setState(() {
        _filter = result.copyWith(search: _filter.search);
        _limit = _pageSize;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = TransactionQuery(_filter, _limit);
    final async = ref.watch(transactionListProvider(query));
    final activeFilters =
        _filter.types.length +
        _filter.categoryIds.length +
        (_filter.range != null ? 1 : 0) +
        (widget.accountId == null && _filter.accountId != null ? 1 : 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        final items = async.value;
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 400 &&
            items != null &&
            items.length >= _limit) {
          setState(() => _limit += _pageSize);
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.page,
                Gap.md,
                Gap.page,
                Gap.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: _onSearch,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.txSearchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: l10n.actionClear,
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _search.clear();
                                  _onSearch('');
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Badge(
                    isLabelVisible: activeFilters > 0,
                    label: Text('$activeFilters'),
                    child: IconButton.filledTonal(
                      tooltip: l10n.actionFilter,
                      onPressed: _openFilters,
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.accountId == null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.page),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push(Routes.recurring),
                    icon: const Icon(Icons.repeat_rounded, size: 18),
                    label: Text(l10n.recurringTitle),
                  ),
                ),
              ),
            ),
          async.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(Gap.xxl),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.error_outline_rounded,
                message: l10n.errorLoading,
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message:
                        _filter.isEmpty ||
                            (widget.accountId != null &&
                                _filter.search.isEmpty &&
                                _filter.types.isEmpty &&
                                _filter.range == null)
                        ? l10n.txEmpty
                        : l10n.txNoResults,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 120),
                sliver: SliverToBoxAdapter(
                  child: GroupedTransactionList(
                    items: items,
                    perspectiveAccountId: widget.accountId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial, required this.lockAccount});

  final TransactionFilter initial;
  final bool lockAccount;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late Set<TransactionType> _types = {...widget.initial.types};
  late Set<String> _categories = {...widget.initial.categoryIds};
  late String? _accountId = widget.initial.accountId;
  late DateRange? _range = widget.initial.range;
  RangePreset? _preset;

  static const _typeChoices = [
    TransactionType.expense,
    TransactionType.income,
    TransactionType.transfer,
    TransactionType.reimbursement,
    TransactionType.loanGiven,
    TransactionType.loanReceived,
    TransactionType.loanRepaymentReceived,
    TransactionType.loanRepaymentPaid,
    TransactionType.adjustmentIn,
    TransactionType.adjustmentOut,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = ref.watch(todayProvider);
    final formatter = ref.watch(dateFormatterProvider);
    final expenseCats =
        ref.watch(categoriesProvider(CategoryKind.expense)).value ?? const [];
    final incomeCats =
        ref.watch(categoriesProvider(CategoryKind.income)).value ?? const [];
    final accounts = ref.watch(activeAccountsProvider).value ?? const [];

    String presetLabel(RangePreset p) => switch (p) {
      RangePreset.today => l10n.rangeToday,
      RangePreset.yesterday => l10n.rangeYesterday,
      RangePreset.last7Days => l10n.rangeLast7Days,
      RangePreset.thisMonth => l10n.rangeThisMonth,
      RangePreset.lastMonth => l10n.rangeLastMonth,
      RangePreset.custom => l10n.rangeCustom,
    };

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
          children: [
            Text(l10n.actionFilter, style: context.textTheme.titleLarge),
            const SizedBox(height: Gap.lg),
            Text(l10n.txFilterDates, style: context.textTheme.labelLarge),
            const SizedBox(height: Gap.sm),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                ChoiceChip(
                  label: Text(l10n.txFilterAnyDate),
                  selected: _range == null,
                  onSelected: (_) => setState(() {
                    _range = null;
                    _preset = null;
                  }),
                ),
                for (final p in RangePreset.values)
                  ChoiceChip(
                    label: Text(presetLabel(p)),
                    selected:
                        _preset == p ||
                        (_preset == null &&
                            p != RangePreset.custom &&
                            _range == p.resolve(today)),
                    onSelected: (_) async {
                      if (p == RangePreset.custom) {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setState(() {
                          _preset = p;
                          _range = DateRange(
                            LocalDate.fromDateTime(picked.start),
                            LocalDate.fromDateTime(picked.end),
                          );
                        });
                      } else {
                        setState(() {
                          _preset = p;
                          _range = p.resolve(today);
                        });
                      }
                    },
                  ),
              ],
            ),
            if (_range != null)
              Padding(
                padding: const EdgeInsets.only(top: Gap.sm),
                child: Text(
                  '${formatter.date(_range!.start)} – ${formatter.date(_range!.end)}',
                  style: context.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: Gap.lg),
            Text(l10n.txFilterType, style: context.textTheme.labelLarge),
            const SizedBox(height: Gap.sm),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final t in _typeChoices)
                  FilterChip(
                    label: Text(l10n.transactionTypeLabel(t)),
                    selected: _types.contains(t),
                    onSelected: (on) => setState(() {
                      _types = {..._types};
                      on ? _types.add(t) : _types.remove(t);
                    }),
                  ),
              ],
            ),
            if (!widget.lockAccount && accounts.isNotEmpty) ...[
              const SizedBox(height: Gap.lg),
              Text(l10n.commonAccount, style: context.textTheme.labelLarge),
              const SizedBox(height: Gap.sm),
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  ChoiceChip(
                    label: Text(l10n.commonAll),
                    selected: _accountId == null,
                    onSelected: (_) => setState(() => _accountId = null),
                  ),
                  for (final a in accounts)
                    ChoiceChip(
                      label: Text(a.name),
                      selected: _accountId == a.id,
                      onSelected: (_) => setState(() => _accountId = a.id),
                    ),
                ],
              ),
            ],
            const SizedBox(height: Gap.lg),
            Text(l10n.commonCategory, style: context.textTheme.labelLarge),
            const SizedBox(height: Gap.sm),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final c in [...expenseCats, ...incomeCats])
                  FilterChip(
                    label: Text(c.label(l10n)),
                    selected: _categories.contains(c.id),
                    onSelected: (on) => setState(() {
                      _categories = {..._categories};
                      on ? _categories.add(c.id) : _categories.remove(c.id);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: Gap.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(
                      TransactionFilter(
                        accountId: widget.lockAccount
                            ? widget.initial.accountId
                            : null,
                      ),
                    ),
                    child: Text(l10n.actionClear),
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      TransactionFilter(
                        types: _types,
                        categoryIds: _categories,
                        accountId: _accountId,
                        range: _range,
                      ),
                    ),
                    child: Text(l10n.actionDone),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
