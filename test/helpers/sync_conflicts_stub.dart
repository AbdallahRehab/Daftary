import 'package:daftary/core/di/injection.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_conflict_item.dart';
import 'package:daftary/features/cloud_sync/domain/repositories/cloud_sync_repository.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/resolve_sync_conflict.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/watch_sync_conflicts.dart';
import 'package:daftary/features/cloud_sync/presentation/cubit/sync_conflicts_cubit.dart';
import 'package:mocktail/mocktail.dart';

/// A repository with no open sync conflicts, for pages that show the
/// conflict badge (021 T074).
class NoConflictsRepository extends Fake implements CloudSyncRepository {
  @override
  Stream<List<SyncConflictItem>> watchConflicts() => Stream.value(const []);
}

/// Registers a [SyncConflictsCubit] that never reports a conflict.
void registerNoSyncConflicts() {
  final repository = NoConflictsRepository();
  getIt.registerFactory<SyncConflictsCubit>(
    () => SyncConflictsCubit(
      WatchSyncConflicts(repository),
      ResolveSyncConflict(repository),
    ),
  );
}
