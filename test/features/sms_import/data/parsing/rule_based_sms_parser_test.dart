import 'dart:math';

import 'package:daftary/core/confidence/field_confidence.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/sms_import/data/parsing/bank_profile.dart';
import 'package:daftary/features/sms_import/data/parsing/rule_based_sms_parser.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_amount_reader.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_date_reader.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_parser_registry.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_confidence.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_result.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

// 023 T049: the rule-based parser engine (parser-contract §4-§7, §10).
// Every message is synthetic; every number is invented.

final DateTime _now = DateTime(2026, 3, 10, 12);

RuleBasedSmsParser _parser({DateTime? now, SmsParserRegistry? registry}) =>
    RuleBasedSmsParser(clock: FixedClock(now ?? _now), registry: registry);

ParseResult _paste(String text, {DateTime? now, SmsParserRegistry? registry}) =>
    _parser(
      now: now,
      registry: registry,
    ).parse(SmsParseInput(rawText: text, source: SmsSource.paste));

ParseResult _scan(
  String text, {
  String? sender = 'BANKX',
  DateTime? receivedAt,
  SmsParserRegistry? registry,
  ParserOptions options = const ParserOptions(),
}) => _parser(registry: registry).parse(
  SmsParseInput(
    rawText: text,
    source: SmsSource.inboxScan,
    sender: sender,
    receivedAt: receivedAt ?? DateTime(2026, 3, 9, 18, 30),
  ),
  options: options,
);

ParsedTransaction _parsed(ParseResult result) {
  expect(result, isA<ParsedTransaction>(), reason: '$result');
  return result as ParsedTransaction;
}

// Test-only bank profiles. Patterns are written in folded form.
final BankProfile _bankA = BankProfile(
  id: 'banka',
  version: 1,
  senders: const {'BANKA'},
  signatures: [ContentSignature(RegExp(r'\bbanka\b'))],
  defaultCurrency: 'EGP',
  templates: [
    SmsTemplate(
      name: 'purchase_en_1',
      kind: SmsKind.cardPurchase,
      direction: SmsDirection.debit,
      language: SmsLanguage.en,
      pattern: RegExp(
        r'banka: purchase of (?:(?<currency>egp|usd|kwd) )?'
        r'(?<amount>\d[\d,]{0,15}(?:\.\d{1,3})?) '
        r'at (?<merchant>[a-z][a-z ]{1,40}?) '
        r'on (?<date>\d{1,2}/\d{1,2}/\d{4})'
        r'(?: (?<time>\d{1,2}:\d{2}))?'
        r'(?: original (?<foreignCurrency>[a-z]{3}) (?<foreignAmount>\d[\d,]{0,15}(?:\.\d{1,2})?))?'
        r'(?: fee egp (?<fee>\d[\d,]{0,15}(?:\.\d{1,2})?))?'
        r'(?: card x+(?<last4>\d{4}))?'
        r'(?: ref (?<ref>[a-z0-9]{4,20}))?',
      ),
    ),
    SmsTemplate(
      name: 'auth_purchase_en',
      kind: SmsKind.cardPurchase,
      direction: SmsDirection.debit,
      language: SmsLanguage.en,
      postsAtAuthorization: true,
      pattern: RegExp(
        r'banka: authorization of egp (?<amount>\d[\d,]{0,15}(?:\.\d{1,2})?) '
        r'at (?<merchant>[a-z][a-z ]{1,40}?) on (?<date>\d{1,2}/\d{1,2}/\d{4})',
      ),
    ),
  ],
);

BankProfile _bankB({bool verified = false}) => BankProfile(
  id: 'bankb',
  version: 2,
  senders: const {'BANK B'},
  signatures: [ContentSignature(RegExp(r'\bbankb\b'))],
  defaultCurrency: 'EGP',
  verified: verified,
  templates: [
    SmsTemplate(
      name: 'purchase_en_1',
      kind: SmsKind.cardPurchase,
      direction: SmsDirection.debit,
      language: SmsLanguage.en,
      anchored: true,
      pattern: RegExp(
        r'bankb: (?<currency>egp) (?<amount>\d[\d,]{0,15}(?:\.\d{1,2})?) spent at '
        r'(?<merchant>[a-z][a-z ]{1,40}?) on (?<date>\d{1,2}/\d{1,2}/\d{4})',
      ),
    ),
  ],
);

void main() {
  group('amounts', () {
    test('exact minor units from grouped, glued and Arabic-Indic forms', () {
      final cases = {
        'Purchase of EGP 1,250.50 at Example Cafe': 125050,
        'Purchase of EGP 1 500.00 at Example Cafe': 150000,
        'Purchase of 1500EGP at Example Cafe': 150000,
        'Purchase of EGP1,500.00 at Example Cafe': 150000,
        'Purchase of EGP 15 000 at Example Cafe': 1500000,
        'تم خصم ١٬٥٠٠٫٧٥ جنيه من بطاقتك': 150075,
        'تم خصم ۲۵۰ ج.م من بطاقتك': 25000,
      };
      cases.forEach((text, minor) {
        final p = _parsed(_paste(text));
        expect(p.amount, Money.egp(minor), reason: text);
      });
    });

    test('ambiguous separators are unreadable, never reinterpreted '
        '(CHK045)', () {
      for (final text in [
        'Purchase of EGP 100,50 at Example Cafe',
        'Purchase of EGP 1.234,50 at Example Cafe',
        'Purchase of EGP 1,23 at Example Cafe',
        'Purchase of EGP 1.234.567 at Example Cafe',
        'Purchase of EGP 1 500,00 at Example Cafe',
      ]) {
        expect(
          _paste(text),
          const Unreadable(
            UnreadableReason.amountUnreadable,
            bankId: 'generic',
          ),
          reason: text,
        );
      }
    });

    test('more than 2 decimals or more than 12 whole digits is unreadable, '
        'never clamped', () {
      for (final text in [
        'Purchase of EGP 12.345 at Example Cafe',
        'Purchase of EGP 1234567890123 at Example Cafe',
        'Purchase of EGP 0.00 at Example Cafe',
      ]) {
        final result = _paste(text);
        expect(
          result,
          const Unreadable(
            UnreadableReason.amountUnreadable,
            bankId: 'generic',
          ),
          reason: text,
        );
        // The FormatException message (which embeds the input) is never
        // copied anywhere.
        expect(result.toString(), isNot(contains('12345')));
      }
    });

    test('the balance is never a candidate', () {
      final p = _parsed(
        _paste(
          'Purchase of EGP 100.00 at Example Cafe. '
          'Available balance EGP 5,000.00',
        ),
      );
      expect(p.amount, const Money.egp(10000));
      final ar = _parsed(
        _paste('تم خصم 100 جنيه من حسابك والرصيد المتاح 900 جنيه'),
      );
      expect(ar.amount, const Money.egp(10000));
    });

    test('two non-fee candidates: amount null, both listed, Low', () {
      final p = _parsed(
        _paste('Purchase of EGP 100.00 and EGP 250.00 at Example Cafe'),
      );
      expect(p.amount, isNull);
      expect(p.amountCandidatesMinor, [10000, 25000]);
      expect(p.warnings, contains(SmsWarning.ambiguousAmount));
      expect(
        p.confidence[SmsField.amount],
        FieldConfidence.read(FieldConfidenceLevel.low),
      );
      expect(p.confidence.overall, OverallConfidence.low);
    });

    test('an in-message fee is parsed into fee, never added (FR-030a)', () {
      final p = _parsed(
        _scan('Cash withdrawal of EGP 500.00 from ATM. Fees EGP 5.00'),
      );
      expect(p.kind, SmsKind.atmWithdrawal);
      expect(p.amount, const Money.egp(50000));
      expect(p.fee, const Money.egp(500));
    });

    test('a fee SMS is its own fee item', () {
      final p = _parsed(
        _scan('A fee of EGP 5.00 has been deducted from your account'),
      );
      expect(p.kind, SmsKind.fee);
      expect(p.amount, const Money.egp(500));
      expect(p.fee, isNull);
      expect(p.warnings, contains(SmsWarning.feeSeparateItem));
    });

    test('a masked amount (re-parse of masked text) is unreadable', () {
      expect(
        _paste('Purchase of EGP •••• at Example Cafe'),
        const Unreadable(UnreadableReason.noAmount, bankId: 'generic'),
      );
    });

    test('every catalog currency has two decimals (the no-currency '
        'candidate relies on it)', () {
      for (final currency in Currency.catalog) {
        expect(currency.minorUnitsPerMajor, 100, reason: currency.code);
      }
      expect(SmsAmountReader.minorAssumingTwoDecimals('250.5'), 25050);
    });
  });

  group('currencies', () {
    test('the word and symbol map', () {
      final cases = {
        'Purchase of LE 10 at Example Cafe': 'EGP',
        'Purchase of 10 L.E. at Example Cafe': 'EGP',
        'تم خصم 10 ج.م من بطاقتك': 'EGP',
        'تم خصم 10 جنيه من بطاقتك': 'EGP',
        r'Purchase of $10 at Example Cafe': 'USD',
        'Purchase of USD 10 at Example Cafe': 'USD',
        'Purchase of €10 at Example Cafe': 'EUR',
        'تم خصم 10 يورو من بطاقتك': 'EUR',
        'Purchase of SAR 10 at Example Cafe': 'SAR',
        'Purchase of AED 10 at Example Cafe': 'AED',
        'تم خصم 10 جنيه استرليني من بطاقتك': 'GBP',
      };
      cases.forEach((text, code) {
        final p = _parsed(_paste(text));
        expect(p.amount?.currency.code, code, reason: text);
        expect(p.currencyCodeRead, code, reason: text);
      });
    });

    test('an ISO code outside the catalog: null amount, code kept, '
        'unsupportedCurrency', () {
      final p = _parsed(_paste('Purchase of KWD 12.500 at Example Cafe'));
      expect(p.amount, isNull);
      expect(p.amountCandidatesMinor, isEmpty);
      expect(p.currencyCodeRead, 'KWD');
      expect(p.warnings, contains(SmsWarning.unsupportedCurrency));
      expect(p.confidence.overall, OverallConfidence.low);
    });

    test('no currency stated (generic): the number is a single candidate and '
        'currency stays empty', () {
      final p = _parsed(_paste('Your account was debited with 250.00'));
      expect(p.amount, isNull);
      expect(p.amountCandidatesMinor, [25000]);
      expect(p.currencyCodeRead, isNull);
      expect(p.confidence[SmsField.currency], isNull);
      expect(p.warnings, isNot(contains(SmsWarning.ambiguousAmount)));
    });

    test('a bank profile default currency is inferred', () {
      final registry = SmsParserRegistry(profiles: [_bankA]);
      final p = _parsed(
        _scan(
          'BANKA: Purchase of 125.50 at Example Cafe on 04/03/2026',
          sender: 'BANKA',
          registry: registry,
        ),
      );
      expect(p.amount, const Money.egp(12550));
      expect(p.confidence[SmsField.currency], const FieldConfidence.inferred());
      expect(p.warnings, contains(SmsWarning.currencyInferred));
    });
  });

  group('dates', () {
    DateTime? dateOf(String text, {DateTime? now}) =>
        _parsed(_paste(text, now: now)).occurredOn;

    test('numeric, 2-digit year, Arabic Egyptian and Levantine months', () {
      final march4 = DateTime(2026, 3, 4);
      for (final text in [
        'Purchase of EGP 10 at Example Cafe on 04/03/2026',
        'Purchase of EGP 10 at Example Cafe on 4-3-26',
        'Purchase of EGP 10 at Example Cafe on 04 Mar 2026',
        'Purchase of EGP 10 at Example Cafe on March 4, 2026',
        'تم خصم 10 جنيه من بطاقتك يوم 4 مارس 2026',
        'تم خصم 10 جنيه من بطاقتك يوم ٤ آذار ٢٠٢٦',
        'تم خصم 10 جنيه من بطاقتك بتاريخ 2026-03-04',
      ]) {
        expect(dateOf(text), march4, reason: text);
      }
      expect(
        dateOf('تم خصم 10 جنيه يوم 15 تشرين الأول 2025'),
        DateTime(2025, 10, 15),
      );
      expect(
        dateOf('تم خصم 10 جنيه يوم 1 كانون الثاني 2026'),
        DateTime(2026, 1, 1),
      );
    });

    test('an invalid date is not constructed (round-trip check)', () {
      final p = _parsed(
        _paste('Purchase of EGP 10 at Example Cafe on 31/02/2026'),
      );
      expect(p.occurredOn, isNull);
    });

    test('a year-less date takes the current year, inferred', () {
      final p = _parsed(_paste('Purchase of EGP 10 at Example Cafe on 04 Mar'));
      expect(p.occurredOn, DateTime(2026, 3, 4));
      expect(p.confidence[SmsField.date], const FieldConfidence.inferred());
      expect(p.warnings, contains(SmsWarning.dateInferred));
    });

    test('year edge (FR-036, CHK050): a paste on Jan 2 for "30 Dec" is the '
        'previous year', () {
      final jan2 = DateTime(2026, 1, 2, 9);
      expect(
        dateOf('Purchase of EGP 10 at Example Cafe on 30 Dec', now: jan2),
        DateTime(2025, 12, 30),
      );
      // One day after "now" is still the current year; two days is not.
      expect(
        dateOf('Purchase of EGP 10 at Example Cafe on 3 Jan', now: jan2),
        DateTime(2026, 1, 3),
      );
      expect(
        dateOf('Purchase of EGP 10 at Example Cafe on 4 Jan', now: jan2),
        DateTime(2025, 1, 4),
      );
      expect(SmsDateReader.inferYear(1, 1, DateTime(2025, 12, 31)), 2025);
    });

    test('12-hour and 24-hour times', () {
      int? timeOf(String suffix) => _parsed(
        _paste('Purchase of EGP 10 at Example Cafe on 04/03/2026 $suffix'),
      ).timeMinutes;
      expect(timeOf('22:40'), 22 * 60 + 40);
      expect(timeOf('10:15 PM'), 22 * 60 + 15);
      expect(timeOf('12:30 am'), 30);
      expect(timeOf('12:05 pm'), 12 * 60 + 5);
      expect(
        _parsed(
          _paste('تم خصم 10 جنيه يوم 04/03/2026 الساعة 9:05 م'),
        ).timeMinutes,
        21 * 60 + 5,
      );
    });

    test('paste without a date leaves it empty (FR-038)', () {
      final p = _parsed(_paste('Purchase of EGP 10 at Example Cafe'));
      expect(p.occurredOn, isNull);
      expect(p.confidence[SmsField.date], isNull);
      expect(p.confidence.overall, OverallConfidence.low);
    });

    test('scan without a date: the received local day, inferred, around '
        "Egypt's DST transitions (FR-038)", () {
      for (final received in [
        DateTime(2026, 4, 24, 0, 30), // spring forward night
        DateTime(2026, 10, 29, 23, 45), // fall back night
        DateTime(2026, 10, 30, 0, 15),
      ]) {
        final p = _parsed(
          _scan('Purchase of EGP 10 at Example Cafe', receivedAt: received),
        );
        expect(
          p.occurredOn,
          DateTime(received.year, received.month, received.day),
        );
        expect(p.confidence[SmsField.date], const FieldConfidence.inferred());
      }
    });

    test('a UTC receipt instant maps to the local day of that instant; a '
        'stated date always wins (time-zone change)', () {
      final instant = DateTime.utc(2026, 3, 4, 22, 30);
      final local = instant.toLocal();
      final p = _parsed(
        _scan('Purchase of EGP 10 at Example Cafe', receivedAt: instant),
      );
      expect(p.occurredOn, DateTime(local.year, local.month, local.day));
      final stated = _parsed(
        _scan(
          'Purchase of EGP 10 at Example Cafe on 04/03/2026',
          receivedAt: instant,
        ),
      );
      expect(stated.occurredOn, DateTime(2026, 3, 4));
    });
  });

  group('classification', () {
    void expectNonTransactional(String text, NonTransactionalReason reason) {
      final result = _scan(text);
      expect(result, isA<NonTransactional>(), reason: text);
      expect((result as NonTransactional).reason, reason, reason: text);
    }

    test('OTP wins over everything (EN, AR, mixed)', () {
      for (final text in [
        'Your OTP is 482913. Do not share it with anyone.',
        'Use verification code 482913 to confirm purchase of EGP 100.00',
        'رمز التحقق الخاص بك هو 482913 لا تشاركه مع أحد',
        'OTP 482913 لعملية شراء بمبلغ 100 جنيه',
      ]) {
        expectNonTransactional(text, NonTransactionalReason.otp);
      }
    });

    test('promotion', () {
      expectNonTransactional(
        'Enjoy 20% cashback on all purchases this weekend! Offer ends soon.',
        NonTransactionalReason.promotion,
      );
      expectNonTransactional(
        'استمتع بخصم 20% على مشترياتك لفترة محدودة',
        NonTransactionalReason.promotion,
      );
    });

    test('decline', () {
      expectNonTransactional(
        'Your purchase of EGP 300.00 at Example Shop was declined.',
        NonTransactionalReason.declined,
      );
      expectNonTransactional(
        'تم رفض عملية شراء بمبلغ 300 جنيه لعدم كفاية الرصيد',
        NonTransactionalReason.declined,
      );
    });

    test('balance inquiry', () {
      expectNonTransactional(
        'Your available balance is EGP 5,000.00',
        NonTransactionalReason.balanceInquiry,
      );
      expectNonTransactional(
        'رصيدك الحالي 5000 جنيه',
        NonTransactionalReason.balanceInquiry,
      );
    });

    test('pending authorization', () {
      expectNonTransactional(
        'An authorization of EGP 300.00 at Example Hotel is pending.',
        NonTransactionalReason.pendingAuthorization,
      );
      expectNonTransactional(
        'تم حجز مبلغ 300 جنيه قيد التنفيذ',
        NonTransactionalReason.pendingAuthorization,
      );
    });

    test('authorization reversal: a pending item, Ignore, reversalHint '
        '(FR-024b)', () {
      final p = _parsed(
        _scan(
          'Authorization reversed: EGP 250.00 hold released at Example Shop',
        ),
      );
      expect(p.kind, SmsKind.authorizationReversal);
      expect(p.direction, SmsDirection.credit);
      expect(p.suggestedType, SuggestedRecordType.ignore);
      expect(p.warnings, contains(SmsWarning.reversalHint));
      expect(p.amount, const Money.egp(25000));
    });

    test('a refund credit: Ignore with refundHint (FR-024a)', () {
      final p = _parsed(
        _scan('Refund of EGP 80.00 from Example Shop credited to your card'),
      );
      expect(p.kind, SmsKind.refund);
      expect(p.direction, SmsDirection.credit);
      expect(p.suggestedType, SuggestedRecordType.ignore);
      expect(p.warnings, contains(SmsWarning.refundHint));
    });

    test('a bank whose purchase is sent at authorization time: its own '
        'cardPurchase template wins (FR-024b)', () {
      final registry = SmsParserRegistry(profiles: [_bankA]);
      final p = _parsed(
        _scan(
          'BANKA: Authorization of EGP 300.00 at Example Hotel on 04/03/2026',
          sender: 'BANKA',
          registry: registry,
        ),
      );
      expect(p.kind, SmsKind.cardPurchase);
      expect(p.bankId, 'banka');
      expect(p.amount, const Money.egp(30000));
    });

    test('ambiguous direction is unknown (FR-033)', () {
      final p = _parsed(
        _scan('EGP 100.00 debited and credited on your account'),
      );
      expect(p.direction, SmsDirection.unknown);
      expect(p.suggestedType, SuggestedRecordType.unset);
      expect(p.confidence.overall, OverallConfidence.low);
    });

    test('not a bank message: NotRecognized; vocabulary without amount: '
        'Unreadable(noAmount)', () {
      expect(_paste('See you at the cafe at 10:15'), const NotRecognized());
      expect(
        _paste('Your card was debited. Thank you.'),
        const Unreadable(UnreadableReason.noAmount, bankId: 'generic'),
      );
    });
  });

  group('precedence (FR-028)', () {
    final registry = SmsParserRegistry(profiles: [_bankA, _bankB()]);
    const textA = 'BANKA: Purchase of EGP 125.50 at Example Cafe on 04/03/2026';

    test('sender plus signature selects the bank', () {
      final p = _parsed(_scan(textA, sender: 'banka', registry: registry));
      expect(p.bankId, 'banka');
      expect(p.parserId, 'banka');
      expect(p.ruleVersion, 'banka@1');
    });

    test('sender IDs match on the canonical form', () {
      final p = _parsed(
        _scan(
          'BANKB: EGP 10.00 spent at Example Cafe on 04/03/2026',
          sender: 'bank b',
          registry: registry,
        ),
      );
      expect(p.bankId, 'bankb');
    });

    test('paste and share: signature only', () {
      final p = _parsed(_paste(textA, registry: registry));
      expect(p.bankId, 'banka');
      expect(p.confidence.overall, isNot(OverallConfidence.high));
    });

    test('a spoofed or look-alike sender falls to generic', () {
      final p = _parsed(
        _scan(textA, sender: 'BANKA-ALERT', registry: registry),
      );
      expect(p.bankId, 'generic');
      expect(p.warnings, contains(SmsWarning.genericParser));
    });

    test('a recognized sender with a non-matching signature falls to '
        'generic', () {
      final p = _parsed(
        _scan(
          'Purchase of EGP 10.00 at Example Cafe',
          sender: 'BANKA',
          registry: registry,
        ),
      );
      expect(p.bankId, 'generic');
    });

    test('a profile whose templates find nothing gives way to the generic '
        'last try; fields are never merged', () {
      final p = _parsed(
        _scan(
          'BANKA: Your account was debited with EGP 40.00',
          sender: 'BANKA',
          registry: registry,
        ),
      );
      expect(p.bankId, 'generic');
      expect(p.parserId, 'generic');
      expect(p.amount, const Money.egp(4000));
      expect(p.currencyCodeRead, 'EGP');
      // No default currency or other field from banka leaked in.
      expect(p.warnings, isNot(contains(SmsWarning.currencyInferred)));
    });

    test('several candidates: highest overall wins, then registry order', () {
      BankProfile shared(String id, {required bool verified}) => BankProfile(
        id: id,
        version: 1,
        verified: verified,
        signatures: [ContentSignature(RegExp('shared'))],
        templates: [
          SmsTemplate(
            name: 't',
            kind: SmsKind.cardPurchase,
            direction: SmsDirection.debit,
            language: SmsLanguage.en,
            pattern: RegExp(
              r'shared (?<currency>egp) (?<amount>\d{1,6}) '
              r'on (?<date>\d\d/\d\d/\d{4})',
            ),
          ),
        ],
      );
      const text = 'shared EGP 10 on 04/03/2026';
      final ranked = SmsParserRegistry(
        profiles: [
          shared('first', verified: false),
          shared('second', verified: true),
        ],
      );
      final p = _parsed(_scan(text, sender: null, registry: ranked));
      expect(p.bankId, 'second');
      expect(p.confidence.overall, OverallConfidence.high);
      final tied = SmsParserRegistry(
        profiles: [
          shared('first', verified: true),
          shared('second', verified: true),
        ],
      );
      expect(
        _parsed(_scan(text, sender: null, registry: tied)).bankId,
        'first',
      );
    });
  });

  group('templates and confidence', () {
    test('a verified bank anchored template reads High on a scan', () {
      final registry = SmsParserRegistry(profiles: [_bankB(verified: true)]);
      final p = _parsed(
        _scan(
          'BANKB: EGP 10.00 spent at Example Cafe on 04/03/2026',
          sender: 'BANKB',
          registry: registry,
        ),
      );
      expect(p.confidence.overall, OverallConfidence.high);
      expect(p.merchant, 'Example Cafe');
      expect(p.warnings, isNot(contains(SmsWarning.unverifiedProfile)));
    });

    test('an unverified bank profile is capped at Medium with a warning', () {
      final registry = SmsParserRegistry(profiles: [_bankB()]);
      final p = _parsed(
        _scan(
          'BANKB: EGP 10.00 spent at Example Cafe on 04/03/2026',
          sender: 'BANKB',
          registry: registry,
        ),
      );
      expect(p.confidence.overall, OverallConfidence.medium);
      expect(p.warnings, contains(SmsWarning.unverifiedProfile));
    });

    test('generic and paste results are never High', () {
      final generic = _parsed(
        _scan('Purchase of EGP 10.00 at Example Cafe on 04/03/2026'),
      );
      expect(generic.confidence.overall, OverallConfidence.medium);
      for (final c in generic.confidence.fields.values) {
        expect(c.level, isNot(FieldConfidenceLevel.high));
      }
      final registry = SmsParserRegistry(profiles: [_bankB(verified: true)]);
      final pasted = _parsed(
        _paste(
          'BANKB: EGP 10.00 spent at Example Cafe on 04/03/2026',
          registry: registry,
        ),
      );
      expect(pasted.confidence.overall, OverallConfidence.medium);
    });

    test('template groups: merchant as written, time, last4, ref, fee and '
        'foreign amount (FR-059)', () {
      final registry = SmsParserRegistry(profiles: [_bankA]);
      final p = _parsed(
        _scan(
          'BANKA: Purchase of EGP 1,250.00 at Example Store on 04/03/2026 '
          '10:15 original USD 25.00 fee EGP 12.50 card XX0000 ref Ab12CD34',
          sender: 'BANKA',
          registry: registry,
        ),
      );
      expect(p.amount, const Money.egp(125000));
      expect(p.merchant, 'Example Store');
      expect(p.merchantKey, 'example store');
      expect(p.occurredOn, DateTime(2026, 3, 4));
      expect(p.timeMinutes, 615);
      expect(p.cardLast4, '0000');
      expect(p.referenceId, 'Ab12CD34');
      expect(p.fee, const Money.egp(1250));
      expect(p.foreignAmount, const Money.fromMinorUnits(2500, Currency.usd));
      expect(p.foreignAmountText, 'USD 25.00');
      expect(p.warnings, contains(SmsWarning.foreignCurrencyBilledAmount));
      expect(p.toString(), isNot(contains('Ab12CD34')));
      expect(p.toString(), isNot(contains('1250')));
    });

    test('a template amount with an unsupported currency', () {
      final registry = SmsParserRegistry(profiles: [_bankA]);
      final p = _parsed(
        _scan(
          'BANKA: Purchase of KWD 12.500 at Example Store on 04/03/2026',
          sender: 'BANKA',
          registry: registry,
        ),
      );
      expect(p.amount, isNull);
      expect(p.currencyCodeRead, 'KWD');
      expect(p.warnings, contains(SmsWarning.unsupportedCurrency));
    });

    test('a template amount with a decimal comma is unreadable', () {
      final registry = SmsParserRegistry(profiles: [_bankA]);
      expect(
        _scan(
          'BANKA: Purchase of EGP 100,50 at Example Store on 04/03/2026',
          sender: 'BANKA',
          registry: registry,
        ),
        const Unreadable(UnreadableReason.amountUnreadable, bankId: 'banka'),
      );
    });
  });

  group('extraction details (generic)', () {
    test('merchant, last four, reference', () {
      final p = _parsed(
        _scan(
          'Purchase of EGP 125.50 at Example Cafe on 04/03/2026 10:15 with '
          'card ****0000. Ref: TX12345678',
        ),
      );
      expect(p.kind, SmsKind.cardPurchase);
      expect(p.merchant, 'Example Cafe');
      expect(p.cardLast4, '0000');
      expect(p.referenceId, 'TX12345678');
      expect(p.timeMinutes, 615);
    });

    test('transfer counterparty and an existing-person match', () {
      const options = ParserOptions(
        peopleNames: [PersonNameRef(id: 'person-1', normalizedName: 'ahmed')],
      );
      final p = _parsed(
        _scan('EGP 500.00 transferred to Ahmed via InstaPay', options: options),
      );
      expect(p.kind, SmsKind.transferOut);
      expect(p.counterparty, 'Ahmed');
      // Expense stays the default; the person is the one-tap Given (FR-054).
      expect(p.suggestedType, SuggestedRecordType.expense);
      expect(p.suggestedPersonId, 'person-1');
    });

    test('output never carries a full card number, a mobile or the '
        'balance', () {
      final p = _parsed(
        _scan(
          'Purchase of EGP 100.00 at Example Cafe card 0000111122223333. '
          'Available balance EGP 98,765.00',
        ),
      );
      final values = [
        p.merchant,
        p.counterparty,
        p.cardLast4,
        p.referenceId,
        p.amountCandidatesMinor.join(','),
      ].whereType<String>().join(' ');
      expect(values, isNot(contains('0000111122223333')));
      expect(values, isNot(contains('98765')));
      expect(p.amount, const Money.egp(10000));
      final mobile = _parsed(
        _scan('EGP 50.00 sent to Ahmed 01012345678 via InstaPay'),
      );
      expect(mobile.counterparty, isNot(contains('01012345678')));
    });
  });

  group('hostile input (FR-098)', () {
    test('empty, whitespace, non-text, too long', () {
      expect(_paste(''), const Unreadable(UnreadableReason.empty));
      expect(_paste(' \n\u{200F}\t'), const Unreadable(UnreadableReason.empty));
      expect(
        _paste('Purchase\u{0000}\u{0001} of EGP 10'),
        const Unreadable(UnreadableReason.nonText),
      );
      expect(
        _paste('Purchase of EGP 10 ${'x' * 4000}'),
        const Unreadable(UnreadableReason.tooLong),
      );
    });

    test('truncated messages never throw', () {
      const full =
          'Purchase of EGP 1,250.50 at Example Cafe on 04/03/2026 10:15';
      for (var i = 0; i <= full.length; i++) {
        expect(() => _paste(full.substring(0, i)), returnsNormally);
      }
    });

    test('adversarial strings finish within the budget', () {
      final parser = _parser();
      final inputs = [
        '1,' * 1999,
        '${'1 ' * 1999}1',
        'at ' * 1333,
        'EGP ' * 999,
        '${'9' * 3999}.',
        '٠' * 3999,
        'a' * 3999,
        '${'04/' * 1300}2026',
        'ref ' * 999,
        '${'x' * 1990}${'1' * 8}',
        'تم خصم ' * 570,
        '${'[' * 1000}${']' * 1000}',
      ];
      for (final input in inputs) {
        final watch = Stopwatch()..start();
        final result = parser.parse(
          SmsParseInput(rawText: input, source: SmsSource.paste),
        );
        watch.stop();
        expect(result, isNotNull);
        expect(
          watch.elapsedMilliseconds,
          lessThan(500),
          reason: input.substring(0, 20),
        );
      }
    });

    test('every engine pattern finishes on 10,000 adversarial characters in '
        'under 50 ms', () {
      final adversarial = [
        '1,' * 5000,
        '1 ' * 5000,
        'a' * 10000,
        '${'0' * 9999}x',
        '04/' * 3333,
        'ref: ' * 2000,
        '${'x' * 9990}0000',
      ];
      for (final pattern in RuleBasedSmsParser.patternsForTest) {
        for (final input in adversarial) {
          pattern.allMatches(input).length; // warm up
          final watch = Stopwatch()..start();
          pattern.allMatches(input).length;
          watch.stop();
          expect(
            watch.elapsedMilliseconds,
            lessThan(50),
            reason: '${pattern.pattern} on ${input.substring(0, 6)}',
          );
        }
      }
    });

    test('never throws over random strings; deterministic', () {
      final random = Random(23);
      const alphabet =
          '0123456789٠١٢٣٤٥٦٧٨٩,.:/-* EGPegpLE\$€تم خصم جنيه رصيد '
          'purchase at on debited credited fee otp \u{200F}\u{202E}\n';
      final parser = _parser();
      for (var i = 0; i < 400; i++) {
        final length = random.nextInt(300);
        final text = String.fromCharCodes(
          List.generate(
            length,
            (_) => alphabet.codeUnitAt(random.nextInt(alphabet.length)),
          ),
        );
        final input = SmsParseInput(rawText: text, source: SmsSource.paste);
        final a = parser.parse(input);
        final b = parser.parse(input);
        expect(a, b);
        expect(a, isNot(const Unreadable(UnreadableReason.parserError)));
      }
    });
  });

  group('convergence fixes (P1-P11)', () {
    void expectNonTransactional(String text, NonTransactionalReason reason) {
      final result = _paste(text);
      expect(result, isA<NonTransactional>(), reason: text);
      expect((result as NonTransactional).reason, reason, reason: text);
    }

    test('P1: an abbreviated balance (`Avl. Bal.`) is never the amount', () {
      final onlyBalance = _paste(
        'Salary credited to a/c ****0000. Avl. Bal. EGP 12,500.00',
      );
      expect(onlyBalance, isA<Unreadable>(), reason: '$onlyBalance');
      expect((onlyBalance as Unreadable).reason, UnreadableReason.noAmount);

      final p = _parsed(
        _paste(
          'Your account was credited with EGP 500.00. Avl. Bal. EGP 5,500.00',
        ),
      );
      expect(p.amount, const Money.egp(50000));
      expect(p.amountCandidatesMinor, isEmpty);
    });

    test('P1: a real sentence end still separates the balance sentence', () {
      final p = _parsed(
        _paste('EGP 250.00 debited at Example Cafe. Balance EGP 1,000.00'),
      );
      expect(p.amount, const Money.egp(25000));
    });

    test('P2: the Arabic comma between digits groups thousands, never '
        'drops the leading group', () {
      final p = _parsed(_paste('تم خصم ١،٥٠٠ جنيه من حسابك'));
      expect(p.amount, const Money.egp(150000));
      final malformed = _paste('تم خصم ١،٥٠ جنيه من حسابك');
      expect(malformed, isA<Unreadable>(), reason: '$malformed');
      expect(
        (malformed as Unreadable).reason,
        UnreadableReason.amountUnreadable,
      );
      expect(SmsAmountReader.parse('1،500', Currency.egp), isNotNull);
      expect(SmsAmountReader.parse('1،50', Currency.egp), isNull);
    });

    test('P3: a transaction is not a promotion because of a substring or a '
        'URL', () {
      final ar = _parsed(
        _paste(
          'البنك التجاري الدولي: تمت عملية شراء بمبلغ 540 جنيه لدى معرض المثال',
        ),
      );
      expect(ar.amount, const Money.egp(54000));
      expect(ar.kind, SmsKind.cardPurchase);
      final en = _parsed(
        _paste('Purchase of EGP 250.00 at Example Cafe. Visit www.example.com'),
      );
      expect(en.amount, const Money.egp(25000));
      // Real promotions still are.
      expectNonTransactional(
        'Get 0% installment on purchases above EGP 1,000. Offer ends soon!',
        NonTransactionalReason.promotion,
      );
      expectNonTransactional(
        'عرض خاص: خصم 10% على مشترياتك',
        NonTransactionalReason.promotion,
      );
      expectNonTransactional(
        'لدينا عروض جديدة، زوروا موقعنا www.example.com',
        NonTransactionalReason.promotion,
      );
    });

    test('P4: a currency-less card last four is never an amount', () {
      final p = _parsed(
        _paste('Card ending with 0000 debited 250.00 at Example Cafe'),
      );
      expect(p.amountCandidatesMinor, [25000]);
      expect(p.cardLast4, '0000');
    });

    test('P5: a safety reminder or a QR code word is not an OTP', () {
      final en = _parsed(
        _paste(
          'Your card ****0000 was charged EGP 500.00 at Example Shop. '
          'Never share your card details.',
        ),
      );
      expect(en.amount, const Money.egp(50000));
      final ar = _parsed(_paste('تم الدفع باستخدام رمز QR بمبلغ 200 جنيه'));
      expect(ar.amount, const Money.egp(20000));
      expect(ar.direction, SmsDirection.debit);
      // Real OTPs still are.
      for (final text in [
        'Your code is 482913. Do not share it.',
        'رمزك هو 482913 لا تشاركه مع أحد',
        'كلمة المرور لمرة واحدة 482913',
      ]) {
        expectNonTransactional(text, NonTransactionalReason.otp);
      }
    });

    test('P6: a posted refund for a failed transaction is not a decline', () {
      final p = _parsed(
        _paste(
          'Refund of EGP 500.00 for a failed transaction has been credited '
          'to your card ****0000',
        ),
      );
      expect(p.kind, SmsKind.refund);
      expect(p.amount, const Money.egp(50000));
      expectNonTransactional(
        'Your purchase of EGP 300.00 at Example Shop failed.',
        NonTransactionalReason.declined,
      );
    });

    test('P7: a due-date or statement reminder is not a transaction', () {
      for (final text in [
        'Reminder: your loan installment of EGP 2,000.00 is due on 05/04/2026',
        'Statement ready. Total due EGP 5,000.00. Minimum payment '
            'EGP 250.00 due by 15/03',
        'تذكير: قسط القرض بمبلغ 2000 جنيه مستحق بتاريخ 05/04/2026',
      ]) {
        expectNonTransactional(text, NonTransactionalReason.other);
      }
      // A posted settlement is still a transaction.
      final p = _parsed(
        _paste('Your loan installment of EGP 2,000.00 has been debited'),
      );
      expect(p.kind, SmsKind.cardOrLoanSettlement);
    });

    test('P8: feminine `تمت` verbs are posted verbs', () {
      final added = _parsed(_paste('تمت إضافة 1,500 جنيه في حسابك'));
      expect(added.direction, SmsDirection.credit);
      expect(added.amount, const Money.egp(150000));
      final withdrawn = _parsed(_paste('تمت عملية سحب 500 جنيه'));
      expect(withdrawn.direction, SmsDirection.debit);
      expect(withdrawn.amount, const Money.egp(50000));
    });

    test('P10: `مدين` does not match inside `مدينة`', () {
      final p = _parsed(_paste('تم إيداع 500 جنيه في حسابك فرع مدينة نصر'));
      expect(p.direction, SmsDirection.credit);
      expect(p.amount, const Money.egp(50000));
      final debit = _parsed(_paste('عملية مدينة بمبلغ 500 جنيه على حسابك'));
      expect(debit.direction, SmsDirection.debit);
      final debitMasc = _parsed(_paste('مبلغ مدين 500 جنيه على حسابك'));
      expect(debitMasc.direction, SmsDirection.debit);
    });

    test('P11: `may` followed by a verb is not a month', () {
      final p = _parsed(
        _paste(
          'Purchase of EGP 250.00 at Example Cafe. A fee of EGP 10 may apply',
        ),
      );
      expect(p.occurredOn, isNull);
      expect(
        SmsDateReader.findDate(
          'on 10 may 2026',
          order: DateOrder.dayMonth,
          now: _now,
        )?.date,
        DateTime(2026, 5, 10),
      );
    });
  });

  test('currentVersions and allowedSenders come from the registry', () {
    final parser = _parser();
    // 023 T117: the shipped registry now holds the seven bank profiles.
    expect(parser.currentVersions, SmsParserRegistry.standard.currentVersions);
    expect(parser.currentVersions['generic'], 1);
    expect(parser.allowedSenders, SmsParserRegistry.standard.allowedSenders);
    expect(parser.allowedSenders, isNotEmpty);
    final generic = _parser(registry: SmsParserRegistry());
    expect(generic.currentVersions, {'generic': 1});
    expect(generic.allowedSenders, isEmpty);
    final withBanks = _parser(
      registry: SmsParserRegistry(profiles: [_bankA, _bankB()]),
    );
    expect(withBanks.allowedSenders, {'BANKA', 'BANKB'});
    expect(withBanks.currentVersions, {'banka': 1, 'bankb': 2, 'generic': 1});
  });
}
