import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/watch_savings_overview.dart';
import 'savings_overview_state.dart';

/// Drives the goals overview (FR-019/FR-023): every active goal with its
/// progress, and the combined total in the primary currency.
///
/// 021: a live [WatchSavingsOverview] subscription, cancelled in [close] —
/// a goal created, an entry logged, a goal archived or a rate set (here or
/// through sync) reaches the open page with no reload. Archiving and
/// deleting go through `SavingsGoalActionsCubit`; this cubit only reads.
@injectable
class SavingsOverviewCubit extends Cubit<SavingsOverviewState> {
  SavingsOverviewCubit(this._watchSavingsOverview)
    : super(const SavingsOverviewState());

  final WatchSavingsOverview _watchSavingsOverview;

  StreamSubscription<void>? _subscription;
  Completer<void>? _firstResult;

  /// Subscribes to the active overview, replacing any earlier
  /// subscription. Completes once the first result has been emitted.
  Future<void> subscribe() {
    _cancelSubscription();
    emit(state.copyWith(status: SavingsOverviewStatus.loading));
    final firstResult = _firstResult = Completer<void>();
    _subscription = _watchSavingsOverview().listen((result) {
      if (isClosed) return;
      result.match(
        (failure) => emit(
          state.copyWith(
            status: SavingsOverviewStatus.failure,
            failure: failure,
          ),
        ),
        (overview) => emit(
          state.copyWith(
            status: SavingsOverviewStatus.success,
            overview: overview,
            clearFailure: true,
          ),
        ),
      );
      _completeFirstResult();
    });
    return firstResult.future;
  }

  /// Retry / pull-to-refresh: subscribes again from scratch.
  Future<void> resubscribe() => subscribe();

  void _completeFirstResult() {
    final firstResult = _firstResult;
    if (firstResult != null && !firstResult.isCompleted) {
      firstResult.complete();
    }
  }

  void _cancelSubscription() {
    _subscription?.cancel();
    _subscription = null;
    _completeFirstResult();
  }

  @override
  Future<void> close() {
    _cancelSubscription();
    return super.close();
  }
}
