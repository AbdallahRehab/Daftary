import 'dart:io';

import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/provenance/import_provenance.dart';
import 'package:daftary/features/finance/data/models/finance_entry_mapper.dart';
import 'package:daftary/features/transactions/data/models/transaction_mapper.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/v11_fixture.dart';

/// 023 T037: the v12 -> v13 step (data-model §11). It adds the five
/// local-only SMS import tables (empty) and nullable `import_source` on
/// `money_transactions` and `finance_entries` (NULL on every existing row),
/// and changes no existing row. v1.0.1 shipped schema 11, so both 11 -> 13
/// in one open (the committed real v11 file) and 12 -> 13 are covered.
void main() {
  // Several tests open a fresh in-memory database next to the upgraded one.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  final sqlFile = File('test/core/database/fixtures/financial_world_v11.sql');

  const smsTables = [
    'pending_sms_imports',
    'sms_import_tombstones',
    'sms_sender_mutes',
    'sms_merchant_category_mappings',
    'sms_import_settings',
  ];
  const smsIndexes = [
    'idx_sms_pending_fingerprint',
    'idx_sms_pending_status_expiry',
    'idx_sms_pending_ref_hash',
    'idx_sms_pending_amount_pair',
    'idx_sms_tomb_ref_hash',
    'idx_sms_tomb_ref_amount',
    'idx_sms_tomb_saved_record',
    'idx_sms_tomb_purge',
  ];

  int userVersion(Database raw) =>
      raw.select('PRAGMA user_version').single.values.single as int;

  List<String> namesOf(Database raw, String type) => [
    for (final r in raw.select(
      'SELECT name FROM sqlite_master WHERE type = ? ORDER BY name',
      [type],
    ))
      r['name'] as String,
  ];

  List<String> columnsOf(Database raw, String table) => [
    for (final c in raw.select('PRAGMA table_info("$table")'))
      c['name'] as String,
  ];

  /// `PRAGMA table_info` without `cid`, so two files can be compared.
  List<Map<String, Object?>> shapeOf(Database raw, String table) => [
    for (final c in raw.select('PRAGMA table_info("$table")'))
      {
        'name': c['name'],
        'type': c['type'],
        'notnull': c['notnull'],
        'dflt_value': c['dflt_value'],
        'pk': c['pk'],
      },
  ];

  List<Map<String, Object?>> indexShape(Database raw, String index) => [
    for (final c in raw.select('PRAGMA index_xinfo("$index")'))
      {for (final key in c.keys) key: c[key]},
  ];

  /// Every row of every user table except the ones the v12/v13 steps
  /// themselves change, as plain maps without `import_source` (checked
  /// NULL).
  Map<String, List<Map<String, Object?>>> snapshot(Database raw) => {
    for (final table in namesOf(raw, 'table'))
      if (!table.startsWith('sqlite_') &&
          table != 'sync_state' &&
          !smsTables.contains(table))
        table: [
          for (final r in raw.select('SELECT * FROM "$table" ORDER BY rowid'))
            withoutImportSource(r),
        ],
  };

  Database loadV11() {
    final raw = sqlite3.openInMemory();
    raw.execute(sqlFile.readAsStringSync());
    expect(userVersion(raw), 11);
    return raw;
  }

  /// Today's schema minus the v13 additions, at `user_version` 12, with one
  /// person, one transaction and one finance entry.
  Future<Database> createV12() async {
    final raw = sqlite3.openInMemory();
    final bootstrap = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    await bootstrap.customSelect('SELECT 1').get();
    await bootstrap.close();
    dropSmsImportAdditions(raw);
    raw.execute('PRAGMA user_version = 12;');
    raw.execute(
      'INSERT INTO people (id, name, normalized_name, created_at, '
      "updated_at) VALUES ('p1', 'Mona', 'mona', 1, 1)",
    );
    raw.execute(
      'INSERT INTO money_transactions (id, idempotency_key, person_id, '
      'amount_minor_units, currency_code, direction, kind, date, note, '
      "created_at) VALUES ('t1', 'k-t1', 'p1', 9007199254740993, 'USD', "
      "'given', 'initialExchange', 1760000000000, 'lunch', 1760000000001)",
    );
    raw.execute(
      'INSERT INTO finance_entries (id, idempotency_key, category_id, type, '
      'amount_minor_units, currency_code, date, created_at) VALUES '
      "('e1', 'k-e1', 'seed_food', 'expense', 150000, 'EGP', 1760000000000, "
      '1760000000002)',
    );
    return raw;
  }

  Future<AppDatabase> open(Database raw) async {
    final db = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    await db.select(db.financeCategories).get();
    return db;
  }

  void expectV13Objects(Database raw) {
    expect(namesOf(raw, 'table'), containsAll(smsTables));
    expect(namesOf(raw, 'index'), containsAll(smsIndexes));
    for (final table in smsTables) {
      expect(
        raw.select('SELECT COUNT(*) AS n FROM "$table"').single['n'],
        0,
        reason: '$table must start empty (no settings singleton either)',
      );
    }
    expect(columnsOf(raw, 'money_transactions'), contains('import_source'));
    expect(columnsOf(raw, 'finance_entries'), contains('import_source'));
  }

  test('schemaVersion is 13', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 13);
  });

  test(
    'v11 -> v13 in one open (the committed real v11 file): the new '
    'objects exist, import_source is NULL, no existing row changes',
    () async {
      final raw = loadV11();
      addTearDown(raw.close);
      final before = snapshot(raw);
      expect(before['money_transactions'], isNotEmpty);
      expect(before['finance_entries'], isNotEmpty);

      final db = await open(raw);
      addTearDown(db.close);

      expect(userVersion(raw), 13);
      expectV13Objects(raw);
      final after = snapshot(raw)..remove('finance_entry_audits');
      expect(after.keys.toSet(), before.keys.toSet());
      for (final table in before.keys) {
        expect(after[table], before[table], reason: table);
      }
      expect(
        raw
            .select(
              'SELECT COUNT(*) AS n FROM money_transactions '
              'WHERE import_source IS NOT NULL',
            )
            .single['n'],
        0,
      );
      expect(
        raw
            .select(
              'SELECT COUNT(*) AS n FROM finance_entries '
              'WHERE import_source IS NOT NULL',
            )
            .single['n'],
        0,
      );

      // Existing rows read as "not imported" through the local mappers.
      final transactions = await db.select(db.moneyTransactions).get();
      expect(
        transactions.map((r) => r.toDomain().importSource),
        everyElement(isNull),
      );
      final entries = await db.select(db.financeEntries).get();
      expect(
        entries.map((r) => r.toDomain().importSource),
        everyElement(isNull),
      );
    },
  );

  test('v12 -> v13: the new objects exist, no existing row changes, and an '
      'upgraded file has exactly the shape of a fresh install', () async {
    final raw = await createV12();
    addTearDown(raw.close);
    expect(namesOf(raw, 'table'), isNot(anyElement(isIn(smsTables))));
    expect(
      columnsOf(raw, 'money_transactions'),
      isNot(contains('import_source')),
    );
    final before = snapshot(raw);

    final db = await open(raw);
    addTearDown(db.close);

    expect(userVersion(raw), 13);
    expectV13Objects(raw);
    final after = snapshot(raw);
    for (final table in before.keys) {
      expect(after[table], before[table], reason: table);
    }
    final t1 = raw.select("SELECT * FROM money_transactions WHERE id = 't1'");
    expect(t1.single['amount_minor_units'], 9007199254740993);
    expect(t1.single['import_source'], isNull);

    // Same columns, types, defaults and keys as `onCreate` produces, and
    // `import_source` is the last column in both.
    final fresh = sqlite3.openInMemory();
    addTearDown(fresh.close);
    final freshDb = AppDatabase.forTesting(
      NativeDatabase.opened(fresh, closeUnderlyingOnClose: false),
    );
    await freshDb.customSelect('SELECT 1').get();
    await freshDb.close();
    for (final table in [
      ...smsTables,
      'money_transactions',
      'finance_entries',
    ]) {
      expect(shapeOf(raw, table), shapeOf(fresh, table), reason: table);
    }
    for (final index in smsIndexes) {
      expect(indexShape(raw, index), indexShape(fresh, index), reason: index);
    }
    expect(columnsOf(raw, 'money_transactions').last, 'import_source');
    expect(columnsOf(raw, 'finance_entries').last, 'import_source');
    expect(
      raw
          .select(
            "SELECT \"unique\" AS u FROM pragma_index_list('pending_sms_imports') "
            "WHERE name = 'idx_sms_pending_fingerprint'",
          )
          .single['u'],
      1,
    );
    // No index on import_source (data-model §4.6).
    for (final table in ['money_transactions', 'finance_entries']) {
      for (final index in raw.select('PRAGMA index_list("$table")')) {
        final cols = [
          for (final c in raw.select('PRAGMA index_info("${index['name']}")'))
            c['name'],
        ];
        expect(cols, isNot(contains('import_source')), reason: table);
      }
    }
  });

  test('re-opening an upgraded file is a no-op', () async {
    final raw = await createV12();
    addTearDown(raw.close);
    final first = await open(raw);
    await first.close();
    final afterFirst = snapshot(raw);
    final schemaAfterFirst = raw.select(
      'SELECT type, name, sql FROM sqlite_master ORDER BY type, name',
    );

    final second = await open(raw);
    addTearDown(second.close);

    expect(userVersion(raw), 13);
    expect(snapshot(raw), afterFirst);
    expect(
      raw.select(
        'SELECT type, name, sql FROM sqlite_master ORDER BY type, name',
      ),
      schemaAfterFirst,
    );
  });

  test('a v12 file whose v13 step already ran (user_version still 12) '
      'opens and finishes the upgrade', () async {
    final raw = await createV12();
    addTearDown(raw.close);
    final first = await open(raw);
    await first.close();
    raw.execute('PRAGMA user_version = 12;');
    final before = snapshot(raw);

    final db = await open(raw);
    addTearDown(db.close);

    expect(userVersion(raw), 13);
    expectV13Objects(raw);
    expect(snapshot(raw), before);
  });

  test('a failure inside the step leaves the file at v12, and the next open '
      'retries cleanly', () async {
    final raw = await createV12();
    addTearDown(raw.close);
    // A table already squatting on the new name with another shape makes
    // `CREATE INDEX` fail inside the step, after other tables were created.
    raw.execute('CREATE TABLE pending_sms_imports (x INTEGER);');
    final before = snapshot(raw);

    final db = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    await expectLater(db.select(db.financeCategories).get(), throwsA(anything));
    await db.close();

    expect(userVersion(raw), 12);
    expect(
      columnsOf(raw, 'money_transactions'),
      isNot(contains('import_source')),
    );
    expect(columnsOf(raw, 'finance_entries'), isNot(contains('import_source')));
    for (final table in smsTables.skip(1)) {
      expect(namesOf(raw, 'table'), isNot(contains(table)), reason: table);
    }
    expect(snapshot(raw), before);

    raw.execute('DROP TABLE pending_sms_imports;');
    final retry = await open(raw);
    addTearDown(retry.close);
    expect(userVersion(raw), 13);
    expectV13Objects(raw);
  });

  test('a fresh install gets the v13 objects from onCreate, the settings '
      'row is absent, and an id-only insert reads the defaults', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await db.select(db.smsImportSettings).get(), isEmpty);
    await db
        .into(db.smsImportSettings)
        .insert(SmsImportSettingsCompanion.insert(id: 'singleton'));
    final settings = await db.select(db.smsImportSettings).getSingle();
    expect(settings.isEnabled, isFalse);
    expect(settings.onboardingDismissed, isFalse);
    expect(settings.scanWindowDays, 30);
    expect(settings.countCashWithdrawals, isFalse);
    expect(settings.permissionRequested, isFalse);
    expect(settings.scannedCount, 0);
    expect(settings.recognizedCount, 0);
    expect(settings.addedCount, 0);
    expect(settings.ignoredCount, 0);
    expect(settings.rulesSeen, '{}');
    expect(settings.cursorDate, isNull);
    expect(settings.lastCatchUpAt, isNull);
    expect(settings.expiredNoticeSeenAt, isNull);

    await db
        .into(db.pendingSmsImports)
        .insert(
          PendingSmsImportsCompanion.insert(
            id: 'imp1',
            fingerprint: 'fp',
            origin: 'paste',
            bankId: 'generic',
            parserId: 'generic',
            ruleVersion: 'generic@1',
            kind: 'unknown',
            direction: 'unknown',
            confidenceJson: '{}',
            createdAt: 1,
            expiresAt: 2,
          ),
        );
    final pending = await db.select(db.pendingSmsImports).getSingle();
    expect(pending.status, 'pending');
    expect(pending.suggestedAction, 'unset');
    expect(pending.warningsJson, '{}');
    expect(pending.rawBlob, isNull);

    // UNIQUE(fingerprint): a second row with the same fingerprint fails.
    await expectLater(
      db
          .into(db.pendingSmsImports)
          .insert(
            PendingSmsImportsCompanion.insert(
              id: 'imp2',
              fingerprint: 'fp',
              origin: 'paste',
              bankId: 'generic',
              parserId: 'generic',
              ruleVersion: 'generic@1',
              kind: 'unknown',
              direction: 'unknown',
              confidenceJson: '{}',
              createdAt: 1,
              expiresAt: 2,
            ),
          ),
      throwsA(anything),
    );
  });

  test('import_source round-trips through the local mappers', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();
    await db.customStatement(
      'INSERT INTO people (id, name, normalized_name, created_at, '
      "updated_at) VALUES ('p1', 'Mona', 'mona', 1, 1)",
    );
    await db
        .into(db.moneyTransactions)
        .insert(
          MoneyTransactionsCompanion.insert(
            id: 't1',
            idempotencyKey: 'sms-import:imp1',
            personId: 'p1',
            amountMinorUnits: 1000,
            direction: 'given',
            kind: 'initialExchange',
            date: 1,
            createdAt: 1,
            importSource: const Value('sms'),
          ),
        );
    await db
        .into(db.financeEntries)
        .insert(
          FinanceEntriesCompanion.insert(
            id: 'e1',
            idempotencyKey: 'sms-import:imp2',
            categoryId: 'seed_food',
            type: 'expense',
            amountMinorUnits: 1000,
            date: 1,
            createdAt: 1,
            importSource: const Value('future-thing'),
          ),
        );

    final t = (await db.select(db.moneyTransactions).getSingle()).toDomain();
    expect(t.importSource, ImportProvenance.sms);
    final e = (await db.select(db.financeEntries).getSingle()).toDomain();
    expect(e.importSource!.isUnknown, isTrue);
    expect(e.importSource!.wire, 'future-thing');
  });

  test('dropSmsImportAdditions turns today\'s schema into the v12 shape and '
      'tolerates missing objects', () async {
    final raw = sqlite3.openInMemory();
    addTearDown(raw.close);
    final bootstrap = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    await bootstrap.customSelect('SELECT 1').get();
    await bootstrap.close();

    dropSmsImportAdditions(raw);
    expect(namesOf(raw, 'table'), isNot(anyElement(isIn(smsTables))));
    expect(namesOf(raw, 'index'), isNot(anyElement(isIn(smsIndexes))));
    expect(
      columnsOf(raw, 'money_transactions'),
      isNot(contains('import_source')),
    );
    expect(columnsOf(raw, 'finance_entries'), isNot(contains('import_source')));

    // A second run (everything already gone) is safe.
    dropSmsImportAdditions(raw);
  });
}
