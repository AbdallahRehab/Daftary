import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../entities/pending_sms_import.dart';
import '../entities/sms_value_types.dart';

/// Pending imports, tombstones and decisions (domain-interfaces §3.1).
abstract class SmsImportRepository {
  // --- ingestion -----------------------------------------------------------

  /// Idempotent insert of one parsed suggestion. Returns
  /// [InsertOutcome.inserted] or [InsertOutcome.alreadyKnown] (fingerprint
  /// present in pending rows or tombstones, or a tier-2 exact match). Never
  /// creates a `MoneyTransaction` or `FinanceEntry` (FR-022). Seals the
  /// masked original inside the call; if sealing fails the row is stored
  /// with no original.
  Future<Either<Failure, InsertOutcome>> insertPending(NewPendingImport item);

  /// Batched exact-tier lookup for one page: which of these fingerprints
  /// and reference-amount hashes are already known. One query per page.
  Future<Either<Failure, KnownKeys>> findKnown({
    required Set<String> fingerprints,
    required Set<String> refAmountHashes,
  });

  /// Tier-3 helper: tombstone and pending reference hashes for a bank, to
  /// decide "both present and different" (FR-059b).
  Future<Either<Failure, Set<String>>> refHashesForBank(String bankId);

  // --- reading -------------------------------------------------------------

  /// Ordered: low confidence first, then oldest first.
  Stream<Either<Failure, List<PendingSmsImport>>> watchPending();

  /// For the Home card (FR-050).
  Stream<Either<Failure, int>> watchPendingCount();

  Future<Either<Failure, PendingSmsImport>> getById(String id);

  /// Ignored and expired items decided within 30 days.
  Stream<Either<Failure, List<PendingSmsImport>>> watchUndoList();

  /// For the "N suggestions expired" notice (FR-025).
  Future<Either<Failure, int>> unseenExpiredCount();

  Future<Either<Failure, Unit>> markExpiredNoticeSeen();

  /// Decrypts the masked original. `Left(OriginalUnavailableFailure)` when
  /// the item is not pending, has no original, or the original cannot be
  /// opened; on the first failed open the original is deleted (FR-074a).
  Future<Either<Failure, String>> openOriginal(String id);

  // --- decisions (each in ONE transaction; the original is deleted) --------

  /// THE gate (FR-052). In one database transaction: re-read the row and
  /// require `pending` (else `ImportAlreadyDecidedFailure`); create the
  /// record through `addSmsSourcedTransaction` or `addSmsSourcedEntry` with
  /// idempotency key `sms-import:<id>`; write the `added` tombstone; mark
  /// the row added; upsert the learned mapping when the chosen category
  /// differs from the suggestion; increment `addedCount`. Any inner failure
  /// rolls the whole transaction back and maps to a fixed, content-free
  /// failure. Called only by `AddImportedTransaction`.
  Future<Either<Failure, SavedRecordRef>> confirm({
    required String pendingId,
    required ConfirmedImport confirmed,
  });

  /// Single or batch; one transaction.
  Future<Either<Failure, Unit>> ignore(Set<String> ids);

  /// Tombstone `duplicate` (FR-061).
  Future<Either<Failure, Unit>> closeAsDuplicate(String id);

  /// Ignored or expired only; deletes the tombstone and the row.
  Future<Either<Failure, Unit>> undo(String id);

  // --- maintenance ---------------------------------------------------------

  /// Expires every pending row with `expiresAt <= now`; returns how many.
  Future<Either<Failure, int>> expireDue(DateTime now);

  /// Deletes decided rows older than 30 days and tombstones past
  /// `purgeAfter`.
  Future<Either<Failure, PurgeResult>> purgeDecided(DateTime now);

  /// Replaces only the parsed-field columns and the rule version of one
  /// pending row, in one transaction. The fingerprint, hashes, receipt
  /// time, source and creation time are immutable (research Decision 7).
  Future<Either<Failure, Unit>> replaceParsedFields(
    String id,
    ReparsedFields fields,
  );

  Future<Either<Failure, List<ReparseCandidate>>> pendingNeedingReparse(
    Map<String, int> currentVersions,
  );

  /// Disable-with-delete (FR-078): removes every pending row, writes no
  /// tombstone. Returns how many were deleted.
  Future<Either<Failure, int>> deleteAllPending();
}

enum InsertOutcome { inserted, alreadyKnown }

/// What the user confirmed on Add. Sealed so the repository picks the table
/// without a boolean flag.
sealed class ConfirmedImport extends Equatable {
  const ConfirmedImport({required this.amount, required this.date, this.note});

  final Money amount;

  /// Date-only.
  final DateTime date;
  final String? note;

  /// Redacted: never prints the amount, the date or the note.
  @override
  String toString() => '$runtimeType()';
}

/// Saved as an own-money `FinanceEntry` (expense or income).
class ConfirmedFinanceEntry extends ConfirmedImport {
  const ConfirmedFinanceEntry({
    required this.categoryId,
    required this.type,
    required super.amount,
    required super.date,
    super.note,
  });

  final String categoryId;
  final FinanceEntryType type;

  @override
  List<Object?> get props => [categoryId, type, amount, date, note];
}

/// Saved as a people-ledger `MoneyTransaction` (given or received), kind
/// `initialExchange` (NG8).
class ConfirmedPersonTransaction extends ConfirmedImport {
  const ConfirmedPersonTransaction({
    required this.personId,
    required this.direction,
    required super.amount,
    required super.date,
    super.note,
  });

  final String personId;
  final TransactionDirection direction;

  @override
  List<Object?> get props => [personId, direction, amount, date, note];
}
