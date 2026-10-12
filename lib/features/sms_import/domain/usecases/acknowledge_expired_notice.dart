import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/sms_import_repository.dart';

/// Dismisses the "N suggestions expired" notice (FR-025).
@injectable
class AcknowledgeExpiredNotice {
  AcknowledgeExpiredNotice(this._repository);

  final SmsImportRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.markExpiredNoticeSeen();
}
