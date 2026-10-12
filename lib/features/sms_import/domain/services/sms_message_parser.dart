import 'package:equatable/equatable.dart';

import '../entities/parse_result.dart';
import '../entities/sms_import_enums.dart';

/// The rule-based bank-message parser (parser-contract §1). Pure,
/// deterministic, synchronous: no Flutter, no I/O, no network, no
/// randomness, no AI (NG4, FR-027, FR-081).
abstract class SmsMessageParser {
  /// Never throws: any internal exception becomes
  /// `Unreadable(UnreadableReason.parserError)` (FR-098).
  ParseResult parse(
    SmsParseInput input, {
    ParserOptions options = const ParserOptions(),
  });

  /// Rule versions currently shipped: `{profileId: version}`.
  Map<String, int> get currentVersions;

  /// The allow-list handed to the inbox query: union of profile senders,
  /// canonical upper-case, no spaces (FR-020).
  Set<String> get allowedSenders;
}

/// One message to parse.
class SmsParseInput extends Equatable {
  const SmsParseInput({
    required this.rawText,
    required this.source,
    this.sender,
    this.receivedAt,
  });

  /// As received; never persisted by the parser, never in [toString].
  final String rawText;

  /// `null` for paste and share.
  final String? sender;

  /// `null` for paste and share.
  final DateTime? receivedAt;
  final SmsSource source;

  @override
  List<Object?> get props => [rawText, sender, receivedAt, source];

  @override
  String toString() =>
      'SmsParseInput(source: ${source.name}, length: ${rawText.length})';
}

/// The user's settings and data the parser's suggestions read
/// (parser-contract §1, §8). Suggestions only; nothing is ever created.
class ParserOptions extends Equatable {
  const ParserOptions({
    this.countCashWithdrawals = false,
    this.learnedCategoryIds = const {},
    this.activeCategoryIdsBySeedKey = const {},
    this.activeCategoryIds = const {},
    this.peopleNames = const [],
  });

  /// FR-051b.
  final bool countCashWithdrawals;

  /// `(merchantKey, entryType dbValue)` -> category id (FR-056).
  final Map<(String, String), String> learnedCategoryIds;

  /// Stable seed key -> the user's current active category id. Archived or
  /// missing categories are absent, so they are never suggested (FR-055).
  final Map<String, String> activeCategoryIdsBySeedKey;

  /// Every active (not archived) category id. A learned mapping is
  /// suggested only when its id is here or among
  /// [activeCategoryIdsBySeedKey]; an archived or deleted mapping target is
  /// skipped (FR-055, FR-056).
  final Set<String> activeCategoryIds;

  /// Existing people, for an exact existing-name match only (FR-054).
  final List<PersonNameRef> peopleNames;

  @override
  List<Object?> get props => [
    countCashWithdrawals,
    learnedCategoryIds,
    activeCategoryIdsBySeedKey,
    activeCategoryIds,
    peopleNames,
  ];

  @override
  String toString() =>
      'ParserOptions(countCash: $countCashWithdrawals, '
      'learned: ${learnedCategoryIds.length}, '
      'people: ${peopleNames.length})';
}

/// An existing person's id and normalized name, for name matching only.
class PersonNameRef extends Equatable {
  const PersonNameRef({required this.id, required this.normalizedName});

  final String id;
  final String normalizedName;

  @override
  List<Object?> get props => [id, normalizedName];

  @override
  String toString() => 'PersonNameRef()';
}
