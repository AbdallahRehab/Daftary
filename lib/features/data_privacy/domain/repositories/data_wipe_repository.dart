import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

/// The one write capability 013 adds: permanently removing everything the
/// user has recorded on this device (FR-016).
abstract class DataWipeRepository {
  /// Deletes every row from every table as one atomic operation (FR-018) —
  /// either the database ends up in its fresh-install state, or (on any
  /// failure) every table is left completely unchanged. Never a partial
  /// wipe.
  Future<Either<Failure, Unit>> deleteAllUserData();
}
