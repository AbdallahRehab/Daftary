import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../occasions/domain/entities/occasion.dart';
import '../../../occasions/domain/entities/occasion_detail.dart';
import '../../../occasions/domain/usecases/get_occasion_detail.dart';
import '../../../occasions/domain/usecases/get_occasions_list.dart';
import '../entities/tool_result.dart';
import 'ai_tool.dart';
import 'tool_arguments.dart';
import 'tool_catalog.dart';

/// Keys of a `getOccasionTotals` result.
abstract final class AIOccasionDataKeys {
  /// A single named occasion's totals.
  static const String occasion = 'occasion';

  /// The most recent occasions' totals, newest first.
  static const String occasions = 'occasions';
  static const String occasionName = 'occasionName';
  static const String date = 'date';
  static const String totalReceivedMinorUnits = 'totalReceivedMinorUnits';
  static const String totalGivenMinorUnits = 'totalGivenMinorUnits';

  /// Exactly `OccasionSummary.net` (`received − given`, as 008 computes it).
  static const String netMinorUnits = 'netMinorUnits';

  /// `SettlementStatus` name: `settled` | `moreReceived` | `moreGiven`.
  static const String settlementStatus = 'settlementStatus';
}

/// `getOccasionTotals` — wraps [GetOccasionDetail] (008), whose
/// `OccasionSummary` carries the totals. [GetOccasionsList] only resolves
/// which occasion(s) to read: the named one, or the
/// [recentOccasionLimit] most recent when no name is given.
///
/// `foundData: false` when no occasion is recorded, or the name matches
/// none / more than one.
@injectable
class GetOccasionTotalsTool extends AITool {
  const GetOccasionTotalsTool(this._getOccasionDetail, this._getOccasionsList);

  final GetOccasionDetail _getOccasionDetail;
  final GetOccasionsList _getOccasionsList;

  static const String sourceUseCase = 'GetOccasionDetail';

  /// How many occasions an unnamed request reports — the minimum that
  /// answers "recent occasions" without dumping the whole history (FR-007).
  static const int recentOccasionLimit = 5;

  @override
  String get name => AIToolNames.getOccasionTotals;

  @override
  Future<Either<Failure, ToolResult>> call(
    Map<String, Object?> arguments,
  ) async {
    final String? requested;
    switch (AIToolArgumentReader.optionalString(
      arguments,
      AIToolArgs.occasionName,
    )) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final value):
        requested = value;
    }

    // Archived occasions still answer "how much did I get at X?".
    final List<Occasion> all;
    switch (await _getOccasionsList(includeArchived: true)) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final occasions):
        all = occasions;
    }
    if (all.isEmpty) {
      return Right(
        _noData({
          AIToolArgs.occasionName: ?requested,
          AIToolDataKeys.reason: AIToolNoDataReasons.noOccasionsRecorded,
        }),
      );
    }

    if (requested == null) {
      final details = <Map<String, Object?>>[];
      // The list is already newest first (008 FR-015).
      for (final occasion in all.take(recentOccasionLimit)) {
        switch (await _getOccasionDetail(occasion.id)) {
          case Left(value: final failure):
            return Left(failure);
          case Right(value: final detail):
            details.add(_occasion(detail));
        }
      }
      return Right(
        _found({AIOccasionDataKeys.occasions: details, ...aiToolMoneyUnits}),
      );
    }

    switch (matchByName<Occasion>(requested, all, (o) => o.name)) {
      case AINameNotFound():
        return Right(
          _noData({
            AIToolArgs.occasionName: requested,
            AIToolDataKeys.reason: AIToolNoDataReasons.occasionNotFound,
          }),
        );
      case AINameAmbiguous(:final candidateNames):
        return Right(
          _noData({
            AIToolArgs.occasionName: requested,
            AIToolDataKeys.reason: AIToolNoDataReasons.ambiguousOccasion,
            AIToolDataKeys.candidates: candidateNames,
          }),
        );
      case AINameMatched(item: final occasion):
        final detail = await _getOccasionDetail(occasion.id);
        return detail.map(
          (d) => _found({
            AIOccasionDataKeys.occasion: _occasion(d),
            ...aiToolMoneyUnits,
          }),
        );
    }
  }

  static Map<String, Object?> _occasion(OccasionDetail detail) => {
    AIOccasionDataKeys.occasionName: detail.occasion.name,
    AIOccasionDataKeys.date: formatAIDate(detail.occasion.date),
    AIOccasionDataKeys.totalReceivedMinorUnits:
        detail.summary.totalReceived.minorUnits,
    AIOccasionDataKeys.totalGivenMinorUnits:
        detail.summary.totalGiven.minorUnits,
    AIOccasionDataKeys.netMinorUnits: detail.summary.net.minorUnits,
    AIOccasionDataKeys.settlementStatus: detail.summary.settlementStatus.name,
  };

  ToolResult _found(Map<String, Object?> data) => ToolResult(
    toolName: name,
    sourceUseCase: sourceUseCase,
    foundData: true,
    data: data,
  );

  ToolResult _noData(Map<String, Object?> data) => ToolResult(
    toolName: name,
    sourceUseCase: sourceUseCase,
    foundData: false,
    data: data,
  );
}
