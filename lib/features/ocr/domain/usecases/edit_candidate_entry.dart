import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../entities/candidate_entry.dart';
import '../repositories/ocr_repository.dart';

/// Applies one correction on the review screen (FR-008).
///
/// Corrections go through the same validation as manual entry — a
/// non-positive amount is refused here exactly as it would be in the
/// transaction form — because a value the user typed deserves the same
/// scrutiny whether or not a scan suggested it first.
@injectable
class EditCandidateEntry {
  const EditCandidateEntry(this._repository);

  final OcrRepository _repository;

  Future<Either<Failure, CandidateEntry>> call({
    required String entryId,
    String? personName,
    String? matchedPersonId,
    bool clearMatchedPersonId = false,
    int? amountMinorUnits,
    TransactionDirection? direction,
    DateTime? date,
    String? notes,
  }) {
    return _repository.editCandidateEntry(
      entryId: entryId,
      personName: personName,
      matchedPersonId: matchedPersonId,
      clearMatchedPersonId: clearMatchedPersonId,
      amountMinorUnits: amountMinorUnits,
      direction: direction,
      date: date,
      notes: notes,
    );
  }
}
