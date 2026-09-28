import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/delete_scan.dart';
import '../../domain/usecases/watch_scan_detail.dart';
import 'scan_detail_state.dart';

/// Drives one past scan's detail screen (FR-018): its original image, its
/// candidate entries as they ended up, and the transactions it produced.
///
/// 021: the detail is a live [WatchScanDetail] subscription, cancelled in
/// [close], so a produced transaction edited or deleted from its person's
/// screen — or through sync — updates this page with no reload (FR-031).
@injectable
class ScanDetailCubit extends Cubit<ScanDetailState> {
  ScanDetailCubit(this._watchScanDetail, this._deleteScan)
    : super(const ScanDetailState());

  final WatchScanDetail _watchScanDetail;
  final DeleteScan _deleteScan;

  /// The scan currently shown, remembered so [delete] needs no argument
  /// and can never be pointed at a different scan than the one on screen.
  String? _scanId;

  StreamSubscription<void>? _subscription;
  Completer<void>? _firstResult;

  /// Subscribes to [scanId], replacing any earlier subscription. The
  /// returned future completes once the first result has been emitted.
  Future<void> subscribe(String scanId) {
    _cancelSubscription();
    _scanId = scanId;
    emit(state.copyWith(status: ScanDetailStatus.loading));

    final firstResult = _firstResult = Completer<void>();
    _subscription = _watchScanDetail(scanId).listen((result) {
      if (isClosed || state.isDeleted) return;
      emit(
        result.match(
          (failure) => state.copyWith(
            status: ScanDetailStatus.failure,
            failure: failure,
          ),
          (detail) => state.copyWith(
            status: ScanDetailStatus.success,
            detail: detail,
            clearFailure: true,
          ),
        ),
      );
      _completeFirstResult();
    });
    return firstResult.future;
  }

  /// Retry: subscribes again, from scratch, to the displayed scan.
  Future<void> resubscribe() {
    final scanId = _scanId;
    if (scanId == null) return Future.value();
    return subscribe(scanId);
  }

  /// Deletes the shown scan, its entries, and its image file (FR-023).
  ///
  /// The transactions listed on this very screen survive: they are real
  /// financial records the user confirmed, and only their "view the
  /// original scan" link goes away. The confirmation dialog the page shows
  /// before calling this says so explicitly — the distinction is the whole
  /// reason the action is safe to offer.
  Future<void> delete() async {
    final scanId = _scanId;
    if (scanId == null) return;

    final result = await _deleteScan(scanId);
    if (isClosed) return;

    result.match(
      (failure) => emit(
        state.copyWith(status: ScanDetailStatus.failure, failure: failure),
      ),
      (_) {
        // The deleted scan must not be re-read into a "not found" failure.
        _cancelSubscription();
        emit(
          state.copyWith(status: ScanDetailStatus.deleted, clearFailure: true),
        );
      },
    );
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
