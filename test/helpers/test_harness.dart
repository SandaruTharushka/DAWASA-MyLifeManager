import 'dart:async';
import 'dart:io';

import 'package:dawasa/app/app_root.dart';
import 'package:dawasa/core/database/app_database.dart';
import 'package:dawasa/core/database/connection.dart';
import 'package:dawasa/core/notifications/notification_service.dart';
import 'package:dawasa/core/platform/data_paths.dart';
import 'package:dawasa/core/platform/platform_bridge.dart';
import 'package:dawasa/core/security/biometrics.dart';
import 'package:dawasa/core/security/pin_hasher.dart';
import 'package:dawasa/core/security/secure_store.dart';
import 'package:dawasa/core/time/local_date.dart';
import 'package:dawasa/core/utils/isolate_runner.dart';
import 'package:dawasa/features/accounts/data/account_repository.dart';
import 'package:dawasa/features/security/app_lock.dart';
import 'package:dawasa/features/transactions/data/category_repository.dart';
import 'package:dawasa/features/transactions/data/transaction_repository.dart';
import 'package:dawasa/features/transactions/domain/transaction_models.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Fresh in-memory database with default seed data.
AppDatabase newTestDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(openInMemoryConnection());
}

/// Repositories bundle for data-layer tests.
class TestData {
  TestData(this.db)
    : accounts = AccountRepository(db),
      transactions = TransactionRepository(db),
      categories = CategoryRepository(db);

  final AppDatabase db;
  final AccountRepository accounts;
  final TransactionRepository transactions;
  final CategoryRepository categories;

  Future<String> account({
    String name = 'Cash',
    AccountType type = AccountType.cash,
    int opening = 0,
    String currency = 'LKR',
  }) => accounts.create(
    name: name,
    type: type,
    currencyCode: currency,
    openingBalanceMinor: opening,
  );

  Future<String> categoryId(CategoryKind kind, String key) async =>
      (await categories.bySystemKey(kind, key))!.id;

  Future<String> expense(
    String accountId,
    int amount, {
    LocalDate? date,
    String category = 'food',
    String description = '',
  }) async {
    final id = newId();
    await transactions.create(
      TransactionDraft(
        id: id,
        type: TransactionType.expense,
        amountMinor: amount,
        currencyCode: 'LKR',
        accountId: accountId,
        categoryId: await categoryId(CategoryKind.expense, category),
        occurredAt: (date ?? LocalDate(2026, 3, 15)).atMinutes(12 * 60),
        description: description,
      ),
    );
    return id;
  }

  Future<String> income(
    String accountId,
    int amount, {
    LocalDate? date,
    String category = 'salary',
  }) async {
    final id = newId();
    await transactions.create(
      TransactionDraft(
        id: id,
        type: TransactionType.income,
        amountMinor: amount,
        currencyCode: 'LKR',
        accountId: accountId,
        categoryId: await categoryId(CategoryKind.income, category),
        occurredAt: (date ?? LocalDate(2026, 3, 15)).atMinutes(9 * 60),
      ),
    );
    return id;
  }

  Future<String> transfer(
    String from,
    String to,
    int amount, {
    LocalDate? date,
  }) async {
    final id = newId();
    await transactions.create(
      TransactionDraft(
        id: id,
        type: TransactionType.transfer,
        amountMinor: amount,
        currencyCode: 'LKR',
        accountId: from,
        toAccountId: to,
        occurredAt: (date ?? LocalDate(2026, 3, 15)).atMinutes(10 * 60),
      ),
    );
    return id;
  }
}

/// Records calls instead of talking to Android.
class FakePlatformBridge extends PlatformBridge {
  final List<bool> screenProtection = [];

  @override
  Future<void> setScreenProtection(bool enabled) async =>
      screenProtection.add(enabled);
}

/// Platform services replaced by in-memory doubles in widget tests.
class TestPlatform {
  TestPlatform({
    MemorySecureStore? secureStore,
    FakeBiometricAuthenticator? biometrics,
  }) : secureStore = secureStore ?? MemorySecureStore(),
       biometrics = biometrics ?? FakeBiometricAuthenticator(),
       root = Directory.systemTemp.createTempSync('dawasa_widget_test');

  final MemorySecureStore secureStore;
  final FakeBiometricAuthenticator biometrics;
  final FakePlatformBridge bridge = FakePlatformBridge();

  /// Private "app storage" for this test.
  final Directory root;

  late final DataPaths paths = DataPaths(
    dataDirectory: () async =>
        Directory(p.join(root.path, 'data'))..createSync(recursive: true),
    tempDirectory: () async =>
        Directory(p.join(root.path, 'cache'))..createSync(recursive: true),
  );

  /// Cheap PIN hashing that runs inline (no isolates under fake time).
  static const pinHasher = PinHasher(
    memoryKiB: 64,
    iterations: 1,
    runner: runInline,
  );

  List<Override> get overrides => [
    secureStoreProvider.overrideWithValue(secureStore),
    biometricAuthenticatorProvider.overrideWithValue(biometrics),
    pinHasherProvider.overrideWithValue(pinHasher),
    platformBridgeProvider.overrideWithValue(bridge),
    dataPathsProvider.overrideWithValue(paths),
  ];

  void dispose() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  }
}

/// Pumps the complete app with an in-memory database.
///
/// When [reopenDatabase] is given, every reload of the app (restore,
/// delete all) opens the database it returns; otherwise the same
/// [database] is used throughout.
Future<AppDatabase> pumpDawasaApp(
  WidgetTester tester, {
  Map<String, Object> preferences = const {},
  AppDatabase? database,
  NotificationGateway? notifications,
  TestPlatform? platform,
  Future<AppDatabase> Function()? reopenDatabase,
}) async {
  await initializeDateFormatting();
  SharedPreferences.setMockInitialValues(preferences);
  final prefs = await SharedPreferences.getInstance();
  final db = database ?? newTestDatabase();
  final testPlatform = platform ?? TestPlatform();
  addTearDown(testPlatform.dispose);
  var first = true;
  await tester.pumpWidget(
    AppRoot(
      preferences: prefs,
      notificationGateway: notifications ?? NoopNotificationGateway(),
      openDatabase: () async {
        if (first || reopenDatabase == null) {
          first = false;
          return db;
        }
        return reopenDatabase();
      },
      overrides: testPlatform.overrides,
    ),
  );
  await settle(tester);
  return db;
}

/// Pumps frames until drift streams and animations have settled.
///
/// Drift schedules zero-duration timers, which only fire when fake time
/// advances, so we pump in small steps before settling.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 10),
  );
}

/// Runs a database operation inside a widget test by advancing fake time
/// until it completes (never use `runAsync` with drift: it deadlocks).
Future<T> runDb<T>(WidgetTester tester, Future<T> Function() body) async {
  var done = false;
  late T result;
  Object? error;
  StackTrace? stack;
  unawaited(
    body().then(
      (value) {
        result = value;
        done = true;
      },
      onError: (Object e, StackTrace s) {
        error = e;
        stack = s;
        done = true;
      },
    ),
  );
  for (var i = 0; i < 500 && !done; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  if (error != null) Error.throwWithStackTrace(error!, stack!);
  if (!done) throw StateError('Database operation did not complete');
  return result;
}

/// Preferences for an already onboarded user.
const Map<String, Object> onboardedPrefs = {
  'pref.onboardingComplete': true,
  'pref.language': 'en',
};

/// Unmounts the app and closes the database so no timers leak.
Future<void> disposeApp(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await runDb(tester, db.close);
  await tester.pump(const Duration(seconds: 1));
}
