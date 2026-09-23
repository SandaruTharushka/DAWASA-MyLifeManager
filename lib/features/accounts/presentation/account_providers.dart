import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../data/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(databaseProvider)),
);

/// All accounts (including archived) with computed balances.
final accountBalancesProvider = StreamProvider<List<AccountBalance>>(
  (ref) => ref.watch(accountRepositoryProvider).watchBalances(),
);

/// Active accounts for pickers.
final activeAccountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountRepositoryProvider).watchAccounts(),
);

final accountByIdProvider = StreamProvider.family<Account?, String>(
  (ref, id) => ref.watch(accountRepositoryProvider).watchById(id),
);

/// Summary of the "available balance" shown on the dashboard.
class BalanceSummary {
  const BalanceSummary({
    required this.totalMinor,
    required this.currencyCode,
    required this.hasOtherCurrencies,
  });

  final int totalMinor;
  final String currencyCode;
  final bool hasOtherCurrencies;
}

/// Total of active accounts included in the total, in the user's currency.
final balanceSummaryProvider = Provider<AsyncValue<BalanceSummary>>((ref) {
  final currency = ref.watch(currencyProvider).code;
  return ref.watch(accountBalancesProvider).whenData((balances) {
    var total = 0;
    var others = false;
    for (final b in balances) {
      if (b.account.isArchived || !b.account.includeInTotal) continue;
      if (b.account.currencyCode == currency) {
        total += b.balanceMinor;
      } else {
        others = true;
      }
    }
    return BalanceSummary(
      totalMinor: total,
      currencyCode: currency,
      hasOtherCurrencies: others,
    );
  });
});
