import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/notification_providers.dart';
import '../core/providers.dart';
import '../features/transactions/presentation/transaction_providers.dart';
import 'router.dart';

/// Hooks that other modules register to run on launch and resume.
typedef StartupHook = Future<void> Function(Ref ref, {required bool launch});

/// Work that runs when the app starts or returns to the foreground.
///
/// Everything here is local and fast; nothing blocks the UI and nothing
/// requires the internet.
class StartupTasks {
  StartupTasks(this._ref);

  final Ref _ref;
  bool _running = false;
  bool _notificationsReady = false;

  Future<void> onLaunch() => _run(launch: true);

  Future<void> onResume() => _run(launch: false);

  void onPause() {}

  void _openPayload(String? payload) {
    if (payload == null || !payload.startsWith('/')) return;
    _ref.read(routerProvider).push(payload);
  }

  Future<void> _run({required bool launch}) async {
    if (_running) return;
    _running = true;
    try {
      if (!_notificationsReady) {
        final gateway = _ref.read(notificationGatewayProvider);
        await gateway.initialize(onTap: _openPayload);
        _notificationsReady = true;
        if (launch) _openPayload(await gateway.launchPayload());
      }
      final today = _ref.read(todayProvider);
      await _ref.read(recurringRepositoryProvider).generateDue(today);
      for (final hook in _ref.read(startupHooksProvider)) {
        await hook(_ref, launch: launch);
      }
    } on Object catch (e, st) {
      debugPrint('Startup task failed: $e\n$st');
    } finally {
      _running = false;
    }
  }
}

final startupTasksProvider = Provider<StartupTasks>(StartupTasks.new);

/// Additional launch/resume work of feature modules (reminder sync, update
/// check, ...). Hooks must never throw for offline conditions.
final startupHooksProvider = Provider<List<StartupHook>>((ref) => const []);
