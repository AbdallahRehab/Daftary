import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/pending_sms_import.dart';
import '../repositories/sms_import_repository.dart';
import 'get_pending_imports.dart';

/// The pending list as a live stream, in review order (low confidence
/// first, then oldest first; FR-042).
@injectable
class WatchPendingImports {
  WatchPendingImports(this._repository);

  final SmsImportRepository _repository;

  Stream<Either<Failure, List<PendingSmsImport>>> call() => _repository
      .watchPending()
      .map((result) => result.map(GetPendingImports.sortForReview));
}
