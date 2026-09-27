import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/sync_conflict_item.dart';
import '../../domain/usecases/resolve_sync_conflict.dart';
import '../../domain/usecases/watch_sync_conflicts.dart';
import 'sync_conflicts_state.dart';

/// 021 T074: the open conflicts on financial records, and their resolution
/// (FR-035). Drives the row badges and the resolution sheet.
@injectable
class SyncConflictsCubit extends Cubit<SyncConflictsState> {
  SyncConflictsCubit(this._watchConflicts, this._resolveConflict)
    : super(const SyncConflictsState());

  final WatchSyncConflicts _watchConflicts;
  final ResolveSyncConflict _resolveConflict;

  StreamSubscription<List<SyncConflictItem>>? _subscription;

  /// Subscribes to the live list, replacing any earlier subscription.
  void subscribe() {
    unawaited(_subscription?.cancel());
    _subscription = _watchConflicts().listen(
      (items) {
        if (isClosed) return;
        emit(
          state.copyWith(
            status: SyncConflictsStatus.success,
            items: List.unmodifiable(items),
            resolveFailure: state.resolveFailure,
          ),
        );
      },
      onError: (Object error) {
        if (isClosed) return;
        emit(
          state.copyWith(
            status: SyncConflictsStatus.failure,
            failure: UnknownFailure('Failed to read the conflicts: $error'),
          ),
        );
      },
    );
  }

  /// Keeps [choice] for [item]. Ignored while that record is already being
  /// resolved. Returns whether it succeeded.
  Future<bool> resolve(SyncConflictItem item, ConflictChoice choice) async {
    if (state.isResolving(item)) return false;
    final key = SyncConflictsState.keyOf(item.entityType, item.entityId);
    emit(state.copyWith(resolving: {...state.resolving, key}));

    final result = await _resolveConflict(
      item.entityType,
      item.entityId,
      choice,
    );
    if (isClosed) return result.isRight();
    final resolving = {...state.resolving}..remove(key);
    emit(
      state.copyWith(
        resolving: resolving,
        failure: state.failure,
        resolveFailure: result.getLeft().toNullable(),
      ),
    );
    return result.isRight();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
