import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../finance/domain/entities/finance_entry.dart';
import '../../../finance/domain/entities/finance_history_filter.dart';
import '../../../finance/domain/entities/finance_summary.dart';
import '../../../finance/domain/usecases/watch_finance_history.dart';
import '../../../finance/domain/usecases/watch_finance_summary.dart';
import '../../../transactions/domain/entities/overview_summary.dart';
import '../../../transactions/domain/usecases/watch_overview.dart';
import '../../domain/entities/dashboard_snapshot.dart';
import 'dashboard_state.dart';
import 'load_status.dart';

/// Drives Home: the balances aggregate and this month's finance aggregate,
/// tracked, failed, and retried independently (FR-001–FR-005, FR-012;
/// contracts/get_dashboard_snapshot.md).
///
/// 021: every part is a live subscription — the overview, this month's
/// finance summary and the "any finance entry at all" check — so a change
/// anywhere (another screen, a rate, the primary currency, or a sync pull)
/// updates Home with no reload (FR-011, 021 FR-031). All subscriptions are
/// cancelled in [close].
@injectable
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(
    this._watchOverview,
    this._watchFinanceSummary,
    this._watchFinanceHistory,
  ) : super(const DashboardState());

  final WatchOverview _watchOverview;
  final WatchFinanceSummary _watchFinanceSummary;
  final WatchFinanceHistory _watchFinanceHistory;

  StreamSubscription<void>? _overviewSubscription;
  StreamSubscription<void>? _financeSubscription;
  StreamSubscription<void>? _historySubscription;

  /// Assumed until the existence check answers, and kept on a failed check:
  /// wrongly showing the first-run state would hide real data (FR-012).
  bool _hasAnyFinanceEntry = true;

  /// Subscribes to everything Home shows, from a fully loading state.
  Future<void> load() async {
    emit(const DashboardState());
    _subscribeOverview();
    _subscribeFinance();
    _subscribeHistory();
  }

  /// Pull to refresh: subscribes again without clearing what is shown.
  Future<void> refresh() async {
    _subscribeOverview();
    _subscribeFinance();
    _subscribeHistory();
  }

  Future<void> retryOverview() async {
    emit(
      state.copyWith(
        overviewStatus: LoadStatus.loading,
        clearOverviewError: true,
      ),
    );
    _subscribeOverview();
  }

  Future<void> retryFinance() async {
    emit(
      state.copyWith(
        financeStatus: LoadStatus.loading,
        clearFinanceError: true,
      ),
    );
    _subscribeFinance();
  }

  void _subscribeOverview() {
    _overviewSubscription?.cancel();
    _overviewSubscription = _watchOverview().listen((result) {
      if (isClosed) return;
      _emitCombined(_applyOverview(state, result));
    });
  }

  void _subscribeFinance() {
    _financeSubscription?.cancel();
    _financeSubscription = _watchFinanceSummary(DateRange.thisMonth()).listen((
      result,
    ) {
      if (isClosed) return;
      _emitCombined(_applyFinance(state, result));
    });
  }

  void _subscribeHistory() {
    _historySubscription?.cancel();
    // Existence check only: one row, no filter, any period.
    _historySubscription = _watchFinanceHistory(limit: 1).listen((
      Either<Failure, List<FinanceEntry>> result,
    ) {
      if (isClosed) return;
      _hasAnyFinanceEntry = result.match(
        (_) => true,
        (rows) => rows.isNotEmpty,
      );
      _emitCombined(state);
    });
  }

  void _emitCombined(DashboardState next) {
    emit(next.copyWith(isCombinedEmpty: _combinedEmpty(next)));
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

  @override
  Future<void> close() {
    _overviewSubscription?.cancel();
    _financeSubscription?.cancel();
    _historySubscription?.cancel();
    return super.close();
  }
}
