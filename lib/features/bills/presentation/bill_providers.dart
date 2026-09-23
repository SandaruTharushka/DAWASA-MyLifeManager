import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../data/bill_repository.dart';

final billRepositoryProvider = Provider<BillRepository>(
  (ref) => BillRepository(
    ref.watch(databaseProvider),
    ref.watch(transactionRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  ),
);

final billsProvider = StreamProvider<List<BillView>>(
  (ref) => ref.watch(billRepositoryProvider).watchAll(),
);

final billByIdProvider = StreamProvider.family<BillRow?, String>(
  (ref, id) => ref.watch(billRepositoryProvider).watchById(id),
);

final billPaymentsProvider =
    StreamProvider.family<List<BillPaymentRow>, String>(
      (ref, id) => ref.watch(billRepositoryProvider).watchPayments(id),
    );

/// Active bills due within the next 7 days (or overdue), for the dashboard.
final upcomingBillsProvider = Provider<AsyncValue<List<BillView>>>((ref) {
  final today = ref.watch(todayProvider);
  return ref
      .watch(billsProvider)
      .whenData(
        (bills) =>
            bills
                .where(
                  (b) =>
                      b.bill.isActive &&
                      !b.bill.nextDueDate.isAfter(today.addDays(7)),
                )
                .toList()
              ..sort(
                (a, b) => a.bill.nextDueDate.compareTo(b.bill.nextDueDate),
              ),
      );
});
