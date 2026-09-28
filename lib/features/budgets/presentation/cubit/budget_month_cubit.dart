import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/watch_budget_for_month.dart';
import 'budget_month_state.dart';

/// Drives the budget month screen (FR-005–FR-009, FR-018).
///
/// Holds no figures of its own: every result is the whole month re-derived
/// by the repository from 007's live expense data.
///
/// 021: the screen is live. The Cubit subscribes to [WatchBudgetForMonth]
/// for the month on screen, so an expense recorded, a budget edited or
/// copied, or an exchange rate set — on another screen or through sync —
/// updates it with no reload (FR-031, US2 scenario 4). The subscription is
/// replaced when the month changes and cancelled in [close].
@injectable
class BudgetMonthCubit extends Cubit<BudgetMonthState> {
  BudgetMonthCubit(this._watchBudgetForMonth)
    : super(const BudgetMonthState(month: ''));

  final WatchBudgetForMonth _watchBudgetForMonth;

  StreamSubscription<void>? _subscription;

  /// Completes on the first result of the current subscription, so pull to
  /// refresh (and tests) can await it.
  Completer<void>? _firstResult;

  /// Subscribes to [month] (`'YYYY-MM'`) from scratch, replacing any
  /// earlier subscription. The returned future completes once the first
  /// result has been emitted.
  Future<void> subscribe(String month) {
    emit(BudgetMonthState(month: month));
    return _subscribe();
  }

  /// Switches the screen to another month (FR-013) — what a month
  /// navigator calls. A no-op for the month already on screen.
  Future<void> monthChanged(String month) {
    if (month == state.month && !state.isFailure) return Future.value();
    return subscribe(month);
  }

  /// Retry and pull to refresh: subscribes again to the month on screen,
  /// keeping what is shown until the fresh result arrives.
  Future<void> resubscribe() {
    emit(state.copyWith(status: BudgetMonthStatus.loading));
    return _subscribe();
  }

  Future<void> _subscribe() {
    _cancelSubscription();
    final month = state.month;
    final firstResult = _firstResult = Completer<void>();
    _subscription = _watchBudgetForMonth(month).listen((result) {
      if (isClosed) return;
      result.match(
        // Keeps the last good detail, so a failed re-read never blanks a
        // screen that was showing figures.
        (failure) => emit(
          state.copyWith(status: BudgetMonthStatus.failure, failure: failure),
        ),
        (detail) => emit(
          BudgetMonthState(
            month: month,
            status: BudgetMonthStatus.success,
            detail: detail,
          ),
        ),
      );
      _completeFirstResult();
    });
    return firstResult.future;
  }

  void _completeFirstResult() {
    final firstResult = _firstResult;
    if (firstResult != null && !firstResult.isCompleted) {
      firstResult.complete();
    }
  }

  void _cancelSubscription() {
    _subscription?.cancel();
    _subscription = null;
    // A superseded subscription will never deliver; release its waiter.
    _completeFirstResult();
  }

  @override
  Future<void> close() {
    _cancelSubscription();
    return super.close();
  }
}
