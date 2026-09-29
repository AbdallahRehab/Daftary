import 'package:daftary/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

import 'v11_fixture.dart';
import 'v9_fixture.dart';

/// A database exactly as the pre-merge feature line (008 → 009 → 010 → 014)
/// left it at [version] (`6..9`): today's schema minus 011's v11 tables,
/// minus everything `main` added in its own v6..v9 (017, 018, 020, 021) and
/// minus every feature-line step newer than [version]. Opening [AppDatabase]
/// on it runs the real upgrade a phone that ran those branches takes
/// (v10_merge_features.dart).
///
/// Built from today's schema, then trimmed, rather than typed out by hand,
/// so it cannot drift from the real tables it stands for.
Future<Database> createFeatureLineDatabase(int version) async {
  assert(version >= 6 && version <= 9);
  final raw = sqlite3.openInMemory();
  final bootstrap = AppDatabase.forTesting(
    NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
  );
  // Opening runs onCreate + beforeOpen, which seeds the categories.
  await bootstrap.customSelect('SELECT 1').get();
  await bootstrap.close();

  // 011 (v11), newer than both lines.
  dropSavingsGoalsAdditions(raw);
  // Merge-era columns neither line had before v10.
  raw.execute('ALTER TABLE budgets DROP COLUMN currency_code;');
  raw.execute('ALTER TABLE ocr_scans DROP COLUMN currency_code;');

  // main v9 (021).
  dropSyncSupportAdditions(raw);
  // main v8 (020).
  raw.execute('ALTER TABLE app_settings DROP COLUMN glass_enabled;');
  raw.execute('ALTER TABLE app_settings DROP COLUMN glass_transparency;');
  raw.execute('ALTER TABLE app_settings DROP COLUMN glass_intensity;');
  // main v7 (018).
  raw.execute('DROP TABLE exchange_rates;');
  raw.execute('DROP TABLE primary_currency_settings;');
  raw.execute('ALTER TABLE money_transactions DROP COLUMN currency_code;');
  raw.execute('ALTER TABLE finance_entries DROP COLUMN currency_code;');
  // main v6 (017).
  raw.execute('DROP TABLE notification_history;');
  raw.execute('DROP TABLE notification_preferences;');

  if (version < 9) {
    raw.execute('DROP TABLE ai_messages;');
    raw.execute('DROP TABLE ai_conversations;');
    raw.execute('DROP TABLE ai_settings;');
  }
  if (version < 8) {
    raw.execute('DROP TABLE budget_category_allocations;');
    raw.execute('DROP TABLE budgets;');
  }
  if (version < 7) {
    raw.execute('DROP INDEX idx_transactions_ocr_scan_id;');
    raw.execute('ALTER TABLE money_transactions DROP COLUMN source;');
    raw.execute('ALTER TABLE money_transactions DROP COLUMN ocr_scan_id;');
    raw.execute('DROP TABLE candidate_entries;');
    raw.execute('DROP TABLE ocr_scans;');
  }
  raw.execute('PRAGMA user_version = $version;');
  return raw;
}
