import '../../../domain/entities/sms_import_enums.dart';
import '../bank_profile.dart';
import '../sms_text_normalizer.dart';

/// Shared building blocks for the bank profiles (parser-contract §2).
///
/// A template source is written naturally, in Arabic or English, with
/// placeholders for the named groups. [compile] folds the whole source
/// exactly as message text is folded (Arabic letter forms, lower-case
/// Latin; parser-contract §3) and then substitutes the placeholders, so a
/// source must never use an upper-case regex escape (`\D`, `\S`, `\W`,
/// `\B`): folding would lower-case it.
///
/// Placeholders:
/// - `{amount}`, `{fee}`: a money token. Bounded and free of nested
///   quantifiers. A malformed token (`100,50`, `1.234,50`) is captured
///   whole, so the engine reports it as unreadable instead of reading a
///   shorter, wrong number (orchestrator decision CHK045);
/// - `{currency}`, `{feeCurrency}`: a currency marker of the app catalog;
/// - `{date}`, `{time}`: a numeric date (year optional) and a clock time;
/// - `{merchant}`, `{counterparty}`: a lazy name of 1-60 characters;
///   always follow it with a literal or with `{end}`;
/// - `{last4}`: four digits, optionally after a mask (`****`, `XX`, `•`);
/// - `{ref}`: a reference token;
/// - `{end}`: the end of a sentence (`. `, `,`, `;`, `،` or the end).
///
/// Every profile built with this kit is SYNTHETIC: modeled on generic,
/// public bank-SMS phrasing, never on a real message, and `verified:
/// false` until the owner provides real anonymized samples (OQ2/OQ3).
class SmsTemplateKit {
  const SmsTemplateKit._();

  static String _money(String name) =>
      '(?<$name>\\d{1,3}(?: \\d{3}){1,4}(?:\\.\\d{1,3})?(?![\\d,])'
      '|\\d(?:[\\d,.]{0,20}\\d)?)';

  static const String _currencyAlternation =
      r'egp|usd|eur|gbp|sar|aed|l\.e\.?|le|جنيه مصري|جنيها|جنيه|ج\.م\.?|'
      r'دولار|يورو';

  static String _currency(String name) =>
      '(?<$name>$_currencyAlternation)(?![a-zء-ي])';

  static String _name(String name) => '(?<$name>[^ ,;.،][^,;،]{0,59}?)';

  static final Map<String, String> _placeholders = {
    '{amount}': _money('amount'),
    '{fee}': _money('fee'),
    '{currency}': _currency('currency'),
    // Folding lower-cases the source, so the key is the folded form.
    '{feecurrency}': _currency('feeCurrency'),
    '{date}':
        r'(?<date>\d{1,2}[/\-.]\d{1,2}(?:[/\-.](?:\d{4}|\d{2}))?)'
        r'(?![\d/])',
    '{time}':
        '(?<time>\\d{1,2}:\\d{2}(?: ?(?:am|pm|ص|م)'
        '(?![a-zء-ي]))?)',
    '{merchant}': _name('merchant'),
    '{counterparty}': _name('counterparty'),
    '{last4}': r'(?:[x*•#]{2,12}|\.{2,4})?(?<last4>\d{4})(?!\d)',
    '{ref}': r'(?<ref>[a-z0-9][a-z0-9\-]{3,29})(?![a-z0-9\-])',
    '{end}': '(?=\\.(?: |\$)|[,;،]|\$)',
  };

  /// Folds [source] and substitutes its placeholders.
  static RegExp compile(String source) {
    var pattern = SmsTextNormalizerImpl.foldWithMap(source).forMatching;
    _placeholders.forEach((key, value) {
      pattern = pattern.replaceAll(key, value);
    });
    assert(!pattern.contains(RegExp(r'\{[a-z][a-z0-9]*\}')), 'placeholder');
    return RegExp(pattern);
  }

  /// One template from a natural-language [source].
  static SmsTemplate template(
    String name,
    SmsKind kind,
    SmsDirection direction,
    SmsLanguage language,
    String source,
  ) => SmsTemplate(
    name: name,
    kind: kind,
    direction: direction,
    language: language,
    pattern: compile(source),
  );

  /// A content signature: one of [names] as a whole word, followed by an
  /// optional colon or comma, one space and a letter. A bare sender line
  /// (`NBE`, `NBE 10/03/2026`) therefore never matches, so the paste
  /// envelope rules can still strip it (safety rule 2,
  /// `SmsEnvelopeRules.isProtected`). With [atStart] the name must open
  /// the message (InstaPay, whose name appears inside other banks'
  /// messages).
  static ContentSignature signature(
    List<String> names, {
    bool atStart = false,
  }) {
    final alternation = names
        .map((n) => RegExp.escape(SmsTextNormalizerImpl.fold(n)))
        .join('|');
    final lead = atStart ? '^' : '(?:^|(?<![a-z0-9ء-ي]))';
    return ContentSignature(RegExp('$lead(?:$alternation)[:,،]? [a-zء-ي]'));
  }

  /// Every pattern of [profile], for the backtracking guard tests.
  static List<RegExp> patternsOf(BankProfile profile) => [
    for (final t in profile.templates) t.pattern,
    for (final s in profile.signatures) s.pattern,
  ];
}

/// Shorthands used by the profile files.
const SmsDirection debit = SmsDirection.debit;
const SmsDirection credit = SmsDirection.credit;
const SmsLanguage en = SmsLanguage.en;
const SmsLanguage ar = SmsLanguage.ar;
