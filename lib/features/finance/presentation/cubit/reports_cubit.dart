import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/finance_entry_type.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/usecases/get_category_breakdown.dart';
import '../../domain/usecases/get_spending_trend.dart';
import 'reports_state.dart';

/// Drives the Reports screen (013 US1): the recent-months trend (FR-001)
/// and the expense breakdown for a selectable period (FR-002), both read
/// through 007's existing aggregation — nothing here computes a figure of
/// its own (FR-003).
@injectable
class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit(this._getTrend, this._getBreakdown, this._repository)
    : super(const ReportsState());

  final GetSpendingTrend _getTrend;
  final GetCategoryBreakdown _getBreakdown;

  /// Only ever used for `hasAnyEntry` — the true-empty check (FR-004),
  /// exactly as `FinanceHistoryCubit` makes it.
  final FinanceRepository _repository;

  /// The trend window, in calendar months (spec Assumptions' "reasonable
  /// rolling window"). Read by the page for the chart's subtitle so the two
  /// can never disagree.
  static const int trendMonths = 6;

  /// Bumped on every breakdown request, so a slow response for a period the
  /// user has already switched away from is dropped rather than shown.
  int _breakdownRequest = 0;

  /// Loads the existence check, the trend, and the breakdown concurrently.
  /// Any one failing is a single error state with retry (FR-005); the
  /// selected breakdown period survives a reload.
  Future<void> load() async {
    final period = state.breakdownPeriod;
    final request = ++_breakdownRequest;
    emit(ReportsState(breakdownPeriod: period));

    final (hasAnyEntry, trend, breakdown) = await (
      _repository.hasAnyEntry(),
      _getTrend(monthsBack: trendMonths),
      _getBreakdown(period.range(), type: FinanceEntryType.expense),
    ).wait;
    if (isClosed) return;

    final failure =
        hasAnyEntry.getLeft().toNullable() ??
        trend.getLeft().toNullable() ??
        breakdown.getLeft().toNullable();
    if (failure != null) {
      emit(
        state.copyWith(
          status: ReportsStatus.failure,
          errorMessage: failure.message,
        ),
      );
      return;
    }

    if (!(hasAnyEntry.toNullable() ?? false)) {
      emit(
        state.copyWith(status: ReportsStatus.empty, clearErrorMessage: true),
      );
      return;
    }

    // A period switch issued while this load was in flight owns the
    // breakdown from here on.
    final breakdownIsCurrent = request == _breakdownRequest;
    emit(
      state.copyWith(
        status: ReportsStatus.success,
        trend: trend.toNullable(),
        breakdown: breakdownIsCurrent ? breakdown.toNullable() : null,
        breakdownStatus: breakdownIsCurrent
            ? ReportsBreakdownStatus.success
            : null,
        clearErrorMessage: true,
      ),
    );
  }

  /// Re-fetches only the breakdown for [period] (spec US1 AC3) — the trend
  /// and the screen-level status are never touched. A failure here stays
  /// inside the breakdown section.
  Future<void> changeBreakdownPeriod(ReportsPeriod period) async {
    final request = ++_breakdownRequest;
    emit(
      state.copyWith(
        breakdownPeriod: period,
        breakdownStatus: ReportsBreakdownStatus.loading,
      ),
    );

    final result = await _getBreakdown(
      period.range(),
      type: FinanceEntryType.expense,
    );
    if (isClosed || request != _breakdownRequest) return;

    result.match(
      (failure) => emit(
        state.copyWith(
          breakdownStatus: ReportsBreakdownStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (items) => emit(
        state.copyWith(
          breakdown: items,
          breakdownStatus: ReportsBreakdownStatus.success,
          clearErrorMessage: true,
        ),
      ),
    );
  }

  /// The breakdown section's inline retry: the same period again.
  Future<void> retryBreakdown() => changeBreakdownPeriod(state.breakdownPeriod);
}
