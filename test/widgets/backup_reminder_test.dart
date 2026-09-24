import 'package:dawasa/features/backup/presentation/backup_reminder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_harness.dart';
import 'app_flow_test.dart' show usePhoneScreen;

void main() {
  final now = DateTime(2026, 9, 24);

  test('the reminder appears only when there is something to lose', () {
    expect(shouldRemindBackup(now: now, transactions: 5), isFalse);
    expect(shouldRemindBackup(now: now, transactions: 20), isTrue);
    expect(
      shouldRemindBackup(
        now: now,
        transactions: 500,
        lastBackup: now.subtract(const Duration(days: 3)),
      ),
      isFalse,
    );
    expect(
      shouldRemindBackup(
        now: now,
        transactions: 500,
        lastBackup: now.subtract(const Duration(days: 40)),
      ),
      isTrue,
    );
    expect(
      shouldRemindBackup(
        now: now,
        transactions: 500,
        dismissed: now.subtract(const Duration(days: 2)),
      ),
      isFalse,
    );
    expect(
      shouldRemindBackup(
        now: now,
        transactions: 500,
        dismissed: now.subtract(const Duration(days: 15)),
      ),
      isTrue,
    );
  });

  testWidgets('home suggests a backup and "Later" snoozes it', (tester) async {
    usePhoneScreen(tester);
    final db = newTestDatabase();
    final data = TestData(db);
    final cash = await runDb(tester, () => data.account(opening: 100000));
    await runDb(tester, () async {
      for (var i = 0; i < 20; i++) {
        await data.expense(cash, 100 + i);
      }
    });
    await pumpDawasaApp(tester, preferences: onboardedPrefs, database: db);
    expect(find.text('Keep a backup of your records'), findsOneWidget);

    await tester.tap(find.text('Later'));
    await settle(tester);
    expect(find.text('Keep a backup of your records'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pref.backup.reminderDismissed'), isNotNull);
    await disposeApp(tester, db);
  });
}
