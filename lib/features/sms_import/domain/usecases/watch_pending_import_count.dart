import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/sms_import_repository.dart';

/// How many items wait for review: a count only, never content (FR-050).
@injectable
class WatchPendingImportCount {
  WatchPendingImportCount(this._repository);

  final SmsImportRepository _repository;

  Stream<Either<Failure, int>> call() => _repository.watchPendingCount();
}
