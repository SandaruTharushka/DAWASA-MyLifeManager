import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/providers.dart';
import '../domain/budget_logic.dart';
import 'budget_providers.dart';

/// Evaluates budgets after spending is recorded and raises a local
/// notification when a warning threshold is crossed or a budget is exceeded
/// (once per budget, period and level).
class BudgetAlertService {
  BudgetAlertService(this._ref);

  final Ref _ref;

  Future<List<BudgetProgress>> checkAfterSpending() async {
    final prefs = _ref.read(preferencesProvider);
    final repo = _ref.read(budgetRepositoryProvider);
    final progress = await repo.progress(
      _ref.read(todayProvider),
      _ref.read(userSettingsProvider).firstDayOfWeek,
    );
    final alerts = progress.where((p) => p.shouldAlert()).toList();
    if (alerts.isEmpty) return const [];
    final l10n = lookupAppLocalizations(Locale(_ref.read(localeNameProvider)));
    final gateway = _ref.read(notificationGatewayProvider);
    final enabled = prefs.notificationsEnabled && prefs.notifyBudgets;
    for (final p in alerts) {
      await repo.setLastAlert(p.budget.id, p.alertKey);
      if (!enabled) continue;
      final currency = Currencies.byCode(p.budget.currencyCode);
      final amount = Money.format(p.amountMinor, currency);
      final exceeded = p.alertLevel == BudgetAlertLevel.exceeded;
      await gateway.showNow(
        PlannedNotification(
          id: notificationIdFor('budget:${p.budget.id}'),
          channel: ReminderChannel.budgets,
          when: DateTime.now(),
          title: exceeded
              ? l10n.notifBudgetOverTitle(p.budget.name)
              : l10n.notifBudgetWarnTitle(p.budget.name),
          body: exceeded
              ? l10n.notifBudgetOverBody(
                  Money.format(p.spentMinor, currency),
                  amount,
                )
              : l10n.notifBudgetWarnBody(p.percentUsed, amount),
          payload: Routes.moneyTab('budgets'),
        ),
      );
    }
    return alerts;
  }
}

final budgetAlertServiceProvider = Provider<BudgetAlertService>(
  BudgetAlertService.new,
);
