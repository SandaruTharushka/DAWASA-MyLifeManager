import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../time/local_date.dart';
import 'app_database.steps.dart';
import 'converters.dart';
import 'enums.dart';
import 'seed.dart';
import 'tables/common.dart';
import 'tables/finance_tables.dart';
import 'tables/planner_tables.dart';
import 'tables/system_tables.dart';

export 'enums.dart';
export 'tables/common.dart' show newId, deterministicId, nowUtc;

part 'app_database.g.dart';

/// The single local SQLite database of DAWASA.
///
/// Schema history (never edit a released version, only add new ones):
///  * v1 – accounts, categories, transactions, recurring rules, attachments,
///         settings, migration log.
///  * v2 – budgets, tasks, task reminders, bills, bill payments, shopping.
@DriftDatabase(
  tables: [
    Accounts,
    TransactionCategories,
    Attachments,
    RecurringRules,
    Transactions,
    AppSettings,
    SchemaMigrations,
    Budgets,
    BudgetCategories,
    Tasks,
    TaskReminders,
    Bills,
    BillPayments,
    ShoppingLists,
    ShoppingItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static const int latestSchemaVersion = 2;

  @override
  int get schemaVersion => latestSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await DatabaseSeeder(this).seedDefaults();
      await _logMigration(schemaVersion, 'Initial schema v$schemaVersion');
    },
    onUpgrade: (m, from, to) async {
      // Foreign keys are checked again in beforeOpen; disabling them while
      // tables are created keeps migrations order-independent.
      await customStatement('PRAGMA foreign_keys = OFF');
      await transaction(() async {
        await stepByStep(
          from1To2: (m, schema) async {
            await m.createTable(schema.budgets);
            await m.createTable(schema.budgetCategories);
            await m.createTable(schema.tasks);
            await m.createTable(schema.taskReminders);
            await m.createTable(schema.bills);
            await m.createTable(schema.billPayments);
            await m.createTable(schema.shoppingLists);
            await m.createTable(schema.shoppingItems);
            await m.createIndex(schema.idxTasksDue);
            await m.createIndex(schema.idxBillsDue);
            await m.createIndex(schema.idxBillPaymentsBill);
            await m.createIndex(schema.idxShoppingItemsList);
            await _logMigration(2, 'Budgets, tasks, bills and shopping lists');
          },
        )(m, from, to);
      });
      await customStatement('PRAGMA foreign_keys = ON');
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (kDebugMode) {
        final violations = await customSelect('PRAGMA foreign_key_check').get();
        assert(violations.isEmpty, 'Foreign key violations: $violations');
      }
    },
  );

  Future<void> _logMigration(int version, String description) {
    return into(schemaMigrations).insert(
      SchemaMigrationsCompanion.insert(
        version: Value(version),
        description: description,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
}
