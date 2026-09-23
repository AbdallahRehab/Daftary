import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/ocr_scan.dart';
import '../repositories/ocr_repository.dart';

/// Reads the scan's image and turns what it finds into candidate entries
/// (FR-003).
///
/// The one thing worth being explicit about: this produces *suggestions*.
/// A successful extraction leaves the scan in `needsReview` and the ledger
/// untouched — every path to real money goes through [ConfirmScanBatch]
/// (constitution Principle X).
@injectable
class RunOcrExtraction {
  const RunOcrExtraction(this._repository);

  final OcrRepository _repository;

  Future<Either<Failure, OcrScan>> call(String scanId) =>
      _repository.runExtraction(scanId);
}
