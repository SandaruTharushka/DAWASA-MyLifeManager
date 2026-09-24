import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_providers.dart';
import '../../../core/platform/app_info.dart';
import '../../../core/platform/data_paths.dart';
import '../../../core/providers.dart';
import '../../../core/security/secure_store.dart';
import '../data/backup_service.dart';
import '../data/data_wiper.dart';

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    db: ref.watch(databaseProvider),
    paths: ref.watch(dataPathsProvider),
    appVersion: () => ref.read(appVersionProvider.future),
    clock: ref.watch(clockProvider),
  ),
);

final dataWiperProvider = Provider<DataWiper>(
  (ref) => DataWiper(
    paths: ref.watch(dataPathsProvider),
    secureStore: ref.watch(secureStoreProvider),
    preferences: ref.watch(preferencesStoreProvider),
    notifications: ref.watch(notificationGatewayProvider),
  ),
);

/// The copy of the data kept from before the last restore, if any.
final safetyCopyProvider = FutureProvider.autoDispose<SafetyCopyInfo?>(
  (ref) => ref.watch(backupServiceProvider).safetyCopy(),
);
