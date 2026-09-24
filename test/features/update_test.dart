import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dawasa/core/platform/app_info.dart';
import 'package:dawasa/core/platform/data_paths.dart';
import 'package:dawasa/core/providers.dart';
import 'package:dawasa/core/security/secure_store.dart';
import 'package:dawasa/features/updates/application/update_controller.dart';
import 'package:dawasa/features/updates/data/apk_installer.dart';
import 'package:dawasa/features/updates/data/network_status.dart';
import 'package:dawasa/features/updates/data/update_client.dart';
import 'package:dawasa/features/updates/domain/update_manifest.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

const _package = 'com.sandarutharushka.dawasa';
final _base = Uri.parse('https://updates.example.test/downloads/dawasa/');
final _manifestUri = _base.resolve('manifest.json');

List<int> _apkBytes([int size = 300000]) =>
    List<int>.generate(size, (i) => (i * 31 + 7) % 256);

String _sha(List<int> bytes) => sha256.convert(bytes).toString();

Map<String, Object?> _manifestJson({
  int versionCode = 2,
  String apkUrl = 'dawasa-1.1.0-2.apk',
  List<int>? apk,
  int minimum = 1,
  String packageName = _package,
  List<String>? certs,
}) {
  final bytes = apk ?? _apkBytes();
  return {
    'schema': 1,
    'app': 'dawasa',
    'packageName': packageName,
    'minimumSupportedVersionCode': minimum,
    'latest': {
      'versionName': '1.1.0',
      'versionCode': versionCode,
      'apkUrl': apkUrl,
      'sha256': _sha(bytes),
      'sizeBytes': bytes.length,
      'releasedAt': '2026-09-20',
      'releaseNotes': {'en': 'Faster reports', 'si': 'වේගවත් වාර්තා'},
      'signingCertSha256': ?certs,
    },
  };
}

/// A tiny HTTPS "server" with Range support.
class _Server {
  _Server({Map<String, Object?>? manifest, List<int>? apk})
    : manifest = manifest ?? _manifestJson(),
      apk = apk ?? _apkBytes();

  Map<String, Object?> manifest;
  List<int> apk;
  bool honourRange = true;
  int? cutAfter;
  void Function(int sent)? onChunk;
  final List<http.BaseRequest> requests = [];
  final Map<String, String> redirects = {};

  http.Client client() => MockClient.streaming((request, body) async {
    requests.add(request);
    final path = request.url.path;
    final redirect = redirects[path];
    if (redirect != null) {
      return http.StreamedResponse(
        const Stream.empty(),
        302,
        headers: {'location': redirect},
      );
    }
    if (path.endsWith('manifest.json')) {
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(manifest))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (path.endsWith('.apk')) {
      var start = 0;
      var status = 200;
      final headers = <String, String>{};
      final range = request.headers['Range'];
      if (range != null && honourRange) {
        start = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
        status = 206;
        headers['content-range'] =
            'bytes $start-${apk.length - 1}/${apk.length}';
      }
      var bytes = apk.sublist(start);
      if (cutAfter != null && bytes.length > cutAfter!) {
        bytes = bytes.sublist(0, cutAfter);
      }
      Stream<List<int>> chunks() async* {
        for (var i = 0; i < bytes.length; i += 16384) {
          onChunk?.call(i);
          yield bytes.sublist(i, (i + 16384).clamp(0, bytes.length));
        }
      }

      return http.StreamedResponse(chunks(), status, headers: headers);
    }
    return http.StreamedResponse(const Stream.empty(), 404);
  });
}

Matcher _failure(UpdateFailure f) =>
    isA<UpdateException>().having((e) => e.failure, 'failure', f);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('manifest', () {
    test('accepts a valid manifest and resolves the APK next to it', () {
      final m = UpdateManifest.parse(
        _manifestJson(certs: ['AB:' * 31 + 'AB']),
        _manifestUri,
      );
      expect(m.packageName, _package);
      expect(m.latest.versionCode, 2);
      expect(
        m.latest.apkUri.toString(),
        'https://updates.example.test/downloads/dawasa/dawasa-1.1.0-2.apk',
      );
      expect(m.latest.notesFor('si'), 'වේගවත් වාර්තා');
      expect(m.latest.notesFor('ta'), 'Faster reports');
      expect(m.latest.signingCertSha256.single, 'ab' * 32);
    });

    test('rejects anything that could point to another server or file', () {
      void rejects(Object json, [Uri? uri]) => expect(
        () => UpdateManifest.parse(json, uri ?? _manifestUri),
        throwsA(isA<ManifestException>()),
      );

      rejects(_manifestJson(), Uri.parse('http://updates.example.test/m.json'));
      rejects(_manifestJson(apkUrl: 'https://evil.example/dawasa.apk'));
      rejects(_manifestJson(apkUrl: 'http://updates.example.test/d.apk'));
      rejects(_manifestJson(apkUrl: 'https://user@updates.example.test/d.apk'));
      rejects(_manifestJson(apkUrl: 'dawasa.zip'));
      rejects(_manifestJson(minimum: 5));
      rejects(_manifestJson(packageName: 'Not A Package'));
      rejects(_manifestJson(certs: ['zz']));
      rejects({..._manifestJson(), 'schema': 2});
      rejects({..._manifestJson(), 'app': 'other'});
      final bad = _manifestJson();
      (bad['latest']! as Map<String, Object?>)['sha256'] = 'abc';
      rejects(bad);
      final empty = _manifestJson();
      (empty['latest']! as Map<String, Object?>)['sizeBytes'] = 0;
      rejects(empty);
      rejects(const ['not', 'an', 'object']);
    });

    test('only https update folders are accepted', () {
      expect(
        manifestUriFor(
          'https://example.com/downloads/dawasa',
          'manifest.json',
        ).toString(),
        'https://example.com/downloads/dawasa/manifest.json',
      );
      expect(manifestUriFor('', 'manifest.json'), isNull);
      expect(manifestUriFor('http://example.com/', 'manifest.json'), isNull);
      expect(manifestUriFor('https://example.com/?a=1', 'm.json'), isNull);
      expect(manifestUriFor('https://u:p@example.com/', 'm.json'), isNull);
      expect(manifestUriFor('https://example.com/', '../m.json'), isNull);
    });
  });

  group('update client', () {
    late Directory dir;
    late _Server server;
    late UpdateClient client;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('dawasa_update_test');
      server = _Server();
      client = UpdateClient(
        clientFactory: server.client,
        userAgent: 'DAWASA/test',
      );
    });

    tearDown(() => dir.deleteSync(recursive: true));

    UpdateRelease release() =>
        UpdateManifest.parse(server.manifest, _manifestUri).latest;

    test('manifest requests carry no personal data', () async {
      final m = await client.fetchManifest(_manifestUri);
      expect(m.latest.versionName, '1.1.0');
      final request = server.requests.single;
      expect(request.method, 'GET');
      expect(request.url.query, isEmpty);
      expect(request.headers.keys.map((k) => k.toLowerCase()).toSet(), {
        'user-agent',
        'accept',
        'cache-control',
      });
    });

    test('redirects are followed only on the same host', () async {
      server.redirects['/downloads/dawasa/manifest.json'] =
          'https://updates.example.test/v2/manifest.json';
      expect((await client.fetchManifest(_manifestUri)).packageName, _package);

      server.redirects['/v2/manifest.json'] = 'https://evil.example/m.json';
      await expectLater(
        client.fetchManifest(_manifestUri),
        throwsA(_failure(UpdateFailure.server)),
      );
    });

    test('server errors and broken manifests are reported', () async {
      await expectLater(
        client.fetchManifest(_base.resolve('missing.json')),
        throwsA(_failure(UpdateFailure.server)),
      );
      server.manifest = {'schema': 1};
      await expectLater(
        client.fetchManifest(_manifestUri),
        throwsA(_failure(UpdateFailure.invalidManifest)),
      );
    });

    test('downloads, verifies and reports progress', () async {
      final progress = <int>[];
      var verifying = false;
      final file = await client.download(
        release(),
        dir,
        onProgress: (received, _) => progress.add(received),
        onVerifying: () => verifying = true,
      );
      expect(await file.readAsBytes(), server.apk);
      expect(progress.last, server.apk.length);
      expect(verifying, isTrue);
      expect(p.basename(file.path), startsWith('dawasa-2-'));
      // A second call reuses the verified file.
      server.requests.clear();
      await client.download(release(), dir, onProgress: (_, _) {});
      expect(server.requests, isEmpty);
    });

    test('an interrupted download resumes with a Range request', () async {
      server.cutAfter = 100000;
      await expectLater(
        client.download(release(), dir, onProgress: (_, _) {}),
        throwsA(_failure(UpdateFailure.server)),
      );
      final part = UpdateClient.partialFile(dir, release());
      expect(part.lengthSync(), 100000);

      server.cutAfter = null;
      final file = await client.download(release(), dir, onProgress: (_, _) {});
      expect(server.requests.last.headers['Range'], 'bytes=100000-');
      expect(await file.readAsBytes(), server.apk);
    });

    test(
      'a server without Range support restarts from the beginning',
      () async {
        final part = UpdateClient.partialFile(dir, release())
          ..writeAsBytesSync(server.apk.sublist(0, 5000));
        server.honourRange = false;
        final file = await client.download(
          release(),
          dir,
          onProgress: (_, _) {},
        );
        expect(await file.readAsBytes(), server.apk);
        expect(part.existsSync(), isFalse);
      },
    );

    test('a tampered file is deleted and never offered for install', () async {
      server.apk = List<int>.from(server.apk)..[1234] ^= 0xFF;
      await expectLater(
        client.download(release(), dir, onProgress: (_, _) {}),
        throwsA(_failure(UpdateFailure.checksum)),
      );
      expect(dir.listSync(), isEmpty);
    });

    test('cancelling keeps the partial file for later', () async {
      final token = CancelToken();
      server.onChunk = (sent) {
        if (sent > 50000) token.cancel();
      };
      await expectLater(
        client.download(release(), dir, cancel: token, onProgress: (_, _) {}),
        throwsA(isA<DownloadCancelled>()),
      );
      final part = UpdateClient.partialFile(dir, release());
      expect(part.existsSync(), isTrue);
      expect(part.lengthSync(), lessThan(server.apk.length));
    });
  });

  group('update controller', () {
    late Directory root;
    late _Server server;
    late FakeApkInstaller installer;
    late FakeNetworkStatus network;
    late DateTime now;
    late SharedPreferences prefs;

    setUp(() async {
      root = Directory.systemTemp.createTempSync('dawasa_update_ctrl');
      server = _Server();
      installer = FakeApkInstaller(
        info: const ApkInfo(
          packageName: _package,
          versionCode: 2,
          signerSha256: ['aa'],
        ),
        signers: const ['aa'],
      );
      network = FakeNetworkStatus();
      now = DateTime(2026, 9, 24, 9);
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() => root.deleteSync(recursive: true));

    ProviderContainer container({
      bool enabled = true,
      String base = 'https://updates.example.test/downloads/dawasa/',
      int installedCode = 1,
      ApkInstaller? apkInstaller,
    }) {
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => now),
          secureStoreProvider.overrideWithValue(MemorySecureStore()),
          updateConfigProvider.overrideWithValue(
            UpdateConfig(
              enabled: enabled,
              defaultBaseUrl: base,
              manifestName: 'manifest.json',
            ),
          ),
          appVersionProvider.overrideWith(
            (ref) async => AppVersion(
              versionName: '1.0.0',
              versionCode: installedCode,
              packageName: _package,
            ),
          ),
          networkStatusProvider.overrideWithValue(network),
          apkInstallerProvider.overrideWithValue(apkInstaller ?? installer),
          updateClientProvider.overrideWithValue(
            UpdateClient(clientFactory: server.client, userAgent: 't'),
          ),
          dataPathsProvider.overrideWithValue(
            DataPaths(
              dataDirectory: () async => root,
              tempDirectory: () async => root,
            ),
          ),
        ],
      );
      c.listen(updateControllerProvider, (_, _) {});
      addTearDown(c.dispose);
      return c;
    }

    UpdateController ctrl(ProviderContainer c) =>
        c.read(updateControllerProvider.notifier);

    test('reports not configured and disabled builds', () {
      expect(
        container(base: '').read(updateControllerProvider),
        isA<UpdateNotConfigured>(),
      );
      expect(
        container(base: 'http://insecure.example/')
            .read(updateControllerProvider),
        isA<UpdateNotConfigured>(),
      );
      expect(
        container(enabled: false).read(updateControllerProvider),
        isA<UpdateDisabled>(),
      );
    });

    test('a user-entered server replaces the default one', () async {
      final c = container(base: '');
      await c
          .read(preferencesProvider.notifier)
          .update(
            (p) => p.copyWith(
              customUpdateUrl: 'https://updates.example.test/downloads/dawasa',
            ),
          );
      expect(c.read(updateControllerProvider), isA<UpdateIdle>());
      await ctrl(c).check();
      expect(c.read(updateControllerProvider), isA<UpdateAvailable>());
    });

    test('finds a newer version and throttles automatic checks', () async {
      final c = container();
      expect(ctrl(c).shouldAutoCheck(), isTrue);
      await ctrl(c).check();
      final state = c.read(updateControllerProvider) as UpdateAvailable;
      expect(state.release.versionName, '1.1.0');
      expect(state.required, isFalse);
      expect(c.read(preferencesProvider).lastUpdateCheck, now);

      final later = container();
      expect(ctrl(later).shouldAutoCheck(), isFalse);
      now = now.add(const Duration(hours: 25));
      expect(ctrl(later).shouldAutoCheck(), isTrue);
      await later
          .read(preferencesProvider.notifier)
          .update((p) => p.copyWith(autoCheckUpdates: false));
      expect(ctrl(later).shouldAutoCheck(), isFalse);
    });

    test('same version is up to date; old versions must update', () async {
      final same = container(installedCode: 2);
      await ctrl(same).check();
      expect(same.read(updateControllerProvider), isA<UpdateUpToDate>());

      server.manifest = _manifestJson(versionCode: 5, minimum: 3);
      final old = container();
      await ctrl(old).check();
      expect(
        (old.read(updateControllerProvider) as UpdateAvailable).required,
        isTrue,
      );
    });

    test('a manifest for a different app is rejected', () async {
      server.manifest = _manifestJson(packageName: 'com.example.other');
      final c = container();
      await ctrl(c).check();
      final state = c.read(updateControllerProvider) as UpdateFailed;
      expect(state.failure, UpdateFailure.invalidManifest);
    });

    test('offline checks say so; quiet checks stay silent', () async {
      network.kind = NetworkKind.none;
      final c = container();
      await ctrl(c).check();
      expect(c.read(updateControllerProvider), isA<UpdateOffline>());

      network.kind = NetworkKind.unmetered;
      server.manifest = {'broken': true};
      final quiet = container();
      await ctrl(quiet).check(quiet: true);
      expect(quiet.read(updateControllerProvider), isA<UpdateIdle>());
    });

    test('Wi-Fi only asks before using mobile data', () async {
      final c = container();
      await ctrl(c).check();
      network.kind = NetworkKind.metered;
      await ctrl(c).download();
      expect(c.read(updateControllerProvider), isA<UpdateWifiRequired>());
      expect(
        server.requests.where((r) => r.url.path.endsWith('.apk')),
        isEmpty,
      );

      await ctrl(c).download(allowMobileData: true);
      final ready = c.read(updateControllerProvider) as UpdateReady;
      expect(await ready.apk.readAsBytes(), server.apk);
    });

    test(
      'an APK for another app or signed by someone else is refused',
      () async {
        for (final info in const [
          ApkInfo(
            packageName: 'com.evil',
            versionCode: 2,
            signerSha256: ['aa'],
          ),
          ApkInfo(packageName: _package, versionCode: 1, signerSha256: ['aa']),
          ApkInfo(packageName: _package, versionCode: 2, signerSha256: ['bb']),
        ]) {
          installer.info = info;
          final c = container();
          await ctrl(c).check();
          await ctrl(c).download();
          final state = c.read(updateControllerProvider) as UpdateFailed;
          expect(state.failure, UpdateFailure.packageMismatch);
          expect(
            Directory(p.join(root.path, 'updates'))
                .listSync()
                .where((f) => f.path.endsWith('.apk')),
            isEmpty,
          );
        }
      },
    );

    test('the manifest can pin the signing certificate', () async {
      server.manifest = _manifestJson(certs: ['cc' * 32]);
      final c = container();
      await ctrl(c).check();
      await ctrl(c).download();
      expect(
        (c.read(updateControllerProvider) as UpdateFailed).failure,
        UpdateFailure.packageMismatch,
      );
    });

    test(
      'installing asks for permission, then hands over to Android',
      () async {
        final c = container();
        await ctrl(c).check();
        await ctrl(c).download();
        installer.allowed = false;
        await ctrl(c).install();
        expect(c.read(updateControllerProvider), isA<UpdateNeedsPermission>());
        await ctrl(c).openInstallPermissionSettings();
        expect(installer.settingsOpened, 1);

        installer.allowed = true;
        await ctrl(c).onResumed();
        expect(c.read(updateControllerProvider), isA<UpdateInstalling>());
        expect(installer.installed.single, endsWith('.apk'));

        installer.controller.add(const InstallCancelled());
        await pumpEventQueue();
        final ready = c.read(updateControllerProvider) as UpdateReady;
        expect(ready.installCancelled, isTrue);

        await ctrl(c).install();
        installer.controller.add(
          const InstallFailed('INSTALL_FAILED_NO_SPACE'),
        );
        await pumpEventQueue();
        final failed = c.read(updateControllerProvider) as UpdateFailed;
        expect(failed.failure, UpdateFailure.install);
        expect(failed.detail, 'INSTALL_FAILED_NO_SPACE');
        // "Try again" continues with the same release.
        await ctrl(c).download();
        expect(c.read(updateControllerProvider), isA<UpdateReady>());
      },
    );

    test('a platform error while installing is reported', () async {
      final c = container(apkInstaller: _ThrowingInstaller(installer));
      await ctrl(c).check();
      await ctrl(c).download();
      await ctrl(c).install();
      final failed = c.read(updateControllerProvider) as UpdateFailed;
      expect(failed.failure, UpdateFailure.install);
      expect(failed.detail, 'boom');
    });

    test('downloads for installed versions are cleaned up', () async {
      final dir = Directory(p.join(root.path, 'updates'))..createSync();
      final old = File(p.join(dir.path, 'dawasa-1-abcdefabcdef.apk'))
        ..writeAsBytesSync([1]);
      final newer = File(p.join(dir.path, 'dawasa-9-abcdefabcdef.apk'))
        ..writeAsBytesSync([1]);
      final c = container(installedCode: 2);
      await ctrl(c).cleanupDownloads();
      expect(old.existsSync(), isFalse);
      expect(newer.existsSync(), isTrue);
    });
  });
}

class _ThrowingInstaller implements ApkInstaller {
  _ThrowingInstaller(this.inner);

  final FakeApkInstaller inner;

  @override
  Future<bool> canRequestInstalls() async => true;

  @override
  Future<ApkInfo?> inspect(String path) => inner.inspect(path);

  @override
  Future<void> install(String path) =>
      throw PlatformException(code: 'update_error', message: 'boom');

  @override
  Future<List<String>> installedSigners() => inner.installedSigners();

  @override
  Future<void> openInstallPermissionSettings() async {}

  @override
  Stream<InstallStatus> get statuses => const Stream.empty();
}
