import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/usecases/edit_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/get_goal_detail.dart';
import 'package:daftary/features/savings/domain/usecases/log_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/log_withdrawal.dart';
import 'package:daftary/features/savings/presentation/cubit/contribution_form_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/contribution_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/savings_harness.dart';
import '../../helpers/savings_test_data.dart';

/// T035 — `ContributionFormCubit`: log and edit, contribution and
/// withdrawal; currency defaulting to the goal's; the missing-rate error
/// state; the archived-goal state; duplicate-tap protection.
void main() {
  late MockSavingsRepository repository;

  final goal = testGoal(target: 1000000);
  final starting = testEntry(
    id: 's',
    amount: 50000,
    note: SavingsContribution.startingAmountNote,
  );
  final usdEntry = testEntry(
    id: 'u',
    amount: 500000,
    entered: 10000,
    enteredCurrency: Currency.usd,
    date: DateTime(2026, 9, 3),
    note: 'from abroad',
  );

  setUpAll(() {
    registerFallbackValue(Money.egp(0));
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repository = MockSavingsRepository();
    when(() => repository.getGoalDetail('g1')).thenAnswer(
      (_) async => Right(testDetail(goal, history: [starting, usdEntry])),
    );
  });

  ContributionFormCubit buildCubit() => ContributionFormCubit(
    GetGoalDetail(repository),
    LogContribution(repository),
    LogWithdrawal(repository),
    EditContribution(repository),
    SettableClock(testToday),
  );

  void stubLog(
    Either<Failure, SavingsContribution> Function() answer, {
    bool withdrawal = false,
  }) {
    final call = withdrawal
        ? () => repository.logWithdrawal(
            idempotencyKey: any(named: 'idempotencyKey'),
            goalId: any(named: 'goalId'),
            amount: any(named: 'amount'),
            date: any(named: 'date'),
            note: any(named: 'note'),
          )
        : () => repository.logContribution(
            idempotencyKey: any(named: 'idempotencyKey'),
            goalId: any(named: 'goalId'),
            amount: any(named: 'amount'),
            date: any(named: 'date'),
            note: any(named: 'note'),
          );
    when(call).thenAnswer((_) async => answer());
  }

  test('a new entry defaults to the goal currency and today', () async {
    final cubit = buildCubit();
    await cubit.initialize(goalId: 'g1');

    final state = cubit.state;
    expect(state.status, ContributionFormStatus.editing);
    expect(state.currency, Currency.egp);
    expect(state.date, DateTime(2026, 9, 15));
    expect(state.type, ContributionType.contribution);
    expect(state.isEditMode, isFalse);
    expect(state.availableMinorUnits, 550000);
    await cubit.close();
  });

  test('logs a contribution with the typed amount and note', () async {
    stubLog(() => Right(testEntry(id: 'new')));
    final cubit = buildCubit();
    await cubit.initialize(goalId: 'g1');
    cubit
      ..amountChanged('1,500.25')
      ..noteChanged('  bonus ');

    await cubit.submit();

    verify(
      () => repository.logContribution(
        idempotencyKey: any(named: 'idempotencyKey'),
        goalId: 'g1',
        amount: Money.egp(150025),
        date: DateTime(2026, 9, 15),
        note: 'bonus',
      ),
    ).called(1);
    expect(cubit.state.isSuccess, isTrue);
    await cubit.close();
  });

  test('the toggle switches a new entry to a withdrawal', () async {
    stubLog(
      () => Right(testEntry(id: 'w', type: ContributionType.withdrawal)),
      withdrawal: true,
    );
    final cubit = buildCubit();
    await cubit.initialize(goalId: 'g1');
    cubit
      ..typeChanged(ContributionType.withdrawal)
      ..amountChanged('100');

    await cubit.submit();

    verify(
      () => repository.logWithdrawal(
        idempotencyKey: any(named: 'idempotencyKey'),
        goalId: 'g1',
        amount: Money.egp(10000),
        date: any(named: 'date'),
        note: null,
      ),
    ).called(1);
    verifyNever(
      () => repository.logContribution(
        idempotencyKey: any(named: 'idempotencyKey'),
        goalId: any(named: 'goalId'),
        amount: any(named: 'amount'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    );
    await cubit.close();
  });

  test('a foreign currency is sent as entered; a missing rate is the error '
      'state and the form stays filled', () async {
    stubLog(() => Left(RatesMissingFailure(const [Currency.usd])));
    final cubit = buildCubit();
    await cubit.initialize(goalId: 'g1');
    cubit
      ..currencyChanged(Currency.usd)
      ..amountChanged('100');
    expect(cubit.state.needsConversion, isTrue);

    await cubit.submit();

    verify(
      () => repository.logContribution(
        idempotencyKey: any(named: 'idempotencyKey'),
        goalId: 'g1',
        amount: Money.fromMinorUnits(10000, Currency.usd),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).called(1);
    expect(cubit.state.status, ContributionFormStatus.failure);
    expect(cubit.state.failure, isA<RatesMissingFailure>());
    expect(cubit.state.amountInput, '100');
    await cubit.close();
  });

  test('an over-withdrawal is surfaced as the error state', () async {
    stubLog(
      () => const Left(
        WithdrawalExceedsBalanceFailure('too much', availableMinorUnits: 5),
      ),
      withdrawal: true,
    );
    final cubit = buildCubit();
    await cubit.initialize(goalId: 'g1', type: ContributionType.withdrawal);
    cubit.amountChanged('999999');

    await cubit.submit();

    expect(cubit.state.failure, isA<WithdrawalExceedsBalanceFailure>());
    await cubit.close();
  });

  test(
    'a zero or unparseable amount is flagged and nothing is saved',
    () async {
      final cubit = buildCubit();
      await cubit.initialize(goalId: 'g1');
      for (final input in ['', '0', 'abc', '-3']) {
        cubit.amountChanged(input);
        await cubit.submit();
        expect(cubit.state.amountInvalid, isTrue, reason: input);
      }
      verifyNever(
        () => repository.logContribution(
          idempotencyKey: any(named: 'idempotencyKey'),
          goalId: any(named: 'goalId'),
          amount: any(named: 'amount'),
          date: any(named: 'date'),
        ),
      );
      await cubit.close();
    },
  );

  group('edit mode (FR-009)', () {
    test('is prefilled from the entry as entered; its type is fixed', () async {
      final cubit = buildCubit();
      await cubit.initialize(goalId: 'g1', contributionId: 'u');
      cubit.typeChanged(ContributionType.withdrawal);

      final state = cubit.state;
      expect(state.isEditMode, isTrue);
      expect(state.editingContributionId, 'u');
      expect(state.type, ContributionType.contribution);
      expect(state.currency, Currency.usd);
      expect(state.amountInput, '100.00');
      expect(state.date, DateTime(2026, 9, 3));
      expect(state.note, 'from abroad');
      await cubit.close();
    });

    test('submit edits through EditContribution', () async {
      when(
        () => repository.editContribution(
          contributionId: any(named: 'contributionId'),
          amount: any(named: 'amount'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => Right(usdEntry));
      final cubit = buildCubit();
      await cubit.initialize(goalId: 'g1', contributionId: 'u');
      cubit.amountChanged('120');

      await cubit.submit();

      verify(
        () => repository.editContribution(
          contributionId: 'u',
          amount: Money.fromMinorUnits(12000, Currency.usd),
          date: DateTime(2026, 9, 3),
          note: 'from abroad',
        ),
      ).called(1);
      expect(cubit.state.isSuccess, isTrue);
      await cubit.close();
    });

    test('the starting-amount entry keeps its marker unless a note is '
        'typed', () async {
      when(
        () => repository.editContribution(
          contributionId: any(named: 'contributionId'),
          amount: any(named: 'amount'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => Right(starting));
      final cubit = buildCubit();
      await cubit.initialize(goalId: 'g1', contributionId: 's');
      expect(cubit.state.note, isEmpty);

      await cubit.submit();

      verify(
        () => repository.editContribution(
          contributionId: 's',
          amount: Money.egp(50000),
          date: any(named: 'date'),
          note: SavingsContribution.startingAmountNote,
        ),
      ).called(1);
      await cubit.close();
    });

    test('an unknown entry is the error state', () async {
      final cubit = buildCubit();
      await cubit.initialize(goalId: 'g1', contributionId: 'missing');

      expect(cubit.state.status, ContributionFormStatus.failure);
      expect(cubit.state.failure, isA<GoalNotFoundFailure>());
      await cubit.close();
    });
  });

  group('archived goal (FR-020)', () {
    setUp(
      () => when(() => repository.getGoalDetail('g1')).thenAnswer(
        (_) async =>
            Right(testDetail(testGoal(isArchived: true), history: [usdEntry])),
      ),
    );

    test('a new entry is blocked', () async {
      final cubit = buildCubit();
      await cubit.initialize(goalId: 'g1');
      expect(cubit.state.blocksNewEntry, isTrue);
      await cubit.close();
    });

    test('editing an existing entry is not', () async {
      final cubit = buildCubit();
      await cubit.initialize(goalId: 'g1', contributionId: 'u');
      expect(cubit.state.blocksNewEntry, isFalse);
      await cubit.close();
    });
  });

  test('FR-022: a rapid double-tap logs once, with the form\'s key', () async {
    final pending = Completer<Either<Failure, SavingsContribution>>();
    when(
      () => repository.logContribution(
        idempotencyKey: any(named: 'idempotencyKey'),
        goalId: any(named: 'goalId'),
        amount: any(named: 'amount'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) => pending.future);
    final cubit = buildCubit();
    await cubit.initialize(goalId: 'g1');
    final key = cubit.state.idempotencyKey;
    cubit.amountChanged('10');

    final a = cubit.submit();
    final b = cubit.submit();
    pending.complete(Right(testEntry(id: 'x')));
    await Future.wait([a, b]);

    verify(
      () => repository.logContribution(
        idempotencyKey: key,
        goalId: 'g1',
        amount: Money.egp(1000),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).called(1);
    expect(cubit.state.idempotencyKey, isNot(key));
    await cubit.close();
  });
}
