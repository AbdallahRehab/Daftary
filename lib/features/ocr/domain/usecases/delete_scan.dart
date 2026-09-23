import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/ocr_repository.dart';

/// Deletes a past scan and its image (FR-023).
///
/// Leaves the transactions the scan produced alone: by the time they exist
/// the user has confirmed them, and they are financial records in their own
/// right. Deleting the scan costs only the "view original scan" link, which
/// is exactly what the user asked for.
@injectable
class DeleteScan {
  const DeleteScan(this._repository);

  final OcrRepository _repository;

  Future<Either<Failure, Unit>> call(String scanId) =>
      _repository.deleteScan(scanId);
}
