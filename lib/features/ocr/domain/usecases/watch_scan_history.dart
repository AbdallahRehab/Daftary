import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/ocr_scan.dart';
import '../repositories/ocr_repository.dart';

/// 021: past scans, newest first, live (FR-018, FR-031) — a scan finished,
/// abandoned or deleted on any screen updates the history with no reload.
@injectable
class WatchScanHistory {
  const WatchScanHistory(this._repository);

  final OcrRepository _repository;

  Stream<Either<Failure, List<OcrScan>>> call() =>
      _repository.watchScanHistory();
}
