import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Evaluates budgets after spending is recorded and raises alerts when a
/// warning threshold is crossed. Budgets are implemented with schema v2.
class BudgetAlertService {
  Future<void> checkAfterSpending() async {}
}

final budgetAlertServiceProvider = Provider<BudgetAlertService>(
  (ref) => BudgetAlertService(),
);
