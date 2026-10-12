import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../entities/pending_sms_import.dart';
import '../entities/sms_import_enums.dart';
import '../entities/sms_value_types.dart';

/// Read-only duplicate queries across both aggregates (domain-interfaces
/// §3.3, FR-060). The person-scoped `FindPossibleDuplicate` is not changed.
abstract class SmsDuplicateLookup {
  /// Probable tier 1 for one pending item with the CURRENT edited values.
  /// Same currency and amount, date within one day (calendar arithmetic,
  /// never `Duration` math), direction group (expense = given, income =
  /// received), not deleted, any source. Returns references only.
  Future<Either<Failure, List<DuplicateRecordRef>>> findSavedMatches({
    required Money amount,
    required DateTime date,
    required SuggestedRecordType type,
  });

  /// One query for a whole ingestion page: every row of both tables in
  /// `[minDate - 1 day, maxDate + 1 day]`, indexed by (currency, amount).
  Future<Either<Failure, SavedRecordWindow>> loadWindow(
    DateTime minDate,
    DateTime maxDate,
  );

  /// Tier 1 branch (2): another pending item with the same card last four,
  /// merchant key and amount within 10 minutes, no reference, parsed time
  /// on both.
  Future<Either<Failure, PendingSmsImport?>> findPendingPair(
    PendingSmsImport item,
  );

  /// SMS-sourced match refinement (FR-059a): the tombstone reference hash
  /// of an existing record, by saved record id.
  Future<Either<Failure, String?>> refHashForSavedRecord(String savedRecordId);

  /// Exact tiers 1-2 and the tier-3 stop (FR-059b): the OTHER pending rows
  /// (never [excludeId]) and the tombstones that share [fingerprint], or
  /// [refAmountHash] when given.
  Future<Either<Failure, List<ImportKeyMatch>>> findKeyMatches({
    required String excludeId,
    required String fingerprint,
    String? refAmountHash,
  });

  /// Other pending rows (never [excludeId]) with exactly [amount], for the
  /// own-transfer pair rule (FR-051d).
  Future<Either<Failure, List<PendingSmsImport>>> findPendingWithAmount(
    Money amount, {
    required String excludeId,
  });

  /// Saved, not deleted records whose `added` tombstone carries [refHash],
  /// for the authorization-reversal match (FR-024b).
  Future<Either<Failure, List<DuplicateRecordRef>>> savedRecordsForRefHash(
    String refHash,
  );

  /// The bank of the message an SMS-sourced record was added from, by
  /// saved record id; `null` when no tombstone remains (FR-051d).
  Future<Either<Failure, String?>> bankForSavedRecord(String savedRecordId);
}
