import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T066 (constitution, ui-contract §5/§7) — no user-visible string literal
/// in the feature's presentation layer: every text, semantics label,
/// tooltip, label and hint comes from the ARB files.
///
/// Combines the single-file check of `data_export_page_test.dart` with the
/// directory walk of `architecture_boundary_test.dart`.
void main() {
  const root = 'lib/features/sms_import/presentation';

  final literal = RegExp(
    r'''(\bText\(\s*|\b(semanticsLabel|tooltip|labelText|hintText|helperText|errorText|label|title|message)\s*:\s*)['"]''',
  );

  List<File> dartFilesUnder(String path) {
    final dir = Directory(path);
    expect(dir.existsSync(), isTrue, reason: '$path must exist');
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  test('the guard catches a literal (positive control)', () {
    expect(literal.hasMatch("Text('Add')"), isTrue);
    expect(literal.hasMatch('tooltip: "Scan"'), isTrue);
    expect(literal.hasMatch('Text(l10n.smsImportErrorNotRecognized)'), isFalse);
  });

  test('no hardcoded user-facing strings in sms_import/presentation', () {
    final violations = <String>[];
    for (final file in dartFilesUnder(root)) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (literal.hasMatch(line)) violations.add('${file.path}:${i + 1}');
      }
    }
    expect(violations, isEmpty);
  });
}
