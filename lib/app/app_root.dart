import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/app_database.dart';
import '../core/database/connection.dart';
import '../core/notifications/notification_providers.dart';
import '../core/notifications/notification_service.dart';
import '../core/platform/data_paths.dart';
import '../core/providers.dart';
import '../core/settings/user_settings.dart';
import '../ui/theme/app_theme.dart';
import '../ui/widgets/brand.dart';
import 'app.dart';

/// Owns the database connection and the [ProviderScope]. Reloading creates a
/// fresh scope so that every provider re-reads the (possibly restored) data.
class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    required this.preferences,
    required this.notificationGateway,
    this.openDatabase,
    this.overrides = const [],
  });

  final SharedPreferences preferences;
  final NotificationGateway notificationGateway;

  /// Custom database opener (tests use an in-memory database).
  final Future<AppDatabase> Function()? openDatabase;

  /// Extra provider overrides (tests replace platform services).
  final List<Override> overrides;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  AppDatabase? _db;
  UserSettings? _settings;
  Key _scopeKey = UniqueKey();
  Object? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<AppDatabase> _defaultOpen() async =>
      AppDatabase(openDatabaseConnection(await databaseFile()));

  Future<void> _open() async {
    try {
      final db = await (widget.openDatabase ?? _defaultOpen)();
      final settings = await UserSettingsRepository(db).load();
      if (!mounted) {
        await db.close();
        return;
      }
      setState(() {
        _db = db;
        _settings = settings;
        _scopeKey = UniqueKey();
        _error = null;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _reload({Future<void> Function()? whileClosed}) async {
    final db = _db;
    setState(() {
      _db = null;
      _settings = null;
    });
    await db?.close();
    try {
      await whileClosed?.call();
    } finally {
      await _open();
    }
  }

  @override
  void dispose() {
    _db?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = _db;
    final settings = _settings;
    if (db == null || settings == null) {
      return _Splash(error: _error, onRetry: _open);
    }
    return ProviderScope(
      key: _scopeKey,
      retry: (retryCount, error) => null,
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(widget.preferences),
        initialUserSettingsProvider.overrideWithValue(settings),
        notificationGatewayProvider.overrideWithValue(
          widget.notificationGateway,
        ),
        appReloaderProvider.overrideWithValue(_reload),
        ...widget.overrides,
      ],
      child: const DawasaApp(),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DawasaLogo(size: 88),
              const SizedBox(height: Gap.xl),
              if (error == null)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Gap.xl),
                  child: Text(
                    'DAWASA could not open its data.\nදත්ත විවෘත කළ නොහැකි විය.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: Gap.md),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again / නැවත උත්සාහ කරන්න'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
