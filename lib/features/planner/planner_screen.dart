import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/l10n/l10n.dart';
import '../events/presentation/event_screens.dart';
import '../habits/presentation/habit_screens.dart';
import '../money/money_screen.dart';
import '../shopping/presentation/shopping_tab.dart';
import '../tasks/presentation/tasks_tab.dart';

/// Habits and important dates tabs.
List<HubTab> extraPlannerTabs(BuildContext context) {
  final l10n = context.l10n;
  return [
    HubTab(
      key: 'habits',
      label: l10n.tabHabits,
      body: const HabitsTab(),
      fabLabel: l10n.habitAdd,
      onFab: (c) => c.push(Routes.newHabit),
    ),
    HubTab(
      key: 'events',
      label: l10n.tabEvents,
      body: const EventsTab(),
      fabLabel: l10n.eventAdd,
      onFab: (c) => c.push(Routes.newEvent),
    ),
  ];
}

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
