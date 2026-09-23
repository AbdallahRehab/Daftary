import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/ocr_scan.dart';
import '../repositories/ocr_repository.dart';

/// Records the whole batch against an occasion (FR-014), so everything
/// confirmed from it lands as that occasion's contributions (008) rather
/// than as plain transactions. Passing `null` clears the tag.
@injectable
class TagBatchToOccasion {
  const TagBatchToOccasion(this._repository);

  final OcrRepository _repository;

  Future<Either<Failure, OcrScan>> call({
    required String scanId,
    String? occasionId,
  }) {
    return _repository.tagBatchToOccasion(
      scanId: scanId,
      occasionId: occasionId,
    );
  }
}
