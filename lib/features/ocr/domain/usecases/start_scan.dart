import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/ocr_scan.dart';
import '../repositories/ocr_repository.dart';

/// Opens a scan session over an already-prepared image (FR-001/FR-002).
///
/// Creates the `processing` scan record and nothing else — no recognition
/// runs here, and certainly no transaction is created.
@injectable
class StartScan {
  const StartScan(this._repository);

  final OcrRepository _repository;

  Future<Either<Failure, OcrScan>> call({
    required String sourceImagePath,
    required int rotationDegrees,
    String? cropBounds,
  }) {
    return _repository.startScan(
      sourceImagePath: sourceImagePath,
      rotationDegrees: rotationDegrees,
      cropBounds: cropBounds,
    );
  }
}
