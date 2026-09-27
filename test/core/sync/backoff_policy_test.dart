import 'dart:math';

import 'package:daftary/core/sync/backoff_policy.dart';
import 'package:flutter_test/flutter_test.dart';

/// 021 T057: `min(5 s · 2^n, 15 min) ± 20 %`.
void main() {
  test('nominal delay doubles from 5 s and caps at 15 min', () {
    final policy = BackoffPolicy.withRandom(Random(1));
    expect(policy.nominalDelayFor(0), const Duration(seconds: 5));
    expect(policy.nominalDelayFor(1), const Duration(seconds: 10));
    expect(policy.nominalDelayFor(4), const Duration(seconds: 80));
    expect(policy.nominalDelayFor(7), const Duration(seconds: 640));
    expect(policy.nominalDelayFor(8), const Duration(minutes: 15));
    expect(policy.nominalDelayFor(60), const Duration(minutes: 15));
    expect(policy.nominalDelayFor(-3), const Duration(seconds: 5));
  });

  test('jittered delay stays within ±20 % for n = 0..12, over many draws', () {
    final policy = BackoffPolicy.withRandom(Random(42));
    for (var n = 0; n <= 12; n++) {
      final nominal = policy.nominalDelayFor(n).inMilliseconds;
      for (var i = 0; i < 200; i++) {
        final ms = policy.delayFor(n).inMilliseconds;
        expect(ms, greaterThanOrEqualTo((nominal * 0.8).floor()));
        expect(ms, lessThanOrEqualTo((nominal * 1.2).ceil()));
      }
    }
  });

  test('the cap holds: never more than 15 min + 20 %', () {
    final high = BackoffPolicy.withRandom(_Fixed(0.999999));
    expect(high.delayFor(30), lessThanOrEqualTo(const Duration(minutes: 18)));
    final low = BackoffPolicy.withRandom(_Fixed(0));
    expect(low.delayFor(0), const Duration(seconds: 4));
  });
}

class _Fixed implements Random {
  _Fixed(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => false;

  @override
  int nextInt(int max) => 0;
}
