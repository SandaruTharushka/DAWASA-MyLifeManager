// On-device end-to-end test. Run on an emulator or phone:
//
//   flutter test integration_test/app_test.dart
//
// It uses the real database file, plugins and Android services, so it must
// run on a fresh install (or after "Clear storage"). It is not run by
// `flutter test` on a computer.
import 'package:dawasa/app/app_root.dart';
import 'package:dawasa/core/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch, add an expense, see it on the dashboard', (
    tester,
  ) async {
    await initializeDateFormatting();
    await LocalNotificationGateway.initializeTimeZones();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString('pref.language', 'en');

    await tester.pumpWidget(
      AppRoot(
        preferences: prefs,
        notificationGateway: LocalNotificationGateway(),
      ),
    );
    await tester.pumpAndSettle();

    // Welcome guide.
    expect(find.text('Welcome to DAWASA'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue')); // language
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue')); // currency (LKR)
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cash in hand'),
      '5000',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip')); // daily budget
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start using DAWASA'));
    await tester.pumpAndSettle();
    expect(find.text('Rs 5,000.00'), findsWidgets);

    // Add an expense through the quick-add sheet.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '250');
    final save = find.text('Save');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Rs 4,750.00'), findsWidgets);
  });
}
