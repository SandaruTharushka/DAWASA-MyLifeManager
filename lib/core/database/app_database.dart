import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../time/local_date.dart';
import 'converters.dart';
import 'enums.dart';
import 'seed.dart';
import 'tables/common.dart';
import 'tables/finance_tables.dart';
import 'tables/system_tables.dart';

export 'enums.dart';
export 'tables/common.dart' show newId, deterministicId, nowUtc;

part 'app_database.g.dart';

/// The single local SQLite database of DAWASA.
///
/// Schema history (never edit a released version, only add new ones):
///  * v1 – accounts, categories, transactions, recurring rules, attachments,
///         settings, migration log.
@DriftDatabase(
  tables: [
    Accounts,
    TransactionCategories,
    Attachments,
    RecurringRules,
    Transactions,
    AppSettings,
    SchemaMigrations,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static const int latestSchemaVersion = 1;

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
      // Upgrades are added here as the schema evolves.
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
