import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../budgets/domain/entities/budget_month.dart';
import '../entities/tool_result.dart';
import 'ai_tool.dart';
import 'compare_spending_across_periods.dart';
import 'tool_arguments.dart';

/// The smallest month-over-month change in total spending, in percent
/// (either direction), worth volunteering unprompted (spec User Story 7).
/// Below it the change is ordinary noise and the tool reports
/// `foundData: false`. Checked exactly, in integers, against the two
/// totals — not against the rounded `percentChange`.
const int proactiveObservationMinPercentChange = 20;

/// Keys a proactive observation adds on top of the comparison's own data.
abstract final class AIObservationDataKeys {
  /// Stable identity of this observation — what the caller persists to
  /// avoid surfacing the same one twice (User Story 7 AC3). Format:
  /// `overallSpending:<periodA YYYY-MM>:<periodB YYYY-MM>:<direction>:<rounded percent>`.
  static const String observationKey = 'observationKey';

  /// `increase` | `decrease`.
  static const String direction = 'direction';
  static const String thresholdPercent = 'thresholdPercent';
}

/// Produces at most one unprompted spending observation: total spending in
/// the last complete month vs the complete month before it.
///
/// Not a model-callable tool (it is not in `aiToolCatalog` or the
/// registry); `GetProactiveObservation` invokes it when the assistant
/// opens. It computes nothing itself — the figures are
/// [CompareSpendingAcrossPeriodsTool.compare]'s, over [GetFinanceSummary]
/// results. Two *complete* months are compared (not the month in
/// progress) so a partial month never reads as a sudden drop.
///
/// `foundData: false` when either month has no expenses (insufficient
/// history) or the change is below [proactiveObservationMinPercentChange].
@injectable
class GetProactiveObservationTool extends AITool {
  const GetProactiveObservationTool(this._compareSpending, this._periods);

  final CompareSpendingAcrossPeriodsTool _compareSpending;
  final AIPeriodResolver _periods;

  static const String toolName = 'getProactiveObservation';

  @override
  String get name => toolName;

  /// Takes no arguments; any given are ignored.
  @override
  Future<Either<Failure, ToolResult>> call(
    Map<String, Object?> arguments,
  ) async {
    final periodA = _periods.monthBeforeLast();
    final periodB = _periods.lastMonth();
    final comparison = await _compareSpending.compare(periodA, periodB);
    return comparison.map((result) {
      if (!result.foundData) {
        return _result(foundData: false, {
          ...result.data,
          AIToolDataKeys.reason: AIToolNoDataReasons.insufficientHistory,
          AIObservationDataKeys.thresholdPercent:
              proactiveObservationMinPercentChange,
        });
      }
      final percentChange =
          result.data[AICompareDataKeys.percentChange]! as num;
      final difference =
          result.data[AICompareDataKeys.differenceMinorUnits]! as int;
      final baseline =
          result.data[AICompareDataKeys.periodATotalMinorUnits]! as int;
      // |difference| / baseline < threshold %, compared without division.
      if (difference.abs() * 100 <
          proactiveObservationMinPercentChange * baseline) {
        return _result(foundData: false, {
          ...result.data,
          AIToolDataKeys.reason: AIToolNoDataReasons.belowThreshold,
          AIObservationDataKeys.thresholdPercent:
              proactiveObservationMinPercentChange,
        });
      }
      final direction = difference > 0 ? 'increase' : 'decrease';
      final key = [
        'overallSpending',
        BudgetMonth.fromDate(periodA.start),
        BudgetMonth.fromDate(periodB.start),
        direction,
        percentChange.round().abs(),
      ].join(':');
      return _result(foundData: true, {
        ...result.data,
        AIObservationDataKeys.direction: direction,
        AIObservationDataKeys.thresholdPercent:
            proactiveObservationMinPercentChange,
        AIObservationDataKeys.observationKey: key,
      });
    });
  }

  ToolResult _result(Map<String, Object?> data, {required bool foundData}) =>
      ToolResult(
        toolName: name,
        sourceUseCase: CompareSpendingAcrossPeriodsTool.sourceUseCase,
        data: data,
        foundData: foundData,
      );
}
