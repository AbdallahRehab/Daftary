import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../finance/domain/entities/category.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/domain/entities/finance_history_filter.dart';
import '../../../finance/domain/usecases/get_categories.dart';
import '../../../finance/domain/usecases/get_category_breakdown.dart';
import '../entities/tool_result.dart';
import 'ai_tool.dart';
import 'category_breakdown_data.dart';
import 'tool_arguments.dart';
import 'tool_catalog.dart';

/// `getCategorySpend` — wraps [GetCategoryBreakdown] (007) for expenses.
///
/// Without `categoryName`: the breakdown list exactly as returned (already
/// largest first). With it: the one matching entry, picked by id from that
/// same list — no new aggregation. [GetCategories] is used only to resolve
/// the name, so a real category with no spend in the period is reported as
/// a genuine zero rather than "not found" (contract: a real zero is an
/// answer, not missing data).
///
/// `foundData: false` when the period has no expense entries at all, or
/// the named category does not exist / is ambiguous.
@injectable
class GetCategorySpendTool extends AITool {
  const GetCategorySpendTool(
    this._getCategoryBreakdown,
    this._getCategories,
    this._periods,
  );

  final GetCategoryBreakdown _getCategoryBreakdown;
  final GetCategories _getCategories;
  final AIPeriodResolver _periods;

  static const String sourceUseCase = 'GetCategoryBreakdown';

  @override
  String get name => AIToolNames.getCategorySpend;

  @override
  Future<Either<Failure, ToolResult>> call(
    Map<String, Object?> arguments,
  ) async {
    final period = _periods.resolveArgument(arguments, AIToolArgs.period);
    final categoryName = AIToolArgumentReader.optionalString(
      arguments,
      AIToolArgs.categoryName,
    );
    final DateRange range;
    final String? requested;
    switch ((period, categoryName)) {
      case (Left(value: final failure), _):
        return Left(failure);
      case (_, Left(value: final failure)):
        return Left(failure);
      case (Right(value: final r), Right(value: final c)):
        range = r;
        requested = c;
    }

    final breakdown = await _getCategoryBreakdown(
      range,
      type: FinanceEntryType.expense,
    );
    return breakdown.fold(Left.new, (items) async {
      final base = {
        AIToolArgs.period: aiPeriodData(range),
        ...aiToolMoneyUnits,
      };
      if (items.isEmpty) {
        return Right(
          _result(foundData: false, {
            ...base,
            AIToolDataKeys.reason: AIToolNoDataReasons.noEntriesForPeriod,
          }),
        );
      }
      final wanted = requested;
      if (wanted == null) {
        return Right(
          _result(foundData: true, {
            ...base,
            AICategoryDataKeys.categories: [
              for (final item in items) categoryBreakdownItemData(item),
            ],
          }),
        );
      }

      final categories = await _getCategories(
        type: FinanceEntryType.expense,
        includeArchived: true,
      );
      return categories.map((all) {
        switch (matchByName<Category>(wanted, all, (c) => c.name)) {
          case AINameNotFound():
            return _result(foundData: false, {
              ...base,
              AIToolArgs.categoryName: wanted,
              AIToolDataKeys.reason: AIToolNoDataReasons.categoryNotFound,
            });
          case AINameAmbiguous(:final candidateNames):
            return _result(foundData: false, {
              ...base,
              AIToolArgs.categoryName: wanted,
              AIToolDataKeys.reason: AIToolNoDataReasons.ambiguousCategory,
              AIToolDataKeys.candidates: candidateNames,
            });
          case AINameMatched(item: final category):
            final item = items
                .where((i) => i.categoryId == category.id)
                .firstOrNull;
            return _result(foundData: true, {
              ...base,
              AICategoryDataKeys.category: item != null
                  ? categoryBreakdownItemData(item)
                  // A real category with no entries in the period: the
                  // breakdown omits it, and its true total is zero.
                  : {
                      AICategoryDataKeys.name: category.name,
                      AICategoryDataKeys.amountMinorUnits: 0,
                      AICategoryDataKeys.shareOfPeriod: 0.0,
                    },
            });
        }
      });
    });
  }

  ToolResult _result(Map<String, Object?> data, {required bool foundData}) =>
      ToolResult(
        toolName: name,
        sourceUseCase: sourceUseCase,
        data: data,
        foundData: foundData,
      );
}
