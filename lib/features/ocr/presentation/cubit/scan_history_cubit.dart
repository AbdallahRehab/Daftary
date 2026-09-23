import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/delete_scan.dart';
import '../../domain/usecases/get_scan_history.dart';
import 'scan_history_state.dart';

/// Drives the past-scans list (FR-018): every retained scan, newest first,
/// with the delete action that also removes its image from the device
/// (FR-023).
@injectable
class ScanHistoryCubit extends Cubit<ScanHistoryState> {
  ScanHistoryCubit(this._getScanHistory, this._deleteScan)
    : super(const ScanHistoryState());

  final GetScanHistory _getScanHistory;
  final DeleteScan _deleteScan;

  Future<void> load() async {
    emit(state.copyWith(status: ScanHistoryStatus.loading));

    final result = await _getScanHistory();
    if (isClosed) return;

    emit(
      result.match(
        (failure) =>
            state.copyWith(status: ScanHistoryStatus.failure, failure: failure),
        (scans) => state.copyWith(
          status: ScanHistoryStatus.success,
          scans: scans,
          clearFailure: true,
        ),
      ),
    );
  }

  /// Deletes one scan and its source image, then re-reads the list.
  ///
  /// Re-reading rather than removing the row locally: deletion is a
  /// repository-side cascade (scan + entries + image file), so the
  /// authoritative answer to "what is left" comes from the same query the
  /// list was built from. It notably does **not** delete the transactions
  /// the scan produced — those are real, user-confirmed financial records
  /// by now (data-model.md Relationships, FR-023).
  Future<void> deleteScan(String scanId) async {
    final result = await _deleteScan(scanId);
    if (isClosed) return;

    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(state.copyWith(status: ScanHistoryStatus.failure, failure: failure));
      return;
    }
    await load();
  }
}
