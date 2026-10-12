import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T075 — invariant 2 (domain-interfaces §7): `addSmsSourcedTransaction`
/// and `addSmsSourcedEntry` have exactly one non-test caller,
/// `SmsImportRepositoryImpl.confirm`, and `confirm` has exactly one,
/// `AddImportedTransaction` (FR-052, the single review gate).
void main() {
  const gate =
      'lib/features/sms_import/data/repositories/sms_import_repository_impl.dart';
  const useCase =
      'lib/features/sms_import/domain/usecases/add_imported_transaction.dart';

  /// Files that declare or implement a method, which are not callers.
  const declarations = {
    'lib/features/transactions/domain/repositories/transactions_repository.dart',
    'lib/features/transactions/data/repositories/transactions_repository_impl.dart',
    'lib/features/finance/domain/repositories/finance_repository.dart',
    'lib/features/finance/data/repositories/finance_repository_impl.dart',
  };

  List<File> dartFiles(String root) {
    final dir = Directory(root);
    expect(dir.existsSync(), isTrue, reason: '$root must exist');
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart'))
        .where((f) => !f.path.endsWith('.config.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  String withoutComments(String source) => source
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .split('\n')
      .map((line) {
        final index = line.indexOf('//');
        return index < 0 ? line : line.substring(0, index);
      })
      .join('\n');

  /// Files under lib/ that CALL [method] (not counting declarations).
  Set<String> callersOf(String method, {Set<String> exclude = const {}}) {
    final call = RegExp('[.]$method\\s*\\(');
    return {
      for (final file in dartFiles('lib'))
        if (!exclude.contains(file.path) &&
            call.hasMatch(withoutComments(file.readAsStringSync())))
          file.path,
    };
  }

  test('addSmsSourcedTransaction: one caller, the SMS confirm gate', () {
    expect(callersOf('addSmsSourcedTransaction', exclude: declarations), {
      gate,
    });
  });

  test('addSmsSourcedEntry: one caller, the SMS confirm gate', () {
    expect(callersOf('addSmsSourcedEntry', exclude: declarations), {gate});
  });

  test('each is called exactly once inside the gate', () {
    final source = withoutComments(File(gate).readAsStringSync());
    for (final method in ['addSmsSourcedTransaction', 'addSmsSourcedEntry']) {
      expect(
        RegExp('[.]$method\\s*\\(').allMatches(source),
        hasLength(1),
        reason: method,
      );
    }
  });

  test(
    'SmsImportRepository.confirm is called only by AddImportedTransaction',
    () {
      // `.confirm(` on the SMS repository; other features' confirm methods
      // have different names (confirmScanBatch), so a plain match is exact.
      final callers = callersOf('confirm');
      expect(callers.where((p) => p.contains('/sms_import/')), {useCase});
    },
  );

  test('positive control: the matcher sees a call and skips comments', () {
    final call = RegExp(r'[.]addSmsSourcedEntry\s*\(');
    expect(
      call.hasMatch(withoutComments('repo.addSmsSourcedEntry(x);')),
      isTrue,
    );
    expect(
      call.hasMatch(withoutComments('// repo.addSmsSourcedEntry(x);')),
      isFalse,
    );
  });
}
