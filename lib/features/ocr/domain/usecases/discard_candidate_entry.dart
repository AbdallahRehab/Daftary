import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/ocr_repository.dart';

/// Drops one suggested entry from the batch (FR-010). Its siblings and the
/// scan itself are untouched — discarding a misread line is a routine part
/// of reviewing, not an abandonment of the scan.
@injectable
class DiscardCandidateEntry {
  const DiscardCandidateEntry(this._repository);

  final OcrRepository _repository;

  Future<Either<Failure, Unit>> call(String entryId) =>
      _repository.discardCandidateEntry(entryId);
}
