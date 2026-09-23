import 'package:drift/drift.dart';

import 'app_database.dart';
import 'enums.dart';

/// Built-in category definition. Labels are localized from [key].
class DefaultCategory {
  const DefaultCategory(this.key, this.kind, this.iconKey, this.color);

  final String key;
  final CategoryKind kind;
  final String iconKey;
  final int color;
}

const List<DefaultCategory> kDefaultExpenseCategories = [
  DefaultCategory('food', CategoryKind.expense, 'restaurant', 0xFFF97316),
  DefaultCategory('transport', CategoryKind.expense, 'bus', 0xFF0EA5E9),
  DefaultCategory('shopping', CategoryKind.expense, 'shopping', 0xFFA855F7),
  DefaultCategory('bills', CategoryKind.expense, 'receipt', 0xFFEAB308),
  DefaultCategory('healthcare', CategoryKind.expense, 'health', 0xFFEF4444),
  DefaultCategory('education', CategoryKind.expense, 'school', 0xFF6366F1),
  DefaultCategory('entertainment', CategoryKind.expense, 'movie', 0xFFEC4899),
  DefaultCategory('family', CategoryKind.expense, 'family', 0xFF14B8A6),
  DefaultCategory('fuel', CategoryKind.expense, 'fuel', 0xFF78716C),
  DefaultCategory('rent', CategoryKind.expense, 'home', 0xFF8B5CF6),
  DefaultCategory('interestFees', CategoryKind.expense, 'percent', 0xFFDC2626),
  DefaultCategory('other', CategoryKind.expense, 'category', 0xFF64748B),
];

const List<DefaultCategory> kDefaultIncomeCategories = [
  DefaultCategory('salary', CategoryKind.income, 'work', 0xFF16A34A),
  DefaultCategory('business', CategoryKind.income, 'store', 0xFF0D9488),
  DefaultCategory('freelancing', CategoryKind.income, 'laptop', 0xFF2563EB),
  DefaultCategory('interest', CategoryKind.income, 'percent', 0xFF65A30D),
  DefaultCategory('gifts', CategoryKind.income, 'gift', 0xFFDB2777),
  DefaultCategory('other', CategoryKind.income, 'category', 0xFF64748B),
];

/// Inserts default data. Idempotent: existing built-in categories are kept.
class DatabaseSeeder {
  DatabaseSeeder(this.db);

  final AppDatabase db;

  Future<void> seedDefaults() async {
    await db.batch((batch) {
      var order = 0;
      for (final c in [
        ...kDefaultExpenseCategories,
        ...kDefaultIncomeCategories,
      ]) {
        batch.insert(
          db.transactionCategories,
          TransactionCategoriesCompanion.insert(
            kind: c.kind,
            systemKey: Value(c.key),
            iconKey: Value(c.iconKey),
            colorValue: Value(c.color),
            sortOrder: Value(order++),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }
}
