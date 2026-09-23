import 'package:dawasa/core/database/app_database.dart';
import 'package:dawasa/core/l10n/l10n.dart';
import 'package:dawasa/core/notifications/notification_service.dart';
import 'package:dawasa/core/settings/app_preferences.dart';
import 'package:dawasa/core/time/date_range.dart';
import 'package:dawasa/core/time/local_date.dart';
import 'package:dawasa/core/time/recurrence.dart';
import 'package:dawasa/features/bills/data/bill_repository.dart';
import 'package:dawasa/features/budgets/data/budget_repository.dart';
import 'package:dawasa/features/budgets/domain/budget_logic.dart';
import 'package:dawasa/features/reminders/reminder_planner.dart';
import 'package:dawasa/features/shopping/data/shopping_repository.dart';
import 'package:dawasa/features/tasks/data/task_repository.dart';
import 'package:dawasa/ui/format/formatters.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/test_harness.dart';

void main() {
  late AppDatabase db;
  late TestData data;

  setUpAll(initializeDateFormatting);

  setUp(() {
    db = newTestDatabase();
    data = TestData(db);
  });

  tearDown(() => db.close());

  group('Budgets', () {
    test('windows for daily, weekly (first weekday), monthly and custom', () {
      final today = LocalDate(2026, 9, 23); // Wednesday
      expect(
        budgetWindow(BudgetPeriod.daily, today).range,
        DateRange.singleDay(today),
      );
      expect(
        budgetWindow(BudgetPeriod.weekly, today, firstWeekday: 1).range,
        DateRange(LocalDate(2026, 9, 21), LocalDate(2026, 9, 27)),
      );
      expect(
        budgetWindow(BudgetPeriod.weekly, today, firstWeekday: 7).range,
        DateRange(LocalDate(2026, 9, 20), LocalDate(2026, 9, 26)),
      );
      expect(
        budgetWindow(
          BudgetPeriod.monthly,
          LocalDate(2026, 2, 10),
        ).range.lengthInDays,
        28,
      );
      final custom = budgetWindow(
        BudgetPeriod.custom,
        today,
        customStart: LocalDate(2026, 10, 1),
        customEnd: LocalDate(2026, 10, 31),
      );
      expect(custom.status, BudgetStatus.notStarted);
    });

    test('progress counts only expenses of the budget categories', () async {
      final cash = await data.account(opening: 10000000);
      final bank = await data.account(name: 'Bank');
      final repo = BudgetRepository(db, data.transactions);
      final food = await data.categoryId(CategoryKind.expense, 'food');
      await repo.save(
        BudgetDraft(
          id: 'food-budget',
          name: 'Food',
          period: BudgetPeriod.monthly,
          amountMinor: 1000000,
          currencyCode: 'LKR',
          categoryIds: {food},
        ),
      );
      await repo.save(
        const BudgetDraft(
          id: 'all',
          name: 'All spending',
          period: BudgetPeriod.monthly,
          amountMinor: 5000000,
          currencyCode: 'LKR',
        ),
      );
      await data.expense(
        cash,
        300000,
        date: LocalDate(2026, 3, 2),
        category: 'food',
      );
      await data.expense(
        cash,
        550000,
        date: LocalDate(2026, 3, 9),
        category: 'food',
      );
      await data.expense(
        cash,
        200000,
        date: LocalDate(2026, 3, 9),
        category: 'transport',
      );
      await data.expense(
        cash,
        999999,
        date: LocalDate(2026, 2, 28),
        category: 'food',
      );
      // Transfers and income never count as spending.
      await data.transfer(cash, bank, 4000000, date: LocalDate(2026, 3, 10));
      await data.income(cash, 7000000, date: LocalDate(2026, 3, 10));

      final progress = await repo.progress(LocalDate(2026, 3, 15), 1);
      final foodP = progress.firstWhere((p) => p.budget.id == 'food-budget');
      final allP = progress.firstWhere((p) => p.budget.id == 'all');
      expect(foodP.spentMinor, 850000);
      expect(foodP.percentUsed, 85);
      expect(foodP.alertLevel, BudgetAlertLevel.warning);
      expect(foodP.daysLeft, 17);
      expect(allP.spentMinor, 1050000);
      expect(allP.alertLevel, BudgetAlertLevel.none);

      final monthly = await repo.monthlyOverall(LocalDate(2026, 3, 15), 'LKR');
      expect(monthly!.amount, 5000000);
      expect(monthly.spentBeforeToday, 1050000);
    });

    test('alerts once per period and level, never stepping back', () async {
      final cash = await data.account(opening: 10000000);
      final repo = BudgetRepository(db, data.transactions);
      await repo.save(
        const BudgetDraft(
          id: 'b',
          name: 'Week',
          period: BudgetPeriod.weekly,
          amountMinor: 10000,
          currencyCode: 'LKR',
          warnPercent: 80,
        ),
      );
      final day = LocalDate(2026, 3, 11);
      await data.expense(cash, 8500, date: day);
      var p = (await repo.progress(day, 1)).single;
      expect(p.shouldAlert(), isTrue);
      await repo.setLastAlert('b', p.alertKey);
      p = (await repo.progress(day, 1)).single;
      expect(p.shouldAlert(), isFalse, reason: 'warning already sent');

      await data.expense(cash, 2000, date: day);
      p = (await repo.progress(day, 1)).single;
      expect(p.alertLevel, BudgetAlertLevel.exceeded);
      expect(p.shouldAlert(), isTrue);
      await repo.setLastAlert('b', p.alertKey);

      // Next week starts fresh.
      p = (await repo.progress(LocalDate(2026, 3, 18), 1)).single;
      expect(p.spentMinor, 0);
      expect(p.alertLevel, BudgetAlertLevel.none);
    });
  });

  group('Tasks', () {
    test('views, overdue and sorting', () async {
      final repo = TaskRepository(db);
      final today = LocalDate(2026, 5, 10);
      await repo.save(
        TaskDraft(id: 't1', title: 'Pay fees', dueDate: today.addDays(-1)),
      );
      await repo.save(
        TaskDraft(
          id: 't2',
          title: 'Call amma',
          dueDate: today,
          priority: TaskPriority.high,
        ),
      );
      await repo.save(
        TaskDraft(id: 't3', title: 'Tomorrow', dueDate: today.addDays(1)),
      );
      await repo.save(
        TaskDraft(
          id: 't4',
          title: 'Later',
          dueDate: today.addDays(5),
          priority: TaskPriority.low,
        ),
      );
      await repo.save(const TaskDraft(id: 't5', title: 'Someday'));
      final all = await repo.all();
      List<String> ids(TaskView v, TaskSort s) => TaskRepository.sort(
        all.where((i) => TaskRepository.matches(i.task, v, today)).toList(),
        s,
      ).map((i) => i.task.id).toList();
      expect(ids(TaskView.today, TaskSort.dueDate), ['t1', 't2']);
      expect(ids(TaskView.tomorrow, TaskSort.dueDate), ['t3']);
      expect(ids(TaskView.upcoming, TaskSort.dueDate), ['t4']);
      expect(ids(TaskView.all, TaskSort.dueDate), [
        't1',
        't2',
        't3',
        't4',
        't5',
      ]);
      expect(ids(TaskView.all, TaskSort.priority).first, 't2');
      expect(
        all.firstWhere((i) => i.task.id == 't1').isOverdue(today, 0),
        isTrue,
      );
    });

    test(
      'completing a recurring task creates the next one exactly once',
      () async {
        final repo = TaskRepository(db);
        await repo.save(
          TaskDraft(
            id: 'rent',
            title: 'Pay rent',
            dueDate: LocalDate(2026, 1, 31),
            dueTimeMinutes: 9 * 60,
            recurrence: RecurrenceRule.monthly(),
            reminderMinutesBefore: const [0, 24 * 60],
          ),
        );
        final next = await repo.complete('rent', DateTime(2026, 1, 31, 10));
        expect(next!.dueDate, LocalDate(2026, 2, 28));
        expect(await repo.complete('rent', DateTime(2026, 1, 31, 10)), isNull);
        final third = await repo.complete(next.id, DateTime(2026, 2, 28, 10));
        expect(
          third!.dueDate,
          LocalDate(2026, 3, 31),
          reason: 'keeps the 31st',
        );
        final items = await repo.all();
        expect(items.length, 3);
        expect(items.firstWhere((i) => i.task.id == third.id).reminders, [
          0,
          1440,
        ]);
        // Reopening and completing again reuses the deterministic id.
        await repo.reopen(next.id);
        await repo.complete(next.id, DateTime(2026, 2, 28, 11));
        expect((await repo.all()).length, 3);
      },
    );
  });

  group('Bills', () {
    late BillRepository bills;
    late String cash;

    setUp(() async {
      bills = BillRepository(db, data.transactions, data.categories);
      cash = await data.account(opening: 5000000);
      await bills.save(
        BillDraft(
          id: 'ceb',
          name: 'CEB electricity',
          category: BillCategory.electricity,
          amountMinor: 450000,
          currencyCode: 'LKR',
          nextDueDate: LocalDate(2026, 1, 31),
          recurrence: RecurrenceRule.monthly(),
          accountId: cash,
        ),
      );
    });

    test('paying creates one expense and advances the due date', () async {
      await bills.recordPayment(
        paymentId: 'p1',
        billId: 'ceb',
        dueDate: LocalDate(2026, 1, 31),
        paidAt: DateTime(2026, 1, 30, 18),
        amountMinor: 462000,
        recording: RecordNewExpense(transactionId: 'tx-ceb-1', accountId: cash),
      );
      // Retrying the same payment (e.g. double tap) is a no-op.
      await bills.recordPayment(
        paymentId: 'p1',
        billId: 'ceb',
        dueDate: LocalDate(2026, 1, 31),
        paidAt: DateTime(2026, 1, 30, 18),
        amountMinor: 462000,
        recording: RecordNewExpense(transactionId: 'tx-ceb-1', accountId: cash),
      );
      expect(await data.transactions.count(), 1);
      expect(await data.accounts.balanceOf(cash), 5000000 - 462000);
      final bill = (await bills.byId('ceb'))!;
      expect(bill.nextDueDate, LocalDate(2026, 2, 28));
      final tx = (await data.transactions.byId('tx-ceb-1'))!;
      expect(tx.category!.systemKey, 'bills');
      expect(tx.transaction.source, TransactionSource.bill);

      // A different payment for the same cycle is rejected.
      expect(
        () => bills.recordPayment(
          paymentId: 'p2',
          billId: 'ceb',
          dueDate: LocalDate(2026, 1, 31),
          paidAt: DateTime(2026, 2, 1),
          amountMinor: 1,
          recording: const NoExpense(),
        ),
        throwsA(isA<BillAlreadyPaidException>()),
      );
    });

    test(
      'an expense already recorded is linked instead of duplicated',
      () async {
        final existing = await data.expense(
          cash,
          450000,
          date: LocalDate(2026, 1, 29),
          category: 'bills',
          description: 'Electricity',
        );
        final candidates = await bills.duplicateCandidates(
          amountMinor: 450000,
          around: LocalDate(2026, 1, 31),
        );
        expect(candidates.map((c) => c.transaction.id), [existing]);
        await bills.recordPayment(
          paymentId: 'p1',
          billId: 'ceb',
          dueDate: LocalDate(2026, 1, 31),
          paidAt: DateTime(2026, 1, 31),
          amountMinor: 450000,
          recording: LinkExistingExpense(existing),
        );
        expect(await data.transactions.count(), 1);
        expect(await data.accounts.balanceOf(cash), 5000000 - 450000);
        // The linked expense is no longer offered as a candidate.
        expect(
          await bills.duplicateCandidates(
            amountMinor: 450000,
            around: LocalDate(2026, 1, 31),
          ),
          isEmpty,
        );
      },
    );

    test('undo makes the cycle due again; one-time bills finish', () async {
      await bills.recordPayment(
        paymentId: 'p1',
        billId: 'ceb',
        dueDate: LocalDate(2026, 1, 31),
        paidAt: DateTime(2026, 1, 31),
        amountMinor: 450000,
        recording: const NoExpense(),
      );
      await bills.undoPayment('p1');
      expect((await bills.byId('ceb'))!.nextDueDate, LocalDate(2026, 1, 31));

      await bills.save(
        BillDraft(
          id: 'once',
          name: 'Insurance',
          category: BillCategory.insurance,
          amountMinor: 100000,
          currencyCode: 'LKR',
          nextDueDate: LocalDate(2026, 6, 1),
        ),
      );
      await bills.recordPayment(
        paymentId: 'p-once',
        billId: 'once',
        dueDate: LocalDate(2026, 6, 1),
        paidAt: DateTime(2026, 6, 1),
        amountMinor: 100000,
        recording: const NoExpense(),
      );
      expect((await bills.byId('once'))!.isActive, isFalse);
      expect(await data.transactions.count(), 0);
    });

    test('loan instalments are not recorded as spending by default', () {
      expect(
        BillRepository.recordsAsExpenseByDefault(BillCategory.loan),
        isFalse,
      );
      expect(
        BillRepository.recordsAsExpenseByDefault(BillCategory.water),
        isTrue,
      );
    });
  });

  group('Shopping', () {
    test(
      'estimates never touch balances; purchases are recorded once',
      () async {
        final cash = await data.account(opening: 1000000);
        final shop = ShoppingRepository(db, data.transactions, data.categories);
        final list = await shop.createList('Weekly groceries');
        await shop.saveItem(
          ShoppingItemDraft(
            id: 'rice',
            listId: list,
            name: 'Rice',
            quantityMilli: 5000,
            unit: 'kg',
            estimatedPriceMinor: 125000,
          ),
        );
        await shop.saveItem(
          ShoppingItemDraft(
            id: 'dhal',
            listId: list,
            name: 'Dhal',
            estimatedPriceMinor: 45000,
          ),
        );
        await shop.saveItem(
          ShoppingItemDraft(
            id: 'milk',
            listId: list,
            name: 'Milk powder',
            estimatedPriceMinor: 99000,
          ),
        );
        expect(await data.accounts.balanceOf(cash), 1000000);

        await shop.setPurchased(
          'rice',
          purchased: true,
          actualPriceMinor: 130000,
        );
        await shop.setPurchased('dhal', purchased: true);
        expect(
          () => shop.recordPurchases(
            listId: list,
            transactionId: 'tx1',
            accountId: cash,
            occurredAt: DateTime(2026, 3, 1),
            currencyCode: 'LKR',
          ),
          throwsA(isA<MissingActualPriceException>()),
        );
        await shop.setPurchased(
          'dhal',
          purchased: true,
          actualPriceMinor: 47000,
        );
        final total = await shop.recordPurchases(
          listId: list,
          transactionId: 'tx1',
          accountId: cash,
          occurredAt: DateTime(2026, 3, 1),
          currencyCode: 'LKR',
        );
        expect(total, 177000);
        expect(await data.accounts.balanceOf(cash), 1000000 - 177000);
        // Same request again returns the existing expense, no double count.
        await shop.recordPurchases(
          listId: list,
          transactionId: 'tx1',
          accountId: cash,
          occurredAt: DateTime(2026, 3, 1),
          currencyCode: 'LKR',
        );
        expect(
          () => shop.recordPurchases(
            listId: list,
            transactionId: 'tx2',
            accountId: cash,
            occurredAt: DateTime(2026, 3, 1),
            currencyCode: 'LKR',
          ),
          throwsA(isA<NothingToRecordException>()),
        );
        // A later purchase is recorded separately.
        await shop.setPurchased(
          'milk',
          purchased: true,
          actualPriceMinor: 98000,
        );
        await shop.recordPurchases(
          listId: list,
          transactionId: 'tx3',
          accountId: cash,
          occurredAt: DateTime(2026, 3, 2),
          currencyCode: 'LKR',
        );
        expect(await data.transactions.count(), 2);
        expect(await data.accounts.balanceOf(cash), 1000000 - 177000 - 98000);
        final totals = ShoppingTotals.of(await shop.items(list));
        expect(totals.estimatedMinor, 269000);
        expect(totals.actualMinor, 275000);
        expect(totals.unrecordedCount, 0);

        // Deleting the expense makes the items recordable again.
        await data.transactions.delete('tx3');
        expect(ShoppingTotals.of(await shop.items(list)).unrecordedCount, 1);
      },
    );
  });

  group('Reminder planning', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final formatter = AppDateFormatter(
      localeName: 'en',
      format: DateDisplayFormat.medium,
    );

    test('plans task, bill and daily reminders in the future only', () async {
      final repo = TaskRepository(db);
      final bills = BillRepository(db, data.transactions, data.categories);
      final now = DateTime(2026, 5, 10, 8);
      await repo.save(
        TaskDraft(
          id: 'task',
          title: 'Doctor',
          dueDate: LocalDate(2026, 5, 10),
          dueTimeMinutes: 15 * 60,
          reminderMinutesBefore: const [0, 60, 24 * 60],
        ),
      );
      await repo.save(
        TaskDraft(
          id: 'done',
          title: 'Done',
          dueDate: LocalDate(2026, 5, 11),
          reminderMinutesBefore: const [0],
        ),
      );
      await repo.complete('done', now);
      await bills.save(
        BillDraft(
          id: 'water',
          name: 'Water',
          category: BillCategory.water,
          amountMinor: 120000,
          currencyCode: 'LKR',
          nextDueDate: LocalDate(2026, 5, 15),
          remindDaysBefore: 2,
        ),
      );

      final planned = planReminders(
        ReminderInputs(
          now: now,
          prefs: const AppPreferences(
            dailyPlanningEnabled: true,
            dailyPlanningMinutes: 20 * 60,
          ),
          l10n: l10n,
          formatter: formatter,
          tasks: await repo.all(),
          bills: await bills.all(),
        ),
      );
      final byChannel = <ReminderChannel, List<DateTime>>{};
      for (final n in planned) {
        byChannel.putIfAbsent(n.channel, () => []).add(n.when);
      }
      // The "1 day before" task reminder is already in the past.
      expect(byChannel[ReminderChannel.tasks], [
        DateTime(2026, 5, 10, 14),
        DateTime(2026, 5, 10, 15),
      ]);
      expect(byChannel[ReminderChannel.bills], [
        DateTime(2026, 5, 13, 9),
        DateTime(2026, 5, 15, 9),
      ]);
      expect(byChannel[ReminderChannel.planning]!.length, 7);
      expect(planned.map((n) => n.id).toSet().length, planned.length);
      expect(planned.first.title, 'Task: Doctor');

      final disabled = planReminders(
        ReminderInputs(
          now: now,
          prefs: const AppPreferences(notificationsEnabled: false),
          l10n: l10n,
          formatter: formatter,
          tasks: await repo.all(),
          bills: await bills.all(),
        ),
      );
      expect(disabled, isEmpty);

      final noBills = planReminders(
        ReminderInputs(
          now: now,
          prefs: const AppPreferences(notifyBills: false),
          l10n: l10n,
          formatter: formatter,
          tasks: await repo.all(),
          bills: await bills.all(),
        ),
      );
      expect(noBills.any((n) => n.channel == ReminderChannel.bills), isFalse);
    });

    test('notification ids are stable', () {
      expect(notificationIdFor('task:a:0'), notificationIdFor('task:a:0'));
      expect(
        notificationIdFor('task:a:0'),
        isNot(notificationIdFor('task:a:60')),
      );
      expect(notificationIdFor('x') >= 0, isTrue);
    });
  });
}
