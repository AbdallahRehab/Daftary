import 'package:daftary/features/sms_import/data/parsing/registry_bank_reference_policy.dart';
import 'package:daftary/features/sms_import/data/parsing/rule_based_sms_parser.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_parser_registry.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_result.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

// 023 T117: the shipped registry holds every profile that passed its gate
// (T110-T116), in a fixed tie-break order, all synthetic and unverified.

void main() {
  final registry = SmsParserRegistry.standard;

  test('registers the seven gated bank profiles in order, plus generic', () {
    expect(registry.profiles.map((p) => p.id), [
      'nbe',
      'banque_misr',
      'cib',
      'qnb',
      'banque_du_caire',
      'aaib',
      'instapay',
    ]);
    expect(registry.generic.id, 'generic');
    expect(registry.currentVersions, {
      'nbe': 1,
      'banque_misr': 1,
      'cib': 1,
      'qnb': 1,
      'banque_du_caire': 1,
      'aaib': 1,
      'instapay': 1,
      'generic': 1,
    });
  });

  test('every bank profile is unverified, non-unique-ref and keeps the '
      'default mask threshold', () {
    for (final profile in registry.profiles) {
      expect(profile.verified, isFalse, reason: profile.id);
      expect(profile.refIsUnique, isFalse, reason: profile.id);
      expect(profile.maskThreshold, 12, reason: profile.id);
      expect(profile.isGeneric, isFalse, reason: profile.id);
    }
  });

  test('the allow-list is the union of the canonical profile senders', () {
    expect(registry.allowedSenders, {
      'NBE',
      'NBEGYPT',
      'BANQUEMISR',
      'BMISR',
      'CIB',
      'CIBEGYPT',
      'QNB',
      'QNBALAHLI',
      'BDC',
      'BANQUEDUCAIRE',
      'AAIB',
      'INSTAPAY',
    });
    final ids = [for (final p in registry.profiles) ...p.senders];
    expect(ids.toSet(), hasLength(ids.length), reason: 'no shared sender');
  });

  test('the reference policy treats every shipped bank as non-unique', () {
    final policy = RegistryBankReferencePolicy();
    for (final profile in registry.profiles) {
      expect(policy.refIsUnique(profile.id), isFalse);
    }
  });

  group('selection', () {
    final parser = RuleBasedSmsParser(clock: FixedClock(DateTime(2026, 3, 10)));
    ParseResult scan(String text, String sender) => parser.parse(
      SmsParseInput(
        rawText: text,
        source: SmsSource.inboxScan,
        sender: sender,
        receivedAt: DateTime(2026, 3, 9, 18, 30),
      ),
    );

    test('a recognized sender is parsed by its profile, capped at Medium', () {
      final result = scan(
        'NBE: Your card ending 4821 was charged EGP 250.00 at Example Market '
            'on 05/03/2026 at 14:30.',
        'NBE',
      );
      expect(result, isA<ParsedTransaction>());
      final parsed = result as ParsedTransaction;
      expect(parsed.bankId, 'nbe');
      expect(parsed.warnings, contains(SmsWarning.unverifiedProfile));
      expect(parsed.confidence.overall.dbValue, 'medium');
    });

    test('another bank\'s sender never selects the NBE profile (FR-028)', () {
      final result = scan(
        'NBE: Your card ending 4821 was charged EGP 250.00 at Example Market '
            'on 05/03/2026.',
        'CIB',
      );
      expect(result, isA<ParsedTransaction>());
      expect((result as ParsedTransaction).bankId, 'generic');
    });

    test('a recognized sender with unmatched content falls to generic', () {
      final result = scan(
        'Purchase of EGP 99.00 at Example Cafe on 07/03/2026',
        'NBE',
      );
      expect(result, isA<ParsedTransaction>());
      expect((result as ParsedTransaction).bankId, 'generic');
    });
  });
}
