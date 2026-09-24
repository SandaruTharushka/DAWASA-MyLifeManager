// Creates the files for the DAWASA update server from a signed release APK:
//
//   dist/dawasa/dawasa-<version>-<code>.apk
//   dist/dawasa/manifest.json
//   dist/dawasa/SHA256SUMS
//
// Usage (from the project root):
//
//   dart run tool/generate_manifest.dart \
//     --apk build/app/outputs/flutter-apk/app-release.apk \
//     --notes-en "What changed" --notes-si "වෙනස් වූ දේ" \
//     [--out dist/dawasa] [--minimum-supported 1] \
//     [--signing-cert-sha256 AB:CD:...] [--base-url https://example.com/dawasa/]
//
// The version name and code are read from pubspec.yaml unless given with
// --version-name / --version-code. The manifest is validated with the same
// rules the app uses before anything is written.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dawasa/features/updates/domain/update_manifest.dart';
import 'package:path/path.dart' as p;

const String packageName = 'com.sandarutharushka.dawasa';

class ReleaseInput {
  const ReleaseInput({
    required this.apk,
    required this.outDir,
    required this.versionName,
    required this.versionCode,
    this.minimumSupportedVersionCode = 1,
    this.notes = const {},
    this.signingCertSha256 = const [],
    this.baseUrl,
    this.releasedAt,
  });

  final File apk;
  final Directory outDir;
  final String versionName;
  final int versionCode;
  final int minimumSupportedVersionCode;
  final Map<String, String> notes;
  final List<String> signingCertSha256;
  final String? baseUrl;
  final DateTime? releasedAt;
}

class GeneratedRelease {
  const GeneratedRelease(this.apk, this.manifest, this.checksums, this.sha256);

  final File apk;
  final File manifest;
  final File checksums;
  final String sha256;
}

/// Reads `version: 1.2.3+45` from pubspec.yaml.
(String, int) readPubspecVersion(File pubspec) {
  final match = RegExp(
    r'^version:\s*([0-9A-Za-z.\-]+)\+(\d+)\s*$',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync());
  if (match == null) {
    throw const FormatException('pubspec.yaml has no "version: x.y.z+code"');
  }
  return (match.group(1)!, int.parse(match.group(2)!));
}

Future<GeneratedRelease> generateRelease(ReleaseInput input) async {
  if (!input.apk.existsSync()) {
    throw ArgumentError('APK not found: ${input.apk.path}');
  }
  final bytes = await input.apk.length();
  final digest = (await sha256.bind(input.apk.openRead()).first).toString();
  final apkName = 'dawasa-${input.versionName}-${input.versionCode}.apk';

  final manifestJson = <String, Object?>{
    'schema': UpdateManifest.schemaVersion,
    'app': 'dawasa',
    'packageName': packageName,
    'minimumSupportedVersionCode': input.minimumSupportedVersionCode,
    'latest': {
      'versionName': input.versionName,
      'versionCode': input.versionCode,
      'apkUrl': apkName,
      'sha256': digest,
      'sizeBytes': bytes,
      'releasedAt': (input.releasedAt ?? DateTime.now().toUtc())
          .toIso8601String()
          .substring(0, 10),
      if (input.notes.isNotEmpty) 'releaseNotes': input.notes,
      if (input.signingCertSha256.isNotEmpty)
        'signingCertSha256': [
          for (final c in input.signingCertSha256)
            c.replaceAll(':', '').toLowerCase(),
        ],
    },
  };

  // Validate exactly like the app will.
  final base = input.baseUrl ?? 'https://updates.invalid/dawasa/';
  final manifestUri = manifestUriFor(base, 'manifest.json');
  if (manifestUri == null) {
    throw ArgumentError('--base-url must be an https folder address: $base');
  }
  UpdateManifest.parse(jsonDecode(jsonEncode(manifestJson)), manifestUri);

  final out = input.outDir;
  await out.create(recursive: true);
  final manifestFile = File(p.join(out.path, 'manifest.json'));
  if (manifestFile.existsSync()) {
    final previous = jsonDecode(await manifestFile.readAsString());
    if (previous case {'latest': {'versionCode': final int previousCode}}
        when previousCode >= input.versionCode) {
      throw StateError(
        'versionCode ${input.versionCode} is not newer than the published '
        '$previousCode. Increase the +build number in pubspec.yaml.',
      );
    }
  }

  final apkOut = await input.apk.copy(p.join(out.path, apkName));
  await manifestFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(manifestJson)}\n',
  );
  final sums = File(p.join(out.path, 'SHA256SUMS'));
  await sums.writeAsString('$digest  $apkName\n');
  return GeneratedRelease(apkOut, manifestFile, sums, digest);
}

Map<String, String> _parseArgs(List<String> args) {
  final result = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) throw FormatException('Unexpected "$arg"');
    final eq = arg.indexOf('=');
    if (eq > 0) {
      result[arg.substring(2, eq)] = arg.substring(eq + 1);
    } else {
      if (i + 1 >= args.length) throw FormatException('$arg needs a value');
      result[arg.substring(2)] = args[++i];
    }
  }
  return result;
}

Future<void> main(List<String> arguments) async {
  final Map<String, String> args;
  try {
    args = _parseArgs(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exitCode = 64;
    return;
  }
  final apk = args['apk'];
  if (apk == null) {
    stderr.writeln('Usage: dart run tool/generate_manifest.dart --apk <file>');
    exitCode = 64;
    return;
  }
  var (versionName, versionCode) = readPubspecVersion(File('pubspec.yaml'));
  versionName = args['version-name'] ?? versionName;
  versionCode = int.tryParse(args['version-code'] ?? '') ?? versionCode;
  final notes = <String, String>{
    if (args['notes-en'] != null) 'en': args['notes-en']!,
    if (args['notes-si'] != null) 'si': args['notes-si']!,
  };
  try {
    final release = await generateRelease(
      ReleaseInput(
        apk: File(apk),
        outDir: Directory(args['out'] ?? 'dist/dawasa'),
        versionName: versionName,
        versionCode: versionCode,
        minimumSupportedVersionCode:
            int.tryParse(args['minimum-supported'] ?? '') ?? 1,
        notes: notes,
        signingCertSha256: [
          if (args['signing-cert-sha256'] != null) args['signing-cert-sha256']!,
        ],
        baseUrl: args['base-url'],
      ),
    );
    stdout
      ..writeln('APK:       ${release.apk.path}')
      ..writeln('SHA-256:   ${release.sha256}')
      ..writeln('Manifest:  ${release.manifest.path}')
      ..writeln('Checksums: ${release.checksums.path}')
      ..writeln()
      ..writeln(
        'Upload the APK first and manifest.json last '
        '(see docs/UPDATE_SERVER.md).',
      );
  } on Object catch (e) {
    stderr.writeln('Error: $e');
    exitCode = 1;
  }
}
