import 'package:dawasa/core/notifications/notification_service.dart';
import 'package:dawasa/features/tasks/data/task_repository.dart';
import 'package:dawasa/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';
import 'app_flow_test.dart' show usePhoneScreen;

void main() {
  testWidgets('create a task from the planner and complete it', (tester) async {
    usePhoneScreen(tester);
    final gateway = NoopNotificationGateway();
    final db = await pumpDawasaApp(
      tester,
      preferences: onboardedPrefs,
      notifications: gateway,
    );

    await tester.tap(find.text('Planner'));
    await settle(tester);
    expect(
      find.text('Nothing planned for today. Enjoy your day!'),
      findsOneWidget,
    );

    await tester.tap(find.text('New task').last);
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Buy vegetables');
    await tester.tap(find.text('At the due time'));
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
    await settle(tester);

    expect(find.text('Buy vegetables'), findsOneWidget);
    final tasks = await runDb(tester, () => TaskRepository(db).all());
    expect(tasks.single.reminders, [0]);

    await tester.tap(find.byType(Checkbox).first);
    await settle(tester);
    final after = await runDb(tester, () => TaskRepository(db).all());
    expect(after.single.task.isCompleted, isTrue);

    // Let the debounced reminder sync run.
    await tester.pump(const Duration(seconds: 2));
    await disposeApp(tester, db);
  });

  testWidgets('money hub shows budgets and bills tabs', (tester) async {
    usePhoneScreen(tester);
    final db = await pumpDawasaApp(tester, preferences: onboardedPrefs);
    await tester.tap(find.text('Money'));
    await settle(tester);
    await tester.ensureVisible(find.text('Budgets'));
    await tester.tap(find.text('Budgets'));
    await settle(tester);
    expect(
      find.text(
        'No budgets yet. A budget helps you keep spending under control.',
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Bills'));
    await tester.tap(find.text('Bills'));
    await settle(tester);
    expect(find.textContaining('No bills yet'), findsOneWidget);
    await disposeApp(tester, db);
  });
}
