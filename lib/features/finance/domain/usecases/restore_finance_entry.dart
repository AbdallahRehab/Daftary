import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/finance_entry.dart';
import '../repositories/finance_repository.dart';

/// Reverses a soft delete when the user taps Undo (FR-020).
///
/// A no-op success on an entry that is not currently deleted — a duplicate
/// or late undo tap is a user doing nothing wrong, not an error to show.
@injectable
class RestoreFinanceEntry {
  const RestoreFinanceEntry(this._repository);

  final FinanceRepository _repository;

  Future<Either<Failure, FinanceEntry>> call(String entryId) =>
      _repository.restoreEntry(entryId);
}
