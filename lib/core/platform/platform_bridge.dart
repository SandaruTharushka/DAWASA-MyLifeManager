import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Small Android-only helpers implemented in `MainActivity.kt`.
class PlatformBridge {
  const PlatformBridge();

  static const MethodChannel _channel = MethodChannel(
    'com.sandarutharushka.dawasa/platform',
  );

  /// Blocks screenshots and hides the app content in the recent-apps
  /// overview (Android `FLAG_SECURE`).
  Future<void> setScreenProtection(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setSecureScreen', {
        'enabled': enabled,
      });
    } on MissingPluginException {
      // Not running on Android (tests, desktop).
    } on PlatformException catch (e) {
      debugPrint('setSecureScreen failed: $e');
    }
  }
}

final platformBridgeProvider = Provider<PlatformBridge>(
  (ref) => const PlatformBridge(),
);
