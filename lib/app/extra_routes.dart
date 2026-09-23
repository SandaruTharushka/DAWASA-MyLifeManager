import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/time/local_date.dart';
import '../features/bills/presentation/bill_detail_screen.dart';
import '../features/bills/presentation/bill_form_screen.dart';
import '../features/budgets/presentation/budget_form_screen.dart';
import '../features/shopping/presentation/shopping_list_screen.dart';
import '../features/tasks/presentation/task_form_screen.dart';
import 'routes.dart';

typedef PageRouteFactory = GoRoute Function(
  String path,
  Widget Function(GoRouterState state) builder,
);

/// Full-screen routes of the planner, budgets, bills, savings, loans,
/// reports, security, backup and update modules.
List<GoRoute> extraRoutes(PageRouteFactory page) => [
  page(Routes.newBudget, (_) => const BudgetFormScreen()),
  page(
    '/budgets/:id/edit',
    (s) => BudgetFormScreen(budgetId: s.pathParameters['id']),
  ),
  page(Routes.newBill, (_) => const BillFormScreen()),
  page('/bills/:id', (s) => BillDetailScreen(billId: s.pathParameters['id']!)),
  page(
    '/bills/:id/edit',
    (s) => BillFormScreen(billId: s.pathParameters['id']),
  ),
  page(
    Routes.newTask,
    (s) => TaskFormScreen(
      initialDate: LocalDate.tryParse(s.uri.queryParameters['date']),
    ),
  ),
  page(
    '/tasks/:id/edit',
    (s) => TaskFormScreen(taskId: s.pathParameters['id']),
  ),
  page(
    '/shopping/:id',
    (s) => ShoppingListScreen(listId: s.pathParameters['id']!),
  ),
];
