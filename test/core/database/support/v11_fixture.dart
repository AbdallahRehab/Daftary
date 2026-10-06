import 'package:sqlite3/sqlite3.dart';

/// Removes exactly what the 011 v11 step adds (the three savings tables;
/// their indexes go with them) and what the 022 v12 step adds (the
/// `finance_entry_audits` table and `sync_state.b1_repull_done`), turning a
/// database created from today's schema back into its v10 shape. Every
/// "today's schema minus N" migration fixture calls this, so the upgrade
/// runs v11 and v12 for real.
void dropSavingsGoalsAdditions(Database raw) {
  raw.execute('DROP TABLE savings_contribution_audits;');
  raw.execute('DROP TABLE savings_contributions;');
  raw.execute('DROP TABLE savings_goals;');
  dropFinanceEntryAuditAdditions(raw);
}

/// Removes exactly what the v12 step adds, turning today's schema back into
/// its v11 shape. Tolerates `sync_state` already being gone (the v9
/// helper drops the sync tables).
void dropFinanceEntryAuditAdditions(Database raw) {
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
