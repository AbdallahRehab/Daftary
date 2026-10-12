import 'dart:io';

import 'package:daftary/core/money/numeral_parser.dart';
import 'package:daftary/features/sms_import/data/parsing/rule_based_sms_parser.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_message_splitter.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_parser_registry.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_text_normalizer.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_confidence.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_result.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/sms_fixture_loader.dart';

// 023 T052: the golden corpus harness (parser-contract §9, SC-001).
// Iterates test/fixtures/sms/**; adding a case adds no code. Only the keys
// present in a case's JSON are asserted.

final SmsParserRegistry _registry = SmsParserRegistry.standard;

/// Seed keys resolve to `cat-<key>`, so `suggestion.categoryKey` can be
/// checked.
const ParserOptions _options = ParserOptions(
  activeCategoryIdsBySeedKey: {
    'other': 'cat-other',
    'other_income': 'cat-other_income',
    'salary': 'cat-salary',
    'restaurants': 'cat-restaurants',
    'groceries': 'cat-groceries',
    'electricity': 'cat-electricity',
    'water': 'cat-water',
    'phone': 'cat-phone',
    'internet': 'cat-internet',
  },
);

SmsSource _source(String value) => SmsSource.values.firstWhere(
  (s) => s.dbValue == value,
  orElse: () => throw StateError('unknown source $value'),
);

String _snake(String camel) =>
    camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

ParseResult _parse(SmsFixture f, String text) =>
    RuleBasedSmsParser(clock: FixedClock(f.now), registry: _registry).parse(
      SmsParseInput(
        rawText: text,
        source: _source(f.source),
        sender: f.sender,
        receivedAt: f.receivedAt,
      ),
      options: _options,
    );

String _classification(ParseResult r) => switch (r) {
  ParsedTransaction() => 'transaction',
  NonTransactional() => 'non_transactional',
  Unreadable() => 'unreadable',
  NotRecognized() => 'not_recognized',
};

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String? _confidenceToken(ParseConfidence c, SmsField field) {
  final value = c[field];
  if (value == null) return null;
  if (value.isInferred) return 'inferred';
  return 'read:${value.level.name}';
}

/// Asserts every expectation key present in [e] against [r].
void _expectResult(ParseResult r, Map<String, dynamic> e, String where) {
  if (e.containsKey('classification')) {
    expect(_classification(r), e['classification'], reason: where);
  }
  if (e.containsKey('reason')) {
    final reason = switch (r) {
      NonTransactional(:final reason) => _snake(reason.name),
      Unreadable(:final reason) => _snake(reason.name),
      _ => null,
    };
    expect(reason, e['reason'], reason: where);
  }
  if (r is! ParsedTransaction) return;
  void check(String key, Object? actual) {
    if (e.containsKey(key)) expect(actual, e[key], reason: '$where $key');
  }

  check('bankId', r.bankId);
  check('ruleVersion', r.ruleVersion);
  check('kind', r.kind.dbValue);
  check('direction', r.direction.dbValue);
  check('amountMinor', r.amount?.minorUnits);
  check('amountCandidatesMinor', r.amountCandidatesMinor);
  check('currency', r.amount?.currency.code ?? r.currencyCodeRead);
  check('date', r.occurredOn == null ? null : _day(r.occurredOn!));
  check('dateInferred', r.confidence.isInferred(SmsField.date));
  check('timeMinutes', r.timeMinutes);
  check('merchant', r.merchant);
  check('counterparty', r.counterparty);
  check('last4', r.cardLast4);
  check('refPresent', r.referenceId != null);
  check('feeMinor', r.fee?.minorUnits);
  if (e['suggestion'] is Map) {
    final s = e['suggestion'] as Map<String, dynamic>;
    if (s.containsKey('type')) {
      expect(r.suggestedType.dbValue, s['type'], reason: '$where suggestion');
    }
    if (s.containsKey('categoryKey')) {
      expect(
        r.suggestedCategoryKeyOrId,
        s['categoryKey'] == null ? null : 'cat-${s['categoryKey']}',
        reason: '$where category',
      );
    }
  }
  if (e['warnings'] is List) {
    expect(
      r.warnings.map((w) => w.dbValue),
      containsAll(e['warnings'] as List<dynamic>),
      reason: '$where warnings',
    );
  }
  if (e['confidence'] is Map) {
    final c = e['confidence'] as Map<String, dynamic>;
    for (final entry in c.entries) {
      if (entry.key == 'overall') {
        expect(r.confidence.overall.dbValue, entry.value, reason: where);
        continue;
      }
      final field = SmsField.values.firstWhere((f) => f.name == entry.key);
      expect(
        _confidenceToken(r.confidence, field),
        entry.value,
        reason: '$where confidence.${entry.key}',
      );
    }
  }
}

void main() {
  final fixtures = loadSmsFixtures();

  test('the corpus is present', () {
    expect(fixtures.length, greaterThanOrEqualTo(50));
    for (final folder in ['_noise', '_paste', '_cross', '_hostile']) {
      expect(fixtures.where((f) => f.folder == folder), isNotEmpty);
    }
  });

  group('anonymization guard (fails the build)', () {
    final sixteen = RegExp(r'\d{16}');
    final mobile = RegExp(r'(?<!\d)(?:\+?20|0)1[0125]\d{8}(?!\d)');

    String digitsJoined(String text) => NumeralParser.toWesternDigits(
      text,
    ).replaceAllMapped(RegExp(r'(\d)[ \-](?=\d)'), (m) => m[1]!);

    test('every case is synthetic', () {
      for (final f in fixtures) {
        expect(f.meta['synthetic'], isTrue, reason: f.path);
      }
    });

    test('no 16-digit run and no real-looking Egyptian mobile', () {
      final files = Directory(kSmsFixtureRoot)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.txt') || f.path.endsWith('.json'));
      final hex = RegExp(r'^[0-9a-f]{64}$');
      for (final file in files) {
        if (file.uri.pathSegments.last == '_fingerprints.json') {
          // The golden file holds HMAC-SHA256 hex digests, which can contain
          // 16 decimal digits in a row by chance (023 T117: ~1% per digest).
          // Its keys are still digit-scanned, and every value must be
          // exactly one digest, so no message content can hide in it.
          final golden = readFixtureJson('_fingerprints.json');
          for (final entry in golden.entries) {
            final key = digitsJoined(entry.key);
            expect(sixteen.hasMatch(key), isFalse, reason: entry.key);
            expect(mobile.hasMatch(key), isFalse, reason: entry.key);
            expect(entry.value, matches(hex), reason: entry.key);
          }
          continue;
        }
        final text = digitsJoined(file.readAsStringSync());
        expect(sixteen.hasMatch(text), isFalse, reason: file.path);
        expect(mobile.hasMatch(text), isFalse, reason: file.path);
      }
    });
  });

  test('rule versions are pinned (_versions.json == currentVersions)', () {
    expect(readFixtureJson('_versions.json'), _registry.currentVersions);
  });

  test('cross-bank invariant: no bank sample matches another bank '
      '(FR-028)', () {
    for (final f in fixtures.where((f) => f.isBank)) {
      final folded = const SmsTextNormalizerImpl()
          .normalize(f.text)
          .forMatching;
      for (final profile in _registry.profiles) {
        if (profile.id == f.folder) continue;
        expect(
          profile.signatures.any((s) => s.matches(folded)),
          isFalse,
          reason: '${f.path} matches ${profile.id}',
        );
      }
    }
  });

  test('SC-001 per-bank gate: >= 95% on amount, currency, direction, '
      'date', () {
    final byBank = <String, List<int>>{};
    for (final f in fixtures.where((f) => f.isBank)) {
      final result = _parse(f, f.text);
      final tally = byBank.putIfAbsent(f.folder, () => [0, 0]);
      for (final key in ['amountMinor', 'currency', 'direction', 'date']) {
        if (!f.meta.containsKey(key)) continue;
        tally[1]++;
        if (result is! ParsedTransaction) continue;
        final actual = switch (key) {
          'amountMinor' => result.amount?.minorUnits,
          'currency' => result.amount?.currency.code ?? result.currencyCodeRead,
          'direction' => result.direction.dbValue,
          _ => result.occurredOn == null ? null : _day(result.occurredOn!),
        };
        if (actual == f.meta[key]) tally[0]++;
      }
    }
    byBank.forEach((bank, tally) {
      expect(
        tally[0] / tally[1],
        greaterThanOrEqualTo(0.95),
        reason: '$bank: ${tally[0]}/${tally[1]}',
      );
    });
  });

  test('100% of _noise is rejected as non-transactional', () {
    final noise = fixtures.where((f) => f.folder == '_noise').toList();
    expect(noise.length, greaterThanOrEqualTo(15));
    for (final f in noise) {
      expect(_parse(f, f.text), isA<NonTransactional>(), reason: f.path);
    }
  });

  group('cases', () {
    final splitter = SmsMessageSplitterImpl(registry: _registry);
    for (final f in fixtures) {
      if (f.path.startsWith('_paste/envelopes/')) continue;
      test(f.path, () {
        final watch = Stopwatch()..start();
        if (f.meta.containsKey('failure')) {
          final failure = splitter.split(f.text).getLeft().toNullable();
          expect(failure, isA<InputTooLargeFailure>(), reason: f.path);
          final limit = (failure! as InputTooLargeFailure).limit;
          expect('input_too_large_${limit.name}', f.meta['failure']);
          return;
        }
        if (f.meta.containsKey('expectedItems')) {
          final messages = splitter
              .split(f.text)
              .getOrElse((l) => fail('split failed: $l'));
          final results = [for (final m in messages) _parse(f, m.text)];
          final items = results.whereType<ParsedTransaction>().toList();
          final expected = (f.meta['expectedItems'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
          expect(items, hasLength(expected.length), reason: f.path);
          for (var i = 0; i < expected.length; i++) {
            _expectResult(items[i], expected[i], '${f.path}[$i]');
          }
          if (f.meta.containsKey('skipped')) {
            expect(results.length - items.length, f.meta['skipped']);
          }
          return;
        }
        final result = _parse(f, f.text);
        expect(
          result,
          isNot(const Unreadable(UnreadableReason.parserError)),
          reason: f.path,
        );
        _expectResult(result, f.meta, f.path);
        if (result is ParsedTransaction && f.meta.containsKey('ruleVersion')) {
          expect(_registry.currentVersions[result.bankId], isNotNull);
        }
        watch.stop();
        expect(watch.elapsedMilliseconds, lessThan(500), reason: f.path);
      });
    }
  });
}
