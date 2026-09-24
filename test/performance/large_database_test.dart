import 'dart:io';
import 'dart:math';

import 'package:dawasa/core/database/app_database.dart';
import 'package:dawasa/core/database/connection.dart';
import 'package:dawasa/core/time/date_range.dart';
import 'package:dawasa/core/time/local_date.dart';
import 'package:dawasa/features/accounts/data/account_repository.dart';
import 'package:dawasa/features/reports/data/report_service.dart';
import 'package:dawasa/features/transactions/data/category_repository.dart';
import 'package:dawasa/features/transactions/data/transaction_repository.dart';
import 'package:dawasa/features/transactions/domain/transaction_models.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Several years of heavy use, stored in a real file and opened exactly like
/// the app does (background isolate, WAL).
const int _transactions = 50000;

Future<Duration> _time(Future<void> Function() body) async {
  final watch = Stopwatch()..start();
  await body();
  return watch.elapsed;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late AppDatabase db;
  late String cash;
  late String bank;
  final expected = <String, int>{};
  final today = LocalDate(2026, 9, 24);

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('dawasa_perf');
    db = AppDatabase(
      openDatabaseConnection(File(p.join(dir.path, kDatabaseFileName))),
    );
    final accounts = AccountRepository(db);
    cash = await accounts.create(
      name: 'Cash',
      type: AccountType.cash,
      currencyCode: 'LKR',
      openingBalanceMinor: 1000000,
    );
    bank = await accounts.create(
      name: 'Bank',
      type: AccountType.bank,
      currencyCode: 'LKR',
      openingBalanceMinor: 50000000,
    );
    expected[cash] = 1000000;
    expected[bank] = 50000000;
    final categories = CategoryRepository(db);
    final food = (await categories.bySystemKey(CategoryKind.expense, 'food'))!;
    final salary = (await categories.bySystemKey(
      CategoryKind.income,
      'salary',
    ))!;

    final random = Random(42);
    final words = ['Rice & curry', 'Bus fare', 'Vegetables', 'Tea', 'Dialog'];
    final watch = Stopwatch()..start();
    await db.batch((batch) {
      for (var i = 0; i < _transactions; i++) {
        final date = today.addDays(-random.nextInt(3 * 365));
        final roll = random.nextInt(100);
        final amount = 1000 + random.nextInt(500000);
        final account = random.nextBool() ? cash : bank;
        final TransactionType type;
        String? to;
        if (roll < 85) {
          type = TransactionType.expense;
          expected[account] = expected[account]! - amount;
        } else if (roll < 95) {
          type = TransactionType.income;
          expected[account] = expected[account]! + amount;
        } else {
          type = TransactionType.transfer;
          to = account == cash ? bank : cash;
          expected[account] = expected[account]! - amount;
          expected[to] = expected[to]! + amount;
        }
        batch.insert(
          db.transactions,
          TransactionsCompanion.insert(
            id: Value('perf-$i'),
            type: type,
            amountMinor: amount,
            accountId: account,
            toAccountId: Value(to),
            categoryId: Value(
              type == TransactionType.expense
                  ? food.id
                  : type == TransactionType.income
                  ? salary.id
                  : null,
            ),
            occurredAt: date.atMinutes(9 * 60).toUtc(),
            localDate: date,
            description: Value(words[i % words.length]),
          ),
        );
      }
    });
    // ignore: avoid_print
    print('Inserted $_transactions transactions in ${watch.elapsed}');
  });

  tearDownAll(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  void report(String what, Duration d) =>
      // ignore: avoid_print
      print('${what.padRight(34)} ${d.inMilliseconds} ms');

  test('balances are exact and fast', () async {
    late List<AccountBalance> balances;
    final d = await _time(
      () async => balances = await AccountRepository(db).balances(),
    );
    report('account balances', d);
    expect({for (final b in balances) b.account.id: b.balanceMinor}, expected);
    expect(d, lessThan(const Duration(milliseconds: 1500)));
  });

  test('month totals and daily chart data', () async {
    final repo = TransactionRepository(db);
    final month = DateRange.monthOf(today);
    final d1 = await _time(() => repo.totals(month, currencyCode: 'LKR'));
    final d2 = await _time(() => repo.dailyTotals(month, currencyCode: 'LKR'));
    final d3 = await _time(
      () => repo.categoryTotals(
        month,
        type: TransactionType.expense,
        currencyCode: 'LKR',
      ),
    );
    report('month totals', d1);
    report('daily totals (month)', d2);
    report('category totals (month)', d3);
    for (final d in [d1, d2, d3]) {
      expect(d, lessThan(const Duration(milliseconds: 1000)));
    }
  });

  test('first page of the transaction list and search', () async {
    final repo = TransactionRepository(db);
    late List<TransactionView> page;
    final d1 = await _time(
      () async => page = await repo
          .watchFiltered(const TransactionFilter(), limit: 50)
          .first,
    );
    late List<TransactionView> found;
    final d2 = await _time(
      () async => found = await repo.filtered(
        const TransactionFilter(search: 'curry'),
        limit: 50,
      ),
    );
    report('first page (50 of $_transactions)', d1);
    report('search "curry"', d2);
    expect(page, hasLength(50));
    expect(found, hasLength(50));
    expect(d1, lessThan(const Duration(milliseconds: 1000)));
    expect(d2, lessThan(const Duration(milliseconds: 1500)));
  });

  test('a full-year report', () async {
    final service = ReportService(TransactionRepository(db));
    late ReportData data;
    final d = await _time(
      () async => data = await service.build(
        DateRange(LocalDate(2025, 10, 1), LocalDate(2026, 9, 30)),
        'LKR',
      ),
    );
    report('12-month report', d);
    expect(data.cashFlow, hasLength(12));
    expect(data.totals.expenseMinor, greaterThan(0));
    expect(d, lessThan(const Duration(seconds: 5)));
  });
}
