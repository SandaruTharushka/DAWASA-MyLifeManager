// ignore_for_file: prefer_single_quotes
import 'dart:convert';
import 'dart:io';

import 'package:dawasa/core/backup/backup_format.dart';
import 'package:dawasa/core/database/app_database.dart';
import 'package:dawasa/core/database/connection.dart';
import 'package:dawasa/core/platform/app_info.dart';
import 'package:dawasa/core/platform/data_paths.dart';
import 'package:dawasa/features/backup/data/backup_service.dart';
import 'package:dawasa/features/transactions/data/attachment_store.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../drift/dawasa/generated/schema.dart';
import '../helpers/test_harness.dart';

// Cheap KDF settings so tests run quickly; the production defaults are
// covered by `BackupFormat` constants.
const _memory = 1024;
const _passes = 1;
const _password = 'correct horse battery';

Future<AppVersion> _version() async =>
    const AppVersion(versionName: '1.0.0', versionCode: 1, packageName: 'x');

Matcher _backupError(BackupErrorKind kind) =>
    isA<BackupException>().having((e) => e.kind, 'kind', kind);

/// A database stored in a real file, reopened by [reload] like the app does.
class _FileApp {
  _FileApp(this.root)
    : paths = DataPaths(
        dataDirectory: () async =>
            Directory(p.join(root.path, 'data'))..createSync(recursive: true),
        tempDirectory: () async =>
            Directory(p.join(root.path, 'cache'))..createSync(recursive: true),
      );

  final Directory root;
  final DataPaths paths;
  late AppDatabase db;

  Future<void> open() async {
    db = AppDatabase(openDatabaseConnection(await paths.databaseFile()));
  }

  Future<void> reload({Future<void> Function()? whileClosed}) async {
    await db.close();
    try {
      await whileClosed?.call();
    } finally {
      await open();
    }
  }

  BackupService service() => BackupService(
    db: db,
    paths: paths,
    appVersion: _version,
    memoryKiB: _memory,
    iterations: _passes,
  );

  TestData get data => TestData(db);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('backup container', () {
    Future<Uint8List> seal([List<BackupEntry>? entries, int schema = 3]) =>
        BackupCrypto.seal(
          entries:
              entries ??
              [
                BackupEntry('a.txt', Uint8List.fromList(utf8.encode('hello'))),
                BackupEntry('empty', Uint8List(0)),
              ],
          password: _password,
          appVersion: '1.0.0',
          appVersionCode: 1,
          schemaVersion: schema,
          memoryKiB: _memory,
          iterations: _passes,
        );

    test('round trip keeps every entry', () async {
      final file = await seal();
      final entries = await BackupCrypto.open(file, _password);
      expect(entries.map((e) => e.name), ['a.txt', 'empty']);
      expect(utf8.decode(entries.first.data), 'hello');
      expect(entries.last.data, isEmpty);
    });

    test('header is readable without password but holds no secrets', () async {
      final file = await seal();
      final parsed = BackupCrypto.parse(file);
      expect(parsed.header.schemaVersion, 3);
      expect(parsed.header.salt, hasLength(16));
      expect(parsed.header.nonce, hasLength(12));
      final headerText = utf8.decode(parsed.aad.sublist(14));
      expect(headerText, isNot(contains(_password)));
      expect(headerText, contains('argon2id'));
      // The payload is not readable as plain text.
      expect(latin1.decode(file), isNot(contains('hello')));
    });

    test('two backups of the same data use different salt and nonce', () async {
      final a = BackupCrypto.parse(await seal()).header;
      final b = BackupCrypto.parse(await seal()).header;
      expect(a.salt, isNot(b.salt));
      expect(a.nonce, isNot(b.nonce));
    });

    test('wrong password is rejected', () async {
      final file = await seal();
      await expectLater(
        BackupCrypto.open(file, 'wrong password!'),
        throwsA(_backupError(BackupErrorKind.wrongPasswordOrCorrupted)),
      );
    });

    test('any modified byte is detected', () async {
      final file = await seal();
      final headerEnd = BackupCrypto.parse(file).aad.length;
      // A byte of the ciphertext, the tag, and the authenticated header's
      // app version string.
      final headerText = utf8.decode(file.sublist(14, headerEnd));
      final versionAt = 14 + headerText.indexOf('1.0.0');
      for (final index in [headerEnd + 1, file.length - 1, versionAt]) {
        final copy = Uint8List.fromList(file);
        copy[index] ^= index == versionAt ? 0x01 : 0xFF;
        await expectLater(
          BackupCrypto.open(copy, _password),
          throwsA(_backupError(BackupErrorKind.wrongPasswordOrCorrupted)),
          reason: 'byte $index',
        );
      }
    });

    test('truncated and foreign files are rejected', () async {
      final file = await seal();
      expect(
        () => BackupCrypto.parse(Uint8List.sublistView(file, 0, 40)),
        throwsA(_backupError(BackupErrorKind.notABackup)),
      );
      expect(
        () => BackupCrypto.parse(Uint8List.fromList(utf8.encode('x' * 100))),
        throwsA(_backupError(BackupErrorKind.notABackup)),
      );
      await expectLater(
        BackupCrypto.open(
          Uint8List.sublistView(file, 0, file.length - 5),
          _password,
        ),
        throwsA(_backupError(BackupErrorKind.wrongPasswordOrCorrupted)),
      );
    });

    test('unsafe KDF parameters in a crafted header are refused', () {
      final header = BackupHeader(
        appVersion: '1',
        appVersionCode: 1,
        schemaVersion: 1,
        createdAt: DateTime.utc(2026),
        salt: List.filled(16, 1),
        nonce: List.filled(12, 1),
        memoryKiB: BackupFormat.maxArgonMemoryKiB * 4,
      );
      expect(
        () => BackupHeader.fromJson(header.toJson()),
        throwsA(_backupError(BackupErrorKind.unsupportedFormat)),
      );
    });

    test('archive rejects truncated data', () {
      final packed = BackupArchive.pack([
        BackupEntry('x', Uint8List.fromList([1, 2, 3])),
      ]);
      expect(BackupArchive.unpack(packed).single.data, [1, 2, 3]);
      expect(
        () => BackupArchive.unpack(Uint8List.sublistView(packed, 0, 12)),
        throwsA(_backupError(BackupErrorKind.corruptedPayload)),
      );
    });
  });

  group('backup service', () {
    late Directory root;
    late _FileApp app;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('dawasa_backup_test');
      app = _FileApp(root);
      await app.open();
    });

    tearDown(() async {
      await app.db.close();
      await root.delete(recursive: true);
    });

    Future<String> addReceipt() async {
      final source = File(p.join(root.path, 'receipt.jpg'))
        ..writeAsBytesSync(List.generate(2048, (i) => i % 251));
      final store = AttachmentStore(app.db, app.paths.dataDirectory);
      return store.importImage(source);
    }

    test('backup and restore bring back exactly the backed-up data', () async {
      final cash = await app.data.account(opening: 500000);
      await app.data.expense(cash, 125050, description: 'Rice & curry');
      final receipt = await addReceipt();

      final backup = await app.service().createBackup(_password);
      expect(backup.fileName, endsWith('.dawasa'));
      expect(backup.attachmentCount, 1);
      final bytes = await backup.file.readAsBytes();
      // The snapshot used to build the backup is gone.
      final leftovers = (await app.paths.workDirectory()).listSync().map(
        (e) => p.basename(e.path),
      );
      expect(leftovers, [backup.fileName]);

      // Change the data after the backup.
      final bank = await app.data.account(name: 'Bank');
      await app.data.income(bank, 9000000);
      final receiptFile = File(
        p.join((await app.paths.attachmentsDirectory()).path, '$receipt.jpg'),
      );
      await receiptFile.delete();

      final service = app.service();
      final prepared = await service.prepareRestore(bytes, _password);
      expect(prepared.summary.schemaVersion, AppDatabase.latestSchemaVersion);
      expect(prepared.summary.count('accounts'), 1);
      expect(prepared.summary.count('transactions'), 1);
      expect(prepared.summary.attachmentCount, 1);
      // Preparing does not touch the current data.
      expect(await app.db.select(app.db.accounts).get(), hasLength(2));

      await service.applyRestore(prepared, app.reload);

      final accounts = await app.db.select(app.db.accounts).get();
      expect(accounts.map((a) => a.name), ['Cash']);
      final tx = await app.db.select(app.db.transactions).get();
      expect(tx.single.amountMinor, 125050);
      expect(tx.single.description, 'Rice & curry');
      expect(receiptFile.existsSync(), isTrue);
      expect(receiptFile.lengthSync(), 2048);
      expect(Directory(prepared.stagingPath).existsSync(), isFalse);

      // The replaced data was kept and can be brought back.
      final undo = app.service();
      expect(await undo.safetyCopy(), isNotNull);
      await undo.restoreSafetyCopy(app.reload);
      final back = await app.db.select(app.db.accounts).get();
      expect(back.map((a) => a.name).toSet(), {'Cash', 'Bank'});
      expect(receiptFile.existsSync(), isFalse);
      expect(await app.service().safetyCopy(), isNull);
    });

    test('a wrong password changes nothing', () async {
      final cash = await app.data.account();
      await app.data.expense(cash, 1000);
      final backup = await app.service().createBackup(_password);
      final bytes = await backup.file.readAsBytes();
      await app.data.expense(cash, 2000);

      await expectLater(
        app.service().prepareRestore(bytes, 'not the password'),
        throwsA(_backupError(BackupErrorKind.wrongPasswordOrCorrupted)),
      );
      expect(await app.db.select(app.db.transactions).get(), hasLength(2));
      final staging = (await app.paths.workDirectory()).listSync().where(
        (e) => p.basename(e.path).startsWith('restore-'),
      );
      expect(staging, isEmpty);
    });

    test('production key derivation settings work end to end', () async {
      final cash = await app.data.account(opening: 777700);
      await app.data.expense(cash, 12300);
      final service = BackupService(
        db: app.db,
        paths: app.paths,
        appVersion: _version,
      );
      final backup = await service.createBackup(_password);
      final bytes = await backup.file.readAsBytes();
      final header = service.inspect(bytes);
      expect(header.memoryKiB, BackupFormat.argonMemoryKiB);
      expect(header.iterations, BackupFormat.argonIterations);
      final prepared = await service.prepareRestore(bytes, _password);
      expect(prepared.summary.count('transactions'), 1);
      await service.cancelRestore(prepared);
    });

    test('short passwords are refused', () async {
      expect(
        () => app.service().createBackup('short'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'backups from a newer app version are refused before decrypting',
      () async {
        final file = await BackupCrypto.seal(
          entries: const [],
          password: _password,
          appVersion: '9.0.0',
          appVersionCode: 90,
          schemaVersion: AppDatabase.latestSchemaVersion + 1,
          memoryKiB: _memory,
          iterations: _passes,
        );
        expect(
          () => app.service().inspect(file),
          throwsA(_backupError(BackupErrorKind.newerSchema)),
        );
      },
    );

    test('a backup without a database is refused', () async {
      final file = await BackupCrypto.seal(
        entries: [BackupEntry('manifest.json', Uint8List(2))],
        password: _password,
        appVersion: '1.0.0',
        appVersionCode: 1,
        schemaVersion: 3,
        memoryKiB: _memory,
        iterations: _passes,
      );
      await expectLater(
        app.service().prepareRestore(file, _password),
        throwsA(_backupError(BackupErrorKind.missingDatabase)),
      );
    });

    test('a corrupted database inside a valid container is refused', () async {
      final file = await BackupCrypto.seal(
        entries: [
          BackupEntry(
            'database.sqlite',
            Uint8List.fromList(utf8.encode('SQLite format 3\u0000garbage')),
          ),
        ],
        password: _password,
        appVersion: '1.0.0',
        appVersionCode: 1,
        schemaVersion: 3,
        memoryKiB: _memory,
        iterations: _passes,
      );
      await expectLater(
        app.service().prepareRestore(file, _password),
        throwsA(_backupError(BackupErrorKind.corruptedPayload)),
      );
    });

    test('attachment names cannot escape the attachments folder', () async {
      final snapshot = File(p.join(root.path, 'snap.sqlite'));
      await app.db.customStatement('VACUUM INTO ?', [snapshot.path]);
      final file = await BackupCrypto.seal(
        entries: [
          BackupEntry('database.sqlite', await snapshot.readAsBytes()),
          BackupEntry('attachments/../../evil.txt', Uint8List(3)),
          BackupEntry('attachments/ok.jpg', Uint8List(3)),
        ],
        password: _password,
        appVersion: '1.0.0',
        appVersionCode: 1,
        schemaVersion: 3,
        memoryKiB: _memory,
        iterations: _passes,
      );
      final prepared = await app.service().prepareRestore(file, _password);
      expect(prepared.summary.attachmentCount, 1);
      final written = prepared.attachmentsDirectory.listSync().map(
        (e) => p.basename(e.path),
      );
      expect(written, ['ok.jpg']);
      expect(
        root
            .listSync(recursive: true)
            .where((e) => e.path.endsWith('evil.txt')),
        isEmpty,
      );
    });

    test('a backup made with the first schema is migrated on restore', () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final v1 = await verifier.schemaAt(1);
      v1.rawDatabase
        ..execute(
          "INSERT INTO accounts (id, created_at, updated_at, name, type, "
          "currency_code, opening_balance_minor, opening_date, color_value, "
          "icon_key, include_in_total, is_archived, sort_order) VALUES "
          "('acc-old', '2026-01-01T00:00:00.000Z', "
          "'2026-01-01T00:00:00.000Z', 'Old wallet', 'cash', 'LKR', 250000, "
          "'2026-01-01', NULL, NULL, 1, 0, 1)",
        )
        ..execute(
          "INSERT INTO transactions (id, created_at, updated_at, type, "
          "amount_minor, currency_code, account_id, to_account_id, "
          "category_id, occurred_at, local_date, description, note, "
          "attachment_id, recurring_rule_id, source, source_ref_id) VALUES "
          "('tx-old', '2026-02-02T06:30:00.000Z', '2026-02-02T06:30:00.000Z', "
          "'expense', 125050, 'LKR', 'acc-old', NULL, NULL, "
          "'2026-02-02T06:30:00.000Z', '2026-02-02', 'Tea', NULL, NULL, NULL, "
          "'manual', NULL)",
        )
        ..execute('PRAGMA user_version = 1');
      final v1File = File(p.join(root.path, 'v1.sqlite'));
      v1.rawDatabase.execute("VACUUM INTO '${v1File.path}'");
      v1.rawDatabase.close();

      final file = await BackupCrypto.seal(
        entries: [BackupEntry('database.sqlite', await v1File.readAsBytes())],
        password: _password,
        appVersion: '1.0.0',
        appVersionCode: 1,
        schemaVersion: 1,
        memoryKiB: _memory,
        iterations: _passes,
      );
      final service = app.service();
      final prepared = await service.prepareRestore(file, _password);
      expect(prepared.summary.schemaVersion, 1);
      expect(prepared.summary.count('accounts'), 1);
      // Tables added later are simply not counted.
      expect(prepared.summary.counts.containsKey('tasks'), isFalse);

      await service.applyRestore(prepared, app.reload);
      final tx = await app.db.select(app.db.transactions).getSingle();
      expect(tx.description, 'Tea');
      expect(tx.amountMinor, 125050);
      // Newer tables exist and work after the migration.
      expect(await app.db.select(app.db.tasks).get(), isEmpty);
      final version = await app.db
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data.values.single, AppDatabase.latestSchemaVersion);
    });
  });
}
