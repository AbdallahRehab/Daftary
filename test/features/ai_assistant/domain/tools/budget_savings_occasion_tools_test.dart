// T032 (partial): the budget and occasion tools. The savings tools
// (`getSavingsGoalStatus`/`getSavingsProjection`) are blocked on feature
// 011 and are tested here once they exist.
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/ai_assistant/domain/tools/ai_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_budget_status_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_occasion_totals_tool.dart';
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
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBudgetForMonth extends Mock implements GetBudgetForMonth {}

class MockGetOccasionDetail extends Mock implements GetOccasionDetail {}

class MockGetOccasionsList extends Mock implements GetOccasionsList {}

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
      expect(result.data['overallState'], summary.overallStatus.name);
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
}
