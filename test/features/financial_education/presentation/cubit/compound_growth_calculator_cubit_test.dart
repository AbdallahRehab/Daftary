import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/features/financial_education/domain/entities/calculator_results.dart';
import 'package:daftary/features/financial_education/domain/services/compound_growth_calculator.dart';
import 'package:daftary/features/financial_education/domain/usecases/calculate_compound_growth.dart';
import 'package:daftary/features/financial_education/domain/usecases/get_prefillable_savings_goal_amount.dart';
import 'package:daftary/features/financial_education/presentation/cubit/calculator_field_error.dart';
import 'package:daftary/features/financial_education/presentation/cubit/compound_growth_calculator_cubit.dart';
import 'package:daftary/features/financial_education/presentation/cubit/compound_growth_calculator_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetPrefillableSavingsGoalAmount extends Mock
    implements GetPrefillableSavingsGoalAmount {}

/// T031 — the real (pure) calculator behind the real use case; only the
/// optional savings-goal pre-fill is mocked.
void main() {
  late MockGetPrefillableSavingsGoalAmount getPrefill;

  setUp(() {
    getPrefill = MockGetPrefillableSavingsGoalAmount();
    when(() => getPrefill()).thenAnswer((_) async => null);
  });

  CompoundGrowthCalculatorCubit buildCubit() => CompoundGrowthCalculatorCubit(
    const CalculateCompoundGrowth(CompoundGrowthCalculatorImpl()),
    getPrefill,
    EgpFormatter(),
  );

  void fill(
    CompoundGrowthCalculatorCubit cubit, {
    required String monthly,
    required String rate,
    required String years,
  }) {
    cubit
      ..monthlyContributionChanged(monthly)
      ..annualRateChanged(rate)
      ..yearsChanged(years);
  }

  const reference = CompoundGrowthResult(
    futureValueMinorUnits: 20484498,
    totalContributedMinorUnits: 12000000,
    totalGrowthMinorUnits: 8484498,
    isHighRateWarningShown: false,
  );

  test('starts empty with no result, no errors and no pre-fill', () {
    final cubit = buildCubit();
    expect(cubit.state, const CompoundGrowthCalculatorState());
    expect(cubit.state.isPrefillAvailable, isFalse);
    addTearDown(cubit.close);
  });

  group('valid input', () {
    blocTest<CompoundGrowthCalculatorCubit, CompoundGrowthCalculatorState>(
      '1,000 EGP / 10% / 10 years produces the reference result',
      build: buildCubit,
      act: (cubit) {
        fill(cubit, monthly: '1000', rate: '10', years: '10');
        cubit.calculate();
      },
      skip: 3,
      expect: () => [
        const CompoundGrowthCalculatorState(
          monthlyContributionInput: '1000',
          annualRateInput: '10',
          yearsInput: '10',
          result: reference,
        ),
      ],
    );

    blocTest<CompoundGrowthCalculatorCubit, CompoundGrowthCalculatorState>(
      'accepts Arabic-Indic digits, grouping and a 0% rate',
      build: buildCubit,
      act: (cubit) {
        fill(cubit, monthly: '١,٠٠٠', rate: '٠', years: '١٠');
        cubit.calculate();
      },
      verify: (cubit) {
        expect(cubit.state.result?.futureValueMinorUnits, 12000000);
        expect(cubit.state.result?.totalGrowthMinorUnits, 0);
        expect(cubit.state.hasErrors, isFalse);
      },
    );

    test('determinism: same inputs submitted twice → identical result', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      fill(cubit, monthly: '1000', rate: '10', years: '10');
      cubit.calculate();
      final first = cubit.state.result;
      cubit
        ..yearsChanged('10')
        ..calculate();
      final second = cubit.state.result;
      expect(first, isNotNull);
      expect(second, first);
    });

    blocTest<CompoundGrowthCalculatorCubit, CompoundGrowthCalculatorState>(
      'editing any input clears a stale result',
      build: buildCubit,
      act: (cubit) {
        fill(cubit, monthly: '1000', rate: '10', years: '10');
        cubit
          ..calculate()
          ..annualRateChanged('11');
      },
      verify: (cubit) => expect(cubit.state.result, isNull),
    );
  });

  group('high-rate note (FR-010)', () {
    blocTest<CompoundGrowthCalculatorCubit, CompoundGrowthCalculatorState>(
      'appears above the threshold, with the result still computed',
      build: buildCubit,
      act: (cubit) {
        fill(cubit, monthly: '1000', rate: '31', years: '1');
        cubit.calculate();
      },
      verify: (cubit) {
        expect(cubit.state.result?.isHighRateWarningShown, isTrue);
        expect(cubit.state.result?.futureValueMinorUnits, 1386072);
      },
    );

    blocTest<CompoundGrowthCalculatorCubit, CompoundGrowthCalculatorState>(
      'does not appear at 29%',
      build: buildCubit,
      act: (cubit) {
        fill(cubit, monthly: '1000', rate: '29', years: '1');
        cubit.calculate();
      },
      verify: (cubit) =>
          expect(cubit.state.result?.isHighRateWarningShown, isFalse),
    );
  });

  group('validation rejections surface as inline field errors', () {
    Future<CompoundGrowthCalculatorState> run(
      String monthly,
      String rate,
      String years,
    ) async {
      final cubit = buildCubit();
      fill(cubit, monthly: monthly, rate: rate, years: years);
      // Must not throw.
      cubit.calculate();
      final state = cubit.state;
      await cubit.close();
      expect(state.result, isNull);
      return state;
    }

    test('zero monthly amount', () async {
      final state = await run('0', '10', '10');
      expect(
        state.monthlyContributionError,
        CalculatorFieldError.mustBePositive,
      );
      expect(state.annualRateError, isNull);
      expect(state.yearsError, isNull);
    });

    test('negative monthly amount', () async {
      final state = await run('-50', '10', '10');
      expect(
        state.monthlyContributionError,
        CalculatorFieldError.mustBePositive,
      );
    });

    test('negative rate', () async {
      final state = await run('1000', '-1', '10');
      expect(state.annualRateError, CalculatorFieldError.mustNotBeNegative);
      expect(state.monthlyContributionError, isNull);
    });

    test('zero years', () async {
      final state = await run('1000', '10', '0');
      expect(state.yearsError, CalculatorFieldError.mustBePositive);
    });

    test('negative years', () async {
      final state = await run('1000', '10', '-2');
      expect(state.yearsError, CalculatorFieldError.mustBePositive);
    });

    test('empty and unparseable fields are all reported at once', () async {
      final state = await run('', 'abc', '2.5');
      expect(state.monthlyContributionError, CalculatorFieldError.required);
      expect(state.annualRateError, CalculatorFieldError.invalidNumber);
      expect(state.yearsError, CalculatorFieldError.wholeNumberRequired);
    });

    test('an amount with more than two decimals is invalid', () async {
      final state = await run('10.555', '10', '1');
      expect(
        state.monthlyContributionError,
        CalculatorFieldError.invalidNumber,
      );
    });

    test('an out-of-range figure is a form-level message', () async {
      final state = await run('1000', '1000', '100');
      expect(state.isResultTooLarge, isTrue);
    });

    blocTest<CompoundGrowthCalculatorCubit, CompoundGrowthCalculatorState>(
      'editing a field clears only that field’s error, keeping input',
      build: buildCubit,
      act: (cubit) {
        fill(cubit, monthly: '0', rate: '', years: '10');
        cubit
          ..calculate()
          ..monthlyContributionChanged('5');
      },
      verify: (cubit) {
        expect(cubit.state.monthlyContributionError, isNull);
        expect(cubit.state.annualRateError, CalculatorFieldError.required);
        expect(cubit.state.monthlyContributionInput, '5');
        expect(cubit.state.yearsInput, '10');
      },
    );
  });

  group('savings-goal pre-fill (FR-014)', () {
    blocTest<CompoundGrowthCalculatorCubit, CompoundGrowthCalculatorState>(
      'stays hidden when the use case returns null (011 unavailable)',
      build: buildCubit,
      act: (cubit) => cubit.loadPrefillAvailability(),
      expect: () => <CompoundGrowthCalculatorState>[],
      verify: (cubit) => expect(cubit.state.isPrefillAvailable, isFalse),
    );

    blocTest<CompoundGrowthCalculatorCubit, CompoundGrowthCalculatorState>(
      'stays hidden when the use case throws',
      setUp: () => when(() => getPrefill()).thenThrow(StateError('boom')),
      build: buildCubit,
      act: (cubit) => cubit.loadPrefillAvailability(),
      expect: () => <CompoundGrowthCalculatorState>[],
    );

    blocTest<CompoundGrowthCalculatorCubit, CompoundGrowthCalculatorState>(
      'offers the amount without calculating or filling anything',
      setUp: () => when(() => getPrefill()).thenAnswer((_) async => 150050),
      build: buildCubit,
      act: (cubit) => cubit.loadPrefillAvailability(),
      expect: () => [
        const CompoundGrowthCalculatorState(prefillAmountMinorUnits: 150050),
      ],
    );

    blocTest<CompoundGrowthCalculatorCubit, CompoundGrowthCalculatorState>(
      'pre-fill copies into an editable field, which the user overwrites',
      setUp: () => when(() => getPrefill()).thenAnswer((_) async => 150050),
      build: buildCubit,
      act: (cubit) async {
        await cubit.loadPrefillAvailability();
        cubit.applyPrefill();
        expect(cubit.state.monthlyContributionInput, '1500.50');
        expect(cubit.state.result, isNull);

        cubit
          ..monthlyContributionChanged('1000')
          ..annualRateChanged('10')
          ..yearsChanged('10')
          ..calculate();
      },
      verify: (cubit) {
        // The calculation used the overwritten value, not the pre-fill.
        expect(cubit.state.result, reference);
        expect(cubit.state.monthlyContributionInput, '1000');
        verify(() => getPrefill()).called(1);
      },
    );

    blocTest<CompoundGrowthCalculatorCubit, CompoundGrowthCalculatorState>(
      'a pre-filled whole amount is used as-is when not overwritten',
      setUp: () => when(() => getPrefill()).thenAnswer((_) async => 100000),
      build: buildCubit,
      act: (cubit) async {
        await cubit.loadPrefillAvailability();
        cubit
          ..applyPrefill()
          ..annualRateChanged('10')
          ..yearsChanged('10')
          ..calculate();
      },
      verify: (cubit) {
        expect(cubit.state.monthlyContributionInput, '1000');
        expect(cubit.state.result, reference);
      },
    );

    blocTest<CompoundGrowthCalculatorCubit, CompoundGrowthCalculatorState>(
      'applyPrefill is a no-op when nothing is available',
      build: buildCubit,
      act: (cubit) => cubit.applyPrefill(),
      expect: () => <CompoundGrowthCalculatorState>[],
    );
  });
}
