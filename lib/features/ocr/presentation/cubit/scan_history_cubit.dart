import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/delete_scan.dart';
import '../../domain/usecases/watch_scan_history.dart';
import 'scan_history_state.dart';

/// Drives the past-scans list (FR-018): every retained scan, newest first,
/// with the delete action that also removes its image from the device
/// (FR-023).
///
/// 021: the list is a live [WatchScanHistory] subscription, cancelled in
/// [close], so a scan finished, abandoned or deleted on another screen —
/// the detail screen included — shows here with no reload (FR-031).
@injectable
class ScanHistoryCubit extends Cubit<ScanHistoryState> {
  ScanHistoryCubit(this._watchScanHistory, this._deleteScan)
    : super(const ScanHistoryState());

  final WatchScanHistory _watchScanHistory;
  final DeleteScan _deleteScan;

  StreamSubscription<void>? _subscription;
  Completer<void>? _firstResult;

  /// Subscribes to the history, replacing any earlier subscription. The
  /// returned future completes once the first result has been emitted.
  Future<void> subscribe() {
    _cancelSubscription();
    emit(state.copyWith(status: ScanHistoryStatus.loading));

    final firstResult = _firstResult = Completer<void>();
    _subscription = _watchScanHistory().listen((result) {
      if (isClosed) return;
      emit(
        result.match(
          (failure) => state.copyWith(
            status: ScanHistoryStatus.failure,
            failure: failure,
          ),
          (scans) => state.copyWith(
            status: ScanHistoryStatus.success,
            scans: scans,
            clearFailure: true,
          ),
        ),
      );
      _completeFirstResult();
    });
    return firstResult.future;
  }

  /// Retry and pull to refresh: subscribes again from scratch.
  Future<void> resubscribe() => subscribe();

  /// Deletes one scan and its source image.
  ///
  /// The row is not removed locally: deletion is a repository-side cascade
  /// (scan + entries + image file), so the authoritative answer to "what is
  /// left" comes from the live query the list is built from. It notably
  /// does **not** delete the transactions the scan produced — those are
  /// real, user-confirmed financial records by now (data-model.md
  /// Relationships, FR-023).
  Future<void> deleteScan(String scanId) async {
    final result = await _deleteScan(scanId);
    if (isClosed) return;

    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(state.copyWith(status: ScanHistoryStatus.failure, failure: failure));
    }
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
