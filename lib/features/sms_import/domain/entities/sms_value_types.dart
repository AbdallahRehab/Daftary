import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/provenance/import_provenance.dart';
import 'parse_confidence.dart';
import 'parse_result.dart';
import 'pending_sms_import.dart';
import 'sms_import_enums.dart';
import 'sms_permission_status.dart';

// Shared value types of the bank-message import domain
// (domain-interfaces §6, data-model §2). Every type here that can hold
// message-derived content overrides `toString` with a redacted form.

/// One message entering the pipeline (scan, catch-up, paste or share).
class RawIncoming extends Equatable {
  const RawIncoming({
    required this.text,
    this.sender,
    this.receivedAt,
    this.providerId,
  });

  /// The message as received. Never persisted as is.
  final String text;

  /// `null` for paste and share.
  final String? sender;

  /// `null` for paste and share.
  final DateTime? receivedAt;

  /// The provider `_id` (scan and catch-up only).
  final int? providerId;

  @override
  List<Object?> get props => [text, sender, receivedAt, providerId];

  @override
  String toString() => 'RawIncoming(length: ${text.length})';
}

/// What ingestion hands to `SmsImportRepository.insertPending`: every
/// persisted field (as a [PendingSmsImport], whose `hasRawText` is ignored
/// on insert) plus the masked original to seal.
class NewPendingImport extends Equatable {
  const NewPendingImport({required this.item, this.rawMasked});

  /// The row to insert, including its hashes.
  final PendingSmsImport item;

  /// The masked original; sealed by the repository inside the insert. When
  /// `null`, or when sealing fails, the row is stored with no original.
  final String? rawMasked;

  @override
  List<Object?> get props => [item, rawMasked];

  @override
  String toString() =>
      'NewPendingImport(item: $item, hasRaw: ${rawMasked != null})';
}

/// The parsed-field columns a re-parse may replace (research Decision 7).
/// The fingerprint, the hashes, the bank, the source, the sender, the
/// receipt time and the creation time are immutable and not here.
class ReparsedFields extends Equatable {
  ReparsedFields({
    required this.parserId,
    required this.ruleVersion,
    required this.kind,
    required this.direction,
    required this.suggestedType,
    required this.confidence,
    this.amount,
    List<int> amountCandidates = const [],
    this.foreignAmountText,
    this.foreignAmount,
    this.occurredOn,
    this.timeMinutes,
    this.merchant,
    this.merchantKey,
    this.counterparty,
    this.cardLast4,
    this.suggestedCategoryId,
    this.suggestedPersonId,
    Set<SmsWarning> warnings = const {},
  }) : amountCandidates = List.unmodifiable(amountCandidates),
       warnings = Set.unmodifiable(warnings);

  final String parserId;
  final String ruleVersion;
  final SmsKind kind;
  final SmsDirection direction;
  final Money? amount;
  final List<int> amountCandidates;
  final String? foreignAmountText;

  /// The stated original-currency amount when in the catalog (FR-059).
  final Money? foreignAmount;
  final DateTime? occurredOn;
  final int? timeMinutes;
  final String? merchant;
  final String? merchantKey;
  final String? counterparty;
  final String? cardLast4;
  final String? suggestedCategoryId;
  final String? suggestedPersonId;
  final SuggestedRecordType suggestedType;
  final ParseConfidence confidence;
  final Set<SmsWarning> warnings;

  @override
  List<Object?> get props => [
    parserId,
    ruleVersion,
    kind,
    direction,
    amount,
    amountCandidates,
    foreignAmountText,
    foreignAmount,
    occurredOn,
    timeMinutes,
    merchant,
    merchantKey,
    counterparty,
    cardLast4,
    suggestedCategoryId,
    suggestedPersonId,
    suggestedType,
    confidence,
    warnings,
  ];

  @override
  String toString() =>
      'ReparsedFields(rule: $ruleVersion, kind: ${kind.name}, '
      'direction: ${direction.name})';
}

/// What a re-parse needs to re-run one pending item (research Decision 7).
class ReparseCandidate extends Equatable {
  const ReparseCandidate({
    required this.id,
    required this.source,
    required this.ruleVersion,
    this.senderId,
    this.receivedAt,
  });

  final String id;
  final SmsSource source;
  final String? senderId;
  final DateTime? receivedAt;
  final String ruleVersion;

  @override
  List<Object?> get props => [id, source, senderId, receivedAt, ruleVersion];

  @override
  String toString() =>
      'ReparseCandidate(source: ${source.name}, rule: $ruleVersion)';
}

/// The record an Add created.
class SavedRecordRef extends Equatable {
  const SavedRecordRef({required this.id, required this.type});

  final String id;
  final SavedRecordType type;

  @override
  List<Object?> get props => [id, type];
}

/// Which keys of one ingestion page are already known (exact tiers 1-2).
class KnownKeys extends Equatable {
  KnownKeys({
    Set<String> fingerprints = const {},
    Set<String> refAmountHashes = const {},
  }) : fingerprints = Set.unmodifiable(fingerprints),
       refAmountHashes = Set.unmodifiable(refAmountHashes);

  final Set<String> fingerprints;
  final Set<String> refAmountHashes;

  @override
  List<Object?> get props => [fingerprints, refAmountHashes];

  @override
  String toString() =>
      'KnownKeys(fingerprints: ${fingerprints.length}, '
      'refAmountHashes: ${refAmountHashes.length})';
}

/// What a purge pass deleted.
class PurgeResult extends Equatable {
  const PurgeResult({this.rows = 0, this.tombstones = 0});

  final int rows;
  final int tombstones;

  @override
  List<Object?> get props => [rows, tombstones];
}

/// Progress of a running scan; counts only.
class ScanProgress extends Equatable {
  const ScanProgress({required this.processed, this.total});

  final int processed;

  /// Unknown while paging.
  final int? total;

  @override
  List<Object?> get props => [processed, total];
}

/// A cooperative cancellation flag for one scan. Scans check it between
/// messages and pages, and keep the items created so far (FR-007).
///
/// Not a value type: it is mutable and compared by identity.
class ScanCancellationToken {
  ScanCancellationToken();

  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  /// Idempotent.
  void cancel() => _cancelled = true;

  @override
  String toString() => 'ScanCancellationToken(cancelled: $_cancelled)';
}

/// Why a message was skipped in a scan or paste summary. A code, never
/// text (FR-024, FR-097).
enum SkipReason {
  notRecognized,
  noAmount,
  amountUnreadable,
  tooLong,
  empty,
  nonText,
  parserError;

  static SkipReason fromUnreadable(UnreadableReason reason) => switch (reason) {
    UnreadableReason.noAmount => noAmount,
    UnreadableReason.amountUnreadable => amountUnreadable,
    UnreadableReason.tooLong => tooLong,
    UnreadableReason.empty => empty,
    UnreadableReason.nonText => nonText,
    UnreadableReason.parserError => parserError,
  };
}

/// One skipped or unreadable message, shown only in the in-memory summary
/// of the current scan (bank, date, reason; never text; CHK003).
class SkippedEntry extends Equatable {
  const SkippedEntry({required this.reason, this.bankId, this.receivedAt});

  final String? bankId;
  final DateTime? receivedAt;
  final SkipReason reason;

  @override
  List<Object?> get props => [bankId, receivedAt, reason];
}

/// Content-free result of one scan, catch-up or paste (data-model §2.9,
/// FR-024, FR-097). Held in memory for the summary only.
class ScanSummary extends Equatable {
  ScanSummary({
    this.scanned = 0,
    this.recognized = 0,
    this.createdPending = 0,
    this.ready = 0,
    this.needsReview = 0,
    this.alreadyKnown = 0,
    this.nonTransactional = 0,
    this.unreadable = 0,
    this.mutedSkipped = 0,
    this.cancelled = false,
    this.processedBeforeInterruption = 0,
    List<SkippedEntry> skipped = const [],
  }) : skipped = List.unmodifiable(skipped);

  final int scanned;
  final int recognized;
  final int createdPending;

  /// Created items with complete required fields.
  final int ready;

  /// Created items that are incomplete or Low.
  final int needsReview;
  final int alreadyKnown;
  final int nonTransactional;
  final int unreadable;
  final int mutedSkipped;
  final bool cancelled;
  final int processedBeforeInterruption;

  /// In-memory only; never persisted.
  final List<SkippedEntry> skipped;

  @override
  List<Object?> get props => [
    scanned,
    recognized,
    createdPending,
    ready,
    needsReview,
    alreadyKnown,
    nonTransactional,
    unreadable,
    mutedSkipped,
    cancelled,
    processedBeforeInterruption,
    skipped,
  ];
}

/// The result of a paste or share import (FR-017, FR-018).
class PasteImportResult extends Equatable {
  PasteImportResult({
    required this.summary,
    List<String> newIds = const [],
    this.notRecognized = false,
  }) : newIds = List.unmodifiable(newIds);

  final ScanSummary summary;

  /// Ids of the pending items this import created.
  final List<String> newIds;
  final bool notRecognized;

  @override
  List<Object?> get props => [summary, newIds, notRecognized];
}

/// FR-102 content-free counters.
class SmsImportCounts extends Equatable {
  const SmsImportCounts({
    this.scanned = 0,
    this.recognized = 0,
    this.added = 0,
    this.ignored = 0,
  });

  final int scanned;
  final int recognized;
  final int added;
  final int ignored;

  @override
  List<Object?> get props => [scanned, recognized, added, ignored];
}

/// Why a scan or catch-up did not run. A skip, not a failure.
enum ScanBlockReason {
  disabled,
  noPermission,
  alreadyRunning,
  locked,
  capabilityOff,

  /// A catch-up inside the 60-second debounce (FR-013).
  debounced,

  /// The app is not in the resumed state (FR-008a).
  notResumed,
}

/// The result of one automatic catch-up (FR-013).
sealed class CatchUpOutcome extends Equatable {
  const CatchUpOutcome();
}

/// The catch-up did not run.
class CatchUpSkipped extends CatchUpOutcome {
  const CatchUpSkipped(this.reason);

  final ScanBlockReason reason;

  @override
  List<Object?> get props => [reason];
}

/// The catch-up ran.
class CatchUpRan extends CatchUpOutcome {
  const CatchUpRan(this.summary);

  final ScanSummary summary;

  @override
  List<Object?> get props => [summary];
}

/// The catch-up started but a read or a store failed; it stopped there and
/// is retried at the next resume (FR-013). [failure] is a fixed,
/// content-free token; [summary] counts what was done before the failure
/// (those items are kept).
class CatchUpFailed extends CatchUpOutcome {
  const CatchUpFailed(this.failure, this.summary);

  final Failure failure;
  final ScanSummary summary;

  @override
  List<Object?> get props => [failure, summary];
}

/// The result of the enable flow: the permission status, and whether the
/// feature is now on (only when granted).
class EnableResult extends Equatable {
  const EnableResult({required this.status, required this.enabled});

  final SmsPermissionStatus status;
  final bool enabled;

  @override
  List<Object?> get props => [status, enabled];
}

/// The result of Undo: the message returns only after a re-scan, re-paste
/// or share (FR-067, FR-068).
class UndoResult extends Equatable {
  const UndoResult({this.needsRescan = true});

  final bool needsRescan;

  @override
  List<Object?> get props => [needsRescan];
}

/// The direction to render a text in, detected from its first strong
/// character (FR-091). A domain value, so the domain needs no Flutter type.
enum TextDirectionHint { ltr, rtl }

/// The masked original of a pending item, for "Show original" (FR-045).
class OriginalMessage extends Equatable {
  const OriginalMessage({required this.text, required this.direction});

  /// The masked text. Never logged, never in [toString].
  final String text;
  final TextDirectionHint direction;

  @override
  List<Object?> get props => [text, direction];

  @override
  String toString() =>
      'OriginalMessage(length: ${text.length}, direction: ${direction.name})';
}

/// Duplicate tiers, evaluated in the fixed FR-059b order.
enum DuplicateTier { none, exact, probable, legitimatelySimilar }

enum ExactBasis { fingerprint, bankReferenceAmountDirection }

enum ProbableBasis { savedRecord, pendingPair }

/// A saved record that may be the same money as a pending item (FR-060).
class DuplicateRecordRef extends Equatable {
  const DuplicateRecordRef({
    required this.id,
    required this.recordType,
    required this.type,
    required this.amount,
    required this.date,
    this.importProvenance,
    this.note,
  });

  final String id;
  final SavedRecordType recordType;

  /// The record's direction or type, as one of expense, income, given or
  /// received.
  final SuggestedRecordType type;
  final Money amount;

  /// Date-only.
  final DateTime date;

  /// `null` when the record was not imported.
  final ImportProvenance? importProvenance;

  /// The record's note, used only to rank candidates by similarity
  /// (FR-060). User data: never in [toString].
  final String? note;

  @override
  List<Object?> get props => [
    id,
    recordType,
    type,
    amount,
    date,
    importProvenance,
    note,
  ];

  /// Redacted: no amount or date.
  @override
  String toString() =>
      'DuplicateRecordRef(recordType: ${recordType.name}, '
      'type: ${type.name})';
}

/// The outcome of `CheckDuplicates` for one pending item (not persisted).
class DuplicateFinding extends Equatable {
  const DuplicateFinding({
    required this.tier,
    this.exactBasis,
    this.probableBasis,
    this.matchedPendingId,
    this.matchedRecord,
    this.possibleOwnTransfer = false,
  });

  static const DuplicateFinding none = DuplicateFinding(
    tier: DuplicateTier.none,
  );

  final DuplicateTier tier;
  final ExactBasis? exactBasis;
  final ProbableBasis? probableBasis;
  final String? matchedPendingId;
  final DuplicateRecordRef? matchedRecord;

  /// An opposite-direction item of the same amount and currency from a
  /// different bank or channel exists within one day (FR-051d).
  /// Informational only.
  final bool possibleOwnTransfer;

  bool get isProbable => tier == DuplicateTier.probable;

  @override
  List<Object?> get props => [
    tier,
    exactBasis,
    probableBasis,
    matchedPendingId,
    matchedRecord,
    possibleOwnTransfer,
  ];

  @override
  String toString() =>
      'DuplicateFinding(tier: ${tier.name}, '
      'exact: ${exactBasis?.name}, probable: ${probableBasis?.name}, '
      'ownTransfer: $possibleOwnTransfer)';
}

/// Saved records of both tables in a date window, indexed by
/// (currency, amount) for one ingestion page (`SmsDuplicateLookup.loadWindow`).
class SavedRecordWindow extends Equatable {
  SavedRecordWindow(List<DuplicateRecordRef> records)
    : records = List.unmodifiable(records);

  final List<DuplicateRecordRef> records;

  late final Map<Money, List<DuplicateRecordRef>> _byAmount = () {
    final index = <Money, List<DuplicateRecordRef>>{};
    for (final record in records) {
      (index[record.amount] ??= []).add(record);
    }
    return index;
  }();

  /// Records with exactly [amount] (same currency, same minor units).
  List<DuplicateRecordRef> withAmount(Money amount) =>
      _byAmount[amount] ?? const [];

  @override
  List<Object?> get props => [records];

  @override
  String toString() => 'SavedRecordWindow(records: ${records.length})';
}

/// A settings write the UI can make (`UpdateSmsImportPreferences`).
sealed class SmsPreferenceChange extends Equatable {
  const SmsPreferenceChange();
}

class ScanWindowChanged extends SmsPreferenceChange {
  const ScanWindowChanged(this.window);

  final ScanWindow window;

  @override
  List<Object?> get props => [window];
}

class CountCashChanged extends SmsPreferenceChange {
  const CountCashChanged(this.countCashWithdrawals);

  final bool countCashWithdrawals;

  @override
  List<Object?> get props => [countCashWithdrawals];
}

class OnboardingDismissed extends SmsPreferenceChange {
  const OnboardingDismissed();

  @override
  List<Object?> get props => const [];
}

/// What `ClearSmsImportData` clears. Tombstones are never cleared here.
enum ClearScope { pending, learnedMappings, mutedSenders }

/// Another staged or decided message that shares a keyed hash with a
/// pending item (exact tiers 1-2 and the tier-3 stop of FR-059b). Hashes
/// and codes only; no content.
class ImportKeyMatch extends Equatable {
  const ImportKeyMatch({
    required this.fingerprint,
    required this.bankId,
    this.pendingId,
    this.refHash,
    this.refAmountHash,
    this.occurredOn,
    this.outcome,
    this.savedRecordId,
    this.savedRecordType,
  });

  /// Set for another pending row; `null` for a tombstone.
  final String? pendingId;
  final String fingerprint;
  final String bankId;
  final String? refHash;
  final String? refAmountHash;

  /// The other row's date (pending rows only; a tombstone keeps no date).
  final DateTime? occurredOn;

  /// Set for a tombstone.
  final TombstoneOutcome? outcome;
  final String? savedRecordId;
  final SavedRecordType? savedRecordType;

  bool get isTombstone => pendingId == null;

  @override
  List<Object?> get props => [
    pendingId,
    fingerprint,
    bankId,
    refHash,
    refAmountHash,
    occurredOn,
    outcome,
    savedRecordId,
    savedRecordType,
  ];

  /// Redacted: no hash and no date.
  @override
  String toString() =>
      'ImportKeyMatch(tombstone: $isTombstone, bank: $bankId, '
      'outcome: ${outcome?.name})';
}
