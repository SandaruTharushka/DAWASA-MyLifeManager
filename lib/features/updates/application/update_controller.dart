import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../core/config/app_config.dart';
import '../../../core/platform/app_info.dart';
import '../../../core/platform/data_paths.dart';
import '../../../core/providers.dart';
import '../../security/app_lock.dart';
import '../data/apk_installer.dart';
import '../data/network_status.dart';
import '../data/update_client.dart';
import '../domain/update_manifest.dart';

/// Build-time update settings (overridable in tests).
class UpdateConfig {
  const UpdateConfig({
    required this.enabled,
    required this.defaultBaseUrl,
    required this.manifestName,
  });

  final bool enabled;
  final String defaultBaseUrl;
  final String manifestName;
}

final updateConfigProvider = Provider<UpdateConfig>(
  (ref) => const UpdateConfig(
    enabled: AppConfig.selfUpdateEnabled,
    defaultBaseUrl: AppConfig.updateBaseUrl,
    manifestName: AppConfig.updateManifestName,
  ),
);

/// The manifest address in use: the user's own server if set, otherwise
/// the one configured at build time; null when neither is valid.
final manifestUriProvider = Provider<Uri?>((ref) {
  final config = ref.watch(updateConfigProvider);
  final custom = ref.watch(
    preferencesProvider.select((p) => p.customUpdateUrl),
  );
  return manifestUriFor(custom ?? config.defaultBaseUrl, config.manifestName);
});

final updateClientProvider = Provider<UpdateClient>((ref) {
  final version = ref.watch(appVersionProvider).value;
  return UpdateClient(
    clientFactory: http.Client.new,
    userAgent: 'DAWASA/${version?.versionName ?? '1'} (Android)',
  );
});

// ------------------------------------------------------------------ states

sealed class UpdateState {
  const UpdateState();
}

/// Self-update is switched off (store builds).
class UpdateDisabled extends UpdateState {
  const UpdateDisabled();
}

class UpdateNotConfigured extends UpdateState {
  const UpdateNotConfigured();
}

class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

class UpdateOffline extends UpdateState {
  const UpdateOffline();
}

class UpdateUpToDate extends UpdateState {
  const UpdateUpToDate(this.checkedAt);

  final DateTime checkedAt;
}

/// States that concern a specific newer release.
sealed class UpdateWithRelease extends UpdateState {
  const UpdateWithRelease(this.release, {required this.required});

  final UpdateRelease release;

  /// The installed version is below the minimum supported version.
  final bool required;
}

class UpdateAvailable extends UpdateWithRelease {
  const UpdateAvailable(super.release, {required super.required});
}

class UpdateWifiRequired extends UpdateWithRelease {
  const UpdateWifiRequired(super.release, {required super.required});
}

class UpdateDownloading extends UpdateWithRelease {
  const UpdateDownloading(
    super.release, {
    required super.required,
    required this.received,
    required this.total,
  });

  final int received;
  final int total;

  double get fraction => total <= 0 ? 0 : (received / total).clamp(0, 1);
  int get percent => (fraction * 100).floor();
}

class UpdateDownloadCancelled extends UpdateWithRelease {
  const UpdateDownloadCancelled(super.release, {required super.required});
}

class UpdateVerifying extends UpdateWithRelease {
  const UpdateVerifying(super.release, {required super.required});
}

class UpdateReady extends UpdateWithRelease {
  const UpdateReady(
    super.release, {
    required super.required,
    required this.apk,
    this.installCancelled = false,
  });

  final File apk;

  /// The user tapped Cancel on Android's installer screen last time.
  final bool installCancelled;
}

class UpdateNeedsPermission extends UpdateWithRelease {
  const UpdateNeedsPermission(
    super.release, {
    required super.required,
    required this.apk,
  });

  final File apk;
}

class UpdateInstalling extends UpdateWithRelease {
  const UpdateInstalling(super.release, {required super.required});
}

class UpdateFailed extends UpdateState {
  const UpdateFailed(
    this.failure, {
    this.release,
    this.required = false,
    this.detail,
  });

  final UpdateFailure failure;

  /// Set when the failure happened while downloading or installing, so
  /// "try again" resumes that release instead of checking again.
  final UpdateRelease? release;
  final bool required;
  final String? detail;
}

// -------------------------------------------------------------- controller

/// Checks for, downloads, verifies and hands over app updates.
///
/// Updating only replaces the APK. The user's database stays where it is and
/// is migrated by the new version on its next start, exactly as after an
/// update from any other source.
class UpdateController extends Notifier<UpdateState> {
  static const autoCheckInterval = Duration(hours: 24);
  static const updatesFolder = 'updates';

  CancelToken? _cancel;
  StreamSubscription<InstallStatus>? _installStatus;

  @override
  UpdateState build() {
    ref.onDispose(() {
      _cancel?.cancel();
      _installStatus?.cancel();
    });
    if (!ref.watch(updateConfigProvider).enabled) return const UpdateDisabled();
    return ref.watch(manifestUriProvider) == null
        ? const UpdateNotConfigured()
        : const UpdateIdle();
  }

  DateTime _now() => ref.read(clockProvider)();

  bool get _busy =>
      state is UpdateChecking ||
      state is UpdateDownloading ||
      state is UpdateVerifying ||
      state is UpdateInstalling;

  /// Whether the throttled background check should run now.
  bool shouldAutoCheck() {
    if (state is! UpdateIdle) return false;
    final prefs = ref.read(preferencesProvider);
    if (!prefs.autoCheckUpdates) return false;
    final last = prefs.lastUpdateCheck;
    if (last == null) return true;
    final since = _now().difference(last);
    return since.isNegative || since >= autoCheckInterval;
  }

  /// Checks the server. A [quiet] check (automatic, in the background) never
  /// shows errors; it only surfaces an available update.
  Future<void> check({bool quiet = false}) async {
    if (_busy) return;
    if (!ref.read(updateConfigProvider).enabled) return;
    final uri = ref.read(manifestUriProvider);
    if (uri == null) {
      state = const UpdateNotConfigured();
      return;
    }
    final before = state;
    if (!quiet) state = const UpdateChecking();
    if (await ref.read(networkStatusProvider).current() == NetworkKind.none) {
      state = quiet ? before : const UpdateOffline();
      return;
    }
    try {
      final manifest = await ref.read(updateClientProvider).fetchManifest(uri);
      final installed = await ref.read(appVersionProvider.future);
      await ref
          .read(preferencesProvider.notifier)
          .update((p) => p.copyWith(lastUpdateCheck: _now()));
      if (manifest.packageName != installed.packageName) {
        throw const UpdateException(
          UpdateFailure.invalidManifest,
          'manifest is for another app',
        );
      }
      final release = manifest.latest;
      if (release.versionCode <= installed.versionCode) {
        state = UpdateUpToDate(_now());
        return;
      }
      final required =
          installed.versionCode < manifest.minimumSupportedVersionCode;
      state = UpdateAvailable(release, required: required);
    } on UpdateException catch (e) {
      debugPrint('Update check failed: $e');
      state = quiet
          ? before
          : e.failure == UpdateFailure.offline
          ? const UpdateOffline()
          : UpdateFailed(e.failure, detail: e.detail);
    }
  }

  Future<Directory> _updatesDirectory() async {
    final temp = await ref.read(dataPathsProvider).tempDirectory();
    final dir = Directory(p.join(temp.path, updatesFolder));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Downloads the release shown in the current state. On mobile data with
  /// "Wi-Fi only" on, asks first unless [allowMobileData] is set.
  Future<void> download({bool allowMobileData = false}) async {
    final current = state;
    final UpdateRelease release;
    final bool required;
    switch (current) {
      case UpdateAvailable() ||
          UpdateWifiRequired() ||
          UpdateDownloadCancelled():
        release = (current as UpdateWithRelease).release;
        required = current.required;
      case UpdateFailed(release: final r?, required: final req):
        release = r;
        required = req;
      default:
        return;
    }
    final network = await ref.read(networkStatusProvider).current();
    if (network == NetworkKind.none) {
      state = UpdateFailed(
        UpdateFailure.offline,
        release: release,
        required: required,
      );
      return;
    }
    if (network == NetworkKind.metered &&
        ref.read(preferencesProvider).wifiOnlyUpdates &&
        !allowMobileData) {
      state = UpdateWifiRequired(release, required: required);
      return;
    }

    final token = _cancel = CancelToken();
    state = UpdateDownloading(
      release,
      required: required,
      received: 0,
      total: release.sizeBytes,
    );
    try {
      final dir = await _updatesDirectory();
      final apk = await ref
          .read(updateClientProvider)
          .download(
            release,
            dir,
            cancel: token,
            onProgress: (received, total) {
              if (token.isCancelled) return;
              state = UpdateDownloading(
                release,
                required: required,
                received: received,
                total: total,
              );
            },
            onVerifying: () =>
                state = UpdateVerifying(release, required: required),
          );
      state = UpdateVerifying(release, required: required);
      await _verifyApk(apk, release);
      state = UpdateReady(release, required: required, apk: apk);
    } on DownloadCancelled {
      state = UpdateDownloadCancelled(release, required: required);
    } on UpdateException catch (e) {
      debugPrint('Update download failed: $e');
      state = UpdateFailed(
        e.failure,
        release: release,
        required: required,
        detail: e.detail,
      );
    } on FileSystemException catch (e) {
      state = UpdateFailed(
        UpdateFailure.storage,
        release: release,
        required: required,
        detail: e.message,
      );
    } finally {
      if (identical(_cancel, token)) _cancel = null;
    }
  }

  void cancelDownload() => _cancel?.cancel();

  /// Makes sure the file is a newer DAWASA build signed like this app.
  /// Android enforces the signature again when installing.
  Future<void> _verifyApk(File apk, UpdateRelease release) async {
    final installer = ref.read(apkInstallerProvider);
    final installed = await ref.read(appVersionProvider.future);
    final info = await installer.inspect(apk.path);
    Future<Never> reject(String why) async {
      if (apk.existsSync()) await apk.delete();
      throw UpdateException(UpdateFailure.packageMismatch, why);
    }

    if (info == null) await reject('not a readable APK');
    if (info.packageName != installed.packageName) {
      await reject('package ${info.packageName}');
    }
    if (info.versionCode != release.versionCode ||
        info.versionCode <= installed.versionCode) {
      await reject('version ${info.versionCode}');
    }
    if (info.signerSha256.isNotEmpty) {
      final mine = await installer.installedSigners();
      if (mine.isNotEmpty && !info.signerSha256.any(mine.contains)) {
        await reject('signed with a different key');
      }
      final published = release.signingCertSha256;
      if (published.isNotEmpty && !info.signerSha256.any(published.contains)) {
        await reject('signer not listed in the manifest');
      }
    }
  }

  /// Opens Android's installer for a verified update.
  Future<void> install() async {
    final current = state;
    final File apk;
    switch (current) {
      case UpdateReady(apk: final a) || UpdateNeedsPermission(apk: final a):
        apk = a;
      default:
        return;
    }
    final release = (current as UpdateWithRelease).release;
    final required = current.required;
    if (!apk.existsSync()) {
      state = UpdateAvailable(release, required: required);
      return;
    }
    final installer = ref.read(apkInstallerProvider);
    if (!await installer.canRequestInstalls()) {
      state = UpdateNeedsPermission(release, required: required, apk: apk);
      return;
    }
    state = UpdateInstalling(release, required: required);
    _installStatus ??= installer.statuses.listen(_onInstallStatus);
    ref.read(appLockProvider.notifier).expectExternalActivity();
    try {
      await installer.install(apk.path);
    } on PlatformException catch (e) {
      state = UpdateFailed(
        UpdateFailure.install,
        release: release,
        required: required,
        detail: e.message,
      );
    }
  }

  void _onInstallStatus(InstallStatus status) {
    final current = state;
    if (current is! UpdateInstalling) return;
    final release = current.release;
    final required = current.required;
    Future<void> backToReady({required bool cancelled}) async {
      final dir = await _updatesDirectory();
      state = UpdateReady(
        release,
        required: required,
        apk: UpdateClient.completeFile(dir, release),
        installCancelled: cancelled,
      );
    }

    switch (status) {
      case InstallAwaitingUser():
        ref.read(appLockProvider.notifier).expectExternalActivity();
      case InstallSucceeded():
        // Android replaces the app and restarts it with the new version.
        break;
      case InstallCancelled():
        unawaited(backToReady(cancelled: true));
      case InstallFailed(:final message):
        state = UpdateFailed(
          UpdateFailure.install,
          release: release,
          required: required,
          detail: message,
        );
    }
  }

  Future<void> openInstallPermissionSettings() async {
    ref.read(appLockProvider.notifier).expectExternalActivity();
    await ref.read(apkInstallerProvider).openInstallPermissionSettings();
  }

  /// Called when the app returns to the foreground: continues the install
  /// once the user granted the permission.
  Future<void> onResumed() async {
    if (state is! UpdateNeedsPermission) return;
    if (await ref.read(apkInstallerProvider).canRequestInstalls()) {
      await install();
    }
  }

  /// Removes downloaded APKs that are not newer than the installed version
  /// (for example, after an update was installed).
  Future<void> cleanupDownloads() async {
    if (_busy || state is UpdateWithRelease) return;
    try {
      final installed = await ref.read(appVersionProvider.future);
      final dir = await _updatesDirectory();
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        final match = RegExp(r'^dawasa-(\d+)-').firstMatch(name);
        final code = match == null ? null : int.tryParse(match.group(1)!);
        final stalePart =
            name.endsWith('.part') &&
            _now().difference(entity.lastModifiedSync()).inDays >= 7;
        if ((code != null && code <= installed.versionCode) || stalePart) {
          await entity.delete();
        }
      }
    } on Object catch (e) {
      debugPrint('Update cleanup failed: $e');
    }
  }
}

final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

/// Launch/resume hook: tidies old downloads and runs the throttled
/// automatic check without blocking anything else.
Future<void> updateStartupHook(Ref ref, {required bool launch}) async {
  final controller = ref.read(updateControllerProvider.notifier);
  if (launch) unawaited(controller.cleanupDownloads());
  if (controller.shouldAutoCheck()) {
    unawaited(controller.check(quiet: true));
  }
}
