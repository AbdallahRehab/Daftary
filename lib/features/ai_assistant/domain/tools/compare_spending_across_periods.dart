import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../finance/domain/entities/finance_history_filter.dart';
import '../../../finance/domain/usecases/get_finance_summary.dart';
import '../entities/tool_result.dart';
import 'ai_tool.dart';
import 'tool_arguments.dart';
import 'tool_catalog.dart';

/// Keys of a `compareSpendingAcrossPeriods` result.
abstract final class AICompareDataKeys {
  static const String periodATotalMinorUnits = 'periodATotalMinorUnits';
  static const String periodBTotalMinorUnits = 'periodBTotalMinorUnits';

  /// `periodB − periodA`: positive means spending went up.
  static const String differenceMinorUnits = 'differenceMinorUnits';

  /// `difference / periodA × 100`, rounded to one decimal place.
  static const String percentChange = 'percentChange';

  /// Which of `periodA`/`periodB` had no expenses (when `foundData` is
  /// false).
  static const String emptyPeriods = 'emptyPeriods';
}

/// `compareSpendingAcrossPeriods` — wraps [GetFinanceSummary] (007), called
/// once per period.
///
/// THE ONE DOCUMENTED ARITHMETIC EXCEPTION in `domain/tools/` (research.md
/// Decision 4, contracts/financial_query_tools.md): the difference and
/// percentage change between the two `totalExpense` values, each of which
/// came unmodified from its own [GetFinanceSummary] call. Nothing else is
/// computed — no estimate, no value the use case did not return.
///
/// `foundData: false` when either period has no recorded expenses — a
/// change against an empty side cannot be stated honestly (and a
/// percentage against zero is undefined).
@injectable
class CompareSpendingAcrossPeriodsTool extends AITool {
  const CompareSpendingAcrossPeriodsTool(
    this._getFinanceSummary,
    this._periods,
  );

  final GetFinanceSummary _getFinanceSummary;
  final AIPeriodResolver _periods;

  static const String sourceUseCase = 'GetFinanceSummary';

  @override
  String get name => AIToolNames.compareSpendingAcrossPeriods;

  @override
  Future<Either<Failure, ToolResult>> call(
    Map<String, Object?> arguments,
  ) async {
    final periodA = _periods.resolveArgument(arguments, AIToolArgs.periodA);
    final periodB = _periods.resolveArgument(arguments, AIToolArgs.periodB);
    switch ((periodA, periodB)) {
      case (Left(value: final failure), _):
        return Left(failure);
      case (_, Left(value: final failure)):
        return Left(failure);
      case (Right(value: final a), Right(value: final b)):
        return compare(a, b);
    }
  }

  /// The comparison itself, for already-resolved periods — also what the
  /// proactive observation tool reuses, so there is one implementation of
  /// the exception above.
  Future<Either<Failure, ToolResult>> compare(DateRange a, DateRange b) async {
    final int totalA;
    switch (await _getFinanceSummary(a)) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final summary):
        totalA = summary.totalExpense.minorUnits;
    }
    final int totalB;
    switch (await _getFinanceSummary(b)) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final summary):
        totalB = summary.totalExpense.minorUnits;
    }

    final base = <String, Object?>{
      AIToolArgs.periodA: aiPeriodData(a),
      AIToolArgs.periodB: aiPeriodData(b),
      ...aiToolMoneyUnits,
    };
    if (totalA == 0 || totalB == 0) {
      return Right(
        ToolResult(
          toolName: name,
          sourceUseCase: sourceUseCase,
          foundData: false,
          data: {
            ...base,
            AIToolDataKeys.reason: AIToolNoDataReasons.noEntriesForPeriod,
            AICompareDataKeys.emptyPeriods: [
              if (totalA == 0) AIToolArgs.periodA,
              if (totalB == 0) AIToolArgs.periodB,
            ],
          },
        ),
      );
    }

    // The documented exception: one subtraction and one percentage between
    // two independently sourced totals.
    final difference = totalB - totalA;
    final percentChange = (difference * 1000 / totalA).round() / 10;
    return Right(
      ToolResult(
        toolName: name,
        sourceUseCase: sourceUseCase,
        foundData: true,
        data: {
          ...base,
          AICompareDataKeys.periodATotalMinorUnits: totalA,
          AICompareDataKeys.periodBTotalMinorUnits: totalB,
          AICompareDataKeys.differenceMinorUnits: difference,
          AICompareDataKeys.percentChange: percentChange,
        },
      ),
    );
  }
}
