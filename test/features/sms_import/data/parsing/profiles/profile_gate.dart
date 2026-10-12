import 'package:daftary/features/sms_import/data/parsing/bank_profile.dart';
import 'package:daftary/features/sms_import/data/parsing/profiles/sms_template_kit.dart';
import 'package:daftary/features/sms_import/data/parsing/rule_based_sms_parser.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_parser_registry.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_text_normalizer.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_confidence.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_result.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/sms_fixture_loader.dart';

// 023 T110-T116: the per-bank gate (SC-001, FR-028), run for ONE profile
// in a registry of its own, so a profile is gated before it is registered
// (T117). Fixtures are synthetic (orchestrator decision OQ2/OQ3).
//
// The gate:
// 1. >= 95% on amount, currency, direction and date over the bank folder;
// 2. 100% noise rejection: the bank's own noise cases, and every `_noise`
//    case re-run with this bank's sender;
// 3. cross-bank non-match: the profile's signatures match no fixture of
//    another bank folder and no generic fixture (`_noise`, `_paste`,
//    `_cross`, `_hostile`);
// plus: every transaction case is read by this profile's own templates
// (never the generic fallback), every case's classification, kind,
// direction and expected fields hold, the profile is unverified and capped
// at Medium, and every pattern survives the adversarial budget.

SmsSource _source(String value) =>
    SmsSource.values.firstWhere((s) => s.dbValue == value);

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String _classification(ParseResult r) => switch (r) {
  ParsedTransaction() => 'transaction',
  NonTransactional() => 'non_transactional',
  Unreadable() => 'unreadable',
  NotRecognized() => 'not_recognized',
};

String _snake(String camel) =>
    camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

/// Runs the gate for [profile]. [minCases] is the minimum number of
/// transaction fixtures the folder must hold.
void runProfileGate(BankProfile profile, {int minCases = 20}) {
  final all = loadSmsFixtures();
  final mine = all.where((f) => f.folder == profile.id).toList();
  final registry = SmsParserRegistry(profiles: [profile]);

  ParseResult parse(SmsFixture f, {String? sender, String? source}) =>
      RuleBasedSmsParser(clock: FixedClock(f.now), registry: registry).parse(
        SmsParseInput(
          rawText: f.text,
          source: _source(source ?? f.source),
          sender: source == null ? f.sender : sender,
          receivedAt: source == null ? f.receivedAt : null,
        ),
      );

  final transactions = mine
      .where((f) => f.classification == 'transaction')
      .toList();
  final noise = mine
      .where((f) => f.classification == 'non_transactional')
      .toList();

  group('${profile.id} profile', () {
    test('is synthetic, unverified and well formed', () {
      expect(profile.verified, isFalse);
      expect(profile.isGeneric, isFalse);
      expect(profile.version, greaterThanOrEqualTo(1));
      expect(profile.senders, isNotEmpty);
      for (final sender in profile.senders) {
        expect(SmsParserRegistry.canonicalSender(sender), sender);
      }
      expect(profile.signatures, isNotEmpty);
      expect(profile.defaultCurrency, 'EGP');
      expect(profile.refIsUnique, isFalse);
      expect(profile.maskThreshold, BankProfile.defaultMaskThreshold);
      final names = profile.templates.map((t) => t.name).toList();
      expect(names.toSet(), hasLength(names.length), reason: 'unique names');
      for (final f in mine) {
        expect(f.meta['synthetic'], isTrue, reason: f.path);
      }
    });

    test('has a corpus: transactions in every kind, plus noise', () {
      expect(transactions.length, greaterThanOrEqualTo(minCases));
      expect(noise, isNotEmpty);
    });

    test('gate: >= 95% on amount, currency, direction and date', () {
      var hits = 0;
      var total = 0;
      for (final f in transactions) {
        final r = parse(f);
        for (final key in ['amountMinor', 'currency', 'direction', 'date']) {
          if (!f.meta.containsKey(key)) continue;
          total++;
          if (r is! ParsedTransaction) continue;
          final actual = switch (key) {
            'amountMinor' => r.amount?.minorUnits,
            'currency' => r.amount?.currency.code ?? r.currencyCodeRead,
            'direction' => r.direction.dbValue,
            _ => r.occurredOn == null ? null : _day(r.occurredOn!),
          };
          if (actual == f.meta[key]) hits++;
        }
      }
      expect(total, greaterThan(0));
      expect(hits / total, greaterThanOrEqualTo(0.95), reason: '$hits/$total');
    });

    test('every transaction case is read by this profile, capped at '
        'Medium with the unverified warning', () {
      for (final f in transactions) {
        final r = parse(f);
        expect(r, isA<ParsedTransaction>(), reason: f.path);
        final p = r as ParsedTransaction;
        expect(p.bankId, profile.id, reason: f.path);
        expect(p.ruleVersion, profile.ruleVersion, reason: f.path);
        expect(p.warnings, contains(SmsWarning.unverifiedProfile));
        expect(p.confidence.overall, isNot(OverallConfidence.high));
      }
    });

    test('every case meets its expectations', () {
      for (final f in mine) {
        final r = parse(f);
        final where = f.path;
        expect(_classification(r), f.classification, reason: where);
        if (f.meta.containsKey('reason')) {
          final reason = switch (r) {
            NonTransactional(:final reason) => _snake(reason.name),
            Unreadable(:final reason) => _snake(reason.name),
            _ => null,
          };
          expect(reason, f.meta['reason'], reason: where);
        }
        if (r is! ParsedTransaction) continue;
        void check(String key, Object? actual) {
          if (f.meta.containsKey(key)) {
            expect(actual, f.meta[key], reason: '$where $key');
          }
        }

        check('kind', r.kind.dbValue);
        check('direction', r.direction.dbValue);
        check('amountMinor', r.amount?.minorUnits);
        check('currency', r.amount?.currency.code ?? r.currencyCodeRead);
        check('date', r.occurredOn == null ? null : _day(r.occurredOn!));
        check('dateInferred', r.confidence.isInferred(SmsField.date));
        check('timeMinutes', r.timeMinutes);
        check('merchant', r.merchant);
        check('counterparty', r.counterparty);
        check('last4', r.cardLast4);
        check('feeMinor', r.fee?.minorUnits);
        if (f.meta['confidence'] is Map) {
          expect(
            r.confidence.overall.dbValue,
            (f.meta['confidence'] as Map)['overall'],
            reason: where,
          );
        }
      }
    });

    test('100% noise rejection (own noise and _noise with this sender)', () {
      for (final f in noise) {
        expect(parse(f), isA<NonTransactional>(), reason: f.path);
      }
      final sender = profile.senders.first;
      for (final f in all.where((f) => f.folder == '_noise')) {
        expect(
          parse(f, sender: sender, source: 'scan'),
          isA<NonTransactional>(),
          reason: '${f.path} as $sender',
        );
      }
    });

    test('cross-bank non-match: no other fixture matches the signatures', () {
      for (final f in all.where((f) => f.folder != profile.id)) {
        final folded = const SmsTextNormalizerImpl()
            .normalize(f.text)
            .forMatching;
        expect(
          profile.signatures.any((s) => s.matches(folded)),
          isFalse,
          reason: '${f.path} matches ${profile.id}',
        );
      }
    });

    test('a bare sender line never matches a signature (envelope rule)', () {
      for (final sender in profile.senders) {
        for (final line in [sender, '$sender:', '$sender 05/03/2026 10:15']) {
          final folded = SmsTextNormalizerImpl.fold(line);
          expect(
            profile.signatures.any((s) => s.matches(folded)),
            isFalse,
            reason: line,
          );
        }
      }
    });

    test('every pattern finishes on 10,000 adversarial characters in under '
        '50 ms', () {
      final adversarial = [
        '1,' * 5000,
        '1 ' * 5000,
        'a' * 10000,
        '${'0' * 9999}x',
        '04/' * 3333,
        'ref: ' * 2000,
        '${'x' * 9990}0000',
        'تم خصم ' * 1400,
        'egp 1 ' * 1600,
        'at ' * 3333,
      ];
      for (final pattern in SmsTemplateKit.patternsOf(profile)) {
        for (final input in adversarial) {
          pattern.allMatches(input).length; // warm up
          final watch = Stopwatch()..start();
          pattern.allMatches(input).length;
          watch.stop();
          expect(
            watch.elapsedMilliseconds,
            lessThan(50),
            reason: '${profile.id} ${input.substring(0, 6)}',
          );
        }
      }
    });
  });
}
