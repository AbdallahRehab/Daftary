import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/sync/local/sync_local_store.dart';
import '../../../../core/sync/remote/secure_local_storage.dart';
import '../../../../core/sync/remote/supabase_initializer.dart';
import '../../../../core/sync/remote/sync_error_mapper.dart';
import '../../../../core/sync/sync_scheduler.dart';
import '../../../data_privacy/domain/services/cloud_copy_eraser.dart';

/// [CloudCopyEraser] over Supabase (021): the `sync_delete_all` RPC deletes
/// every row the signed-in account owns, and a local sign-out forgets the
/// session on this device.
@LazySingleton(as: CloudCopyEraser)
class SupabaseCloudCopyEraser implements CloudCopyEraser {
  SupabaseCloudCopyEraser(
    this._supabase,
    this._scheduler,
    this._store,
    this._secureStorage,
  );

  final SupabaseInitializer _supabase;
  final SyncScheduler _scheduler;
  final SyncLocalStore _store;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<Either<Failure, Unit>> wipe({
    required bool eraseCloudCopy,
    required Future<Either<Failure, Unit>> Function() wipeLocalData,
  }) => _scheduler.runExclusive(() async {
    final cloud = await _dealWithCloudCopy(eraseCloudCopy: eraseCloudCopy);
    if (cloud.isLeft()) return cloud;
    return wipeLocalData();
  }, resetBackoff: true);

  Future<Either<Failure, Unit>> _dealWithCloudCopy({
    required bool eraseCloudCopy,
  }) async {
    final hasSession = await _secureStorage.containsKey(
      key: SecureLocalStorage.sessionKey,
    );
    if (!_supabase.isConfigured || !hasSession) return const Right(unit);

    // Sync switched off (FR-041): no request leaves the device, so the
    // cloud copy is left alone and only the session is forgotten.
    final reachable =
        (await _store.readState()).enabled &&
        await _supabase.ensureInitialized();
    if (!reachable) {
      await _forgetSession();
      return const Right(unit);
    }

    final client = _supabase.client;
    if (eraseCloudCopy) {
      try {
        await client.rpc<void>('sync_delete_all');
      } catch (e) {
        final failure = SyncErrorMapper.map(e).failure;
        // The account is already gone — an earlier attempt erased it and
        // then stopped short of the local wipe. Nothing is left to erase.
        if (failure is! UnauthorizedFailure) return Left(failure);
      }
    }
    try {
      // Local scope: only this device's session ends, and other devices
      // stay signed in.
      await client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // Best-effort: the stored session is forgotten below either way.
    }
    await _forgetSession();
    return const Right(unit);
  }

  /// Belt and braces: the session must not survive even if the auth client
  /// never had it loaded.
  Future<void> _forgetSession() =>
      _secureStorage.delete(key: SecureLocalStorage.sessionKey);
}
