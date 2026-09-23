import 'package:dawasa/core/database/app_database.dart';
import 'package:dawasa/core/l10n/l10n.dart';
import 'package:dawasa/core/time/date_range.dart';
import 'package:dawasa/core/time/local_date.dart';
import 'package:dawasa/core/time/recurrence.dart';
import 'package:dawasa/features/events/data/event_repository.dart';
import 'package:dawasa/features/habits/data/habit_repository.dart';
import 'package:dawasa/features/loans/data/loan_repository.dart';
import 'package:dawasa/features/reports/data/csv_exporter.dart';
import 'package:dawasa/features/reports/data/report_service.dart';
import 'package:dawasa/features/savings/data/savings_repository.dart';
import 'package:dawasa/features/transactions/domain/transaction_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  late AppDatabase db;
  late TestData data;

  setUp(() {
    db = newTestDatabase();
    data = TestData(db);
  });

  tearDown(() => db.close());

  DateRange march() => DateRange.month(2026, 3);

  group('Savings goals', () {
    test(
      'deposits into a linked account are transfers, not spending',
      () async {
        final cash = await data.account(opening: 5000000);
        final savingsAcc = await data.account(
          name: 'Savings',
          type: AccountType.savings,
        );
        final repo = SavingsRepository(db, data.transactions);
        await repo.saveGoal(
          SavingsGoalDraft(
            id: 'phone',
            name: 'New phone',
            targetAmountMinor: 12000000,
            currencyCode: 'LKR',
            linkedAccountId: savingsAcc,
            targetDate: LocalDate(2026, 12, 31),
          ),
        );
        await repo.deposit(
          movementId: 'm1',
          goalId: 'phone',
          amountMinor: 3000000,
          occurredAt: DateTime(2026, 3, 5, 10),
          fromAccountId: cash,
        );
        // Retrying the same movement does nothing.
        await repo.deposit(
          movementId: 'm1',
          goalId: 'phone',
          amountMinor: 3000000,
          occurredAt: DateTime(2026, 3, 5, 10),
          fromAccountId: cash,
        );
        expect(await data.accounts.balanceOf(cash), 2000000);
        expect(await data.accounts.balanceOf(savingsAcc), 3000000);
        final totals = await data.transactions.totals(march());
        expect(totals.expenseMinor, 0, reason: 'saving is not spending');
        expect(totals.incomeMinor, 0);
        final goal = (await repo.goal('phone'))!;
        expect(goal.savedMinor, 3000000);
        expect(goal.percent, 25);
        expect(goal.monthlyNeededMinor(LocalDate(2026, 3, 5)), 900000);

        // Withdrawal back to cash.
        await repo.withdraw(
          movementId: 'm2',
          goalId: 'phone',
          amountMinor: 1000000,
          occurredAt: DateTime(2026, 3, 20),
          toAccountId: cash,
        );
        expect(await data.accounts.balanceOf(cash), 3000000);
        expect((await repo.goal('phone'))!.savedMinor, 2000000);
        expect(
          () => repo.withdraw(
            movementId: 'm3',
            goalId: 'phone',
            amountMinor: 2000001,
            occurredAt: DateTime(2026, 3, 21),
            toAccountId: cash,
          ),
          throwsA(isA<InsufficientSavingsException>()),
        );

        // Deleting the transfer transaction also removes the movement.
        final transfer = (await data.transactions.filtered(
          const TransactionFilter(types: {TransactionType.transfer}),
        )).firstWhere((t) => t.transaction.amountMinor == 3000000);
        await data.transactions.delete(transfer.transaction.id);
        // Only the withdrawal movement remains; goal math follows the records.
        final after = (await repo.goal('phone'))!;
        expect(after.savedMinor, -1000000);
        expect(after.percent, 0);
        expect(await data.accounts.balanceOf(cash), 6000000);
      },
    );

    test(
      'tracking-only goals never change balances and complete at target',
      () async {
        final cash = await data.account(opening: 100000);
        final repo = SavingsRepository(db, data.transactions);
        await repo.saveGoal(
          const SavingsGoalDraft(
            id: 'trip',
            name: 'Trip',
            targetAmountMinor: 50000,
            currencyCode: 'LKR',
          ),
        );
        await repo.deposit(
          movementId: 'x',
          goalId: 'trip',
          amountMinor: 50000,
          occurredAt: DateTime(2026, 3, 1),
          fromAccountId: cash,
        );
        expect(await data.accounts.balanceOf(cash), 100000);
        expect(await data.transactions.count(), 0);
        final goal = (await repo.goal('trip'))!;
        expect(goal.reached, isTrue);
        expect(goal.goal.completedAt, isNotNull);
        expect(
          await repo.depositedBetween(
            LocalDate(2026, 3, 1),
            LocalDate(2026, 3, 31),
          ),
          50000,
        );
      },
    );
  });

  group('Loans', () {
    test(
      'lent money: principal and interest are classified correctly',
      () async {
        final cash = await data.account(opening: 10000000);
        final repo = LoanRepository(db, data.transactions, data.categories);
        await repo.save(
          LoanDraft(
            id: 'kamal',
            direction: LoanDirection.lent,
            counterparty: 'Kamal',
            principalMinor: 2000000,
            currencyCode: 'LKR',
            startDate: LocalDate(2026, 3, 1),
            dueDate: LocalDate(2026, 6, 1),
            accountId: cash,
            recordMovement: true,
          ),
        );
        expect(await data.accounts.balanceOf(cash), 8000000);
        await repo.recordRepayment(
          repaymentId: 'r1',
          loanId: 'kamal',
          principalMinor: 500000,
          interestMinor: 20000,
          paidAt: DateTime(2026, 3, 15),
          accountId: cash,
        );
        expect(await data.accounts.balanceOf(cash), 8000000 + 520000);
        final loan = (await repo.loan('kamal'))!;
        expect(loan.outstandingMinor, 1500000);
        final totals = await data.transactions.totals(march());
        expect(totals.incomeMinor, 20000, reason: 'only interest is income');
        expect(totals.expenseMinor, 0, reason: 'lending is not spending');
        expect(totals.otherOutMinor, 2000000);
        expect(totals.otherInMinor, 500000);
        expect(
          () => repo.recordRepayment(
            repaymentId: 'r2',
            loanId: 'kamal',
            principalMinor: 1500001,
            paidAt: DateTime(2026, 3, 20),
          ),
          throwsA(isA<OverpaymentException>()),
        );
        await repo.recordRepayment(
          repaymentId: 'r3',
          loanId: 'kamal',
          principalMinor: 1500000,
          paidAt: DateTime(2026, 4, 1),
          accountId: cash,
        );
        expect((await repo.loan('kamal'))!.loan.status, LoanStatus.settled);
        expect(await data.accounts.balanceOf(cash), 10000000 + 20000);

        // Deleting a repayment re-opens the loan and restores balances.
        await repo.deleteRepayment('r3');
        final reopened = (await repo.loan('kamal'))!;
        expect(reopened.loan.status, LoanStatus.active);
        expect(reopened.outstandingMinor, 1500000);
        expect(await data.accounts.balanceOf(cash), 8000000 + 520000);
      },
    );

    test(
      'borrowed money: interest paid is an expense; delete removes movements',
      () async {
        final bank = await data.account(name: 'Bank', opening: 0);
        final repo = LoanRepository(db, data.transactions, data.categories);
        await repo.save(
          LoanDraft(
            id: 'bank-loan',
            direction: LoanDirection.borrowed,
            counterparty: 'People\'s Bank',
            principalMinor: 10000000,
            currencyCode: 'LKR',
            startDate: LocalDate(2026, 3, 1),
            accountId: bank,
            recordMovement: true,
            interestRateBps: 1250,
          ),
        );
        await repo.recordRepayment(
          repaymentId: 'p1',
          loanId: 'bank-loan',
          principalMinor: 800000,
          interestMinor: 104000,
          paidAt: DateTime(2026, 3, 31),
          accountId: bank,
        );
        final totals = await data.transactions.totals(march());
        expect(totals.expenseMinor, 104000);
        expect(totals.incomeMinor, 0);
        expect(await data.accounts.balanceOf(bank), 10000000 - 904000);
        final loanTotals = await repo.totals('LKR');
        expect(loanTotals.youOwe, 9200000);
        expect(loanTotals.owedToYou, 0);

        await repo.delete('bank-loan');
        expect(await data.transactions.count(), 0);
        expect(await data.accounts.balanceOf(bank), 0);
      },
    );

    test('manual settlement writes off the rest', () async {
      final repo = LoanRepository(db, data.transactions, data.categories);
      await repo.save(
        LoanDraft(
          id: 'friend',
          direction: LoanDirection.lent,
          counterparty: 'Friend',
          principalMinor: 100000,
          currencyCode: 'LKR',
          startDate: LocalDate(2026, 1, 1),
        ),
      );
      await repo.settle('friend');
      final loan = (await repo.loan('friend'))!;
      expect(loan.outstandingMinor, 0);
      expect(loan.loan.settledAt, isNotNull);
    });
  });

  group('Habits', () {
    final today = LocalDate(2026, 5, 10); // Sunday

    test(
      'daily streak counts consecutive days and survives until end of today',
      () {
        final counts = {
          today.addDays(-1): 1,
          today.addDays(-2): 1,
          today.addDays(-3): 1,
          today.addDays(-5): 1,
          today.addDays(-6): 1,
          today.addDays(-7): 1,
          today.addDays(-8): 1,
        };
        final s = computeHabitStats(
          frequency: HabitFrequency.daily,
          target: 1,
          counts: counts,
          today: today,
        );
        expect(s.current, 3);
        expect(s.best, 4);
        expect(s.completedToday, isFalse);
        final done = computeHabitStats(
          frequency: HabitFrequency.daily,
          target: 1,
          counts: {...counts, today: 1},
          today: today,
        );
        expect(done.current, 4);
        expect(done.completedToday, isTrue);
      },
    );

    test('targets per day and weekly streaks', () {
      final water = computeHabitStats(
        frequency: HabitFrequency.daily,
        target: 8,
        counts: {today: 5, today.addDays(-1): 8},
        today: today,
      );
      expect(water.completedToday, isFalse);
      expect(water.doneInPeriod, 5);
      expect(water.current, 1);

      // Three times a week, weeks starting Monday.
      final gym = computeHabitStats(
        frequency: HabitFrequency.weekly,
        target: 3,
        counts: {
          LocalDate(2026, 5, 4): 1,
          LocalDate(2026, 5, 6): 1,
          LocalDate(2026, 5, 8): 1, // week of May 4: done
          LocalDate(2026, 4, 27): 3, // week of Apr 27: done
          LocalDate(2026, 4, 20): 1, // week of Apr 20: not done
        },
        today: today,
      );
      expect(gym.completedToday, isTrue);
      expect(gym.current, 2);
    });

    test('logs are upserted per day and never touch money', () async {
      final repo = HabitRepository(db);
      await repo.save(
        const HabitDraft(
          id: 'h',
          name: 'Read',
          frequency: HabitFrequency.daily,
        ),
      );
      await repo.setCount('h', today, 1);
      await repo.setCount('h', today, 2);
      expect(await repo.countOn('h', today), 2);
      await repo.setCount('h', today, 0);
      expect(await repo.countOn('h', today), 0);
      expect(await data.transactions.count(), 0);
    });
  });

  group('Important dates', () {
    test('yearly birthdays find the next occurrence and age', () async {
      final repo = EventRepository(db);
      await repo.save(
        EventDraft(
          id: 'amma',
          title: 'Amma',
          type: EventType.birthday,
          date: LocalDate(1972, 2, 29),
          recurrence: RecurrenceRule.yearly(),
          remindDaysBefore: 1,
        ),
      );
      await repo.save(
        EventDraft(
          id: 'exam',
          title: 'O/L exam',
          type: EventType.exam,
          date: LocalDate(2026, 1, 5),
        ),
      );
      final events = await repo.all();
      final today = LocalDate(2026, 9, 23);
      final amma = EventView.of(
        events.firstWhere((e) => e.id == 'amma'),
        today,
      );
      expect(amma.next, LocalDate(2027, 2, 28));
      expect(amma.yearsAtNext, 55);
      expect(amma.occurrencesIn(2028, 2), [LocalDate(2028, 2, 29)]);
      final exam = EventView.of(
        events.firstWhere((e) => e.id == 'exam'),
        today,
      );
      expect(exam.next, isNull, reason: 'one-off event in the past');
    });
  });

  group('Reports', () {
    test(
      'report service groups by day for short ranges and by month for long',
      () async {
        final cash = await data.account(opening: 10000000);
        await data.income(cash, 10000000, date: LocalDate(2026, 1, 25));
        await data.expense(cash, 250000, date: LocalDate(2026, 2, 3));
        await data.expense(cash, 150000, date: LocalDate(2026, 3, 2));
        await data.expense(
          cash,
          50000,
          date: LocalDate(2026, 3, 2),
          category: 'transport',
        );
        final service = ReportService(data.transactions);

        final short = await service.build(march(), 'LKR');
        expect(short.granularity, ReportGranularity.day);
        expect(short.cashFlow.length, 31);
        expect(short.cashFlow[1].expenseMinor, 200000);
        expect(short.expenseByCategory.first.totalMinor, 150000);
        expect(short.monthlyTrend.length, 6);
        expect(short.monthlyTrend.last.expenseMinor, 200000);
        expect(short.monthlyTrend[4].expenseMinor, 250000);

        final long = await service.build(
          DateRange(LocalDate(2026, 1, 1), LocalDate(2026, 3, 31)),
          'LKR',
        );
        expect(long.granularity, ReportGranularity.month);
        expect(
          long.cashFlow.map((p) => (p.incomeMinor, p.expenseMinor)).toList(),
          [(10000000, 0), (0, 250000), (0, 200000)],
        );
        expect(long.totals.netMinor, 10000000 - 450000);
      },
    );

    test('CSV export escapes fields, blocks formulas and hides notes by default', () async {
      final cash = await data.account(name: 'Cash, wallet', opening: 0);
      await data.expense(
        cash,
        125050,
        description: '=HYPERLINK("x")',
        category: 'food',
      );
      final rows = await data.transactions.filtered(const TransactionFilter());
      final l10n = lookupAppLocalizations(const Locale('en'));
      final csv = const CsvExporter().build(rows, l10n);
      expect(csv.startsWith('﻿'), isTrue);
      final lines = csv.substring(1).trim().split('\n');
      expect(
        lines.first,
        'Date,Time,Type,Counts as,Category,Account,To account,Amount,Currency',
      );
      expect(lines[1], contains('"Cash, wallet"'));
      expect(lines[1], contains('-1250.50'));
      expect(
        csv,
        isNot(contains('HYPERLINK')),
        reason: 'notes excluded by default',
      );

      final withNotes = const CsvExporter().build(
        rows,
        l10n,
        options: const CsvExportOptions(includeNotes: true),
      );
      expect(withNotes, contains("\"'=HYPERLINK(\"\"x\"\")\""));
      expect(CsvExporter.escape('-12.00', text: false), '-12.00');
      expect(CsvExporter.escape('a"b'), '"a""b"');
    });
  });
}
