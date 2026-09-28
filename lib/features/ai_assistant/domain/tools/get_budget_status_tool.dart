import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../budgets/domain/entities/budget_category_line.dart';
import '../../../budgets/domain/entities/budget_month.dart';
import '../../../budgets/domain/entities/budget_summary.dart';
import '../../../budgets/domain/usecases/get_budget_for_month.dart';
import '../entities/tool_result.dart';
import 'ai_tool.dart';
import 'tool_arguments.dart';
import 'tool_catalog.dart';

/// Keys of a `getBudgetStatus` result.
abstract final class AIBudgetDataKeys {
  static const String categories = 'categories';
  static const String category = 'category';
  static const String plannedMinorUnits = 'plannedMinorUnits';
  static const String actualMinorUnits = 'actualMinorUnits';
  static const String remainingMinorUnits = 'remainingMinorUnits';

  /// `actual / planned × 100` as 010 computes it; `null` when nothing is
  /// planned.
  static const String percentUsed = 'percentUsed';

  /// `BudgetCategoryStatus` name: `onTrack` | `nearFull` | `overBudget`.
  static const String state = 'state';
  static const String totalPlannedMinorUnits = 'totalPlannedMinorUnits';
  static const String totalActualMinorUnits = 'totalActualMinorUnits';
  static const String totalRemainingMinorUnits = 'totalRemainingMinorUnits';
  static const String overallPercentUsed = 'overallPercentUsed';
  static const String overallState = 'overallState';
  static const String isOverBudget = 'isOverBudget';

  /// `[{category, amountMinorUnits}]` — spend in categories the budget has
  /// no allocation for (010 FR-007).
  static const String unbudgetedSpending = 'unbudgetedSpending';
  static const String amountMinorUnits = 'amountMinorUnits';
}

/// `getBudgetStatus` — wraps [GetBudgetForMonth] (010).
///
/// Every figure is read from 010's own value objects ([BudgetSummary],
/// [BudgetCategoryLine]), whose getters are 010's single implementation of
/// the budget arithmetic; the tool copies them, it does not recompute them.
///
/// `month` defaults to the current calendar month. `foundData: false` when
/// the month has no budget (010's own empty state).
///
/// 018 FR-009: a figure 010 reports as unknown (it needs a missing exchange
/// rate) is left out — never estimated. A blocked line keeps its planned
/// amount and carries `reason`/`missingRatesFor` instead of its actual,
/// remaining, percentage and state; a blocked unbudgeted item likewise
/// instead of its amount; and when any actual-side total is unknown, those
/// totals are omitted and the result carries `reason`/`missingRatesFor`
/// naming every currency the month needs.
@injectable
class GetBudgetStatusTool extends AITool {
  const GetBudgetStatusTool(this._getBudgetForMonth, this._periods);

  final GetBudgetForMonth _getBudgetForMonth;
  final AIPeriodResolver _periods;

  static const String sourceUseCase = 'GetBudgetForMonth';

  @override
  String get name => AIToolNames.getBudgetStatus;

  @override
  Future<Either<Failure, ToolResult>> call(
    Map<String, Object?> arguments,
  ) async {
    final String month;
    switch (AIToolArgumentReader.optionalString(arguments, AIToolArgs.month)) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: null):
        month = _periods.currentMonth();
      case Right(value: final String value):
        if (!BudgetMonth.isValid(value)) {
          return Left(
            ValidationFailure('"${AIToolArgs.month}" must be YYYY-MM'),
          );
        }
        month = value;
    }

    final detail = await _getBudgetForMonth(month);
    return detail.map((d) {
      final summary = d.summary;
      if (!d.hasBudget || summary == null) {
        return ToolResult(
          toolName: name,
          sourceUseCase: sourceUseCase,
          foundData: false,
          data: {
            AIToolArgs.month: d.month,
            AIToolDataKeys.reason: AIToolNoDataReasons.noBudgetForMonth,
          },
        );
      }
      return ToolResult(
        toolName: name,
        sourceUseCase: sourceUseCase,
        foundData: true,
        data: {
          AIToolArgs.month: d.month,
          AIBudgetDataKeys.categories: [
            for (final line in summary.categoryBreakdown) _line(line),
          ],
          AIBudgetDataKeys.totalPlannedMinorUnits:
              summary.totalPlannedMinorUnits,
          if (!summary.isActualBlocked) ...{
            AIBudgetDataKeys.totalActualMinorUnits:
                summary.totalActualMinorUnits,
            AIBudgetDataKeys.totalRemainingMinorUnits:
                summary.totalRemainingMinorUnits,
            AIBudgetDataKeys.overallPercentUsed: summary.overallPercentageUsed,
            AIBudgetDataKeys.overallState: summary.overallStatus?.name,
            AIBudgetDataKeys.isOverBudget: summary.isOverBudgetOverall,
          },
          AIBudgetDataKeys.unbudgetedSpending: [
            for (final item in summary.unbudgetedSpending)
              {
                AIBudgetDataKeys.category: item.categoryName,
                if (item.amountMinorUnits case final amount?)
                  AIBudgetDataKeys.amountMinorUnits: amount
                else
                  ...aiRatesMissingData(item.missingRatesFor),
              },
          ],
          ...aiToolMoneyUnits(summary.currency),
          if (summary.isBlocked) ...aiRatesMissingData(summary.missingRatesFor),
        },
      );
    });
  }

  static Map<String, Object?> _line(BudgetCategoryLine line) => {
    AIBudgetDataKeys.category: line.categoryName,
    AIBudgetDataKeys.plannedMinorUnits: line.plannedAmountMinorUnits,
    if (line.isBlocked)
      ...aiRatesMissingData(line.missingRatesFor)
    else ...{
      AIBudgetDataKeys.actualMinorUnits: line.actualAmountMinorUnits,
      AIBudgetDataKeys.remainingMinorUnits: line.remainingMinorUnits,
      AIBudgetDataKeys.percentUsed: line.percentageUsed,
      AIBudgetDataKeys.state: line.status?.name,
    },
  };
}
