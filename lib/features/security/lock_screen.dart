import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/brand.dart';
import '../backup/presentation/delete_all.dart';
import 'app_lock.dart';
import 'pin_pad.dart';

String formatWait(Duration d) {
  final total = d.inSeconds + (d.inMilliseconds % 1000 == 0 ? 0 : 1);
  final minutes = total ~/ 60;
  final seconds = (total % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Full-screen lock shown above the whole app while it is locked.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pad = GlobalKey<PinPadState>();
  String? _error;
  bool _busy = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startTickerIfPaused();
    if (ref.read(appLockProvider).biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _biometric());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTickerIfPaused() {
    _ticker?.cancel();
    if (ref.read(appLockProvider.notifier).pauseRemaining() == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = ref.read(appLockProvider.notifier).pauseRemaining();
      if (remaining == null) {
        _ticker?.cancel();
        _ticker = null;
        setState(() => _error = null);
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _biometric() async {
    if (!mounted || _busy) return;
    final reason = context.l10n.securityBiometricReason;
    await ref.read(appLockProvider.notifier).unlockWithBiometrics(reason);
  }

  Future<void> _submit(String pin) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final result = await ref.read(appLockProvider.notifier).unlockWithPin(pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = switch (result) {
        PinAccepted() => null,
        PinRejected(:final attemptsLeft) => l10n.securityWrongPin(attemptsLeft),
        PinPaused() => null,
      };
    });
    if (result is! PinAccepted) {
      _pad.currentState?.clear();
      _startTickerIfPaused();
    }
  }

  Future<void> _forgotPin() async {
    final l10n = context.l10n;
    final erase = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.securityForgotPin),
        content: Text(l10n.securityForgotPinBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.securityDeleteAndReset),
          ),
        ],
      ),
    );
    if (erase != true || !mounted) return;
    if (!await confirmDeleteAll(context)) return;
    await deleteAllData(ref);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lock = ref.watch(appLockProvider);
    final paused = ref.read(appLockProvider.notifier).pauseRemaining();
    final error = paused != null
        ? l10n.securityPausedFor(formatWait(paused))
        : _error;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.xl,
                  vertical: Gap.lg,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const DawasaLogo(size: 64),
                    const SizedBox(height: Gap.lg),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.securityUnlockTitle,
                        style: context.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: Gap.xs),
                    Text(
                      l10n.securityEnterPin,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Gap.xl),
                    PinPad(
                      key: _pad,
                      length: lock.pinLength,
                      enabled: paused == null,
                      busy: _busy,
                      errorText: error,
                      onCompleted: _submit,
                      onBiometric: lock.biometricEnabled ? _biometric : null,
                    ),
                    const SizedBox(height: Gap.md),
                    TextButton(
                      onPressed: _busy ? null : _forgotPin,
                      child: Text(l10n.securityForgotPin),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
