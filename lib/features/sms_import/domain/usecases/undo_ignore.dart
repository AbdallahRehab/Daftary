import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/sms_value_types.dart';
import '../repositories/sms_import_repository.dart';

/// Undo an ignore or an expiry from the 30-day Undo list (FR-067, FR-068).
///
/// Removes the item's tombstone and the item itself. Its original was
/// purged when it was decided, so the message comes back only when the
/// user scans, pastes or shares it again: the result always says
/// `needsRescan: true` and the UI says so. `ImportAlreadyDecidedFailure`
/// for an item that was added or closed as a duplicate.
@injectable
class UndoIgnore {
  UndoIgnore(this._repository);

  final SmsImportRepository _repository;

  Future<Either<Failure, UndoResult>> call(String id) async =>
      (await _repository.undo(id)).map((_) => const UndoResult());
}
