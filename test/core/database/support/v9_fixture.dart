import 'package:sqlite3/sqlite3.dart';

/// Removes exactly what the 021 v9 migration adds (the five sync tables,
/// their indexes and the two business indexes), turning a database created
/// from today's schema back into its pre-021 shape. Every "today's schema
/// minus N" migration fixture calls this so the upgrade runs v9 for real.
void dropSyncSupportAdditions(Database raw) {
  raw.execute('DROP INDEX idx_people_archived;');
  raw.execute('DROP INDEX idx_transactions_date;');
  raw.execute('DROP TABLE sync_outbox;');
  raw.execute('DROP TABLE sync_record_meta;');
  raw.execute('DROP TABLE sync_conflicts;');
  raw.execute('DROP TABLE conflict_resolutions;');
  raw.execute('DROP TABLE sync_state;');
}
