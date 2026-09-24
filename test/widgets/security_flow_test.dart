import 'dart:io';

import 'package:dawasa/core/database/app_database.dart';
import 'package:dawasa/features/security/app_lock.dart';
import 'package:dawasa/ui/widgets/common.dart';
import 'package:dawasa/ui/widgets/form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_harness.dart';
import 'app_flow_test.dart' show usePhoneScreen;

Future<void> enterPin(
  WidgetTester tester,
  String pin, {
  bool ok = false,
}) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(ValueKey('pin-key-$digit')));
    await tester.pump();
  }
  if (ok) await tester.tap(find.byKey(const ValueKey('pin-key-ok')));
  await settle(tester);
}

Future<void> saveTestPin(
  WidgetTester tester,
  TestPlatform platform,
  String pin, {
  bool biometric = false,
}) async {
  final hash = await runDb(tester, () => TestPlatform.pinHasher.hash(pin));
  platform.secureStore.values
    ..[AppLockController.kPin] = hash.encode()
    ..[AppLockController.kPinLength] = '${pin.length}';
  if (biometric) {
    platform.secureStore.values[AppLockController.kBiometric] = 'true';
  }
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Settings'));
  await settle(tester);
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find
        .descendant(
          of: find.byType(PageBody),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(finder);
  await tester.pump();
}

Future<void> sendToBackgroundAndBack(WidgetTester tester) async {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }
  await settle(tester);
}

void main() {
  testWidgets('a locked app shows nothing until the right PIN is entered', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final platform = TestPlatform();
    await saveTestPin(tester, platform, '2580');
    final db = newTestDatabase();
    await runDb(tester, () => TestData(db).account(opening: 123400));
    await pumpDawasaApp(
      tester,
      preferences: onboardedPrefs,
      database: db,
      platform: platform,
    );

    expect(find.text('DAWASA is locked'), findsOneWidget);
    expect(find.text('Available balance'), findsNothing);
    expect(find.text('Rs 1,234.00'), findsNothing);

    await enterPin(tester, '1357');
    expect(
      find.text('Wrong PIN. 4 attempts left before a pause.'),
      findsOneWidget,
    );
    expect(find.text('Available balance'), findsNothing);

    await enterPin(tester, '2580');
    expect(find.text('DAWASA is locked'), findsNothing);
    expect(find.text('Available balance'), findsOneWidget);

    // "Lock after: immediately" is the default.
    await sendToBackgroundAndBack(tester);
    expect(find.text('DAWASA is locked'), findsOneWidget);
    await enterPin(tester, '2580');
    expect(find.text('Available balance'), findsOneWidget);

    await disposeApp(tester, db);
  });

  testWidgets('fingerprint unlock is offered as soon as the app opens', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final platform = TestPlatform()..biometrics.available = true;
    await saveTestPin(tester, platform, '2580', biometric: true);
    final db = await pumpDawasaApp(
      tester,
      preferences: onboardedPrefs,
      platform: platform,
    );

    expect(platform.biometrics.prompts, 1);
    expect(find.text('DAWASA is locked'), findsNothing);
    expect(find.text('Available balance'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('setting a PIN in Settings turns on the lock', (tester) async {
    usePhoneScreen(tester);
    final platform = TestPlatform();
    final db = await pumpDawasaApp(
      tester,
      preferences: onboardedPrefs,
      platform: platform,
    );
    await openSettings(tester);
    await scrollTo(tester, find.byKey(const ValueKey('settings-pin-lock')));
    await tester.tap(find.byKey(const ValueKey('settings-pin-lock')));
    await settle(tester);
    expect(find.text('Create a PIN'), findsOneWidget);

    // Obvious PINs are refused.
    await enterPin(tester, '1111', ok: true);
    expect(
      find.text(
        'That PIN is too easy to guess. Avoid repeated or consecutive digits.',
      ),
      findsOneWidget,
    );

    // A mismatch starts again.
    await enterPin(tester, '2580', ok: true);
    expect(find.text('Enter the PIN again'), findsOneWidget);
    await enterPin(tester, '2581');
    expect(find.text('PINs do not match. Try again.'), findsOneWidget);
    expect(find.text('Create a PIN'), findsOneWidget);

    await enterPin(tester, '2580', ok: true);
    await enterPin(tester, '2580');
    expect(find.text('PIN lock enabled'), findsOneWidget);
    expect(find.text('Change PIN'), findsOneWidget);
    final stored = platform.secureStore.values[AppLockController.kPin]!;
    expect(stored, isNot(contains('2580')));

    // Screen protection is sent to Android.
    await scrollTo(tester, find.text('Protect screen contents'));
    await tester.tap(find.text('Protect screen contents'));
    await settle(tester);
    expect(platform.bridge.screenProtection, [false, true]);

    await sendToBackgroundAndBack(tester);
    expect(find.text('DAWASA is locked'), findsOneWidget);
    await enterPin(tester, '2580');
    expect(find.text('DAWASA is locked'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('removing the PIN needs the current PIN', (tester) async {
    usePhoneScreen(tester);
    final platform = TestPlatform();
    await saveTestPin(tester, platform, '2580');
    final db = await pumpDawasaApp(
      tester,
      preferences: onboardedPrefs,
      platform: platform,
    );
    await enterPin(tester, '2580');
    await openSettings(tester);
    await scrollTo(tester, find.byKey(const ValueKey('settings-pin-lock')));
    await tester.tap(find.byKey(const ValueKey('settings-pin-lock')));
    await settle(tester);
    expect(find.text('Enter your current PIN'), findsOneWidget);
    await enterPin(tester, '9753');
    expect(
      find.text('Wrong PIN. 4 attempts left before a pause.'),
      findsOneWidget,
    );
    expect(
      platform.secureStore.values.containsKey(AppLockController.kPin),
      isTrue,
    );
    await enterPin(tester, '2580');
    expect(find.text('PIN lock removed'), findsOneWidget);
    expect(platform.secureStore.values, isEmpty);
    expect(find.text('Change PIN'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('backup passwords are checked before encrypting', (tester) async {
    usePhoneScreen(tester);
    final db = await pumpDawasaApp(tester, preferences: onboardedPrefs);
    await openSettings(tester);
    await scrollTo(tester, find.text('Create backup'));
    expect(find.text('No backup made yet'), findsOneWidget);
    await tester.tap(find.text('Create backup'));
    await settle(tester);

    final create = find.descendant(
      of: find.byType(SubmitButton),
      matching: find.text('Create backup'),
    );
    await tester.enterText(
      find.byKey(const ValueKey('backup-password')),
      'short',
    );
    await tester.tap(create);
    await settle(tester);
    expect(find.text('Use at least 8 characters'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('backup-password')),
      'long enough password',
    );
    await tester.enterText(
      find.byKey(const ValueKey('backup-password-confirm')),
      'something else',
    );
    await tester.tap(create);
    await settle(tester);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(find.text('Encrypting your data…'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('a backup can be restored instead of the welcome guide', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final db = await pumpDawasaApp(tester);
    expect(find.text('Welcome to DAWASA'), findsOneWidget);
    await tester.tap(find.text('Restore from a backup'));
    await settle(tester);
    expect(find.text('Choose backup file'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    expect(find.text('Welcome to DAWASA'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('delete all data erases everything and restarts the guide', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final platform = TestPlatform();
    platform.secureStore.values['something'] = 'secret';
    final dataDir = await runDb(tester, platform.paths.dataDirectory);
    final dbFile = File(p.join(dataDir.path, 'dawasa.sqlite'))
      ..writeAsStringSync('old database');
    final photo = File(p.join(dataDir.path, 'attachments', 'r.jpg'))
      ..createSync(recursive: true);
    late AppDatabase fresh;
    final db = await pumpDawasaApp(
      tester,
      preferences: {...onboardedPrefs, 'pref.hideBalancesOnStart': true},
      platform: platform,
      reopenDatabase: () async => fresh = newTestDatabase(),
    );
    await runDb(tester, () => TestData(db).account(opening: 500000));
    await openSettings(tester);
    await scrollTo(tester, find.text('Delete all personal data'));
    await tester.tap(find.text('Delete all personal data'));
    await settle(tester);

    final action = find.widgetWithText(FilledButton, 'Delete everything');
    expect(tester.widget<FilledButton>(action).onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('delete-all-confirm')),
      'delete',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
    await tester.tap(action);
    await settle(tester);
    await settle(tester);

    expect(find.text('Welcome to DAWASA'), findsOneWidget);
    expect(find.text('All data deleted'), findsOneWidget);
    expect(dbFile.existsSync(), isFalse);
    expect(photo.existsSync(), isFalse);
    expect(platform.secureStore.values, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('pref.onboardingComplete'), isNull);
    expect(prefs.getBool('pref.hideBalancesOnStart'), isNull);
    expect(prefs.getString('pref.language'), 'en');
    final accounts = await runDb(
      tester,
      () => fresh.select(fresh.accounts).get(),
    );
    expect(accounts, isEmpty);
    await disposeApp(tester, fresh);
  });
}
