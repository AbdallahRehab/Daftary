import 'dart:io';

import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/features/data_privacy/domain/services/export_directory_provider.dart';
import 'package:daftary/features/data_privacy/domain/usecases/export_user_data.dart';
import 'package:daftary/features/settings/data/datasources/settings_dao.dart';
import 'package:daftary/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:daftary/features/sms_import/domain/entities/review_draft.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../helpers/catalogue_fixtures.dart';
import '../helpers/pipeline_harness.dart';

class _FixedDirectory implements ExportDirectoryProvider {
  _FixedDirectory(this.directory);

  final Directory directory;

  @override
  Future<Directory> resolve() async => directory;
}

const String _exportFile =
    'lib/features/data_privacy/domain/usecases/export_user_data.dart';

/// Every `lib/` file reachable from [entry] through relative or
/// `package:daftary/` imports and exports (parts included).
Set<String> _libraryClosure(String entry) {
  final seen = <String>{};
  final queue = [p.normalize(entry)];
  final directive = RegExp(
    r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );
  while (queue.isNotEmpty) {
    final path = queue.removeLast();
    if (!seen.add(path)) continue;
    final file = File(path);
    if (!file.existsSync()) continue;
    for (final match in directive.allMatches(file.readAsStringSync())) {
      final uri = match.group(1)!;
      String? target;
      if (uri.startsWith('package:daftary/')) {
        target = p.join('lib', uri.substring('package:daftary/'.length));
      } else if (!uri.contains(':')) {
        target = p.join(p.dirname(path), uri);
      }
      if (target != null) queue.add(p.normalize(target));
    }
  }
  return seen;
}

/// T155 — invariant 7 (domain-interfaces §7): `ExportUserData` has no
/// dependency on any bank-message interface, and its CSV carries no
/// provenance header. `export_user_data.dart` itself is not modified by
/// this feature; an SMS-sourced record exports exactly like a manual one.
/// Every value is synthetic.
void main() {
  group('static', () {
    test('the export source names nothing from the bank-message feature '
        'and no provenance', () {
      final source = File(_exportFile).readAsStringSync();
      expect(source, isNot(contains('sms_import')));
      expect(source.toLowerCase(), isNot(contains('sms')));
      expect(source, isNot(contains('provenance')));
      expect(source, isNot(contains('import_source')));
      expect(source, isNot(contains('importSource')));
    });

    test(
      'no file reachable from the export imports lib/features/sms_import',
      () {
        final closure = _libraryClosure(_exportFile);
        // Positive control: the closure really walks the graph.
        expect(
          closure,
          contains(
            p.normalize(
              'lib/features/finance/domain/entities/'
              'finance_entry.dart',
            ),
          ),
        );
        expect(
          closure.where((f) => f.contains(p.join('features', 'sms_import'))),
          isEmpty,
        );
      },
    );

    test('positive control: the closure would see an sms_import import', () {
      final dir = Directory.systemTemp.createTempSync('export_closure');
      addTearDown(() => dir.deleteSync(recursive: true));
      final probe = File(p.join(dir.path, 'probe.dart'))
        ..writeAsStringSync(
          "import 'package:daftary/features/sms_import/domain/"
          "repositories/sms_import_repository.dart';\n",
        );
      expect(
        _libraryClosure(probe.path),
        contains(
          p.normalize(
            'lib/features/sms_import/domain/repositories/'
            'sms_import_repository.dart',
          ),
        ),
      );
    });
  });

  group('behaviour (real export over a database holding SMS-sourced '
      'records)', () {
    late PipelineHarness h;
    late Directory dir;
    late ExportUserData export;

    setUp(() async {
      h = PipelineHarness();
      await h.open();
      final env = await CatalogueEnv.open(database: h.database);
      dir = Directory.systemTemp.createTempSync('sms_export_isolation');
      export = ExportUserData(
        env.people,
        env.transactions,
        env.finance,
        env.categories,
        SettingsRepositoryImpl(SettingsDao(h.database)),
        _FixedDirectory(dir),
        env.occasions,
        env.budgets,
        env.savings,
        env.currency,
      );
      await h.database
          .into(h.database.people)
          .insert(
            db.PeopleCompanion.insert(
              id: 'person-1',
              name: 'Ahmed Example',
              normalizedName: 'ahmed example',
              createdAt: 1,
              updatedAt: 1,
            ),
          );
    });

    tearDown(() async {
      await h.close();
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    Future<String> csv() async {
      final result = (await export()).getOrElse(
        (f) => fail('export failed: $f'),
      );
      return File(result.filePath).readAsStringSync();
    }

    Future<void> addFromSms() async {
      final purchase = await h.pasteText(
        'Purchase of EGP 125.50 at Example Cafe on 04/03/2026 10:15 with '
        'card ****0000.',
      );
      final item = await h.item(purchase.newIds.single);
      final added = await h.add(
        pendingId: item.id,
        draft: ReviewDraft(
          type: SuggestedRecordType.expense,
          amountMinorUnits: item.amount!.minorUnits,
          currencyCode: item.amount!.currency.code,
          date: item.occurredOn,
          categoryId: 'seed_groceries',
        ),
        duplicateOverride: true,
      );
      expect(added.isRight(), isTrue);
      final transfer = await h.pasteText(
        'NBE: Transfer of EGP 1,500.00 to Ahmed Example from your account '
        '****4821 on 05/03/2026. Ref 7731902',
      );
      final given = await h.item(transfer.newIds.single);
      final saved = await h.add(
        pendingId: given.id,
        draft: ReviewDraft(
          type: SuggestedRecordType.given,
          amountMinorUnits: given.amount!.minorUnits,
          currencyCode: given.amount!.currency.code,
          date: given.occurredOn,
          personId: 'person-1',
        ),
        duplicateOverride: true,
      );
      expect(saved.isRight(), isTrue);
      expect(await h.savedRecords(), 2);
    }

    List<List<String>> headers(String text) {
      final lines = text.split(RegExp(r'\r?\n'));
      return [
        for (var i = 0; i < lines.length - 1; i++)
          if (lines[i].startsWith('## ')) lines[i + 1].split(','),
      ];
    }

    test('no section header is a provenance column, before or after an SMS '
        'Add, and the header set does not change', () async {
      final before = headers(await csv());
      await addFromSms();
      final after = headers(await csv());

      expect(after, before);
      expect(after, isNotEmpty);
      for (final header in after) {
        for (final column in header) {
          final name = column.toLowerCase();
          expect(name, isNot(contains('provenance')));
          expect(name, isNot(contains('import_source')));
          expect(name, isNot(contains('sms')));
        }
      }
    });

    test('an SMS-sourced record exports like a manual one: no "sms" '
        'anywhere, the transaction source column reads manual', () async {
      await addFromSms();
      final text = await csv();

      expect(text.toLowerCase(), isNot(contains('sms')));
      expect(text, isNot(contains('Example Cafe')));
      final lines = text.split(RegExp(r'\r?\n'));
      final start = lines.indexOf('## TRANSACTIONS');
      final header = lines[start + 1].split(',');
      final row = lines[start + 2].split(',');
      expect(row[header.indexOf('person_id')], 'person-1');
      expect(row[header.indexOf('source')], 'manual');
      expect(row[header.indexOf('note')], isEmpty);
    });
  });
}
