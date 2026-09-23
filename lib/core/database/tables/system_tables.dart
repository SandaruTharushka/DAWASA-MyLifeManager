import 'package:drift/drift.dart';

import 'common.dart';

/// Key/value settings that belong to the user's data and are therefore
/// included in backups (e.g. default currency, daily budget).
@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().clientDefault(nowUtc)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Audit log of applied schema migrations. Drift itself tracks the current
/// version with `PRAGMA user_version`; this table keeps the history.
@DataClassName('SchemaMigrationRow')
class SchemaMigrations extends Table {
  IntColumn get version => integer()();
  DateTimeColumn get appliedAt => dateTime().clientDefault(nowUtc)();
  TextColumn get description => text()();

  @override
  Set<Column<Object>> get primaryKey => {version};
}
