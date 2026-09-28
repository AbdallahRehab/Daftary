import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/delete_scan.dart';
import '../../domain/usecases/get_scan_detail.dart';
import 'scan_detail_state.dart';

/// Drives one past scan's detail screen (FR-018): its original image, its
/// candidate entries as they ended up, and the transactions it produced.
@injectable
class ScanDetailCubit extends Cubit<ScanDetailState> {
  ScanDetailCubit(this._getScanDetail, this._deleteScan)
    : super(const ScanDetailState());

  final GetScanDetail _getScanDetail;
  final DeleteScan _deleteScan;

  /// The scan currently loaded, remembered so [delete] needs no argument
  /// and can never be pointed at a different scan than the one on screen.
  String? _scanId;

  Future<void> load(String scanId) async {
    _scanId = scanId;
    emit(state.copyWith(status: ScanDetailStatus.loading));

    final result = await _getScanDetail(scanId);
    if (isClosed) return;

    emit(
      result.match(
        (failure) =>
            state.copyWith(status: ScanDetailStatus.failure, failure: failure),
        (detail) => state.copyWith(
          status: ScanDetailStatus.success,
          detail: detail,
          clearFailure: true,
        ),
      ),
    );
  }

  /// Deletes the loaded scan, its entries, and its image file (FR-023).
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

    emit(
      result.match(
        (failure) =>
            state.copyWith(status: ScanDetailStatus.failure, failure: failure),
        (_) => state.copyWith(
          status: ScanDetailStatus.deleted,
          clearFailure: true,
        ),
      ),
    );
  }
}
