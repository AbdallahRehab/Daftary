import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../finance/domain/entities/finance_summary.dart';
import '../../../transactions/domain/entities/overview_summary.dart';

/// Everything Home needs from one load, as returned by
/// `GetDashboardSnapshot` (data-model.md "Entity: DashboardSnapshot").
///
/// The two aggregates stay as separate [Either]s rather than one combined
/// failure, which is what lets each side fail and be retried on its own
/// (FR-003). Never persisted; recomputed on every load.
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.overview,
    required this.finance,
    required this.hasAnyFinanceEntry,
  });

  /// The person-to-person balances aggregate, exactly as `GetOverview`
  /// returned it.
  final Either<Failure, OverviewSummary> overview;

  /// This month's income/expense aggregate, exactly as `GetFinanceSummary`
  /// returned it.
  final Either<Failure, FinanceSummary> finance;

  /// Whether at least one finance entry exists in any period. Only feeds
  /// [isCombinedEmpty]; never displayed. `true` when the existence check
  /// itself failed, so a transient error cannot show the first-run state
  /// to a returning user (research.md Decision 3).
  final bool hasAnyFinanceEntry;

  /// The first-run "nothing recorded yet" signal (FR-005): both aggregates
  /// loaded, zero people exist, and no finance entry has ever been recorded.
  ///
  /// `false` whenever either aggregate failed — a partial error is its own
  /// state, not an empty one.
  bool get isCombinedEmpty => overview.match(
    (_) => false,
    (summary) =>
        finance.isRight() &&
        isCombinedEmptyFor(summary, hasAnyFinanceEntry: hasAnyFinanceEntry),
  );

  /// Shared rule behind [isCombinedEmpty], exposed so a single-side retry
  /// can re-derive it without re-running the whole snapshot.
  ///
  /// People are counted from all three `GetOverview` groupings: `settledCount`
  /// covers people whose balance is zero, so this is a true "no people"
  /// check rather than merely "no outstanding balances".
  static bool isCombinedEmptyFor(
    OverviewSummary overview, {
    required bool hasAnyFinanceEntry,
  }) {
    final peopleCount =
        overview.peopleTheyOweYou.length +
        overview.peopleYouOweThem.length +
        overview.peopleRateNeeded.length +
        overview.settledCount;
    return peopleCount == 0 && !hasAnyFinanceEntry;
  }
}
