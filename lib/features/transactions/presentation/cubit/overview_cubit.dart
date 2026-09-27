import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/watch_overview.dart';
import 'overview_state.dart';

/// The consolidated owed-to-me / I-owe overview (US4).
///
/// 021: a live [WatchOverview] subscription, cancelled in [close] — totals
/// change as soon as a transaction, person, rate or the primary currency
/// changes anywhere, with no reload from other screens (FR-014, FR-031).
@injectable
class OverviewCubit extends Cubit<OverviewState> {
  OverviewCubit(this._watchOverview) : super(const OverviewState());

  final WatchOverview _watchOverview;

  StreamSubscription<void>? _subscription;
  Completer<void>? _firstResult;

  /// Subscribes to the overview, replacing any earlier subscription. The
  /// returned future completes once the first result has been emitted.
  Future<void> subscribe() {
    _cancelSubscription();
    emit(state.copyWith(status: OverviewStatus.loading));
    final firstResult = _firstResult = Completer<void>();
    _subscription = _watchOverview().listen((result) {
      if (isClosed) return;
      result.match(
        (failure) => emit(
          state.copyWith(status: OverviewStatus.failure, failure: failure),
        ),
        (summary) => emit(
          state.copyWith(status: OverviewStatus.success, summary: summary),
        ),
      );
      _completeFirstResult();
    });
    return firstResult.future;
  }

  /// Retry and pull to refresh: subscribes again from scratch.
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
