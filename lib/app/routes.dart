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

  // Planner
  static const newTask = '/tasks/new';

  // Settings sub pages
  static const privacy = '/settings/privacy';
}
