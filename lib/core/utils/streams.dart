import 'dart:async';

import 'package:drift/drift.dart';

/// Emits [compute]'s result immediately and again whenever one of [tables]
/// changes. Used for aggregates that span several queries.
Stream<T> watchComputed<T>(
  DatabaseConnectionUser db,
  List<TableInfo<Table, Object?>> tables,
  Future<T> Function() compute,
) async* {
  yield await compute();
  await for (final _ in db.tableUpdates(TableUpdateQuery.onAllTables(tables))) {
    yield await compute();
  }
}
