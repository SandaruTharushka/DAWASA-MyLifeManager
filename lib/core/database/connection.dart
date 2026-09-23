import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

const String kDatabaseFileName = 'dawasa.sqlite';

/// Private, app-only directory holding the database and attachments.
Future<Directory> appDataDirectory() async {
  final dir = await getApplicationSupportDirectory();
  if (!dir.existsSync()) await dir.create(recursive: true);
  return dir;
}

Future<File> databaseFile() async =>
    File(p.join((await appDataDirectory()).path, kDatabaseFileName));

void _configure(Database database) {
  database
    ..execute('PRAGMA foreign_keys = ON;')
    ..execute('PRAGMA journal_mode = WAL;')
    ..execute('PRAGMA synchronous = NORMAL;');
}

/// Opens the on-device database in a background isolate so that queries
/// never block the UI thread.
QueryExecutor openDatabaseConnection(File file) {
  return NativeDatabase.createInBackground(file, setup: _configure);
}

/// In-memory database for tests.
QueryExecutor openInMemoryConnection() =>
    NativeDatabase.memory(setup: _configure);
