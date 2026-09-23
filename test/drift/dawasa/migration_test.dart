// dart format width=80
// ignore_for_file: unused_local_variable, unused_import, prefer_single_quotes, directives_ordering
import 'package:dawasa/core/database/app_database.dart';
import 'package:dawasa/features/accounts/data/account_repository.dart';
import 'package:dawasa/features/transactions/data/transaction_repository.dart';
import 'package:dawasa/features/transactions/domain/transaction_models.dart';
import 'package:dawasa/core/settings/user_settings.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

/// Realistic data as a v1 (first release) installation would contain it.
const _v1Seed = [
  "INSERT INTO accounts (id, created_at, updated_at, name, type, currency_code, opening_balance_minor, opening_date, color_value, icon_key, include_in_total, is_archived, sort_order) VALUES "
      "('acc-cash', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z', 'Cash', 'cash', 'LKR', 500000, '2026-01-01', NULL, NULL, 1, 0, 1), "
      "('acc-bank', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z', 'Bank', 'bank', 'LKR', 2500000, '2026-01-01', NULL, NULL, 1, 0, 2)",
  "INSERT INTO transaction_categories (id, created_at, updated_at, kind, system_key, name, icon_key, color_value, is_archived, sort_order) VALUES "
      "('cat-food', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z', 'expense', 'food', NULL, 'restaurant', 4294079766, 0, 0), "
      "('cat-salary', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z', 'income', 'salary', NULL, 'work', 4279733066, 0, 1), "
      "('cat-custom', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z', 'expense', NULL, 'Tuition', 'school', 4284900966, 0, 2)",
  "INSERT INTO transactions (id, created_at, updated_at, type, amount_minor, currency_code, account_id, to_account_id, category_id, occurred_at, local_date, description, note, attachment_id, recurring_rule_id, source, source_ref_id) VALUES "
      "('tx-1', '2026-02-01T03:00:00.000Z', '2026-02-01T03:00:00.000Z', 'income', 15000000, 'LKR', 'acc-bank', NULL, 'cat-salary', '2026-02-01T03:00:00.000Z', '2026-02-01', 'February salary', NULL, NULL, NULL, 'manual', NULL), "
      "('tx-2', '2026-02-02T06:30:00.000Z', '2026-02-02T06:30:00.000Z', 'expense', 125050, 'LKR', 'acc-cash', NULL, 'cat-food', '2026-02-02T06:30:00.000Z', '2026-02-02', 'Rice & curry', 'lunch', NULL, NULL, 'manual', NULL), "
      "('tx-3', '2026-02-03T04:00:00.000Z', '2026-02-03T04:00:00.000Z', 'transfer', 1000000, 'LKR', 'acc-bank', 'acc-cash', NULL, '2026-02-03T04:00:00.000Z', '2026-02-03', '', NULL, NULL, NULL, 'manual', NULL), "
      "('tx-4', '2026-02-04T04:00:00.000Z', '2026-02-04T04:00:00.000Z', 'expense', 450000, 'LKR', 'acc-bank', NULL, 'cat-custom', '2026-02-04T04:00:00.000Z', '2026-02-04', 'Class fees', NULL, NULL, NULL, 'manual', NULL), "
      "('tx-5', '2026-02-05T04:00:00.000Z', '2026-02-05T04:00:00.000Z', 'adjustmentOut', 5000, 'LKR', 'acc-cash', NULL, NULL, '2026-02-05T04:00:00.000Z', '2026-02-05', '', NULL, NULL, NULL, 'manual', NULL)",
  "INSERT INTO app_settings (key, value, updated_at) VALUES "
      "('currency_code', 'LKR', '2026-01-01T00:00:00.000Z'), "
      "('daily_budget_minor', '150000', '2026-01-01T00:00:00.000Z'), "
      "('user_name', 'Nimal', '2026-01-01T00:00:00.000Z')",
  "INSERT INTO schema_migrations (version, applied_at, description) VALUES (1, '2026-01-01T00:00:00.000Z', 'Initial schema v1')",
];

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('schema migrations', () {
    // Every historical schema must upgrade to every later schema and end up
    // exactly equal to a freshly created database of that version.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('upgrading a v1 database keeps all user data and balances', () async {
    final schema = await verifier.schemaAt(1);
    for (final statement in _v1Seed) {
      schema.rawDatabase.execute(statement);
    }

    final db = AppDatabase(schema.newConnection());
    // Opening the database runs every migration up to the latest version.
    final accounts = AccountRepository(db);
    final balances = {
      for (final b in await accounts.balances()) b.account.id: b.balanceMinor,
    };
    expect(balances['acc-cash'], 500000 - 125050 + 1000000 - 5000);
    expect(balances['acc-bank'], 2500000 + 15000000 - 1000000 - 450000);

    final txs = await TransactionRepository(db)
        .filtered(const TransactionFilter());
    expect(txs.map((t) => t.transaction.id).toSet(), {
      'tx-1',
      'tx-2',
      'tx-3',
      'tx-4',
      'tx-5',
    });
    final food = txs.firstWhere((t) => t.transaction.id == 'tx-2');
    expect(food.transaction.note, 'lunch');
    expect(food.category?.systemKey, 'food');
    expect(
      txs.firstWhere((t) => t.transaction.id == 'tx-4').category?.name,
      'Tuition',
    );

    final settings = await UserSettingsRepository(db).load();
    expect(settings.dailyBudgetMinor, 150000);
    expect(settings.userName, 'Nimal');

    final log = await (db.select(
      db.schemaMigrations,
    )..orderBy([(m) => OrderingTerm.asc(m.version)])).get();
    expect(log.first.version, 1);
    expect(log.last.version, AppDatabase.latestSchemaVersion);

    final fk = await db.customSelect('PRAGMA foreign_key_check').get();
    expect(fk, isEmpty);
    await db.close();
  });
}
