import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T083 (spec SC-007/SC-008) — every assistant string exists, non-empty,
/// in both English and Arabic, with the same placeholders, so neither
/// language ever falls back to the other or shows a raw key.
void main() {
  Map<String, Object?> arb(String locale) =>
      jsonDecode(File('lib/core/l10n/app_$locale.arb').readAsStringSync())
          as Map<String, Object?>;

  final en = arb('en');
  final ar = arb('ar');
  final aiKeys = en.keys.where((k) => k.startsWith('ai')).toList();

  Set<String> placeholders(String text) =>
      RegExp(r'\{(\w+)').allMatches(text).map((m) => m.group(1)!).toSet();

  test('the assistant has localized strings', () {
    expect(aiKeys, isNotEmpty);
  });

  test('every assistant key exists, non-empty, in Arabic too', () {
    for (final key in aiKeys) {
      final arText = ar[key];
      expect(arText, isA<String>(), reason: key);
      expect((arText! as String).trim(), isNotEmpty, reason: key);
      expect((en[key]! as String).trim(), isNotEmpty, reason: key);
    }
    final arOnly = ar.keys.where(
      (k) => k.startsWith('ai') && !en.containsKey(k),
    );
    expect(arOnly, isEmpty);
  });

  test('placeholders match between English and Arabic', () {
    for (final key in aiKeys) {
      expect(
        placeholders(ar[key]! as String),
        placeholders(en[key]! as String),
        reason: key,
      );
    }
  });
}
