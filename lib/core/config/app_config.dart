/// Build-time configuration supplied with `--dart-define` or
/// `--dart-define-from-file=config/dawasa.json` (see docs/BUILD_AND_RELEASE.md).
///
/// Nothing here is a secret and no production URL is hard-coded: when a value
/// is not configured the related feature is simply hidden or reports that it
/// is not configured.
abstract final class AppConfig {
  /// HTTPS folder that contains the update manifest and APK files, e.g.
  /// `https://example.com/downloads/dawasa/`.
  static const String updateBaseUrl = String.fromEnvironment(
    'DAWASA_UPDATE_BASE_URL',
  );

  /// Manifest file name inside [updateBaseUrl].
  static const String updateManifestName = String.fromEnvironment(
    'DAWASA_UPDATE_MANIFEST',
    defaultValue: 'manifest.json',
  );

  /// Set to false for builds distributed through an app store, which must
  /// not update themselves.
  static const bool selfUpdateEnabled = bool.fromEnvironment(
    'DAWASA_SELF_UPDATE',
    defaultValue: true,
  );

  static const String developerName = 'Sandaru Tharushka';

  /// Optional, verified developer website shown in About.
  static const String developerWebsite = String.fromEnvironment(
    'DAWASA_DEVELOPER_WEBSITE',
  );

  /// Optional, verified contact e-mail shown in About.
  static const String developerEmail = String.fromEnvironment(
    'DAWASA_DEVELOPER_EMAIL',
  );
}
