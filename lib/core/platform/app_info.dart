import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Installed app version. `versionCode` is the Android version code used to
/// decide whether an update is newer.
class AppVersion {
  const AppVersion({
    required this.versionName,
    required this.versionCode,
    required this.packageName,
  });

  final String versionName;
  final int versionCode;
  final String packageName;
}

final appVersionProvider = FutureProvider<AppVersion>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return AppVersion(
    versionName: info.version,
    versionCode: int.tryParse(info.buildNumber) ?? 0,
    packageName: info.packageName,
  );
});
