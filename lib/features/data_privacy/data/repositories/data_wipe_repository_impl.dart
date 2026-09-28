import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/data_wipe.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/data_wipe_repository.dart';

@LazySingleton(as: DataWipeRepository)
class DataWipeRepositoryImpl implements DataWipeRepository {
  DataWipeRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Either<Failure, Unit>> deleteAllUserData() async {
    final Set<String> filePaths;
    try {
      filePaths = await _db.userFilePaths();
      await _db.deleteAllUserData();
    } catch (e) {
      // The wipe is one transaction, so reaching here means nothing was
      // deleted — and no file has been touched yet either.
      return Left(CacheFailure('Failed to delete user data: $e'));
    }
    await _deleteFiles(filePaths);
    return const Right(unit);
  }

  /// Best-effort, and only after the wipe has committed: a file cannot be
  /// part of the database transaction, so deleting it first could leave a
  /// row pointing at a photo that is gone if the wipe then rolled back.
  /// The rows are what the user sees; a leftover file in private storage
  /// is not worth reporting the whole deletion as failed (same policy as
  /// `OcrRepositoryImpl`'s scan delete).
  Future<void> _deleteFiles(Set<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      } catch (_) {
        // See above.
      }
    }
  }
}
