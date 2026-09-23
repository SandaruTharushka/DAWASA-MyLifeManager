import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../ui/widgets/common.dart';

/// Planner hub: tasks, shopping lists, habits and important dates.
class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navPlanner)),
      body: EmptyState(
        icon: Icons.event_note_outlined,
        message: context.l10n.emptyGeneric,
      ),
    );
  }
}
