import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/platform/data_paths.dart';
import '../../../core/providers.dart';
import '../../../core/time/date_range.dart';
import '../../../core/time/local_date.dart';
import '../data/attachment_store.dart';
import '../data/category_repository.dart';
import '../data/recurring_repository.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction_models.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(databaseProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(databaseProvider)),
);

final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => RecurringRepository(
    ref.watch(databaseProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);

final attachmentStoreProvider = Provider<AttachmentStore>(
  (ref) => AttachmentStore(
    ref.watch(databaseProvider),
    ref.watch(dataPathsProvider).dataDirectory,
  ),
);

/// Active categories of a kind for pickers.
final categoriesProvider =
    StreamProvider.family<List<TxCategory>, CategoryKind>(
      (ref, kind) => ref.watch(categoryRepositoryProvider).watch(kind),
    );

/// All categories including archived ones, for management screens.
final allCategoriesProvider =
    StreamProvider.family<List<TxCategory>, CategoryKind>(
      (ref, kind) => ref
          .watch(categoryRepositoryProvider)
          .watch(kind, includeArchived: true),
    );

final recentTransactionsProvider = StreamProvider<List<TransactionView>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchRecent(limit: 6),
);

final transactionByIdProvider = StreamProvider.family<TransactionView?, String>(
  (ref, id) => ref.watch(transactionRepositoryProvider).watchById(id),
);

/// Query key for a paginated list.
class TransactionQuery {
  const TransactionQuery(this.filter, this.limit);

  final TransactionFilter filter;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is TransactionQuery &&
      other.filter == filter &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(filter, limit);
}

final transactionListProvider =
    StreamProvider.family<List<TransactionView>, TransactionQuery>(
      (ref, q) => ref
          .watch(transactionRepositoryProvider)
          .watchFiltered(q.filter, limit: q.limit),
    );

/// Totals for today in the user's currency.
final todayTotalsProvider = StreamProvider<PeriodTotals>((ref) {
  final today = ref.watch(todayProvider);
  final currency = ref.watch(currencyProvider).code;
  return ref
      .watch(transactionRepositoryProvider)
      .watchTotals(DateRange.singleDay(today), currencyCode: currency);
});

/// Spending of the last seven days (oldest first).
final last7DaysSpendingProvider = StreamProvider<Map<LocalDate, int>>((ref) {
  final today = ref.watch(todayProvider);
  final currency = ref.watch(currencyProvider).code;
  return ref
      .watch(transactionRepositoryProvider)
      .watchDailyTotals(DateRange.lastDays(today, 7), currencyCode: currency);
});

final recurringRulesProvider = StreamProvider<List<RecurringRuleView>>(
  (ref) => ref.watch(recurringRepositoryProvider).watchAll(),
);
