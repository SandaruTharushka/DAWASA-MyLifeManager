import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_service.dart';

/// Platform notification gateway. Bootstrap overrides this with
/// [LocalNotificationGateway]; tests use the default no-op gateway.
final notificationGatewayProvider = Provider<NotificationGateway>(
  (ref) => NoopNotificationGateway(),
);
