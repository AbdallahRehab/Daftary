import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/sms_import_repository.dart';

/// "It's the same, don't add" on ONE pending item (FR-061, US5-2).
///
/// Closes the item as a duplicate: tombstone `duplicate` (so the same
/// message never comes back), the original purged and the row scrubbed to
/// its identity shell. It never reads, creates, changes or deletes a saved
/// record: the record the user already has stays exactly as it is.
/// `ImportAlreadyDecidedFailure` when the item is no longer pending.
@injectable
class CloseAsDuplicate {
  CloseAsDuplicate(this._repository);

  final SmsImportRepository _repository;

  Future<Either<Failure, Unit>> call(String pendingId) =>
      _repository.closeAsDuplicate(pendingId);
}
