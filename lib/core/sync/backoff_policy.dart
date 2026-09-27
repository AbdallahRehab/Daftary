import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// 021: exponential backoff with jitter for transient sync failures
/// (research.md Decisions 13 and 19): `min(5 s · 2^n, 15 min) ± 20 %`.
@lazySingleton
class BackoffPolicy {
  BackoffPolicy() : _random = Random();

  @visibleForTesting
  BackoffPolicy.withRandom(this._random);

  static const base = Duration(seconds: 5);
  static const cap = Duration(minutes: 15);
  static const jitter = 0.2;

  final Random _random;

  /// The capped delay before jitter, for the [failures]-th consecutive
  /// failure (0-based).
  Duration nominalDelayFor(int failures) {
    final n = failures < 0 ? 0 : failures;
    // 2^8 · 5 s already exceeds the cap; stop before the shift overflows.
    if (n >= 8) return cap;
    final ms = base.inMilliseconds << n;
    return ms >= cap.inMilliseconds ? cap : Duration(milliseconds: ms);
  }

  /// [nominalDelayFor] with ±20 % uniform jitter, so devices that failed
  /// together do not retry together.
  Duration delayFor(int failures) {
    final nominal = nominalDelayFor(failures).inMilliseconds;
    final factor = 1 + jitter * (2 * _random.nextDouble() - 1);
    return Duration(milliseconds: (nominal * factor).round());
  }
}
