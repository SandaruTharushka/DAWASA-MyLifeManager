import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../data/savings_repository.dart';

final savingsRepositoryProvider = Provider<SavingsRepository>(
  (ref) => SavingsRepository(
    ref.watch(databaseProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);

final savingsGoalsProvider = StreamProvider<List<SavingsGoalView>>(
  (ref) => ref.watch(savingsRepositoryProvider).watchGoals(),
);

final savingsGoalProvider = StreamProvider.family<SavingsGoalView?, String>(
  (ref, id) => ref.watch(savingsRepositoryProvider).watchGoal(id),
);

final savingsMovementsProvider =
    StreamProvider.family<List<SavingsMovementRow>, String>(
      (ref, id) => ref.watch(savingsRepositoryProvider).watchMovements(id),
    );
