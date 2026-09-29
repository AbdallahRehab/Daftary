// T032 (+ 011 T068): the budget, savings and occasion tools.
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/ai_assistant/domain/tools/ai_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_budget_status_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_occasion_totals_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_savings_goal_status_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_savings_projection_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_arguments.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_catalog.dart';
import 'package:daftary/features/budgets/domain/entities/budget.dart';
import 'package:daftary/features/budgets/domain/entities/budget_category_line.dart';
import 'package:daftary/features/budgets/domain/entities/budget_summary.dart';
import 'package:daftary/features/budgets/domain/usecases/get_budget_for_month.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_detail.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_summary.dart';
import 'package:daftary/features/occasions/domain/usecases/get_occasion_detail.dart';
import 'package:daftary/features/occasions/domain/usecases/get_occasions_list.dart';
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/entities/savings_overview.dart';
import 'package:daftary/features/savings/domain/entities/what_if_result.dart';
import 'package:daftary/features/savings/domain/services/savings_calculator.dart';
import 'package:daftary/features/savings/domain/usecases/calculate_what_if_completion_date.dart';
import 'package:daftary/features/savings/domain/usecases/calculate_what_if_monthly_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/get_goal_detail.dart';
import 'package:daftary/features/savings/domain/usecases/get_savings_overview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../savings/helpers/savings_test_data.dart';

class MockGetBudgetForMonth extends Mock implements GetBudgetForMonth {}

class MockGetOccasionDetail extends Mock implements GetOccasionDetail {}

class MockGetOccasionsList extends Mock implements GetOccasionsList {}

class MockGetGoalDetail extends Mock implements GetGoalDetail {}

class MockGetSavingsOverview extends Mock implements GetSavingsOverview {}

class MockWhatIfMonthly extends Mock
    implements CalculateWhatIfMonthlyContribution {}

class MockWhatIfDate extends Mock implements CalculateWhatIfCompletionDate {}

class _FixedClock implements AppClock {
  const _FixedClock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

final _now = DateTime(2026, 9, 24, 15, 30);

Occasion _occasion(String id, String name, DateTime date) => Occasion(
  id: id,
  idempotencyKey: 'k-$id',
  name: name,
  date: date,
  type: 'wedding',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

OccasionDetail _detail(Occasion occasion, int received, int given) =>
    OccasionDetail(
      occasion: occasion,
      summary: OccasionSummary(
        occasionId: occasion.id,
        totalReceived: Money.egp(received),
        totalGiven: Money.egp(given),
        participantCount: 4,
      ),
      participants: const [],
      attachments: const [],
    );

void main() {
  group('GetBudgetStatusTool', () {
    late MockGetBudgetForMonth getBudgetForMonth;
    late GetBudgetStatusTool tool;

    setUp(() {
      getBudgetForMonth = MockGetBudgetForMonth();
      tool = GetBudgetStatusTool(
        getBudgetForMonth,
        AIPeriodResolver.withClock(() => _now),
      );
    });

    const food = BudgetCategoryLine(
      allocationId: 'a1',
      categoryId: 'c1',
      categoryName: 'Food',
      categoryIcon: 'food',
      plannedAmountMinorUnits: 300000,
      actualAmountMinorUnits: 310001,
    );
    const transport = BudgetCategoryLine(
      allocationId: 'a2',
      categoryId: 'c2',
      categoryName: 'Transport',
      categoryIcon: 'car',
      plannedAmountMinorUnits: 90000,
      actualAmountMinorUnits: 30000,
    );
    const summary = BudgetSummary(
      budgetId: 'b1',
      categoryBreakdown: [food, transport],
      unbudgetedSpending: [
        UnbudgetedCategorySpend(
          categoryId: 'c3',
          categoryName: 'Gifts',
          categoryIcon: 'gift',
          amountMinorUnits: 12345,
        ),
      ],
    );
    final detail = BudgetMonthDetail(
      month: '2026-08',
      budget: Budget(
        id: 'b1',
        idempotencyKey: 'k',
        month: '2026-08',
        createdAt: DateTime(2026, 8),
        updatedAt: DateTime(2026, 8),
      ),
      summary: summary,
    );

    test('copies 010\'s own computed figures through unchanged', () async {
      when(
        () => getBudgetForMonth('2026-08'),
      ).thenAnswer((_) async => Right(detail));

      final result = (await tool({
        AIToolArgs.month: '2026-08',
      })).getOrElse((f) => fail('$f'));

      verify(() => getBudgetForMonth('2026-08')).called(1);
      expect(result.toolName, AIToolNames.getBudgetStatus);
      expect(result.sourceUseCase, 'GetBudgetForMonth');
      expect(result.foundData, isTrue);
      expect(result.data['month'], '2026-08');
      expect(result.data['categories'], [
        {
          'category': 'Food',
          'plannedMinorUnits': 300000,
          'actualMinorUnits': 310001,
          'remainingMinorUnits': food.remainingMinorUnits,
          'percentUsed': food.percentageUsed,
          'state': 'overBudget',
        },
        {
          'category': 'Transport',
          'plannedMinorUnits': 90000,
          'actualMinorUnits': 30000,
          'remainingMinorUnits': transport.remainingMinorUnits,
          'percentUsed': transport.percentageUsed,
          'state': 'onTrack',
        },
      ]);
      expect(
        result.data['totalPlannedMinorUnits'],
        summary.totalPlannedMinorUnits,
      );
      expect(
        result.data['totalActualMinorUnits'],
        summary.totalActualMinorUnits,
      );
      expect(
        result.data['totalRemainingMinorUnits'],
        summary.totalRemainingMinorUnits,
      );
      expect(result.data['overallPercentUsed'], summary.overallPercentageUsed);
      expect(result.data['overallState'], summary.overallStatus!.name);
      expect(result.data['isOverBudget'], summary.isOverBudgetOverall);
      expect(result.data['unbudgetedSpending'], [
        {'category': 'Gifts', 'amountMinorUnits': 12345},
      ]);
      expect(result.data[AIToolDataKeys.amountUnit], 'minorUnits');
    });

    test('an omitted month defaults to the current calendar month', () async {
      when(() => getBudgetForMonth('2026-09')).thenAnswer(
        (_) async => const Right(BudgetMonthDetail.empty('2026-09')),
      );

      await tool({});

      verify(() => getBudgetForMonth('2026-09')).called(1);
    });

    test('foundData=false when the month has no budget', () async {
      when(() => getBudgetForMonth('2026-09')).thenAnswer(
        (_) async => const Right(BudgetMonthDetail.empty('2026-09')),
      );

      final result = (await tool({
        AIToolArgs.month: '2026-09',
      })).getOrElse((f) => fail('$f'));

      expect(result.foundData, isFalse);
      expect(result.data['reason'], AIToolNoDataReasons.noBudgetForMonth);
      expect(result.data.containsKey('categories'), isFalse);
    });

    test(
      'a malformed month → ValidationFailure, use case never called',
      () async {
        for (final month in <Object>[
          '2026-13',
          'September',
          '2026-9',
          202609,
        ]) {
          final result = await tool({AIToolArgs.month: month});
          expect(result.getLeft().toNullable(), isA<ValidationFailure>());
        }
        verifyZeroInteractions(getBudgetForMonth);
      },
    );

    test('passes a use-case failure through unchanged', () async {
      when(
        () => getBudgetForMonth(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('db')));

      expect(
        await tool({AIToolArgs.month: '2026-08'}),
        const Left<Failure, Never>(CacheFailure('db')),
      );
    });

    test('018: a line blocked on a missing rate reports its plan and the '
        'missing rates, never a figure; the actual-side totals are '
        'omitted', () async {
      final blocked = BudgetMonthDetail(
        month: '2026-08',
        budget: detail.budget,
        summary: const BudgetSummary(
          budgetId: 'b1',
          categoryBreakdown: [
            BudgetCategoryLine(
              allocationId: 'a1',
              categoryId: 'c1',
              categoryName: 'Food',
              categoryIcon: 'food',
              plannedAmountMinorUnits: 300000,
              actualAmountMinorUnits: null,
              missingRatesFor: [Currency.usd],
            ),
            transport,
          ],
          unbudgetedSpending: [
            UnbudgetedCategorySpend(
              categoryId: 'c3',
              categoryName: 'Gifts',
              categoryIcon: 'gift',
              amountMinorUnits: null,
              missingRatesFor: [Currency.eur],
            ),
          ],
        ),
      );
      when(
        () => getBudgetForMonth('2026-08'),
      ).thenAnswer((_) async => Right(blocked));

      final result = (await tool({
        AIToolArgs.month: '2026-08',
      })).getOrElse((f) => fail('$f'));

      expect(result.foundData, isTrue);
      expect(result.data['categories'], [
        {
          'category': 'Food',
          'plannedMinorUnits': 300000,
          AIToolDataKeys.reason: AIToolNoDataReasons.exchangeRateMissing,
          AIToolDataKeys.missingRatesFor: ['USD'],
        },
        {
          'category': 'Transport',
          'plannedMinorUnits': 90000,
          'actualMinorUnits': 30000,
          'remainingMinorUnits': 60000,
          'percentUsed': transport.percentageUsed,
          'state': 'onTrack',
        },
      ]);
      expect(result.data['totalPlannedMinorUnits'], 390000);
      for (final key in [
        'totalActualMinorUnits',
        'totalRemainingMinorUnits',
        'overallPercentUsed',
        'overallState',
        'isOverBudget',
      ]) {
        expect(result.data.containsKey(key), isFalse, reason: key);
      }
      expect(result.data['unbudgetedSpending'], [
        {
          'category': 'Gifts',
          AIToolDataKeys.reason: AIToolNoDataReasons.exchangeRateMissing,
          AIToolDataKeys.missingRatesFor: ['EUR'],
        },
      ]);
      expect(
        result.data[AIToolDataKeys.reason],
        AIToolNoDataReasons.exchangeRateMissing,
      );
      expect(result.data[AIToolDataKeys.missingRatesFor], ['USD', 'EUR']);
    });
  });

  group('GetOccasionTotalsTool', () {
    late MockGetOccasionDetail getOccasionDetail;
    late MockGetOccasionsList getOccasionsList;
    late GetOccasionTotalsTool tool;

    final wedding = _occasion('o1', "Ahmed's Wedding", DateTime(2026, 8, 15));
    final sebou = _occasion('o2', 'Sebou Mona', DateTime(2026, 6, 2));

    setUp(() {
      getOccasionDetail = MockGetOccasionDetail();
      getOccasionsList = MockGetOccasionsList();
      tool = GetOccasionTotalsTool(getOccasionDetail, getOccasionsList);
    });

    void stubList(List<Occasion> occasions) {
      when(
        () => getOccasionsList(includeArchived: true),
      ).thenAnswer((_) async => Right(occasions));
    }

    test('named occasion: GetOccasionDetail\'s totals, unchanged', () async {
      stubList([wedding, sebou]);
      when(
        () => getOccasionDetail('o1'),
      ).thenAnswer((_) async => Right(_detail(wedding, 500050, 120000)));

      final result = (await tool({
        AIToolArgs.occasionName: "ahmed's wedding",
      })).getOrElse((f) => fail('$f'));

      verify(() => getOccasionDetail('o1')).called(1);
      verifyNever(() => getOccasionDetail('o2'));
      expect(result.toolName, AIToolNames.getOccasionTotals);
      expect(result.sourceUseCase, 'GetOccasionDetail');
      expect(result.foundData, isTrue);
      expect(result.data['occasion'], {
        'occasionName': "Ahmed's Wedding",
        'date': '2026-08-15',
        'totalReceivedMinorUnits': 500050,
        'totalGivenMinorUnits': 120000,
        'netMinorUnits': 380050, // OccasionSummary.net, not recomputed here
        'settlementStatus': 'moreReceived',
      });
    });

    test('no name: the most recent occasions, newest first, capped', () async {
      final many = [
        for (var i = 0; i < 7; i++)
          _occasion('o$i', 'Occasion $i', DateTime(2026, 9 - i, 1)),
      ];
      stubList(many);
      for (final o in many) {
        when(
          () => getOccasionDetail(o.id),
        ).thenAnswer((_) async => Right(_detail(o, 1000, 1000)));
      }

      final result = (await tool({})).getOrElse((f) => fail('$f'));

      final occasions = result.data['occasions']! as List<Object?>;
      expect(occasions, hasLength(GetOccasionTotalsTool.recentOccasionLimit));
      expect((occasions.first! as Map)['occasionName'], 'Occasion 0');
      expect((occasions.first! as Map)['settlementStatus'], 'settled');
      verifyNever(() => getOccasionDetail('o5'));
      verifyNever(() => getOccasionDetail('o6'));
    });

    test('foundData=false when no occasion is recorded at all', () async {
      stubList([]);

      final result = (await tool({})).getOrElse((f) => fail('$f'));

      expect(result.foundData, isFalse);
      expect(result.data['reason'], AIToolNoDataReasons.noOccasionsRecorded);
      verifyZeroInteractions(getOccasionDetail);
    });

    test('foundData=false for an unmatched occasion name', () async {
      stubList([wedding]);

      final result = (await tool({
        AIToolArgs.occasionName: 'Graduation',
      })).getOrElse((f) => fail('$f'));

      expect(result.foundData, isFalse);
      expect(result.data['reason'], AIToolNoDataReasons.occasionNotFound);
      verifyZeroInteractions(getOccasionDetail);
    });

    test('foundData=false with candidates for an ambiguous name', () async {
      stubList([
        _occasion('a', 'Wedding Ahmed', DateTime(2026, 5)),
        _occasion('b', 'Wedding Sara', DateTime(2026, 4)),
      ]);

      final result = (await tool({
        AIToolArgs.occasionName: 'wedding',
      })).getOrElse((f) => fail('$f'));

      expect(result.foundData, isFalse);
      expect(result.data['reason'], AIToolNoDataReasons.ambiguousOccasion);
      expect(result.data['candidates'], ['Wedding Ahmed', 'Wedding Sara']);
      verifyZeroInteractions(getOccasionDetail);
    });

    test('a non-string occasionName → ValidationFailure', () async {
      final result = await tool({AIToolArgs.occasionName: 3});
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyZeroInteractions(getOccasionsList);
    });

    test('passes a use-case failure through unchanged', () async {
      stubList([wedding]);
      when(
        () => getOccasionDetail('o1'),
      ).thenAnswer((_) async => const Left(CacheFailure('db')));

      expect(
        await tool({AIToolArgs.occasionName: "Ahmed's Wedding"}),
        const Left<Failure, Never>(CacheFailure('db')),
      );
    });
  });

  group('011 savings fixtures', () {
    final house = testGoal(
      name: 'House',
      target: 10000000,
      monthly: 100000,
      targetDate: DateTime(2027, 9, 15),
    );
    final car = testGoal(
      id: 'g2',
      name: 'Car Fund',
      currency: Currency.usd,
      target: 500000,
    );
    final houseLine = testOverviewLine(house, saved: 1000000);
    final carLine = testOverviewLine(
      car,
      saved: 50000,
      missing: [Currency.usd],
    );

    group('GetSavingsGoalStatusTool', () {
      late MockGetGoalDetail getGoalDetail;
      late MockGetSavingsOverview getSavingsOverview;
      late GetSavingsGoalStatusTool tool;

      setUp(() {
        getGoalDetail = MockGetGoalDetail();
        getSavingsOverview = MockGetSavingsOverview();
        tool = GetSavingsGoalStatusTool(getGoalDetail, getSavingsOverview);
      });

      void stubOverview(List<GoalOverviewLine> lines, {bool? archived}) {
        final overview = SavingsOverview(
          goals: lines,
          primaryCurrency: Currency.egp,
        );
        if (archived == null) {
          when(
            () => getSavingsOverview(),
          ).thenAnswer((_) async => Right(overview));
        } else {
          when(
            () => getSavingsOverview(includeArchived: archived),
          ).thenAnswer((_) async => Right(overview));
        }
      }

      test('no name: every active goal with 011\'s own figures, each in its '
          'own currency, and the overview total', () async {
        stubOverview([houseLine]);

        final result = (await tool({})).getOrElse((f) => fail('$f'));

        expect(result.toolName, AIToolNames.getSavingsGoalStatus);
        expect(result.sourceUseCase, 'GetSavingsOverview');
        expect(result.foundData, isTrue);
        final p = houseLine.progress;
        final e = p.estimatedCompletion!;
        expect(result.data['goals'], [
          {
            'goalName': 'House',
            'currency': 'EGP',
            'amountUnit': 'minorUnits',
            'minorUnitsPerMajorUnit': 100,
            'targetMinorUnits': p.targetAmountMinorUnits,
            'currentMinorUnits': p.currentAmountMinorUnits,
            'remainingMinorUnits': p.remainingMinorUnits,
            'percentProgress': p.percentageProgress,
            'isAchieved': p.isAchieved,
            'monthlyContributionMinorUnits': 100000,
            'targetDate': '2027-09-15',
            'estimatedMonthsToCompletion': e.estimatedMonths,
            'estimatedCompletionDate': formatAIDate(e.estimatedDate!),
            'requiredMonthlyContributionMinorUnits':
                e.requiredMonthlyContributionMinorUnits,
            'shortfallMonths': e.shortfallMonths,
          },
        ]);
        expect(p.remainingMinorUnits, 9000000, reason: 'fixture sanity');
        expect(result.data['totalSavedMinorUnits'], 1000000);
        expect(result.data['currency'], 'EGP');
        expect(result.data.containsKey('isTotalIncomplete'), isFalse);
        verifyZeroInteractions(getGoalDetail);
      });

      test('018: a goal needing a missing rate keeps its own figures, is '
          'marked excluded, and the total is flagged incomplete', () async {
        stubOverview([houseLine, carLine]);

        final result = (await tool({})).getOrElse((f) => fail('$f'));

        final goals = result.data['goals']! as List<Object?>;
        final carData = goals[1]! as Map<String, Object?>;
        expect(carData['currency'], 'USD');
        expect(carData['currentMinorUnits'], 50000);
        expect(carData['excludedFromTotal'], isTrue);
        expect((goals[0]! as Map).containsKey('excludedFromTotal'), isFalse);
        expect(
          result.data['totalSavedMinorUnits'],
          SavingsOverview(
            goals: [houseLine, carLine],
            primaryCurrency: Currency.egp,
          ).totalSavedMinorUnits,
        );
        expect(result.data['isTotalIncomplete'], isTrue);
        expect(result.data[AIToolDataKeys.missingRatesFor], ['USD']);
      });

      test('foundData=false when the user has no savings goal', () async {
        stubOverview([]);

        final result = (await tool({})).getOrElse((f) => fail('$f'));

        expect(result.foundData, isFalse);
        expect(result.data['reason'], AIToolNoDataReasons.noSavingsGoals);
        expect(result.data.containsKey('goals'), isFalse);
      });

      test('named goal: GetGoalDetail\'s figures, unchanged', () async {
        stubOverview([houseLine, carLine], archived: true);
        final detail = testDetail(house, history: [testEntry(amount: 1500000)]);
        when(() => getGoalDetail('g1')).thenAnswer((_) async => Right(detail));

        final result = (await tool({
          AIToolArgs.goalName: ' house ',
        })).getOrElse((f) => fail('$f'));

        verify(() => getGoalDetail('g1')).called(1);
        expect(result.sourceUseCase, 'GetGoalDetail');
        expect(result.foundData, isTrue);
        final goal = result.data['goal']! as Map<String, Object?>;
        expect(goal['goalName'], 'House');
        expect(goal['currentMinorUnits'], 1500000);
        expect(
          goal['remainingMinorUnits'],
          detail.progress.remainingMinorUnits,
        );
        expect(
          goal['estimatedMonthsToCompletion'],
          detail.progress.estimatedCompletion!.estimatedMonths,
        );
        expect(goal['isArchived'], isFalse);
        expect(goal.containsKey('history'), isFalse, reason: 'minimum data');
      });

      test('foundData=false for an unmatched or ambiguous name; no goal '
          'at all → noSavingsGoals', () async {
        stubOverview([
          houseLine,
          testOverviewLine(testGoal(id: 'g3', name: 'House repairs')),
        ], archived: true);

        final missing = (await tool({
          AIToolArgs.goalName: 'Wedding',
        })).getOrElse((f) => fail('$f'));
        expect(missing.foundData, isFalse);
        expect(missing.data['reason'], AIToolNoDataReasons.goalNotFound);

        final ambiguous = (await tool({
          AIToolArgs.goalName: 'hous',
        })).getOrElse((f) => fail('$f'));
        expect(ambiguous.foundData, isFalse);
        expect(ambiguous.data['reason'], AIToolNoDataReasons.ambiguousGoal);
        expect(ambiguous.data['candidates'], ['House', 'House repairs']);

        stubOverview([], archived: true);
        final none = (await tool({
          AIToolArgs.goalName: 'House',
        })).getOrElse((f) => fail('$f'));
        expect(none.foundData, isFalse);
        expect(none.data['reason'], AIToolNoDataReasons.noSavingsGoals);
        verifyZeroInteractions(getGoalDetail);
      });

      test('a goal deleted between lookup and read → foundData=false; other '
          'failures pass through', () async {
        stubOverview([houseLine], archived: true);
        when(
          () => getGoalDetail('g1'),
        ).thenAnswer((_) async => const Left(GoalNotFoundFailure('gone')));
        final gone = (await tool({
          AIToolArgs.goalName: 'House',
        })).getOrElse((f) => fail('$f'));
        expect(gone.foundData, isFalse);
        expect(gone.data['reason'], AIToolNoDataReasons.goalNotFound);

        when(
          () => getGoalDetail('g1'),
        ).thenAnswer((_) async => const Left(CacheFailure('db')));
        expect(
          await tool({AIToolArgs.goalName: 'House'}),
          const Left<Failure, Never>(CacheFailure('db')),
        );

        when(
          () => getSavingsOverview(),
        ).thenAnswer((_) async => const Left(UnknownFailure('x')));
        expect(await tool({}), const Left<Failure, Never>(UnknownFailure('x')));
      });

      test('a non-string goalName → ValidationFailure', () async {
        final result = await tool({AIToolArgs.goalName: 7});
        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
        verifyZeroInteractions(getSavingsOverview);
      });
    });

    group('GetSavingsProjectionTool', () {
      late MockGetSavingsOverview getSavingsOverview;
      late MockWhatIfMonthly whatIfMonthly;
      late MockWhatIfDate whatIfDate;
      late GetSavingsProjectionTool tool;

      setUp(() {
        getSavingsOverview = MockGetSavingsOverview();
        whatIfMonthly = MockWhatIfMonthly();
        whatIfDate = MockWhatIfDate();
        tool = GetSavingsProjectionTool(
          getSavingsOverview,
          whatIfMonthly,
          whatIfDate,
        );
        when(() => getSavingsOverview(includeArchived: true)).thenAnswer(
          (_) async => Right(
            SavingsOverview(
              goals: [houseLine, carLine],
              primaryCurrency: Currency.egp,
            ),
          ),
        );
      });

      test('monthly amount: CalculateWhatIfMonthlyContribution\'s result, '
          'unchanged, in the goal\'s currency', () async {
        final whatIf = WhatIfResult(
          hypotheticalMonthlyContributionMinorUnits: 7000,
          hypotheticalTargetDate: DateTime(2032, 3, 15),
          estimatedMonths: 65,
        );
        when(
          () => whatIfMonthly(
            goalId: 'g2',
            hypotheticalMonthlyContributionMinorUnits: 7000,
          ),
        ).thenAnswer((_) async => Right(whatIf));

        final result = (await tool({
          AIToolArgs.goalName: 'car fund',
          AIToolArgs.hypotheticalMonthlyContributionMinorUnits: 7000,
        })).getOrElse((f) => fail('$f'));

        expect(result.toolName, AIToolNames.getSavingsProjection);
        expect(result.sourceUseCase, 'CalculateWhatIfMonthlyContribution');
        expect(result.foundData, isTrue);
        expect(result.data, {
          'goalName': 'Car Fund',
          'mode': 'monthlyContribution',
          'hypotheticalMonthlyContributionMinorUnits': 7000,
          'projectedMonthsToCompletion': 65,
          'projectedCompletionDate': '2032-03-15',
          'currency': 'USD',
          'amountUnit': 'minorUnits',
          'minorUnitsPerMajorUnit': 100,
        });
        verifyZeroInteractions(whatIfDate);
      });

      test('a whole-number double (JSON 7000.0) is the same integer', () async {
        when(
          () => whatIfMonthly(
            goalId: 'g1',
            hypotheticalMonthlyContributionMinorUnits: 7000,
          ),
        ).thenAnswer(
          (_) async => const Right(
            WhatIfResult(
              hypotheticalMonthlyContributionMinorUnits: 7000,
              estimatedMonths: 3,
            ),
          ),
        );
        final result = await tool({
          AIToolArgs.goalName: 'House',
          AIToolArgs.hypotheticalMonthlyContributionMinorUnits: 7000.0,
        });
        expect(result.isRight(), isTrue);
      });

      test('target date: CalculateWhatIfCompletionDate\'s required monthly '
          'contribution, unchanged', () async {
        when(
          () => whatIfDate(
            goalId: 'g1',
            hypotheticalTargetDate: DateTime(2027, 9, 15),
          ),
        ).thenAnswer(
          (_) async => Right(
            WhatIfResult(
              hypotheticalMonthlyContributionMinorUnits: 750001,
              hypotheticalTargetDate: DateTime(2027, 9, 15),
              estimatedMonths: 12,
            ),
          ),
        );

        final result = (await tool({
          AIToolArgs.goalName: 'House',
          AIToolArgs.hypotheticalTargetDate: '2027-09-15',
        })).getOrElse((f) => fail('$f'));

        expect(result.sourceUseCase, 'CalculateWhatIfCompletionDate');
        expect(result.data['mode'], 'targetDate');
        expect(result.data['hypotheticalTargetDate'], '2027-09-15');
        expect(result.data['requiredMonthlyContributionMinorUnits'], 750001);
        expect(result.data['projectedMonthsToCompletion'], 12);
        expect(result.data['currency'], 'EGP');
        verifyZeroInteractions(whatIfMonthly);
      });

      test('over the real 011 use cases, the stated figures are exactly '
          'what those use cases compute', () async {
        final getGoalDetail = MockGetGoalDetail();
        final detail = testDetail(house, history: [testEntry(amount: 1000000)]);
        when(() => getGoalDetail('g1')).thenAnswer((_) async => Right(detail));
        final clock = _FixedClock(testToday);
        const calculator = DefaultSavingsCalculator();
        final monthly = CalculateWhatIfMonthlyContribution(
          getGoalDetail,
          calculator,
          clock,
        );
        final byDate = CalculateWhatIfCompletionDate(
          getGoalDetail,
          calculator,
          clock,
        );
        final real = GetSavingsProjectionTool(
          getSavingsOverview,
          monthly,
          byDate,
        );

        final expectedMonthly = (await monthly(
          goalId: 'g1',
          hypotheticalMonthlyContributionMinorUnits: 333333,
        )).getOrElse((f) => fail('$f'));
        final byAmount = (await real({
          AIToolArgs.goalName: 'House',
          AIToolArgs.hypotheticalMonthlyContributionMinorUnits: 333333,
        })).getOrElse((f) => fail('$f'));
        expect(
          byAmount.data['projectedMonthsToCompletion'],
          expectedMonthly.estimatedMonths,
        );
        expect(
          byAmount.data['projectedCompletionDate'],
          formatAIDate(expectedMonthly.hypotheticalTargetDate!),
        );

        final expectedByDate = (await byDate(
          goalId: 'g1',
          hypotheticalTargetDate: DateTime(2028, 1, 1),
        )).getOrElse((f) => fail('$f'));
        final byDateResult = (await real({
          AIToolArgs.goalName: 'House',
          AIToolArgs.hypotheticalTargetDate: '2028-01-01',
        })).getOrElse((f) => fail('$f'));
        expect(
          byDateResult.data['requiredMonthlyContributionMinorUnits'],
          expectedByDate.hypotheticalMonthlyContributionMinorUnits,
        );
        expect(
          byDateResult.data['projectedMonthsToCompletion'],
          expectedByDate.estimatedMonths,
        );
      });

      test('foundData=false when no goal matches, or none exists', () async {
        final missing = (await tool({
          AIToolArgs.goalName: 'Wedding',
          AIToolArgs.hypotheticalMonthlyContributionMinorUnits: 5000,
        })).getOrElse((f) => fail('$f'));
        expect(missing.foundData, isFalse);
        expect(missing.data['reason'], AIToolNoDataReasons.goalNotFound);

        when(() => getSavingsOverview(includeArchived: true)).thenAnswer(
          (_) async => const Right(
            SavingsOverview(goals: [], primaryCurrency: Currency.egp),
          ),
        );
        final none = (await tool({
          AIToolArgs.goalName: 'House',
          AIToolArgs.hypotheticalMonthlyContributionMinorUnits: 5000,
        })).getOrElse((f) => fail('$f'));
        expect(none.foundData, isFalse);
        expect(none.data['reason'], AIToolNoDataReasons.noSavingsGoals);
        verifyZeroInteractions(whatIfMonthly);
      });

      test('an achieved goal → foundData=false, never "0 months"', () async {
        when(
          () => whatIfMonthly(
            goalId: 'g1',
            hypotheticalMonthlyContributionMinorUnits: 5000,
          ),
        ).thenAnswer((_) async => const Left(goalAlreadyAchieved));

        final result = (await tool({
          AIToolArgs.goalName: 'House',
          AIToolArgs.hypotheticalMonthlyContributionMinorUnits: 5000,
        })).getOrElse((f) => fail('$f'));

        expect(result.foundData, isFalse);
        expect(result.data['reason'], AIToolNoDataReasons.goalAlreadyAchieved);
        expect(result.data.containsKey('projectedMonthsToCompletion'), isFalse);
      });

      test('failures: validation and invalid dates become ValidationFailure; '
          'GoalNotFound → foundData=false; others pass through', () async {
        when(
          () => whatIfMonthly(
            goalId: 'g1',
            hypotheticalMonthlyContributionMinorUnits: 0,
          ),
        ).thenAnswer((_) async => const Left(ValidationFailure('must be > 0')));
        expect(
          await tool({
            AIToolArgs.goalName: 'House',
            AIToolArgs.hypotheticalMonthlyContributionMinorUnits: 0,
          }),
          const Left<Failure, Never>(ValidationFailure('must be > 0')),
        );

        when(
          () => whatIfDate(
            goalId: 'g1',
            hypotheticalTargetDate: DateTime(2020, 1, 1),
          ),
        ).thenAnswer(
          (_) async => const Left(InvalidTargetDateFailure('after today')),
        );
        final pastDate = await tool({
          AIToolArgs.goalName: 'House',
          AIToolArgs.hypotheticalTargetDate: '2020-01-01',
        });
        expect(pastDate.getLeft().toNullable(), isA<ValidationFailure>());

        when(
          () => whatIfMonthly(
            goalId: 'g1',
            hypotheticalMonthlyContributionMinorUnits: 5000,
          ),
        ).thenAnswer((_) async => const Left(GoalNotFoundFailure('gone')));
        final gone = (await tool({
          AIToolArgs.goalName: 'House',
          AIToolArgs.hypotheticalMonthlyContributionMinorUnits: 5000,
        })).getOrElse((f) => fail('$f'));
        expect(gone.foundData, isFalse);
        expect(gone.data['reason'], AIToolNoDataReasons.goalNotFound);

        when(
          () => whatIfMonthly(
            goalId: 'g1',
            hypotheticalMonthlyContributionMinorUnits: 6000,
          ),
        ).thenAnswer((_) async => const Left(CacheFailure('db')));
        expect(
          await tool({
            AIToolArgs.goalName: 'House',
            AIToolArgs.hypotheticalMonthlyContributionMinorUnits: 6000,
          }),
          const Left<Failure, Never>(CacheFailure('db')),
        );
      });

      test('malformed arguments → ValidationFailure before anything is '
          'read', () async {
        for (final args in <Map<String, Object?>>[
          {AIToolArgs.hypotheticalMonthlyContributionMinorUnits: 5000},
          {AIToolArgs.goalName: 'House'},
          {
            AIToolArgs.goalName: 'House',
            AIToolArgs.hypotheticalMonthlyContributionMinorUnits: 5000,
            AIToolArgs.hypotheticalTargetDate: '2028-01-01',
          },
          {
            AIToolArgs.goalName: 'House',
            AIToolArgs.hypotheticalMonthlyContributionMinorUnits: 50.5,
          },
          {
            AIToolArgs.goalName: 'House',
            AIToolArgs.hypotheticalMonthlyContributionMinorUnits: '5000',
          },
          {
            AIToolArgs.goalName: 'House',
            AIToolArgs.hypotheticalTargetDate: '2028-02-30',
          },
        ]) {
          final result = await tool(args);
          expect(
            result.getLeft().toNullable(),
            isA<ValidationFailure>(),
            reason: '$args',
          );
        }
        verifyNever(
          () => getSavingsOverview(
            includeArchived: any(named: 'includeArchived'),
          ),
        );
        verifyZeroInteractions(whatIfMonthly);
        verifyZeroInteractions(whatIfDate);
      });
    });
  });
}
