import 'package:dawasa/core/database/app_database.dart';
import 'package:dawasa/core/database/connection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('database opens and seeds default categories', () async {
    final db = AppDatabase(openInMemoryConnection());
    final categories = await db.select(db.transactionCategories).get();
    expect(categories.length, 18);
    final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(fk.data.values.first, 1);
    await db.close();
  });
}
