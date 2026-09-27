import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/sync_conflict_item.dart';
import '../entities/sync_status.dart';

/// 021: the only sync API the Presentation layer sees
/// (contracts/dart-interfaces.md §4).
abstract class CloudSyncRepository {
  /// The live status behind the Settings sync page.
  Stream<SyncStatus> watchStatus();

  /// Requests a cycle now ("Sync now"); never starts a second one.
  Future<Either<Failure, Unit>> syncNow();

  /// Switches sync on or off (FR-041).
  Future<Either<Failure, Unit>> setEnabled(bool enabled);

  /// Records that the one-time sync notice was shown.
  Future<Either<Failure, Unit>> markNoticeShown();

  /// Queues every failed item again.
  Future<Either<Failure, Unit>> retryFailed();

  /// The open conflicts, oldest first.
  Stream<List<SyncConflictItem>> watchConflicts();

  /// Resolves the open conflict of one record (contracts/sync-rpc.md §6).
  Future<Either<Failure, Unit>> resolveConflict(
    String entityType,
    String entityId,
    ConflictChoice choice,
  );

  /// Sends a one-time code to [email], to link it to the current account
  /// ([linkCurrent]) or to sign in to an existing one.
  Future<Either<Failure, Unit>> requestEmailCode(
    String email, {
    required bool linkCurrent,
  });

  /// Confirms the code sent by [requestEmailCode].
  Future<Either<Failure, Unit>> confirmEmailCode(
    String email,
    String code, {
    required bool linkCurrent,
  });

  /// Whether the record has an open conflict (the row badge).
  Stream<bool> watchHasConflict(String entityType, String entityId);
}
