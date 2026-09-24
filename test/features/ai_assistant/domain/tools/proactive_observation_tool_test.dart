import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/ai_assistant/domain/tools/ai_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/compare_spending_across_periods.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_proactive_observation_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_arguments.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetFinanceSummary extends Mock implements GetFinanceSummary {}

final _now = DateTime(2026, 9, 24, 15, 30);
final _august = DateRange(
  start: DateTime(2026, 8, 1),
  end: DateTime(2026, 8, 31),
);
final _july = DateRange(
  start: DateTime(2026, 7, 1),
  end: DateTime(2026, 7, 31),
);

void main() {
  setUpAll(() => registerFallbackValue(_august));

  late MockGetFinanceSummary getFinanceSummary;
  late GetProactiveObservationTool tool;

  setUp(() {
    getFinanceSummary = MockGetFinanceSummary();
    final periods = AIPeriodResolver.withClock(() => _now);
    tool = GetProactiveObservationTool(
      CompareSpendingAcrossPeriodsTool(getFinanceSummary, periods),
      periods,
    );
  });

  void stubSpend({required int july, required int august}) {
    for (final (period, expense) in [(_july, july), (_august, august)]) {
      when(() => getFinanceSummary(period)).thenAnswer(
        (_) async => Right(
          FinanceSummary(
            totalIncome: const Money.fromMinorUnits(0),
            totalExpense: Money.fromMinorUnits(expense),
            period: period,
          ),
        ),
      );
    }
  }

  test('the threshold is a documented, fixed constant', () {
    expect(proactiveObservationMinPercentChange, 20);
  });

  test(
    'compares the last two complete months (never the month in progress) '
    'and surfaces a qualifying increase with the comparison\'s own figures',
    () async {
      stubSpend(july: 400000, august: 500000);

      final result = (await tool({})).getOrElse((f) => fail('$f'));

      verify(() => getFinanceSummary(_july)).called(1);
      verify(() => getFinanceSummary(_august)).called(1);
      verifyNoMoreInteractions(getFinanceSummary);
      expect(result.toolName, GetProactiveObservationTool.toolName);
      expect(result.sourceUseCase, 'GetFinanceSummary');
      expect(result.foundData, isTrue);
      expect(result.data['periodATotalMinorUnits'], 400000);
      expect(result.data['periodBTotalMinorUnits'], 500000);
      expect(result.data['differenceMinorUnits'], 100000);
      expect(result.data['percentChange'], 25.0);
      expect(result.data['direction'], 'increase');
      expect(
        result.data['observationKey'],
        'overallSpending:2026-07:2026-08:increase:25',
      );
    },
  );

  test('a qualifying decrease is surfaced too', () async {
    stubSpend(july: 500000, august: 300000);

    final result = (await tool({})).getOrElse((f) => fail('$f'));

    expect(result.foundData, isTrue);
    expect(result.data['direction'], 'decrease');
    expect(
      result.data['observationKey'],
      'overallSpending:2026-07:2026-08:decrease:40',
    );
  });

  test('the key is stable for the same data (de-duplicable)', () async {
    stubSpend(july: 400000, august: 500000);

    final first = (await tool({})).getOrElse((f) => fail('$f'));
    final second = (await tool({})).getOrElse((f) => fail('$f'));

    expect(second.data['observationKey'], first.data['observationKey']);
  });

  test('exactly at the threshold qualifies', () async {
    stubSpend(july: 100000, august: 120000);

    final result = (await tool({})).getOrElse((f) => fail('$f'));

    expect(result.foundData, isTrue);
  });

  test('foundData=false below the threshold (not meaningful)', () async {
    stubSpend(july: 100000, august: 119999);

    final result = (await tool({})).getOrElse((f) => fail('$f'));

    expect(result.foundData, isFalse);
    expect(result.data['reason'], AIToolNoDataReasons.belowThreshold);
    expect(result.data.containsKey('observationKey'), isFalse);
  });

  test('foundData=false on insufficient history (an empty month)', () async {
    stubSpend(july: 0, august: 500000);

    final result = (await tool({})).getOrElse((f) => fail('$f'));

    expect(result.foundData, isFalse);
    expect(result.data['reason'], AIToolNoDataReasons.insufficientHistory);
    expect(result.data.containsKey('observationKey'), isFalse);
  });

  test('passes a use-case failure through unchanged', () async {
    when(
      () => getFinanceSummary(any()),
    ).thenAnswer((_) async => const Left(CacheFailure('db')));

    expect(await tool({}), const Left<Failure, Never>(CacheFailure('db')));
  });
}
