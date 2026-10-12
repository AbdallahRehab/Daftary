import '../../domain/entities/parse_result.dart';
import '../../domain/entities/sms_import_enums.dart';
import 'sms_text_normalizer.dart';

/// The language a rule is written for. Informational: a profile matches an
/// Arabic, English or mixed body regardless of the app locale (FR-091).
enum SmsLanguage { ar, en, any }

/// How a bank writes a numeric date (FR-036). All v1 profiles and the
/// generic profile use [dayMonth] (Egyptian convention).
enum DateOrder { dayMonth, monthDay }

/// One transaction template of a bank profile (parser-contract §2).
///
/// [pattern] runs on the FOLDED matching text (parser-contract §3, steps
/// 1-5: no bidi marks, single spaces, Western digits, folded Arabic,
/// lower-case Latin), so it must be written in that form. It uses named
/// groups, all optional except `amount`: `amount`, `currency`, `date`,
/// `time`, `merchant`, `counterparty`, `last4`, `ref`, `balance`, `fee`,
/// `feeCurrency`, `foreignAmount`, `foreignCurrency`. The `balance` group is
/// read only to be excluded and is never stored (FR-030, FR-031).
///
/// Rules for authors (enforced by tests): no nested quantifiers and no
/// unbounded alternation over `.*`; every pattern finishes on a
/// 10,000-character adversarial string in under 50 ms.
class SmsTemplate {
  SmsTemplate({
    required this.name,
    required this.kind,
    required this.direction,
    required this.language,
    required this.pattern,
    this.anchored = true,
    this.postsAtAuthorization = false,
  });

  /// A stable id for tests, e.g. `purchase_en_1`.
  final String name;
  final SmsKind kind;

  /// Fixed by the template: debit or credit.
  final SmsDirection direction;
  final SmsLanguage language;
  final RegExp pattern;

  /// `true` when `amount` is adjacent to the debit/credit/purchase verb:
  /// fields it captures are read at High confidence; otherwise Medium.
  final bool anchored;

  /// FR-024b: this bank sends its purchase message at authorization time,
  /// so the template is tried before the generic pending-authorization
  /// rule. Calibrated per bank on its corpus.
  final bool postsAtAuthorization;

  /// The named groups the engine reads.
  static const List<String> groupNames = [
    'amount',
    'currency',
    'date',
    'time',
    'merchant',
    'counterparty',
    'last4',
    'ref',
    'balance',
    'fee',
    'feeCurrency',
    'foreignAmount',
    'foreignCurrency',
  ];

  @override
  String toString() => 'SmsTemplate($name)';
}

/// Content that must match for a profile to be selected (FR-028).
/// Matched on the folded text.
class ContentSignature {
  ContentSignature(this.pattern, {this.language = SmsLanguage.any});

  final RegExp pattern;
  final SmsLanguage language;

  bool matches(String folded) => pattern.hasMatch(folded);
}

/// A profile-specific non-transactional rule (OTP, promotion, decline,
/// balance inquiry, pending authorization). Profile rules run before the
/// generic rules of the same step (parser-contract §5).
class NonTransactionalRule {
  NonTransactionalRule(this.reason, this.pattern);

  final NonTransactionalReason reason;

  /// Matched on the folded text.
  final RegExp pattern;
}

/// Keyword -> seeded category key (parser-contract §8, FR-055).
class MerchantKeywordRule {
  MerchantKeywordRule(this.keywords, this.categoryKey);

  final KeywordSet keywords;

  /// A stable seed key (`finance_category_seed.dart`), e.g. `restaurants`.
  final String categoryKey;
}

/// A set of phrases matched on folded text.
///
/// Phrases are written naturally and folded once, exactly as message text
/// is folded. A phrase edge that is a Latin letter or a digit must sit on a
/// word boundary (`hold` never matches `cardholder`); an Arabic edge may
/// carry attached prefixes and suffixes (`رصيد` matches `رصيدك`).
///
/// With [arabicWordStart], an Arabic start edge must begin a word or follow
/// only an attached clitic (`و`, `ف`, `ب`, `ل`, `ك`, `ال` and their
/// combinations), so `عرض` matches `العرض` but never `معرض`. With
/// [arabicWordEnd], an Arabic end edge must end the word, so `مدين` never
/// matches `مدينة`. Sets with different edge rules are combined with
/// [KeywordSet.merge].
///
/// Matching is a linear substring search: no regular expression.
class KeywordSet {
  KeywordSet(
    Iterable<String> phrases, {
    bool arabicWordStart = false,
    bool arabicWordEnd = false,
  }) : this._(
         List.unmodifiable(
           phrases.map(SmsTextNormalizerImpl.fold).where((p) => p.isNotEmpty),
         ),
         arabicWordStart,
         arabicWordEnd,
       );

  KeywordSet._(
    this.phrases,
    bool arabicWordStart,
    bool arabicWordEnd, [
    List<KeywordSet> parts = const [],
  ]) : _arabicWordStart = arabicWordStart,
       _arabicWordEnd = arabicWordEnd,
       _parts = parts;

  /// The union of [sets], each keeping its own edge rules.
  factory KeywordSet.merge(List<KeywordSet> sets) => KeywordSet._(
    List.unmodifiable([for (final s in sets) ...s.phrases]),
    false,
    false,
    List.unmodifiable(sets),
  );

  /// The folded phrases.
  final List<String> phrases;

  final bool _arabicWordStart;
  final bool _arabicWordEnd;

  /// Non-empty for a [KeywordSet.merge] union.
  final List<KeywordSet> _parts;

  bool matches(String folded) => firstHit(folded) != null;

  /// The earliest hit, or `null`.
  KeywordHit? firstHit(String folded) {
    KeywordHit? best;
    for (final hit in hits(folded)) {
      if (best == null || hit.start < best.start) best = hit;
    }
    return best;
  }

  /// Every hit of every phrase, in no particular order.
  Iterable<KeywordHit> hits(String folded) sync* {
    if (_parts.isNotEmpty) {
      for (final part in _parts) {
        yield* part.hits(folded);
      }
      return;
    }
    for (final phrase in phrases) {
      var from = 0;
      while (from <= folded.length - phrase.length) {
        final index = folded.indexOf(phrase, from);
        if (index < 0) break;
        final end = index + phrase.length;
        if (_bounded(folded, index, end, phrase)) {
          yield KeywordHit(index, end, phrase);
        }
        from = index + 1;
      }
    }
  }

  bool _bounded(String text, int start, int end, String phrase) {
    final first = phrase.codeUnitAt(0);
    final last = phrase.codeUnitAt(phrase.length - 1);
    if (_isWordUnit(first) &&
        start > 0 &&
        _isWordUnit(text.codeUnitAt(start - 1))) {
      return false;
    }
    if (_isWordUnit(last) &&
        end < text.length &&
        _isWordUnit(text.codeUnitAt(end))) {
      return false;
    }
    if (_arabicWordStart &&
        isArabicLetter(first) &&
        !_arabicStartOk(text, start)) {
      return false;
    }
    if (_arabicWordEnd &&
        isArabicLetter(last) &&
        end < text.length &&
        isArabicLetter(text.codeUnitAt(end))) {
      return false;
    }
    return true;
  }

  /// Attached clitics that may precede an Arabic word (folded forms).
  static const Set<String> _clitics = {
    'و', 'ف', 'ب', 'ل', 'ك', 'ال', 'وال', 'فال', 'بال', 'كال', 'لل', //
    'ولل', 'فلل', 'وب', 'فب', 'ول', 'فل', 'وك',
  };

  /// The Arabic letters directly before [start] are empty or a clitic.
  static bool _arabicStartOk(String text, int start) {
    var i = start;
    while (i > 0 && isArabicLetter(text.codeUnitAt(i - 1))) {
      i--;
      if (start - i > 3) return false;
    }
    return i == start || _clitics.contains(text.substring(i, start));
  }

  /// An Arabic letter (U+0621-U+064A) in folded text.
  static bool isArabicLetter(int unit) => unit >= 0x0621 && unit <= 0x064A;

  /// Latin letter (folded text is lower-case) or ASCII digit.
  static bool _isWordUnit(int unit) =>
      (unit >= 0x61 && unit <= 0x7A) ||
      (unit >= 0x30 && unit <= 0x39) ||
      (unit >= 0xDF && unit <= 0x24F);
}

/// One keyword occurrence in folded text: `[start, end)`.
class KeywordHit {
  const KeywordHit(this.start, this.end, this.phrase);

  final int start;
  final int end;
  final String phrase;
}
