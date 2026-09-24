import 'dart:convert';

import 'package:dawasa/features/updates/application/update_controller.dart';
import 'package:dawasa/features/updates/data/network_status.dart';
import 'package:dawasa/features/updates/data/update_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/test_harness.dart';
import 'app_flow_test.dart' show usePhoneScreen;
import 'security_flow_test.dart' show openSettings, scrollTo;

final _manifest = {
  'schema': 1,
  'app': 'dawasa',
  'packageName': 'com.sandarutharushka.dawasa',
  'minimumSupportedVersionCode': 1,
  'latest': {
    'versionName': '1.1.0',
    'versionCode': 2,
    'apkUrl': 'dawasa-1.1.0-2.apk',
    'sha256': 'a' * 64,
    'sizeBytes': 15 * 1024 * 1024,
    'releaseNotes': {'en': 'Faster reports and bug fixes'},
  },
};

void main() {
  testWidgets('an available update is announced and asks before using data', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final requests = <http.BaseRequest>[];
    final platform = TestPlatform()
      ..network.kind = NetworkKind.metered
      ..updateConfig = const UpdateConfig(
        enabled: true,
        defaultBaseUrl: 'https://updates.example.test/dawasa/',
        manifestName: 'manifest.json',
      )
      ..updateClient = UpdateClient(
        clientFactory: () => MockClient((request) async {
          requests.add(request);
          return http.Response(jsonEncode(_manifest), 200);
        }),
        userAgent: 'test',
      );
    final db = await pumpDawasaApp(
      tester,
      preferences: onboardedPrefs,
      platform: platform,
    );

    // The automatic check ran once on launch.
    expect(requests.single.url.path, '/dawasa/manifest.json');
    expect(find.text('A new version of DAWASA is available'), findsOneWidget);

    await tester.tap(find.text('A new version of DAWASA is available'));
    await settle(tester);
    expect(find.text('Update available: 1.1.0'), findsOneWidget);
    expect(find.text('Faster reports and bug fixes'), findsOneWidget);
    expect(find.text('Download size: 15.0 MB'), findsOneWidget);
    expect(find.text('Updating keeps all your data.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('update-now')));
    await settle(tester);
    expect(
      find.text('You are on mobile data and "Wi-Fi only" is on.'),
      findsOneWidget,
    );
    expect(find.text('Download anyway'), findsOneWidget);
    // Nothing was downloaded without the user's consent.
    expect(requests, hasLength(1));
    await disposeApp(tester, db);
  });

  testWidgets('an update server can be entered (https only)', (tester) async {
    usePhoneScreen(tester);
    final db = await pumpDawasaApp(tester, preferences: onboardedPrefs);
    await openSettings(tester);
    await scrollTo(tester, find.text('App updates'));
    expect(find.text('Installed: 1.0.0'), findsOneWidget);
    await tester.tap(find.text('App updates'));
    await settle(tester);

    expect(
      find.textContaining('enter the HTTPS address of the DAWASA update'),
      findsOneWidget,
    );
    await tester.tap(find.text('Update server'));
    await settle(tester);
    final field = find.byKey(const ValueKey('update-server-url'));
    await tester.enterText(field, 'http://example.com/dawasa');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Enter a valid https:// address'), findsOneWidget);

    await tester.enterText(field, 'https://example.com/dawasa');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('https://example.com/dawasa'), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
    await disposeApp(tester, db);
  });
}
