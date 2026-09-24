import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T049 — grep-style structural guarantees for research.md Decision 3
/// (FR-004/FR-005/FR-013) and FR-017.
///
/// The calculators, the education content repository/data source, and the
/// calculator cubits must never be able to reach the user's financial data
/// or any risk-profiling type, and nothing in the feature may import a
/// network package. Checked on the source text of every import/export
/// directive, so a violation fails here before it can ship.
const _featureRoot = 'lib/features/financial_education';

/// Import targets that would give a file access to the user's own financial
/// data, persistence, or risk profiling.
final List<RegExp> _forbiddenDataAccess = [
  RegExp('TransactionRepository', caseSensitive: false),
  RegExp('transactions_repository', caseSensitive: false),
  RegExp('FinanceRepository', caseSensitive: false),
  RegExp('finance_repository', caseSensitive: false),
  RegExp('SavingsRepository', caseSensitive: false),
  RegExp('savings_repository', caseSensitive: false),
  RegExp('features/transactions'),
  RegExp('features/finance/'),
  RegExp('features/budgets'),
  RegExp('drift', caseSensitive: false),
  RegExp('database', caseSensitive: false),
  RegExp('risk[_ ]?profil', caseSensitive: false),
  RegExp('risk[_ ]?tolerance', caseSensitive: false),
];

/// Network packages the feature must never import (FR-017: fully offline).
final List<RegExp> _forbiddenNetwork = [
  RegExp('^package:http/'),
  RegExp('^package:dio/'),
  RegExp('^package:dio_'),
  RegExp('^package:chopper/'),
  RegExp('^package:retrofit/'),
  RegExp('^package:graphql'),
  RegExp('^package:grpc/'),
  RegExp('^package:web_socket_channel/'),
  RegExp('^package:cached_network_image/'),
  RegExp('^package:connectivity'),
  RegExp('^dart:io\$'),
  RegExp('^dart:html\$'),
];

final RegExp _directive = RegExp(
  r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// The URIs of every import/export/part directive in [file].
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

File _file(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path must exist');
  return file;
}

/// Every `file: uri` pair where uri matches one of [patterns].
List<String> _violations(Iterable<File> files, List<RegExp> patterns) => [
  for (final file in files)
    for (final uri in _importsOf(file))
      if (patterns.any((p) => p.hasMatch(uri))) '${file.path}: $uri',
];

void main() {
  late List<File> services;
  late List<File> contentFiles;
  late List<File> calculatorCubits;

  setUpAll(() {
    services = _dartFilesUnder('$_featureRoot/domain/services');
    contentFiles = [
      _file(
        '$_featureRoot/domain/repositories/education_content_repository.dart',
      ),
      _file(
        '$_featureRoot/data/repositories/education_content_repository_impl.dart',
      ),
      _file(
        '$_featureRoot/data/datasources/bundled_education_content_data_source.dart',
      ),
    ];
    calculatorCubits = _dartFilesUnder(
      '$_featureRoot/presentation/cubit',
    ).where((f) => f.path.contains('calculator')).toList();
  });

  test('the guarded file sets are non-empty', () {
    expect(services, hasLength(3));
    expect(calculatorCubits.length, greaterThanOrEqualTo(3));
  });

  test('calculator services never import user financial data, persistence, '
      'or risk-profiling types', () {
    expect(_violations(services, _forbiddenDataAccess), isEmpty);
  });

  test('the education content repository and data source never import user '
      'financial data, persistence, or risk-profiling types', () {
    expect(_violations(contentFiles, _forbiddenDataAccess), isEmpty);
  });

  test('calculator cubits never import user financial data, persistence, '
      'or risk-profiling types', () {
    expect(_violations(calculatorCubits, _forbiddenDataAccess), isEmpty);
  });

  test('calculator services import only dart:, injectable, and the '
      "feature's own entities", () {
    final disallowed = [
      for (final file in services)
        for (final uri in _importsOf(file))
          if (!(uri.startsWith('dart:') ||
              uri.startsWith('package:injectable/') ||
              RegExp(r'^\.\./entities/[a-z0-9_]+\.dart$').hasMatch(uri) ||
              RegExp(
                r'^package:daftary/features/financial_education/domain/entities/',
              ).hasMatch(uri)))
            '${file.path}: $uri',
    ];
    expect(disallowed, isEmpty);
  });

  test('nothing in the feature imports a network package (FR-017)', () {
    final files = _dartFilesUnder(_featureRoot);
    expect(files, isNotEmpty);
    expect(_violations(files, _forbiddenNetwork), isEmpty);
  });

  test('the checks actually detect a forbidden import', () {
    final probe =
        File(
          '${Directory.systemTemp.createTempSync('boundary_probe').path}'
          '/probe.dart',
        )..writeAsStringSync(
          "import 'package:dio/dio.dart';\n"
          "import '../../../finance/domain/repositories/finance_repository.dart';\n",
        );
    addTearDown(() => probe.parent.deleteSync(recursive: true));
    expect(_violations([probe], _forbiddenNetwork), hasLength(1));
    expect(_violations([probe], _forbiddenDataAccess), hasLength(1));
  });
}
