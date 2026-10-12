import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/sms_import_repository.dart';

/// Ignore one pending item or a selection of them in one action (FR-064,
/// US6). The UI confirms a batch first; this use case does not ask.
///
/// One transaction: each item gets an `ignored` tombstone (so the same
/// message never comes back on a re-scan, FR-066), loses its original and
/// keeps only the six fields the Undo list shows. All or nothing: when any
/// item is missing or no longer pending, nothing is ignored. It never
/// touches a saved record.
@injectable
class IgnoreImport {
  IgnoreImport(this._repository);

  final SmsImportRepository _repository;

  Future<Either<Failure, Unit>> call({required Set<String> ids}) =>
      _repository.ignore(ids);
}
