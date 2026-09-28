import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';

import '../entities/pin_credential.dart';

/// Pure PIN hashing service (contracts/app_lock_repository.md) — no I/O,
/// no `Either`. The raw PIN only ever lives for the duration of one call.
abstract class PinHasher {
  /// Validates [rawPin] is 4-6 ASCII digits (FR-003); throws [ArgumentError]
  /// if not. Callers translate that into a typed `Failure`.
  void validate(String rawPin);

  /// Generates a fresh random salt and derives a [PinCredential] via
  /// PBKDF2-HMAC-SHA256 (research.md Decision 7). Validates first.
  PinCredential hash(String rawPin);

  /// Re-derives [rawPin] with [credential]'s salt/iterations and compares
  /// the result to [credential]'s hash in constant time.
  bool verify(String rawPin, PinCredential credential);
}

/// PBKDF2-HMAC-SHA256 over a 16-byte CSPRNG salt, producing a 32-byte key.
///
/// [iterations] defaults to [defaultIterations]; tests pass a small count so
/// they run fast. Existing credentials always verify with their own stored
/// iteration count, never this default.
@LazySingleton(as: PinHasher)
class Pbkdf2PinHasher implements PinHasher {
  Pbkdf2PinHasher({
    @ignoreParam int iterations = defaultIterations,
    @ignoreParam Random? random,
  }) : assert(iterations > 0, 'iterations must be positive'),
       _iterations = iterations,
       _random = random ?? Random.secure();

  static const int defaultIterations = 120000;
  static const int saltLength = 16;
  static const int keyLength = 32;
  static const int minPinLength = 4;
  static const int maxPinLength = 6;

  static final RegExp _pinPattern = RegExp(r'^[0-9]{4,6}$');

  final int _iterations;
  final Random _random;

  @override
  void validate(String rawPin) {
    if (!_pinPattern.hasMatch(rawPin)) {
      // Never echo the rejected value (FR-016).
      throw ArgumentError('PIN must be 4-6 numeric digits');
    }
  }

  @override
  PinCredential hash(String rawPin) {
    validate(rawPin);
    final salt = Uint8List(saltLength);
    for (var i = 0; i < saltLength; i++) {
      salt[i] = _random.nextInt(256);
    }
    final derived = derive(rawPin, salt, _iterations);
    return PinCredential(
      hash: base64Encode(derived),
      salt: base64Encode(salt),
      iterations: _iterations,
    );
  }

  @override
  bool verify(String rawPin, PinCredential credential) {
    if (!_pinPattern.hasMatch(rawPin) || credential.iterations <= 0) {
      return false;
    }
    final List<int> expected;
    final List<int> salt;
    try {
      expected = base64Decode(credential.hash);
      salt = base64Decode(credential.salt);
    } on FormatException {
      // A corrupted credential can never match any PIN.
      return false;
    }
    final actual = derive(rawPin, salt, credential.iterations);
    return constantTimeEquals(actual, expected);
  }

  /// PBKDF2 (RFC 8018) with HMAC-SHA256 as the PRF, producing
  /// [keyLength] bytes — exactly one PRF block, so a single `F(P, S, c, 1)`.
  static Uint8List derive(String rawPin, List<int> salt, int iterations) {
    final hmac = Hmac(sha256, utf8.encode(rawPin));
    // U1 = PRF(P, S || INT(1))
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result;
  }

  /// Compares every byte regardless of where the first difference is, so
  /// the running time never reveals how much of the hash matched.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    var diff = a.length ^ b.length;
    final length = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
