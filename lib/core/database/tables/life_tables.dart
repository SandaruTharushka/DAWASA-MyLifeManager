import 'package:drift/drift.dart';

import '../converters.dart';
import '../enums.dart';
import 'common.dart';
import 'finance_tables.dart';

// Schema v3 tables: savings goals, loans, habits and important dates.

@DataClassName('SavingsGoalRow')
class SavingsGoals extends Table with UuidPrimaryKey, Timestamps {
  TextColumn get name => text().withLength(min: 1, max: 60)();
  IntColumn get targetAmountMinor => integer()();
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('LKR'))();
  TextColumn get targetDate =>
      text().map(const LocalDateConverter()).nullable()();

  /// Savings account where the money is kept (deposits become transfers).
  TextColumn get linkedAccountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get iconKey => text().withDefault(const Constant('savings'))();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF16A34A))();

  /// Monthly reminder to contribute (on the 1st).
  BoolColumn get remindMonthly =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  List<String> get customConstraints => ['CHECK (target_amount_minor > 0)'];
}

@DataClassName('SavingsMovementRow')
@TableIndex(name: 'idx_savings_movements_goal', columns: {#goalId})
class SavingsMovements extends Table with UuidPrimaryKey {
  TextColumn get goalId =>
      text().references(SavingsGoals, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => textEnum<SavingsMovementType>()();
  IntColumn get amountMinor => integer()();
  TextColumn get localDate => text().map(const LocalDateConverter())();
  DateTimeColumn get occurredAt => dateTime()();

  /// Account movement, when money actually moved between accounts. Deleting
  /// that transfer removes the movement too, keeping goal and balances in
  /// sync.
  TextColumn get transactionId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(nowUtc)();

  @override
  List<String> get customConstraints => ['CHECK (amount_minor > 0)'];
}

@DataClassName('LoanRow')
class Loans extends Table with UuidPrimaryKey, Timestamps {
  TextColumn get direction => textEnum<LoanDirection>()();
  TextColumn get counterparty => text().withLength(min: 1, max: 80)();
  IntColumn get principalMinor => integer()();
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('LKR'))();

  /// Optional annual interest rate in basis points (12.5% = 1250).
  IntColumn get interestRateBps => integer().nullable()();
  TextColumn get startDate => text().map(const LocalDateConverter())();
  TextColumn get dueDate => text().map(const LocalDateConverter()).nullable()();

  /// Account the principal left (lent) or entered (borrowed), if recorded.
  TextColumn get accountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get disbursementTransactionId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get status =>
      textEnum<LoanStatus>().withDefault(Constant(LoanStatus.active.name))();
  DateTimeColumn get settledAt => dateTime().nullable()();
  IntColumn get remindDaysBefore => integer().withDefault(const Constant(3))();
  BoolColumn get remindersEnabled =>
      boolean().withDefault(const Constant(true))();
  TextColumn get note => text().nullable()();

  @override
  List<String> get customConstraints => [
    'CHECK (principal_minor > 0)',
    'CHECK (interest_rate_bps IS NULL OR interest_rate_bps >= 0)',
  ];
}

@DataClassName('LoanRepaymentRow')
@TableIndex(name: 'idx_loan_repayments_loan', columns: {#loanId})
class LoanRepayments extends Table with UuidPrimaryKey {
  TextColumn get loanId =>
      text().references(Loans, #id, onDelete: KeyAction.cascade)();

  /// Reduces the outstanding balance; never income or spending.
  IntColumn get principalMinor => integer().withDefault(const Constant(0))();

  /// Recorded as income (lent) or expense (borrowed).
  IntColumn get interestMinor => integer().withDefault(const Constant(0))();
  TextColumn get localDate => text().map(const LocalDateConverter())();
  DateTimeColumn get paidAt => dateTime()();
  TextColumn get accountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.setNull,
  )();
  @ReferenceName('loanPrincipalRepayments')
  TextColumn get principalTransactionId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.cascade,
  )();
  @ReferenceName('loanInterestRepayments')
  TextColumn get interestTransactionId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(nowUtc)();

  @override
  List<String> get customConstraints => [
    'CHECK (principal_minor >= 0 AND interest_minor >= 0)',
    'CHECK (principal_minor + interest_minor > 0)',
  ];
}

@DataClassName('HabitRow')
class Habits extends Table with UuidPrimaryKey, Timestamps {
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get iconKey => text().withDefault(const Constant('star'))();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF0EA5E9))();
  TextColumn get frequency => textEnum<HabitFrequency>()();

  /// Times per day (daily) or per week (weekly) to count as done.
  IntColumn get targetCount => integer().withDefault(const Constant(1))();
  IntColumn get reminderMinutes => integer().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  List<String> get customConstraints => [
    'CHECK (target_count BETWEEN 1 AND 99)',
  ];
}

@DataClassName('HabitLogRow')
@TableIndex(name: 'idx_habit_logs_date', columns: {#habitId, #date})
class HabitLogs extends Table with UuidPrimaryKey {
  TextColumn get habitId =>
      text().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get date => text().map(const LocalDateConverter())();
  IntColumn get count => integer().withDefault(const Constant(1))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {habitId, date},
  ];

  @override
  List<String> get customConstraints => ['CHECK (count >= 0)'];
}

@DataClassName('PersonalEventRow')
@TableIndex(name: 'idx_events_date', columns: {#date})
class PersonalEvents extends Table with UuidPrimaryKey, Timestamps {
  TextColumn get title => text().withLength(min: 1, max: 80)();
  TextColumn get type => textEnum<EventType>()();

  /// First (or only) date; recurring events repeat from here.
  TextColumn get date => text().map(const LocalDateConverter())();
  IntColumn get timeMinutes => integer().nullable()();

  /// Encoded RecurrenceRule (birthdays default to yearly).
  TextColumn get recurrence => text().nullable()();
  IntColumn get remindDaysBefore => integer().nullable()();
  IntColumn get remindAtMinutes =>
      integer().withDefault(const Constant(9 * 60))();

  /// Optional planned spending for the event (informational only).
  IntColumn get budgetMinor => integer().nullable()();
  TextColumn get note => text().nullable()();

  @override
  List<String> get customConstraints => [
    'CHECK (budget_minor IS NULL OR budget_minor >= 0)',
  ];
}
