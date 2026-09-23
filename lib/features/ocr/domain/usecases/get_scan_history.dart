import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/ocr_scan.dart';
import '../repositories/ocr_repository.dart';

/// Past scans, newest first (FR-018).
@injectable
class GetScanHistory {
  const GetScanHistory(this._repository);

  final OcrRepository _repository;

  Future<Either<Failure, List<OcrScan>>> call() => _repository.getScanHistory();
}
