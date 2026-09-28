import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

/// Puts back exactly the secure-storage values a [SecureStorageWiper.wipe]
/// removed. Returned by a successful wipe so `DeleteAllUserData` can undo it
/// if the database wipe that follows fails.
typedef SecureStorageRestore = Future<Either<Failure, Unit>> Function();

/// A feature's OS secure-storage keys that a full "delete all my data"
/// (013 FR-016) must clear but the database transaction cannot reach
/// (015 T085: App Lock's `app_lock.*` keys).
///
/// A Domain-layer seam only: the implementation lives in the owning
/// feature's data layer and is bound via `injectable`, so `data_privacy`
/// never imports that feature (constitution Principle II).
///
/// Secure storage has no transactions, so atomicity with the database wipe
/// (013 FR-018 / 015 FR-019) is built from a snapshot instead:
/// - [wipe] is itself all-or-nothing — if a delete fails part-way it
///   restores what it had already removed and returns a [Failure];
/// - on success it returns a [SecureStorageRestore] that `DeleteAllUserData`
///   calls if the database wipe then rolls back, so a failed deletion
///   leaves secure storage as untouched as the database.
abstract class SecureStorageWiper {
  Future<Either<Failure, SecureStorageRestore>> wipe();
}
