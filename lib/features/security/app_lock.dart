import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/security/biometrics.dart';
import '../../core/security/pin_hasher.dart';
import '../../core/security/secure_store.dart';

final pinHasherProvider = Provider<PinHasher>((ref) => const PinHasher());

enum LockPhase {
  /// Reading the lock settings from secure storage.
  loading,
  unlocked,
  locked,
}

@immutable
class AppLockState {
  const AppLockState({
    required this.phase,
    this.pinEnabled = false,
    this.pinLength,
    this.biometricEnabled = false,
    this.failedAttempts = 0,
    this.pausedUntil,
  });

  final LockPhase phase;
  final bool pinEnabled;

  /// Length of the PIN, so the keypad can submit automatically.
  final int? pinLength;
  final bool biometricEnabled;
  final int failedAttempts;

  /// Unlocking with the PIN is paused until then after repeated failures.
  final DateTime? pausedUntil;

  bool get isLocked => phase == LockPhase.locked;

  AppLockState copyWith({
    LockPhase? phase,
    bool? pinEnabled,
    int? pinLength,
    bool? biometricEnabled,
    int? failedAttempts,
    DateTime? pausedUntil,
    bool clearPause = false,
  }) => AppLockState(
    phase: phase ?? this.phase,
    pinEnabled: pinEnabled ?? this.pinEnabled,
    pinLength: pinLength ?? this.pinLength,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    pausedUntil: clearPause ? null : (pausedUntil ?? this.pausedUntil),
  );
}

sealed class PinAttempt {
  const PinAttempt();
}

class PinAccepted extends PinAttempt {
  const PinAccepted();
}

class PinRejected extends PinAttempt {
  const PinRejected(this.attemptsLeft);

  /// Wrong PINs still allowed before unlocking is paused.
  final int attemptsLeft;
}

class PinPaused extends PinAttempt {
  const PinPaused(this.remaining);

  final Duration remaining;
}

/// The optional app lock (PIN plus fingerprint/face).
///
/// Only an Argon2id hash of the PIN is stored, in Android Keystore-backed
/// secure storage. Wrong attempts are counted persistently, so restarting
/// the app does not reset the back-off.
class AppLockController extends Notifier<AppLockState> {
  static const kPin = 'dawasa.lock.pin';
  static const kPinLength = 'dawasa.lock.pinLength';
  static const kBiometric = 'dawasa.lock.biometric';
  static const kFailures = 'dawasa.lock.failures';
  static const kPausedUntil = 'dawasa.lock.pausedUntil';

  /// How long the app may stay in the background while the user is in a
  /// file picker, share sheet or installer opened by the app itself.
  static const externalActivityGrace = Duration(minutes: 5);

  PinHash? _pin;
  DateTime? _backgroundedAt;
  bool _backgroundedDuringExternal = false;
  int _external = 0;

  final Completer<void> _loaded = Completer<void>();

  /// Completes once the lock settings have been read.
  Future<void> get loaded => _loaded.future;

  SecureStore get _store => ref.read(secureStoreProvider);
  DateTime _now() => ref.read(clockProvider)();

  @override
  AppLockState build() {
    unawaited(_load());
    return const AppLockState(phase: LockPhase.loading);
  }

  Future<void> _load() async {
    PinHash? pin;
    var biometric = false;
    var failures = 0;
    int? length;
    DateTime? pausedUntil;
    try {
      pin = PinHash.decode(await _store.read(kPin));
      if (pin != null) {
        length = int.tryParse(await _store.read(kPinLength) ?? '');
        biometric = await _store.read(kBiometric) == 'true';
        failures = int.tryParse(await _store.read(kFailures) ?? '') ?? 0;
        pausedUntil = DateTime.tryParse(await _store.read(kPausedUntil) ?? '');
      }
    } on Object catch (e) {
      // Secure storage failed: the lock cannot be enforced, but the user's
      // data stays available (the lock is a privacy screen, not encryption).
      debugPrint('Could not read lock settings: $e');
    }
    _pin = pin;
    state = AppLockState(
      phase: pin == null ? LockPhase.unlocked : LockPhase.locked,
      pinEnabled: pin != null,
      pinLength: length,
      biometricEnabled: pin != null && biometric,
      failedAttempts: failures,
      pausedUntil: pausedUntil,
    );
    if (!_loaded.isCompleted) _loaded.complete();
  }

  /// Time left before the PIN may be tried again, or null.
  Duration? pauseRemaining() {
    final until = state.pausedUntil;
    if (until == null) return null;
    final remaining = until.difference(_now());
    if (remaining <= Duration.zero) return null;
    // Guards against the clock being moved backwards.
    return remaining > PinPolicy.maxDelay ? PinPolicy.maxDelay : remaining;
  }

  /// Checks [pin] without changing the lock state (used before changing or
  /// removing the PIN). Wrong attempts count towards the back-off.
  Future<PinAttempt> checkPin(String pin) async {
    final paused = pauseRemaining();
    if (paused != null) return PinPaused(paused);
    final stored = _pin;
    if (stored == null) return const PinAccepted();
    if (await ref.read(pinHasherProvider).verify(pin, stored)) {
      await _resetFailures();
      return const PinAccepted();
    }
    final failures = state.failedAttempts + 1;
    final delay = PinPolicy.delayAfter(failures);
    final until = delay == null ? null : _now().add(delay);
    await _store.write(kFailures, '$failures');
    if (until != null) {
      await _store.write(kPausedUntil, until.toIso8601String());
    }
    state = state.copyWith(failedAttempts: failures, pausedUntil: until);
    return delay == null
        ? PinRejected(PinPolicy.freeAttempts - failures)
        : PinPaused(delay);
  }

  Future<PinAttempt> unlockWithPin(String pin) async {
    final result = await checkPin(pin);
    if (result is PinAccepted) _unlock();
    return result;
  }

  Future<bool> unlockWithBiometrics(String reason) async {
    if (!state.biometricEnabled || !state.isLocked) return false;
    final ok = await whileExternal(
      () => ref.read(biometricAuthenticatorProvider).authenticate(reason),
    );
    if (ok) {
      await _resetFailures();
      _unlock();
    }
    return ok;
  }

  Future<void> _resetFailures() async {
    if (state.failedAttempts == 0 && state.pausedUntil == null) return;
    await _store.delete(kFailures);
    await _store.delete(kPausedUntil);
    state = state.copyWith(failedAttempts: 0, clearPause: true);
  }

  void _unlock() {
    _backgroundedAt = null;
    state = state.copyWith(phase: LockPhase.unlocked);
  }

  void lock() {
    if (!state.pinEnabled) return;
    state = state.copyWith(phase: LockPhase.locked);
    if (ref.read(preferencesProvider).hideBalancesOnStart) {
      ref.read(balancesHiddenProvider.notifier).set(true);
    }
  }

  // ------------------------------------------------------------ settings

  Future<void> setPin(String pin) async {
    final hash = await ref.read(pinHasherProvider).hash(pin);
    await _store.write(kPin, hash.encode());
    await _store.write(kPinLength, '${pin.length}');
    await _store.delete(kFailures);
    await _store.delete(kPausedUntil);
    _pin = hash;
    state = state.copyWith(
      phase: LockPhase.unlocked,
      pinEnabled: true,
      pinLength: pin.length,
      failedAttempts: 0,
      clearPause: true,
    );
  }

  Future<void> removePin() async {
    for (final key in const [
      kPin,
      kPinLength,
      kBiometric,
      kFailures,
      kPausedUntil,
    ]) {
      await _store.delete(key);
    }
    _pin = null;
    state = const AppLockState(phase: LockPhase.unlocked);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (!state.pinEnabled) return;
    await _store.write(kBiometric, '$enabled');
    state = state.copyWith(biometricEnabled: enabled);
  }

  // ----------------------------------------------------------- lifecycle

  /// Runs [action] (a picker, share sheet, system prompt or installer that
  /// the app opened itself) without locking when the user comes back soon.
  Future<T> whileExternal<T>(Future<T> Function() action) async {
    _external++;
    try {
      return await action();
    } finally {
      _external--;
    }
  }

  void onBackgrounded() {
    if (!state.pinEnabled || state.phase != LockPhase.unlocked) return;
    _backgroundedAt ??= _now();
    _backgroundedDuringExternal = _external > 0;
  }

  void onForegrounded() {
    final at = _backgroundedAt;
    _backgroundedAt = null;
    if (at == null || !state.pinEnabled || state.phase != LockPhase.unlocked) {
      return;
    }
    var timeout = Duration(
      seconds: ref.read(preferencesProvider).lockTimeoutSeconds,
    );
    if (_backgroundedDuringExternal && timeout < externalActivityGrace) {
      timeout = externalActivityGrace;
    }
    final away = _now().difference(at);
    if (away.isNegative || away >= timeout) lock();
  }
}

final appLockProvider = NotifierProvider<AppLockController, AppLockState>(
  AppLockController.new,
);
