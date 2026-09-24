import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/security/pin_hasher.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/common.dart';
import 'app_lock.dart';
import 'lock_screen.dart';
import 'pin_pad.dart';

enum PinSetupMode { create, change, remove }

enum _Stage { current, create, confirm }

/// Sets, changes or removes the app PIN. Changing and removing first ask
/// for the current PIN (wrong attempts count towards the back-off).
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key, required this.mode});

  final PinSetupMode mode;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pad = GlobalKey<PinPadState>();
  late _Stage _stage = widget.mode == PinSetupMode.create
      ? _Stage.create
      : _Stage.current;
  String? _firstPin;
  String? _error;
  bool _busy = false;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _reset({String? error, _Stage? stage}) {
    setState(() {
      _error = error;
      if (stage != null) _stage = stage;
    });
    _pad.currentState?.clear();
  }

  Future<void> _onPin(String pin) async {
    final l10n = context.l10n;
    switch (_stage) {
      case _Stage.current:
        setState(() => _busy = true);
        final result = await ref.read(appLockProvider.notifier).checkPin(pin);
        if (!mounted) return;
        setState(() => _busy = false);
        switch (result) {
          case PinAccepted():
            if (widget.mode == PinSetupMode.remove) {
              await ref.read(appLockProvider.notifier).removePin();
              if (!mounted) return;
              showAppSnackBar(context, l10n.securityPinRemoved);
              context.pop(true);
            } else {
              _reset(stage: _Stage.create);
            }
          case PinRejected(:final attemptsLeft):
            _reset(error: l10n.securityWrongPin(attemptsLeft));
          case PinPaused():
            _reset();
            _startTicker();
        }
      case _Stage.create:
        final problem = PinPolicy.validate(pin);
        if (problem != null) {
          _reset(
            error: switch (problem) {
              PinProblem.tooSimple => l10n.securityPinTooSimple,
              PinProblem.length ||
              PinProblem.digitsOnly => l10n.securityCreatePinDesc,
            },
          );
          return;
        }
        _firstPin = pin;
        _reset(stage: _Stage.confirm);
      case _Stage.confirm:
        if (pin != _firstPin) {
          _firstPin = null;
          _reset(error: l10n.securityPinMismatch, stage: _Stage.create);
          return;
        }
        setState(() => _busy = true);
        await ref.read(appLockProvider.notifier).setPin(pin);
        if (!mounted) return;
        showAppSnackBar(context, l10n.securityPinSet);
        context.pop(true);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (ref.read(appLockProvider.notifier).pauseRemaining() == null) {
        _ticker?.cancel();
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lock = ref.watch(appLockProvider);
    final paused = _stage == _Stage.current
        ? ref.read(appLockProvider.notifier).pauseRemaining()
        : null;
    final (title, body) = switch (_stage) {
      _Stage.current => (l10n.securityEnterCurrentPin, null),
      _Stage.create => (l10n.securityCreatePin, l10n.securityCreatePinDesc),
      _Stage.confirm => (l10n.securityConfirmPin, null),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (widget.mode) {
          PinSetupMode.create => l10n.securitySetPin,
          PinSetupMode.change => l10n.securityChangePin,
          PinSetupMode.remove => l10n.securityRemovePin,
        }),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.xl),
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 40,
              color: context.colors.primary,
            ),
            const SizedBox(height: Gap.md),
            Text(
              title,
              key: ValueKey('pin-stage-${_stage.name}'),
              style: context.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: Gap.xs),
              Text(
                body,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: Gap.xl),
            PinPad(
              key: _pad,
              length: switch (_stage) {
                _Stage.current => lock.pinLength,
                _Stage.create => null,
                _Stage.confirm => _firstPin?.length,
              },
              enabled: paused == null,
              busy: _busy,
              errorText: paused != null
                  ? l10n.securityPausedFor(formatWait(paused))
                  : _error,
              onCompleted: _onPin,
            ),
          ],
        ),
      ),
    );
  }
}
