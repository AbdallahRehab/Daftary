import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/ocr_scan_detail.dart';
import '../repositories/ocr_repository.dart';

/// 021: one past scan with its entries and the transactions it produced,
/// live (FR-018, FR-031) — a produced transaction edited or deleted from
/// its person's screen, or through sync, updates the detail with no reload.
@injectable
class WatchScanDetail {
  const WatchScanDetail(this._repository);

  final OcrRepository _repository;

  Stream<Either<Failure, OcrScanDetail>> call(String scanId) =>
      _repository.watchScanDetail(scanId);
}
