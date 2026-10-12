import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/pending_sms_import.dart';
import '../repositories/sms_import_repository.dart';

/// One pending import by id; `NotFoundFailure` when it no longer exists
/// (purged, undone, or deleted by a disable or a mute).
@injectable
class GetPendingImport {
  GetPendingImport(this._repository);

  final SmsImportRepository _repository;

  Future<Either<Failure, PendingSmsImport>> call(String id) async {
    final result = await _repository.getById(id);
    return result.mapLeft(
      (failure) => failure is NotFoundFailure
          ? const NotFoundFailure('sms_import_not_found')
          : failure,
    );
  }
}
