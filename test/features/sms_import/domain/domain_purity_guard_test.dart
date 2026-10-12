import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 023 T033: the SMS import domain is pure Dart, and the SMS import and AI
/// assistant features never import each other (constitution, FR-081:
/// message text never reaches an AI service).
///
/// Checked on the source text of every import/export/part directive, so a
/// violation fails here before it can ship.
const _domainRoot = 'lib/features/sms_import/domain';
const _smsRoot = 'lib/features/sms_import';
const _aiRoot = 'lib/features/ai_assistant';

final List<RegExp> _impureImports = [
  RegExp(r'^package:flutter/'),
  RegExp(r'^package:flutter_'),
  RegExp(r'^package:drift'),
  RegExp(r'^dart:io$'),
  RegExp(r'^dart:ui$'),
  RegExp(r'services\.dart$'),
];

final RegExp _directive = RegExp(
  r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

List<String> _importsOf(File file) => _directive
    .allMatches(file.readAsStringSync())
    .map((m) => m.group(1)!)
    .toList();

List<File> _dartFilesUnder(String path) {
  final dir = Directory(path);
  expect(dir.existsSync(), isTrue, reason: '$path must exist');
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// Whether [uri], imported from [file], points into the feature at
/// [featureRoot] (`lib/features/<name>`), for package and relative URIs.
bool _pointsInto(File file, String uri, String featureRoot) {
  final feature = featureRoot.substring('lib/'.length);
  if (uri.startsWith('package:daftary/')) {
    return uri.startsWith('package:daftary/$feature/');
  }
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return false;
  final resolved = file.absolute.parent.uri.resolve(uri).path;
  return resolved.contains('/$featureRoot/');
}

List<String> _crossImports(String fromRoot, String toRoot) {
  final dir = Directory(fromRoot);
  if (!dir.existsSync()) return const [];
  return [
    for (final file in _dartFilesUnder(fromRoot))
      for (final uri in _importsOf(file))
        if (_pointsInto(file, uri, toRoot)) '${file.path}: $uri',
  ];
}

void main() {
  test('the SMS import domain imports no Flutter, Drift, dart:io or '
      'platform services', () {
    final files = _dartFilesUnder(_domainRoot);
    expect(files, isNotEmpty);
    final violations = [
      for (final file in files)
        for (final uri in _importsOf(file))
          if (_impureImports.any((p) => p.hasMatch(uri))) '${file.path}: $uri',
    ];
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('sms_import does not import ai_assistant', () {
    final violations = _crossImports(_smsRoot, _aiRoot);
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('ai_assistant does not import sms_import', () {
    final violations = _crossImports(_aiRoot, _smsRoot);
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('the cross-import check catches both URI styles', () {
    // Positive control: a file inside the AI feature resolves a relative
    // import that walks into sms_import, and a package import does too.
    final aiFile = File('$_aiRoot/domain/example.dart');
    expect(
      _pointsInto(
        aiFile,
        '../../sms_import/domain/entities/sms_import_enums.dart',
        _smsRoot,
      ),
      isTrue,
    );
    expect(
      _pointsInto(
        aiFile,
        'package:daftary/features/sms_import/domain/x.dart',
        _smsRoot,
      ),
      isTrue,
    );
    expect(_pointsInto(aiFile, '../entities/x.dart', _smsRoot), isFalse);
  });
}
