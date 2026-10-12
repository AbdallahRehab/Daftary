import 'dart:io';

import 'package:daftary/core/confidence/field_confidence.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_confidence.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_result.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:flutter_test/flutter_test.dart';

/// 023 T021: parse result and confidence types (parser-contract §4, §6).
void main() {
  ParseConfidence confidence({
    OverallConfidence overall = OverallConfidence.high,
  }) => ParseConfidence(
    fields: {
      SmsField.amount: FieldConfidence.read(FieldConfidenceLevel.high),
      SmsField.date: const FieldConfidence.inferred(),
    },
    overall: overall,
  );

  ParsedTransaction parsed({
    Money? amount = const Money.egp(12550),
    String? referenceId = 'REF000000',
    String? merchant = 'Example Cafe',
  }) => ParsedTransaction(
    bankId: 'nbe',
    parserId: 'nbe',
    ruleVersion: 'nbe@1',
    kind: SmsKind.cardPurchase,
    direction: SmsDirection.debit,
    suggestedType: SuggestedRecordType.expense,
    confidence: confidence(),
    amount: amount,
    merchant: merchant,
    referenceId: referenceId,
    cardLast4: '0000',
    warnings: const {SmsWarning.dateInferred},
  );

  group('ParseConfidence', () {
    test('equality by fields and overall', () {
      expect(confidence(), confidence());
      expect(
        confidence(),
        isNot(confidence(overall: OverallConfidence.medium)),
      );
    });

    test('lookup and inferred check', () {
      final c = confidence();
      expect(c[SmsField.amount]!.level, FieldConfidenceLevel.high);
      expect(c[SmsField.merchant], isNull);
      expect(c.isInferred(SmsField.date), isTrue);
      expect(c.isInferred(SmsField.amount), isFalse);
    });

    test('fields are unmodifiable', () {
      expect(
        () => confidence().fields[SmsField.time] =
            const FieldConfidence.inferred(),
        throwsUnsupportedError,
      );
    });

    test('the required set is amount, currency, direction, date', () {
      expect(SmsField.required, {
        SmsField.amount,
        SmsField.currency,
        SmsField.direction,
        SmsField.date,
      });
    });

    test('OverallConfidence round-trips; unknown -> low', () {
      for (final level in OverallConfidence.values) {
        expect(OverallConfidence.fromDb(level.dbValue), level);
      }
      expect(OverallConfidence.fromDb('none'), OverallConfidence.low);
      expect(OverallConfidence.fromDb(null), OverallConfidence.low);
    });
  });

  group('ParseResult equality', () {
    test('ParsedTransaction', () {
      expect(parsed(), parsed());
      expect(parsed(), isNot(parsed(amount: const Money.egp(1))));
      expect(parsed(), isNot(parsed(referenceId: 'OTHER')));
    });

    test('NonTransactional, NotRecognized, Unreadable', () {
      expect(
        const NonTransactional(NonTransactionalReason.otp),
        const NonTransactional(NonTransactionalReason.otp),
      );
      expect(
        const NonTransactional(NonTransactionalReason.otp),
        isNot(const NonTransactional(NonTransactionalReason.promotion)),
      );
      expect(const NotRecognized(), const NotRecognized());
      expect(
        const Unreadable(UnreadableReason.noAmount, bankId: 'cib'),
        const Unreadable(UnreadableReason.noAmount, bankId: 'cib'),
      );
      expect(
        const Unreadable(UnreadableReason.noAmount),
        isNot(const Unreadable(UnreadableReason.tooLong)),
      );
    });

    test('the four variants are distinct', () {
      final results = <ParseResult>[
        parsed(),
        const NonTransactional(NonTransactionalReason.other),
        const NotRecognized(),
        const Unreadable(UnreadableReason.empty),
      ];
      expect(results.toSet(), hasLength(4));
    });

    test('collections are unmodifiable', () {
      expect(
        () => parsed().warnings.add(SmsWarning.genericParser),
        throwsUnsupportedError,
      );
      expect(
        () => parsed().amountCandidatesMinor.add(1),
        throwsUnsupportedError,
      );
    });
  });

  group('privacy', () {
    test('toString never prints the amount, merchant, reference or card', () {
      final text = parsed(
        amount: const Money.egp(987654),
        referenceId: 'REF555111',
        merchant: 'Sentinel Shop',
      ).toString();
      expect(text, isNot(contains('987654')));
      expect(text, isNot(contains('555111')));
      expect(text, isNot(contains('Sentinel')));
      expect(text, isNot(contains('0000')));
    });

    test('ParsedTransaction has no balance, OTP or full account field '
        '(FR-031)', () {
      final source = File(
        'lib/features/sms_import/domain/entities/parse_result.dart',
      ).readAsStringSync();
      final fieldNames = RegExp(
        r'^\s+final [\w<>?, ]+ (\w+);',
        multiLine: true,
      ).allMatches(source).map((m) => m.group(1)!.toLowerCase());
      for (final name in fieldNames) {
        expect(name, isNot(contains('balance')));
        expect(name, isNot(contains('otp')));
        expect(name, isNot(contains('account')));
        expect(name, isNot(contains('cardnumber')));
      }
    });
  });
}
