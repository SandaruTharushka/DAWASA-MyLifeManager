import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../utils/isolate_runner.dart';

/// Stored form of the app PIN: an Argon2id hash with a random salt. The PIN
/// itself is never stored.
class PinHash {
  const PinHash({
    required this.salt,
    required this.hash,
    required this.memoryKiB,
    required this.iterations,
  });

  final List<int> salt;
  final List<int> hash;
  final int memoryKiB;
  final int iterations;

  String encode() => jsonEncode({
    'v': 1,
    'alg': 'argon2id',
    'm': memoryKiB,
    't': iterations,
    'salt': base64Encode(salt),
    'hash': base64Encode(hash),
  });

  static PinHash? decode(String? value) {
    if (value == null) return null;
    try {
      final json = jsonDecode(value) as Map<String, Object?>;
      if (json['v'] != 1 || json['alg'] != 'argon2id') return null;
      return PinHash(
        salt: base64Decode(json['salt']! as String),
        hash: base64Decode(json['hash']! as String),
        memoryKiB: json['m']! as int,
        iterations: json['t']! as int,
      );
    } on Object {
      return null;
    }
  }
}

/// Hashes and verifies PINs with Argon2id in a background isolate.
class PinHasher {
  const PinHasher({
    this.memoryKiB = 12288,
    this.iterations = 2,
    this.runner = runInIsolate,
  });

  final int memoryKiB;
  final int iterations;
  final TaskRunner runner;

  Future<PinHash> hash(String pin) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final m = memoryKiB;
    final t = iterations;
    final bytes = await runner(() => _derive(pin, salt, m, t));
    return PinHash(salt: salt, hash: bytes, memoryKiB: m, iterations: t);
  }

  Future<bool> verify(String pin, PinHash stored) async {
    final salt = stored.salt;
    final m = stored.memoryKiB;
    final t = stored.iterations;
    final bytes = await runner(() => _derive(pin, salt, m, t));
    return constantTimeEquals(bytes, stored.hash);
  }

  static Future<List<int>> _derive(
    String pin,
    List<int> salt,
    int memoryKiB,
    int iterations,
  ) async {
    final kdf = Argon2id(
      parallelism: 1,
      memory: memoryKiB,
      iterations: iterations,
      hashLength: 32,
    );
    final key = await kdf.deriveKeyFromPassword(password: pin, nonce: salt);
    return key.extractBytes();
  }
}

bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

enum PinProblem { length, digitsOnly, tooSimple }

abstract final class PinPolicy {
  static const int minLength = 4;
  static const int maxLength = 6;

  /// Failed attempts allowed before unlocking is paused.
  static const int freeAttempts = 5;

  static const List<Duration> _delays = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
  ];

  static PinProblem? validate(String pin) {
    if (!RegExp(r'^\d*$').hasMatch(pin)) return PinProblem.digitsOnly;
    if (pin.length < minLength || pin.length > maxLength) {
      return PinProblem.length;
    }
    final digits = pin.codeUnits.map((c) => c - 0x30).toList();
    final same = digits.every((d) => d == digits.first);
    bool step(int delta) {
      for (var i = 1; i < digits.length; i++) {
        if (digits[i] - digits[i - 1] != delta) return false;
      }
      return true;
    }

    if (same || step(1) || step(-1)) return PinProblem.tooSimple;
    return null;
  }

  /// How long unlocking is paused after [failures] consecutive wrong PINs.
  static Duration? delayAfter(int failures) {
    if (failures < freeAttempts) return null;
    final index = (failures - freeAttempts).clamp(0, _delays.length - 1);
    return _delays[index];
  }

  static Duration get maxDelay => _delays.last;
}
