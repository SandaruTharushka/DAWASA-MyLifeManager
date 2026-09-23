import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/finance/transaction_rules.dart';
import '../../../core/time/local_date.dart';

/// An account together with its computed balance.
class AccountBalance {
  const AccountBalance(this.account, this.balanceMinor);

  final Account account;
  final int balanceMinor;
}

class AccountInUseException implements Exception {
  const AccountInUseException();
}

/// Balances are never stored: they are always computed as
/// `opening balance + Σ(signed transaction amounts)`, so editing or deleting
/// a transaction can never leave a balance inconsistent.
class AccountRepository {
  AccountRepository(this._db);

  final AppDatabase _db;

  static String _balanceSelect({String where = ''}) {
    final signed = TransactionRules.signedAmountSql('t');
    return '''
SELECT a.*,
  a.opening_balance_minor
  + COALESCE((SELECT SUM($signed) FROM transactions t WHERE t.account_id = a.id), 0)
  + COALESCE((SELECT SUM(t.amount_minor) FROM transactions t
              WHERE t.to_account_id = a.id AND t.type = 'transfer'), 0)
  AS balance
FROM accounts a
$where
ORDER BY a.is_archived ASC, a.sort_order ASC, a.created_at ASC''';
  }

  List<AccountBalance> _mapBalances(List<QueryRow> rows) => [
    for (final row in rows)
      AccountBalance(_db.accounts.map(row.data), row.read<int>('balance')),
  ];

  Stream<List<AccountBalance>> watchBalances({bool includeArchived = true}) {
    return _db
        .customSelect(
          _balanceSelect(
            where: includeArchived ? '' : 'WHERE a.is_archived = 0',
          ),
          readsFrom: {_db.accounts, _db.transactions},
        )
        .watch()
        .map(_mapBalances);
  }

  Future<List<AccountBalance>> balances({bool includeArchived = true}) async {
    final rows = await _db
        .customSelect(
          _balanceSelect(
            where: includeArchived ? '' : 'WHERE a.is_archived = 0',
          ),
          readsFrom: {_db.accounts, _db.transactions},
        )
        .get();
    return _mapBalances(rows);
  }

  Future<int> balanceOf(String accountId) async {
    final rows = await _db
        .customSelect(
          _balanceSelect(where: 'WHERE a.id = ?'),
          variables: [Variable.withString(accountId)],
          readsFrom: {_db.accounts, _db.transactions},
        )
        .get();
    if (rows.isEmpty) throw StateError('Unknown account $accountId');
    return rows.first.read<int>('balance');
  }

  Stream<List<Account>> watchAccounts({bool includeArchived = false}) {
    final query = _db.select(_db.accounts)
      ..orderBy([
        (a) => OrderingTerm.asc(a.sortOrder),
        (a) => OrderingTerm.asc(a.createdAt),
      ]);
    if (!includeArchived) query.where((a) => a.isArchived.equals(false));
    return query.watch();
  }

  Future<List<Account>> accounts({bool includeArchived = false}) {
    final query = _db.select(_db.accounts)
      ..orderBy([
        (a) => OrderingTerm.asc(a.sortOrder),
        (a) => OrderingTerm.asc(a.createdAt),
      ]);
    if (!includeArchived) query.where((a) => a.isArchived.equals(false));
    return query.get();
  }

  Future<Account?> byId(String id) => (_db.select(
    _db.accounts,
  )..where((a) => a.id.equals(id))).getSingleOrNull();

  Stream<Account?> watchById(String id) => (_db.select(
    _db.accounts,
  )..where((a) => a.id.equals(id))).watchSingleOrNull();

  Future<String> create({
    String? id,
    required String name,
    required AccountType type,
    required String currencyCode,
    int openingBalanceMinor = 0,
    LocalDate? openingDate,
    bool includeInTotal = true,
    int? colorValue,
  }) async {
    final accountId = id ?? newId();
    final maxOrder = await _maxSortOrder();
    await _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: Value(accountId),
            name: name.trim(),
            type: type,
            currencyCode: Value(currencyCode),
            openingBalanceMinor: Value(openingBalanceMinor),
            openingDate: Value(openingDate),
            includeInTotal: Value(includeInTotal),
            colorValue: Value(colorValue),
            sortOrder: Value(maxOrder + 1),
          ),
        );
    return accountId;
  }

  Future<int> _maxSortOrder() async {
    final max = _db.accounts.sortOrder.max();
    final row = await (_db.selectOnly(
      _db.accounts,
    )..addColumns([max])).getSingle();
    return row.read(max) ?? 0;
  }

  Future<void> update(
    String id, {
    required String name,
    required AccountType type,
    required int openingBalanceMinor,
    required bool includeInTotal,
    String? currencyCode,
  }) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        name: Value(name.trim()),
        type: Value(type),
        openingBalanceMinor: Value(openingBalanceMinor),
        includeInTotal: Value(includeInTotal),
        currencyCode: currencyCode == null
            ? const Value.absent()
            : Value(currencyCode),
        updatedAt: Value(nowUtc()),
      ),
    );
  }

  Future<bool> hasTransactions(String id) async {
    final count = _db.transactions.id.count();
    final row =
        await (_db.selectOnly(_db.transactions)
              ..addColumns([count])
              ..where(
                _db.transactions.accountId.equals(id) |
                    _db.transactions.toAccountId.equals(id),
              ))
            .getSingle();
    return (row.read(count) ?? 0) > 0;
  }

  Future<void> setArchived(String id, {required bool archived}) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        isArchived: Value(archived),
        updatedAt: Value(nowUtc()),
      ),
    );
  }

  /// Deletes an account that has no transactions. Accounts with history must
  /// be archived instead so that balances and reports stay correct.
  Future<void> delete(String id) async {
    if (await hasTransactions(id)) throw const AccountInUseException();
    await (_db.delete(_db.accounts)..where((a) => a.id.equals(id))).go();
  }

  /// Records a user-confirmed balance correction so that the computed balance
  /// equals [actualBalanceMinor]. Returns the created transaction id, or null
  /// when no correction was necessary.
  Future<String?> correctBalance({
    required String accountId,
    required int actualBalanceMinor,
    required DateTime occurredAt,
    String? note,
    String? transactionId,
  }) {
    return _db.transaction(() async {
      final account = await byId(accountId);
      if (account == null) throw StateError('Unknown account $accountId');
      final current = await balanceOf(accountId);
      final diff = actualBalanceMinor - current;
      if (diff == 0) return null;
      final id = transactionId ?? newId();
      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: Value(id),
              type: diff > 0
                  ? TransactionType.adjustmentIn
                  : TransactionType.adjustmentOut,
              amountMinor: diff.abs(),
              currencyCode: Value(account.currencyCode),
              accountId: accountId,
              occurredAt: occurredAt.toUtc(),
              localDate: LocalDate.fromDateTime(occurredAt),
              note: Value(note),
            ),
          );
      return id;
    });
  }
}
