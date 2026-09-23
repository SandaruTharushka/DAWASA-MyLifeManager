import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../data/loan_repository.dart';

final loanRepositoryProvider = Provider<LoanRepository>(
  (ref) => LoanRepository(
    ref.watch(databaseProvider),
    ref.watch(transactionRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  ),
);

final loansProvider = StreamProvider<List<LoanView>>(
  (ref) => ref.watch(loanRepositoryProvider).watchLoans(),
);

final loanProvider = StreamProvider.family<LoanView?, String>(
  (ref, id) => ref.watch(loanRepositoryProvider).watchLoan(id),
);

final loanRepaymentsProvider =
    StreamProvider.family<List<LoanRepaymentRow>, String>(
      (ref, id) => ref.watch(loanRepositoryProvider).watchRepayments(id),
    );
