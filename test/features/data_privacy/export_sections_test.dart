import 'dart:convert';
import 'dart:io';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/data_privacy/domain/services/export_directory_provider.dart';
import 'package:daftary/features/data_privacy/domain/usecases/export_user_data.dart';
import 'package:daftary/features/settings/data/datasources/settings_dao.dart';
import 'package:daftary/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../helpers/catalogue_fixtures.dart';

class _FixedDirectory implements ExportDirectoryProvider {
  _FixedDirectory(this.directory);

  final Directory directory;

  @override
  Future<Directory> resolve() async => directory;
}

/// 022 T070 (D1, RF-03): the export of the T003 data carries ten new
/// sections after the five existing ones, in a fixed order, and the existing
/// sections are byte-identical to what `main` (v1.0.1) wrote.
///
/// `fixtures/export_v1_0_1_sections.csv` was captured from `main` (before
/// any export change) by exporting the committed v11 world under
/// `TZ=UTC`. Timestamps are local wall-clock ISO strings, so in any other
/// zone they are masked before the comparison; everything else, including
/// the byte order mark and line endings, must match exactly.
void main() {
  late Directory dir;
  late CatalogueEnv env;
  late ExportUserData exportUserData;

  final fixture = File(
    'test/features/data_privacy/fixtures/export_v1_0_1_sections.csv',
  );
  final world = File('test/core/database/fixtures/financial_world_v11.sql');

  const newMarkers = [
    'OCCASIONS',
    'OCCASION_CONTRIBUTIONS',
    'BUDGETS',
    'BUDGET_ALLOCATIONS',
    'SAVINGS_GOALS',
    'SAVINGS_CONTRIBUTIONS',
    'EXCHANGE_RATES',
    'TRANSACTION_CHANGES',
    'SAVINGS_CONTRIBUTION_CHANGES',
    'FINANCE_ENTRY_CHANGES',
  ];

  setUp(() async {
    final raw = sqlite3.openInMemory();
    addTearDown(raw.close);
    raw.execute(world.readAsStringSync());
    env = await CatalogueEnv.open(
      database: AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      ),
    );
    dir = Directory.systemTemp.createTempSync('export_sections_test');
    exportUserData = ExportUserData(
      env.people,
      env.transactions,
      env.finance,
      env.categories,
      SettingsRepositoryImpl(SettingsDao(env.db)),
      _FixedDirectory(dir),
      env.occasions,
      env.budgets,
      env.savings,
      env.currency,
    );
  });

  tearDown(() async {
    await env.close();
    dir.deleteSync(recursive: true);
  });

  Future<String> export() async {
    final result = (await exportUserData()).getOrElse(
      (f) => throw StateError('$f'),
    );
    return utf8.decode(File(result.filePath).readAsBytesSync());
  }

  String mask(String text) => DateTime(2026).timeZoneOffset == Duration.zero
      ? text
      : text.replaceAll(
          RegExp(r'\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d+'),
          '<instant>',
        );

  /// The rows of the section opened by `## [marker]`, header excluded.
  List<String> rowsOf(String content, String marker) {
    final lines = content.split('\r\n');
    final start = lines.indexOf('## $marker');
    expect(start, isNonNegative, reason: marker);
    final rows = <String>[];
    for (var i = start + 2; i < lines.length; i++) {
      if (lines[i].isEmpty || lines[i].startsWith('## ')) break;
      rows.add(lines[i]);
    }
    return rows;
  }

  test('the existing sections are byte-identical to the v1.0.1 export, and '
      'the new ones follow', () async {
    final content = await export();
    final before = fixture.readAsStringSync();

    expect(mask(content.substring(0, before.length)), mask(before));
    // The new sections start right after the old content, with the same
    // blank-line separator the existing sections use.
    expect(content.substring(before.length), startsWith('\r\n## OCCASIONS'));
  });

  test('the ten new sections appear in the specified order, after the '
      'existing five', () async {
    final content = await export();

    final positions = [
      for (final marker in [
        'PEOPLE',
        'TRANSACTIONS',
        'FINANCE_ENTRIES',
        'CATEGORIES',
        'SETTINGS',
        ...newMarkers,
      ])
        content.indexOf('\r\n## $marker\r\n').clamp(-1, content.length),
    ];
    // PEOPLE is at the very start (after the byte order mark), so it has no
    // preceding line break.
    positions[0] = content.indexOf('## PEOPLE\r\n');
    expect(positions, everyElement(isNonNegative));
    expect(positions, orderedEquals([...positions]..sort()));
  });

  test('the T003 data fills the new sections', () async {
    final content = await export();
    final result = (await exportUserData()).getOrElse(
      (f) => throw StateError('$f'),
    );

    // Counts straight from the committed world.
    Future<int> sql(String q) async =>
        (await env.db.customSelect(q).getSingle()).read<int>('c');

    expect(
      rowsOf(content, 'OCCASIONS'),
      hasLength(
        await sql('SELECT COUNT(*) c FROM occasions WHERE deleted_at IS NULL'),
      ),
    );
    expect(
      rowsOf(content, 'OCCASION_CONTRIBUTIONS'),
      hasLength(
        await sql(
          'SELECT COUNT(*) c FROM money_transactions '
          'WHERE occasion_id IS NOT NULL AND deleted_at IS NULL',
        ),
      ),
    );
    expect(rowsOf(content, 'BUDGETS'), hasLength(1));
    expect(rowsOf(content, 'BUDGET_ALLOCATIONS'), hasLength(4));
    expect(rowsOf(content, 'SAVINGS_GOALS'), hasLength(2));
    expect(rowsOf(content, 'SAVINGS_CONTRIBUTIONS'), hasLength(4));
    expect(rowsOf(content, 'EXCHANGE_RATES'), hasLength(1));
    expect(
      rowsOf(content, 'TRANSACTION_CHANGES'),
      hasLength(await sql('SELECT COUNT(*) c FROM transaction_audit_entries')),
    );
    expect(rowsOf(content, 'SAVINGS_CONTRIBUTION_CHANGES'), isEmpty);
    expect(rowsOf(content, 'FINANCE_ENTRY_CHANGES'), isEmpty);

    expect(result.sectionCounts['Budgets'], 1);
    expect(result.sectionCounts['FinanceEntryChanges'], 0);
    // Money is written as exact minor units plus a major-unit column.
    expect(content, contains('amount_minor_units'));
  });

  test(
    'history written after the upgrade shows in the change sections',
    () async {
      final entries = (await env.finance.getHistory(
        limit: 1,
      )).getOrElse((f) => throw StateError('$f'));
      final entry = entries.single;
      unwrapOrThrow(
        await env.finance.editEntry(
          entryId: entry.id,
          categoryId: entry.categoryId,
          amount: const Money.egp(777700),
          date: entry.date,
        ),
      );
      unwrapOrThrow(await env.finance.deleteEntry(entry.id));

      final content = await export();
      final rows = rowsOf(content, 'FINANCE_ENTRY_CHANGES');
      expect(rows, hasLength(2));
      expect(rows[0], contains(',edited,'));
      expect(rows[0], contains(entry.id));
      expect(rows[1], contains(',deleted,'));
    },
  );

  test('previous values are exported with sorted keys', () async {
    final entry = (await env.finance.getHistory(
      limit: 1,
    )).getOrElse((f) => throw StateError('$f')).single;
    unwrapOrThrow(
      await env.finance.editEntry(
        entryId: entry.id,
        categoryId: entry.categoryId,
        amount: const Money.egp(123400),
        date: entry.date,
      ),
    );

    final row = rowsOf(await export(), 'FINANCE_ENTRY_CHANGES').last;
    final keys = [
      'amountMinorUnits',
      'categoryId',
      'currencyCode',
      'date',
      'note',
      'type',
    ];
    final at = [for (final k in keys) row.indexOf(k)];
    expect(at, everyElement(isNonNegative));
    expect(at, orderedEquals([...at]..sort()));
  });
}
