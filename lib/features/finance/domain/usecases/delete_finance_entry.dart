import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/finance_repository.dart';

/// Soft-deletes an entry, committing immediately (FR-020, research.md
/// Decision 8).
///
/// The undo window lives in the Presentation layer, not here: deferring the
/// commit would mean a backgrounded or killed app leaves the delete in
/// limbo, whereas committing now and offering [RestoreFinanceEntry] leaves
/// the data consistent at every instant.
@injectable
class DeleteFinanceEntry {
  const DeleteFinanceEntry(this._repository);

  final FinanceRepository _repository;

  Future<Either<Failure, Unit>> call(String entryId) =>
      _repository.deleteEntry(entryId);
}
