import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_root.dart';
import 'core/notifications/notification_service.dart';
import 'core/settings/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Errors are only printed locally. DAWASA has no crash reporting or
  // analytics service, so nothing leaves the device.
  FlutterError.onError = (details) => FlutterError.presentError(details);
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

  await initializeDateFormatting();
  await LocalNotificationGateway.initializeTimeZones();
  final preferences = await SharedPreferences.getInstance();

  // Before the user picks a language, follow the device (Sinhala or English).
  await PreferencesStore(preferences)
      .ensureLanguage(PlatformDispatcher.instance.locale.languageCode);

  runApp(
    AppRoot(
      preferences: preferences,
      notificationGateway: LocalNotificationGateway(),
    ),
  );
}
