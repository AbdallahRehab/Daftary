import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/acknowledge_sync_notice.dart';
import '../../domain/usecases/watch_sync_status.dart';
import 'sync_notice_state.dart';

/// 021 US6: the one-time notice that explains cloud backup. It is due only
/// when cloud sync is available in this build and the notice was never
/// acknowledged.
@injectable
class SyncNoticeCubit extends Cubit<SyncNoticeState> {
  SyncNoticeCubit(this._watchStatus, this._acknowledge)
    : super(const SyncNoticeState());

  final WatchSyncStatus _watchStatus;
  final AcknowledgeSyncNotice _acknowledge;

  /// Reads the status once and decides.
  Future<void> check() async {
    if (state.visibility != SyncNoticeVisibility.unknown) return;
    try {
      final status = await _watchStatus().first;
      if (isClosed) return;
      emit(
        state.copyWith(
          visibility: status.available && !status.noticeShown
              ? SyncNoticeVisibility.show
              : SyncNoticeVisibility.hidden,
        ),
      );
    } catch (_) {
      // Unknown status: never nag.
      if (!isClosed) {
        emit(state.copyWith(visibility: SyncNoticeVisibility.hidden));
      }
    }
  }

  /// The notice was dismissed (by its button or by closing the sheet).
  /// Only the first call counts.
  Future<void> acknowledge() async {
    if (state.visibility != SyncNoticeVisibility.show) return;
    emit(
      state.copyWith(
        visibility: SyncNoticeVisibility.hidden,
        isAcknowledging: true,
      ),
    );
    await _acknowledge();
    if (!isClosed) emit(state.copyWith(isAcknowledging: false));
  }
}
