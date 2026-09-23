import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/database/app_database.dart';
import '../../core/l10n/l10n.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/common.dart';

/// Opens the "new task" editor.
void openNewTask(BuildContext context) => context.push(Routes.newTask);

/// Bottom sheet with the most frequent entry types.
Future<void> showQuickAddSheet(BuildContext context) {
  final l10n = context.l10n;
  final s = context.semantic;
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      Widget item(IconData icon, Color color, String label, VoidCallback go) =>
          ListTile(
            leading: IconBadge(icon: icon, color: color, size: 40),
            title: Text(label),
            onTap: () {
              Navigator.of(sheetContext).pop();
              go();
            },
          );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: Gap.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              item(
                Icons.remove_circle_outline_rounded,
                s.expense,
                l10n.quickAddExpense,
                () => context.push(Routes.newTransaction()),
              ),
              item(
                Icons.add_circle_outline_rounded,
                s.income,
                l10n.quickAddIncome,
                () => context.push(
                  Routes.newTransaction(type: TransactionType.income),
                ),
              ),
              item(
                Icons.swap_horiz_rounded,
                s.transfer,
                l10n.quickAddTransfer,
                () => context.push(
                  Routes.newTransaction(type: TransactionType.transfer),
                ),
              ),
              item(
                Icons.task_alt_rounded,
                context.colors.primary,
                l10n.quickAddTask,
                () => openNewTask(context),
              ),
            ],
          ),
        ),
      );
    },
  );
}
