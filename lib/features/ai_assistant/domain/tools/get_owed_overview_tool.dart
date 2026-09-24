import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../transactions/domain/entities/overview_summary.dart';
import '../../../transactions/domain/usecases/get_overview.dart';
import '../entities/tool_result.dart';
import 'ai_tool.dart';
import 'get_person_balance_tool.dart';
import 'tool_catalog.dart';

/// Keys of a `getOwedOverview` result.
abstract final class AIOverviewDataKeys {
  static const String totalOwedToUserMinorUnits = 'totalOwedToUserMinorUnits';
  static const String totalUserOwesMinorUnits = 'totalUserOwesMinorUnits';

  /// `[{personName, netMinorUnits}]`, `netMinorUnits` positive.
  static const String peopleTheyOweYou = 'peopleTheyOweYou';

  /// `[{personName, netMinorUnits}]`, `netMinorUnits` negative — exactly
  /// `PersonSummary.net`, sign included.
  static const String peopleYouOweThem = 'peopleYouOweThem';
  static const String settledCount = 'settledCount';
}

/// `getOwedOverview` — wraps [GetOverview] (001) and copies its totals and
/// groupings through unchanged.
///
/// `foundData: false` only when no person is recorded at all (every
/// grouping empty and `settledCount == 0`); an all-settled book is a real
/// answer.
@injectable
class GetOwedOverviewTool extends AITool {
  const GetOwedOverviewTool(this._getOverview);

  final GetOverview _getOverview;

  static const String sourceUseCase = 'GetOverview';

  @override
  String get name => AIToolNames.getOwedOverview;

  @override
  Future<Either<Failure, ToolResult>> call(
    Map<String, Object?> arguments,
  ) async {
    final overview = await _getOverview();
    return overview.map((summary) {
      final noPeople = summary.isAllSettled && summary.settledCount == 0;
      return ToolResult(
        toolName: name,
        sourceUseCase: sourceUseCase,
        foundData: !noPeople,
        data: noPeople
            ? {AIToolDataKeys.reason: AIToolNoDataReasons.noPeopleRecorded}
            : {
                AIOverviewDataKeys.totalOwedToUserMinorUnits:
                    summary.totalOwedToUser.minorUnits,
                AIOverviewDataKeys.totalUserOwesMinorUnits:
                    summary.totalUserOwes.minorUnits,
                AIOverviewDataKeys.peopleTheyOweYou: [
                  for (final p in summary.peopleTheyOweYou) _person(p),
                ],
                AIOverviewDataKeys.peopleYouOweThem: [
                  for (final p in summary.peopleYouOweThem) _person(p),
                ],
                AIOverviewDataKeys.settledCount: summary.settledCount,
                ...aiToolMoneyUnits,
              },
      );
    });
  }

  static Map<String, Object?> _person(PersonSummary person) => {
    AIPersonDataKeys.personName: person.name,
    AIPersonDataKeys.netMinorUnits: person.net.minorUnits,
  };
}
