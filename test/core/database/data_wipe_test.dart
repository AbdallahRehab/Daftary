import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/database/data_wipe.dart';
import 'package:daftary/core/database/finance_category_seed.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// T031 — `AppDatabase.deleteAllUserData()` against a real in-memory drift
/// database (research.md Decision 10). Atomicity is a property of the SQL
/// transaction boundary, not of the Dart call sequence, so the failure cases
/// below are forced *inside SQLite* (a `RAISE(ABORT)` trigger) partway
/// through the wipe, and the assertions read the tables back afterwards.
void main() {
  late AppDatabase db;

  // One test deliberately opens a second, independent in-memory database to
  // compare against; the two never share an executor.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Enforce foreign keys for the whole test so the wipe's delete order is
    // proven FK-safe, not merely tolerated by SQLite's lax default.
    await db.customStatement('PRAGMA foreign_keys = ON');
  });

  tearDown(() => db.close());

  Future<int> countRows(TableInfo<Table, dynamic> table) async {
    final row = await db
        .customSelect('SELECT COUNT(*) AS c FROM ${table.actualTableName}')
        .getSingle();
    return row.read<int>('c');
  }

  Future<Map<String, int>> snapshotCounts() async => {
    for (final table in db.allTables)
      table.actualTableName: await countRows(table),
  };

  /// Full row contents of every table, so "intact" means byte-for-byte
  /// identical, not merely the same number of rows.
  Future<Map<String, List<Map<String, Object?>>>> snapshotContents() async => {
    for (final table in db.allTables)
      table.actualTableName: [
        for (final row
            in await db
                .customSelect(
                  'SELECT * FROM ${table.actualTableName} ORDER BY rowid',
                )
                .get())
          row.data,
      ],
  };

  /// Puts at least one row in every table of [AppDatabase], with every
  /// foreign key pointing at a real parent row.
  Future<void> populateEveryTable() async {
    const t = 1760000000000;
    await db
        .into(db.people)
        .insert(
          PeopleCompanion.insert(
            id: 'p1',
            name: 'Ahmed',
            normalizedName: 'ahmed',
            createdAt: t,
            updatedAt: t,
          ),
        );
    await db
        .into(db.occasions)
        .insert(
          OccasionsCompanion.insert(
            id: 'o1',
            idempotencyKey: 'ok1',
            name: 'Wedding',
            date: t,
            type: 'wedding',
            createdAt: t,
            updatedAt: t,
          ),
        );
    await db
        .into(db.occasionAttachments)
        .insert(
          OccasionAttachmentsCompanion.insert(
            id: 'a1',
            occasionId: 'o1',
            filePath: '/nonexistent/a1.jpg',
            createdAt: t,
          ),
        );
    await db
        .into(db.ocrScans)
        .insert(
          OcrScansCompanion.insert(
            id: 's1',
            idempotencyKey: 'sk1',
            sourceImagePath: '/nonexistent/s1.jpg',
            status: 'needsReview',
            occasionId: const Value('o1'),
            createdAt: t,
          ),
        );
    await db
        .into(db.candidateEntries)
        .insert(
          CandidateEntriesCompanion.insert(
            id: 'c1',
            scanId: 's1',
            personName: 'Ahmed',
            personNameConfidenceKind: 'read',
            personNameConfidenceLevel: 'high',
            matchedPersonId: const Value('p1'),
            amountConfidenceKind: 'read',
            amountConfidenceLevel: 'high',
            directionConfidenceKind: 'inferred',
            directionConfidenceLevel: 'low',
            dateConfidenceKind: 'read',
            dateConfidenceLevel: 'none',
            rawOcrText: 'Ahmed 100',
            createdAt: t,
          ),
        );
    await db
        .into(db.moneyTransactions)
        .insert(
          MoneyTransactionsCompanion.insert(
            id: 'm1',
            idempotencyKey: 'mk1',
            personId: 'p1',
            amountMinorUnits: 10000,
            direction: 'given',
            kind: 'occasionContribution',
            date: t,
            occasionId: const Value('o1'),
            createdAt: t,
          ),
        );
    await db
        .into(db.transactionAuditEntries)
        .insert(
          TransactionAuditEntriesCompanion.insert(
            id: 'au1',
            transactionId: 'm1',
            changeType: 'created',
            changedAt: t,
          ),
        );
    // The seeded starter categories already exist (`beforeOpen`); add a
    // custom one too so the post-wipe state is distinguishable from "the
    // wipe skipped this table".
    await db
        .into(db.financeCategories)
        .insert(
          FinanceCategoriesCompanion.insert(
            id: 'custom1',
            name: 'Pets',
            normalizedName: 'pets',
            type: 'expense',
            icon: 'other',
            createdAt: t,
            updatedAt: t,
          ),
        );
    await db
        .into(db.financeEntries)
        .insert(
          FinanceEntriesCompanion.insert(
            id: 'f1',
            idempotencyKey: 'fk1',
            categoryId: 'custom1',
            type: 'expense',
            amountMinorUnits: 5000,
            date: t,
            createdAt: t,
          ),
        );
    await db
        .into(db.budgets)
        .insert(
          BudgetsCompanion.insert(
            id: 'b1',
            idempotencyKey: 'bk1',
            month: '2026-09',
            createdAt: t,
            updatedAt: t,
          ),
        );
    await db
        .into(db.budgetCategoryAllocations)
        .insert(
          BudgetCategoryAllocationsCompanion.insert(
            id: 'ba1',
            idempotencyKey: 'bak1',
            budgetId: 'b1',
            categoryId: 'custom1',
            plannedAmountMinorUnits: 20000,
            createdAt: t,
            updatedAt: t,
          ),
        );
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            id: 'singleton',
            languageCode: 'ar',
            updatedAt: t,
          ),
        );
    await db
        .into(db.onboardingStatus)
        .insert(
          OnboardingStatusCompanion.insert(
            id: 'singleton',
            isComplete: const Value(true),
          ),
        );
  }

  test('fixture populates every table in AppDatabase', () async {
    await populateEveryTable();
    final counts = await snapshotCounts();
    // Guards the rest of this file: if a future feature adds a table, this
    // fails until the fixture (and so the wipe assertions) covers it.
    for (final entry in counts.entries) {
      expect(entry.value, greaterThan(0), reason: '${entry.key} is empty');
    }
  });

  test('empties every table, leaving only the fresh-install starter '
      'categories', () async {
    await populateEveryTable();

    await db.deleteAllUserData();

    for (final table in db.allTables) {
      if (table.actualTableName == db.financeCategories.actualTableName) {
        continue;
      }
      expect(
        await countRows(table),
        0,
        reason: '${table.actualTableName} still has rows',
      );
    }

    final categories = await db.select(db.financeCategories).get();
    expect(categories.map((c) => c.id).toSet(), {
      for (final seed in defaultFinanceCategorySeeds) 'seed_${seed.key}',
    });
    expect(categories.every((c) => c.isDefault && !c.isArchived), isTrue);
  });

  test('post-wipe state equals a freshly created database', () async {
    final fresh = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(fresh.close);
    Future<Map<String, int>> countsOf(AppDatabase d) async => {
      for (final table in d.allTables)
        table.actualTableName:
            (await d
                    .customSelect(
                      'SELECT COUNT(*) AS c FROM ${table.actualTableName}',
                    )
                    .getSingle())
                .read<int>('c'),
    };

    await populateEveryTable();
    await db.deleteAllUserData();

    expect(await countsOf(db), await countsOf(fresh));
  });

  test('is idempotent: a second call on an already-wiped database is a '
      'safe no-op', () async {
    await populateEveryTable();
    await db.deleteAllUserData();
    final afterFirst = await snapshotCounts();

    await db.deleteAllUserData();

    // Counts, not contents: the re-seeded starter rows legitimately carry
    // a new `created_at` each time.
    expect(await snapshotCounts(), afterFirst);
  });

  test('a failure partway through the wipe rolls back every earlier delete '
      '(FR-018)', () async {
    await populateEveryTable();
    final before = await snapshotContents();

    // Several tables (audit entries, transactions, people, occasions,
    // budgets …) are deleted before finance_entries, so by the time this
    // fires the transaction has already emptied most of the database.
    await db.customStatement('''
      CREATE TRIGGER force_wipe_failure BEFORE DELETE ON finance_entries
      BEGIN SELECT RAISE(ABORT, 'forced mid-wipe failure'); END;
    ''');

    await expectLater(db.deleteAllUserData(), throwsA(anything));

    expect(await snapshotContents(), before);
  });

  test('a failure while re-seeding, after every delete has run, still '
      'rolls the whole wipe back', () async {
    await populateEveryTable();
    final before = await snapshotContents();

    await db.customStatement('''
      CREATE TRIGGER force_seed_failure BEFORE INSERT ON finance_categories
      BEGIN SELECT RAISE(ABORT, 'forced re-seed failure'); END;
    ''');

    await expectLater(db.deleteAllUserData(), throwsA(anything));

    expect(await snapshotContents(), before);
  });

  test('userFilePaths lists every stored attachment and scan image', () async {
    await populateEveryTable();

    expect(await db.userFilePaths(), {
      '/nonexistent/a1.jpg',
      '/nonexistent/s1.jpg',
    });
  });
}
