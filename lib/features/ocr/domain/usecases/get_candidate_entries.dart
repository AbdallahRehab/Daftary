import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/candidate_entry.dart';
import '../repositories/ocr_repository.dart';

/// Loads the batch the review screen works on (FR-008).
@injectable
class GetCandidateEntries {
  const GetCandidateEntries(this._repository);

  final OcrRepository _repository;

  Future<Either<Failure, List<CandidateEntry>>> call(String scanId) =>
      _repository.getCandidateEntries(scanId);
}
