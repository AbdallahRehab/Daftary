import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/ocr_scan_detail.dart';
import '../repositories/ocr_repository.dart';

/// One past scan with its original image, its entries as they ended up,
/// and the transactions it produced (FR-018).
@injectable
class GetScanDetail {
  const GetScanDetail(this._repository);

  final OcrRepository _repository;

  Future<Either<Failure, OcrScanDetail>> call(String scanId) =>
      _repository.getScanDetail(scanId);
}
