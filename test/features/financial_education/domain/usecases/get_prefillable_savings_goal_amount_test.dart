import 'dart:io';

import 'package:daftary/features/financial_education/domain/usecases/get_prefillable_savings_goal_amount.dart';
import 'package:flutter_test/flutter_test.dart';

/// T030 — FR-014's optional pre-fill, in a build WITHOUT Savings Goals
/// (spec 011).
///
/// 011 has not shipped in this codebase, so there is no `SavingsRepository`
/// to mock: the use case takes the spec's "unavailable in this build"
/// graceful-degradation path. The "most-recent active goal" and "no write
/// calls" cases from T030 become testable once 011 lands and is injected
/// here; until then the read-only guarantee is structural (the use case
/// has no dependency at all, asserted below).
void main() {
  const useCase = GetPrefillableSavingsGoalAmount();

  test('returns null — nothing to pre-fill when 011 is unavailable', () async {
    expect(await useCase(), isNull);
  });

  test('is stable across repeated calls and never throws', () async {
    for (var i = 0; i < 3; i++) {
      await expectLater(useCase(), completion(isNull));
    }
  });

  test('has no dependency on any repository, DAO or database', () {
    final source = File(
      'lib/features/financial_education/domain/usecases/'
      'get_prefillable_savings_goal_amount.dart',
    ).readAsStringSync();
    final imports = RegExp(
      r'^import .*;$',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(0)!);
    for (final line in imports) {
      expect(line, isNot(contains('repositor')));
      expect(line, isNot(contains('/data/')));
      expect(line, isNot(contains('database')));
      expect(line, isNot(contains('drift')));
    }
  });
}
