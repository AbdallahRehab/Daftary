import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/finance_entry.dart';
import '../repositories/finance_repository.dart';

/// Corrects an existing entry's amount/category/date/note (FR-019).
///
/// There is deliberately no `type` parameter: the entry's direction is
/// re-derived from the category it now points at, so an edit cannot leave
/// the two disagreeing.
@injectable
class EditFinanceEntry {
  const EditFinanceEntry(this._repository);

  final FinanceRepository _repository;

  Future<Either<Failure, FinanceEntry>> call({
    required String entryId,
    required String categoryId,
    required int amountMinorUnits,
    required DateTime date,
    String? note,
  }) {
    return _repository.editEntry(
      entryId: entryId,
      categoryId: categoryId,
      amountMinorUnits: amountMinorUnits,
      date: date,
      note: note,
    );
  }
}
