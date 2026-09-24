import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/platform/data_paths.dart';
import '../../../core/security/secure_store.dart';
import '../../../core/settings/app_preferences.dart';

/// Erases everything DAWASA stored on this phone: the database, receipt
/// photos, the safety copy of a restore, cached backup files, the PIN and
/// all preferences. The app then starts again with the welcome guide.
class DataWiper {
  const DataWiper({
    required this.paths,
    required this.secureStore,
    required this.preferences,
    required this.notifications,
  });

  final DataPaths paths;
  final SecureStore secureStore;
  final PreferencesStore preferences;
  final NotificationGateway notifications;

  static const String notice = 'deleted';

  Future<void> wipe(AppReloader reload) async {
    try {
      await notifications.cancelAllScheduled();
    } on Object catch (e) {
      debugPrint('Could not cancel reminders: $e');
    }
    await reload(
      whileClosed: () async {
        final db = await paths.databaseFile();
        for (final suffix in const ['', '-wal', '-shm', '-journal']) {
          final f = File('${db.path}$suffix');
          if (f.existsSync()) f.deleteSync();
        }
        for (final dir in [
          await paths.attachmentsDirectory(),
          await paths.safetyDirectory(),
          await paths.workDirectory(),
        ]) {
          if (dir.existsSync()) dir.deleteSync(recursive: true);
        }
        await secureStore.deleteAll();
        await preferences.resetKeepingLanguage();
        await preferences.setNotice(notice);
      },
    );
  }
}
