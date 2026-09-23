import 'package:dawasa/core/database/app_database.dart';
import 'package:dawasa/core/settings/user_settings.dart';
import 'package:dawasa/features/accounts/data/account_repository.dart';
import 'package:dawasa/features/transactions/data/transaction_repository.dart';
import 'package:dawasa/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('first launch onboarding creates accounts and settings', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final db = await pumpDawasaApp(tester);

    expect(find.text('Welcome to DAWASA'), findsOneWidget);
    expect(find.text('100% free — no ads, no subscriptions'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await settle(tester);

    // Language: switching to Sinhala updates the UI immediately.
    expect(find.text('Choose your language'), findsOneWidget);
    await tester.tap(find.text('සිංහල'));
    await settle(tester);
    expect(find.text('ඔබේ භාෂාව තෝරන්න'), findsOneWidget);
    await tester.tap(find.text('English'));
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    // Currency (LKR is the default).
    expect(find.text('Choose your currency'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    // Opening balances.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cash in hand'),
      '5,000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bank balance'),
      '20000.50',
    );
    await tester.tap(find.text('Continue'));
    await settle(tester);

    // Daily budget.
    expect(find.text('Daily spending budget'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '1500');
    await tester.tap(find.text('Continue'));
    await settle(tester);

    // Reminders are optional; finish without granting.
    expect(find.text('Enable reminders'), findsOneWidget);
    await tester.tap(find.text('Start using DAWASA'));
    await settle(tester);

    expect(find.text('Available balance'), findsOneWidget);
    expect(find.text('Rs 25,000.50'), findsOneWidget);
    expect(find.text('Left to spend today'), findsOneWidget);

    final accounts = await runDb(
      tester,
      () => AccountRepository(db).balances(),
    );
    expect(accounts.map((a) => (a.account.type, a.balanceMinor)), [
      (AccountType.cash, 500000),
      (AccountType.bank, 2000050),
    ]);
    final settings = await runDb(
      tester,
      () => UserSettingsRepository(db).load(),
    );
    expect(settings.dailyBudgetMinor, 150000);
    expect(settings.currencyCode, 'LKR');

    await disposeApp(tester, db);
  });

  testWidgets('adding an expense twice quickly records it once', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final db = newTestDatabase();
    await runDb(
      tester,
      () => AccountRepository(db).create(
        name: 'Cash',
        type: AccountType.cash,
        currencyCode: 'LKR',
        openingBalanceMinor: 100000,
      ),
    );
    await pumpDawasaApp(tester, preferences: onboardedPrefs, database: db);

    expect(find.text('Rs 1,000.00'), findsWidgets);
    await tester.tap(find.byTooltip('Add'));
    await settle(tester);
    await tester.tap(find.text('Add expense').last);
    await settle(tester);

    await tester.enterText(find.byType(TextFormField).first, '250');
    await tester.tap(find.text('Food'));
    await tester.pump();
    final save = find.text('Save');
    await tester.scrollUntilVisible(
      save,
      300,
      scrollable: find
          .descendant(
            of: find.byType(PageBody),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.tap(save, warnIfMissed: false);
    await settle(tester);

    final count = await runDb(tester, () => TransactionRepository(db).count());
    expect(count, 1);
    final balance = await runDb(
      tester,
      () async => (await AccountRepository(db).balances()).single.balanceMinor,
    );
    expect(balance, 75000);
    expect(find.text('Rs 750.00'), findsWidgets);

    await disposeApp(tester, db);
  });

  testWidgets('the home screen is fully translated to Sinhala', (tester) async {
    usePhoneScreen(tester);
    final db = await pumpDawasaApp(
      tester,
      preferences: {'pref.onboardingComplete': true, 'pref.language': 'si'},
    );
    expect(find.text('පවතින ශේෂය'), findsOneWidget);
    expect(find.text('මුල් පිටුව'), findsOneWidget);
    expect(find.text('වාර්තා'), findsWidgets);
    expect(find.text('Available balance'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('hide balances masks amounts on the dashboard', (tester) async {
    usePhoneScreen(tester);
    final db = newTestDatabase();
    await runDb(
      tester,
      () => AccountRepository(db).create(
        name: 'Cash',
        type: AccountType.cash,
        currencyCode: 'LKR',
        openingBalanceMinor: 123400,
      ),
    );
    await pumpDawasaApp(tester, preferences: onboardedPrefs, database: db);
    expect(find.text('Rs 1,234.00'), findsWidgets);
    await tester.tap(find.byTooltip('Hide balances'));
    await tester.pump();
    expect(find.text('Rs 1,234.00'), findsNothing);
    expect(find.text('Rs ••••••'), findsWidgets);
    await disposeApp(tester, db);
  });
}
