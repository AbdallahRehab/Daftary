import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal_detail.dart';
import 'package:daftary/features/savings/domain/services/savings_calculator.dart';
import 'package:daftary/features/savings/domain/usecases/calculate_what_if_monthly_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/get_goal_detail.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/catalogue_fixtures.dart';

/// 022 Phase 2 (T010) — savings catalogue. Setup for CHK058-CHK064: goal
/// "Car", target 12,000.00 EGP (1200000), as of 2026-10-05. Every figure is
/// an exact integer count of minor units.
void main() {
  late CatalogueEnv env;

  setUp(() async => env = await CatalogueEnv.open());
  tearDown(() => env.close());

  Future<SavingsGoalDetail> detailOf(String goalId) async =>
      unwrapOrThrow(await env.savings.getGoalDetail(goalId));

  group('CHK058 no contributions', () {
    test('current 0, remaining 1200000, progress 0%', () async {
      final goal = await env.goal();

      final progress = (await detailOf(goal.id)).progress;

      expect(progress.currentAmountMinorUnits, 0);
      expect(progress.remainingMinorUnits, 1200000);
      expect(progress.percentageProgress, 0);
    });
  });

  group('CHK059 contributions 2,000.00 + 1,000.00', () {
    test('current 300000, remaining 900000, progress 25%', () async {
      final goal = await env.goal();
      await env.contribute(goal.id, 200000);
      await env.contribute(goal.id, 100000);

      final progress = (await detailOf(goal.id)).progress;

      expect(progress.currentAmountMinorUnits, 300000);
      expect(progress.remainingMinorUnits, 900000);
      expect(progress.percentageProgress, 25.0);
    });
  });

  group('CHK060 planned 1,000.00 a month', () {
    test('9 months left, estimated date 2027-07-05', () async {
      final goal = await env.goal(monthly: 100000);
      await env.contribute(goal.id, 300000);

      final estimate = (await detailOf(goal.id)).progress.estimatedCompletion!;

      expect(estimate.estimatedMonths, 9);
      expect(estimate.estimatedDate, DateTime(2027, 7, 5));
    });
  });

  group('CHK061 target date 2027-04-05 (6 whole months away)', () {
    test('needed per month 150000 and a 3-month shortfall', () async {
      final goal = await env.goal(
        monthly: 100000,
        targetDate: DateTime(2027, 4, 5),
      );
      await env.contribute(goal.id, 300000);

      final estimate = (await detailOf(goal.id)).progress.estimatedCompletion!;

      expect(estimate.requiredMonthlyContributionMinorUnits, 150000);
      expect(estimate.estimatedMonths, 9);
      expect(estimate.shortfallMonths, 3);
      expect(estimate.hasShortfall, isTrue);
    });
  });

  group('CHK062 remaining 1,000.00, target date 2027-01-05', () {
    test('needed per month 33334: always rounded up, never 33333', () {
      final estimate = const DefaultSavingsCalculator()
          .requiredContributionForTargetDate(
            remainingMinorUnits: 100000,
            targetDate: DateTime(2027, 1, 5),
            asOf: catalogueToday,
          )!;

      expect(estimate.requiredMonthlyContributionMinorUnits, 33334);
    });

    test(
      'the same figure through a real goal (target 1,000.00 unfunded)',
      () async {
        final goal = await env.goal(
          target: 100000,
          targetDate: DateTime(2027, 1, 5),
        );

        final estimate = (await detailOf(
          goal.id,
        )).progress.estimatedCompletion!;

        expect(estimate.requiredMonthlyContributionMinorUnits, 33334);
      },
    );
  });

  group('CHK063 target date inside the current month', () {
    test('2026-10-20 with remaining 9,000.00 needs 900000 this month '
        '(divide by 1)', () {
      final estimate = const DefaultSavingsCalculator()
          .requiredContributionForTargetDate(
            remainingMinorUnits: 900000,
            targetDate: DateTime(2026, 10, 20),
            asOf: catalogueToday,
          )!;

      expect(estimate.requiredMonthlyContributionMinorUnits, 900000);
    });
  });

  group('CHK064 withdrawals', () {
    test('current 250000: withdraw 50000 => 200000; withdraw 300000 is '
        'rejected and current stays 200000', () async {
      final goal = await env.goal();
      await env.contribute(goal.id, 250000);

      unwrapOrThrow(
        await env.savings.logWithdrawal(
          idempotencyKey: env.nextKey(),
          goalId: goal.id,
          amount: const Money.egp(50000),
          date: catalogueToday,
        ),
      );
      expect(
        (await detailOf(goal.id)).progress.currentAmountMinorUnits,
        200000,
      );

      final rejected = await env.savings.logWithdrawal(
        idempotencyKey: env.nextKey(),
        goalId: goal.id,
        amount: const Money.egp(300000),
        date: catalogueToday,
      );

      final failure = rejected.getLeft().toNullable();
      expect(failure, isA<WithdrawalExceedsBalanceFailure>());
      expect(
        (failure! as WithdrawalExceedsBalanceFailure).availableMinorUnits,
        200000,
      );
      expect(
        (await detailOf(goal.id)).progress.currentAmountMinorUnits,
        200000,
      );
    });
  });

  group('CHK065 achieved goal', () {
    test('1,250,000 contributed: achieved, progress 100%, remaining 0 (never '
        'negative), no estimate', () async {
      final goal = await env.goal(monthly: 100000);
      await env.contribute(goal.id, 1250000);

      final progress = (await detailOf(goal.id)).progress;

      expect(progress.isAchieved, isTrue);
      expect(progress.currentAmountMinorUnits, 1250000);
      expect(progress.percentageProgress, greaterThanOrEqualTo(100));
      expect(progress.remainingMinorUnits, 0);
      expect(progress.estimatedCompletion, isNull);
    });
  });

  group('CHK066 USD contribution locks its conversion rate', () {
    test('100.00 USD at 48.50 adds 485000; changing the rate to 50.00 does '
        'not change current', () async {
      await env.setRate(Currency.usd, 48.5);
      final goal = await env.goal();

      await env.contribute(goal.id, 10000, currency: Currency.usd);
      expect(
        (await detailOf(goal.id)).progress.currentAmountMinorUnits,
        485000,
      );

      await env.setRate(Currency.usd, 50);

      expect(
        (await detailOf(goal.id)).progress.currentAmountMinorUnits,
        485000,
      );
    });
  });

  group('CHK067 what-if calculator', () {
    test('a hypothetical monthly amount of 0 or less returns a '
        'ValidationFailure and no result', () async {
      final goal = await env.goal();
      final whatIf = CalculateWhatIfMonthlyContribution(
        GetGoalDetail(env.savings),
        const DefaultSavingsCalculator(),
        env.clock,
      );

      for (final amount in [0, -1, -100000]) {
        final result = await whatIf(
          goalId: goal.id,
          hypotheticalMonthlyContributionMinorUnits: amount,
        );
        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
        expect(result.isRight(), isFalse);
      }
    });
  });
}
