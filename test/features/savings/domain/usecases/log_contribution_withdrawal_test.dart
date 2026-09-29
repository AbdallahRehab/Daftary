import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/usecases/archive_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/log_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/log_withdrawal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/savings_harness.dart';

/// T031 — `LogContribution`/`LogWithdrawal` through the real repository.
void main() {
  late SavingsHarness h;
  late LogContribution logContribution;
  late LogWithdrawal logWithdrawal;

  setUp(() async {
    h = await SavingsHarness.open();
    logContribution = LogContribution(h.repository);
    logWithdrawal = LogWithdrawal(h.repository);
  });

  tearDown(() => h.close());

  test('US2 AS-1: a 5,000 contribution on 35,000 makes 40,000, and the '
      'estimate recalculates', () async {
    final goal = await h.createGoal(
      target: 10000000,
      starting: 3500000,
      monthly: 500000,
    );

    final result = await logContribution(
      idempotencyKey: 'k',
      goalId: goal.id,
      amount: Money.egp(500000),
      date: h.today,
      note: '  Bonus ',
    );

    final entry = result.toNullable()!;
    expect(entry.type, ContributionType.contribution);
    expect(entry.note, 'Bonus');
    expect(entry.date, h.today);
    final progress = (await h.detail(goal.id)).progress;
    expect(progress.currentAmountMinorUnits, 4000000);
    expect(progress.remainingMinorUnits, 6000000);
    expect(progress.estimatedCompletion!.estimatedMonths, 12);
  });

  test('US2 AS-3: a withdrawal lowers the current amount', () async {
    final goal = await h.createGoal(target: 100000, starting: 10000);

    final result = await logWithdrawal(
      idempotencyKey: 'k',
      goalId: goal.id,
      amount: Money.egp(3000),
      date: h.today,
    );

    expect(result.toNullable()!.type, ContributionType.withdrawal);
    expect((await h.detail(goal.id)).progress.currentAmountMinorUnits, 7000);
  });

  test('a withdrawal of exactly the balance is allowed', () async {
    final goal = await h.createGoal(target: 100000, starting: 10000);

    final result = await logWithdrawal(
      idempotencyKey: 'k',
      goalId: goal.id,
      amount: Money.egp(10000),
      date: h.today,
    );

    expect(result.isRight(), isTrue);
    expect((await h.detail(goal.id)).progress.currentAmountMinorUnits, 0);
  });

  test('US2 AS-4 / FR-006: a withdrawal above the balance is rejected with '
      'the available amount', () async {
    final goal = await h.createGoal(target: 10000000, starting: 1000000);

    final result = await logWithdrawal(
      idempotencyKey: 'k',
      goalId: goal.id,
      amount: Money.egp(1500000),
      date: h.today,
    );

    final failure = result.getLeft().toNullable();
    expect(failure, isA<WithdrawalExceedsBalanceFailure>());
    expect(
      (failure! as WithdrawalExceedsBalanceFailure).availableMinorUnits,
      1000000,
    );
    expect((await h.detail(goal.id)).history, hasLength(1));
  });

  test(
    'FR-007: a zero or negative amount is rejected for either type',
    () async {
      final goal = await h.createGoal(target: 100000, starting: 1000);
      for (final amount in [0, -5]) {
        final c = await logContribution(
          idempotencyKey: 'c$amount',
          goalId: goal.id,
          amount: Money.egp(amount),
          date: h.today,
        );
        final w = await logWithdrawal(
          idempotencyKey: 'w$amount',
          goalId: goal.id,
          amount: Money.egp(amount),
          date: h.today,
        );
        expect(c.getLeft().toNullable(), isA<ValidationFailure>());
        expect(w.getLeft().toNullable(), isA<ValidationFailure>());
      }
      expect(await h.contributionRows(), hasLength(1));
    },
  );

  test('FR-020: a new entry on an archived goal is rejected', () async {
    final goal = await h.createGoal(target: 100000, starting: 1000);
    await ArchiveSavingsGoal(h.repository)(goal.id);

    final c = await logContribution(
      idempotencyKey: 'c',
      goalId: goal.id,
      amount: Money.egp(10),
      date: h.today,
    );
    final w = await logWithdrawal(
      idempotencyKey: 'w',
      goalId: goal.id,
      amount: Money.egp(10),
      date: h.today,
    );

    expect(c.getLeft().toNullable(), isA<GoalArchivedFailure>());
    expect(w.getLeft().toNullable(), isA<GoalArchivedFailure>());
    expect(await h.contributionRows(), hasLength(1));
  });

  test('an unknown goal is GoalNotFoundFailure', () async {
    final result = await logContribution(
      idempotencyKey: 'k',
      goalId: 'missing',
      amount: Money.egp(10),
      date: h.today,
    );

    expect(result.getLeft().toNullable(), isA<GoalNotFoundFailure>());
  });

  test(
    'US2 AS-8 / FR-028: a foreign amount is converted at the current '
    'rate; both figures are stored and only the converted one counts',
    () async {
      await h.setRate(Currency.usd, 50);
      final goal = await h.createGoal(target: 10000000);

      final entry = (await logContribution(
        idempotencyKey: 'k',
        goalId: goal.id,
        amount: Money.fromMinorUnits(10000, Currency.usd),
        date: h.today,
      )).toNullable()!;

      expect(entry.enteredAmountMinorUnits, 10000);
      expect(entry.enteredCurrency, Currency.usd);
      expect(entry.amountMinorUnits, 500000);
      expect(
        (await h.detail(goal.id)).progress.currentAmountMinorUnits,
        500000,
      );
    },
  );

  test('the withdrawal-balance check uses the converted amount', () async {
    await h.setRate(Currency.usd, 50);
    final goal = await h.createGoal(target: 10000000, starting: 499999);

    final result = await logWithdrawal(
      idempotencyKey: 'k',
      goalId: goal.id,
      // 100.00 USD = 5,000.00 EGP > 4,999.99 EGP.
      amount: Money.fromMinorUnits(10000, Currency.usd),
      date: h.today,
    );

    expect(
      result.getLeft().toNullable(),
      isA<WithdrawalExceedsBalanceFailure>(),
    );
  });

  test('US2 AS-9: a missing rate returns RatesMissingFailure naming it and '
      'writes nothing', () async {
    final goal = await h.createGoal(target: 10000000);

    final result = await logContribution(
      idempotencyKey: 'k',
      goalId: goal.id,
      amount: Money.fromMinorUnits(10000, Currency.usd),
      date: h.today,
    );

    final failure = result.getLeft().toNullable();
    expect(failure, isA<RatesMissingFailure>());
    expect((failure! as RatesMissingFailure).missingRatesFor, [Currency.usd]);
    expect(await h.contributionRows(), isEmpty);
  });

  test('FR-022: idempotent on retry — the same key returns the first entry '
      'and writes one row', () async {
    final goal = await h.createGoal(target: 100000);

    final first = await logContribution(
      idempotencyKey: 'same',
      goalId: goal.id,
      amount: Money.egp(100),
      date: h.today,
    );
    final retried = await logContribution(
      idempotencyKey: 'same',
      goalId: goal.id,
      amount: Money.egp(999),
      date: h.today,
    );

    expect(retried.toNullable(), first.toNullable());
    expect(await h.contributionRows(), hasLength(1));
  });

  test('FR-018: contributions keep being accepted past the target', () async {
    final goal = await h.createGoal(target: 1000, starting: 1000);
    expect((await h.detail(goal.id)).progress.isAchieved, isTrue);

    final result = await logContribution(
      idempotencyKey: 'k',
      goalId: goal.id,
      amount: Money.egp(500),
      date: h.today,
    );

    expect(result.isRight(), isTrue);
    final progress = (await h.detail(goal.id)).progress;
    expect(progress.currentAmountMinorUnits, 1500);
    expect(progress.isAchieved, isTrue);
    expect(progress.remainingMinorUnits, 0);
  });
}
