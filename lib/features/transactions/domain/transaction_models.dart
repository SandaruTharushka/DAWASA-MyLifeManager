import '../../../core/database/app_database.dart';
import '../../../core/finance/transaction_rules.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/time/date_range.dart';
import '../../../core/time/local_date.dart';

/// Everything needed to create or update a transaction.
class TransactionDraft {
  const TransactionDraft({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.currencyCode,
    required this.accountId,
    required this.occurredAt,
    this.toAccountId,
    this.categoryId,
    this.description = '',
    this.note,
    this.attachmentId,
    this.source = TransactionSource.manual,
    this.sourceRefId,
    this.recurringRuleId,
  });

  /// Pre-generated when the form opens. Saving the same draft twice hits the
  /// primary key and can therefore never create a duplicate.
  final String id;
  final TransactionType type;
  final int amountMinor;
  final String currencyCode;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;

  /// Local date and time chosen by the user.
  final DateTime occurredAt;
  final String description;
  final String? note;
  final String? attachmentId;
  final TransactionSource source;
  final String? sourceRefId;
  final String? recurringRuleId;

  LocalDate get localDate => LocalDate.fromDateTime(occurredAt);

  TransactionDraft copyWith({
    String? id,
    TransactionType? type,
    int? amountMinor,
    String? accountId,
    String? toAccountId,
    String? categoryId,
    DateTime? occurredAt,
    String? description,
    String? note,
    String? attachmentId,
    TransactionSource? source,
    String? sourceRefId,
    String? recurringRuleId,
  }) => TransactionDraft(
    id: id ?? this.id,
    type: type ?? this.type,
    amountMinor: amountMinor ?? this.amountMinor,
    currencyCode: currencyCode,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId ?? this.toAccountId,
    categoryId: categoryId ?? this.categoryId,
    occurredAt: occurredAt ?? this.occurredAt,
    description: description ?? this.description,
    note: note ?? this.note,
    attachmentId: attachmentId ?? this.attachmentId,
    source: source ?? this.source,
    sourceRefId: sourceRefId ?? this.sourceRefId,
    recurringRuleId: recurringRuleId ?? this.recurringRuleId,
  );
}

enum TransactionValidationError {
  amountNotPositive,
  sameAccount,
  missingToAccount,
  unexpectedToAccount,
  currencyMismatch,
  missingCategory,
  categoryKindMismatch,
  unknownAccount,
}

class TransactionValidationException implements Exception {
  const TransactionValidationException(this.error);

  final TransactionValidationError error;

  @override
  String toString() => 'TransactionValidationException($error)';
}

/// Outcome of saving a new transaction.
enum SaveOutcome { created, alreadyExisted }

/// A transaction joined with the rows needed to display it.
class TransactionView {
  const TransactionView({
    required this.transaction,
    required this.account,
    this.toAccount,
    this.category,
  });

  final MoneyTransaction transaction;
  final Account account;
  final Account? toAccount;
  final TxCategory? category;

  TransactionType get type => transaction.type;
  bool get isExpense => TransactionRules.countsAsSpending(type);
  bool get isIncome => TransactionRules.countsAsIncome(type);
}

/// Filters for the transaction list.
class TransactionFilter {
  const TransactionFilter({
    this.types = const {},
    this.categoryIds = const {},
    this.accountId,
    this.range,
    this.search = '',
  });

  final Set<TransactionType> types;
  final Set<String> categoryIds;
  final String? accountId;
  final DateRange? range;
  final String search;

  bool get isEmpty =>
      types.isEmpty &&
      categoryIds.isEmpty &&
      accountId == null &&
      range == null &&
      search.trim().isEmpty;

  TransactionFilter copyWith({
    Set<TransactionType>? types,
    Set<String>? categoryIds,
    String? accountId,
    bool clearAccount = false,
    DateRange? range,
    bool clearRange = false,
    String? search,
  }) => TransactionFilter(
    types: types ?? this.types,
    categoryIds: categoryIds ?? this.categoryIds,
    accountId: clearAccount ? null : (accountId ?? this.accountId),
    range: clearRange ? null : (range ?? this.range),
    search: search ?? this.search,
  );

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.accountId == accountId &&
      other.range == range &&
      other.search == search &&
      other.types.length == types.length &&
      other.types.containsAll(types) &&
      other.categoryIds.length == categoryIds.length &&
      other.categoryIds.containsAll(categoryIds);

  @override
  int get hashCode => Object.hash(
    accountId,
    range,
    search,
    Object.hashAllUnordered(types),
    Object.hashAllUnordered(categoryIds),
  );
}

/// Income and spending totals of a period. Transfers, loans, reimbursements
/// and corrections are reported separately and never mixed into these.
class PeriodTotals {
  const PeriodTotals({
    required this.incomeMinor,
    required this.expenseMinor,
    this.otherInMinor = 0,
    this.otherOutMinor = 0,
  });

  static const zero = PeriodTotals(incomeMinor: 0, expenseMinor: 0);

  final int incomeMinor;
  final int expenseMinor;

  /// Non-income inflows (reimbursements, borrowed money, repayments
  /// received, positive corrections).
  final int otherInMinor;

  /// Non-spending outflows (money lent, repayments paid, negative
  /// corrections). Transfers are excluded because they net to zero.
  final int otherOutMinor;

  /// Income minus expenses.
  int get netMinor => incomeMinor - expenseMinor;
}

class CategoryTotal {
  const CategoryTotal({required this.category, required this.totalMinor});

  final TxCategory? category;
  final int totalMinor;
}

extension TxCategoryLabel on TxCategory {
  String label(AppLocalizations l10n) =>
      name ?? l10n.systemCategoryLabel(systemKey ?? 'other');
}
