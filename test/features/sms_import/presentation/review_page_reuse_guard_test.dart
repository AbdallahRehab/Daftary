import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// FR-044 / SC-012 (T082 acceptance): the bank-message screens never open
/// or import the manual transaction forms or their Cubits. They may reuse
/// shared widgets of other features, but no other feature's page or Cubit.
void main() {
  final importLine = RegExp(r'''^import\s+['"]([^'"]+)['"]''', multiLine: true);

  List<String> importsOf(File file) => [
    for (final m in importLine.allMatches(file.readAsStringSync())) m.group(1)!,
  ];

  bool forbidden(String uri) {
    if (uri.contains('sms_import/')) return false;
    if (!uri.startsWith('.') && !uri.startsWith('package:daftary/')) {
      return false;
    }
    return uri.contains('/presentation/pages/') ||
        uri.contains('/presentation/cubit/') ||
        uri.contains('_form_page') ||
        uri.contains('_form_cubit');
  }

  test('no manual form page or other feature Cubit is imported', () {
    final dir = Directory('lib/features/sms_import/presentation');
    expect(dir.existsSync(), isTrue);
    final offenders = <String>[];
    for (final file
        in dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      for (final uri in importsOf(file)) {
        if (forbidden(uri)) {
          offenders.add('${file.path}: $uri');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('positive control', () {
    expect(
      forbidden(
        '../../../transactions/presentation/pages/transaction_form_page.dart',
      ),
      isTrue,
    );
    expect(
      forbidden(
        '../../../finance/presentation/cubit/finance_entry_form_cubit.dart',
      ),
      isTrue,
    );
    expect(
      forbidden(
        '../../../transactions/presentation/widgets/person_picker_field.dart',
      ),
      isFalse,
    );
  });
}
