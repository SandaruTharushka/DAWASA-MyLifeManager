import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// New random (v4) UUID used as a primary key.
String newId() => _uuid.v4();

/// Deterministic (v5) UUID. Used for generated records (e.g. recurring
/// occurrences) so that generating the same occurrence twice produces the
/// same primary key and therefore can never create a duplicate row.
String deterministicId(String name) =>
    _uuid.v5(Namespace.url.value, 'dawasa:$name');

DateTime nowUtc() => DateTime.now().toUtc();

mixin UuidPrimaryKey on Table {
  TextColumn get id => text().clientDefault(newId)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

mixin Timestamps on Table {
  DateTimeColumn get createdAt => dateTime().clientDefault(nowUtc)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(nowUtc)();
}
