import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/l10n.dart';
import '../../core/money/currency.dart';
import '../../core/money/money.dart';
import '../../core/providers.dart';
import '../../core/time/date_range.dart';
import '../../core/time/local_date.dart';
import '../../core/utils/streams.dart';
import '../../ui/charts/charts.dart';
import '../../ui/icons/app_icons.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/form_widgets.dart';
import '../../ui/widgets/money_widgets.dart';
import '../accounts/presentation/account_providers.dart';
import '../budgets/presentation/budget_providers.dart';
import '../budgets/presentation/budgets_tab.dart';
import '../loans/presentation/loan_providers.dart';
import '../savings/presentation/savings_providers.dart';
import '../security/app_lock.dart';
import '../transactions/domain/transaction_models.dart';
import '../transactions/presentation/transaction_providers.dart';
import 'data/csv_exporter.dart';
import 'data/report_service.dart';

/// Selected report period.
class ReportRange {
  const ReportRange(this.preset, [this.custom]);

  final RangePreset preset;
  final DateRange? custom;

  DateRange resolve(LocalDate today) => preset.resolve(today, custom: custom);
}

class ReportRangeController extends Notifier<ReportRange> {
  @override
  ReportRange build() => const ReportRange(RangePreset.thisMonth);

  void set(ReportRange r) => state = r;
}

final reportRangeProvider =
    NotifierProvider<ReportRangeController, ReportRange>(
      ReportRangeController.new,
    );

final reportServiceProvider = Provider<ReportService>(
  (ref) => ReportService(ref.watch(transactionRepositoryProvider)),
);

final reportDataProvider = StreamProvider<ReportData>((ref) {
  final range = ref
      .watch(reportRangeProvider)
      .resolve(ref.watch(todayProvider));
  final currency = ref.watch(currencyProvider).code;
  final db = ref.watch(databaseProvider);
  final service = ref.watch(reportServiceProvider);
  return watchComputed(db, [
    db.transactions,
    db.transactionCategories,
  ], () => service.build(range, currency));
});

final savingsDepositedProvider = FutureProvider<int>((ref) {
  ref.watch(savingsGoalsProvider);
  final range = ref
      .watch(reportRangeProvider)
      .resolve(ref.watch(todayProvider));
  return ref
      .watch(savingsRepositoryProvider)
      .depositedBetween(range.start, range.end);
});

String presetLabel(AppLocalizations l10n, RangePreset p) => switch (p) {
  RangePreset.today => l10n.rangeToday,
  RangePreset.yesterday => l10n.rangeYesterday,
  RangePreset.last7Days => l10n.rangeLast7Days,
  RangePreset.thisMonth => l10n.rangeThisMonth,
  RangePreset.lastMonth => l10n.rangeLastMonth,
  RangePreset.custom => l10n.rangeCustom,
};

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final range = ref.watch(reportRangeProvider);
    final today = ref.watch(todayProvider);
    final formatter = ref.watch(dateFormatterProvider);
    final resolved = range.resolve(today);
    final async = ref.watch(reportDataProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsTitle),
        actions: [
          IconButton(
            tooltip: l10n.reportShare,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: async.value == null
                ? null
                : () => _shareSummary(context, ref, async.value!),
          ),
          IconButton(
            tooltip: l10n.reportExportCsv,
            icon: const Icon(Icons.table_view_rounded),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ExportSheet(range: resolved),
            ),
          ),
        ],
      ),
      body: PageBody(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in RangePreset.values)
                  Padding(
                    padding: const EdgeInsets.only(right: Gap.sm),
                    child: ChoiceChip(
                      label: Text(presetLabel(l10n, p)),
                      selected: range.preset == p,
                      onSelected: (_) async {
                        if (p != RangePreset.custom) {
                          ref
                              .read(reportRangeProvider.notifier)
                              .set(ReportRange(p));
                          return;
                        }
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDateRange: DateTimeRange(
                            start: resolved.start.startOfDayLocal,
                            end: resolved.end.startOfDayLocal,
                          ),
                        );
                        if (picked == null) return;
                        ref
                            .read(reportRangeProvider.notifier)
                            .set(
                              ReportRange(
                                RangePreset.custom,
                                DateRange(
                                  LocalDate.fromDateTime(picked.start),
                                  LocalDate.fromDateTime(picked.end),
                                ),
                              ),
                            );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Gap.sm, left: 4),
            child: Text(
              resolved.start == resolved.end
                  ? formatter.fullDay(resolved.start)
                  : '${formatter.date(resolved.start)} – ${formatter.date(resolved.end)}',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          AsyncValueView(
            value: async,
            data: (data) => _ReportBody(data: data),
          ),
        ],
      ),
    );
  }

  Future<void> _shareSummary(
    BuildContext context,
    WidgetRef ref,
    ReportData data,
  ) async {
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ShareSheet(data: data),
    );
    if (text == null) return;
    await ref
        .read(appLockProvider.notifier)
        .whileExternal(
          () => SharePlus.instance.share(
            ShareParams(text: text, subject: 'DAWASA'),
          ),
        );
  }
}

class _ReportBody extends ConsumerWidget {
  const _ReportBody({required this.data});

  final ReportData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = context.semantic;
    final currency = ref.watch(currencyProvider);
    final formatter = ref.watch(dateFormatterProvider);
    final hidden = ref.watch(balancesHiddenProvider);
    final t = data.totals;

    Widget summary(
      String label,
      int value,
      Color color, {
      bool signed = false,
      String? help,
    }) => Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.textTheme.labelMedium, maxLines: 2),
            const SizedBox(height: Gap.xs),
            MoneyText(
              value,
              showSign: signed,
              compact: true,
              color: color,
              style: context.textTheme.titleMedium,
            ),
            if (help != null)
              Text(
                help,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );

    final flowLabel = data.granularity == ReportGranularity.day
        ? (DateTime d) => '${d.day}'
        : (DateTime d) => formatter.monthShort(LocalDate.fromDateTime(d));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Gap.md),
        Row(
          children: [
            summary(l10n.reportTotalIncome, t.incomeMinor, s.income),
            const SizedBox(width: Gap.sm),
            summary(l10n.reportTotalExpenses, t.expenseMinor, s.expense),
          ],
        ),
        const SizedBox(height: Gap.sm),
        Row(
          children: [
            summary(
              l10n.reportNetCashFlow,
              t.netMinor,
              t.netMinor >= 0 ? s.income : s.expense,
              signed: true,
              help: l10n.reportNetHelp,
            ),
          ],
        ),
        if (data.isEmpty)
          EmptyState(
            icon: Icons.insights_outlined,
            message: l10n.reportNoData,
            compact: true,
          )
        else ...[
          SectionHeader(title: l10n.reportIncomeVsExpenses),
          AppCard(
            child: Column(
              children: [
                MoneyBarChart(
                  hidden: hidden,
                  currency: currency,
                  color: s.expense,
                  secondaryColor: s.income,
                  semanticsLabel: l10n.reportChartIncomeExpense(
                    Money.format(t.incomeMinor, currency),
                    Money.format(t.expenseMinor, currency),
                  ),
                  points: [
                    for (final pnt in data.cashFlow)
                      BarPoint(
                        label: flowLabel(pnt.start.startOfDayLocal),
                        valueMinor: pnt.expenseMinor,
                      ),
                  ],
                  secondaryPoints: [
                    for (final pnt in data.cashFlow)
                      BarPoint(label: '', valueMinor: pnt.incomeMinor),
                  ],
                ),
                const SizedBox(height: Gap.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Legend(color: s.income, label: l10n.txTypeIncome),
                    const SizedBox(width: Gap.lg),
                    _Legend(color: s.expense, label: l10n.txTypeExpense),
                  ],
                ),
              ],
            ),
          ),
          if (data.expenseByCategory.isNotEmpty) ...[
            SectionHeader(title: l10n.reportExpensesByCategory),
            _CategoryBreakdown(
              totals: data.expenseByCategory,
              total: t.expenseMinor,
            ),
          ],
          if (data.incomeByCategory.isNotEmpty) ...[
            SectionHeader(title: l10n.reportIncomeByCategory),
            _CategoryBreakdown(
              totals: data.incomeByCategory,
              total: t.incomeMinor,
              showChart: false,
            ),
          ],
          if (data.granularity == ReportGranularity.day &&
              data.cashFlow.length > 1) ...[
            SectionHeader(title: l10n.reportDailyTrend),
            AppCard(
              child: MoneyBarChart(
                hidden: hidden,
                currency: currency,
                color: s.expense,
                semanticsLabel: l10n.reportDailyTrend,
                points: [
                  for (final pnt in data.cashFlow)
                    BarPoint(
                      label: '${pnt.start.day}',
                      valueMinor: pnt.expenseMinor,
                    ),
                ],
              ),
            ),
          ],
          if (t.otherInMinor > 0 || t.otherOutMinor > 0) ...[
            SectionHeader(title: l10n.reportOtherMovements),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(l10n.reportMoneyIn)),
                      MoneyText(
                        t.otherInMinor,
                        style: context.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.xs),
                  Row(
                    children: [
                      Expanded(child: Text(l10n.reportMoneyOut)),
                      MoneyText(
                        t.otherOutMinor,
                        style: context.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.sm),
                  Text(
                    l10n.reportOtherMovementsHelp,
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
        SectionHeader(title: l10n.reportMonthlyTrend),
        AppCard(
          child: MoneyLineChart(
            currency: currency,
            semanticsLabel:
                '${l10n.reportMonthlyTrend}: ${data.monthlyTrend.map((m) => '${formatter.monthShort(m.start)} ${Money.format(m.expenseMinor, currency)}').join(', ')}',
            points: [
              for (final m in data.monthlyTrend)
                LinePoint(
                  label: formatter.monthShort(m.start),
                  valueMinor: m.expenseMinor,
                ),
            ],
          ),
        ),
        const _BudgetPerformance(),
        const _BalancesSection(),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: context.textTheme.labelMedium),
    ],
  );
}

class _CategoryBreakdown extends ConsumerWidget {
  const _CategoryBreakdown({
    required this.totals,
    required this.total,
    this.showChart = true,
  });

  final List<CategoryTotal> totals;
  final int total;
  final bool showChart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currency = ref.watch(currencyProvider);
    String label(CategoryTotal c) =>
        c.category?.label(l10n) ?? l10n.categoryUncategorized;
    Color color(CategoryTotal c) => c.category == null
        ? context.semantic.neutral
        : Color(c.category!.colorValue);
    return AppCard(
      child: Column(
        children: [
          if (showChart)
            DonutChart(
              semanticsLabel: totals
                  .map(
                    (c) => '${label(c)} ${Money.percent(c.totalMinor, total)}%',
                  )
                  .join(', '),
              slices: [
                for (final c in totals)
                  DonutSlice(
                    label: label(c),
                    valueMinor: c.totalMinor,
                    color: color(c),
                  ),
              ],
              center: MoneyText(
                total,
                compact: true,
                style: context.textTheme.titleSmall,
              ),
            ),
          const SizedBox(height: Gap.md),
          for (final c in totals)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  if (c.category != null)
                    Icon(
                      AppIcons.forKey(c.category!.iconKey),
                      color: color(c),
                      size: 20,
                    )
                  else
                    Icon(Icons.help_outline_rounded, color: color(c), size: 20),
                  const SizedBox(width: Gap.sm),
                  Expanded(child: Text(label(c))),
                  Text(
                    '${Money.percent(c.totalMinor, total)}%',
                    style: context.textTheme.bodySmall,
                  ),
                  const SizedBox(width: Gap.md),
                  MoneyText(
                    c.totalMinor,
                    currency: currency,
                    style: context.textTheme.titleSmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetPerformance extends ConsumerWidget {
  const _BudgetPerformance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetProgressProvider).value ?? const [];
    if (budgets.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: context.l10n.budgetPerformance),
        for (final b in budgets)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.sm),
            child: BudgetCard(progress: b),
          ),
      ],
    );
  }
}

class _BalancesSection extends ConsumerWidget {
  const _BalancesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accounts = (ref.watch(accountBalancesProvider).value ?? const [])
        .where((a) => !a.account.isArchived)
        .toList();
    final loans = ref.watch(loansProvider).value ?? const [];
    final goals = ref.watch(savingsGoalsProvider).value ?? const [];
    final deposited = ref.watch(savingsDepositedProvider).value ?? 0;
    final currency = ref.watch(currencyProvider);
    var owedToYou = 0, youOwe = 0;
    for (final l in loans.where((l) => l.loan.currencyCode == currency.code)) {
      l.isLent ? owedToYou += l.outstandingMinor : youOwe += l.outstandingMinor;
    }
    final saved = goals
        .where((g) => g.goal.currencyCode == currency.code)
        .fold<int>(0, (s, g) => s + g.savedMinor);
    Widget row(String label, int amount, {Currency? cur, Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              MoneyText(
                amount,
                currency: cur,
                style: context.textTheme.titleSmall,
                color: color,
              ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.reportAccountBalances),
        AppCard(
          child: Column(
            children: [
              for (final a in accounts)
                row(
                  a.account.name,
                  a.balanceMinor,
                  cur: Currencies.byCode(a.account.currencyCode),
                ),
            ],
          ),
        ),
        if (loans.isNotEmpty) ...[
          SectionHeader(title: l10n.reportLoanBalances),
          AppCard(
            child: Column(
              children: [
                row(
                  l10n.loanTotalOwedToYou,
                  owedToYou,
                  color: context.semantic.income,
                ),
                row(
                  l10n.loanTotalYouOwe,
                  youOwe,
                  color: context.semantic.expense,
                ),
              ],
            ),
          ),
        ],
        if (goals.isNotEmpty) ...[
          SectionHeader(title: l10n.reportSavings),
          AppCard(
            child: Column(
              children: [
                row(l10n.savingsTotalSaved, saved),
                row(l10n.reportSavingsTransfers, deposited),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Lets the user choose what the shared summary contains.
class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.data});

  final ReportData data;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  bool _categories = true;
  bool _balances = false;

  String _text() {
    final l10n = context.l10n;
    final currency = ref.read(currencyProvider);
    final formatter = ref.read(dateFormatterProvider);
    final d = widget.data;
    final lines = <String>[
      'DAWASA — ${l10n.reportsTitle}',
      '${formatter.date(d.range.start)} – ${formatter.date(d.range.end)}',
      '',
      '${l10n.reportTotalIncome}: ${Money.format(d.totals.incomeMinor, currency)}',
      '${l10n.reportTotalExpenses}: ${Money.format(d.totals.expenseMinor, currency)}',
      '${l10n.reportNetCashFlow}: ${Money.format(d.totals.netMinor, currency, showSign: true)}',
    ];
    if (_categories && d.expenseByCategory.isNotEmpty) {
      lines
        ..add('')
        ..add('${l10n.reportExpensesByCategory}:');
      for (final c in d.expenseByCategory) {
        lines.add(
          '• ${c.category?.label(l10n) ?? l10n.categoryUncategorized}: ${Money.format(c.totalMinor, currency)}',
        );
      }
    }
    if (_balances) {
      final accounts = ref.read(accountBalancesProvider).value ?? const [];
      lines
        ..add('')
        ..add('${l10n.reportAccountBalances}:');
      for (final a in accounts.where((a) => !a.account.isArchived)) {
        lines.add(
          '• ${a.account.name}: ${Money.format(a.balanceMinor, Currencies.byCode(a.account.currencyCode))}',
        );
      }
    }
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
        children: [
          Text(l10n.reportShareTitle, style: context.textTheme.titleLarge),
          const SizedBox(height: Gap.sm),
          Text(l10n.reportSharePrivacy, style: context.textTheme.bodySmall),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.reportShareIncludeCategories),
            value: _categories,
            onChanged: (v) => setState(() => _categories = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.reportShareIncludeBalances),
            value: _balances,
            onChanged: (v) => setState(() => _balances = v),
          ),
          Text(l10n.reportPreview, style: context.textTheme.labelLarge),
          const SizedBox(height: Gap.xs),
          AppCard(
            color: context.colors.surfaceContainerLow,
            child: Text(_text(), style: context.textTheme.bodySmall),
          ),
          const SizedBox(height: Gap.lg),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(_text()),
            icon: const Icon(Icons.ios_share_rounded),
            label: Text(l10n.actionShare),
          ),
        ],
      ),
    );
  }
}

/// CSV export with explicit privacy choices.
class ExportSheet extends ConsumerStatefulWidget {
  const ExportSheet({super.key, required this.range});

  final DateRange range;

  @override
  ConsumerState<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<ExportSheet> {
  bool _notes = false;
  bool _accounts = true;

  Future<(String, List<int>, int)> _build() async {
    final rows = await ref
        .read(transactionRepositoryProvider)
        .filtered(TransactionFilter(range: widget.range));
    if (!mounted) return ('', <int>[], 0);
    const exporter = CsvExporter();
    final csv = exporter.build(
      rows,
      context.l10n,
      options: CsvExportOptions(
        includeNotes: _notes,
        includeAccounts: _accounts,
      ),
    );
    final name =
        'dawasa-transactions-${widget.range.start.toIso()}-${widget.range.end.toIso()}.csv';
    return (name, exporter.encode(csv), rows.length);
  }

  Future<void> _share() async {
    final l10n = context.l10n;
    final (name, bytes, count) = await _build();
    if (!mounted) return;
    if (count == 0) {
      showAppSnackBar(context, l10n.exportNothing);
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes, flush: true);
    await ref
        .read(appLockProvider.notifier)
        .whileExternal(
          () => SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'text/csv')],
              subject: name,
            ),
          ),
        );
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final (name, bytes, count) = await _build();
    if (!mounted) return;
    if (count == 0) {
      showAppSnackBar(context, l10n.exportNothing);
      return;
    }
    final uri = await ref
        .read(appLockProvider.notifier)
        .whileExternal(
          () => FilePicker.saveFile(
            fileName: name,
            bytes: Uint8List.fromList(bytes),
            mimeType: 'text/csv',
            allowedExtensions: const ['csv'],
            type: FileType.custom,
          ),
        );
    if (uri != null && mounted) showAppSnackBar(context, l10n.exportDone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatter = ref.watch(dateFormatterProvider);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
        children: [
          Text(l10n.exportTitle, style: context.textTheme.titleLarge),
          Text(
            '${formatter.date(widget.range.start)} – ${formatter.date(widget.range.end)}',
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.exportIncludeNotes),
            value: _notes,
            onChanged: (v) => setState(() => _notes = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.exportIncludeAccounts),
            value: _accounts,
            onChanged: (v) => setState(() => _accounts = v),
          ),
          Text(
            l10n.exportPrivacyNote,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.semantic.warning,
            ),
          ),
          const SizedBox(height: Gap.lg),
          SubmitButton(
            label: l10n.backupSaveToDevice,
            icon: Icons.save_alt_rounded,
            onSubmit: _save,
          ),
          const SizedBox(height: Gap.sm),
          SubmitButton(
            label: l10n.actionShare,
            icon: Icons.ios_share_rounded,
            tonal: true,
            onSubmit: _share,
          ),
        ],
      ),
    );
  }
}
