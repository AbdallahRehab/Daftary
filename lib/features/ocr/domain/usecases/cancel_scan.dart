import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/ocr_repository.dart';

/// Abandons a scan without creating anything (FR-015).
///
/// When the user had already corrected entries, the caller must have shown
/// the "discard your corrections?" prompt first, and the scan is kept as
/// `discarded` rather than hard-deleted — work the user put in should not
/// vanish without at least a warning.
@injectable
class CancelScan {
  const CancelScan(this._repository);

  final OcrRepository _repository;

  Future<Either<Failure, Unit>> call(String scanId) =>
      _repository.cancelScan(scanId);
}
