import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/occasions_repository.dart';

/// Removes a photo from an occasion after the caller has shown a
/// confirmation (FR-017).
///
/// Soft-deletes the reference rather than erasing the record, matching how
/// every other deletion in the app behaves: the attachment leaves the
/// gallery, and no money or audit history is touched.
@injectable
class RemoveOccasionAttachment {
  const RemoveOccasionAttachment(this._repository);

  final OccasionsRepository _repository;

  Future<Either<Failure, Unit>> call(String attachmentId) =>
      _repository.removeOccasionAttachment(attachmentId);
}
