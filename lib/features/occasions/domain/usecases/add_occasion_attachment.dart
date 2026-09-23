import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/occasion_attachment.dart';
import '../repositories/occasions_repository.dart';

/// Links a photo — the cash-envelope list, the event itself — to an
/// occasion (FR-017).
///
/// [filePath] must already point at a file the app copied into its own
/// private storage; capturing and copying belong to the presentation layer's
/// picker service. Persisting a transient OS picker cache path instead would
/// leave an attachment that silently stops resolving once the system clears
/// that cache.
@injectable
class AddOccasionAttachment {
  const AddOccasionAttachment(this._repository);

  final OccasionsRepository _repository;

  Future<Either<Failure, OccasionAttachment>> call({
    required String occasionId,
    required String filePath,
  }) {
    return _repository.addOccasionAttachment(
      occasionId: occasionId,
      filePath: filePath,
    );
  }
}
