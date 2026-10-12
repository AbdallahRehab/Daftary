import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Removes exactly what the 011 v11 step adds (the three savings tables;
/// their indexes go with them), what the 022 v12 step adds (the
/// `finance_entry_audits` table and `sync_state.b1_repull_done`) and what
/// the 023 v13 step adds ([dropSmsImportAdditions]), turning a database
/// created from today's schema back into its v10 shape. Every "today's
/// schema minus N" migration fixture calls this, so the upgrade runs v11,
/// v12 and v13 for real.
void dropSavingsGoalsAdditions(Database raw) {
  raw.execute('DROP TABLE savings_contribution_audits;');
  raw.execute('DROP TABLE savings_contributions;');
  raw.execute('DROP TABLE savings_goals;');
  dropFinanceEntryAuditAdditions(raw);
}

/// Removes exactly what the v12 step adds, turning today's schema back into
/// its v11 shape. Tolerates `sync_state` already being gone (the v9
/// helper drops the sync tables). Drops the newer v13 additions first, so
/// every caller gets a truthful older shape.
void dropFinanceEntryAuditAdditions(Database raw) {
  dropSmsImportAdditions(raw);
  raw.execute('DROP TABLE IF EXISTS finance_entry_audits;');
  final hasSyncState = raw
      .select(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' "
        "AND name = 'sync_state'",
      )
      .isNotEmpty;
  if (hasSyncState) {
    raw.execute('ALTER TABLE sync_state DROP COLUMN b1_repull_done;');
  }
}

/// Removes exactly what the 023 v13 step adds (the five SMS import tables,
/// their indexes going with them, and the nullable `import_source` column on
/// `money_transactions` and `finance_entries`), turning today's schema back
/// into its v12 shape. Tolerates any of those objects already being gone.
/// `DROP COLUMN` works because `import_source` has no index.
void dropSmsImportAdditions(Database raw) {
  raw.execute('DROP TABLE IF EXISTS pending_sms_imports;');
  raw.execute('DROP TABLE IF EXISTS sms_import_tombstones;');
  raw.execute('DROP TABLE IF EXISTS sms_sender_mutes;');
  raw.execute('DROP TABLE IF EXISTS sms_merchant_category_mappings;');
  raw.execute('DROP TABLE IF EXISTS sms_import_settings;');
  for (final table in const ['money_transactions', 'finance_entries']) {
    final hasColumn = raw
        .select('PRAGMA table_info("$table")')
        .any((c) => c['name'] == 'import_source');
    if (hasColumn) {
      raw.execute('ALTER TABLE $table DROP COLUMN import_source;');
    }
  }
}

/// [row] as a plain map without 023's `import_source` column, after
/// checking that it is NULL. Lets the older "every existing row is
/// unchanged" assertions keep comparing full rows across an upgrade that
/// now also runs v13, which only adds that nullable column
/// (`v13_migration_test.dart` covers the column itself).
Map<String, Object?> withoutImportSource(Map<String, Object?> row) {
  expect(row['import_source'], isNull, reason: 'v13 must not backfill');
  return {
    for (final entry in row.entries)
      if (entry.key != 'import_source') entry.key: entry.value,
  };
}
