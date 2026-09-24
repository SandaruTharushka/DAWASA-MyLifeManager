import '../core/database/enums.dart';

/// Central list of route locations.
abstract final class Routes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const money = '/money';
  static const planner = '/planner';
  static const reports = '/reports';
  static const settings = '/settings';

  static String moneyTab(String tab) => '$money?tab=$tab';
  static String plannerTab(String tab) => '$planner?tab=$tab';

  // Transactions
  static String newTransaction({
    TransactionType type = TransactionType.expense,
    String? accountId,
    String? duplicateOf,
  }) {
    final params = <String, String>{
      'type': type.name,
      'account': ?accountId,
      'duplicate': ?duplicateOf,
    };
    return Uri(path: '/transactions/new', queryParameters: params).toString();
  }

  static String transaction(String id) => '/transactions/$id';
  static String editTransaction(String id) => '/transactions/$id/edit';
  static const categories = '/categories';
  static const recurring = '/recurring';

  // Accounts
  static const newAccount = '/accounts/new';
  static String account(String id) => '/accounts/$id';
  static String editAccount(String id) => '/accounts/$id/edit';

  // Budgets
  static const newBudget = '/budgets/new';
  static String editBudget(String id) => '/budgets/$id/edit';

  // Bills
  static const newBill = '/bills/new';
  static String bill(String id) => '/bills/$id';
  static String editBill(String id) => '/bills/$id/edit';

  // Savings & loans
  static const newSavingsGoal = '/savings/new';
  static String savingsGoal(String id) => '/savings/$id';
  static String editSavingsGoal(String id) => '/savings/$id/edit';
  static const newLoan = '/loans/new';
  static String loan(String id) => '/loans/$id';
  static String editLoan(String id) => '/loans/$id/edit';

  // Habits & events
  static const newHabit = '/habits/new';
  static String editHabit(String id) => '/habits/$id/edit';
  static const newEvent = '/events/new';
  static String editEvent(String id) => '/events/$id/edit';

  // Reports
  static const exportCsv = '/reports/export';

  // Planner
  static const newTask = '/tasks/new';
  static String newTaskOn(String isoDate) => '/tasks/new?date=$isoDate';
  static String editTask(String id) => '/tasks/$id/edit';
  static String shoppingList(String id) => '/shopping/$id';

  // Settings sub pages
  static const privacy = '/settings/privacy';
  static const backup = '/settings/backup';
  static const restore = '/settings/restore';
  static String pinSetup(String mode) => '/settings/pin?mode=$mode';
}
