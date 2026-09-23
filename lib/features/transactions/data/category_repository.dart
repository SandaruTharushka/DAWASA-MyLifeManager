import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class DuplicateCategoryException implements Exception {
  const DuplicateCategoryException();
}

class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$TransactionCategoriesTable, TxCategory> _query(
    CategoryKind? kind, {
    bool includeArchived = false,
  }) {
    final q = _db.select(_db.transactionCategories);
    q.where((c) {
      Expression<bool> e = const Constant(true);
      if (kind != null) e = e & c.kind.equalsValue(kind);
      if (!includeArchived) e = e & c.isArchived.equals(false);
      return e;
    });
    q.orderBy([
      (c) => OrderingTerm.asc(c.sortOrder),
      (c) => OrderingTerm.asc(c.createdAt),
    ]);
    return q;
  }

  Stream<List<TxCategory>> watch(
    CategoryKind? kind, {
    bool includeArchived = false,
  }) => _query(kind, includeArchived: includeArchived).watch();

  Future<List<TxCategory>> list(
    CategoryKind? kind, {
    bool includeArchived = false,
  }) => _query(kind, includeArchived: includeArchived).get();

  Future<TxCategory?> byId(String id) => (_db.select(
    _db.transactionCategories,
  )..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<TxCategory?> bySystemKey(CategoryKind kind, String key) =>
      (_db.select(_db.transactionCategories)
            ..where((c) => c.kind.equalsValue(kind) & c.systemKey.equals(key)))
          .getSingleOrNull();

  Future<void> _ensureUniqueName(
    CategoryKind kind,
    String name, {
    String? exceptId,
  }) async {
    final existing = await list(kind, includeArchived: true);
    final lower = name.trim().toLowerCase();
    final clash = existing.any(
      (c) => c.id != exceptId && (c.name?.trim().toLowerCase() == lower),
    );
    if (clash) throw const DuplicateCategoryException();
  }

  Future<String> create({
    required CategoryKind kind,
    required String name,
    required String iconKey,
    required int colorValue,
    String? id,
  }) async {
    await _ensureUniqueName(kind, name);
    final categoryId = id ?? newId();
    final max = _db.transactionCategories.sortOrder.max();
    final row = await (_db.selectOnly(
      _db.transactionCategories,
    )..addColumns([max])).getSingle();
    await _db
        .into(_db.transactionCategories)
        .insert(
          TransactionCategoriesCompanion.insert(
            id: Value(categoryId),
            kind: kind,
            name: Value(name.trim()),
            iconKey: Value(iconKey),
            colorValue: Value(colorValue),
            sortOrder: Value((row.read(max) ?? 0) + 1),
          ),
        );
    return categoryId;
  }

  /// Updates name/icon/colour. For built-in categories a name overrides the
  /// localized label; passing null keeps the localized label.
  Future<void> update(
    String id, {
    required String? name,
    required String iconKey,
    required int colorValue,
  }) async {
    final category = await byId(id);
    if (category == null) return;
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      await _ensureUniqueName(category.kind, trimmed, exceptId: id);
    }
    await (_db.update(
      _db.transactionCategories,
    )..where((c) => c.id.equals(id))).write(
      TransactionCategoriesCompanion(
        name: Value(
          (trimmed == null || trimmed.isEmpty) && category.systemKey != null
              ? null
              : trimmed,
        ),
        iconKey: Value(iconKey),
        colorValue: Value(colorValue),
        updatedAt: Value(nowUtc()),
      ),
    );
  }

  Future<void> setArchived(String id, {required bool archived}) async {
    await (_db.update(
      _db.transactionCategories,
    )..where((c) => c.id.equals(id))).write(
      TransactionCategoriesCompanion(
        isArchived: Value(archived),
        updatedAt: Value(nowUtc()),
      ),
    );
  }
}
