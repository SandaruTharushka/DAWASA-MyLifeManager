import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../../../core/backup/backup_format.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/connection.dart';
import '../../../core/platform/app_info.dart';
import '../../../core/platform/data_paths.dart';
import '../../../core/utils/isolate_runner.dart';

/// A finished, encrypted backup file waiting to be saved or shared.
class BackupFile {
  const BackupFile({
    required this.file,
    required this.fileName,
    required this.sizeBytes,
    required this.attachmentCount,
  });

  final File file;
  final String fileName;
  final int sizeBytes;
  final int attachmentCount;
}

/// What a backup contains, read from its (decrypted, validated) database.
class RestoreSummary {
  const RestoreSummary({
    required this.schemaVersion,
    required this.counts,
    required this.attachmentCount,
  });

  final int schemaVersion;

  /// Row counts keyed by table name (see [BackupService.summaryTables]).
  final Map<String, int> counts;
  final int attachmentCount;

  int count(String table) => counts[table] ?? 0;
}

/// A decrypted and validated backup, staged in private storage and ready to
/// replace the current data.
class PreparedRestore {
  const PreparedRestore({
    required this.header,
    required this.summary,
    required this.stagingPath,
  });

  final BackupHeader header;
  final RestoreSummary summary;
  final String stagingPath;

  File get databaseFile => File(p.join(stagingPath, _stagedDatabaseName));
  Directory get attachmentsDirectory =>
      Directory(p.join(stagingPath, DataPaths.attachmentsFolder));
}

/// Information about the copy of the data kept from before the last restore.
class SafetyCopyInfo {
  const SafetyCopyInfo(this.createdAt);

  final DateTime createdAt;
}

const String _databaseEntry = 'database.sqlite';
const String _manifestEntry = 'manifest.json';
const String _attachmentPrefix = 'attachments/';
const String _stagedDatabaseName = 'restore.sqlite';
const String _safetyInfoName = 'info.json';

final RegExp _safeFileName = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$');

/// Creates encrypted backups and restores them.
///
/// Backups contain a consistent snapshot of the database (`VACUUM INTO`) and
/// the receipt images. They never leave the device unless the user saves or
/// shares the file. Restores are validated completely (authentication,
/// SQLite integrity, schema version) before anything is replaced, and the
/// current data is copied aside first so the restore can be undone.
class BackupService {
  BackupService({
    required this._db,
    required this._paths,
    required this._appVersion,
    DateTime Function()? clock,
    TaskRunner? runner,
    this.memoryKiB = BackupFormat.argonMemoryKiB,
    this.iterations = BackupFormat.argonIterations,
  }) : _clock = clock ?? DateTime.now,
       _run = runner ?? runInIsolate;

  final AppDatabase _db;
  final DataPaths _paths;
  final Future<AppVersion> Function() _appVersion;
  final DateTime Function() _clock;
  final TaskRunner _run;
  final int memoryKiB;
  final int iterations;

  /// Tables whose row counts are shown before restoring.
  static const List<String> summaryTables = [
    'accounts',
    'transactions',
    'budgets',
    'bills',
    'tasks',
    'shopping_lists',
    'savings_goals',
    'loans',
    'habits',
    'personal_events',
  ];

  static String fileNameFor(DateTime local) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'DAWASA-backup-${local.year}-${two(local.month)}-${two(local.day)}'
        '-${two(local.hour)}${two(local.minute)}.${BackupFormat.fileExtension}';
  }

  // ---------------------------------------------------------------- backup

  Future<BackupFile> createBackup(String password) async {
    if (password.length < BackupFormat.minPasswordLength) {
      throw ArgumentError('Password too short');
    }
    final work = await _paths.workDirectory();
    await _cleanWorkDirectory(work);
    final now = _clock();
    final snapshot = File(
      p.join(work.path, 'snapshot-${now.microsecondsSinceEpoch}.sqlite'),
    );
    try {
      await _db.customStatement('VACUUM INTO ?', [snapshot.path]);
      final entries = <BackupEntry>[
        BackupEntry(_databaseEntry, await snapshot.readAsBytes()),
      ];
      final attachments = await _readAttachments();
      entries.addAll(attachments);
      entries.insert(
        0,
        BackupEntry(
          _manifestEntry,
          utf8.encode(
            jsonEncode({
              'schemaVersion': AppDatabase.latestSchemaVersion,
              'attachments': attachments.length,
              'createdAt': now.toUtc().toIso8601String(),
            }),
          ),
        ),
      );
      final version = await _appVersion();
      final memory = memoryKiB;
      final passes = iterations;
      final sealed = await _run(
        () => BackupCrypto.seal(
          entries: entries,
          password: password,
          appVersion: version.versionName,
          appVersionCode: version.versionCode,
          schemaVersion: AppDatabase.latestSchemaVersion,
          createdAt: now.toUtc(),
          memoryKiB: memory,
          iterations: passes,
        ),
      );
      final name = fileNameFor(now);
      final out = File(p.join(work.path, name));
      await out.writeAsBytes(sealed, flush: true);
      return BackupFile(
        file: out,
        fileName: name,
        sizeBytes: sealed.length,
        attachmentCount: attachments.length,
      );
    } finally {
      if (snapshot.existsSync()) await snapshot.delete();
    }
  }

  Future<List<BackupEntry>> _readAttachments() async {
    final rows = await _db.select(_db.attachments).get();
    final dir = await _paths.attachmentsDirectory();
    final result = <BackupEntry>[];
    for (final row in rows) {
      final name = p.basename(row.relativePath);
      if (!_safeFileName.hasMatch(name)) continue;
      final file = File(p.join(dir.path, name));
      if (!file.existsSync()) continue;
      result.add(
        BackupEntry('$_attachmentPrefix$name', await file.readAsBytes()),
      );
    }
    return result;
  }

  /// Removes backup files left over from earlier runs (they are encrypted,
  /// but there is no reason to keep them around).
  Future<void> _cleanWorkDirectory(Directory work) async {
    await for (final entity in work.list()) {
      try {
        await entity.delete(recursive: true);
      } on FileSystemException {
        // Ignore files that are still in use by a share sheet.
      }
    }
  }

  /// Deletes temporary backup files once they were saved or shared.
  Future<void> discardTemporaryFiles() async {
    final work = await _paths.workDirectory();
    await _cleanWorkDirectory(work);
  }

  // --------------------------------------------------------------- restore

  /// Reads the unencrypted header, so the app can show when and with which
  /// version the backup was made before asking for the password.
  BackupHeader inspect(Uint8List file) {
    final header = BackupCrypto.parse(file).header;
    if (header.schemaVersion > AppDatabase.latestSchemaVersion) {
      throw const BackupException(BackupErrorKind.newerSchema);
    }
    return header;
  }

  /// Decrypts [file], validates its database and stages it for [applyRestore].
  /// Nothing in the current data changes.
  Future<PreparedRestore> prepareRestore(
    Uint8List file,
    String password,
  ) async {
    final header = inspect(file);
    final work = await _paths.workDirectory();
    final staging = Directory(
      p.join(work.path, 'restore-${_clock().microsecondsSinceEpoch}'),
    );
    final stagingPath = staging.path;
    try {
      final summary = await _run(
        () => _decryptAndStage(file, password, stagingPath),
      );
      return PreparedRestore(
        header: header,
        summary: summary,
        stagingPath: stagingPath,
      );
    } on Object {
      if (staging.existsSync()) await staging.delete(recursive: true);
      rethrow;
    }
  }

  /// Discards a prepared restore the user decided not to apply.
  Future<void> cancelRestore(PreparedRestore prepared) async {
    final dir = Directory(prepared.stagingPath);
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  /// Replaces the current data with [prepared]. The current data is copied
  /// aside first; if the restored database cannot be opened and migrated,
  /// that copy is put back and the error is rethrown.
  Future<void> applyRestore(
    PreparedRestore prepared,
    AppReloader reload,
  ) async {
    await _takeSafetyCopy();
    final safety = await _paths.safetyDirectory();
    await reload(
      whileClosed: () async {
        try {
          await _swapIn(
            database: prepared.databaseFile,
            attachments: prepared.attachmentsDirectory,
            fallback: File(p.join(safety.path, kDatabaseFileName)),
          );
        } finally {
          await cancelRestore(prepared);
        }
      },
    );
  }

  Future<SafetyCopyInfo?> safetyCopy() async {
    final dir = await _paths.safetyDirectory();
    final db = File(p.join(dir.path, kDatabaseFileName));
    if (!db.existsSync()) return null;
    final info = File(p.join(dir.path, _safetyInfoName));
    DateTime? created;
    if (info.existsSync()) {
      try {
        final json = jsonDecode(await info.readAsString());
        if (json is Map && json['createdAt'] is String) {
          created = DateTime.tryParse(json['createdAt'] as String);
        }
      } on FormatException {
        created = null;
      }
    }
    return SafetyCopyInfo(created ?? db.lastModifiedSync());
  }

  /// Puts back the data that was replaced by the last restore.
  Future<void> restoreSafetyCopy(AppReloader reload) async {
    final dir = await _paths.safetyDirectory();
    final db = File(p.join(dir.path, kDatabaseFileName));
    if (!db.existsSync()) throw StateError('No previous data');
    // Move the copy out of the way first so it cannot be used as its own
    // fallback, then swap it in.
    final work = await _paths.workDirectory();
    final staged = Directory(
      p.join(work.path, 'undo-${_clock().microsecondsSinceEpoch}'),
    );
    await _moveDirectory(dir, staged);
    await reload(
      whileClosed: () async {
        final current = await _paths.databaseFile();
        final keep = File(p.join(staged.path, 'current.sqlite'));
        if (current.existsSync()) await current.copy(keep.path);
        try {
          await _swapIn(
            database: File(p.join(staged.path, kDatabaseFileName)),
            attachments: Directory(
              p.join(staged.path, DataPaths.attachmentsFolder),
            ),
            fallback: keep,
          );
        } finally {
          if (staged.existsSync()) await staged.delete(recursive: true);
        }
      },
    );
  }

  Future<void> deleteSafetyCopy() async {
    final dir = await _paths.safetyDirectory();
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  Future<void> _takeSafetyCopy() async {
    final dir = await _paths.safetyDirectory();
    if (dir.existsSync()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    await _db.customStatement('VACUUM INTO ?', [
      p.join(dir.path, kDatabaseFileName),
    ]);
    final attachments = await _paths.attachmentsDirectory();
    if (attachments.existsSync()) {
      await _copyDirectory(
        attachments,
        Directory(p.join(dir.path, DataPaths.attachmentsFolder)),
      );
    }
    await File(p.join(dir.path, _safetyInfoName)).writeAsString(
      jsonEncode({'createdAt': _clock().toUtc().toIso8601String()}),
      flush: true,
    );
  }

  /// Replaces the database file (and attachments). Runs while the database
  /// is closed.
  Future<void> _swapIn({
    required File database,
    required Directory attachments,
    required File fallback,
  }) async {
    final target = await _paths.databaseFile();
    await target.parent.create(recursive: true);
    await removeDatabaseFiles(target);
    await database.copy(target.path);
    try {
      await _probe(target);
    } on Object {
      await removeDatabaseFiles(target);
      if (fallback.existsSync()) await fallback.copy(target.path);
      rethrow;
    }
    final currentAttachments = await _paths.attachmentsDirectory();
    if (currentAttachments.existsSync()) {
      await currentAttachments.delete(recursive: true);
    }
    if (attachments.existsSync()) {
      await _moveDirectory(attachments, currentAttachments);
    }
  }

  /// Opens the restored file once so that schema migrations run (and are
  /// verified) before the app uses it.
  static Future<void> _probe(File file) async {
    final db = AppDatabase(openDatabaseConnection(file));
    try {
      await db.customSelect('SELECT COUNT(*) AS c FROM accounts').getSingle();
      final problems = await db.customSelect('PRAGMA foreign_key_check').get();
      if (problems.isNotEmpty) {
        throw const BackupException(
          BackupErrorKind.corruptedPayload,
          'foreign key violations',
        );
      }
    } finally {
      await db.close();
    }
  }

  /// Deletes a SQLite database together with its journal files.
  static Future<void> removeDatabaseFiles(File db) async {
    for (final suffix in const ['', '-wal', '-shm', '-journal']) {
      final f = File('${db.path}$suffix');
      if (f.existsSync()) await f.delete();
    }
  }

  static Future<void> _copyDirectory(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final entity in from.list()) {
      if (entity is File) {
        await entity.copy(p.join(to.path, p.basename(entity.path)));
      }
    }
  }

  static Future<void> _moveDirectory(Directory from, Directory to) async {
    if (to.existsSync()) await to.delete(recursive: true);
    await to.parent.create(recursive: true);
    try {
      await from.rename(to.path);
    } on FileSystemException {
      await _copyDirectory(from, to);
      await from.delete(recursive: true);
    }
  }
}

/// Runs in a background isolate: decrypts the backup, writes the database
/// and attachments into [stagingPath] and validates the database.
Future<RestoreSummary> _decryptAndStage(
  Uint8List file,
  String password,
  String stagingPath,
) async {
  final entries = await BackupCrypto.open(file, password);
  final staging = Directory(stagingPath)..createSync(recursive: true);
  final attachmentsDir = Directory(
    p.join(stagingPath, DataPaths.attachmentsFolder),
  )..createSync();
  BackupEntry? database;
  var attachments = 0;
  for (final entry in entries) {
    if (entry.name == _databaseEntry) {
      database = entry;
    } else if (entry.name.startsWith(_attachmentPrefix)) {
      final name = entry.name.substring(_attachmentPrefix.length);
      // Never trust names from a file: no folders, no "..".
      if (!_safeFileName.hasMatch(name) || name.contains('..')) continue;
      File(p.join(attachmentsDir.path, name)).writeAsBytesSync(entry.data);
      attachments++;
    }
  }
  if (database == null) {
    throw const BackupException(BackupErrorKind.missingDatabase);
  }
  final dbFile = File(p.join(staging.path, _stagedDatabaseName))
    ..writeAsBytesSync(database.data, flush: true);
  final counts = <String, int>{};
  final int version;
  final Database sqlite;
  try {
    sqlite = sqlite3.open(dbFile.path, mode: OpenMode.readOnly);
  } on SqliteException catch (e) {
    throw BackupException(BackupErrorKind.corruptedPayload, e.message);
  }
  try {
    final integrity = sqlite.select('PRAGMA integrity_check');
    if (integrity.isEmpty || integrity.first.values.first != 'ok') {
      throw const BackupException(
        BackupErrorKind.corruptedPayload,
        'integrity_check failed',
      );
    }
    version = sqlite.userVersion;
    if (version > AppDatabase.latestSchemaVersion) {
      throw const BackupException(BackupErrorKind.newerSchema);
    }
    if (version < 1) {
      throw const BackupException(
        BackupErrorKind.corruptedPayload,
        'not a DAWASA database',
      );
    }
    final tables = {
      for (final row in sqlite.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ))
        row['name'] as String,
    };
    for (final required in const [
      'accounts',
      'transactions',
      'transaction_categories',
      'app_settings',
    ]) {
      if (!tables.contains(required)) {
        throw BackupException(
          BackupErrorKind.corruptedPayload,
          'missing table $required',
        );
      }
    }
    for (final table in BackupService.summaryTables) {
      if (!tables.contains(table)) continue;
      counts[table] =
          sqlite.select('SELECT COUNT(*) AS c FROM "$table"').first['c'] as int;
    }
  } on SqliteException catch (e) {
    throw BackupException(BackupErrorKind.corruptedPayload, e.message);
  } finally {
    sqlite.close();
  }
  return RestoreSummary(
    schemaVersion: version,
    counts: counts,
    attachmentCount: attachments,
  );
}
