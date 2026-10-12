import 'package:equatable/equatable.dart';

import '../../../people/domain/usecases/find_possible_duplicate_person.dart';
import '../../domain/entities/sms_import_enums.dart';
import '../../domain/services/sms_message_parser.dart';
import 'generic_profile.dart';
import 'sms_template.dart';

/// The suggested record type, category and person for one message
/// (parser-contract §8). Suggestions only: the user decides in review
/// (FR-051). Never creates a record, category or person.
class SmsSuggestion extends Equatable {
  SmsSuggestion({
    required this.type,
    this.categoryId,
    this.personId,
    Set<SmsWarning> warnings = const {},
  }) : warnings = Set.unmodifiable(warnings);

  final SuggestedRecordType type;

  /// A resolved, active category id of the matching type, or `null`.
  final String? categoryId;

  /// Set only on exactly one existing-name match of a named transfer
  /// (FR-054). It never changes [type]: the review offers the one-tap
  /// Given/Received with this person pre-selected.
  final String? personId;
  final Set<SmsWarning> warnings;

  @override
  List<Object?> get props => [type, categoryId, personId, warnings];

  @override
  String toString() =>
      'SmsSuggestion(${type.name}, category: ${categoryId != null}, '
      'person: ${personId != null})';
}

/// The mapping table of parser-contract §8. Pure.
///
/// Category resolution (FR-055): (a) the learned mapping for
/// `(merchantKey, type)` when its category is still active; (b) the
/// profile's then the shared merchant keyword rules (bill keywords for a
/// bill payment); (c) the seed key (`other`, `other_income`, `salary`).
/// Seeds resolve by stable key through
/// [ParserOptions.activeCategoryIdsBySeedKey]; an archived or missing
/// category is never suggested and falls to the next step, and with no
/// active category of the type no category is suggested.
///
/// [matchText] is the folded message text, used for bill keywords.
/// [source] is accepted for the contract signature; no rule depends on it.
SmsSuggestion suggestFor({
  required SmsKind kind,
  required SmsDirection direction,
  required SmsSource source,
  required ParserOptions options,
  String? merchantKey,
  String? counterparty,
  String matchText = '',
  List<MerchantKeywordRule> profileKeywordRules = const [],
}) {
  final rules = GenericRules.instance;

  String? learned(String type) {
    if (merchantKey == null || merchantKey.isEmpty) return null;
    final id = options.learnedCategoryIds[(merchantKey, type)];
    if (id == null) return null;
    final active =
        options.activeCategoryIds.contains(id) ||
        options.activeCategoryIdsBySeedKey.containsValue(id);
    return active ? id : null;
  }

  String? seed(String key) => options.activeCategoryIdsBySeedKey[key];

  String? keyword(List<MerchantKeywordRule> table, String text) {
    if (text.isEmpty) return null;
    for (final rule in table) {
      if (!rule.keywords.matches(text)) continue;
      final id = seed(rule.categoryKey);
      if (id != null) return id;
    }
    return null;
  }

  String? merchantCategory() =>
      keyword(profileKeywordRules, merchantKey ?? '') ??
      keyword(rules.merchantKeywordRules, merchantKey ?? '');

  SmsSuggestion expense({
    String? categoryId,
    Set<SmsWarning> warnings = const {},
  }) => SmsSuggestion(
    type: SuggestedRecordType.expense,
    categoryId: categoryId ?? seed('other'),
    warnings: warnings,
  );

  SmsSuggestion ignore(SmsWarning warning) =>
      SmsSuggestion(type: SuggestedRecordType.ignore, warnings: {warning});

  switch (kind) {
    case SmsKind.cardPurchase:
      return expense(categoryId: learned('expense') ?? merchantCategory());
    case SmsKind.atmWithdrawal:
      if (options.countCashWithdrawals) {
        return expense(categoryId: learned('expense'));
      }
      return ignore(SmsWarning.atmIgnoredByDefault);
    case SmsKind.cardOrLoanSettlement:
      return ignore(SmsWarning.cardSettlementSuggestedIgnore);
    case SmsKind.billPayment:
      return expense(
        categoryId:
            learned('expense') ??
            keyword(rules.billKeywordRules, merchantKey ?? '') ??
            keyword(rules.billKeywordRules, matchText),
      );
    case SmsKind.fee:
      return expense(
        categoryId: learned('expense'),
        warnings: {SmsWarning.feeSeparateItem},
      );
    case SmsKind.salary:
      return SmsSuggestion(
        type: SuggestedRecordType.income,
        categoryId: learned('income') ?? seed('salary'),
      );
    case SmsKind.otherDeposit:
      return SmsSuggestion(type: SuggestedRecordType.unset);
    case SmsKind.transferOut:
      // A named transfer defaults to Expense (FR-051a, US7-1). On exactly
      // one existing-name match the person is pre-selected for the review's
      // one-tap "Record as Given" (FR-054); the type stays Expense.
      return SmsSuggestion(
        type: SuggestedRecordType.expense,
        categoryId: learned('expense') ?? seed('other'),
        personId: _personMatch(counterparty, options),
      );
    case SmsKind.transferIn:
      // Income by default (FR-051a, US7-1), with a one-tap "Record as
      // Received" when exactly one existing person matches (FR-054).
      return SmsSuggestion(
        type: SuggestedRecordType.income,
        categoryId: learned('income') ?? seed('other_income'),
        personId: _personMatch(counterparty, options),
      );
    case SmsKind.refund:
      return ignore(SmsWarning.refundHint);
    case SmsKind.authorizationReversal:
      return ignore(SmsWarning.reversalHint);
    case SmsKind.ownAccountTransfer:
      return ignore(SmsWarning.ownAccountSuggestedIgnore);
    case SmsKind.unknown:
      if (direction == SmsDirection.debit) {
        return expense(categoryId: learned('expense'));
      }
      return SmsSuggestion(type: SuggestedRecordType.unset);
  }
}

/// The id of the one existing person whose normalized name equals the
/// counterparty's; `null` for none or several (FR-054). Name-based only,
/// never by phone; never creates a person.
String? _personMatch(String? counterparty, ParserOptions options) {
  if (counterparty == null) return null;
  final name = FindPossibleDuplicatePerson.normalize(counterparty);
  if (name.isEmpty) return null;
  final matches = {
    for (final person in options.peopleNames)
      if (person.normalizedName == name) person.id,
  };
  return matches.length == 1 ? matches.single : null;
}
