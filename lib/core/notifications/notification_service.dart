import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Android notification channels. Users can tune each one separately in
/// Android settings.
enum ReminderChannel {
  tasks('dawasa_tasks', 'Tasks', 'Task reminders'),
  bills('dawasa_bills', 'Bills', 'Bill and payment reminders'),
  events(
    'dawasa_events',
    'Important dates',
    'Birthdays, appointments and events',
  ),
  budgets('dawasa_budgets', 'Budgets', 'Budget warnings'),
  money(
    'dawasa_money',
    'Savings & loans',
    'Savings goal and loan repayment reminders',
  ),
  habits('dawasa_habits', 'Habits', 'Habit reminders'),
  planning('dawasa_planning', 'Daily planning', 'Daily planning reminder');

  const ReminderChannel(this.id, this.name, this.description);

  final String id;
  final String name;
  final String description;
}

/// A notification to show at a local wall-clock time.
@immutable
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.channel,
    required this.when,
    required this.title,
    required this.body,
    this.payload,
  });

  /// Stable id derived from the record, so re-syncing replaces instead of
  /// duplicating.
  final int id;
  final ReminderChannel channel;

  /// Local date and time.
  final DateTime when;
  final String title;
  final String body;

  /// Deep link (route) opened when the notification is tapped.
  final String? payload;

  @override
  bool operator ==(Object other) =>
      other is PlannedNotification &&
      other.id == id &&
      other.when == when &&
      other.title == title &&
      other.body == body &&
      other.channel == channel;

  @override
  int get hashCode => Object.hash(id, when, title, body, channel);

  @override
  String toString() => 'PlannedNotification($id, $channel, $when, $title)';
}

/// Abstraction over the platform plugin so scheduling logic is testable.
abstract interface class NotificationGateway {
  Future<void> initialize({void Function(String? payload)? onTap});
  Future<bool> requestPermission();
  Future<bool> areNotificationsEnabled();
  Future<void> schedule(PlannedNotification notification);
  Future<void> showNow(PlannedNotification notification);
  Future<void> cancel(int id);
  Future<void> cancelAllScheduled();
  Future<String?> launchPayload();
}

/// Deterministic 31-bit notification id from a string key (FNV-1a).
int notificationIdFor(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

/// Android implementation backed by flutter_local_notifications.
///
/// Uses inexact alarms only (`inexactAllowWhileIdle`), so DAWASA never needs
/// the exact-alarm permission. Reminders may arrive a few minutes late on
/// some power-saving devices, which is acceptable for personal reminders.
class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  static Future<void> initializeTimeZones() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Object {
      // Fall back to Sri Lanka time if the device zone is unknown.
      tz.setLocalLocation(tz.getLocation('Asia/Colombo'));
    }
  }

  @override
  Future<void> initialize({void Function(String? payload)? onTap}) async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_dawasa'),
      ),
      onDidReceiveNotificationResponse: (response) =>
          onTap?.call(response.payload),
    );
    final android = _android;
    if (android != null) {
      for (final channel in ReminderChannel.values) {
        await android.createNotificationChannel(
          AndroidNotificationChannel(
            channel.id,
            channel.name,
            description: channel.description,
            importance: channel == ReminderChannel.budgets
                ? Importance.defaultImportance
                : Importance.high,
          ),
        );
      }
    }
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  @override
  Future<bool> areNotificationsEnabled() async =>
      await _android?.areNotificationsEnabled() ?? false;

  NotificationDetails _details(ReminderChannel channel) => NotificationDetails(
    android: AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      color: const Color(0xFF16A34A),
    ),
  );

  @override
  Future<void> schedule(PlannedNotification n) async {
    final when = tz.TZDateTime.from(n.when, tz.local);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id: n.id,
      title: n.title,
      body: n.body,
      scheduledDate: when,
      notificationDetails: _details(n.channel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: n.payload,
    );
  }

  @override
  Future<void> showNow(PlannedNotification n) => _plugin.show(
    id: n.id,
    title: n.title,
    body: n.body,
    notificationDetails: _details(n.channel),
    payload: n.payload,
  );

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAllScheduled() => _plugin.cancelAllPendingNotifications();

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }
}

/// No-op gateway used in tests and on unsupported platforms.
class NoopNotificationGateway implements NotificationGateway {
  final List<PlannedNotification> scheduled = [];
  final List<PlannedNotification> shown = [];
  bool permissionGranted = true;

  @override
  Future<void> initialize({void Function(String? payload)? onTap}) async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<bool> areNotificationsEnabled() async => permissionGranted;

  @override
  Future<void> schedule(PlannedNotification notification) async =>
      scheduled.add(notification);

  @override
  Future<void> showNow(PlannedNotification notification) async =>
      shown.add(notification);

  @override
  Future<void> cancel(int id) async => scheduled.removeWhere((n) => n.id == id);

  @override
  Future<void> cancelAllScheduled() async => scheduled.clear();

  @override
  Future<String?> launchPayload() async => null;
}
