import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T066 (ui-contract §5) — every `smsImport*` string exists, non-empty, in
/// English and Arabic, carries an `@key` description, and uses the same
/// placeholders. Every plural has English `=0`/`=1`/`other` and Arabic
/// exactly `=0`/`=1`/`=2`/`few`/`many`/`other`; every select has the same
/// categories in both languages.
///
/// Cloned from the assistant's parity test, with one fix
/// (discovery-t007-t009 #2): placeholders come from the `@key` metadata,
/// because a `\{(\w+)` scan also captures the first word of every ICU
/// branch. Only `smsImport*` keys are checked; `syncStatusPending` is left
/// alone.
void main() {
  Map<String, Object?> arb(String locale) =>
      jsonDecode(File('lib/core/l10n/app_$locale.arb').readAsStringSync())
          as Map<String, Object?>;

  final en = arb('en');
  final ar = arb('ar');
  final keys = en.keys.where((k) => k.startsWith('smsImport')).toList();

  Map<String, Object?> meta(String key) =>
      (en['@$key'] as Map<String, Object?>?) ?? const {};

  Set<String> declared(String key) =>
      ((meta(key)['placeholders'] as Map<String, Object?>?) ?? const {}).keys
          .toSet();

  test('the category parser works (positive control)', () {
    final forms = _icuForms(ar['savingsOverviewGoalCount']! as String);
    expect(forms['count']!.$1, 'plural');
    expect(forms['count']!.$2, {'=0', '=1', '=2', 'few', 'many', 'other'});
    final partial = _icuForms(ar['syncStatusPending']! as String);
    expect(partial['count']!.$2, isNot(contains('many')));
  });

  test('the feature has localized strings', () {
    expect(keys, isNotEmpty);
  });

  test(
    'every key exists, non-empty, in both languages; no Arabic-only key',
    () {
      for (final key in keys) {
        expect((en[key]! as String).trim(), isNotEmpty, reason: key);
        final arText = ar[key];
        expect(arText, isA<String>(), reason: key);
        expect((arText! as String).trim(), isNotEmpty, reason: key);
        expect(arText, isNot(en[key]), reason: '$key is not translated');
      }
      final arOnly = ar.keys.where(
        (k) => k.startsWith('smsImport') && !en.containsKey(k),
      );
      expect(arOnly, isEmpty);
    },
  );

  test('every key has an @key description', () {
    for (final key in keys) {
      final description = meta(key)['description'];
      expect(description, isA<String>(), reason: key);
      expect((description! as String).trim(), isNotEmpty, reason: key);
    }
  });

  test('declared placeholders appear in both languages, nothing else', () {
    final reference = RegExp(r'\{(\w+)(?=[,}])');
    for (final key in keys) {
      final names = declared(key);
      for (final text in [en[key]! as String, ar[key]! as String]) {
        for (final name in names) {
          expect(text, contains('{$name'), reason: '$key: $name');
        }
        final used = _topLevelArguments(text, reference);
        expect(used.difference(names), isEmpty, reason: key);
      }
    }
  });

  test('plural and select category sets', () {
    for (final key in keys) {
      final enForms = _icuForms(en[key]! as String);
      final arForms = _icuForms(ar[key]! as String);
      expect(arForms.keys.toSet(), enForms.keys.toSet(), reason: key);
      for (final entry in enForms.entries) {
        final (kind, enCategories) = entry.value;
        final (_, arCategories) = arForms[entry.key]!;
        if (kind == 'plural') {
          expect(
            enCategories,
            containsAll(<String>['=0', '=1', 'other']),
            reason: '$key (en)',
          );
          expect(arCategories, {
            '=0',
            '=1',
            '=2',
            'few',
            'many',
            'other',
          }, reason: '$key (ar)');
        } else {
          expect(arCategories, enCategories, reason: '$key (select)');
          expect(enCategories, contains('other'), reason: key);
        }
      }
    }
  });
}

/// Placeholder references outside ICU branch bodies at depth 0 and the
/// argument of each top-level ICU expression.
Set<String> _topLevelArguments(String text, RegExp reference) {
  final names = <String>{};
  for (final match in reference.allMatches(text)) {
    names.add(match.group(1)!);
  }
  // Branch words followed directly by `}` (e.g. `other{Goals}`) are not
  // arguments: keep only names that are ICU arguments or `{name}` refs
  // whose name is not a plain word inside a branch.
  return names.where((n) => !_isBranchWord(text, n)).toSet();
}

bool _isBranchWord(String text, String name) {
  // A real reference is `{name}` or `{name,`; a branch body is
  // `category{words...}`, whose `{` follows a category token.
  final pattern = RegExp(
    r'(=\d+|zero|one|two|few|many|other|\w+)\{'
    '$name'
    r'[,}]',
  );
  final asRef = RegExp(
    r'(^|[^\w=])\{'
    '$name'
    r'[,}]',
  );
  return pattern.hasMatch(text) && !asRef.hasMatch(text);
}

/// `{argument: (kind, categories)}` of each top-level ICU plural/select.
Map<String, (String, Set<String>)> _icuForms(String text) {
  final forms = <String, (String, Set<String>)>{};
  final head = RegExp(r'\{(\w+),\s*(plural|select),');
  for (final match in head.allMatches(text)) {
    final categories = <String>{};
    var i = match.end;
    var depth = 1;
    final token = StringBuffer();
    while (i < text.length && depth > 0) {
      final c = text[i];
      if (c == '{') {
        if (depth == 1) categories.add(token.toString().trim());
        token.clear();
        depth++;
      } else if (c == '}') {
        depth--;
        token.clear();
      } else if (depth == 1) {
        token.write(c);
      }
      i++;
    }
    forms[match.group(1)!] = (match.group(2)!, categories);
  }
  return forms;
}
