import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// 023 parser-contract §10 invariant 7: the parser makes no network, file or
// platform call, and nothing in the parsing and hashing code logs.
void main() {
  final files = [
    ...Directory('lib/features/sms_import/data/parsing').listSync(),
    File('lib/features/sms_import/data/crypto/hmac_fingerprint_hasher.dart'),
  ].whereType<File>().where((f) => f.path.endsWith('.dart')).toList();

  test('pure Dart imports only', () {
    final impure = RegExp(
      r'''^\s*import\s+['"](package:flutter|package:drift|dart:io|dart:ui|package:http|dart:developer|[^'"]*services\.dart['"]\s*;\s*$)''',
      multiLine: true,
    );
    expect(files, isNotEmpty);
    for (final file in files) {
      final source = file.readAsStringSync();
      final hits = RegExp(
        r'''^\s*import\s+['"]([^'"]+)['"]''',
        multiLine: true,
      ).allMatches(source).map((m) => m[1]!);
      for (final uri in hits) {
        expect(
          uri.startsWith('package:flutter') ||
              uri.startsWith('package:drift') ||
              uri == 'dart:io' ||
              uri == 'dart:ui' ||
              uri == 'dart:developer' ||
              uri.startsWith('package:http'),
          isFalse,
          reason: '${file.path} imports $uri',
        );
      }
      expect(impure.hasMatch(source), isFalse, reason: file.path);
    }
  });

  test('no logging', () {
    final logging = RegExp(r'\b(print|debugPrint|log)\s*\(|developer\.log');
    for (final file in files) {
      expect(
        logging.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: file.path,
      );
    }
  });
}
