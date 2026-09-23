import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../core/database/app_database.dart';
import '../../core/l10n/l10n.dart';
import '../../core/money/currency.dart';
import '../../core/money/money.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/providers.dart';
import '../../core/time/local_date.dart';
import '../events/data/event_repository.dart';
import '../events/presentation/event_screens.dart';
import '../habits/presentation/habit_screens.dart';
import '../loans/presentation/loan_providers.dart';
import '../savings/presentation/savings_providers.dart';

String _when(
  AppLocalizations l10n,
  Ref ref,
  LocalDate today,
  LocalDate date,
  int? minutes,
) {
  final f = ref.read(dateFormatterProvider);
  final diff = today.daysUntil(date);
  final day = diff == 0
      ? l10n.notifWhenToday
      : diff == 1
      ? l10n.notifWhenTomorrow
      : l10n.notifWhenOn(f.date(date));
  return minutes == null
      ? day
      : '$day ${l10n.notifWhenAt(f.timeOfDay(minutes))}';
}

Future<List<PlannedNotification>> eventReminders(
  Ref ref,
  DateTime now,
  AppLocalizations l10n,
) async {
  if (!ref.read(preferencesProvider).notifyEvents) return const [];
  final today = LocalDate.fromDateTime(now);
  final events = await ref.read(eventRepositoryProvider).all();
  final result = <PlannedNotification>[];
  for (final e in events) {
    if (e.remindDaysBefore == null) continue;
    // This and the following occurrence, so a reminder that already passed
    // for today's event does not hide next year's.
    final view = EventView.of(e, today);
    final next = view.next;
    if (next == null) continue;
    final rule = view.rule;
    final dates = [next, ?rule?.nextAfter(e.date, next)];
    for (final date in dates) {
      final body = _when(l10n, ref, today, date, e.timeMinutes);
      final times = {
        date.addDays(-e.remindDaysBefore!).atMinutes(e.remindAtMinutes),
        date.atMinutes(e.timeMinutes ?? e.remindAtMinutes),
      };
      for (final when in times) {
        result.add(
          PlannedNotification(
            id: notificationIdFor(
              'event:${e.id}:${date.toIso()}:${when.millisecondsSinceEpoch}',
            ),
            channel: ReminderChannel.events,
            when: when,
            title: l10n.eventNotifTitle(e.title),
            body: l10n.eventNotifBody(body),
            payload: Routes.editEvent(e.id),
          ),
        );
      }
    }
  }
  return result;
}

Future<List<PlannedNotification>> loanReminders(
  Ref ref,
  DateTime now,
  AppLocalizations l10n,
) async {
  if (!ref.read(preferencesProvider).notifyLoans) return const [];
  final today = LocalDate.fromDateTime(now);
  final loans = await ref.read(loanRepositoryProvider).loans();
  final result = <PlannedNotification>[];
  for (final l in loans) {
    final loan = l.loan;
    if (loan.status != LoanStatus.active ||
        !loan.remindersEnabled ||
        loan.dueDate == null) {
      continue;
    }
    final amount = Money.format(
      l.outstandingMinor,
      Currencies.byCode(loan.currencyCode),
    );
    final title = l.isLent
        ? l10n.loanNotifTitleLent(loan.counterparty)
        : l10n.loanNotifTitleBorrowed(loan.counterparty);
    final body = l10n.loanNotifBody(
      amount,
      _when(l10n, ref, today, loan.dueDate!, null),
    );
    for (final when in {
      loan.dueDate!.addDays(-loan.remindDaysBefore).atMinutes(9 * 60),
      loan.dueDate!.atMinutes(9 * 60),
    }) {
      result.add(
        PlannedNotification(
          id: notificationIdFor(
            'loan:${loan.id}:${when.millisecondsSinceEpoch}',
          ),
          channel: ReminderChannel.money,
          when: when,
          title: title,
          body: body,
          payload: Routes.loan(loan.id),
        ),
      );
    }
  }
  return result;
}

Future<List<PlannedNotification>> savingsReminders(
  Ref ref,
  DateTime now,
  AppLocalizations l10n,
) async {
  if (!ref.read(preferencesProvider).notifySavings) return const [];
  final today = LocalDate.fromDateTime(now);
  final goals = await ref.read(savingsRepositoryProvider).goals();
  final result = <PlannedNotification>[];
  for (final g in goals) {
    if (!g.goal.remindMonthly || g.reached || g.goal.isArchived) continue;
    final amount = Money.format(
      g.remainingMinor,
      Currencies.byCode(g.goal.currencyCode),
    );
    // The next two "1st of the month, 9:00" moments.
    var nextFirst = today.firstDayOfMonth;
    if (!nextFirst.atMinutes(9 * 60).isAfter(now)) {
      nextFirst = nextFirst.addMonths(1);
    }
    for (var i = 0; i < 2; i++) {
      final first = nextFirst.addMonths(i);
      final when = first.atMinutes(9 * 60);
      result.add(
        PlannedNotification(
          id: notificationIdFor('savings:${g.goal.id}:${first.toIso()}'),
          channel: ReminderChannel.money,
          when: when,
          title: l10n.notifSavingsTitle(g.goal.name),
          body: l10n.notifSavingsBody(amount),
          payload: Routes.savingsGoal(g.goal.id),
        ),
      );
    }
  }
  return result;
}

Future<List<PlannedNotification>> habitReminders(
  Ref ref,
  DateTime now,
  AppLocalizations l10n,
) async {
  if (!ref.read(preferencesProvider).notifyHabits) return const [];
  final today = LocalDate.fromDateTime(now);
  final firstWeekday = ref.read(userSettingsProvider).firstDayOfWeek;
  final habits = await ref.read(habitRepositoryProvider).habits();
  final result = <PlannedNotification>[];
  for (final h in habits) {
    final minutes = h.habit.reminderMinutes;
    if (minutes == null) continue;
    final doneToday = h.stats(today, firstWeekday).completedToday;
    for (var i = doneToday ? 1 : 0; i < 7; i++) {
      final day = today.addDays(i);
      result.add(
        PlannedNotification(
          id: notificationIdFor('habit:${h.habit.id}:${day.toIso()}'),
          channel: ReminderChannel.habits,
          when: day.atMinutes(minutes),
          title: l10n.habitNotifTitle(h.habit.name),
          body: l10n.habitNotifBody,
          payload: Routes.plannerTab('habits'),
        ),
      );
    }
  }
  return result;
}
