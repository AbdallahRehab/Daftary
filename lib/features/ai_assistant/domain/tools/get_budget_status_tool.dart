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
    // 018: a month whose spend needs a missing exchange rate has no known
    // actuals — a no-data answer naming the rates, not a tool failure.
    if (detail.getLeft().toNullable() case final RatesMissingFailure failure) {
      return Right(
        ToolResult(
          toolName: name,
          sourceUseCase: sourceUseCase,
          foundData: false,
          data: {
            AIToolArgs.month: month,
            ...aiRatesMissingData(failure.missingRatesFor),
          },
        ),
      );
    }
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
          AIBudgetDataKeys.totalActualMinorUnits: summary.totalActualMinorUnits,
          AIBudgetDataKeys.totalRemainingMinorUnits:
              summary.totalRemainingMinorUnits,
          AIBudgetDataKeys.overallPercentUsed: summary.overallPercentageUsed,
          AIBudgetDataKeys.overallState: summary.overallStatus.name,
          AIBudgetDataKeys.isOverBudget: summary.isOverBudgetOverall,
          AIBudgetDataKeys.unbudgetedSpending: [
            for (final item in summary.unbudgetedSpending)
              {
                AIBudgetDataKeys.category: item.categoryName,
                AIBudgetDataKeys.amountMinorUnits: item.amountMinorUnits,
              },
          ],
          ...aiToolMoneyUnits(summary.currency),
        },
      );
    });
  }

  static Map<String, Object?> _line(BudgetCategoryLine line) => {
    AIBudgetDataKeys.category: line.categoryName,
    AIBudgetDataKeys.plannedMinorUnits: line.plannedAmountMinorUnits,
    AIBudgetDataKeys.actualMinorUnits: line.actualAmountMinorUnits,
    AIBudgetDataKeys.remainingMinorUnits: line.remainingMinorUnits,
    AIBudgetDataKeys.percentUsed: line.percentageUsed,
    AIBudgetDataKeys.state: line.status.name,
  };
}
