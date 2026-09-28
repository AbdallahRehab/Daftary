import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:flutter_test/flutter_test.dart';

/// T011 — primary automated evidence for SC-006 (FR-013 schedule).
void main() {
  const policy = EscalatingLockoutPolicy();
  const s30 = Duration(seconds: 30);
  const m2 = Duration(minutes: 2);
  const m5 = Duration(minutes: 5);

  final expected = <int, Duration?>{
    0: null,
    1: null,
    2: null,
    3: null,
    4: null,
    5: s30,
    6: s30,
    7: s30,
    8: m2,
    9: m2,
    10: m2,
    11: m5,
    12: m5,
    13: m5,
    14: m5,
    17: m5,
    20: m5,
    100: m5,
  };

  expected.forEach((attempts, cooldown) {
    test('$attempts failed attempts -> $cooldown', () {
      expect(policy.cooldownFor(attempts), cooldown);
    });
  });

  test('negative counts never produce a cooldown', () {
    expect(policy.cooldownFor(-1), isNull);
  });

  test('once engaged, every further guess costs at least 30s (SC-006)', () {
    for (var n = 5; n <= 50; n++) {
      expect(policy.cooldownFor(n)! >= s30, isTrue, reason: 'attempt $n');
    }
  });

  test('never de-escalates as failures accumulate', () {
    Duration previous = Duration.zero;
    for (var n = 0; n <= 50; n++) {
      final current = policy.cooldownFor(n) ?? Duration.zero;
      expect(current >= previous, isTrue, reason: 'attempt $n');
      previous = current;
    }
  });
}
