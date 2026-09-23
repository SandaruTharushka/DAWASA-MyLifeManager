import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/notifications/notification_providers.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/providers.dart';
import '../bills/presentation/bill_providers.dart';
import '../tasks/presentation/task_providers.dart';
import 'extra_reminder_sources.dart';
import 'reminder_planner.dart';

/// Builds additional reminders (savings, loans, habits, events).
typedef ExtraReminderSource = Future<List<PlannedNotification>> Function(
  Ref ref,
  DateTime now,
  AppLocalizations l10n,
);

final extraReminderSourcesProvider = Provider<List<ExtraReminderSource>>(
  (ref) => const [
    eventReminders,
    loanReminders,
    savingsReminders,
    habitReminders,
  ],
);

/// Tables whose changes require a reschedule.
final reminderTablesProvider = Provider<List<TableInfo<Table, Object?>>>((ref) {
  final db = ref.watch(databaseProvider);
  return [
    db.tasks,
    db.taskReminders,
    db.bills,
    db.billPayments,
    db.personalEvents,
    db.loans,
    db.loanRepayments,
    db.savingsGoals,
    db.savingsMovements,
    db.habits,
    db.habitLogs,
  ];
});

/// Keeps the scheduled Android notifications in sync with the data.
///
/// Syncing replaces the whole schedule (cancel + schedule), which makes it
/// idempotent and handles edits, deletions, completed tasks, paid bills,
/// device reboots (on next app start), clock and time-zone changes (on
/// resume) and preference changes.
class ReminderSyncService {
  ReminderSyncService(this._ref);

  final Ref _ref;
  StreamSubscription<void>? _subscription;
  ProviderSubscription<Object>? _prefsSubscription;
  Timer? _debounce;
  bool _syncing = false;
  bool _pending = false;

  /// Last computed schedule (for diagnostics and tests).
  List<PlannedNotification> lastPlan = const [];

  void startWatching() {
    if (_subscription != null) return;
    final db = _ref.read(databaseProvider);
    _subscription = db
        .tableUpdates(
          TableUpdateQuery.onAllTables(_ref.read(reminderTablesProvider)),
        )
        .listen((_) => scheduleSync());
    _prefsSubscription = _ref.listen<Object>(
      preferencesProvider.select(
        (p) => (
          p.notificationsEnabled,
          p.notifyTasks,
          p.notifyBills,
          p.notifyEvents,
          p.notifyLoans,
          p.notifySavings,
          p.notifyHabits,
          p.dailyPlanningEnabled,
          p.dailyPlanningMinutes,
          p.languageCode,
        ),
      ),
      (_, _) => scheduleSync(),
    );
  }

  void dispose() {
    _debounce?.cancel();
    _subscription?.cancel();
    _prefsSubscription?.close();
  }

  void scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), sync);
  }

  Future<List<PlannedNotification>> plan() async {
    final now = _ref.read(clockProvider)();
    final l10n = lookupAppLocalizations(Locale(_ref.read(localeNameProvider)));
    final extra = <PlannedNotification>[];
    for (final source in _ref.read(extraReminderSourcesProvider)) {
      extra.addAll(await source(_ref, now, l10n));
    }
    return planReminders(
      ReminderInputs(
        now: now,
        prefs: _ref.read(preferencesProvider),
        l10n: l10n,
        formatter: _ref.read(dateFormatterProvider),
        tasks: await _ref.read(taskRepositoryProvider).all(),
        bills: await _ref.read(billRepositoryProvider).all(),
        extra: extra,
      ),
    );
  }

  Future<void> sync() async {
    if (_syncing) {
      _pending = true;
      return;
    }
    _syncing = true;
    try {
      final gateway = _ref.read(notificationGatewayProvider);
      final planned = await plan();
      await gateway.cancelAllScheduled();
      for (final n in planned) {
        await gateway.schedule(n);
      }
      lastPlan = planned;
    } on Object catch (e, st) {
      debugPrint('Reminder sync failed: $e\n$st');
    } finally {
      _syncing = false;
      if (_pending) {
        _pending = false;
        scheduleSync();
      }
    }
  }
}

final reminderSyncServiceProvider = Provider<ReminderSyncService>((ref) {
  final service = ReminderSyncService(ref);
  ref.onDispose(service.dispose);
  return service;
});
