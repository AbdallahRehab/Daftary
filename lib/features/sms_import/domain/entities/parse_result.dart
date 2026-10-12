import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import 'parse_confidence.dart';
import 'sms_import_enums.dart';

/// Why a message was recognized but carries no transaction (FR-024).
enum NonTransactionalReason {
  otp,
  promotion,
  balanceInquiry,
  declined,
  pendingAuthorization,
  other,
}

/// Why a message could not be read (FR-039a, FR-098).
enum UnreadableReason {
  noAmount,
  amountUnreadable,
  tooLong,
  empty,
  nonText,
  parserError,
}

/// The outcome of parsing one message (parser-contract §4).
///
/// Only [ParsedTransaction] can become a pending item. The other outcomes
/// are counted and nothing is stored (FR-024, FR-039a).
sealed class ParseResult extends Equatable {
  const ParseResult();
}

/// A recognized transaction message.
///
/// It never carries the balance, a full account or card number, or an OTP
/// (FR-031, FR-077): the parser consumes those and drops them. The one
/// transient sensitive value is [referenceId], which exists only so the
/// ingestion pipeline can compute the reference hashes in the same call; it
/// is never persisted or logged.
class ParsedTransaction extends ParseResult {
  ParsedTransaction({
    required this.bankId,
    required this.parserId,
    required this.ruleVersion,
    required this.kind,
    required this.direction,
    required this.suggestedType,
    required this.confidence,
    this.amount,
    List<int> amountCandidatesMinor = const [],
    this.currencyCodeRead,
    this.occurredOn,
    this.timeMinutes,
    this.merchant,
    this.merchantKey,
    this.counterparty,
    this.cardLast4,
    this.referenceId,
    this.foreignAmountText,
    this.fee,
    this.foreignAmount,
    this.suggestedCategoryKeyOrId,
    this.suggestedPersonId,
    Set<SmsWarning> warnings = const {},
  }) : amountCandidatesMinor = List.unmodifiable(amountCandidatesMinor),
       warnings = Set.unmodifiable(warnings);

  /// The winning profile id, or `'generic'`.
  final String bankId;

  /// Equal to [bankId] of the winning profile.
  final String parserId;

  /// `'<profileId>@<n>'` (FR-032).
  final String ruleVersion;
  final SmsKind kind;
  final SmsDirection direction;

  /// `null` only when the currency is outside the catalog or two amount
  /// candidates remain (parser-contract §5).
  final Money? amount;

  /// Empty unless the amount is ambiguous (FR-030).
  final List<int> amountCandidatesMinor;

  /// The currency as read, even when outside the catalog (FR-053).
  final String? currencyCodeRead;

  /// Date-only local; `null` for paste/share with no date (FR-038).
  final DateTime? occurredOn;

  /// Minutes since local midnight (FR-058).
  final int? timeMinutes;
  final String? merchant;

  /// Normalized merchant for learned-mapping lookup (FR-055).
  final String? merchantKey;
  final String? counterparty;

  /// The last four digits only (FR-031).
  final String? cardLast4;

  /// TRANSIENT: only to compute the reference hashes. Never persisted,
  /// never logged, never in [toString].
  final String? referenceId;

  /// Original-currency context, display only (FR-053).
  final String? foreignAmountText;

  /// An in-message fee, staged as its own pending item (FR-030a).
  final Money? fee;

  /// The original-currency amount when stated and in the catalog (FR-059).
  final Money? foreignAmount;
  final SuggestedRecordType suggestedType;

  /// The resolved active category id, else `null`.
  final String? suggestedCategoryKeyOrId;
  final String? suggestedPersonId;
  final ParseConfidence confidence;
  final Set<SmsWarning> warnings;

  @override
  List<Object?> get props => [
    bankId,
    parserId,
    ruleVersion,
    kind,
    direction,
    amount,
    amountCandidatesMinor,
    currencyCodeRead,
    occurredOn,
    timeMinutes,
    merchant,
    merchantKey,
    counterparty,
    cardLast4,
    referenceId,
    foreignAmountText,
    fee,
    foreignAmount,
    suggestedType,
    suggestedCategoryKeyOrId,
    suggestedPersonId,
    confidence,
    warnings,
  ];

  /// Redacted: never prints an amount, a name, a merchant, digits or the
  /// reference (FR-097, FR-101).
  @override
  String toString() =>
      'ParsedTransaction(bank: $bankId, kind: ${kind.name}, '
      'direction: ${direction.name}, '
      'overall: ${confidence.overall.name})';
}

/// Recognized as a bank message, but not a transaction: an OTP, a
/// promotion, a balance inquiry, a decline or a pending authorization.
class NonTransactional extends ParseResult {
  const NonTransactional(this.reason, {this.bankId});

  final NonTransactionalReason reason;

  /// For per-bank counts only.
  final String? bankId;

  @override
  List<Object?> get props => [reason, bankId];

  @override
  String toString() => 'NonTransactional(${reason.name})';
}

/// The text is not a bank message at all: no profile signature and no
/// generic debit/credit vocabulary matched. Counted only; for paste and
/// share it drives "not recognized" (FR-018).
class NotRecognized extends ParseResult {
  const NotRecognized();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => 'NotRecognized()';
}

/// Recognized but unreadable: counted, nothing stored, "could not read,
/// enter manually" for paste/share (FR-039a).
class Unreadable extends ParseResult {
  const Unreadable(this.reason, {this.bankId});

  final UnreadableReason reason;
  final String? bankId;

  @override
  List<Object?> get props => [reason, bankId];

  @override
  String toString() => 'Unreadable(${reason.name})';
}
