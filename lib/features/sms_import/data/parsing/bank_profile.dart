import 'sms_template.dart';

export 'sms_template.dart';

/// One bank's rule set (parser-contract §2, research Decision 8).
///
/// One Dart object per bank, registered in `SmsParserRegistry` as an
/// ordered list (order is the final tie-break), plus the generic profile.
/// Regexes are compiled once. Not JSON assets.
///
/// A rule change requires a [version] bump; the corpus test pins
/// `currentVersions` against `test/fixtures/sms/_versions.json`.
class BankProfile {
  BankProfile({
    required this.id,
    required this.version,
    this.senders = const {},
    this.signatures = const [],
    this.templates = const [],
    this.nonTransactionalRules = const [],
    this.merchantKeywordRules = const [],
    this.ownAccountKeywords = const [],
    this.cardSettlementKeywords = const [],
    this.messageStart,
    int maskThreshold = defaultMaskThreshold,
    this.defaultCurrency,
    this.dateOrder = DateOrder.dayMonth,
    this.isGeneric = false,
    this.refIsUnique = false,
    this.verified = false,
  }) : maskThreshold = maskThreshold > defaultMaskThreshold
           ? defaultMaskThreshold
           : maskThreshold;

  /// The masking threshold default; a profile may lower it, never raise it
  /// (research Decision 7).
  static const int defaultMaskThreshold = 12;

  /// `nbe` | `banque_misr` | `cib` | `qnb` | `banque_du_caire` | `aaib` |
  /// `instapay` | `generic`.
  final String id;

  /// Bumped on any rule change.
  final int version;

  /// `'<id>@<version>'`, stored on the pending row (FR-032).
  String get ruleVersion => '$id@$version';

  /// Canonical sender IDs (upper-case, no spaces): the per-bank allow-list
  /// (FR-020). Empty only for the generic profile.
  final Set<String> senders;

  /// The content must match at least one to select this profile.
  final List<ContentSignature> signatures;

  /// Transaction templates, tried in order.
  final List<SmsTemplate> templates;

  /// Profile-specific OTP, promotion, decline, balance and pending rules.
  final List<NonTransactionalRule> nonTransactionalRules;

  /// Keyword -> seeded category key.
  final List<MerchantKeywordRule> merchantKeywordRules;

  /// Own-account and savings movements: explicit keywords only (FR-051c).
  final List<KeywordSet> ownAccountKeywords;

  /// Credit-card payment, installment, conversion, loan settlement.
  final List<KeywordSet> cardSettlementKeywords;

  /// Optional: a line prefix that begins a new message (paste splitter).
  final RegExp? messageStart;

  /// Digit groups of at least this many digits are masked (<= 12).
  final int maskThreshold;

  /// `'EGP'` for Egyptian banks; `null` for generic. A default currency is
  /// always marked inferred (`currencyInferred`).
  final String? defaultCurrency;
  final DateOrder dateOrder;

  /// Caps every field at Medium; never High (FR-041).
  final bool isGeneric;

  /// `true` only when the bank's reference IDs are unique per transaction
  /// (verified on the corpus); `false` makes duplicate tier 2 also require
  /// a date within one day (FR-059b). Generic: `false`.
  final bool refIsUnique;

  /// `true` only after the rules were checked against real (anonymized)
  /// samples from the owner (OQ2/OQ3). An unverified bank profile caps the
  /// overall confidence at Medium and adds `SmsWarning.unverifiedProfile`
  /// (orchestrator decision). Not applicable to the generic profile, which
  /// is capped at Medium anyway.
  final bool verified;

  @override
  String toString() => 'BankProfile($ruleVersion)';
}
