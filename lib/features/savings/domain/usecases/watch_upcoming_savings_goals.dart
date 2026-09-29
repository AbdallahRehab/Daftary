import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/savings_overview.dart';
import '../repositories/savings_repository.dart';

/// What Home's Upcoming section shows (012 FR-010, 011 FR-031, research.md
/// Decision 12): the active goals that still have a target date to reach —
/// not achieved, target date set — soonest target date first, at most
/// [defaultLimit].
///
/// A read-only view of the live savings overview: each line is the
/// repository's own, so Home's figures are exactly the goal page's. A line
/// blocked on a primary-currency rate is still listed, since only its
/// own-currency progress is shown. An empty list means there is nothing
/// real to show, and Home keeps its honest empty state.
@injectable
class WatchUpcomingSavingsGoals {
  const WatchUpcomingSavingsGoals(this._repository);

  final SavingsRepository _repository;

  static const int defaultLimit = 3;

  Stream<Either<Failure, List<GoalOverviewLine>>> call({
    int limit = defaultLimit,
  }) => _repository.watchSavingsOverview().map(
    (result) => result.map((overview) => upcoming(overview, limit: limit)),
  );

  /// The selection rule, exposed for tests and for a one-shot read.
  static List<GoalOverviewLine> upcoming(
    SavingsOverview overview, {
    int limit = defaultLimit,
  }) {
    final lines = [
      for (final line in overview.goals)
        if (!line.goal.isArchived &&
            !line.goal.isDeleted &&
            !line.progress.isAchieved &&
            line.goal.targetDate != null)
          line,
    ]..sort(_soonestFirst);
    return lines.take(limit).toList(growable: false);
  }

  static int _soonestFirst(GoalOverviewLine a, GoalOverviewLine b) {
    final byDate = a.goal.targetDate!.compareTo(b.goal.targetDate!);
    if (byDate != 0) return byDate;
    final byCreated = a.goal.createdAt.compareTo(b.goal.createdAt);
    return byCreated != 0 ? byCreated : a.goal.id.compareTo(b.goal.id);
  }
}
