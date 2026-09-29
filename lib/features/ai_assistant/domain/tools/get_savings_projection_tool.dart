import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../savings/domain/entities/savings_failures.dart';
import '../../../savings/domain/entities/savings_goal.dart';
import '../../../savings/domain/entities/what_if_mode.dart';
import '../../../savings/domain/entities/what_if_result.dart';
import '../../../savings/domain/usecases/calculate_what_if_completion_date.dart';
import '../../../savings/domain/usecases/calculate_what_if_monthly_contribution.dart';
import '../../../savings/domain/usecases/get_savings_overview.dart';
import '../entities/tool_result.dart';
import 'ai_tool.dart';
import 'get_savings_goal_status_tool.dart';
import 'tool_arguments.dart';
import 'tool_catalog.dart';

/// `getSavingsProjection` — wraps 011's read-only what-if calculators:
/// [CalculateWhatIfMonthlyContribution] ("what if I save X a month?",
/// FR-013) or, given a date instead, [CalculateWhatIfCompletionDate]
/// ("what do I need to save to finish by Y?", FR-014).
///
/// The model-supplied hypothetical is passed straight through and the
/// `WhatIfResult` copied back unchanged, in the goal's own currency — the
/// tool never runs projection math itself. Both use cases are read-only by
/// construction; `ApplyWhatIfScenario`, the one that writes, is never
/// reachable from here (spec 014 FR-010).
///
/// [GetSavingsOverview] only resolves which goal `goalName` means (and its
/// currency). `foundData: false` when the name matches no goal / more than
/// one, or the goal is already achieved (011 FR-016: nothing to plan).
/// A non-positive amount or a date on or before today is a
/// [ValidationFailure] the model can correct.
@injectable
class GetSavingsProjectionTool extends AITool {
  const GetSavingsProjectionTool(
    this._getSavingsOverview,
    this._whatIfMonthlyContribution,
    this._whatIfCompletionDate,
  );

  final GetSavingsOverview _getSavingsOverview;
  final CalculateWhatIfMonthlyContribution _whatIfMonthlyContribution;
  final CalculateWhatIfCompletionDate _whatIfCompletionDate;

  static const String monthlyContributionSourceUseCase =
      'CalculateWhatIfMonthlyContribution';
  static const String completionDateSourceUseCase =
      'CalculateWhatIfCompletionDate';

  @override
  String get name => AIToolNames.getSavingsProjection;

  @override
  Future<Either<Failure, ToolResult>> call(
    Map<String, Object?> arguments,
  ) async {
    // Every argument is validated before anything is read.
    final String goalName;
    final int? monthly;
    final DateTime? date;
    switch (AIToolArgumentReader.requiredString(
      arguments,
      AIToolArgs.goalName,
    )) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final value):
        goalName = value;
    }
    switch (AIToolArgumentReader.optionalInt(
      arguments,
      AIToolArgs.hypotheticalMonthlyContributionMinorUnits,
    )) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final value):
        monthly = value;
    }
    switch (AIToolArgumentReader.optionalDate(
      arguments,
      AIToolArgs.hypotheticalTargetDate,
    )) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final value):
        date = value;
    }
    if ((monthly == null) == (date == null)) {
      return const Left(
        ValidationFailure(
          'Give exactly one of '
          '"${AIToolArgs.hypotheticalMonthlyContributionMinorUnits}" or '
          '"${AIToolArgs.hypotheticalTargetDate}"',
        ),
      );
    }
    final mode = monthly != null
        ? WhatIfMode.monthlyContribution
        : WhatIfMode.targetDate;
    final sourceUseCase = switch (mode) {
      WhatIfMode.monthlyContribution => monthlyContributionSourceUseCase,
      WhatIfMode.targetDate => completionDateSourceUseCase,
    };

    final SavingsGoal goal;
    switch (await resolveAISavingsGoal(_getSavingsOverview, goalName)) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: Left(value: final noData)):
        return Right(_result(sourceUseCase, foundData: false, noData));
      case Right(value: Right(value: final matched)):
        goal = matched;
    }

    final outcome = monthly != null
        ? await _whatIfMonthlyContribution(
            goalId: goal.id,
            hypotheticalMonthlyContributionMinorUnits: monthly,
          )
        : await _whatIfCompletionDate(
            goalId: goal.id,
            hypotheticalTargetDate: date!,
          );

    return switch (outcome) {
      Left(value: GoalAlreadyAchievedFailure()) => Right(
        _result(sourceUseCase, foundData: false, {
          AISavingsDataKeys.goalName: goal.name,
          AIToolDataKeys.reason: AIToolNoDataReasons.goalAlreadyAchieved,
        }),
      ),
      Left(value: GoalNotFoundFailure()) => Right(
        _result(sourceUseCase, foundData: false, {
          AIToolArgs.goalName: goalName,
          AIToolDataKeys.reason: AIToolNoDataReasons.goalNotFound,
        }),
      ),
      // An argument the model can correct (a date on or before today).
      Left(value: InvalidTargetDateFailure(:final message)) => Left(
        ValidationFailure('"${AIToolArgs.hypotheticalTargetDate}": $message'),
      ),
      Left(value: final failure) => Left(failure),
      Right(value: final result) => Right(
        _result(sourceUseCase, foundData: true, {
          AISavingsDataKeys.goalName: goal.name,
          AISavingsDataKeys.mode: mode.name,
          ..._whatIfData(mode, result),
          ...aiToolMoneyUnits(goal.currency),
        }),
      ),
    };
  }

  /// [result]'s fields, copied — named for which one was the input.
  static Map<String, Object?> _whatIfData(
    WhatIfMode mode,
    WhatIfResult result,
  ) {
    final date = result.hypotheticalTargetDate;
    final formattedDate = date == null ? null : formatAIDate(date);
    return switch (mode) {
      WhatIfMode.monthlyContribution => {
        AISavingsDataKeys.hypotheticalMonthlyContributionMinorUnits:
            ?result.hypotheticalMonthlyContributionMinorUnits,
        AISavingsDataKeys.projectedMonthsToCompletion: ?result.estimatedMonths,
        AISavingsDataKeys.projectedCompletionDate: ?formattedDate,
      },
      WhatIfMode.targetDate => {
        AISavingsDataKeys.hypotheticalTargetDate: ?formattedDate,
        AISavingsDataKeys.requiredMonthlyContributionMinorUnits:
            ?result.hypotheticalMonthlyContributionMinorUnits,
        AISavingsDataKeys.projectedMonthsToCompletion: ?result.estimatedMonths,
      },
    };
  }

  ToolResult _result(
    String sourceUseCase,
    Map<String, Object?> data, {
    required bool foundData,
  }) => ToolResult(
    toolName: name,
    sourceUseCase: sourceUseCase,
    foundData: foundData,
    data: data,
  );
}
