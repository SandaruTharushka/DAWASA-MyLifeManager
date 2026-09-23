import '../database/enums.dart';

/// The single source of truth for how each [TransactionType] affects account
/// balances and financial totals.
///
/// * Only [TransactionType.expense] counts as spending.
/// * Only [TransactionType.income] counts as income.
/// * Every other type moves money without being income or spending, which
///   prevents double-counting of transfers, savings movements, loan
///   principal, reimbursements and balance corrections.
abstract final class TransactionRules {
  /// Types that add money to `account_id`.
  static const Set<TransactionType> inflowTypes = {
    TransactionType.income,
    TransactionType.reimbursement,
    TransactionType.loanReceived,
    TransactionType.loanRepaymentReceived,
    TransactionType.adjustmentIn,
  };

  /// Types that remove money from `account_id` (transfers too, while also
  /// adding the same amount to `to_account_id`).
  static const Set<TransactionType> outflowTypes = {
    TransactionType.expense,
    TransactionType.loanGiven,
    TransactionType.loanRepaymentPaid,
    TransactionType.adjustmentOut,
    TransactionType.transfer,
  };

  static bool countsAsIncome(TransactionType type) =>
      type == TransactionType.income;

  static bool countsAsSpending(TransactionType type) =>
      type == TransactionType.expense;

  static bool requiresCategory(TransactionType type) =>
      type == TransactionType.expense || type == TransactionType.income;

  static bool isTransfer(TransactionType type) =>
      type == TransactionType.transfer;

  /// Effect of a single transaction on [accountId]'s balance (signed).
  static int balanceEffect({
    required TransactionType type,
    required int amountMinor,
    required String accountId,
    required String? toAccountId,
    required String forAccountId,
  }) {
    var effect = 0;
    if (accountId == forAccountId) {
      effect += inflowTypes.contains(type) ? amountMinor : -amountMinor;
    }
    if (type == TransactionType.transfer && toAccountId == forAccountId) {
      effect += amountMinor;
    }
    return effect;
  }

  /// SQL expression (for a `transactions` row aliased [alias]) giving the
  /// signed effect on `account_id`. Generated from [inflowTypes] so SQL and
  /// Dart can never disagree.
  static String signedAmountSql(String alias) {
    final inflows = inflowTypes.map((t) => "'${t.name}'").join(', ');
    return 'CASE WHEN $alias.type IN ($inflows) '
        'THEN $alias.amount_minor ELSE -$alias.amount_minor END';
  }
}
