import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/tool_result.dart';
import 'ai_tool.dart';
import 'compare_spending_across_periods.dart';
import 'get_budget_status_tool.dart';
import 'get_category_spend.dart';
import 'get_occasion_totals_tool.dart';
import 'get_owed_overview_tool.dart';
import 'get_person_balance_tool.dart';
import 'get_top_spending_category.dart';

/// Dispatches a provider-requested tool call to the one [AITool] declared
/// under that name (`aiToolCatalog`). A name outside the registry is an
/// [UnknownAIToolFailure] — the model can only ever run what the app
/// declared.
@injectable
class AIToolRegistry {
  /// Every catalog tool, injected explicitly so DI cannot silently leave
  /// one out.
  AIToolRegistry(
    GetCategorySpendTool getCategorySpend,
    GetTopSpendingCategoryTool getTopSpendingCategory,
    CompareSpendingAcrossPeriodsTool compareSpendingAcrossPeriods,
    GetPersonBalanceTool getPersonBalance,
    GetOwedOverviewTool getOwedOverview,
    GetBudgetStatusTool getBudgetStatus,
    GetOccasionTotalsTool getOccasionTotals,
  ) : this.fromTools([
        getCategorySpend,
        getTopSpendingCategory,
        compareSpendingAcrossPeriods,
        getPersonBalance,
        getOwedOverview,
        getBudgetStatus,
        getOccasionTotals,
      ]);

  /// A registry over an explicit tool list. Throws [ArgumentError] when two
  /// tools share a name — dispatch must be unambiguous.
  AIToolRegistry.fromTools(Iterable<AITool> tools) : _tools = _index(tools);

  final Map<String, AITool> _tools;

  static Map<String, AITool> _index(Iterable<AITool> tools) {
    final byName = <String, AITool>{};
    for (final tool in tools) {
      if (byName.containsKey(tool.name)) {
        throw ArgumentError('Duplicate AI tool name: ${tool.name}');
      }
      byName[tool.name] = tool;
    }
    return Map.unmodifiable(byName);
  }

  /// The names this registry can dispatch.
  Set<String> get toolNames => _tools.keys.toSet();

  bool contains(String toolName) => _tools.containsKey(toolName);

  /// Runs [toolName] with the model-supplied [arguments]. Unknown name →
  /// [UnknownAIToolFailure]; anything a tool throws (it should not) →
  /// [UnknownFailure], so a raw exception never reaches the caller.
  Future<Either<Failure, ToolResult>> dispatch(
    String toolName,
    Map<String, Object?> arguments,
  ) async {
    final tool = _tools[toolName];
    if (tool == null) return Left(UnknownAIToolFailure(toolName));
    try {
      return await tool(arguments);
    } catch (e) {
      return Left(UnknownFailure('AI tool "$toolName" failed: $e'));
    }
  }
}
