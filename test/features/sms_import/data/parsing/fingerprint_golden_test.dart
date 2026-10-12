import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:daftary/features/sms_import/data/crypto/hmac_fingerprint_hasher.dart';
import 'package:daftary/features/sms_import/data/parsing/fingerprint_normalizer.dart';
import 'package:daftary/features/sms_import/data/parsing/generic_profile.dart';
import 'package:daftary/features/sms_import/data/parsing/rule_based_sms_parser.dart';
import 'package:daftary/features/sms_import/data/parsing/bank_profile.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_parser_registry.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_result.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/sms_fixture_loader.dart';

// 023 T164: the frozen FingerprintNormalizer v1 (FR-023, analysis H1).
//
// Every fixture's fingerprint, computed with a fixed test key, is pinned in
// test/fixtures/sms/_fingerprints.json. Any edit to
// lib/features/sms_import/data/parsing/fingerprint_normalizer.dart that
// changes output fails here. A changed fingerprint is never updated: that
// needs `fp2|` and a migration (out of v1 scope).
//
// New fixtures: run once with SMS_FINGERPRINTS_ADD_MISSING=1 to append
// their entries. Existing entries are never rewritten by that mode.

const String _goldenPath = '$kSmsFixtureRoot/_fingerprints.json';
const String _frozenFile =
    'lib/features/sms_import/data/parsing/fingerprint_normalizer.dart';
const String _portFile =
    'lib/features/sms_import/domain/services/fingerprint_normalizer.dart';

class _FixedKeyStore extends FakeSmsKeyStore {
  @override
  Future<Uint8List> macKey() async =>
      Uint8List.fromList(List.generate(32, (i) => i));
}

final HmacFingerprintHasher _hasher = HmacFingerprintHasher(_FixedKeyStore());
const FingerprintNormalizerV1 _normalizer = FingerprintNormalizerV1();

Future<Map<String, String>> _computeAll() async => {
  for (final f in loadSmsFixtures())
    f.path: await _hasher.fingerprint(_normalizer.normalize(f.text)),
};

List<String> _imports(String path) => RegExp(
  r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
  multiLine: true,
).allMatches(File(path).readAsStringSync()).map((m) => m[1]!).toList();

void main() {
  test('every fixture fingerprint equals its pinned value', () async {
    final computed = await _computeAll();
    final file = File(_goldenPath);
    final pinned = file.existsSync()
        ? (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)
              .cast<String, String>()
        : <String, String>{};
    final missing = computed.keys.where((k) => !pinned.containsKey(k)).toList();
    if (missing.isNotEmpty &&
        Platform.environment['SMS_FINGERPRINTS_ADD_MISSING'] == '1') {
      final merged = {...pinned, for (final k in missing) k: computed[k]!};
      final sorted = {
        for (final k in merged.keys.toList()..sort()) k: merged[k],
      };
      file.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
      );
      pinned.addAll({for (final k in missing) k: computed[k]!});
    }
    expect(
      missing.where((k) => !pinned.containsKey(k)),
      isEmpty,
      reason: 'unpinned fixtures (see the file header)',
    );
    for (final entry in pinned.entries) {
      expect(computed[entry.key], entry.value, reason: entry.key);
    }
    expect(pinned.keys.toSet(), computed.keys.toSet());
  });

  test('a single known vector pins the frozen pipeline end to end', () async {
    // Bidi marks, mixed whitespace and Arabic-Indic digits in; the same
    // fingerprint as the plain inbox text out.
    final a = await _hasher.fingerprint(
      _normalizer.normalize('\u{200F}تم  خصم\n١٥٠٫٠٠ جنيه\u{2069}'),
    );
    final b = await _hasher.fingerprint(
      _normalizer.normalize('تم خصم 150.00 جنيه'),
    );
    expect(a, b);
    // No folding and no lower-casing: these stay distinct.
    expect(_normalizer.normalize('Purchase'), 'Purchase');
    expect(_normalizer.normalize('شـراء'), 'شـراء');
    expect(_normalizer.normalize('إيداع'), 'إيداع');
  });

  test('bumping a profile version never changes a fingerprint', () async {
    final before = await _computeAll();
    final bumped = SmsParserRegistry(
      generic: BankProfile(
        id: genericProfileId,
        version: genericProfile.version + 1,
        isGeneric: true,
      ),
    );
    final parser = RuleBasedSmsParser(
      clock: FixedClock(DateTime(2026, 3, 10, 12)),
      registry: bumped,
    );
    var parsed = 0;
    for (final f in loadSmsFixtures()) {
      final result = parser.parse(
        SmsParseInput(rawText: f.text, source: SmsSource.paste),
      );
      if (result is ParsedTransaction) {
        parsed++;
        expect(result.ruleVersion, 'generic@${genericProfile.version + 1}');
      }
    }
    expect(parsed, greaterThan(0));
    expect(await _computeAll(), before);
  });

  test('import guard: the frozen file depends only on NumeralParser and the '
      'import-free port it implements', () {
    expect(_imports(_frozenFile), [
      '../../../../core/money/numeral_parser.dart',
      '../../domain/services/fingerprint_normalizer.dart',
    ]);
    expect(_imports(_portFile), isEmpty);
    final numeralImports = _imports('lib/core/money/numeral_parser.dart');
    expect(numeralImports, isEmpty);
  });
}
