import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/l10n.dart';
import '../core/providers.dart';
import '../ui/theme/app_theme.dart';
import 'app_gate.dart';
import 'router.dart';
import 'startup.dart';

class DawasaApp extends ConsumerStatefulWidget {
  const DawasaApp({super.key});

  @override
  ConsumerState<DawasaApp> createState() => _DawasaAppState();
}

class _DawasaAppState extends ConsumerState<DawasaApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.read(todayProvider.notifier).refresh();
        ref.read(startupTasksProvider).onResume();
      },
      onPause: () => ref.read(startupTasksProvider).onPause(),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(startupTasksProvider).onLaunch(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final languageCode = ref.watch(localeNameProvider);
    final themeMode = ref.watch(preferencesProvider.select((p) => p.themeMode));
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: Locale(languageCode),
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => AppGate(child: child ?? const SizedBox()),
    );
  }
}
