import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/goal_progress.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal_detail.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal_type.dart';
import 'package:daftary/features/savings/domain/services/savings_calculator.dart';
import 'package:daftary/features/savings/domain/usecases/create_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/edit_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/get_goal_detail.dart';
import 'package:daftary/features/savings/presentation/cubit/goal_form_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/goal_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../transactions/helpers/currency_test_doubles.dart';
import '../../helpers/savings_harness.dart';

class MockCreateSavingsGoal extends Mock implements CreateSavingsGoal {}

class MockEditSavingsGoal extends Mock implements EditSavingsGoal {}

class MockGetGoalDetail extends Mock implements GetGoalDetail {}

/// T020 — `GoalFormCubit`: create (contribution and target-date modes),
/// edit prefilled from an existing goal, validation, and duplicate-tap
/// protection (FR-022).
void main() {
  final today = DateTime(2026, 9, 15, 10);
  late MockCreateSavingsGoal create;
  late MockEditSavingsGoal edit;
  late MockGetGoalDetail getDetail;

  SavingsGoal goal({
    String id = 'g1',
    Currency currency = Currency.egp,
    int target = 10000000,
    int? monthly,
    DateTime? targetDate,
  }) => SavingsGoal(
    id: id,
    idempotencyKey: 'k',
    name: 'Emergency Fund',
    type: SavingsGoalType.emergencyFund,
    currency: currency,
    targetAmountMinorUnits: target,
    monthlyContributionMinorUnits: monthly,
    targetDate: targetDate,
    createdAt: today,
    updatedAt: today,
  );

  setUpAll(() {
    registerFallbackValue(Currency.egp);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    create = MockCreateSavingsGoal();
    edit = MockEditSavingsGoal();
    getDetail = MockGetGoalDetail();
  });

  GoalFormCubit buildCubit({Currency primary = Currency.egp}) => GoalFormCubit(
    create,
    edit,
    getDetail,
    getPrimaryCurrencyReturning(primary),
    const DefaultSavingsCalculator(),
    SettableClock(today),
  );

  void stubCreate(SavingsGoal result) => when(
    () => create(
      idempotencyKey: any(named: 'idempotencyKey'),
      name: any(named: 'name'),
      type: any(named: 'type'),
      currency: any(named: 'currency'),
      targetAmountMinorUnits: any(named: 'targetAmountMinorUnits'),
      startingAmountMinorUnits: any(named: 'startingAmountMinorUnits'),
      monthlyContributionMinorUnits: any(
        named: 'monthlyContributionMinorUnits',
      ),
      targetDate: any(named: 'targetDate'),
    ),
  ).thenAnswer((_) async => Right(result));

  test('opens with a fresh idempotency key per form', () {
    final a = buildCubit();
    final b = buildCubit();
    expect(a.state.idempotencyKey, isNot(b.state.idempotencyKey));
    a.close();
    b.close();
  });

  test('a new goal defaults to the primary currency (FR-027)', () async {
    final cubit = buildCubit(primary: Currency.usd);
    await cubit.loadDefaultCurrency();
    expect(cubit.state.currency, Currency.usd);
    await cubit.close();
  });

  test('a currency the user already picked is kept', () async {
    final cubit = buildCubit(primary: Currency.usd)
      ..currencyChanged(Currency.eur);
    await cubit.loadDefaultCurrency();
    expect(cubit.state.currency, Currency.eur);
    await cubit.close();
  });

  group('create, contribution mode (US1 AS-1/AS-2)', () {
    test('the live preview shows 20 months, then 13 with a starting '
        'amount', () async {
      final cubit = buildCubit()
        ..nameChanged('Emergency Fund')
        ..targetChanged('100,000')
        ..monthlyChanged('5000');
      final preview = cubit.state.preview!;
      expect(preview.remainingMinorUnits, 10000000);
      expect(preview.estimatedCompletion!.estimatedMonths, 20);

      cubit.startingChanged('35000');
      expect(cubit.state.preview!.remainingMinorUnits, 6500000);
      expect(cubit.state.preview!.estimatedCompletion!.estimatedMonths, 13);
      await cubit.close();
    });

    blocTest<GoalFormCubit, GoalFormState>(
      'submit creates the goal with the parsed minor units (Arabic-Indic '
      'digits accepted) and ends in success',
      setUp: () => stubCreate(goal(monthly: 500000)),
      build: buildCubit,
      act: (cubit) async {
        cubit
          ..nameChanged('  Emergency Fund ')
          ..typeChanged(SavingsGoalType.emergencyFund)
          ..targetChanged('١٠٠٠٠٠')
          ..startingChanged('35000')
          ..monthlyChanged('5000.50');
        await cubit.submit();
      },
      verify: (cubit) {
        final captured = verify(
          () => create(
            idempotencyKey: captureAny(named: 'idempotencyKey'),
            name: 'Emergency Fund',
            type: SavingsGoalType.emergencyFund,
            currency: Currency.egp,
            targetAmountMinorUnits: 10000000,
            startingAmountMinorUnits: 3500000,
            monthlyContributionMinorUnits: 500050,
            targetDate: null,
          ),
        ).captured;
        expect(captured.single, isNotEmpty);
        expect(cubit.state.isSuccess, isTrue);
        expect(cubit.state.savedGoal, goal(monthly: 500000));
        expect(
          cubit.state.idempotencyKey,
          isNot(captured.single),
          reason: 'a later save from the same form is a new goal',
        );
      },
    );
  });

  blocTest<GoalFormCubit, GoalFormState>(
    'create, target-date mode (US1 AS-4): the preview shows the required '
    'monthly contribution and the date reaches the use case',
    setUp: () => stubCreate(goal()),
    build: buildCubit,
    act: (cubit) async {
      cubit
        ..nameChanged('Wedding')
        ..targetChanged('65000')
        ..targetDateChanged(DateTime(2027, 7, 15));
      expect(
        cubit
            .state
            .preview!
            .estimatedCompletion!
            .requiredMonthlyContributionMinorUnits,
        650000,
      );
      await cubit.submit();
    },
    verify: (_) => verify(
      () => create(
        idempotencyKey: any(named: 'idempotencyKey'),
        name: 'Wedding',
        type: null,
        currency: Currency.egp,
        targetAmountMinorUnits: 6500000,
        startingAmountMinorUnits: null,
        monthlyContributionMinorUnits: null,
        targetDate: DateTime(2027, 7, 15),
      ),
    ).called(1),
  );

  blocTest<GoalFormCubit, GoalFormState>(
    'US1 AS-6: with neither plan field the preview has no estimate',
    build: buildCubit,
    act: (cubit) => cubit.targetChanged('1000'),
    verify: (cubit) {
      expect(cubit.state.preview, isNotNull);
      expect(cubit.state.preview!.estimatedCompletion, isNull);
    },
  );

  group('edit mode (FR-029)', () {
    final existing = goal(
      currency: Currency.usd,
      target: 500000,
      monthly: 25000,
      targetDate: DateTime(2027, 1, 1),
    );

    setUp(
      () => when(() => getDetail('g1')).thenAnswer(
        (_) async => Right(
          SavingsGoalDetail(
            goal: existing,
            progress: GoalProgress(
              goalId: 'g1',
              currency: Currency.usd,
              targetAmountMinorUnits: 500000,
              currentAmountMinorUnits: 100000,
            ),
            history: const [],
          ),
        ),
      ),
    );

    blocTest<GoalFormCubit, GoalFormState>(
      'is prefilled from the goal, previews against its real current '
      'amount, and never changes the currency',
      build: buildCubit,
      act: (cubit) async {
        await cubit.loadForEdit('g1');
        cubit.currencyChanged(Currency.eur);
      },
      verify: (cubit) {
        final state = cubit.state;
        expect(state.isEditMode, isTrue);
        expect(state.editingGoalId, 'g1');
        expect(state.name, 'Emergency Fund');
        expect(state.type, SavingsGoalType.emergencyFund);
        expect(state.currency, Currency.usd);
        expect(state.targetInput, '5,000.00');
        expect(state.monthlyInput, '250.00');
        expect(state.targetDate, DateTime(2027, 1, 1));
        expect(state.preview!.remainingMinorUnits, 400000);
        expect(state.preview!.estimatedCompletion!.estimatedMonths, 16);
      },
    );

    blocTest<GoalFormCubit, GoalFormState>(
      'submit edits the goal, clearing a removed monthly contribution',
      setUp: () => when(
        () => edit(
          goalId: any(named: 'goalId'),
          name: any(named: 'name'),
          type: any(named: 'type'),
          targetAmountMinorUnits: any(named: 'targetAmountMinorUnits'),
          monthlyContributionMinorUnits: any(
            named: 'monthlyContributionMinorUnits',
          ),
          targetDate: any(named: 'targetDate'),
        ),
      ).thenAnswer((_) async => Right(existing)),
      build: buildCubit,
      act: (cubit) async {
        await cubit.loadForEdit('g1');
        cubit
          ..targetChanged('6000')
          ..monthlyChanged('');
        await cubit.submit();
      },
      verify: (cubit) {
        verify(
          () => edit(
            goalId: 'g1',
            name: 'Emergency Fund',
            type: SavingsGoalType.emergencyFund,
            targetAmountMinorUnits: 600000,
            monthlyContributionMinorUnits: null,
            targetDate: DateTime(2027, 1, 1),
          ),
        ).called(1);
        verifyNever(
          () => create(
            idempotencyKey: any(named: 'idempotencyKey'),
            name: any(named: 'name'),
            currency: any(named: 'currency'),
            targetAmountMinorUnits: any(named: 'targetAmountMinorUnits'),
          ),
        );
        expect(cubit.state.isSuccess, isTrue);
      },
    );

    blocTest<GoalFormCubit, GoalFormState>(
      'a stored target date that has since passed can be kept',
      setUp: () {
        when(() => getDetail('g1')).thenAnswer(
          (_) async => Right(
            SavingsGoalDetail(
              goal: goal(targetDate: DateTime(2026, 1, 1)),
              progress: const GoalProgress(
                goalId: 'g1',
                currency: Currency.egp,
                targetAmountMinorUnits: 10000000,
                currentAmountMinorUnits: 0,
              ),
              history: const [],
            ),
          ),
        );
        when(
          () => edit(
            goalId: any(named: 'goalId'),
            name: any(named: 'name'),
            type: any(named: 'type'),
            targetAmountMinorUnits: any(named: 'targetAmountMinorUnits'),
            monthlyContributionMinorUnits: any(
              named: 'monthlyContributionMinorUnits',
            ),
            targetDate: any(named: 'targetDate'),
          ),
        ).thenAnswer((_) async => Right(goal()));
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.loadForEdit('g1');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.targetDateInvalid, isFalse);
        expect(cubit.state.isSuccess, isTrue);
      },
    );
  });

  group('validation (FR-001-FR-003) never reaches the use case', () {
    blocTest<GoalFormCubit, GoalFormState>(
      'blank name, zero target, bad starting/monthly amounts, past date',
      build: buildCubit,
      act: (cubit) async {
        cubit
          ..nameChanged('  ')
          ..targetChanged('0')
          ..startingChanged('-5')
          ..monthlyChanged('abc')
          ..targetDateChanged(today);
        await cubit.submit();
      },
      verify: (cubit) {
        final state = cubit.state;
        expect(state.nameInvalid, isTrue);
        expect(state.targetInvalid, isTrue);
        expect(state.startingInvalid, isTrue);
        expect(state.monthlyInvalid, isTrue);
        expect(state.targetDateInvalid, isTrue);
        expect(state.status, GoalFormStatus.editing);
        verifyZeroInteractions(create);
      },
    );

    blocTest<GoalFormCubit, GoalFormState>(
      'a zero monthly contribution is rejected; editing the field clears '
      'its flag',
      build: buildCubit,
      act: (cubit) async {
        cubit
          ..nameChanged('Goal')
          ..targetChanged('100')
          ..monthlyChanged('0');
        await cubit.submit();
        expect(cubit.state.monthlyInvalid, isTrue);
        cubit.monthlyChanged('10');
      },
      verify: (cubit) {
        expect(cubit.state.monthlyInvalid, isFalse);
        verifyZeroInteractions(create);
      },
    );
  });

  blocTest<GoalFormCubit, GoalFormState>(
    'a repository failure is surfaced and the form stays usable',
    setUp: () => when(
      () => create(
        idempotencyKey: any(named: 'idempotencyKey'),
        name: any(named: 'name'),
        type: any(named: 'type'),
        currency: any(named: 'currency'),
        targetAmountMinorUnits: any(named: 'targetAmountMinorUnits'),
        startingAmountMinorUnits: any(named: 'startingAmountMinorUnits'),
        monthlyContributionMinorUnits: any(
          named: 'monthlyContributionMinorUnits',
        ),
        targetDate: any(named: 'targetDate'),
      ),
    ).thenAnswer((_) async => const Left(InvalidTargetDateFailure('past'))),
    build: buildCubit,
    act: (cubit) async {
      cubit
        ..nameChanged('Goal')
        ..targetChanged('100');
      await cubit.submit();
    },
    verify: (cubit) {
      expect(cubit.state.status, GoalFormStatus.failure);
      expect(cubit.state.failure, isA<InvalidTargetDateFailure>());
    },
  );

  test('FR-022: a rapid double-tap saves exactly one goal', () async {
    final pending = Completer<Either<Failure, SavingsGoal>>();
    when(
      () => create(
        idempotencyKey: any(named: 'idempotencyKey'),
        name: any(named: 'name'),
        type: any(named: 'type'),
        currency: any(named: 'currency'),
        targetAmountMinorUnits: any(named: 'targetAmountMinorUnits'),
        startingAmountMinorUnits: any(named: 'startingAmountMinorUnits'),
        monthlyContributionMinorUnits: any(
          named: 'monthlyContributionMinorUnits',
        ),
        targetDate: any(named: 'targetDate'),
      ),
    ).thenAnswer((_) => pending.future);
    final cubit = buildCubit()
      ..nameChanged('Goal')
      ..targetChanged('100');

    final first = cubit.submit();
    final second = cubit.submit();
    expect(cubit.state.isSubmitting, isTrue);
    pending.complete(Right(goal()));
    await Future.wait([first, second]);

    verify(
      () => create(
        idempotencyKey: any(named: 'idempotencyKey'),
        name: any(named: 'name'),
        type: any(named: 'type'),
        currency: any(named: 'currency'),
        targetAmountMinorUnits: any(named: 'targetAmountMinorUnits'),
        startingAmountMinorUnits: any(named: 'startingAmountMinorUnits'),
        monthlyContributionMinorUnits: any(
          named: 'monthlyContributionMinorUnits',
        ),
        targetDate: any(named: 'targetDate'),
      ),
    ).called(1);
    expect(cubit.state.isSuccess, isTrue);
    await cubit.close();
  });

  test('FR-022 end to end: a double-tap against the real repository leaves '
      'exactly one goal row', () async {
    final h = await SavingsHarness.open(today: today);
    final cubit =
        GoalFormCubit(
            CreateSavingsGoal(h.repository, h.getPrimaryCurrency),
            EditSavingsGoal(h.repository),
            GetGoalDetail(h.repository),
            h.getPrimaryCurrency,
            const DefaultSavingsCalculator(),
            h.clock,
          )
          ..nameChanged('Goal')
          ..targetChanged('100')
          ..startingChanged('10');

    await Future.wait([cubit.submit(), cubit.submit(), cubit.submit()]);

    expect(await h.goalRows(), hasLength(1));
    expect(await h.contributionRows(), hasLength(1));
    await cubit.close();
    await h.close();
  });
}
