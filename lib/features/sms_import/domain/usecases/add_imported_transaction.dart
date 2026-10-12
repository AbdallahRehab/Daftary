import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../entities/review_draft.dart';
import '../entities/sms_import_enums.dart';
import '../entities/sms_import_failures.dart';
import '../entities/sms_value_types.dart';
import '../repositories/sms_import_repository.dart';
import 'check_duplicates.dart';

/// The only place an import becomes money (FR-052, constitution X by
/// analogy). Called only after the user's explicit Add on ONE reviewed
/// item: there is no batch variant, no timer and no background caller
/// (FR-046).
///
/// Steps: load the item (it must still be pending) -> `draft.validate()`
/// (`ImportIncompleteFailure` with field codes) -> unless
/// [duplicateOverride], `CheckDuplicates` (`ProbableDuplicateFailure` when
/// probable; it never blocks otherwise, FR-063) -> `confirm`.
@injectable
class AddImportedTransaction {
  AddImportedTransaction(this._repository, this._checkDuplicates);

  final SmsImportRepository _repository;
  final CheckDuplicates _checkDuplicates;

  Future<Either<Failure, SavedRecordRef>> call({
    required String pendingId,
    required ReviewDraft draft,
    bool duplicateOverride = false,
  }) async {
    final loaded = await _repository.getById(pendingId);
    if (loaded case Left(:final value)) return Left(value);
    final item = loaded.getOrElse((_) => throw StateError('unreachable'));
    if (!item.isPending) return Left(ImportAlreadyDecidedFailure(item.status));

    final missing = draft.validate();
    if (missing.isNotEmpty) return Left(ImportIncompleteFailure(missing));

    if (!duplicateOverride) {
      final checked = await _checkDuplicates(item: item, draft: draft);
      switch (checked) {
        case Left(:final value):
          return Left(value);
        case Right(:final value) when value.tier == DuplicateTier.probable:
          return Left(ProbableDuplicateFailure(value));
        case Right():
          break;
      }
    }

    return _repository.confirm(
      pendingId: pendingId,
      confirmed: confirmedFrom(draft),
    );
  }

  /// The confirmed values; only valid after `draft.validate()` is empty.
  static ConfirmedImport confirmedFrom(ReviewDraft draft) {
    final money = draft.money!;
    final date = draft.date!;
    final trimmed = draft.note?.trim();
    final note = trimmed == null || trimmed.isEmpty ? null : trimmed;
    return switch (draft.type!) {
      SuggestedRecordType.expense ||
      SuggestedRecordType.income => ConfirmedFinanceEntry(
        categoryId: draft.categoryId!,
        type: draft.type == SuggestedRecordType.income
            ? FinanceEntryType.income
            : FinanceEntryType.expense,
        amount: money,
        date: date,
        note: note,
      ),
      SuggestedRecordType.given ||
      SuggestedRecordType.received => ConfirmedPersonTransaction(
        personId: draft.personId!,
        direction: draft.type == SuggestedRecordType.received
            ? TransactionDirection.received
            : TransactionDirection.given,
        amount: money,
        date: date,
        note: note,
      ),
      SuggestedRecordType.ignore ||
      SuggestedRecordType.unset => throw StateError('not savable'),
    };
  }
}
