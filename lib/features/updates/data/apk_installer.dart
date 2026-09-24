import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identity of an APK file (read by Android without installing it).
class ApkInfo {
  const ApkInfo({
    required this.packageName,
    required this.versionCode,
    required this.signerSha256,
  });

  final String packageName;
  final int versionCode;

  /// Lower-case hex SHA-256 digests of the signing certificates (empty when
  /// Android could not read them from the archive).
  final List<String> signerSha256;
}

sealed class InstallStatus {
  const InstallStatus();
}

/// Android is showing its "Do you want to update this app?" screen.
class InstallAwaitingUser extends InstallStatus {
  const InstallAwaitingUser();
}

class InstallSucceeded extends InstallStatus {
  const InstallSucceeded();
}

/// The user tapped Cancel in Android's installer.
class InstallCancelled extends InstallStatus {
  const InstallCancelled();
}

class InstallFailed extends InstallStatus {
  const InstallFailed(this.message);

  final String message;
}

/// Hands verified APKs to Android's own package installer. The user always
/// confirms the update on Android's screen; nothing is installed silently.
abstract interface class ApkInstaller {
  Future<ApkInfo?> inspect(String path);

  /// Signing certificate digests of the installed app.
  Future<List<String>> installedSigners();

  /// Whether the user allowed DAWASA to install updates (Android 8+).
  Future<bool> canRequestInstalls();

  /// Opens Android's "Install unknown apps" page for DAWASA.
  Future<void> openInstallPermissionSettings();

  /// Starts an installer session; progress arrives on [statuses].
  Future<void> install(String path);

  Stream<InstallStatus> get statuses;
}

class AndroidApkInstaller implements ApkInstaller {
  AndroidApkInstaller();

  static const MethodChannel _channel = MethodChannel(
    'com.sandarutharushka.dawasa/updates',
  );
  static const EventChannel _events = EventChannel(
    'com.sandarutharushka.dawasa/install_status',
  );

  late final Stream<InstallStatus> _statuses = _events
      .receiveBroadcastStream()
      .map((event) {
        final map = Map<String, Object?>.from(event as Map);
        return switch (map['status']) {
          'pendingUserAction' => const InstallAwaitingUser(),
          'success' => const InstallSucceeded(),
          'aborted' => const InstallCancelled(),
          _ => InstallFailed('${map['message'] ?? map['status']}'),
        };
      })
      .asBroadcastStream();

  @override
  Stream<InstallStatus> get statuses => _statuses;

  @override
  Future<ApkInfo?> inspect(String path) async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'inspectApk',
        {'path': path},
      );
      if (result == null) return null;
      return ApkInfo(
        packageName: result['packageName']! as String,
        versionCode: (result['versionCode']! as num).toInt(),
        signerSha256: [
          for (final s in (result['signers'] as List?) ?? const [])
            '$s'.toLowerCase(),
        ],
      );
    } on PlatformException catch (e) {
      debugPrint('inspectApk failed: $e');
      return null;
    }
  }

  @override
  Future<List<String>> installedSigners() async {
    try {
      final result = await _channel.invokeListMethod<Object?>('appSigners');
      return [for (final s in result ?? const []) '$s'.toLowerCase()];
    } on PlatformException catch (e) {
      debugPrint('appSigners failed: $e');
      return const [];
    }
  }

  @override
  Future<bool> canRequestInstalls() async =>
      await _channel.invokeMethod<bool>('canRequestInstalls') ?? false;

  @override
  Future<void> openInstallPermissionSettings() =>
      _channel.invokeMethod<void>('openInstallSettings');

  @override
  Future<void> install(String path) =>
      _channel.invokeMethod<void>('installApk', {'path': path});
}

/// Test double.
class FakeApkInstaller implements ApkInstaller {
  FakeApkInstaller({this.info, this.signers = const []});

  ApkInfo? info;
  List<String> signers;
  bool allowed = true;
  final List<String> installed = [];
  int settingsOpened = 0;
  // ignore: close_sinks, lives as long as the test.
  final StreamController<InstallStatus> controller =
      StreamController<InstallStatus>.broadcast();

  @override
  Future<ApkInfo?> inspect(String path) async => info;

  @override
  Future<List<String>> installedSigners() async => signers;

  @override
  Future<bool> canRequestInstalls() async => allowed;

  @override
  Future<void> openInstallPermissionSettings() async => settingsOpened++;

  @override
  Future<void> install(String path) async => installed.add(path);

  @override
  Stream<InstallStatus> get statuses => controller.stream;
}

final apkInstallerProvider = Provider<ApkInstaller>(
  (ref) => AndroidApkInstaller(),
);
