import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/sms_import_repository.dart';

/// How many items expired since the notice was last acknowledged, for the
/// one-line "N suggestions expired" notice (FR-025, US1-10).
@injectable
class GetExpiredNotice {
  GetExpiredNotice(this._repository);

  final SmsImportRepository _repository;

  Future<Either<Failure, int>> call() => _repository.unseenExpiredCount();
}
