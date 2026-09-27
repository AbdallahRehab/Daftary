import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/sync_failed_item.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/usecases/retry_failed_sync.dart';
import '../../domain/usecases/set_sync_enabled.dart';
import '../../domain/usecases/sync_now.dart';
import '../../domain/usecases/watch_failed_sync_items.dart';
import '../../domain/usecases/watch_sync_status.dart';
import 'sync_settings_state.dart';

/// 021 US6: the Settings sync page — status, "Sync now", the switch and
/// retrying failed items (FR-040/041). Every action ignores a second tap
/// while the first is running.
@injectable
class SyncSettingsCubit extends Cubit<SyncSettingsState> {
  SyncSettingsCubit(
    this._watchStatus,
    this._watchFailedItems,
    this._syncNow,
    this._setEnabled,
    this._retryFailed,
  ) : super(const SyncSettingsState());

  final WatchSyncStatus _watchStatus;
  final WatchFailedSyncItems _watchFailedItems;
  final SyncNow _syncNow;
  final SetSyncEnabled _setEnabled;
  final RetryFailedSync _retryFailed;

  StreamSubscription<SyncStatus>? _statusSub;
  StreamSubscription<List<SyncFailedItem>>? _failedSub;

  /// Subscribes to the live status and failed items (idempotent).
  void subscribe() {
    unawaited(_statusSub?.cancel());
    unawaited(_failedSub?.cancel());
    _statusSub = _watchStatus().listen(
      (status) {
        if (isClosed) return;
        emit(
          state.copyWith(
            loadStatus: SyncSettingsLoadStatus.ready,
            status: status,
          ),
        );
      },
      onError: (Object error) {
        if (isClosed) return;
        emit(
          state.copyWith(
            loadStatus: SyncSettingsLoadStatus.failure,
            actionFailure: UnknownFailure('Failed to read the status: $error'),
          ),
        );
      },
    );
    _failedSub = _watchFailedItems().listen((items) {
      if (isClosed) return;
      emit(state.copyWith(failedItems: List.unmodifiable(items)));
    }, onError: (Object _) {});
  }

  /// "Sync now": ignored while a cycle runs (the button is disabled too).
  Future<void> syncNow() async {
    if (!state.canSyncNow) return;
    emit(state.copyWith(isRequestingSync: true, clearActionFailure: true));
    final result = await _syncNow();
    _finish(result, (s) => s.copyWith(isRequestingSync: false));
  }

  Future<void> setEnabled(bool enabled) async {
    if (state.isTogglingEnabled || state.status?.enabled == enabled) return;
    emit(state.copyWith(isTogglingEnabled: true, clearActionFailure: true));
    final result = await _setEnabled(enabled);
    _finish(result, (s) => s.copyWith(isTogglingEnabled: false));
  }

  Future<void> retryFailed() async {
    if (state.isRetrying) return;
    emit(state.copyWith(isRetrying: true, clearActionFailure: true));
    final result = await _retryFailed();
    _finish(result, (s) => s.copyWith(isRetrying: false));
  }

  void _finish(
    Either<Failure, Unit> result,
    SyncSettingsState Function(SyncSettingsState) done,
  ) {
    if (isClosed) return;
    final next = done(state);
    emit(
      result.match(
        (failure) => next.copyWith(actionFailure: failure),
        (_) => next,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _statusSub?.cancel();
    await _failedSub?.cancel();
    return super.close();
  }
}
