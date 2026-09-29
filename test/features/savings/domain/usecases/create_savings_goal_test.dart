import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal_type.dart';
import 'package:daftary/features/savings/domain/usecases/create_savings_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/savings_harness.dart';

/// T017 — `CreateSavingsGoal`, through the real repository on an in-memory
/// database: every rule under test (validation, the starting-amount entry,
/// idempotency) is enforced there, not in the use case.
void main() {
  late SavingsHarness h;
  late CreateSavingsGoal create;

  setUp(() async {
    h = await SavingsHarness.open();
    create = CreateSavingsGoal(h.repository, h.getPrimaryCurrency);
  });

  tearDown(() => h.close());

  test('US1 AS-1: creates the goal with remaining = target and a 20-month '
      'estimate at 5,000/month on 100,000', () async {
    final result = await create(
      idempotencyKey: 'k1',
      name: '  Emergency Fund ',
      type: SavingsGoalType.emergencyFund,
      targetAmountMinorUnits: 10000000,
      monthlyContributionMinorUnits: 500000,
    );

    final goal = result.toNullable()!;
    expect(goal.name, 'Emergency Fund', reason: 'trimmed');
    expect(goal.type, SavingsGoalType.emergencyFund);
    expect(goal.isArchived, isFalse);

    final detail = await h.detail(goal.id);
    expect(detail.progress.currentAmountMinorUnits, 0);
    expect(detail.progress.remainingMinorUnits, 10000000);
    expect(detail.progress.estimatedCompletion!.estimatedMonths, 20);
    expect(detail.history, isEmpty);
  });

  test('US1 AS-2: a starting amount becomes the first entry, dated today, '
      'in the same save — remaining 65,000 and 13 months', () async {
    final goal = (await create(
      idempotencyKey: 'k1',
      name: 'Emergency Fund',
      targetAmountMinorUnits: 10000000,
      startingAmountMinorUnits: 3500000,
      monthlyContributionMinorUnits: 500000,
    )).toNullable()!;

    final detail = await h.detail(goal.id);
    expect(detail.progress.currentAmountMinorUnits, 3500000);
    expect(detail.progress.remainingMinorUnits, 6500000);
    expect(detail.progress.estimatedCompletion!.estimatedMonths, 13);

    final entry = detail.history.single;
    expect(entry.type, ContributionType.contribution);
    expect(entry.amountMinorUnits, 3500000);
    expect(entry.enteredAmountMinorUnits, 3500000);
    expect(entry.enteredCurrency, Currency.egp);
    expect(entry.date, h.today);
    expect(entry.isStartingAmount, isTrue);
  });

  test('a zero starting amount is valid and creates no entry', () async {
    final goal = (await create(
      idempotencyKey: 'k1',
      name: 'Car',
      targetAmountMinorUnits: 100,
      startingAmountMinorUnits: 0,
    )).toNullable()!;

    expect((await h.detail(goal.id)).history, isEmpty);
    expect(await h.contributionRows(), isEmpty);
  });

  group('validation (FR-001/FR-002/FR-003) — nothing is written', () {
    Future<void> expectRejected(
      Future<Either<Failure, Object>> Function() call,
      Matcher failure,
    ) async {
      final result = await call();
      expect(result.getLeft().toNullable(), failure);
      expect(await h.goalRows(), isEmpty);
      expect(await h.contributionRows(), isEmpty);
    }

    test('a zero or negative target (US1 AS-3)', () async {
      for (final target in [0, -100]) {
        await expectRejected(
          () => create(
            idempotencyKey: 'k$target',
            name: 'Goal',
            targetAmountMinorUnits: target,
          ),
          isA<ValidationFailure>(),
        );
      }
    });

    test('a blank name', () async {
      await expectRejected(
        () => create(
          idempotencyKey: 'k',
          name: '   ',
          targetAmountMinorUnits: 100,
        ),
        isA<ValidationFailure>(),
      );
    });

    test('a negative or zero monthly contribution', () async {
      for (final monthly in [0, -1]) {
        await expectRejected(
          () => create(
            idempotencyKey: 'k$monthly',
            name: 'Goal',
            targetAmountMinorUnits: 100,
            monthlyContributionMinorUnits: monthly,
          ),
          isA<ValidationFailure>(),
        );
      }
    });

    test('a negative starting amount', () async {
      await expectRejected(
        () => create(
          idempotencyKey: 'k',
          name: 'Goal',
          targetAmountMinorUnits: 100,
          startingAmountMinorUnits: -1,
        ),
        isA<ValidationFailure>(),
      );
    });

    test('a target date today or in the past (InvalidTargetDateFailure)', () {
      return Future.forEach(
        [
          h.today,
          h.today.subtract(const Duration(days: 1)),
          // Later today is still today: compared as calendar dates.
          DateTime(h.today.year, h.today.month, h.today.day, 23, 59),
        ],
        (date) async {
          await expectRejected(
            () => create(
              idempotencyKey: 'k${date.millisecondsSinceEpoch}',
              name: 'Goal',
              targetAmountMinorUnits: 100,
              targetDate: date,
            ),
            isA<InvalidTargetDateFailure>(),
          );
        },
      );
    });
  });

  test('tomorrow is a valid target date, stored date-only', () async {
    final tomorrow = h.today.add(const Duration(days: 1, hours: 13));
    final goal = (await create(
      idempotencyKey: 'k',
      name: 'Goal',
      targetAmountMinorUnits: 100,
      targetDate: tomorrow,
    )).toNullable()!;

    expect(
      goal.targetDate,
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
    );
  });

  test('the currency defaults to the primary currency (FR-027)', () async {
    await h.setPrimary(Currency.usd);

    final goal = (await create(
      idempotencyKey: 'k',
      name: 'Goal',
      targetAmountMinorUnits: 100,
    )).toNullable()!;

    expect(goal.currency, Currency.usd);
  });

  test('an explicit currency wins over the primary currency', () async {
    final goal = (await create(
      idempotencyKey: 'k',
      name: 'Goal',
      currency: Currency.eur,
      targetAmountMinorUnits: 100,
      startingAmountMinorUnits: 50,
    )).toNullable()!;

    expect(goal.currency, Currency.eur);
    final entry = (await h.detail(goal.id)).history.single;
    expect(entry.enteredCurrency, Currency.eur);
  });

  test('US1 AS-6: neither a monthly contribution nor a target date is '
      'valid — the goal has no estimate yet', () async {
    final goal = (await create(
      idempotencyKey: 'k',
      name: 'Someday',
      targetAmountMinorUnits: 100000,
    )).toNullable()!;

    final progress = (await h.detail(goal.id)).progress;
    expect(progress.estimatedCompletion, isNull);
    expect(progress.isAchieved, isFalse);
  });

  test('US1 AS-4: a target date alone yields the required monthly '
      'contribution', () async {
    final goal = (await create(
      idempotencyKey: 'k',
      name: 'Wedding',
      targetAmountMinorUnits: 6500000,
      // 10 whole months from 2026-09-15.
      targetDate: DateTime(2027, 7, 15),
    )).toNullable()!;

    final estimate = (await h.detail(goal.id)).progress.estimatedCompletion!;
    expect(estimate.requiredMonthlyContributionMinorUnits, 650000);
    expect(estimate.estimatedMonths, isNull);
  });

  test(
    'a blank type is stored as no type (a plain custom-named goal)',
    () async {
      final goal = (await create(
        idempotencyKey: 'k',
        name: 'Goal',
        type: '  ',
        targetAmountMinorUnits: 100,
      )).toNullable()!;

      expect(goal.type, isNull);
    },
  );

  test('idempotent on retry (FR-022): the same key returns the first goal '
      'and writes neither a second goal nor a second starting entry', () async {
    final first = await create(
      idempotencyKey: 'same',
      name: 'Goal',
      targetAmountMinorUnits: 1000,
      startingAmountMinorUnits: 100,
    );
    final retried = await create(
      idempotencyKey: 'same',
      name: 'Different',
      targetAmountMinorUnits: 9999,
      startingAmountMinorUnits: 500,
    );

    expect(retried.toNullable(), first.toNullable());
    expect(await h.goalRows(), hasLength(1));
    expect(await h.contributionRows(), hasLength(1));
  });
}
