import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../transactions/data/category_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_models.dart';

/// Summary of a list for the overview screen.
class ShoppingListSummary {
  const ShoppingListSummary({
    required this.list,
    required this.itemCount,
    required this.purchasedCount,
    required this.estimatedTotalMinor,
    required this.actualTotalMinor,
    required this.unrecordedPurchasedCount,
  });

  final ShoppingListRow list;
  final int itemCount;
  final int purchasedCount;
  final int estimatedTotalMinor;
  final int actualTotalMinor;
  final int unrecordedPurchasedCount;
}

/// Totals of a list, computed from its items.
class ShoppingTotals {
  const ShoppingTotals({
    required this.estimatedMinor,
    required this.actualMinor,
    required this.unrecordedActualMinor,
    required this.unrecordedCount,
    required this.missingPriceCount,
  });

  factory ShoppingTotals.of(List<ShoppingItemRow> items) {
    var estimated = 0, actual = 0, unrecorded = 0, unrecordedCount = 0;
    var missing = 0;
    for (final i in items) {
      estimated += i.estimatedPriceMinor ?? 0;
      if (i.isPurchased) {
        actual += i.actualPriceMinor ?? 0;
        if (i.transactionId == null) {
          unrecordedCount++;
          if (i.actualPriceMinor == null) {
            missing++;
          } else {
            unrecorded += i.actualPriceMinor!;
          }
        }
      }
    }
    return ShoppingTotals(
      estimatedMinor: estimated,
      actualMinor: actual,
      unrecordedActualMinor: unrecorded,
      unrecordedCount: unrecordedCount,
      missingPriceCount: missing,
    );
  }

  /// Sum of estimated prices; informational only.
  final int estimatedMinor;

  /// Sum of actual prices of purchased items.
  final int actualMinor;

  /// Purchased, priced items not yet recorded as an expense.
  final int unrecordedActualMinor;
  final int unrecordedCount;

  /// Purchased items without an actual price.
  final int missingPriceCount;
}

class MissingActualPriceException implements Exception {
  const MissingActualPriceException(this.count);

  final int count;
}

class NothingToRecordException implements Exception {
  const NothingToRecordException();
}

class ShoppingItemDraft {
  const ShoppingItemDraft({
    required this.id,
    required this.listId,
    required this.name,
    this.quantityMilli = 1000,
    this.unit = 'pcs',
    this.estimatedPriceMinor,
    this.actualPriceMinor,
  });

  final String id;
  final String listId;
  final String name;
  final int quantityMilli;
  final String unit;
  final int? estimatedPriceMinor;
  final int? actualPriceMinor;
}

class ShoppingRepository {
  ShoppingRepository(this._db, this._transactions, this._categories);

  final AppDatabase _db;
  final TransactionRepository _transactions;
  final CategoryRepository _categories;

  Stream<List<ShoppingListSummary>> watchLists() {
    final listsQuery = _db.select(_db.shoppingLists)
      ..orderBy([
        (l) => OrderingTerm.asc(l.isCompleted),
        (l) => OrderingTerm.desc(l.createdAt),
      ]);
    return listsQuery.watch().asyncMap((lists) async {
      final items = await _db.select(_db.shoppingItems).get();
      final byList = <String, List<ShoppingItemRow>>{};
      for (final i in items) {
        byList.putIfAbsent(i.listId, () => []).add(i);
      }
      return [
        for (final l in lists)
          () {
            final its = byList[l.id] ?? const <ShoppingItemRow>[];
            final totals = ShoppingTotals.of(its);
            return ShoppingListSummary(
              list: l,
              itemCount: its.length,
              purchasedCount: its.where((i) => i.isPurchased).length,
              estimatedTotalMinor: totals.estimatedMinor,
              actualTotalMinor: totals.actualMinor,
              unrecordedPurchasedCount: totals.unrecordedCount,
            );
          }(),
      ];
    });
  }

  Stream<ShoppingListRow?> watchList(String id) => (_db.select(
    _db.shoppingLists,
  )..where((l) => l.id.equals(id))).watchSingleOrNull();

  Stream<List<ShoppingItemRow>> watchItems(String listId) =>
      (_db.select(_db.shoppingItems)
            ..where((i) => i.listId.equals(listId))
            ..orderBy([
              (i) => OrderingTerm.asc(i.isPurchased),
              (i) => OrderingTerm.asc(i.sortOrder),
              (i) => OrderingTerm.asc(i.createdAt),
            ]))
          .watch();

  Future<List<ShoppingItemRow>> items(String listId) => (_db.select(
    _db.shoppingItems,
  )..where((i) => i.listId.equals(listId))).get();

  Future<String> createList(String name, {String? id}) async {
    final listId = id ?? newId();
    await _db
        .into(_db.shoppingLists)
        .insert(
          ShoppingListsCompanion.insert(id: Value(listId), name: name.trim()),
          mode: InsertMode.insertOrIgnore,
        );
    return listId;
  }

  Future<void> renameList(String id, String name) =>
      (_db.update(_db.shoppingLists)..where((l) => l.id.equals(id))).write(
        ShoppingListsCompanion(
          name: Value(name.trim()),
          updatedAt: Value(nowUtc()),
        ),
      );

  Future<void> setListCompleted(String id, {required bool completed}) =>
      (_db.update(_db.shoppingLists)..where((l) => l.id.equals(id))).write(
        ShoppingListsCompanion(
          isCompleted: Value(completed),
          completedAt: Value(completed ? nowUtc() : null),
          updatedAt: Value(nowUtc()),
        ),
      );

  /// Deletes the list and its items. Recorded expenses remain.
  Future<void> deleteList(String id) =>
      (_db.delete(_db.shoppingLists)..where((l) => l.id.equals(id))).go();

  Future<void> saveItem(ShoppingItemDraft d) async {
    final existing = await (_db.select(
      _db.shoppingItems,
    )..where((i) => i.id.equals(d.id))).getSingleOrNull();
    if (existing?.transactionId != null) {
      // Recorded items keep their price so the expense stays consistent.
      await (_db.update(
        _db.shoppingItems,
      )..where((i) => i.id.equals(d.id))).write(
        ShoppingItemsCompanion(
          name: Value(d.name.trim()),
          quantityMilli: Value(d.quantityMilli),
          unit: Value(d.unit),
          updatedAt: Value(nowUtc()),
        ),
      );
      return;
    }
    final companion = ShoppingItemsCompanion.insert(
      id: Value(d.id),
      listId: d.listId,
      name: d.name.trim(),
      quantityMilli: Value(d.quantityMilli),
      unit: Value(d.unit),
      estimatedPriceMinor: Value(d.estimatedPriceMinor),
      actualPriceMinor: Value(d.actualPriceMinor),
      updatedAt: Value(nowUtc()),
    );
    if (existing == null) {
      await _db.into(_db.shoppingItems).insert(companion);
    } else {
      await (_db.update(_db.shoppingItems)..where((i) => i.id.equals(d.id)))
          .write(companion.copyWith(createdAt: const Value.absent()));
    }
  }

  Future<void> setPurchased(
    String itemId, {
    required bool purchased,
    int? actualPriceMinor,
  }) async {
    final item = await (_db.select(
      _db.shoppingItems,
    )..where((i) => i.id.equals(itemId))).getSingleOrNull();
    if (item == null || item.transactionId != null) return;
    await (_db.update(
      _db.shoppingItems,
    )..where((i) => i.id.equals(itemId))).write(
      ShoppingItemsCompanion(
        isPurchased: Value(purchased),
        actualPriceMinor: actualPriceMinor == null
            ? const Value.absent()
            : Value(actualPriceMinor),
        updatedAt: Value(nowUtc()),
      ),
    );
  }

  Future<void> deleteItem(String itemId) =>
      (_db.delete(_db.shoppingItems)..where((i) => i.id.equals(itemId))).go();

  /// Records every purchased item that is not yet recorded as ONE expense
  /// (category "Shopping") and stamps the items with that expense, all in a
  /// single database transaction. Items can therefore never be counted
  /// twice, and estimated prices are never used.
  Future<int> recordPurchases({
    required String listId,
    required String transactionId,
    required String accountId,
    required DateTime occurredAt,
    required String currencyCode,
  }) {
    return _db.transaction(() async {
      final existing = await _transactions.byId(transactionId);
      if (existing != null) return existing.transaction.amountMinor;

      final list = await (_db.select(
        _db.shoppingLists,
      )..where((l) => l.id.equals(listId))).getSingle();
      final pending = (await items(listId))
          .where((i) => i.isPurchased && i.transactionId == null)
          .toList();
      if (pending.isEmpty) throw const NothingToRecordException();
      final missing = pending.where((i) => i.actualPriceMinor == null).length;
      if (missing > 0) throw MissingActualPriceException(missing);
      final total = pending.fold<int>(0, (s, i) => s + i.actualPriceMinor!);
      if (total <= 0) throw const NothingToRecordException();

      final category = await _categories.bySystemKey(
        CategoryKind.expense,
        'shopping',
      );
      await _transactions.insertWithinTransaction(
        TransactionDraft(
          id: transactionId,
          type: TransactionType.expense,
          amountMinor: total,
          currencyCode: currencyCode,
          accountId: accountId,
          categoryId: category?.id,
          occurredAt: occurredAt,
          description: list.name,
          note: pending.map((i) => i.name).join(', '),
          source: TransactionSource.shopping,
          sourceRefId: listId,
        ),
      );
      await (_db.update(_db.shoppingItems)
            ..where((i) => i.id.isIn(pending.map((p) => p.id))))
          .write(ShoppingItemsCompanion(transactionId: Value(transactionId)));
      return total;
    });
  }
}
