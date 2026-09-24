import '../app_database.dart';

/// 018 Multi-Currency Support — the one coordinated schema step (research.md
/// Decision 3). Each table change is its own identifiable, separately tested
/// step below; every pre-existing amount is explicitly labelled `'EGP'`
/// (FR-002) — `addColumn` applies the column's `'EGP'` default to existing
/// rows, and the explicit UPDATEs make that backfill self-evident rather
/// than implicit.
///
/// Occasions (008), Budgets (010) and Savings Goals (011) have no tables in
/// this codebase yet, so there is nothing of theirs to migrate; they will be
/// created currency-aware from the start.
Future<void> migrateToCurrencySupport(AppDatabase db, Migrator m) async {
  // Step 1: the currency feature's own tables.
  await m.createTable(db.primaryCurrencySettings);
  await m.createTable(db.exchangeRates);
  await m.createIndex(db.idxExchangeRatesPair);

  // Step 2 (001 People/Transactions): money_transactions.currency_code.
  if (!await _hasColumn(db, 'money_transactions', 'currency_code')) {
    await m.addColumn(db.moneyTransactions, db.moneyTransactions.currencyCode);
  }
  await db.customStatement(
    "UPDATE money_transactions SET currency_code = 'EGP' "
    'WHERE currency_code IS NULL',
  );

  // Step 3 (007 Income/Expense): finance_entries.currency_code.
  //
  // Skipped when the column is already there: an install upgrading from
  // v4 or earlier creates `finance_entries` in the same `onUpgrade` run
  // (the `from < 5` step), and `createTable` always uses today's schema —
  // which already includes `currency_code`. Adding it again would fail
  // with "duplicate column name" and abort the whole upgrade.
  if (!await _hasColumn(db, 'finance_entries', 'currency_code')) {
    await m.addColumn(db.financeEntries, db.financeEntries.currencyCode);
  }
  await db.customStatement(
    "UPDATE finance_entries SET currency_code = 'EGP' "
    'WHERE currency_code IS NULL',
  );
}

Future<bool> _hasColumn(AppDatabase db, String table, String column) async {
  final rows = await db.customSelect('PRAGMA table_info("$table")').get();
  return rows.any((row) => row.read<String>('name') == column);
}
