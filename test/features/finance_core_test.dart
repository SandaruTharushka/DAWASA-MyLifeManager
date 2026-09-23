import 'package:dawasa/core/database/app_database.dart';
import 'package:dawasa/core/finance/transaction_rules.dart';
import 'package:dawasa/core/time/date_range.dart';
import 'package:dawasa/core/time/local_date.dart';
import 'package:dawasa/core/time/recurrence.dart';
import 'package:dawasa/features/accounts/data/account_repository.dart';
import 'package:dawasa/features/budgets/domain/daily_allowance.dart';
import 'package:dawasa/features/transactions/data/recurring_repository.dart';
import 'package:dawasa/features/transactions/domain/transaction_models.dart';
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

  group('Account balances', () {
    test('opening balance plus income minus expenses', () async {
      final cash = await data.account(opening: 500000); // Rs 5,000
      await data.income(cash, 250000);
      await data.expense(cash, 12550);
      await data.expense(cash, 7450);
      expect(await data.accounts.balanceOf(cash), 500000 + 250000 - 20000);
    });

    test('transfers move money without changing income or spending', () async {
      final cash = await data.account(opening: 100000);
      final bank = await data.account(name: 'Bank', type: AccountType.bank);
      await data.transfer(cash, bank, 40000);
      expect(await data.accounts.balanceOf(cash), 60000);
      expect(await data.accounts.balanceOf(bank), 40000);

      final totals = await data.transactions.totals(
        DateRange.singleDay(LocalDate(2026, 3, 15)),
      );
      expect(totals.incomeMinor, 0);
      expect(totals.expenseMinor, 0);
      expect(totals.otherInMinor, 0);
      expect(totals.otherOutMinor, 0);

      final balances = await data.accounts.balances();
      final total = balances.fold<int>(0, (s, b) => s + b.balanceMinor);
      expect(total, 100000, reason: 'transfers keep the overall total');
    });

    test(
      'editing and deleting a transaction keeps balances consistent',
      () async {
        final cash = await data.account(opening: 100000);
        final id = await data.expense(cash, 30000);
        expect(await data.accounts.balanceOf(cash), 70000);

        final view = (await data.transactions.byId(id))!;
        await data.transactions.update(
          TransactionDraft(
            id: id,
            type: TransactionType.expense,
            amountMinor: 45000,
            currencyCode: 'LKR',
            accountId: cash,
            categoryId: view.transaction.categoryId,
            occurredAt: DateTime(2026, 3, 15, 12),
          ),
        );
        expect(await data.accounts.balanceOf(cash), 55000);

        await data.transactions.delete(id);
        expect(await data.accounts.balanceOf(cash), 100000);
      },
    );

    test(
      'moving an expense to another account updates both balances',
      () async {
        final cash = await data.account(opening: 100000);
        final bank = await data.account(name: 'Bank', opening: 100000);
        final id = await data.expense(cash, 25000);
        final view = (await data.transactions.byId(id))!;
        await data.transactions.update(
          TransactionDraft(
            id: id,
            type: TransactionType.expense,
            amountMinor: 25000,
            currencyCode: 'LKR',
            accountId: bank,
            categoryId: view.transaction.categoryId,
            occurredAt: DateTime(2026, 3, 15, 12),
          ),
        );
        expect(await data.accounts.balanceOf(cash), 100000);
        expect(await data.accounts.balanceOf(bank), 75000);
      },
    );

    test(
      'balance correction records only the difference, not income',
      () async {
        final cash = await data.account(opening: 100000);
        await data.expense(cash, 10000);
        final idUp = await data.accounts.correctBalance(
          accountId: cash,
          actualBalanceMinor: 95000,
          occurredAt: DateTime(2026, 3, 16, 8),
        );
        expect(idUp, isNotNull);
        expect(await data.accounts.balanceOf(cash), 95000);
        final up = (await data.transactions.byId(idUp!))!;
        expect(up.type, TransactionType.adjustmentIn);
        expect(up.transaction.amountMinor, 5000);

        final idDown = await data.accounts.correctBalance(
          accountId: cash,
          actualBalanceMinor: 90000,
          occurredAt: DateTime(2026, 3, 16, 9),
        );
        expect(
          (await data.transactions.byId(idDown!))!.type,
          TransactionType.adjustmentOut,
        );
        expect(await data.accounts.balanceOf(cash), 90000);

        expect(
          await data.accounts.correctBalance(
            accountId: cash,
            actualBalanceMinor: 90000,
            occurredAt: DateTime(2026, 3, 16, 10),
          ),
          isNull,
        );
        final totals = await data.transactions.totals(
          DateRange(LocalDate(2026, 3, 1), LocalDate(2026, 3, 31)),
        );
        expect(totals.incomeMinor, 0);
        expect(totals.expenseMinor, 10000);
        expect(totals.otherInMinor, 5000);
        expect(totals.otherOutMinor, 5000);
      },
    );

    test('account with history cannot be deleted, only archived', () async {
      final cash = await data.account();
      await data.expense(cash, 100);
      expect(
        () => data.accounts.delete(cash),
        throwsA(isA<AccountInUseException>()),
      );
      await data.accounts.setArchived(cash, archived: true);
      expect((await data.accounts.byId(cash))!.isArchived, isTrue);

      final empty = await data.account(name: 'Unused');
      await data.accounts.delete(empty);
      expect(await data.accounts.byId(empty), isNull);
    });

    test(
      'SQL balance matches the Dart rule for every transaction type',
      () async {
        final a = await data.account(opening: 1000);
        final b = await data.account(name: 'B', opening: 0);
        final types = TransactionType.values.where(
          (t) => !TransactionRules.requiresCategory(t),
        );
        final expected = {a: 1000, b: 0};
        var amount = 100;
        for (final type in types) {
          amount += 7;
          final isTransfer = type == TransactionType.transfer;
          await data.transactions.create(
            TransactionDraft(
              id: newId(),
              type: type,
              amountMinor: amount,
              currencyCode: 'LKR',
              accountId: a,
              toAccountId: isTransfer ? b : null,
              occurredAt: DateTime(2026, 3, 15, 12),
            ),
          );
          for (final acc in [a, b]) {
            expected[acc] =
                expected[acc]! +
                TransactionRules.balanceEffect(
                  type: type,
                  amountMinor: amount,
                  accountId: a,
                  toAccountId: isTransfer ? b : null,
                  forAccountId: acc,
                );
          }
        }
        expect(await data.accounts.balanceOf(a), expected[a]);
        expect(await data.accounts.balanceOf(b), expected[b]);
      },
    );
  });

  group('Transaction safety', () {
    test('saving the same draft twice creates exactly one record', () async {
      final cash = await data.account(opening: 10000);
      final draft = TransactionDraft(
        id: newId(),
        type: TransactionType.expense,
        amountMinor: 2500,
        currencyCode: 'LKR',
        accountId: cash,
        categoryId: await data.categoryId(CategoryKind.expense, 'food'),
        occurredAt: DateTime(2026, 3, 15, 12),
      );
      final results = await Future.wait([
        data.transactions.create(draft),
        data.transactions.create(draft),
      ]);
      expect(
        results,
        containsAll([SaveOutcome.created, SaveOutcome.alreadyExisted]),
      );
      expect(await data.transactions.count(), 1);
      expect(await data.accounts.balanceOf(cash), 7500);
    });

    test('validation rejects inconsistent transactions', () async {
      final cash = await data.account();
      final usd = await data.account(name: 'USD', currency: 'USD');
      final food = await data.categoryId(CategoryKind.expense, 'food');
      final salary = await data.categoryId(CategoryKind.income, 'salary');

      Future<void> expectError(
        TransactionDraft d,
        TransactionValidationError e,
      ) => expectLater(
        data.transactions.create(d),
        throwsA(
          isA<TransactionValidationException>().having(
            (x) => x.error,
            'error',
            e,
          ),
        ),
      );

      TransactionDraft base({
        TransactionType type = TransactionType.expense,
        int amount = 100,
        String? to,
        String? category,
        String currency = 'LKR',
        String? account,
      }) => TransactionDraft(
        id: newId(),
        type: type,
        amountMinor: amount,
        currencyCode: currency,
        accountId: account ?? cash,
        toAccountId: to,
        categoryId: category,
        occurredAt: DateTime(2026, 3, 15),
      );

      await expectError(
        base(amount: 0, category: food),
        TransactionValidationError.amountNotPositive,
      );
      await expectError(base(), TransactionValidationError.missingCategory);
      await expectError(
        base(category: salary),
        TransactionValidationError.categoryKindMismatch,
      );
      await expectError(
        base(type: TransactionType.transfer),
        TransactionValidationError.missingToAccount,
      );
      await expectError(
        base(type: TransactionType.transfer, to: cash),
        TransactionValidationError.sameAccount,
      );
      await expectError(
        base(type: TransactionType.transfer, to: usd),
        TransactionValidationError.currencyMismatch,
      );
      await expectError(
        base(category: food, to: usd),
        TransactionValidationError.unexpectedToAccount,
      );
      expect(await data.transactions.count(), 0);
    });

    test(
      'database constraints reject invalid rows even without the repository',
      () async {
        final cash = await data.account();
        expect(
          () => db
              .into(db.transactions)
              .insert(
                TransactionsCompanion.insert(
                  type: TransactionType.expense,
                  amountMinor: -5,
                  accountId: cash,
                  occurredAt: DateTime.utc(2026),
                  localDate: LocalDate(2026, 1, 1),
                ),
              ),
          throwsA(anything),
        );
        expect(
          () => db
              .into(db.transactions)
              .insert(
                TransactionsCompanion.insert(
                  type: TransactionType.expense,
                  amountMinor: 5,
                  accountId: 'missing-account',
                  occurredAt: DateTime.utc(2026),
                  localDate: LocalDate(2026, 1, 1),
                ),
              ),
          throwsA(anything),
        );
      },
    );
  });

  group('Reports queries', () {
    test('totals, daily spending and category totals', () async {
      final cash = await data.account(opening: 1000000);
      await data.income(cash, 500000, date: LocalDate(2026, 3, 1));
      await data.expense(
        cash,
        1200,
        date: LocalDate(2026, 3, 1),
        category: 'food',
      );
      await data.expense(
        cash,
        800,
        date: LocalDate(2026, 3, 2),
        category: 'food',
      );
      await data.expense(
        cash,
        5000,
        date: LocalDate(2026, 3, 2),
        category: 'transport',
      );
      await data.expense(cash, 999, date: LocalDate(2026, 4, 1));

      final march = DateRange.month(2026, 3);
      final totals = await data.transactions.totals(march);
      expect(totals.incomeMinor, 500000);
      expect(totals.expenseMinor, 7000);
      expect(totals.netMinor, 493000);

      final daily = await data.transactions.dailyTotals(
        DateRange(LocalDate(2026, 3, 1), LocalDate(2026, 3, 3)),
      );
      expect(daily.values.toList(), [1200, 5800, 0]);

      final byCategory = await data.transactions.categoryTotals(
        march,
        type: TransactionType.expense,
      );
      expect(
        byCategory.map((c) => (c.category!.systemKey, c.totalMinor)).toList(),
        [('transport', 5000), ('food', 2000)],
      );
    });

    test('search matches description, note and exact amount', () async {
      final cash = await data.account(opening: 100000);
      await data.expense(cash, 1250, description: 'Rice and dhal');
      await data.expense(cash, 700, description: '50% off_sale');
      expect(
        (await data.transactions.filtered(
          const TransactionFilter(search: 'rice'),
        )).length,
        1,
      );
      expect(
        (await data.transactions.filtered(
          const TransactionFilter(search: '12.50'),
        )).length,
        1,
      );
      expect(
        (await data.transactions.filtered(const TransactionFilter(search: '%')))
            .length,
        1,
        reason: 'LIKE wildcards are escaped',
      );
      expect(
        (await data.transactions.filtered(
          const TransactionFilter(types: {TransactionType.income}),
        )).length,
        0,
      );
    });
  });

  group('Recurring transactions', () {
    test('catch-up generation is idempotent and respects month ends', () async {
      final cash = await data.account(opening: 0);
      final repo = RecurringRepository(db, data.transactions);
      final ruleId = newId();
      final template = TransactionDraft(
        id: newId(),
        type: TransactionType.expense,
        amountMinor: 1500000,
        currencyCode: 'LKR',
        accountId: cash,
        categoryId: await data.categoryId(CategoryKind.expense, 'rent'),
        occurredAt: DateTime(2026, 1, 31, 9),
        description: 'Rent',
      );
      final created = await repo.createRule(
        ruleId: ruleId,
        template: template,
        rule: RecurrenceRule.monthly(),
        today: LocalDate(2026, 4, 10),
      );
      expect(created, 3); // Jan 31, Feb 28, Mar 31
      // Repeated creation and generation never duplicate.
      expect(
        await repo.createRule(
          ruleId: ruleId,
          template: template,
          rule: RecurrenceRule.monthly(),
          today: LocalDate(2026, 4, 10),
        ),
        0,
      );
      expect(await repo.generateDue(LocalDate(2026, 4, 10)), 0);
      await Future.wait([
        repo.generateDue(LocalDate(2026, 5, 31)),
        repo.generateDue(LocalDate(2026, 5, 31)),
      ]);
      final all = await data.transactions.filtered(const TransactionFilter());
      expect(all.map((v) => v.transaction.localDate.toIso()).toList()..sort(), [
        '2026-01-31',
        '2026-02-28',
        '2026-03-31',
        '2026-04-30',
        '2026-05-31',
      ]);
      expect(
        all.every((v) => v.transaction.source == TransactionSource.recurring),
        isTrue,
      );
      expect(await data.accounts.balanceOf(cash), -1500000 * 5);
    });

    test('paused rules do not back-fill when resumed', () async {
      final cash = await data.account();
      final repo = RecurringRepository(db, data.transactions);
      final ruleId = newId();
      await repo.createRule(
        ruleId: ruleId,
        template: TransactionDraft(
          id: newId(),
          type: TransactionType.income,
          amountMinor: 1000,
          currencyCode: 'LKR',
          accountId: cash,
          categoryId: await data.categoryId(CategoryKind.income, 'salary'),
          occurredAt: DateTime(2026, 1, 1, 9),
        ),
        rule: RecurrenceRule.daily(),
        today: LocalDate(2026, 1, 3),
      );
      expect(await data.transactions.count(), 3);
      await repo.setActive(ruleId, active: false, today: LocalDate(2026, 1, 3));
      expect(await repo.generateDue(LocalDate(2026, 1, 10)), 0);
      await repo.setActive(ruleId, active: true, today: LocalDate(2026, 1, 10));
      expect(await repo.generateDue(LocalDate(2026, 1, 10)), 1);
      expect(await data.transactions.count(), 4);
    });

    test('rules with a count end and become inactive', () async {
      final cash = await data.account();
      final repo = RecurringRepository(db, data.transactions);
      await repo.createRule(
        ruleId: newId(),
        template: TransactionDraft(
          id: newId(),
          type: TransactionType.expense,
          amountMinor: 100,
          currencyCode: 'LKR',
          accountId: cash,
          categoryId: await data.categoryId(CategoryKind.expense, 'bills'),
          occurredAt: DateTime(2026, 1, 1),
        ),
        rule: RecurrenceRule(frequency: RecurrenceFrequency.weekly, count: 2),
        today: LocalDate(2026, 12, 31),
      );
      expect(await data.transactions.count(), 2);
      final rules = await db.select(db.recurringRules).get();
      expect(rules.single.isActive, isFalse);
      expect(rules.single.nextDate, isNull);
    });
  });

  group('Daily allowance', () {
    test('explicit daily budget', () {
      final a = computeDailyAllowance(
        today: LocalDate(2026, 3, 10),
        spentTodayMinor: 30000,
        dailyBudgetMinor: 100000,
      )!;
      expect(a.remainingMinor, 70000);
      expect(a.exceeded, isFalse);
      expect(a.source, AllowanceSource.dailyBudget);
    });

    test('monthly budget spread across remaining days of different months', () {
      // February (28 days), on the 15th: 14 days left including today.
      final feb = computeDailyAllowance(
        today: LocalDate(2026, 2, 15),
        spentTodayMinor: 0,
        monthlyBudgetMinor: 2800000,
        spentThisMonthBeforeTodayMinor: 1400000,
      )!;
      expect(feb.allowanceMinor, 100000);
      // March (31 days), on the 1st.
      final mar = computeDailyAllowance(
        today: LocalDate(2026, 3, 1),
        spentTodayMinor: 0,
        monthlyBudgetMinor: 3100000,
      )!;
      expect(mar.allowanceMinor, 100000);
      // Overspent month -> zero allowance, never negative.
      final over = computeDailyAllowance(
        today: LocalDate(2026, 3, 20),
        spentTodayMinor: 500,
        monthlyBudgetMinor: 1000,
        spentThisMonthBeforeTodayMinor: 5000,
      )!;
      expect(over.allowanceMinor, 0);
      expect(over.exceeded, isTrue);
    });

    test('no budget configured', () {
      expect(
        computeDailyAllowance(today: LocalDate(2026, 3, 1), spentTodayMinor: 5),
        isNull,
      );
    });
  });
}
