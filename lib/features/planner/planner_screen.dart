import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/l10n/l10n.dart';
import '../money/money_screen.dart';
import '../shopping/presentation/shopping_tab.dart';
import '../tasks/presentation/tasks_tab.dart';

/// Habits and important dates tabs (schema v3).
List<HubTab> extraPlannerTabs(BuildContext context) => const [];

/// Planner hub: tasks, shopping lists, habits and important dates.
class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return HubScaffold(
      title: l10n.plannerTitle,
      initialTab: initialTab,
      tabs: [
        HubTab(
          key: 'tasks',
          label: l10n.tabTasks,
          body: const TasksTab(),
          fabLabel: l10n.taskAdd,
          onFab: (c) => c.push(Routes.newTask),
        ),
        HubTab(
          key: 'shopping',
          label: l10n.tabShopping,
          body: const ShoppingTab(),
          fabLabel: l10n.shoppingNewList,
          onFab: (c) => createShoppingList(c, ref),
        ),
        ...extraPlannerTabs(context),
      ],
    );
  }
}
