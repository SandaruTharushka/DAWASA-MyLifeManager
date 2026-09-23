// Enumerations persisted in the database.
//
// Values are stored by *name* (drift `textEnum`), so the order may change but
// an existing name must NEVER be renamed or removed: that would break
// existing users' data. Add new values only.

enum AccountType { cash, bank, eWallet, savings, other }

enum CategoryKind { expense, income }

/// Every money movement recorded in DAWASA.
///
/// Only [expense] counts as spending and only [income] counts as income. All
/// other types move money without being income or spending, which is how the
/// app prevents double-counting of transfers, loans and reimbursements.
enum TransactionType {
  /// Money spent. Reduces the account balance and counts as spending.
  expense,

  /// Money earned. Increases the account balance and counts as income.
  income,

  /// Money moved between two of the user's own accounts.
  transfer,

  /// Money received back for something previously paid on someone else's
  /// behalf. Increases the balance, is not income.
  reimbursement,

  /// Principal lent to someone (money leaves the account, not spending).
  loanGiven,

  /// Principal borrowed from someone (money enters the account, not income).
  loanReceived,

  /// Principal repaid *to* the user by a borrower (not income).
  loanRepaymentReceived,

  /// Principal repaid *by* the user to a lender (not spending).
  loanRepaymentPaid,

  /// User-confirmed balance correction that increases the balance.
  adjustmentIn,

  /// User-confirmed balance correction that decreases the balance.
  adjustmentOut,
}

/// Where a transaction came from; used for labels and duplicate prevention.
enum TransactionSource { manual, recurring, bill, shopping, savings, loan }

enum BudgetPeriod { daily, weekly, monthly, custom }

enum TaskPriority { low, medium, high }

enum BillCategory {
  electricity,
  water,
  internet,
  mobile,
  rent,
  insurance,
  loan,
  other,
}

enum SavingsMovementType { deposit, withdrawal }

enum LoanDirection {
  /// The user lent money: someone owes the user.
  lent,

  /// The user borrowed money: the user owes someone.
  borrowed,
}

enum LoanStatus { active, settled }

enum HabitFrequency { daily, weekly }

enum EventType { birthday, anniversary, appointment, exam, other }
