import 'package:dawasa/core/providers.dart';
import 'package:dawasa/core/security/biometrics.dart';
import 'package:dawasa/core/security/pin_hasher.dart';
import 'package:dawasa/core/security/secure_store.dart';
import 'package:dawasa/core/utils/isolate_runner.dart';
import 'package:dawasa/features/security/app_lock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _hasher = PinHasher(memoryKiB: 64, iterations: 1, runner: runInline);

class _Env {
  _Env(this.prefs, {MemorySecureStore? store})
    : store = store ?? MemorySecureStore();

  final SharedPreferences prefs;
  final MemorySecureStore store;
  final biometrics = FakeBiometricAuthenticator();
  DateTime now = DateTime(2026, 9, 24, 10);

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        secureStoreProvider.overrideWithValue(store),
        biometricAuthenticatorProvider.overrideWithValue(biometrics),
        pinHasherProvider.overrideWithValue(_hasher),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }
}

Future<(ProviderContainer, AppLockController)> _loaded(_Env env) async {
  final c = env.container();
  // Keep the provider alive for the whole test.
  c.listen(appLockProvider, (_, _) {});
  final controller = c.read(appLockProvider.notifier);
  await controller.loaded;
  return (c, controller);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PIN policy', () {
    test('accepts 4 to 6 digits that are not trivial', () {
      expect(PinPolicy.validate('2580'), isNull);
      expect(PinPolicy.validate('135790'), isNull);
      expect(PinPolicy.validate('12'), PinProblem.length);
      expect(PinPolicy.validate('1234567'), PinProblem.length);
      expect(PinPolicy.validate('12a4'), PinProblem.digitsOnly);
      for (final weak in ['1111', '000000', '1234', '4321', '456789']) {
        expect(PinPolicy.validate(weak), PinProblem.tooSimple, reason: weak);
      }
    });

    test('pauses grow after five wrong attempts and are capped', () {
      expect(PinPolicy.delayAfter(4), isNull);
      expect(PinPolicy.delayAfter(5), const Duration(seconds: 30));
      expect(PinPolicy.delayAfter(6), const Duration(minutes: 1));
      expect(PinPolicy.delayAfter(7), const Duration(minutes: 5));
      expect(PinPolicy.delayAfter(50), PinPolicy.maxDelay);
    });
  });

  group('PIN hashing', () {
    test('verifies the right PIN only and never stores it', () async {
      final a = await _hasher.hash('2580');
      final b = await _hasher.hash('2580');
      expect(a.salt, isNot(b.salt));
      expect(a.hash, isNot(b.hash));
      expect(await _hasher.verify('2580', a), isTrue);
      expect(await _hasher.verify('2581', a), isFalse);
      final encoded = a.encode();
      expect(encoded, isNot(contains('2580')));
      final decoded = PinHash.decode(encoded)!;
      expect(await _hasher.verify('2580', decoded), isTrue);
      expect(PinHash.decode('not json'), isNull);
      expect(PinHash.decode(null), isNull);
    });

    test('production cost settings work in a background isolate', () async {
      const hasher = PinHasher();
      final hash = await hasher.hash('802468');
      expect(hash.memoryKiB, greaterThanOrEqualTo(8192));
      expect(await hasher.verify('802468', hash), isTrue);
    });

    test('constant time comparison', () {
      expect(constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
      expect(constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
      expect(constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
    });
  });

  group('app lock', () {
    late _Env env;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      env = _Env(await SharedPreferences.getInstance());
    });

    test('without a PIN the app is never locked', () async {
      final (c, lock) = await _loaded(env);
      expect(c.read(appLockProvider).phase, LockPhase.unlocked);
      lock
        ..onBackgrounded()
        ..onForegrounded()
        ..lock();
      expect(c.read(appLockProvider).isLocked, isFalse);
    });

    test('a saved PIN locks the app on start and unlocks with it', () async {
      final (_, first) = await _loaded(env);
      await first.setPin('2580');
      expect(env.store.values.values.join(), isNot(contains('2580')));

      final (c, lock) = await _loaded(env);
      expect(c.read(appLockProvider).phase, LockPhase.locked);
      expect(c.read(appLockProvider).pinLength, 4);
      expect(await lock.unlockWithPin('2580'), isA<PinAccepted>());
      expect(c.read(appLockProvider).phase, LockPhase.unlocked);
    });

    test('wrong PINs pause unlocking, even across restarts', () async {
      final (_, setup) = await _loaded(env);
      await setup.setPin('2580');
      final (c, lock) = await _loaded(env);

      for (var left = 4; left >= 1; left--) {
        final r = await lock.unlockWithPin('0000');
        expect(r, isA<PinRejected>());
        expect((r as PinRejected).attemptsLeft, left);
      }
      final paused = await lock.unlockWithPin('0000');
      expect(paused, isA<PinPaused>());
      expect((paused as PinPaused).remaining, const Duration(seconds: 30));
      // The right PIN is not even checked during the pause.
      expect(await lock.unlockWithPin('2580'), isA<PinPaused>());
      expect(c.read(appLockProvider).isLocked, isTrue);

      // Restarting the app keeps the pause.
      final (_, restarted) = await _loaded(env);
      expect(restarted.pauseRemaining(), const Duration(seconds: 30));

      env.now = env.now.add(const Duration(seconds: 31));
      expect(await restarted.unlockWithPin('2580'), isA<PinAccepted>());
      expect(
        env.store.values.containsKey(AppLockController.kFailures),
        isFalse,
      );

      // The next wrong PIN starts counting from the beginning again.
      restarted.lock();
      final again = await restarted.unlockWithPin('1357');
      expect((again as PinRejected).attemptsLeft, 4);
    });

    test('moving the clock back cannot extend a pause forever', () async {
      final (_, setup) = await _loaded(env);
      await setup.setPin('2580');
      env.store.values[AppLockController.kPausedUntil] = DateTime(2030)
          .toIso8601String();
      final (_, lock) = await _loaded(env);
      expect(lock.pauseRemaining(), PinPolicy.maxDelay);
    });

    test('locks after the chosen time in the background', () async {
      final (c, lock) = await _loaded(env);
      await lock.setPin('2580');
      await c
          .read(preferencesProvider.notifier)
          .update((p) => p.copyWith(lockTimeoutSeconds: 60));

      lock.onBackgrounded();
      env.now = env.now.add(const Duration(seconds: 30));
      lock.onForegrounded();
      expect(c.read(appLockProvider).isLocked, isFalse);

      lock.onBackgrounded();
      env.now = env.now.add(const Duration(seconds: 61));
      lock.onForegrounded();
      expect(c.read(appLockProvider).isLocked, isTrue);
    });

    test('"immediately" locks on every return to the app', () async {
      final (c, lock) = await _loaded(env);
      await lock.setPin('2580');
      lock
        ..onBackgrounded()
        ..onForegrounded();
      expect(c.read(appLockProvider).isLocked, isTrue);
    });

    test('file pickers opened by the app get a short grace period', () async {
      final (c, lock) = await _loaded(env);
      await lock.setPin('2580');

      await lock.whileExternal(() async {
        lock.onBackgrounded();
        env.now = env.now.add(const Duration(minutes: 2));
      });
      lock.onForegrounded();
      expect(c.read(appLockProvider).isLocked, isFalse);

      await lock.whileExternal(() async {
        lock.onBackgrounded();
        env.now = env.now.add(const Duration(minutes: 6));
      });
      lock.onForegrounded();
      expect(c.read(appLockProvider).isLocked, isTrue);
    });

    test('locking hides balances when that option is on', () async {
      final (c, lock) = await _loaded(env);
      await lock.setPin('2580');
      await c
          .read(preferencesProvider.notifier)
          .update((p) => p.copyWith(hideBalancesOnStart: true));
      c.read(balancesHiddenProvider.notifier).set(false);
      lock.lock();
      expect(c.read(balancesHiddenProvider), isTrue);
    });

    test('biometric unlock only works when enabled and confirmed', () async {
      final (c, lock) = await _loaded(env);
      await lock.setPin('2580');
      env.biometrics.available = true;
      lock.lock();
      expect(await lock.unlockWithBiometrics('Unlock'), isFalse);
      expect(env.biometrics.prompts, 0);

      await lock.setBiometricEnabled(true);
      env.biometrics.succeed = false;
      expect(await lock.unlockWithBiometrics('Unlock'), isFalse);
      expect(c.read(appLockProvider).isLocked, isTrue);

      env.biometrics.succeed = true;
      expect(await lock.unlockWithBiometrics('Unlock'), isTrue);
      expect(c.read(appLockProvider).isLocked, isFalse);
    });

    test('removing the PIN deletes every stored secret', () async {
      final (c, lock) = await _loaded(env);
      await lock.setPin('2580');
      await lock.setBiometricEnabled(true);
      await lock.removePin();
      expect(env.store.values, isEmpty);
      expect(c.read(appLockProvider).pinEnabled, isFalse);
    });
  });
}
