import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/domain/usecases/get_category_breakdown.dart';
import '../entities/tool_result.dart';
import 'ai_tool.dart';
import 'category_breakdown_data.dart';
import 'tool_arguments.dart';
import 'tool_catalog.dart';

/// `getTopSpendingCategory` — wraps [GetCategoryBreakdown] (007) for
/// expenses and returns its first entry. The use case guarantees the list
/// is largest first, so the tool reads list order and never compares
/// amounts itself.
///
/// `foundData: false` when the period has no expense entries.
@injectable
class GetTopSpendingCategoryTool extends AITool {
  const GetTopSpendingCategoryTool(this._getCategoryBreakdown, this._periods);

  final GetCategoryBreakdown _getCategoryBreakdown;
  final AIPeriodResolver _periods;

  static const String sourceUseCase = 'GetCategoryBreakdown';

  @override
  String get name => AIToolNames.getTopSpendingCategory;

  @override
  Future<Either<Failure, ToolResult>> call(
    Map<String, Object?> arguments,
  ) async {
    final period = _periods.resolveArgument(arguments, AIToolArgs.period);
    return period.fold(Left.new, (range) async {
      final breakdown = await _getCategoryBreakdown(
        range,
        type: FinanceEntryType.expense,
      );
      return breakdown.map((breakdown) {
        final items = breakdown.items;
        final base = {
          AIToolArgs.period: aiPeriodData(range),
          ...aiToolMoneyUnits(breakdown.currency),
        };
        if (breakdown.isBlocked) {
          return ToolResult(
            toolName: name,
            sourceUseCase: sourceUseCase,
            foundData: false,
            data: {...base, ...aiRatesMissingData(breakdown.missingRatesFor)},
          );
        }
        return ToolResult(
          toolName: name,
          sourceUseCase: sourceUseCase,
          foundData: items.isNotEmpty,
          data: items.isEmpty
              ? {
                  ...base,
                  AIToolDataKeys.reason: AIToolNoDataReasons.noEntriesForPeriod,
                }
              : {
                  ...base,
                  AICategoryDataKeys.category: categoryBreakdownItemData(
                    items.first,
                  ),
                },
        );
      });
    });
  }
}
