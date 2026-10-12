import 'package:daftary/features/sms_import/data/parsing/bank_profile.dart';
import 'package:daftary/features/sms_import/data/parsing/fingerprint_normalizer.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_envelope_rules.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_message_splitter.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_parser_registry.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_splitter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/sms_fixture_loader.dart';

// 023 T046: paste/share splitting (FR-017, FR-017a, parser-contract §3).
// The envelope formats are the UNVERIFIED defaults of spikes/S5 (device
// spike not run); every fixture is re-authored and synthetic.
void main() {
  final splitter = SmsMessageSplitterImpl();

  List<String> bodies(String text) => splitter
      .split(text)
      .getOrElse((failure) => fail('unexpected $failure'))
      .map((m) => m.text)
      .toList();

  group('bounds (FR-017)', () {
    test('more than 10,000 characters is rejected; nothing is split', () {
      final result = splitter.split('a' * 10001);
      expect(
        result.getLeft().toNullable(),
        const InputTooLargeFailure(InputLimit.characters),
      );
      expect(splitter.split('a' * 10000).isRight(), isTrue);
    });

    test('more than 50 messages is rejected; 50 is accepted', () {
      String messages(int n) =>
          List.generate(n, (i) => 'Message $i EGP 1.00').join('\n\n');
      expect(bodies(messages(50)), hasLength(50));
      expect(
        splitter.split(messages(51)).getLeft().toNullable(),
        const InputTooLargeFailure(InputLimit.messages),
      );
    });

    test('empty chunks are dropped; indexes are consecutive', () {
      final result = splitter
          .split('\n\n  \nfirst\n\n\u{200F}\n\nsecond\n\n')
          .getOrElse((_) => fail('left'));
      expect(result.map((m) => m.text), ['first', 'second']);
      expect(result.map((m) => m.index), [0, 1]);
      expect(bodies(''), isEmpty);
    });

    test('a single long message is passed through for the parser', () {
      expect(bodies('x' * 5000).single, hasLength(5000));
    });
  });

  group('splitting', () {
    test('runs of blank lines separate messages; single breaks do not', () {
      expect(bodies('line one\nline two\n\n\n\nnext'), [
        'line one\nline two',
        'next',
      ]);
    });

    test('CRLF and CR line endings', () {
      expect(bodies('a\r\nb\r\n\r\nc\rd'), ['a\nb', 'c\nd']);
    });

    test('a profile messageStart splits inside a chunk when two or more lines '
        'match', () {
      final registry = SmsParserRegistry(
        profiles: [
          BankProfile(
            id: 'banka',
            version: 1,
            senders: const {'BANKA'},
            signatures: [ContentSignature(RegExp('banka'))],
            messageStart: RegExp(r'^banka:'),
          ),
        ],
      );
      final s = SmsMessageSplitterImpl(registry: registry);
      final parts = s
          .split('BANKA: one\ncontinued\nBANKA: two')
          .getOrElse((_) => fail('left'))
          .map((m) => m.text);
      expect(parts, ['BANKA: one\ncontinued', 'BANKA: two']);
      final single = s
          .split('BANKA: one\ncontinued')
          .getOrElse((_) => fail('left'))
          .map((m) => m.text);
      expect(single, ['BANKA: one\ncontinued']);
    });
  });

  group('envelope rules (conservative)', () {
    test('a header line is stripped only in header position', () {
      expect(bodies('Debited EGP 40.00\n04/03/2026 10:15'), [
        'Debited EGP 40.00\n04/03/2026 10:15',
      ]);
    });

    test('a lone header with no body is kept', () {
      expect(bodies('04/03/2026 10:15'), ['04/03/2026 10:15']);
    });

    test('a line with a currency token is never stripped', () {
      expect(
        SmsEnvelopeRules.isProtected('egp 100', registry: SmsParserRegistry()),
        isTrue,
      );
      expect(bodies('12345 EGP\nPurchase at Example Cafe'), [
        '12345 EGP\nPurchase at Example Cafe',
      ]);
    });

    test('an unknown lower-case first line is never taken for a sender', () {
      expect(bodies('purchase\n04/03/2026\nat Example Cafe'), [
        'purchase\n04/03/2026\nat Example Cafe',
      ]);
    });

    test('separator lines are boundaries', () {
      expect(bodies('one\n—————\ntwo\n= = = =\nthree'), [
        'one',
        'two',
        'three',
      ]);
    });

    test('the rules are versioned', () {
      expect(SmsEnvelopeRules.version, 1);
    });
  });

  group('every S5 envelope format (UNVERIFIED) fingerprints like the inbox '
      'copy (FR-017a)', () {
    const normalizer = FingerprintNormalizerV1();
    final fixtures = loadSmsFixtures().where(
      (f) => f.path.startsWith('_paste/envelopes/'),
    );

    test('the envelope corpus is present', () {
      expect(fixtures.length, greaterThanOrEqualTo(10));
    });

    for (final fixture in fixtures) {
      test(fixture.path, () {
        expect(fixture.meta['synthetic'], isTrue);
        expect(fixture.meta['unverifiedFormat'], isTrue);
        final expected = (fixture.meta['inboxBodies'] as List<dynamic>)
            .cast<String>();
        final split = bodies(fixture.text);
        expect(split, hasLength(expected.length));
        for (var i = 0; i < expected.length; i++) {
          expect(
            normalizer.normalize(split[i]),
            normalizer.normalize(expected[i]),
            reason: 'message $i',
          );
        }
      });
    }
  });

  test('SplitMessage.toString never prints the text', () {
    const message = SplitMessage(text: 'EGP 987654.32 Example Cafe', index: 0);
    expect(message.toString(), isNot(contains('987654')));
  });
}
