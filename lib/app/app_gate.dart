import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/l10n.dart';
import '../core/platform/platform_bridge.dart';
import '../core/providers.dart';
import '../features/backup/data/data_wiper.dart';
import '../features/backup/presentation/restore_screen.dart';
import '../features/security/app_lock.dart';
import '../features/security/lock_screen.dart';
import '../ui/widgets/brand.dart';
import '../ui/widgets/common.dart';

/// Wraps the whole app below the router: applies screen protection, locks
/// the app when it returns from the background and shows the lock screen
/// on top of everything while locked.
class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onPause: () => ref.read(appLockProvider.notifier).onBackgrounded(),
      onResume: () => ref.read(appLockProvider.notifier).onForegrounded(),
    );
    ref.listenManual(
      preferencesProvider.select((p) => p.screenProtection),
      (_, enabled) =>
          ref.read(platformBridgeProvider).setScreenProtection(enabled),
      fireImmediately: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _showNotice());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _showNotice() {
    if (!mounted) return;
    final notice = ref.read(preferencesStoreProvider).takeNotice();
    if (notice == null) return;
    final l10n = context.l10n;
    final message = switch (notice) {
      AppNotices.restored => l10n.restoreCompleted,
      AppNotices.restoreFailed => l10n.restoreFailedKept,
      DataWiper.notice => l10n.deleteAllDone,
      _ => null,
    };
    if (message != null) showAppSnackBar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(appLockProvider.select((s) => s.phase));
    final hidden = phase != LockPhase.unlocked;
    return Stack(
      children: [
        // Content under the lock is neither painted nor reachable by
        // accessibility services.
        Offstage(
          offstage: hidden,
          child: TickerMode(enabled: !hidden, child: widget.child),
        ),
        if (phase == LockPhase.loading)
          const Positioned.fill(child: _Cover())
        else if (phase == LockPhase.locked)
          Positioned.fill(
            child: Navigator(
              onGenerateRoute: (_) =>
                  MaterialPageRoute<void>(builder: (_) => const LockScreen()),
            ),
          ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: const Center(child: DawasaLogo(size: 72)),
    );
  }
}
