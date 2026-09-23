import 'dart:convert';

import '../../../core/database/enums.dart';
import '../../../core/finance/transaction_rules.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../transactions/domain/transaction_models.dart';

/// What to include in an export. Private text is excluded by default.
class CsvExportOptions {
  const CsvExportOptions({
    this.includeNotes = false,
    this.includeAccounts = true,
  });

  final bool includeNotes;
  final bool includeAccounts;
}

/// Writes transactions as RFC 4180 CSV. The output starts with a UTF-8 BOM
/// so spreadsheet apps show Sinhala text correctly.
class CsvExporter {
  const CsvExporter();

  /// Escapes a field. Text fields that look like spreadsheet formulas are
  /// neutralised; numeric fields (amounts) are left untouched.
  static String escape(String value, {bool text = true}) {
    final needsQuotes =
        value.contains(RegExp(r'[",\r\n]')) ||
        value.startsWith(' ') ||
        value.endsWith(' ');
    final safe = text && RegExp(r'^[=+\-@\t]').hasMatch(value)
        ? "'$value"
        : value;
    if (!needsQuotes && safe == value) return value;
    return '"${safe.replaceAll('"', '""')}"';
  }

  String build(
    List<TransactionView> rows,
    AppLocalizations l10n, {
    CsvExportOptions options = const CsvExportOptions(),
  }) {
    final buffer = StringBuffer('﻿');
    final header = [
      l10n.csvDate,
      l10n.csvTime,
      l10n.csvType,
      l10n.csvCountsAs,
      l10n.csvCategory,
      if (options.includeAccounts) l10n.csvAccount,
      if (options.includeAccounts) l10n.csvToAccount,
      l10n.csvAmount,
      l10n.csvCurrency,
      if (options.includeNotes) l10n.csvDescription,
      if (options.includeNotes) l10n.csvNote,
    ];
    buffer.writeln(header.map(escape).join(','));
    for (final v in rows) {
      final t = v.transaction;
      final local = t.occurredAt.toLocal();
      final currency = Currencies.byCode(t.currencyCode);
      final counts = TransactionRules.countsAsIncome(t.type)
          ? l10n.csvCountsIncome
          : TransactionRules.countsAsSpending(t.type)
          ? l10n.csvCountsExpense
          : l10n.csvCountsNeither;
      final signed = TransactionRules.inflowTypes.contains(t.type)
          ? t.amountMinor
          : t.type == TransactionType.transfer
          ? t.amountMinor
          : -t.amountMinor;
      final amount = Money.formatPlain(
        signed,
        decimalDigits: currency.decimalDigits,
        grouping: false,
      );
      final fields = <Object>[
        t.localDate.toIso(),
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}',
        l10n.transactionTypeLabel(t.type),
        counts,
        v.category?.label(l10n) ?? '',
        if (options.includeAccounts) v.account.name,
        if (options.includeAccounts) v.toAccount?.name ?? '',
        _numeric(amount),
        t.currencyCode,
        if (options.includeNotes) t.description,
        if (options.includeNotes) t.note ?? '',
      ];
      buffer.writeln(
        fields
            .map(
              (f) => f is _Numeric
                  ? escape(f.value, text: false)
                  : escape(f as String),
            )
            .join(','),
      );
    }
    return buffer.toString();
  }

  List<int> encode(String csv) => utf8.encode(csv);

  static _Numeric _numeric(String v) => _Numeric(v);
}

class _Numeric {
  const _Numeric(this.value);

  final String value;
}
