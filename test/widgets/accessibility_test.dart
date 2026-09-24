import 'package:dawasa/app/app_root.dart';
import 'package:dawasa/core/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_harness.dart';
import 'app_flow_test.dart' show usePhoneScreen;
import 'security_flow_test.dart' show openSettings, saveTestPin;

Future<void> expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  testWidgets('main screens meet tap target, label and contrast guidelines', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final handle = tester.ensureSemantics();
    final db = newTestDatabase();
    final data = TestData(db);
    final cash = await runDb(tester, () => data.account(opening: 500000));
    await runDb(tester, () => data.expense(cash, 25000, description: 'Tea'));
    await pumpDawasaApp(tester, preferences: onboardedPrefs, database: db);

    await expectAccessible(tester); // Home
    for (final tab in ['Money', 'Planner', 'Reports']) {
      await tester.tap(find.text(tab));
      await settle(tester);
      await expectAccessible(tester);
    }
    await openSettings(tester);
    await expectAccessible(tester);
    handle.dispose();
    await disposeApp(tester, db);
  });

  testWidgets('the welcome guide and the lock screen are accessible', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final handle = tester.ensureSemantics();
    final db = await pumpDawasaApp(tester);
    await expectAccessible(tester);
    await disposeApp(tester, db);

    final platform = TestPlatform();
    await saveTestPin(tester, platform, '2580');
    final locked = await pumpDawasaApp(
      tester,
      preferences: onboardedPrefs,
      platform: platform,
    );
    expect(find.text('DAWASA is locked'), findsOneWidget);
    await expectAccessible(tester);
    // Every key of the PIN pad is announced.
    for (final label in ['1', '0', 'Delete last digit']) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    handle.dispose();
    await disposeApp(tester, locked);
  });

  testWidgets('large system text does not break the main screens', (
    tester,
  ) async {
    usePhoneScreen(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await initializeDateFormatting();
    SharedPreferences.setMockInitialValues({
      ...onboardedPrefs,
      'pref.language': 'si',
    });
    final prefs = await SharedPreferences.getInstance();
    final db = newTestDatabase();
    final cash = await runDb(tester, () => TestData(db).account(opening: 1));
    await runDb(tester, () => TestData(db).expense(cash, 123456789));
    await tester.pumpWidget(
      AppRoot(
        preferences: prefs,
        notificationGateway: NoopNotificationGateway(),
        openDatabase: () async => db,
        overrides: TestPlatform().overrides,
      ),
    );
    await settle(tester);
    // Any overflow or layout error is reported by the framework and fails
    // the test with the offending widget.
    for (final tab in ['මුදල්', 'සැලසුම්', 'වාර්තා', 'සැකසීම්', 'මුල් පිටුව']) {
      await tester.tap(find.text(tab).last);
      await settle(tester);
    }
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    await disposeApp(tester, db);
  });
}
