import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import 'parse_confidence.dart';
import 'sms_import_enums.dart';

/// An invariant of [PendingSmsImport] (data-model §3.1), named so a check
/// can report which rule failed without printing any value.
enum PendingImportInvariant {
  /// "`amountMinorUnits` > 0 and <= 12 whole digits when set".
  amountRange,

  /// "`merchant` <= 120 chars".
  merchantLength,

  /// "`counterparty` <= 120 chars".
  counterpartyLength,

  /// "`cardLast4` Exactly 4 digits".
  cardLast4Format,

  /// "`expiresAt` = `createdAt + 30 days`".
  expiresAt,

  /// "`timeMinutes`" in 0..1439 (data-model §4.1).
  timeMinutesRange,

  /// `savedRecordId` and `savedRecordType` are set together, and only when
  /// `status = added` (data-model §3.1).
  savedRecord,
}

/// A staged suggestion built from one bank message (data-model §3.1). It is
/// only a suggestion: nothing here is money until the user taps Add
/// (FR-052).
///
/// The entity never carries the sealed bytes or the plaintext: [hasRawText]
/// says whether a sealed original exists, and the original is read only
/// through `SmsImportRepository.openOriginal`.
///
/// `suggestedCategoryId`, `suggestedPersonId`, `savedRecordId` and
/// `parentImportId` are plain text with no foreign key.
///
/// The constraints are checked by [invariantViolations], which the
/// constructor asserts in debug builds. They are not thrown in release
/// builds, because a row read back from the database must never crash the
/// list; the repository checks [invariantViolations] before it writes.
class PendingSmsImport extends Equatable {
  PendingSmsImport({
    required this.id,
    required this.fingerprint,
    required this.status,
    required this.source,
    required this.bankId,
    required this.parserId,
    required this.ruleVersion,
    required this.kind,
    required this.direction,
    required this.suggestedType,
    required this.confidence,
    required this.createdAt,
    required this.expiresAt,
    required this.hasRawText,
    this.parentImportId,
    this.senderId,
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
    this.refHash,
    this.refAmountHash,
    this.receivedAt,
    this.decidedAt,
    this.savedRecordId,
    this.savedRecordType,
  }) : amountCandidates = List.unmodifiable(amountCandidates),
       warnings = Set.unmodifiable(warnings) {
    assert(
      invariantViolations.isEmpty,
      'PendingSmsImport invariants violated: '
      '${invariantViolations.map((v) => v.name).join(', ')}',
    );
  }

  /// How long a pending item lives (FR-025).
  static const Duration lifetime = Duration(days: 30);

  /// "`expiresAt` = `createdAt + 30 days`".
  static DateTime expiryFor(DateTime createdAt) => createdAt.add(lifetime);

  /// Largest whole-unit amount: 12 digits (FR-034, FR-044).
  static const int maxWholeUnits = 999999999999;

  /// "`merchant` <= 120 chars", "`counterparty` <= 120 chars".
  static const int maxNameLength = 120;

  static final RegExp _fourDigits = RegExp(r'^[0-9]{4}$');

  /// UUID v4; the idempotency key for Add is `sms-import:<id>` (FR-075a).
  final String id;

  /// Set only on a fee item split from its parent message (FR-030a).
  final String? parentImportId;

  /// HMAC-SHA256 hex over the frozen `FingerprintNormalizer` v1 output.
  /// Immutable.
  final String fingerprint;
  final SmsImportStatus status;

  /// Immutable.
  final SmsSource source;

  /// Canonical upper-case sender; `null` for paste and share (FR-020).
  final String? senderId;
  final String bankId;
  final String parserId;

  /// `'<profileId>@<n>'` (FR-032).
  final String ruleVersion;
  final SmsKind kind;
  final SmsDirection direction;

  /// `null` only when the currency is outside the catalog or two amount
  /// candidates are unresolved (FR-053, FR-030).
  final Money? amount;

  /// The one-tap choices when two non-fee candidates remain (FR-030).
  final List<int> amountCandidates;

  /// Read-only original-currency context (FR-053); never stored on the
  /// saved record.
  final String? foreignAmountText;

  /// The stated original-currency amount when that currency is in the
  /// catalog (FR-059), compared by the probable duplicate rule. Persisted
  /// inside `warnings_json` (data-model §4.1), never on the saved record.
  final Money? foreignAmount;

  /// Date-only local midnight; `null` for paste/share with no date (FR-038).
  final DateTime? occurredOn;

  /// Minutes since local midnight; display only (FR-058).
  final int? timeMinutes;
  final String? merchant;

  /// Normalized merchant used for learned-mapping lookup (FR-055).
  final String? merchantKey;
  final String? counterparty;

  /// Exactly four digits (FR-031).
  final String? cardLast4;
  final String? suggestedCategoryId;
  final String? suggestedPersonId;
  final SuggestedRecordType suggestedType;
  final ParseConfidence confidence;
  final Set<SmsWarning> warnings;

  /// Immutable keyed hashes.
  final String? refHash;
  final String? refAmountHash;

  /// Provider receipt time; `null` for paste/share. Immutable.
  final DateTime? receivedAt;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? decidedAt;

  /// Set only when `status = added`.
  final String? savedRecordId;
  final SavedRecordType? savedRecordType;

  /// Whether a sealed original exists (`raw_blob IS NOT NULL`).
  final bool hasRawText;

  bool get isPending => status == SmsImportStatus.pending;

  /// The idempotency key of the Add for this item (FR-075a).
  String get idempotencyKey => 'sms-import:$id';

  /// Every rule of data-model §3.1 this value breaks. Empty when valid.
  Set<PendingImportInvariant> get invariantViolations {
    final violations = <PendingImportInvariant>{};
    final money = amount;
    if (money != null &&
        (money.minorUnits <= 0 ||
            money.minorUnits ~/ money.currency.minorUnitsPerMajor >
                maxWholeUnits)) {
      violations.add(PendingImportInvariant.amountRange);
    }
    if ((merchant?.length ?? 0) > maxNameLength) {
      violations.add(PendingImportInvariant.merchantLength);
    }
    if ((counterparty?.length ?? 0) > maxNameLength) {
      violations.add(PendingImportInvariant.counterpartyLength);
    }
    final last4 = cardLast4;
    if (last4 != null && !_fourDigits.hasMatch(last4)) {
      violations.add(PendingImportInvariant.cardLast4Format);
    }
    if (expiresAt != expiryFor(createdAt)) {
      violations.add(PendingImportInvariant.expiresAt);
    }
    final minutes = timeMinutes;
    if (minutes != null && (minutes < 0 || minutes > 1439)) {
      violations.add(PendingImportInvariant.timeMinutesRange);
    }
    final hasSavedId = savedRecordId != null;
    final hasSavedType = savedRecordType != null;
    if (hasSavedId != hasSavedType ||
        (hasSavedId && status != SmsImportStatus.added)) {
      violations.add(PendingImportInvariant.savedRecord);
    }
    return violations;
  }

  @override
  List<Object?> get props => [
    id,
    parentImportId,
    fingerprint,
    status,
    source,
    senderId,
    bankId,
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
    refHash,
    refAmountHash,
    receivedAt,
    createdAt,
    expiresAt,
    decidedAt,
    savedRecordId,
    savedRecordType,
    hasRawText,
  ];

  /// Redacted: never prints an amount, a merchant, a name, digits, a
  /// sender or a hash (FR-097, FR-101).
  @override
  String toString() =>
      'PendingSmsImport(status: ${status.name}, source: ${source.name}, '
      'bank: $bankId, kind: ${kind.name}, '
      'overall: ${confidence.overall.name})';
}
