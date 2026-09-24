import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../entities/finance_entry.dart';
import '../entities/finance_entry_type.dart';
import '../repositories/finance_repository.dart';

/// Records a new income or expense entry (FR-001/FR-002).
///
/// [idempotencyKey] is caller-supplied — generated once when the form opens,
/// not here (per the contract) — which is what makes a retried save a no-op
/// rather than a second entry (FR-021).
@injectable
class AddFinanceEntry {
  const AddFinanceEntry(this._repository);

  final FinanceRepository _repository;

  Future<Either<Failure, FinanceEntry>> call({
    required String idempotencyKey,
    required String categoryId,
    required FinanceEntryType type,
    required Money amount,
    DateTime? date,
    String? note,
  }) {
    return _repository.addEntry(
      idempotencyKey: idempotencyKey,
      categoryId: categoryId,
      type: type,
      amount: amount,
      // FR-001: today is the default, and the caller passing nothing means
      // "today" rather than an error.
      date: date ?? DateTime.now(),
      note: note,
    );
  }
}
