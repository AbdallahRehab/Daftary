import '../app_database.dart';

/// The v9 -> v10 step that joins two lines of development which each shipped
/// their own "v6..v9" before they were merged:
///
/// - `main`: 017 notifications (v6), 018 currency (v7), 020 glass (v8),
///   021 sync (v9);
/// - the feature line: 008 occasions (v6), 009 OCR (v7), 010 budgets (v8),
///   014 AI assistant (v9).
///
/// A `main` install arrives here with none of the feature-line schema; this
/// step adds it. A feature-line install first has `main`'s v6..v9 steps
/// replayed ([isPreMergeFeatureLine]), then arrives here with the feature-line
/// schema already present. Every addition is therefore guarded by an
/// existence check, so both kinds of install converge on the same schema as
/// a fresh `createAll`.
///
/// Like the v9 step, it runs in one explicit transaction so a failure leaves
/// the file at its previous version and the next open retries cleanly.
Future<void> migrateToMergedFeatures(AppDatabase db, Migrator m) {
  return db.transaction(() => _migrate(db, m));
}

Future<void> _migrate(AppDatabase db, Migrator m) async {
  // 008 Occasions.
  await _ensureTable(db, m, db.occasions);
  await _ensureTable(db, m, db.occasionAttachments);
  await _ensureIndex(db, m, db.idxOccasionsIdempotencyKey);
  await _ensureIndex(db, m, db.idxOccasionsDate);
  await _ensureIndex(db, m, db.idxOccasionsType);
  await _ensureIndex(db, m, db.idxOccasionAttachmentsOccasionId);
  // Both columns are nullable or defaulted, so every existing row stays
  // valid with no backfill: it is not linked to an occasion and counts
  // toward the balance, which is what it always did.
  await _ensureColumn(
    db,
    m,
    db.moneyTransactions,
    db.moneyTransactions.occasionId,
  );
  await _ensureColumn(
    db,
    m,
    db.moneyTransactions,
    db.moneyTransactions.countsTowardBalance,
  );
  await _ensureIndex(db, m, db.idxTransactionsOccasionId);

  // 009 OCR paper entry.
  await _ensureTable(db, m, db.ocrScans);
  await _ensureTable(db, m, db.candidateEntries);
  // A pre-merge scan was read in the only currency the app had.
  await _ensureColumn(db, m, db.ocrScans, db.ocrScans.currencyCode);
  await _ensureIndex(db, m, db.idxOcrScansIdempotencyKey);
  await _ensureIndex(db, m, db.idxOcrScansStatus);
  await _ensureIndex(db, m, db.idxCandidateEntriesScanId);
  await _ensureColumn(db, m, db.moneyTransactions, db.moneyTransactions.source);
  await _ensureColumn(
    db,
    m,
    db.moneyTransactions,
    db.moneyTransactions.ocrScanId,
  );
  await _ensureIndex(db, m, db.idxTransactionsOcrScanId);

  // 010 Household budgets.
  await _ensureTable(db, m, db.budgets);
  await _ensureTable(db, m, db.budgetCategoryAllocations);
  // A pre-merge budget was planned in the only currency the app had.
  await _ensureColumn(db, m, db.budgets, db.budgets.currencyCode);
  await _ensureIndex(db, m, db.idxBudgetsIdempotencyKey);
  await _ensureIndex(db, m, db.idxBudgetsMonth);
  await _ensureIndex(db, m, db.idxBudgetAllocationsBudgetCategory);
  await _ensureIndex(db, m, db.idxBudgetAllocationsIdempotencyKey);
  await _ensureIndex(db, m, db.idxBudgetAllocationsBudgetId);

  // 014 AI assistant.
  await _ensureTable(db, m, db.aiConversations);
  await _ensureTable(db, m, db.aiMessages);
  await _ensureTable(db, m, db.aiSettings);
  await _ensureIndex(db, m, db.idxAiMessagesConversationCreated);
}

/// Whether a database reporting a version in `6..9` was written by the
/// pre-merge feature line rather than by `main`. `main` created
/// `notification_preferences` at its v6 (017) and never dropped it, while
/// the feature line never had it — so its absence at v6+ identifies the
/// feature line, whatever else the file holds.
Future<bool> isPreMergeFeatureLine(AppDatabase db) async =>
    !await _exists(db, 'table', 'notification_preferences');

Future<void> _ensureTable(
  AppDatabase db,
  Migrator m,
  TableInfo<Table, dynamic> table,
) async {
  if (!await _exists(db, 'table', table.actualTableName)) {
    await m.createTable(table);
  }
}

Future<void> _ensureIndex(AppDatabase db, Migrator m, Index index) async {
  if (!await _exists(db, 'index', index.entityName)) {
    await m.createIndex(index);
  }
}

Future<void> _ensureColumn(
  AppDatabase db,
  Migrator m,
  TableInfo<Table, dynamic> table,
  GeneratedColumn<Object> column,
) async {
  final rows = await db
      .customSelect('PRAGMA table_info("${table.actualTableName}")')
      .get();
  if (!rows.any((row) => row.read<String>('name') == column.name)) {
    await m.addColumn(table, column);
  }
}

Future<bool> _exists(AppDatabase db, String type, String name) async {
  final rows = await db
      .customSelect(
        'SELECT 1 FROM sqlite_master WHERE type = ? AND name = ?',
        variables: [Variable.withString(type), Variable.withString(name)],
      )
      .get();
  return rows.isNotEmpty;
}
