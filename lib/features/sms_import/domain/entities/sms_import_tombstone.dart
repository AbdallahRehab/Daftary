import 'package:equatable/equatable.dart';

import 'sms_import_enums.dart';

/// The hashed memory of a decision on one message (data-model §3.2), so a
/// re-scan never resurfaces it (FR-059, FR-066).
///
/// Constraint: "No raw text, amount, merchant, name or digits". The type
/// holds only keyed hashes, the bank id, the outcome and the saved-record
/// reference, so there is no field that could carry any of them.
///
/// Constraint: "`purge_after >= created_at + 97 days`" (90-day maximum scan
/// window plus 7). Asserted in debug builds; [meetsRetention] lets the
/// repository check it before writing.
class SmsImportTombstone extends Equatable {
  SmsImportTombstone({
    required this.fingerprint,
    required this.outcome,
    required this.bankId,
    required this.createdAt,
    required this.purgeAfter,
    this.refHash,
    this.refAmountHash,
    this.savedRecordId,
    this.savedRecordType,
  }) {
    assert(meetsRetention, 'purgeAfter must be >= createdAt + 97 days');
  }

  /// The minimum tombstone lifetime (FR-066).
  static const Duration minimumRetention = Duration(days: 97);

  /// The earliest allowed [purgeAfter] for [createdAt].
  static DateTime minimumPurgeAfter(DateTime createdAt) =>
      createdAt.add(minimumRetention);

  /// Primary key (HMAC hex).
  final String fingerprint;
  final TombstoneOutcome outcome;
  final String bankId;

  /// Tier 3: both present and different -> legitimately similar.
  final String? refHash;

  /// Tier 2: same bank + reference + amount + direction. No plain amount is
  /// stored.
  final String? refAmountHash;

  /// Set for [TombstoneOutcome.added].
  final String? savedRecordId;
  final SavedRecordType? savedRecordType;
  final DateTime createdAt;
  final DateTime purgeAfter;

  bool get meetsRetention => !purgeAfter.isBefore(minimumPurgeAfter(createdAt));

  @override
  List<Object?> get props => [
    fingerprint,
    outcome,
    bankId,
    refHash,
    refAmountHash,
    savedRecordId,
    savedRecordType,
    createdAt,
    purgeAfter,
  ];

  /// Redacted: no hash is printed.
  @override
  String toString() =>
      'SmsImportTombstone(outcome: ${outcome.name}, bank: $bankId)';
}
