// Pure Dart (no Flutter imports) so that the release tooling in `tool/`
// validates manifests with exactly the same rules as the app.

/// Why a manifest was rejected.
class ManifestException implements Exception {
  const ManifestException(this.message);

  final String message;

  @override
  String toString() => 'ManifestException: $message';
}

/// One published release described by the update manifest.
class UpdateRelease {
  const UpdateRelease({
    required this.versionName,
    required this.versionCode,
    required this.apkUri,
    required this.sha256,
    required this.sizeBytes,
    this.minSdk,
    this.releasedAt,
    this.releaseNotes = const {},
    this.signingCertSha256 = const [],
  });

  final String versionName;
  final int versionCode;

  /// Absolute HTTPS address of the APK (same host as the manifest).
  final Uri apkUri;

  /// Lower-case hex SHA-256 of the APK file.
  final String sha256;
  final int sizeBytes;
  final int? minSdk;
  final DateTime? releasedAt;

  /// Release notes by language code (`en`, `si`).
  final Map<String, String> releaseNotes;

  /// Optional lower-case hex SHA-256 digests of the release signing
  /// certificate. When present the downloaded APK must be signed with one
  /// of them.
  final List<String> signingCertSha256;

  String? notesFor(String languageCode) =>
      releaseNotes[languageCode] ?? releaseNotes['en'];
}

/// Parsed and validated `manifest.json`.
class UpdateManifest {
  const UpdateManifest({
    required this.packageName,
    required this.latest,
    required this.minimumSupportedVersionCode,
  });

  static const int schemaVersion = 1;

  /// Largest manifest accepted (it is a few hundred bytes in practice).
  static const int maxBytes = 256 * 1024;

  /// Largest APK accepted.
  static const int maxApkBytes = 512 * 1024 * 1024;

  final String packageName;
  final UpdateRelease latest;

  /// Installed versions below this should update before continuing to use
  /// the app. DAWASA still works offline; it only shows a strong prompt.
  final int minimumSupportedVersionCode;

  static final RegExp _hex64 = RegExp(r'^[0-9a-f]{64}$');
  static final RegExp _package = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+$');

  /// Validates [json] fetched from [manifestUri].
  ///
  /// The APK location may be relative to the manifest. It must resolve to
  /// an `https` address on the same host as the manifest, so a manifest can
  /// never point the app at an unrelated server.
  static UpdateManifest parse(Object? json, Uri manifestUri) {
    if (manifestUri.scheme != 'https') {
      throw const ManifestException('manifest must be served over https');
    }
    if (json is! Map<String, Object?>) {
      throw const ManifestException('not a JSON object');
    }
    T field<T>(Map<String, Object?> map, String key) {
      final value = map[key];
      if (value is! T) throw ManifestException('missing or invalid "$key"');
      return value;
    }

    if (field<int>(json, 'schema') != schemaVersion) {
      throw const ManifestException('unsupported manifest schema');
    }
    if (json['app'] != 'dawasa') {
      throw const ManifestException('not a DAWASA manifest');
    }
    final packageName = field<String>(json, 'packageName');
    if (!_package.hasMatch(packageName)) {
      throw const ManifestException('invalid "packageName"');
    }
    final latest = field<Map<String, Object?>>(json, 'latest');

    final versionName = field<String>(latest, 'versionName').trim();
    if (versionName.isEmpty || versionName.length > 40) {
      throw const ManifestException('invalid "versionName"');
    }
    final versionCode = field<int>(latest, 'versionCode');
    if (versionCode < 1 || versionCode > 2100000000) {
      throw const ManifestException('invalid "versionCode"');
    }
    final minimum = json['minimumSupportedVersionCode'] ?? 0;
    if (minimum is! int || minimum < 0 || minimum > versionCode) {
      throw const ManifestException('invalid "minimumSupportedVersionCode"');
    }

    final apk = field<String>(latest, 'apkUrl');
    final Uri apkUri;
    try {
      apkUri = manifestUri.resolve(apk);
    } on FormatException {
      throw const ManifestException('invalid "apkUrl"');
    }
    if (apkUri.scheme != 'https' ||
        apkUri.host.toLowerCase() != manifestUri.host.toLowerCase() ||
        apkUri.port != manifestUri.port ||
        apkUri.userInfo.isNotEmpty ||
        !apkUri.path.toLowerCase().endsWith('.apk')) {
      throw const ManifestException(
        '"apkUrl" must be an https .apk file on the manifest host',
      );
    }

    final sha256 = field<String>(latest, 'sha256').toLowerCase();
    if (!_hex64.hasMatch(sha256)) {
      throw const ManifestException('invalid "sha256"');
    }
    final size = field<int>(latest, 'sizeBytes');
    if (size <= 0 || size > maxApkBytes) {
      throw const ManifestException('invalid "sizeBytes"');
    }
    final minSdk = latest['minSdk'];
    if (minSdk != null && (minSdk is! int || minSdk < 1)) {
      throw const ManifestException('invalid "minSdk"');
    }
    final released = latest['releasedAt'];
    final releasedAt = released is String ? DateTime.tryParse(released) : null;

    final notes = <String, String>{};
    final rawNotes = latest['releaseNotes'];
    if (rawNotes is Map) {
      for (final entry in rawNotes.entries) {
        if (entry.key is String && entry.value is String) {
          final text = (entry.value as String).trim();
          if (text.isNotEmpty) {
            notes[entry.key as String] = text.length > 4000
                ? text.substring(0, 4000)
                : text;
          }
        }
      }
    }

    final certs = <String>[];
    final rawCerts = latest['signingCertSha256'];
    if (rawCerts != null) {
      if (rawCerts is! List) {
        throw const ManifestException('invalid "signingCertSha256"');
      }
      for (final c in rawCerts) {
        final digest = c is String ? c.replaceAll(':', '').toLowerCase() : null;
        if (digest == null || !_hex64.hasMatch(digest)) {
          throw const ManifestException('invalid "signingCertSha256"');
        }
        certs.add(digest);
      }
    }

    return UpdateManifest(
      packageName: packageName,
      minimumSupportedVersionCode: minimum,
      latest: UpdateRelease(
        versionName: versionName,
        versionCode: versionCode,
        apkUri: apkUri,
        sha256: sha256,
        sizeBytes: size,
        minSdk: minSdk as int?,
        releasedAt: releasedAt,
        releaseNotes: notes,
        signingCertSha256: certs,
      ),
    );
  }
}

/// Builds the manifest address from a configured base folder URL.
///
/// Returns null unless [base] is an absolute `https` URL without
/// credentials, query or fragment.
Uri? manifestUriFor(String base, String manifestName) {
  final trimmed = base.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }
  final folder = uri.path.endsWith('/')
      ? uri
      : uri.replace(path: '${uri.path}/');
  if (manifestName.contains('/') || manifestName.isEmpty) return null;
  return folder.resolve(manifestName);
}
