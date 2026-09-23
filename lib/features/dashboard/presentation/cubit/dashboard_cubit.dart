import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../finance/domain/entities/finance_history_filter.dart';
import '../../../finance/domain/entities/finance_summary.dart';
import '../../../finance/domain/usecases/get_finance_summary.dart';
import '../../../transactions/domain/entities/overview_summary.dart';
import '../../../transactions/domain/usecases/get_overview.dart';
import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/usecases/get_dashboard_snapshot.dart';
import 'dashboard_state.dart';
import 'load_status.dart';

/// Drives Home: the balances aggregate and this month's finance aggregate,
/// loaded together but tracked, failed, and retried independently
/// (FR-001–FR-005, FR-012; contracts/get_dashboard_snapshot.md).
///
/// Call [refresh] from anywhere that just changed a transaction or finance
/// entry so Home's totals are current when the user returns (FR-011).
@injectable
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(
    this._getDashboardSnapshot,
    this._getOverview,
    this._getFinanceSummary,
  ) : super(const DashboardState());

  final GetDashboardSnapshot _getDashboardSnapshot;
  final GetOverview _getOverview;
  final GetFinanceSummary _getFinanceSummary;

  /// The last snapshot's "any finance entry ever" answer, kept so a
  /// single-side retry can settle [DashboardState.isCombinedEmpty] without
  /// re-running the other side. `true` until known, so the first-run state
  /// is never shown on a guess.
  bool _hasAnyFinanceEntry = true;

  /// Initial load: resets to the full loading state, then fetches both
  /// aggregates in parallel.
  Future<void> load() async {
    emit(const DashboardState());
    await _loadSnapshot();
  }

  /// Pull-to-refresh (FR-012): re-fetches both aggregates exactly like
  /// [load], and recomputes `isCombinedEmpty` from the fresh snapshot.
  ///
  /// Unlike [load] it does not reset to the loading state first — whatever
  /// is on screen stays visible under the `RefreshIndicator`'s own spinner
  /// until the fresh result replaces it in one emission, so a refresh never
  /// flashes the full-screen loader. A side that fails on refresh shows
  /// its failure rather than keeping stale numbers.
  Future<void> refresh() => _loadSnapshot();

  /// Re-fetches only the balances aggregate (FR-003). The finance fields
  /// are never touched.
  Future<void> retryOverview() async {
    emit(
      state.copyWith(
        overviewStatus: LoadStatus.loading,
        clearOverviewError: true,
      ),
    );
    final result = await _getOverview();
    if (isClosed) return;
    final next = _applyOverview(state, result);
    emit(next.copyWith(isCombinedEmpty: _combinedEmpty(next)));
  }

  /// Re-fetches only this month's finance aggregate (FR-003). The balances
  /// fields are never touched.
  Future<void> retryFinance() async {
    emit(
      state.copyWith(
        financeStatus: LoadStatus.loading,
        clearFinanceError: true,
      ),
    );
    final result = await _getFinanceSummary(DateRange.thisMonth());
    if (isClosed) return;
    final next = _applyFinance(state, result);
    emit(next.copyWith(isCombinedEmpty: _combinedEmpty(next)));
  }

  Future<void> _loadSnapshot() async {
    final snapshot = await _getDashboardSnapshot(period: DateRange.thisMonth());
    if (isClosed) return;
    _hasAnyFinanceEntry = snapshot.hasAnyFinanceEntry;
    final next = _applyFinance(
      _applyOverview(state, snapshot.overview),
      snapshot.finance,
    );
    emit(next.copyWith(isCombinedEmpty: snapshot.isCombinedEmpty));
  }

  static DashboardState _applyOverview(
    DashboardState from,
    Either<Failure, OverviewSummary> result,
  ) {
    return result.match(
      (failure) => from.copyWith(
        overviewStatus: LoadStatus.failure,
        clearOverviewSummary: true,
        overviewError: failure.message,
      ),
      (summary) => from.copyWith(
        overviewStatus: LoadStatus.success,
        overviewSummary: summary,
        clearOverviewError: true,
      ),
    );
  }

  static DashboardState _applyFinance(
    DashboardState from,
    Either<Failure, FinanceSummary> result,
  ) {
    return result.match(
      (failure) => from.copyWith(
        financeStatus: LoadStatus.failure,
        clearFinanceSummary: true,
        financeError: failure.message,
      ),
      (summary) => from.copyWith(
        financeStatus: LoadStatus.success,
        financeSummary: summary,
        clearFinanceError: true,
      ),
    );
  }

  /// Settles the combined-empty flag after a single-side retry: only once
  /// both sides are loaded, from the last snapshot's existence check.
  bool _combinedEmpty(DashboardState s) {
    final overview = s.overviewSummary;
    if (s.overviewStatus != LoadStatus.success ||
        s.financeStatus != LoadStatus.success ||
        overview == null) {
      return false;
    }
    return DashboardSnapshot.isCombinedEmptyFor(
      overview,
      hasAnyFinanceEntry: _hasAnyFinanceEntry,
    );
  }
}
