import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/time/local_date.dart';
import '../features/bills/presentation/bill_detail_screen.dart';
import '../features/bills/presentation/bill_form_screen.dart';
import '../features/budgets/presentation/budget_form_screen.dart';
import '../features/events/presentation/event_screens.dart';
import '../features/habits/presentation/habit_screens.dart';
import '../features/loans/presentation/loan_screens.dart';
import '../features/savings/presentation/savings_screens.dart';
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
  page(Routes.newSavingsGoal, (_) => const SavingsGoalFormScreen()),
  page(
    '/savings/:id',
    (s) => SavingsGoalDetailScreen(goalId: s.pathParameters['id']!),
  ),
  page(
    '/savings/:id/edit',
    (s) => SavingsGoalFormScreen(goalId: s.pathParameters['id']),
  ),
  page(Routes.newLoan, (_) => const LoanFormScreen()),
  page('/loans/:id', (s) => LoanDetailScreen(loanId: s.pathParameters['id']!)),
  page(
    '/loans/:id/edit',
    (s) => LoanFormScreen(loanId: s.pathParameters['id']),
  ),
  page(Routes.newHabit, (_) => const HabitFormScreen()),
  page(
    '/habits/:id/edit',
    (s) => HabitFormScreen(habitId: s.pathParameters['id']),
  ),
  page(
    Routes.newEvent,
    (s) => EventFormScreen(
      initialDate: LocalDate.tryParse(s.uri.queryParameters['date']),
    ),
  ),
  page(
    '/events/:id/edit',
    (s) => EventFormScreen(eventId: s.pathParameters['id']),
  ),
];
