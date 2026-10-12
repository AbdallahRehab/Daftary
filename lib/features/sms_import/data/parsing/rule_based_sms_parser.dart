import '../../../../core/confidence/field_confidence.dart';
import '../../../../core/date/app_clock.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/parse_confidence.dart';
import '../../domain/entities/parse_result.dart';
import '../../domain/entities/sms_import_enums.dart';
import '../../domain/rules/overall_confidence.dart';
import '../../domain/services/sms_message_parser.dart';
import 'bank_profile.dart';
import 'generic_profile.dart';
import 'select_parse.dart';
import 'sms_amount_reader.dart';
import 'sms_currency_table.dart';
import 'sms_date_reader.dart';
import 'sms_parser_registry.dart';
import 'sms_text_normalizer.dart';
import 'suggest_for.dart';

/// The rule-based bank-message parser (parser-contract §1-§8).
///
/// Pure Dart, deterministic and synchronous: no Flutter, no I/O, no
/// network, no randomness, no AI (FR-027). Time comes only from the
/// injected [AppClock]. [parse] never throws: any internal error becomes
/// `Unreadable(parserError)` (FR-098). Nothing here logs, and no result,
/// exception or `toString` carries message content.
///
/// Every regular expression is bounded and free of nested quantifiers;
/// keyword matching is a linear substring search.
class RuleBasedSmsParser implements SmsMessageParser {
  RuleBasedSmsParser({required AppClock clock, SmsParserRegistry? registry})
    : _clock = clock,
      registry = registry ?? SmsParserRegistry.standard;

  final AppClock _clock;
  final SmsParserRegistry registry;

  /// A single message longer than this is `Unreadable(tooLong)`.
  static const int maxMessageLength = 4000;

  /// Merchant and counterparty display text is capped at this length.
  static const int maxNameLength = 120;

  static const _normalizer = SmsTextNormalizerImpl();

  @override
  Map<String, int> get currentVersions => registry.currentVersions;

  @override
  Set<String> get allowedSenders => registry.allowedSenders;

  @override
  ParseResult parse(
    SmsParseInput input, {
    ParserOptions options = const ParserOptions(),
  }) {
    try {
      return _parse(input, options);
    } catch (_) {
      // Contained per message (FR-098). The error is never inspected,
      // logged or rethrown: it may carry message text.
      return const Unreadable(UnreadableReason.parserError);
    }
  }

  ParseResult _parse(SmsParseInput input, ParserOptions options) {
    final raw = input.rawText;
    if (raw.length > maxMessageLength) {
      return const Unreadable(UnreadableReason.tooLong);
    }
    if (_isNonText(raw)) return const Unreadable(UnreadableReason.nonText);
    final text = _normalizer.normalizeWithMap(raw);
    if (text.forDisplay.isEmpty) {
      return const Unreadable(UnreadableReason.empty);
    }
    final message = _Message(input, options, text, _clock.now());
    return selectParse(
      registry: registry,
      sender: input.sender,
      folded: text.forMatching,
      parseWith: (profile) => _parseWith(profile, message),
    );
  }

  /// Eligibility in the fixed order of parser-contract §5; profile rules
  /// run before the generic rules of the same step.
  ParseResult _parseWith(BankProfile profile, _Message m) {
    final f = m.folded;
    final g = m.signals;
    NonTransactional nt(NonTransactionalReason reason) =>
        NonTransactional(reason, bankId: profile.id);
    bool rule(NonTransactionalReason reason) => profile.nonTransactionalRules
        .any((r) => r.reason == reason && r.pattern.hasMatch(f));

    // 1. OTP wins over everything.
    if (rule(NonTransactionalReason.otp) ||
        g.otp ||
        (g.otpWeak && _hasStandaloneCode(m))) {
      return nt(NonTransactionalReason.otp);
    }
    // 2. Declined or failed.
    // A posted refund of a failed transaction is a refund, not a decline.
    final postedRefund = (g.refund || g.reversal) && g.refundPosted;
    if (rule(NonTransactionalReason.declined) ||
        (g.declined && !postedRefund)) {
      return nt(NonTransactionalReason.declined);
    }
    // 3. Pending authorization; a bank whose purchases post at
    //    authorization time matches its own template first (FR-024b).
    if (rule(NonTransactionalReason.pendingAuthorization)) {
      return nt(NonTransactionalReason.pendingAuthorization);
    }
    for (final t in profile.templates.where((t) => t.postsAtAuthorization)) {
      final result = _tryTemplate(profile, t, m);
      if (result != null) return result;
    }
    if (g.pending && !g.posted && !g.reversal && !g.refund) {
      return nt(NonTransactionalReason.pendingAuthorization);
    }
    // 4. Authorization reversal (refund wins when in doubt).
    if (g.reversal && !g.refund) {
      for (final t in profile.templates.where(
        (t) => t.kind == SmsKind.authorizationReversal,
      )) {
        final result = _tryTemplate(profile, t, m);
        if (result != null) return result;
      }
      if (profile.isGeneric) {
        return _generic(profile, m, forcedKind: SmsKind.authorizationReversal);
      }
      return Unreadable(UnreadableReason.noAmount, bankId: profile.id);
    }
    // 5. Promotion: marketing words with no posted verb; a link or a soft
    //    word only when no transaction kind matched either.
    if (rule(NonTransactionalReason.promotion) ||
        (!g.posted &&
            (g.promotion || (g.promotionWeak && g.kindRule == null)))) {
      return nt(NonTransactionalReason.promotion);
    }
    // 5b. Statement, due-date or installment reminder with no posted verb.
    if (g.dueReminder && !g.posted) {
      return nt(NonTransactionalReason.other);
    }
    // 6. Balance inquiry.
    if (rule(NonTransactionalReason.balanceInquiry) ||
        (g.balance && !g.posted && g.kindRule == null)) {
      return nt(NonTransactionalReason.balanceInquiry);
    }
    // 7-8. Templates (refund templates included).
    if (!profile.isGeneric) {
      for (final t in profile.templates) {
        if (t.postsAtAuthorization) continue;
        final result = _tryTemplate(profile, t, m);
        if (result != null) return result;
      }
      return Unreadable(UnreadableReason.noAmount, bankId: profile.id);
    }
    // 9-10. Generic extraction.
    return _generic(profile, m);
  }

  // --- Templates -----------------------------------------------------------

  ParseResult? _tryTemplate(BankProfile profile, SmsTemplate t, _Message m) {
    final match = t.pattern.firstMatch(m.folded);
    if (match == null) return null;
    final amountText = _group(match, 'amount');
    if (amountText == null || amountText.isEmpty) return null;
    final level = t.anchored
        ? FieldConfidenceLevel.high
        : FieldConfidenceLevel.medium;
    final d = _Draft(kind: t.kind, direction: t.direction, level: level);

    // Kind refinement by the profile's explicit keyword lists (FR-051c).
    if ((t.kind == SmsKind.transferOut || t.kind == SmsKind.transferIn) &&
        profile.ownAccountKeywords.any((k) => k.matches(m.folded))) {
      d.kind = SmsKind.ownAccountTransfer;
    } else if (t.direction == SmsDirection.debit &&
        profile.cardSettlementKeywords.any((k) => k.matches(m.folded))) {
      d.kind = SmsKind.cardOrLoanSettlement;
    }

    // Amount and currency.
    final currencyText = _group(match, 'currency');
    String? code;
    if (currencyText != null) {
      code = SmsCurrencyTable.codeFor(currencyText);
      d.currencyLevel = level;
    } else if (profile.defaultCurrency != null) {
      code = profile.defaultCurrency;
      d.currencyInferred = true;
    }
    final amountFailure = _setAmount(
      d,
      amountText.trim(),
      code,
      level,
      profile,
    );
    if (amountFailure != null) return amountFailure;

    // Fee (FR-030a) and foreign amount (FR-059).
    final feeText = _group(match, 'fee');
    if (feeText != null) {
      final feeCode =
          SmsCurrencyTable.codeFor(_group(match, 'feeCurrency') ?? '') ?? code;
      final currency = SmsCurrencyTable.catalogCurrency(feeCode);
      if (currency != null) d.fee = SmsAmountReader.parse(feeText, currency);
    }
    final foreignText = _group(match, 'foreignAmount');
    final foreignCurrencyText = _group(match, 'foreignCurrency');
    if (foreignText != null && foreignCurrencyText != null) {
      final foreignCode = SmsCurrencyTable.codeFor(foreignCurrencyText);
      if (foreignCode != null && SmsAmountReader.isWellFormed(foreignText)) {
        d.foreignAmountText = '$foreignCode ${foreignText.trim()}';
        final currency = SmsCurrencyTable.catalogCurrency(foreignCode);
        if (currency != null) {
          d.foreignAmount = SmsAmountReader.parse(foreignText, currency);
        }
      }
    }

    // Date and time.
    final dateText = _group(match, 'date');
    if (dateText != null) {
      final read = SmsDateReader.parseDate(
        dateText,
        order: profile.dateOrder,
        now: m.now,
      );
      if (read != null) {
        d.date = read.date;
        d.dateInferred = read.yearInferred;
      }
    }
    final timeText = _group(match, 'time');
    if (timeText != null) d.time = SmsDateReader.parseTime(timeText);

    // Names, last four, reference.
    final merchant = _groupDisplay(match, 'merchant', m.text);
    if (merchant != null) d.merchant = _cleanName(merchant);
    final counterparty = _groupDisplay(match, 'counterparty', m.text);
    if (counterparty != null) d.counterparty = _cleanName(counterparty);
    final last4 = _group(match, 'last4');
    if (last4 != null) {
      final digits = last4.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 4) d.last4 = digits.substring(digits.length - 4);
    }
    final ref = _groupDisplay(match, 'ref', m.text);
    if (ref != null && ref.trim().isNotEmpty) d.ref = ref.trim();

    return _finish(profile, d, m);
  }

  /// Sets the amount on [d] from a captured token. Returns
  /// `Unreadable(amountUnreadable)` for a malformed token, else `null`.
  Unreadable? _setAmount(
    _Draft d,
    String token,
    String? code,
    FieldConfidenceLevel level,
    BankProfile profile,
  ) {
    final currency = SmsCurrencyTable.catalogCurrency(code);
    if (currency != null) {
      final money = SmsAmountReader.parse(token, currency);
      if (money == null) {
        return Unreadable(
          UnreadableReason.amountUnreadable,
          bankId: profile.id,
        );
      }
      d.amount = money;
      d.amountLevel = level;
      d.currencyCode = currency.code;
      return null;
    }
    if (code != null) {
      // Stated, outside the catalog: the number is never reinterpreted.
      if (!SmsAmountReader.isWellFormed(token)) {
        return Unreadable(
          UnreadableReason.amountUnreadable,
          bankId: profile.id,
        );
      }
      d.unsupportedCode = code;
      d.currencyInferred = false;
      return null;
    }
    final minor = SmsAmountReader.minorAssumingTwoDecimals(token);
    if (minor == null) {
      return Unreadable(UnreadableReason.amountUnreadable, bankId: profile.id);
    }
    d.candidates = [minor];
    d.amountLevel = level;
    return null;
  }

  // --- Generic extraction (step 9) -----------------------------------------

  ParseResult _generic(BankProfile profile, _Message m, {SmsKind? forcedKind}) {
    final g = m.signals;
    final f = m.folded;
    const level = FieldConfidenceLevel.medium;

    SmsKind kind;
    SmsDirection direction;
    if (forcedKind != null) {
      kind = forcedKind;
      direction = SmsDirection.credit;
    } else if (g.kindRule != null) {
      final rule = g.kindRule!;
      kind = rule.kind;
      direction = rule.direction;
      if (direction == SmsDirection.unknown) {
        direction = g.debit && !g.credit
            ? SmsDirection.debit
            : (g.credit && !g.debit
                  ? SmsDirection.credit
                  : SmsDirection.unknown);
      } else if (kind != SmsKind.refund) {
        final contradicted =
            (direction == SmsDirection.debit && g.credit && !g.debit) ||
            (direction == SmsDirection.credit && g.debit && !g.credit);
        if (contradicted) {
          kind = SmsKind.unknown;
          direction = SmsDirection.unknown;
        }
      }
    } else if (g.debit && g.credit) {
      kind = SmsKind.unknown;
      direction = SmsDirection.unknown;
    } else if (g.debit) {
      kind = SmsKind.unknown;
      direction = SmsDirection.debit;
    } else if (g.credit) {
      kind = SmsKind.otherDeposit;
      direction = SmsDirection.credit;
    } else {
      return const NotRecognized();
    }

    final d = _Draft(kind: kind, direction: direction, level: level);

    // Money tokens.
    final tokens = _moneyTokens(m);
    var primaries = [
      for (final t in tokens)
        if (t.role == _Role.primary && t.code != null) t,
    ];
    if (primaries.isEmpty) {
      primaries = [
        for (final t in tokens)
          if (t.role == _Role.primary && t.code == null && t.afterAmountLead) t,
      ];
    }
    final fees = [
      for (final t in tokens)
        if (t.role == _Role.fee && t.code != null) t,
    ];
    if (primaries.isEmpty) {
      if (fees.isNotEmpty && direction != SmsDirection.credit) {
        d.kind = SmsKind.fee;
        d.direction = SmsDirection.debit;
        primaries = [...fees];
        fees.clear();
      } else {
        return Unreadable(UnreadableReason.noAmount, bankId: profile.id);
      }
    }

    // Validate every primary: one malformed amount makes the message
    // unreadable rather than silently picking another (FR-039a).
    final values = <String, _Value>{};
    for (final t in primaries) {
      final currency = SmsCurrencyTable.catalogCurrency(t.code);
      if (currency != null) {
        final money = SmsAmountReader.parse(t.text, currency);
        if (money == null) {
          return Unreadable(
            UnreadableReason.amountUnreadable,
            bankId: profile.id,
          );
        }
        values.putIfAbsent(
          '${t.code}|${money.minorUnits}',
          () => _Value(t.code, money.minorUnits, money),
        );
      } else if (t.code != null) {
        if (!SmsAmountReader.isWellFormed(t.text)) {
          return Unreadable(
            UnreadableReason.amountUnreadable,
            bankId: profile.id,
          );
        }
        values.putIfAbsent(
          '${t.code}|${t.text}',
          () => _Value(t.code, null, null),
        );
      } else {
        final minor = SmsAmountReader.minorAssumingTwoDecimals(t.text);
        if (minor == null) {
          return Unreadable(
            UnreadableReason.amountUnreadable,
            bankId: profile.id,
          );
        }
        values.putIfAbsent('|$minor', () => _Value(null, minor, null));
      }
    }
    final distinct = values.values.toList();
    if (distinct.length == 1) {
      final v = distinct.single;
      if (v.money != null) {
        d.amount = v.money;
        d.amountLevel = level;
        d.currencyCode = v.code;
        d.currencyLevel = level;
      } else if (v.code != null) {
        d.unsupportedCode = v.code;
      } else {
        d.candidates = [v.minor!];
        d.amountLevel = level;
      }
    } else {
      d.ambiguous = true;
      final codes = {for (final v in distinct) v.code};
      if (codes.length == 1 && distinct.every((v) => v.minor != null)) {
        d.candidates = [for (final v in distinct.take(5)) v.minor!];
        d.amountLevel = FieldConfidenceLevel.low;
        if (codes.single != null) {
          d.currencyCode = codes.single;
          d.currencyLevel = level;
        }
      }
    }

    // In-message fee: exactly one valid fee value.
    final feeValues = <Money>{};
    for (final t in fees) {
      final currency = SmsCurrencyTable.catalogCurrency(t.code);
      final money = currency == null
          ? null
          : SmsAmountReader.parse(t.text, currency);
      if (money != null) feeValues.add(money);
    }
    if (feeValues.length == 1) d.fee = feeValues.single;

    // Date and time.
    final dateRead = SmsDateReader.findDate(
      f,
      order: profile.dateOrder,
      now: m.now,
    );
    if (dateRead != null) {
      d.date = dateRead.date;
      d.dateInferred = dateRead.yearInferred;
    }
    d.time = SmsDateReader.findTime(f);

    // Names.
    if (d.kind == SmsKind.transferOut) {
      d.counterparty = _nameAfter(rules.counterpartyTo, m, excludeOwn: true);
    } else if (d.kind == SmsKind.transferIn) {
      d.counterparty = _nameAfter(rules.counterpartyFrom, m, excludeOwn: true);
    } else {
      d.merchant = _nameAfter(rules.merchantLead, m, excludeOwn: false);
    }

    // Last four and reference.
    _readLast4(d, m);
    _readRef(d, m);

    return _finish(profile, d, m);
  }

  static GenericRules get rules => GenericRules.instance;

  /// Money tokens: numbers next to a currency marker, tagged primary, fee
  /// or balance by the nearest preceding keyword in the same sentence.
  List<_MoneyToken> _moneyTokens(_Message m) {
    final f = m.folded;
    final out = <_MoneyToken>[];
    final last4Ends = _last4Ends(f);
    for (final token in SmsAmountReader.scan(f)) {
      // A card or account last four is never an amount.
      if (last4Ends.contains(token.end)) continue;
      var before = token.start;
      if (before > 0 && f.codeUnitAt(before - 1) == 0x20) before--;
      var after = token.end;
      if (after < f.length && f.codeUnitAt(after) == 0x20) after++;
      var start = token.start;
      String? code;
      final pre =
          SmsCurrencyTable.markerEndingAt(f, before) ?? _isoEndingAt(m, before);
      if (pre != null) {
        code = pre.code;
        start = pre.start;
      } else {
        final post =
            SmsCurrencyTable.markerStartingAt(f, after) ??
            _isoStartingAt(m, after);
        code = post?.code;
      }
      // `EGP 1 500,00`: a short number followed by more digits after one
      // space is a grouping the reader refused; never read it as `1`.
      final brokenGroup =
          RegExp(r'^\d{1,3}$').hasMatch(token.text) &&
          token.end + 1 < f.length &&
          f.codeUnitAt(token.end) == 0x20 &&
          _isAsciiDigit(f.codeUnitAt(token.end + 1));
      out.add(
        _MoneyToken(
          text: brokenGroup ? '${token.text} ?' : token.text,
          code: code,
          role: m.roleAt(start),
          afterAmountLead: m.afterAmountLead(token.start),
        ),
      );
    }
    return out;
  }

  static bool _isAsciiDigit(int unit) => unit >= 0x30 && unit <= 0x39;

  /// A three-letter upper-case ISO code ending at [end].
  CurrencyMarker? _isoEndingAt(_Message m, int end) {
    final f = m.folded;
    final start = end - 3;
    if (start < 0) return null;
    if (start > 0 && SmsCurrencyTable.isLatinOrDigit(f.codeUnitAt(start - 1))) {
      return null;
    }
    return _iso(m, start, end);
  }

  CurrencyMarker? _isoStartingAt(_Message m, int start) {
    final f = m.folded;
    final end = start + 3;
    if (end > f.length) return null;
    if (end < f.length && SmsCurrencyTable.isLatinOrDigit(f.codeUnitAt(end))) {
      return null;
    }
    return _iso(m, start, end);
  }

  CurrencyMarker? _iso(_Message m, int start, int end) {
    final code = m.folded.substring(start, end);
    if (!SmsCurrencyTable.isoCodes.contains(code)) return null;
    final display = m.text.displaySpan(start, end);
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(display)) return null;
    return CurrencyMarker(start, end, display);
  }

  /// A name right after one of [leads]: it starts with a letter and ends at
  /// a stop phrase, sentence punctuation or 60 characters.
  String? _nameAfter(KeywordSet leads, _Message m, {required bool excludeOwn}) {
    final f = m.folded;
    final hits = leads.hits(f).toList()..sort((a, b) => a.start - b.start);
    for (final hit in hits) {
      var start = hit.end;
      if (start < f.length && f.codeUnitAt(start) == 0x20) start++;
      if (start >= f.length || !_isLetter(f.codeUnitAt(start))) continue;
      if (excludeOwn) {
        final own = rules.ownAccountTarget.firstHit(f.substring(start));
        if (own != null && own.start == 0) continue;
      }
      final limit = start + 60 > f.length ? f.length : start + 60;
      var end = limit;
      for (var i = start; i < limit; i++) {
        final unit = f.codeUnitAt(i);
        if (unit == 0x2C || unit == 0x3B || unit == 0x28 || unit == 0x060C) {
          end = i;
          break;
        }
        if (unit == 0x2E &&
            (i + 1 >= f.length || f.codeUnitAt(i + 1) == 0x20)) {
          end = i;
          break;
        }
        if (unit == 0x20 && rules.nameStops.any((s) => f.startsWith(s, i))) {
          end = i;
          break;
        }
        if (unit == 0x20 && _startsMoneyOrDate(f, i + 1)) {
          end = i;
          break;
        }
      }
      final name = _cleanName(m.text.displaySpan(start, end));
      if (name != null) return name;
    }
    return null;
  }

  static bool _startsMoneyOrDate(String f, int i) {
    if (i >= f.length) return false;
    final unit = f.codeUnitAt(i);
    if (unit >= 0x30 && unit <= 0x39) {
      // A trailing digit run that is part of a name (`Store 12`) is kept
      // only when it is not a date or time.
      return RegExp(
        r'^\d{1,4}[/:\-]',
      ).hasMatch(f.substring(i, i + 6 > f.length ? f.length : i + 6));
    }
    return SmsCurrencyTable.markerStartingAt(f, i) != null;
  }

  static bool _isLetter(int unit) =>
      (unit >= 0x61 && unit <= 0x7A) ||
      (unit >= 0xDF && unit <= 0x24F) ||
      (unit >= 0x0621 && unit <= 0x064A);

  /// Trims, masks every digit run of five or more to its last four (a name
  /// must never carry an account or phone number, FR-031), caps the length.
  static String? _cleanName(String text) {
    var name = text.trim();
    while (name.isNotEmpty && '.,:;-'.contains(name[name.length - 1])) {
      name = name.substring(0, name.length - 1).trimRight();
    }
    if (name.length < 2) return null;
    name = name.replaceAllMapped(RegExp(r'\d{5,}'), (match) {
      final run = match[0]!;
      return '${'•' * (run.length - 4)}${run.substring(run.length - 4)}';
    });
    if (name.length > maxNameLength) name = name.substring(0, maxNameLength);
    return name;
  }

  static final RegExp _maskedLast4 = RegExp(
    r'(?<![0-9a-z])(?:[x*•#]{2,12}|\.{2,6})[ \-]?(\d{4})(?![0-9]|[ \-][0-9])',
  );

  static final RegExp _endingLast4 = RegExp(
    r'(?:ending(?: with| in)?|المنتهيه|المنتهي|تنتهي)(?: ?ب| برقم)?[ :]{0,2}'
    r'(\d{4})(?![0-9]|[ \-][0-9])',
  );

  static final RegExp _cardNoLast4 = RegExp(
    r'(?:card|بطاقه|بطاقتك)(?: no\.?| number| رقم)?[ :#]{0,2}'
    r'(\d{4})(?![0-9]|[ \-][0-9])',
  );

  static final RegExp _ref = RegExp(
    r'(?<![a-z])(?:reference|ref|trx|txn|transaction id|رقم المرجع|المرجع|'
    r'مرجع|رقم العمليه|رقم المعامله)(?:[ .]?(?:no|number|id))?[ :.#]{1,3}'
    r'([a-z0-9•][a-z0-9•\-]{3,29})(?![a-z0-9•\-])',
  );

  /// Every engine pattern, for the backtracking guard test.
  static List<RegExp> get patternsForTest => [
    _maskedLast4,
    _endingLast4,
    _cardNoLast4,
    _ref,
    ...SmsDateReader.patternsForTest,
  ];

  /// End offsets of every card or account last-four token: each pattern's
  /// group is its last four characters.
  static Set<int> _last4Ends(String f) => {
    for (final p in [_maskedLast4, _endingLast4, _cardNoLast4])
      for (final match in p.allMatches(f)) match.end,
  };

  static final RegExp _codeShape = RegExp(r'^\d{4,8}$');
  static final RegExp _yearShape = RegExp(r'^(?:19|20)\d\d$');

  /// A standalone 4-8 digit code (an OTP): no currency marker next to it,
  /// not a card last four, not a year.
  bool _hasStandaloneCode(_Message m) {
    final f = m.folded;
    final last4Ends = _last4Ends(f);
    for (final token in SmsAmountReader.scan(f)) {
      final text = token.text;
      if (!_codeShape.hasMatch(text)) continue;
      if (last4Ends.contains(token.end)) continue;
      if (_yearShape.hasMatch(text)) continue;
      var before = token.start;
      if (before > 0 && f.codeUnitAt(before - 1) == 0x20) before--;
      var after = token.end;
      if (after < f.length && f.codeUnitAt(after) == 0x20) after++;
      final marker =
          SmsCurrencyTable.markerEndingAt(f, before) ??
          _isoEndingAt(m, before) ??
          SmsCurrencyTable.markerStartingAt(f, after) ??
          _isoStartingAt(m, after);
      if (marker == null) return true;
    }
    return false;
  }

  void _readLast4(_Draft d, _Message m) {
    final f = m.folded;
    final masked = _maskedLast4.firstMatch(f);
    if (masked != null) {
      d.last4 = masked[1];
      final windowStart = masked.start < 25 ? 0 : masked.start - 25;
      d.last4Level =
          rules.cardWords.matches(f.substring(windowStart, masked.start))
          ? FieldConfidenceLevel.medium
          : FieldConfidenceLevel.low;
      return;
    }
    final named = _endingLast4.firstMatch(f) ?? _cardNoLast4.firstMatch(f);
    if (named != null) d.last4 = named[1];
  }

  void _readRef(_Draft d, _Message m) {
    for (final match in _ref.allMatches(m.folded)) {
      final token = match[1]!;
      if (!token.contains(RegExp(r'[0-9•]'))) continue;
      d.ref = m.text.displaySpan(match.end - token.length, match.end);
      return;
    }
  }

  // --- Assembly -------------------------------------------------------------

  ParsedTransaction _finish(BankProfile profile, _Draft d, _Message m) {
    final input = m.input;
    final warnings = <SmsWarning>{};
    final fields = <SmsField, FieldConfidence>{};

    if (d.amount != null) {
      fields[SmsField.amount] = FieldConfidence.read(d.amountLevel);
    } else if (d.candidates.isNotEmpty) {
      fields[SmsField.amount] = FieldConfidence.read(
        d.ambiguous ? FieldConfidenceLevel.low : d.amountLevel,
      );
    }
    if (d.ambiguous) warnings.add(SmsWarning.ambiguousAmount);

    if (d.unsupportedCode != null) {
      warnings.add(SmsWarning.unsupportedCurrency);
    } else if (d.currencyCode != null) {
      if (d.currencyInferred) {
        fields[SmsField.currency] = const FieldConfidence.inferred();
        warnings.add(SmsWarning.currencyInferred);
      } else {
        fields[SmsField.currency] = FieldConfidence.read(d.currencyLevel);
      }
    }

    if (d.direction != SmsDirection.unknown) {
      fields[SmsField.direction] = FieldConfidence.read(d.level);
    }
    if (d.kind != SmsKind.unknown) {
      fields[SmsField.kind] = FieldConfidence.read(d.level);
    }

    var date = d.date;
    var dateInferred = d.dateInferred;
    if (date == null && input.receivedAt != null) {
      final local = input.receivedAt!.toLocal();
      date = DateTime(local.year, local.month, local.day);
      dateInferred = true;
    }
    if (date != null) {
      fields[SmsField.date] = dateInferred
          ? const FieldConfidence.inferred()
          : FieldConfidence.read(d.level);
      if (dateInferred) warnings.add(SmsWarning.dateInferred);
    }
    if (d.time != null) fields[SmsField.time] = FieldConfidence.read(d.level);
    if (d.merchant != null) {
      fields[SmsField.merchant] = FieldConfidence.read(d.level);
    }
    if (d.counterparty != null) {
      fields[SmsField.counterparty] = FieldConfidence.read(d.level);
    }
    if (d.last4 != null) {
      fields[SmsField.cardLast4] = FieldConfidence.read(
        d.last4Level ?? d.level,
      );
    }
    if (d.ref != null) {
      fields[SmsField.reference] = FieldConfidence.read(d.level);
      if (d.ref!.contains('•')) warnings.add(SmsWarning.maskedReference);
    }
    if (d.foreignAmountText != null) {
      warnings.add(SmsWarning.foreignCurrencyBilledAmount);
    }

    if (profile.isGeneric) {
      warnings.add(SmsWarning.genericParser);
    } else if (!profile.verified) {
      warnings.add(SmsWarning.unverifiedProfile);
    }
    final overall = overallConfidence(
      fields,
      capMedium:
          confidenceCapsAtMedium(
            isGeneric: profile.isGeneric,
            source: input.source,
          ) ||
          !profile.verified,
    );

    final merchantKey = _merchantKey(d.merchant ?? d.counterparty);
    final suggestion = suggestFor(
      kind: d.kind,
      direction: d.direction,
      source: input.source,
      options: m.options,
      merchantKey: merchantKey,
      counterparty: d.counterparty,
      matchText: m.folded,
      profileKeywordRules: profile.merchantKeywordRules,
    );
    warnings.addAll(suggestion.warnings);

    return ParsedTransaction(
      bankId: profile.id,
      parserId: profile.id,
      ruleVersion: profile.ruleVersion,
      kind: d.kind,
      direction: d.direction,
      amount: d.amount,
      amountCandidatesMinor: d.candidates,
      currencyCodeRead: d.unsupportedCode ?? d.currencyCode,
      occurredOn: date,
      timeMinutes: d.time,
      merchant: d.merchant,
      merchantKey: merchantKey,
      counterparty: d.counterparty,
      cardLast4: d.last4,
      referenceId: d.ref,
      foreignAmountText: d.foreignAmountText,
      fee: d.fee,
      foreignAmount: d.foreignAmount,
      suggestedType: suggestion.type,
      suggestedCategoryKeyOrId: suggestion.categoryId,
      suggestedPersonId: suggestion.personId,
      confidence: ParseConfidence(fields: fields, overall: overall),
      warnings: warnings,
    );
  }

  /// FR-055: folded, lower-cased, digits and punctuation removed,
  /// whitespace collapsed. Exact matching only.
  static String? _merchantKey(String? name) {
    if (name == null) return null;
    final folded = SmsTextNormalizerImpl.fold(name);
    final buffer = StringBuffer();
    for (final unit in folded.codeUnits) {
      buffer.writeCharCode(_isLetter(unit) ? unit : 0x20);
    }
    final key = buffer.toString().replaceAll(RegExp(' +'), ' ').trim();
    return key.isEmpty ? null : key;
  }

  static String? _group(RegExpMatch match, String name) {
    if (!match.groupNames.contains(name)) return null;
    return match.namedGroup(name);
  }

  /// A named group's text as the bank wrote it. Dart gives no group
  /// offsets, so the folded group is located inside the whole match; when it
  /// occurs more than once the occurrences are equal after folding, so the
  /// first one carries the same content.
  static String? _groupDisplay(RegExpMatch match, String name, FoldedText t) {
    final value = _group(match, name);
    if (value == null || value.isEmpty) return null;
    final index = t.forMatching.indexOf(value, match.start);
    if (index < 0 || index + value.length > match.end) return value;
    return t.displaySpan(index, index + value.length);
  }

  static bool _isNonText(String raw) {
    var replacements = 0;
    for (var i = 0; i < raw.length; i++) {
      final unit = raw.codeUnitAt(i);
      if ((unit < 0x20 && (unit < 0x09 || unit > 0x0D)) || unit == 0x7F) {
        return true;
      }
      if (unit == 0xFFFD && ++replacements > 2) return true;
      if (unit >= 0xD800 && unit <= 0xDBFF) {
        final next = i + 1 < raw.length ? raw.codeUnitAt(i + 1) : 0;
        if (next < 0xDC00 || next > 0xDFFF) return true;
        i++;
      } else if (unit >= 0xDC00 && unit <= 0xDFFF) {
        return true;
      }
    }
    return false;
  }
}

/// One message during parsing; never logged, never in `toString`.
class _Message {
  _Message(this.input, this.options, this.text, this.now)
    : signals = _Signals(text.forMatching);

  final SmsParseInput input;
  final ParserOptions options;
  final FoldedText text;
  final DateTime now;
  final _Signals signals;

  String get folded => text.forMatching;

  /// The role of a money token starting at [start]: the nearest keyword
  /// before it in the same sentence (at most 40 characters back).
  _Role roleAt(int start) {
    var windowStart = start - 40 < 0 ? 0 : start - 40;
    // The nearest sentence end before [start]; a `. ` after an
    // abbreviation (`Avl. Bal. EGP 100`, `a/c no. 1`) is not one.
    for (var i = start - 1; i > windowStart; i--) {
      final unit = folded.codeUnitAt(i);
      if (unit == 0x0A) {
        windowStart = i + 1;
        break;
      }
      if (unit != 0x20) continue;
      final prev = folded.codeUnitAt(i - 1);
      if (prev == 0x3B ||
          prev == 0x21 ||
          (prev == 0x2E && !_afterAbbreviation(i - 1))) {
        windowStart = i + 1;
        break;
      }
    }
    var bestEnd = -1;
    var role = _Role.primary;
    void consider(Iterable<KeywordHit> hits, _Role r) {
      for (final hit in hits) {
        if (hit.end <= start && hit.end > windowStart && hit.end > bestEnd) {
          bestEnd = hit.end;
          role = r;
        }
      }
    }

    consider(signals.transactionHits, _Role.primary);
    consider(signals.feeHits, _Role.fee);
    consider(signals.balanceHits, _Role.balance);
    return role;
  }

  /// Words that end in a period without ending the sentence.
  static const Set<String> _abbreviations = {
    'bal', 'avl', 'avail', 'amt', 'a/c', 'ac', 'acc', 'acct', 'no', 'ref', //
    'txn', 'trx', 'trans', 'ledg', 'curr', 'cr', 'dr', 'le', 'l.e', 'ltd',
    'co', 'inc', 'st', 'mr', 'mrs', 'ms', 'dt', 'approx',
  };

  /// Whether the period at [dot] closes an abbreviation.
  bool _afterAbbreviation(int dot) {
    var i = dot;
    while (i > 0 && folded.codeUnitAt(i - 1) != 0x20 && dot - i < 12) {
      i--;
    }
    var word = folded.substring(i, dot);
    while (word.isNotEmpty && '(:,'.contains(word[0])) {
      word = word.substring(1);
    }
    return _abbreviations.contains(word);
  }

  /// Whether a currency-less number at [start] directly follows an amount
  /// word (`debited with 250.00`, `مبلغ 250`).
  bool afterAmountLead(int start) {
    for (final hit in signals.amountLeadHits) {
      if (hit.end > start) continue;
      final gap = folded.substring(hit.end, start);
      if (RegExp(r'^[ :]{1,3}$').hasMatch(gap)) return true;
    }
    return false;
  }
}

/// The generic keyword signals of one message, computed once.
class _Signals {
  _Signals(String f)
    : otp = _rules.otp.matches(f),
      otpWeak = _rules.otpWeak.matches(f),
      declined = _rules.declined.matches(f),
      refundPosted = _rules.refundPosted.matches(f),
      promotionWeak = _rules.promotionWeak.matches(f),
      dueReminder = _rules.dueReminder.matches(f),
      pending = _rules.pendingAuthorization.matches(f),
      reversal = _rules.authorizationReversal.matches(f),
      promotion = _rules.promotion.matches(f),
      balance = _rules.balance.matches(f),
      debit = _rules.debitVerbs.matches(f),
      credit = _rules.creditVerbs.matches(f),
      kindRule = _firstKindRule(f),
      balanceHits = _rules.balance.hits(f).toList(),
      feeHits = _rules.fee.hits(f).toList(),
      amountLeadHits = _rules.amountLead.hits(f).toList(),
      transactionHits = [
        ..._rules.debitVerbs.hits(f),
        ..._rules.creditVerbs.hits(f),
        for (final rule in _rules.kindRules) ...rule.keywords.hits(f),
      ];

  static GenericRules get _rules => GenericRules.instance;

  final bool otp;
  final bool otpWeak;
  final bool declined;
  final bool refundPosted;
  final bool promotionWeak;
  final bool dueReminder;
  final bool pending;
  final bool reversal;
  final bool promotion;
  final bool balance;
  final bool debit;
  final bool credit;
  final KindRule? kindRule;
  final List<KeywordHit> balanceHits;
  final List<KeywordHit> feeHits;
  final List<KeywordHit> amountLeadHits;
  final List<KeywordHit> transactionHits;

  bool get posted => debit || credit;

  bool get refund => kindRule?.kind == SmsKind.refund;

  static KindRule? _firstKindRule(String f) {
    for (final rule in _rules.kindRules) {
      if (rule.keywords.matches(f)) return rule;
    }
    return null;
  }
}

enum _Role { primary, fee, balance }

class _MoneyToken {
  const _MoneyToken({
    required this.text,
    required this.code,
    required this.role,
    required this.afterAmountLead,
  });

  final String text;
  final String? code;
  final _Role role;
  final bool afterAmountLead;
}

class _Value {
  const _Value(this.code, this.minor, this.money);

  final String? code;
  final int? minor;
  final Money? money;
}

/// Mutable fields of one parse before assembly.
class _Draft {
  _Draft({required this.kind, required this.direction, required this.level})
    : amountLevel = level,
      currencyLevel = level;

  SmsKind kind;
  SmsDirection direction;

  /// The read level of fields from this source (template or generic).
  final FieldConfidenceLevel level;

  Money? amount;
  FieldConfidenceLevel amountLevel;
  List<int> candidates = const [];
  bool ambiguous = false;
  String? currencyCode;
  FieldConfidenceLevel currencyLevel;
  bool currencyInferred = false;
  String? unsupportedCode;
  Money? fee;
  String? foreignAmountText;
  Money? foreignAmount;
  DateTime? date;
  bool dateInferred = false;
  int? time;
  String? merchant;
  String? counterparty;
  String? last4;
  FieldConfidenceLevel? last4Level;
  String? ref;
}
