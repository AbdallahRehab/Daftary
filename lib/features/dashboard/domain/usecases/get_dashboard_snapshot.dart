import 'package:injectable/injectable.dart';

import '../../../finance/domain/entities/finance_history_filter.dart';
import '../../../finance/domain/usecases/get_finance_history.dart';
import '../../../finance/domain/usecases/get_finance_summary.dart';
import '../../../transactions/domain/usecases/get_overview.dart';
import '../entities/dashboard_snapshot.dart';

/// Coordinates the two independent aggregates Home shows (FR-001/FR-002)
/// and the combined first-run empty signal (FR-005, research.md
/// Decision 3).
///
/// Depends only on other use cases, never a repository, so the numbers
/// Home shows are exactly the numbers each owning feature computes
/// (FR-016). Never throws: each side's [Either] is returned as-is so the
/// caller can treat them independently (FR-003).
@injectable
class GetDashboardSnapshot {
  const GetDashboardSnapshot(
    this._getOverview,
    this._getFinanceSummary,
    this._getFinanceHistory,
  );

  final GetOverview _getOverview;
  final GetFinanceSummary _getFinanceSummary;
  final GetFinanceHistory _getFinanceHistory;

  /// Runs all three reads concurrently — the record `.wait` is
  /// `Future.wait` with each result keeping its own type — so Home's load
  /// time is the slowest read, not the sum of them (SC-001).
  ///
  /// [period] is the finance summary's range; Home passes
  /// `DateRange.thisMonth()`.
  Future<DashboardSnapshot> call({required DateRange period}) async {
    final (overview, finance, history) = await (
      _getOverview(),
      _getFinanceSummary(period),
      // Existence check only: one row, no filter, any period. A failure
      // here degrades to "assume not empty" instead of failing the call.
      _getFinanceHistory(limit: 1, offset: 0),
    ).wait;

    return DashboardSnapshot(
      overview: overview,
      finance: finance,
      hasAnyFinanceEntry: history.match((_) => true, (rows) => rows.isNotEmpty),
    );
  }
}
