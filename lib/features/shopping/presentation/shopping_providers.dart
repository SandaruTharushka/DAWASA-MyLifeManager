import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../data/shopping_repository.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => ShoppingRepository(
    ref.watch(databaseProvider),
    ref.watch(transactionRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  ),
);

final shoppingListsProvider = StreamProvider<List<ShoppingListSummary>>(
  (ref) => ref.watch(shoppingRepositoryProvider).watchLists(),
);

final shoppingListProvider = StreamProvider.family<ShoppingListRow?, String>(
  (ref, id) => ref.watch(shoppingRepositoryProvider).watchList(id),
);

final shoppingItemsProvider =
    StreamProvider.family<List<ShoppingItemRow>, String>(
      (ref, id) => ref.watch(shoppingRepositoryProvider).watchItems(id),
    );
