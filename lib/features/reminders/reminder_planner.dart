import '../../app/routes.dart';
import '../../core/l10n/l10n.dart';
import '../../core/money/currency.dart';
import '../../core/money/money.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/settings/app_preferences.dart';
import '../../core/time/local_date.dart';
import '../../ui/format/formatters.dart';
import '../bills/data/bill_repository.dart';
import '../tasks/data/task_repository.dart';

/// Everything the planner needs; plain data so it can be unit tested.
class ReminderInputs {
  const ReminderInputs({
    required this.now,
    required this.prefs,
    required this.l10n,
    required this.formatter,
    this.tasks = const [],
    this.bills = const [],
    this.extra = const [],
  });

  final DateTime now;
  final AppPreferences prefs;
  final AppLocalizations l10n;
  final AppDateFormatter formatter;
  final List<TaskItem> tasks;
  final List<BillView> bills;

  /// Reminders contributed by savings, loans, habits and events.
  final List<PlannedNotification> extra;
}

/// Default time for date-only reminders.
const int kDefaultReminderMinutes = 9 * 60;

/// Computes the set of local notifications that should be scheduled.
///
/// Only future reminders inside [horizon] are returned, soonest first, and
/// at most [max] of them, keeping well below Android's alarm limits. The
/// schedule is recomputed whenever data changes, so reminders further in the
/// future are picked up later.
List<PlannedNotification> planReminders(
  ReminderInputs input, {
  int max = 64,
  Duration horizon = const Duration(days: 45),
}) {
  final prefs = input.prefs;
  if (!prefs.notificationsEnabled) return const [];
  final now = input.now;
  final until = now.add(horizon);
  final l10n = input.l10n;
  final f = input.formatter;
  final today = LocalDate.fromDateTime(now);
  final result = <PlannedNotification>[];

  bool inWindow(DateTime when) => when.isAfter(now) && when.isBefore(until);

  String whenLabel(LocalDate date, int? minutes) {
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

  if (prefs.notifyTasks) {
    for (final item in input.tasks) {
      final t = item.task;
      if (t.isCompleted || t.dueDate == null) continue;
      final base = t.dueDate!.atMinutes(
        t.dueTimeMinutes ?? kDefaultReminderMinutes,
      );
      for (final minutes in item.reminders) {
        final when = base.subtract(Duration(minutes: minutes));
        if (!inWindow(when)) continue;
        result.add(
          PlannedNotification(
            id: notificationIdFor('task:${t.id}:$minutes'),
            channel: ReminderChannel.tasks,
            when: when,
            title: l10n.notifTaskTitle(t.title),
            body: l10n.notifTaskBodyDue(
              whenLabel(t.dueDate!, t.dueTimeMinutes),
            ),
            payload: Routes.editTask(t.id),
          ),
        );
      }
    }
  }

  if (prefs.notifyBills) {
    for (final view in input.bills) {
      final b = view.bill;
      if (!b.isActive || !b.remindersEnabled) continue;
      final amount = Money.format(
        b.amountMinor,
        Currencies.byCode(b.currencyCode),
      );
      final body = l10n.notifBillBody(amount, whenLabel(b.nextDueDate, null));
      final candidates = <(String, DateTime)>[
        (
          'advance',
          b.nextDueDate
              .addDays(-b.remindDaysBefore)
              .atMinutes(b.remindAtMinutes),
        ),
        if (b.remindDaysBefore > 0)
          ('due', b.nextDueDate.atMinutes(b.remindAtMinutes)),
      ];
      var scheduled = false;
      for (final (kind, at) in candidates) {
        if (!inWindow(at)) continue;
        scheduled = true;
        result.add(
          PlannedNotification(
            id: notificationIdFor(
              'bill:${b.id}:${b.nextDueDate.toIso()}:$kind',
            ),
            channel: ReminderChannel.bills,
            when: at,
            title: l10n.notifBillTitle(b.name),
            body: body,
            payload: Routes.bill(b.id),
          ),
        );
      }
      // Overdue and still unpaid: one gentle reminder at the next reminder
      // time.
      if (!scheduled && b.nextDueDate.isBefore(today.addDays(1))) {
        var when = today.atMinutes(b.remindAtMinutes);
        if (!when.isAfter(now)) {
          when = today.addDays(1).atMinutes(b.remindAtMinutes);
        }
        if (inWindow(when)) {
          result.add(
            PlannedNotification(
              id: notificationIdFor(
                'bill:${b.id}:${b.nextDueDate.toIso()}:overdue',
              ),
              channel: ReminderChannel.bills,
              when: when,
              title: l10n.notifBillTitle(b.name),
              body: body,
              payload: Routes.bill(b.id),
            ),
          );
        }
      }
    }
  }

  result.addAll(input.extra.where((n) => inWindow(n.when)));

  if (prefs.dailyPlanningEnabled) {
    for (var i = 0; i < 7; i++) {
      final when = today.addDays(i).atMinutes(prefs.dailyPlanningMinutes);
      if (!inWindow(when)) continue;
      result.add(
        PlannedNotification(
          id: notificationIdFor('daily:${today.addDays(i).toIso()}'),
          channel: ReminderChannel.planning,
          when: when,
          title: l10n.notifDailyTitle,
          body: l10n.notifDailyBody,
          payload: Routes.home,
        ),
      );
    }
  }

  result.sort((a, b) => a.when.compareTo(b.when));
  final unique = <int>{};
  return [
    for (final n in result)
      if (unique.add(n.id)) n,
  ].take(max).toList();
}
