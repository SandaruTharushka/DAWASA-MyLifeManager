import 'dart:convert';
import 'dart:io';

import 'package:dawasa/features/updates/data/update_client.dart';
import 'package:dawasa/features/updates/domain/update_manifest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;

import '../../tool/generate_manifest.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('dawasa_release'));
  tearDown(() => root.deleteSync(recursive: true));

  File fakeApk() =>
      File(p.join(root.path, 'app-release.apk'))
        ..writeAsBytesSync(List.generate(123457, (i) => (i * 7) % 256));

  test('reads the version from pubspec.yaml', () {
    final pubspec = File(p.join(root.path, 'pubspec.yaml'))
      ..writeAsStringSync('name: x\nversion: 1.4.2+17\n');
    expect(readPubspecVersion(pubspec), ('1.4.2', 17));
  });

  test('a generated release is accepted and verified by the app', () async {
    final out = Directory(p.join(root.path, 'dist'));
    final release = await generateRelease(
      ReleaseInput(
        apk: fakeApk(),
        outDir: out,
        versionName: '1.1.0',
        versionCode: 2,
        notes: const {'en': 'Notes', 'si': 'සටහන්'},
        signingCertSha256: ['AB:' * 31 + 'AB'],
      ),
    );
    expect(p.basename(release.apk.path), 'dawasa-1.1.0-2.apk');
    expect(
      release.checksums.readAsStringSync(),
      '${release.sha256}  dawasa-1.1.0-2.apk\n',
    );

    // Serve the generated folder and let the app's client use it.
    final server = MockClient((request) async {
      final file = File(p.join(out.path, p.basename(request.url.path)));
      if (!file.existsSync()) return http.Response('', 404);
      return http.Response.bytes(await file.readAsBytes(), 200);
    });
    final client = UpdateClient(clientFactory: () => server, userAgent: 'test');
    final manifestUri = manifestUriFor(
      'https://downloads.example.test/dawasa',
      'manifest.json',
    )!;
    final manifest = await client.fetchManifest(manifestUri);
    expect(manifest.packageName, packageName);
    expect(manifest.latest.signingCertSha256.single, 'ab' * 32);
    final downloads = Directory(p.join(root.path, 'phone'))..createSync();
    final apk = await client.download(
      manifest.latest,
      downloads,
      onProgress: (_, _) {},
    );
    expect(await UpdateClient.sha256OfFile(apk), release.sha256);
  });

  test('refuses to publish a version that is not newer', () async {
    final out = Directory(p.join(root.path, 'dist'));
    Future<void> publish(int code) => generateRelease(
      ReleaseInput(
        apk: fakeApk(),
        outDir: out,
        versionName: '1.0.$code',
        versionCode: code,
      ),
    );
    await publish(3);
    await expectLater(publish(3), throwsStateError);
    await expectLater(publish(2), throwsStateError);
    await publish(4);
    final json = jsonDecode(
      File(p.join(out.path, 'manifest.json')).readAsStringSync(),
    );
    expect(json, containsPair('latest', containsPair('versionCode', 4)));
  });

  test('refuses a plain http base address', () async {
    await expectLater(
      generateRelease(
        ReleaseInput(
          apk: fakeApk(),
          outDir: Directory(p.join(root.path, 'dist')),
          versionName: '1.0.0',
          versionCode: 1,
          baseUrl: 'http://downloads.example.test/',
        ),
      ),
      throwsArgumentError,
    );
  });
}
