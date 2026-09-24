import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/connection.dart';

/// Locations of the app's private files. Everything lives inside the app's
/// own sandbox; tests point these at temporary folders.
class DataPaths {
  const DataPaths({required this.dataDirectory, required this.tempDirectory});

  /// Private directory holding the database and attachments.
  final Future<Directory> Function() dataDirectory;

  /// Cache directory for backup files that are about to be saved or shared.
  final Future<Directory> Function() tempDirectory;

  static const String attachmentsFolder = 'attachments';
  static const String safetyFolder = 'restore_safety';
  static const String workFolder = 'dawasa_backup';

  Future<File> databaseFile() async =>
      File(p.join((await dataDirectory()).path, kDatabaseFileName));

  Future<Directory> attachmentsDirectory() async =>
      Directory(p.join((await dataDirectory()).path, attachmentsFolder));

  /// Copy of the data taken just before a restore replaced it.
  Future<Directory> safetyDirectory() async =>
      Directory(p.join((await dataDirectory()).path, safetyFolder));

  /// Scratch space for creating and staging backups.
  Future<Directory> workDirectory() async {
    final dir = Directory(p.join((await tempDirectory()).path, workFolder));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }
}

final dataPathsProvider = Provider<DataPaths>(
  (ref) => const DataPaths(
    dataDirectory: appDataDirectory,
    tempDirectory: getTemporaryDirectory,
  ),
);

/// Closes the database, optionally runs `whileClosed` (for example to
/// replace the database file during a restore) and opens everything again
/// in a fresh provider scope.
typedef AppReloader = Future<void> Function({
  Future<void> Function()? whileClosed,
});

final appReloaderProvider = Provider<AppReloader>(
  (ref) =>
      ({whileClosed}) async => whileClosed?.call(),
);
