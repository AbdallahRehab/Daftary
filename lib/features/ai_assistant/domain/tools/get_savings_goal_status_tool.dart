import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../savings/domain/entities/goal_progress.dart';
import '../../../savings/domain/entities/savings_failures.dart';
import '../../../savings/domain/entities/savings_goal.dart';
import '../../../savings/domain/entities/savings_overview.dart';
import '../../../savings/domain/usecases/get_goal_detail.dart';
import '../../../savings/domain/usecases/get_savings_overview.dart';
import '../entities/tool_result.dart';
import 'ai_tool.dart';
import 'tool_arguments.dart';
import 'tool_catalog.dart';

/// Keys of a `getSavingsGoalStatus` / `getSavingsProjection` result.
abstract final class AISavingsDataKeys {
  /// A single named goal.
  static const String goal = 'goal';

  /// Every active goal (unnamed request), in 011's overview order.
  static const String goals = 'goals';
  static const String goalName = 'goalName';
  static const String targetMinorUnits = 'targetMinorUnits';

  /// `GoalProgress.currentAmountMinorUnits`: Σ contributions − Σ
  /// withdrawals, as 011 derives it.
  static const String currentMinorUnits = 'currentMinorUnits';
  static const String remainingMinorUnits = 'remainingMinorUnits';

  /// `GoalProgress.percentageProgress` (0..100, display only).
  static const String percentProgress = 'percentProgress';
  static const String isAchieved = 'isAchieved';
  static const String isArchived = 'isArchived';

  /// The goal's own planned monthly contribution, when set.
  static const String monthlyContributionMinorUnits =
      'monthlyContributionMinorUnits';

  /// The goal's own target date (`YYYY-MM-DD`), when set.
  static const String targetDate = 'targetDate';

  /// `EstimatedCompletion` figures, each present only when 011 computed it.
  static const String estimatedMonthsToCompletion =
      'estimatedMonthsToCompletion';
  static const String estimatedCompletionDate = 'estimatedCompletionDate';
  static const String requiredMonthlyContributionMinorUnits =
      'requiredMonthlyContributionMinorUnits';
  static const String shortfallMonths = 'shortfallMonths';

  /// `SavingsOverview.totalSavedMinorUnits`, in the primary currency (the
  /// result's top-level `currency`), exactly as 011's overview shows it.
  static const String totalSavedMinorUnits = 'totalSavedMinorUnits';

  /// `SavingsOverview.isIncomplete`: the total leaves out the goals marked
  /// [excludedFromTotal], whose conversion needs a rate for a currency in
  /// `missingRatesFor` (018 FR-009) — they are never converted by guess.
  static const String isTotalIncomplete = 'isTotalIncomplete';

  /// `GoalOverviewLine.isBlocked`: this goal is not in the total.
  static const String excludedFromTotal = 'excludedFromTotal';

  /// `getSavingsProjection`: the `WhatIfMode` name the figures answer.
  static const String mode = 'mode';
  static const String hypotheticalMonthlyContributionMinorUnits =
      AIToolArgs.hypotheticalMonthlyContributionMinorUnits;
  static const String hypotheticalTargetDate =
      AIToolArgs.hypotheticalTargetDate;

  /// `WhatIfResult.estimatedMonths`.
  static const String projectedMonthsToCompletion =
      'projectedMonthsToCompletion';

  /// `WhatIfResult.hypotheticalTargetDate` in monthly-contribution mode.
  static const String projectedCompletionDate = 'projectedCompletionDate';
}

/// The outcome of resolving a model-supplied goal name against 011's own
/// goal list: either the goal, or the `foundData: false` data to report.
typedef AISavingsGoalLookup = Either<Map<String, Object?>, SavingsGoal>;

/// Resolves [goalName] through 011's [GetSavingsOverview] (archived goals
/// included — "how is my old car fund doing?" is still answerable), with
/// the same never-guess name matching every tool uses.
///
/// Right(goal) on an unambiguous match; Left(data) with a
/// [AIToolNoDataReasons] value otherwise. A use-case failure is returned
/// as the outer `Left`.
Future<Either<Failure, AISavingsGoalLookup>> resolveAISavingsGoal(
  GetSavingsOverview getSavingsOverview,
  String goalName,
) async {
  final List<GoalOverviewLine> lines;
  switch (await getSavingsOverview(includeArchived: true)) {
    case Left(value: final failure):
      return Left(failure);
    case Right(value: final overview):
      lines = overview.goals;
  }
  if (lines.isEmpty) {
    return Right(
      Left({
        AIToolArgs.goalName: goalName,
        AIToolDataKeys.reason: AIToolNoDataReasons.noSavingsGoals,
      }),
    );
  }
  return Right(switch (matchByName<GoalOverviewLine>(
    goalName,
    lines,
    (line) => line.goal.name,
  )) {
    AINameNotFound() => Left({
      AIToolArgs.goalName: goalName,
      AIToolDataKeys.reason: AIToolNoDataReasons.goalNotFound,
    }),
    AINameAmbiguous(:final candidateNames) => Left({
      AIToolArgs.goalName: goalName,
      AIToolDataKeys.reason: AIToolNoDataReasons.ambiguousGoal,
      AIToolDataKeys.candidates: candidateNames,
    }),
    AINameMatched(item: final line) => Right(line.goal),
  });
}

/// `getSavingsGoalStatus` — wraps [GetGoalDetail] for a named goal and
/// [GetSavingsOverview] for "all my goals" (011, research.md Decision 13).
///
/// Every figure is copied from 011's own [GoalProgress] getters and its
/// `SavingsCalculator`-derived `EstimatedCompletion`; the tool computes
/// nothing. Each goal's figures are in its own currency (011 FR-027), so
/// every goal carries its own `currency`; only the overview total is in
/// the primary currency (FR-019).
///
/// `foundData: false` when the user has no (active) goal, or the name
/// matches none / more than one. 018 FR-009: when some goal cannot be
/// converted for the total, the total is 011's own incomplete total,
/// flagged `isTotalIncomplete` with the missing rates and the excluded
/// goals marked — never a guessed conversion.
@injectable
class GetSavingsGoalStatusTool extends AITool {
  const GetSavingsGoalStatusTool(this._getGoalDetail, this._getSavingsOverview);

  final GetGoalDetail _getGoalDetail;
  final GetSavingsOverview _getSavingsOverview;

  static const String detailSourceUseCase = 'GetGoalDetail';
  static const String overviewSourceUseCase = 'GetSavingsOverview';

  @override
  String get name => AIToolNames.getSavingsGoalStatus;

  @override
  Future<Either<Failure, ToolResult>> call(
    Map<String, Object?> arguments,
  ) async {
    final String? requested;
    switch (AIToolArgumentReader.optionalString(
      arguments,
      AIToolArgs.goalName,
    )) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final value):
        requested = value;
    }
    return requested == null ? _overview() : _named(requested);
  }

  Future<Either<Failure, ToolResult>> _overview() async {
    final overview = await _getSavingsOverview();
    return overview.map((o) {
      if (o.isEmpty) {
        return _result(overviewSourceUseCase, foundData: false, {
          AIToolDataKeys.reason: AIToolNoDataReasons.noSavingsGoals,
        });
      }
      return _result(overviewSourceUseCase, foundData: true, {
        AISavingsDataKeys.goals: [
          for (final line in o.goals)
            {
              ...goalData(line.goal, line.progress),
              if (line.isBlocked) AISavingsDataKeys.excludedFromTotal: true,
            },
        ],
        AISavingsDataKeys.totalSavedMinorUnits: o.totalSavedMinorUnits,
        ...aiToolMoneyUnits(o.primaryCurrency),
        if (o.isIncomplete) ...{
          AISavingsDataKeys.isTotalIncomplete: true,
          AIToolDataKeys.missingRatesFor: [
            for (final c in o.missingRatesFor) c.code,
          ],
        },
      });
    });
  }

  Future<Either<Failure, ToolResult>> _named(String goalName) async {
    final SavingsGoal goal;
    switch (await resolveAISavingsGoal(_getSavingsOverview, goalName)) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: Left(value: final noData)):
        return Right(_result(detailSourceUseCase, foundData: false, noData));
      case Right(value: Right(value: final matched)):
        goal = matched;
    }
    return switch (await _getGoalDetail(goal.id)) {
      // Deleted between the list and the read: genuinely not there.
      Left(value: GoalNotFoundFailure()) => Right(
        _result(detailSourceUseCase, foundData: false, {
          AIToolArgs.goalName: goalName,
          AIToolDataKeys.reason: AIToolNoDataReasons.goalNotFound,
        }),
      ),
      Left(value: final failure) => Left(failure),
      Right(value: final detail) => Right(
        _result(detailSourceUseCase, foundData: true, {
          AISavingsDataKeys.goal: {
            ...goalData(detail.goal, detail.progress),
            AISavingsDataKeys.isArchived: detail.goal.isArchived,
          },
        }),
      ),
    };
  }

  /// One goal's figures, each copied from 011 — in the goal's currency.
  static Map<String, Object?> goalData(
    SavingsGoal goal,
    GoalProgress progress,
  ) {
    final estimate = progress.estimatedCompletion;
    final estimatedDate = estimate?.estimatedDate;
    final targetDate = goal.targetDate;
    return {
      AISavingsDataKeys.goalName: goal.name,
      ...aiToolMoneyUnits(progress.currency),
      AISavingsDataKeys.targetMinorUnits: progress.targetAmountMinorUnits,
      AISavingsDataKeys.currentMinorUnits: progress.currentAmountMinorUnits,
      AISavingsDataKeys.remainingMinorUnits: progress.remainingMinorUnits,
      AISavingsDataKeys.percentProgress: progress.percentageProgress,
      AISavingsDataKeys.isAchieved: progress.isAchieved,
      AISavingsDataKeys.monthlyContributionMinorUnits:
          ?goal.monthlyContributionMinorUnits,
      if (targetDate != null)
        AISavingsDataKeys.targetDate: formatAIDate(targetDate),
      AISavingsDataKeys.estimatedMonthsToCompletion: ?estimate?.estimatedMonths,
      if (estimatedDate != null)
        AISavingsDataKeys.estimatedCompletionDate: formatAIDate(estimatedDate),
      AISavingsDataKeys.requiredMonthlyContributionMinorUnits:
          ?estimate?.requiredMonthlyContributionMinorUnits,
      AISavingsDataKeys.shortfallMonths: ?estimate?.shortfallMonths,
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
