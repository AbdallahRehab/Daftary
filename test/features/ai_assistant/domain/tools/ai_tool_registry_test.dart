import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ai_assistant/domain/entities/tool_result.dart';
import 'package:daftary/features/ai_assistant/domain/tools/ai_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/ai_tool_registry.dart';
import 'package:daftary/features/ai_assistant/domain/tools/compare_spending_across_periods.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_budget_status_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_category_spend.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_occasion_totals_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_owed_overview_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_person_balance_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_savings_goal_status_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_savings_projection_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_top_spending_category.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _FakeTool extends AITool {
  _FakeTool(this.name, {this.throws = false});

  @override
  final String name;
  final bool throws;
  final calls = <Map<String, Object?>>[];

  @override
  Future<Either<Failure, ToolResult>> call(
    Map<String, Object?> arguments,
  ) async {
    calls.add(arguments);
    if (throws) throw StateError('boom');
    return Right(
      ToolResult(toolName: name, sourceUseCase: 'X', data: {}, foundData: true),
    );
  }
}

class _MockCategorySpend extends Mock implements GetCategorySpendTool {}

class _MockTopSpending extends Mock implements GetTopSpendingCategoryTool {}

class _MockCompare extends Mock implements CompareSpendingAcrossPeriodsTool {}

class _MockPersonBalance extends Mock implements GetPersonBalanceTool {}

class _MockOwedOverview extends Mock implements GetOwedOverviewTool {}

class _MockBudgetStatus extends Mock implements GetBudgetStatusTool {}

class _MockSavingsGoalStatus extends Mock implements GetSavingsGoalStatusTool {}

class _MockSavingsProjection extends Mock implements GetSavingsProjectionTool {}

class _MockOccasionTotals extends Mock implements GetOccasionTotalsTool {}

void main() {
  test('the DI constructor registers every catalog tool under its name', () {
    final tools = <AITool>[
      _MockCategorySpend(),
      _MockTopSpending(),
      _MockCompare(),
      _MockPersonBalance(),
      _MockOwedOverview(),
      _MockBudgetStatus(),
      _MockSavingsGoalStatus(),
      _MockSavingsProjection(),
      _MockOccasionTotals(),
    ];
    final names = [
      AIToolNames.getCategorySpend,
      AIToolNames.getTopSpendingCategory,
      AIToolNames.compareSpendingAcrossPeriods,
      AIToolNames.getPersonBalance,
      AIToolNames.getOwedOverview,
      AIToolNames.getBudgetStatus,
      AIToolNames.getSavingsGoalStatus,
      AIToolNames.getSavingsProjection,
      AIToolNames.getOccasionTotals,
    ];
    for (var i = 0; i < tools.length; i++) {
      when(() => tools[i].name).thenReturn(names[i]);
    }

    final registry = AIToolRegistry(
      tools[0] as GetCategorySpendTool,
      tools[1] as GetTopSpendingCategoryTool,
      tools[2] as CompareSpendingAcrossPeriodsTool,
      tools[3] as GetPersonBalanceTool,
      tools[4] as GetOwedOverviewTool,
      tools[5] as GetBudgetStatusTool,
      tools[6] as GetSavingsGoalStatusTool,
      tools[7] as GetSavingsProjectionTool,
      tools[8] as GetOccasionTotalsTool,
    );

    expect(registry.toolNames, AIToolNames.all);
    expect(
      AIToolNames.all,
      containsAll([
        AIToolNames.getSavingsGoalStatus,
        AIToolNames.getSavingsProjection,
      ]),
    );
    expect(
      aiToolCatalog.map((d) => d.name).toSet(),
      registry.toolNames,
      reason: 'every declared tool must be dispatchable, and vice versa',
    );
  });

  test(
    'dispatches to the named tool exactly once, with the arguments',
    () async {
      final a = _FakeTool('a');
      final b = _FakeTool('b');
      final registry = AIToolRegistry.fromTools([a, b]);

      final result = await registry.dispatch('b', {'x': 1});

      expect(result.getOrElse((f) => fail('$f')).toolName, 'b');
      expect(b.calls, [
        {'x': 1},
      ]);
      expect(a.calls, isEmpty);
      expect(registry.contains('a'), isTrue);
      expect(registry.contains('c'), isFalse);
    },
  );

  test('an unknown tool name → UnknownAIToolFailure, nothing runs', () async {
    final a = _FakeTool('a');
    final registry = AIToolRegistry.fromTools([a]);

    final result = await registry.dispatch('applyWhatIfScenario', {});

    expect(
      result,
      const Left<Failure, Never>(UnknownAIToolFailure('applyWhatIfScenario')),
    );
    expect(a.calls, isEmpty);
  });

  test(
    'a throwing tool becomes an UnknownFailure, never a raw exception',
    () async {
      final registry = AIToolRegistry.fromTools([_FakeTool('a', throws: true)]);

      final result = await registry.dispatch('a', {});

      expect(result.getLeft().toNullable(), isA<UnknownFailure>());
    },
  );

  test('duplicate tool names are rejected', () {
    expect(
      () => AIToolRegistry.fromTools([_FakeTool('a'), _FakeTool('a')]),
      throwsArgumentError,
    );
  });
}
