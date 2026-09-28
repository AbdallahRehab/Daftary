import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/category_breakdown_item.dart';
import '../../domain/entities/finance_entry_type.dart';
import '../../domain/entities/spending_trend_point.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/usecases/watch_category_breakdown.dart';
import '../../domain/usecases/watch_spending_trend.dart';
import 'reports_state.dart';

/// Drives the Reports screen (013 US1): the recent-months trend (FR-001)
/// and the expense breakdown for a selectable period (FR-002), both read
/// through 007's existing aggregation — nothing here computes a figure of
/// its own (FR-003).
///
/// 021: the screen is live. The Cubit subscribes to the trend
/// ([WatchSpendingTrend]), the selected period's breakdown
/// ([WatchCategoryBreakdown]) and the true-empty check, so a finance entry,
/// a category, an exchange rate or the primary currency changing — here,
/// on another screen, or through a sync pull — updates the open screen with
/// no reload (FR-031). A trend or breakdown blocked by a missing rate
/// clears itself once the rate arrives. The breakdown has its own
/// subscription, so switching its period never touches the trend. All
/// subscriptions are cancelled in [close].
@injectable
class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit(this._watchTrend, this._watchBreakdown, this._repository)
    : super(const ReportsState());

  final WatchSpendingTrend _watchTrend;
  final WatchCategoryBreakdown _watchBreakdown;

  /// Only ever used for `watchHasAnyEntry` — the true-empty check (FR-004),
  /// exactly as `FinanceHistoryCubit` makes it.
  final FinanceRepository _repository;

  /// The trend window, in calendar months (spec Assumptions' "reasonable
  /// rolling window"). Read by the page for the chart's subtitle so the two
  /// can never disagree.
  static const int trendMonths = 6;

  final _screenSubscriptions = <StreamSubscription<void>>[];
  StreamSubscription<void>? _breakdownSubscription;
  Completer<void>? _firstResult;
  Completer<void>? _firstBreakdown;

  /// Bumped by every breakdown subscription, so a result for a period the
  /// user has already switched away from is dropped rather than shown.
  int _breakdownRequest = 0;

  /// Whether the screen has been shown since the last [subscribe]. Until
  /// then a failed breakdown fails the whole screen (never a half screen,
  /// FR-005); after, it stays inside the breakdown card.
  bool _shown = false;

  Either<Failure, bool>? _hasAnyEntry;
  Either<Failure, List<SpendingTrendPoint>>? _trend;
  Either<Failure, CategoryBreakdown>? _breakdown;

  /// Subscribes to the existence check, the trend, and the breakdown
  /// concurrently, from a loading state. Any one failing is a single error
  /// state with retry (FR-005); the selected breakdown period survives a
  /// resubscribe. The returned future completes once the first complete
  /// result has been emitted.
  Future<void> subscribe() {
    _cancelScreenSubscriptions();
    _shown = false;
    _hasAnyEntry = null;
    _trend = null;
    emit(ReportsState(breakdownPeriod: state.breakdownPeriod));

    final firstResult = _firstResult = Completer<void>();
    _screenSubscriptions.addAll([
      _repository.watchHasAnyEntry().listen(
        (result) => _onScreenChange(() => _hasAnyEntry = result),
      ),
      _watchTrend(
        monthsBack: trendMonths,
      ).listen((result) => _onScreenChange(() => _trend = result)),
    ]);
    unawaited(_subscribeBreakdown(state.breakdownPeriod));
    return firstResult.future;
  }

  /// Retry and pull to refresh: subscribes again from scratch, so the
  /// windows re-resolve against today.
  Future<void> resubscribe() => subscribe();

  /// Re-subscribes only the breakdown, for [period] (spec US1 AC3) — the
  /// trend and the screen-level status are never touched. A failure here
  /// stays inside the breakdown section. The returned future completes once
  /// the new period's first result has been shown (or it was superseded).
  Future<void> changeBreakdownPeriod(ReportsPeriod period) {
    emit(
      state.copyWith(
        breakdownPeriod: period,
        breakdownStatus: ReportsBreakdownStatus.loading,
      ),
    );
    return _subscribeBreakdown(period);
  }

  /// The breakdown section's inline retry: the same period again.
  Future<void> retryBreakdown() => changeBreakdownPeriod(state.breakdownPeriod);

  Future<void> _subscribeBreakdown(ReportsPeriod period) {
    _cancelBreakdownSubscription();
    _breakdown = null;
    final request = ++_breakdownRequest;
    final firstBreakdown = _firstBreakdown = Completer<void>();
    _breakdownSubscription =
        _watchBreakdown(
          // Resolved now, so "this month" is the current month whenever the
          // period is picked or the screen is refreshed.
          period.range(),
          type: FinanceEntryType.expense,
        ).listen((result) {
          if (isClosed || request != _breakdownRequest) return;
          _breakdown = result;
          if (state.isSuccess) {
            _emitBreakdown(result);
          } else {
            // The first screen emission waits for the breakdown too, and a
            // screen-level failure (e.g. a trend needing a rate) keeps its
            // own failure rather than the breakdown's.
            _emitScreen();
          }
          _complete(_firstBreakdown);
        });
    return firstBreakdown.future;
  }

  /// Records [change], then emits the screen once every part has arrived.
  void _onScreenChange(void Function() change) {
    if (isClosed) return;
    change();
    _emitScreen();
  }

  void _emitScreen() {
    final hasAnyEntry = _hasAnyEntry;
    final trend = _trend;
    final breakdown = _breakdown;
    if (hasAnyEntry == null || trend == null) return;
    if (!_shown && breakdown == null) return;

    final failure =
        hasAnyEntry.getLeft().toNullable() ??
        trend.getLeft().toNullable() ??
        (_shown ? null : breakdown?.getLeft().toNullable());
    if (failure != null) {
      emit(state.copyWith(status: ReportsStatus.failure, failure: failure));
    } else if (!(hasAnyEntry.toNullable() ?? false)) {
      emit(state.copyWith(status: ReportsStatus.empty, clearFailure: true));
    } else {
      _shown = true;
      final breakdownFailure = breakdown?.getLeft().toNullable();
      emit(
        state.copyWith(
          status: ReportsStatus.success,
          trend: trend.toNullable(),
          breakdown: breakdown?.toNullable(),
          breakdownStatus: switch (breakdown) {
            null => ReportsBreakdownStatus.loading,
            Left() => ReportsBreakdownStatus.failure,
            Right() => ReportsBreakdownStatus.success,
          },
          failure: breakdownFailure,
          clearFailure: breakdownFailure == null,
        ),
      );
    }
    _complete(_firstResult);
  }

  void _emitBreakdown(Either<Failure, CategoryBreakdown> result) {
    result.match(
      (failure) => emit(
        state.copyWith(
          breakdownStatus: ReportsBreakdownStatus.failure,
          failure: failure,
        ),
      ),
      (breakdown) => emit(
        state.copyWith(
          breakdown: breakdown,
          breakdownStatus: ReportsBreakdownStatus.success,
          clearFailure: true,
        ),
      ),
    );
  }

  static void _complete(Completer<void>? completer) {
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  void _cancelScreenSubscriptions() {
    for (final subscription in _screenSubscriptions) {
      subscription.cancel();
    }
    _screenSubscriptions.clear();
    // A superseded subscription will never deliver; release its waiter.
    _complete(_firstResult);
  }

  void _cancelBreakdownSubscription() {
    _breakdownSubscription?.cancel();
    _breakdownSubscription = null;
    _complete(_firstBreakdown);
  }

  @override
  Future<void> close() {
    _cancelScreenSubscriptions();
    _cancelBreakdownSubscription();
    return super.close();
  }
}
