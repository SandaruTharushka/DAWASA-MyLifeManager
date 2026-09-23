import 'package:drift/drift.dart';

import '../converters.dart';
import '../enums.dart';
import 'common.dart';
import 'finance_tables.dart';

// Schema v2 tables: budgets, tasks, bills and shopping lists.

@DataClassName('BudgetRow')
class Budgets extends Table with UuidPrimaryKey, Timestamps {
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get period => textEnum<BudgetPeriod>()();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('LKR'))();

  /// Only for custom periods.
  TextColumn get startDate =>
      text().map(const LocalDateConverter()).nullable()();
  TextColumn get endDate => text().map(const LocalDateConverter()).nullable()();

  /// Warn when this share (percent) of the budget is used.
  IntColumn get warnPercent => integer().withDefault(const Constant(80))();
  BoolColumn get notify => boolean().withDefault(const Constant(true))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Last alert raised, as `<periodKey>:<level>` (prevents repeated alerts).
  TextColumn get lastAlert => text().nullable()();

  @override
  List<String> get customConstraints => [
    'CHECK (amount_minor > 0)',
    'CHECK (warn_percent BETWEEN 1 AND 100)',
    "CHECK (period <> 'custom' OR (start_date IS NOT NULL AND end_date IS NOT NULL AND end_date >= start_date))",
  ];
}

/// Categories a budget is limited to. No rows = overall spending budget.
@DataClassName('BudgetCategoryRow')
class BudgetCategories extends Table {
  TextColumn get budgetId =>
      text().references(Budgets, #id, onDelete: KeyAction.cascade)();
  TextColumn get categoryId => text().references(
    TransactionCategories,
    #id,
    onDelete: KeyAction.cascade,
  )();

  @override
  Set<Column<Object>> get primaryKey => {budgetId, categoryId};
}

@DataClassName('TaskRow')
@TableIndex(name: 'idx_tasks_due', columns: {#isCompleted, #dueDate})
class Tasks extends Table with UuidPrimaryKey, Timestamps {
  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get description => text().nullable()();
  TextColumn get dueDate => text().map(const LocalDateConverter()).nullable()();

  /// Minutes since local midnight.
  IntColumn get dueTimeMinutes => integer().nullable()();
  TextColumn get priority => textEnum<TaskPriority>().withDefault(
    Constant(TaskPriority.medium.name),
  )();

  /// Encoded RecurrenceRule; completing a recurring task creates the next one.
  TextColumn get recurrence => text().nullable()();

  /// Shared by all tasks of the same recurring series.
  TextColumn get seriesId => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

@DataClassName('TaskReminderRow')
class TaskReminders extends Table with UuidPrimaryKey {
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();

  /// Minutes before the due date/time (0 = at the due time).
  IntColumn get minutesBefore => integer().withDefault(const Constant(0))();

  @override
  List<String> get customConstraints => ['CHECK (minutes_before >= 0)'];
}

@DataClassName('BillRow')
@TableIndex(name: 'idx_bills_due', columns: {#isActive, #nextDueDate})
class Bills extends Table with UuidPrimaryKey, Timestamps {
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get category => textEnum<BillCategory>()();

  /// Expected amount; the actual paid amount may differ.
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('LKR'))();

  /// Due date of the next unpaid cycle.
  TextColumn get nextDueDate => text().map(const LocalDateConverter())();

  /// Encoded RecurrenceRule; null for one-time payments.
  TextColumn get recurrence => text().nullable()();
  TextColumn get startDate => text().map(const LocalDateConverter())();

  /// Days before the due date to remind (0 = on the day).
  IntColumn get remindDaysBefore => integer().withDefault(const Constant(2))();
  IntColumn get remindAtMinutes =>
      integer().withDefault(const Constant(9 * 60))();
  BoolColumn get remindersEnabled =>
      boolean().withDefault(const Constant(true))();
  TextColumn get accountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get note => text().nullable()();

  /// False once a one-time bill is paid or the user stops it.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  List<String> get customConstraints => [
    'CHECK (amount_minor > 0)',
    'CHECK (remind_days_before >= 0)',
  ];
}

@DataClassName('BillPaymentRow')
@TableIndex(name: 'idx_bill_payments_bill', columns: {#billId})
class BillPayments extends Table with UuidPrimaryKey {
  TextColumn get billId =>
      text().references(Bills, #id, onDelete: KeyAction.cascade)();

  /// The due date of the cycle that was paid.
  TextColumn get dueDate => text().map(const LocalDateConverter())();
  DateTimeColumn get paidAt => dateTime()();
  IntColumn get amountMinor => integer()();

  /// Expense recorded for this payment, if any (created or linked).
  TextColumn get transactionId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get note => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {billId, dueDate},
  ];
}

@DataClassName('ShoppingListRow')
class ShoppingLists extends Table with UuidPrimaryKey, Timestamps {
  TextColumn get name => text().withLength(min: 1, max: 60)();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

@DataClassName('ShoppingItemRow')
@TableIndex(name: 'idx_shopping_items_list', columns: {#listId})
class ShoppingItems extends Table with UuidPrimaryKey, Timestamps {
  TextColumn get listId =>
      text().references(ShoppingLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// Quantity in thousandths (1.5 kg = 1500) to avoid floating point.
  IntColumn get quantityMilli => integer().withDefault(const Constant(1000))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();

  /// Estimated line total. Never affects balances.
  IntColumn get estimatedPriceMinor => integer().nullable()();

  /// Actual line total paid.
  IntColumn get actualPriceMinor => integer().nullable()();
  BoolColumn get isPurchased => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Expense this purchase was recorded in. Set once, so an item can never
  /// be counted twice.
  TextColumn get transactionId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )();

  @override
  List<String> get customConstraints => [
    'CHECK (quantity_milli > 0)',
    'CHECK (estimated_price_minor IS NULL OR estimated_price_minor >= 0)',
    'CHECK (actual_price_minor IS NULL OR actual_price_minor >= 0)',
  ];
}
