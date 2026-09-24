import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkKind {
  none,

  /// Wi-Fi or Ethernet (normally not metered).
  unmetered,

  /// Mobile data or an unknown connection type.
  metered,
}

abstract interface class NetworkStatus {
  Future<NetworkKind> current();
}

class DeviceNetworkStatus implements NetworkStatus {
  @override
  Future<NetworkKind> current() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.isEmpty ||
          results.every((r) => r == ConnectivityResult.none)) {
        return NetworkKind.none;
      }
      if (results.any(
        (r) => r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet,
      )) {
        return NetworkKind.unmetered;
      }
      return NetworkKind.metered;
    } on Object catch (e) {
      debugPrint('Connectivity check failed: $e');
      // Let the request itself decide.
      return NetworkKind.metered;
    }
  }
}

class FakeNetworkStatus implements NetworkStatus {
  FakeNetworkStatus([this.kind = NetworkKind.unmetered]);

  NetworkKind kind;

  @override
  Future<NetworkKind> current() async => kind;
}

final networkStatusProvider = Provider<NetworkStatus>(
  (ref) => DeviceNetworkStatus(),
);
