import 'package:daftary/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// 017 T008 — the v5 -> v6 migration adds `notification_preferences` and
/// `notification_history` (plus its unique index) and changes nothing else.
void main() {
  /// A schemaVersion-5 database: the current schema minus 017's two tables
  /// (and minus 018's later v7 additions), with pre-existing rows. Built by
  /// letting drift create today's schema and then removing everything added
  /// after v5, so it cannot drift from the real v5 tables the way a
  /// hand-written copy could.
  Future<Database> createV5Database() async {
    final raw = sqlite3.openInMemory();
    final bootstrap = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    await bootstrap.select(bootstrap.financeCategories).get();
    await bootstrap.close();

    raw.execute('DROP INDEX idx_notification_history_source;');
    raw.execute('DROP TABLE notification_history;');
    raw.execute('DROP TABLE notification_preferences;');
    // 018 (v7) additions, so the upgrade runs v5 -> v6 -> v7 for real.
    raw.execute('DROP INDEX idx_exchange_rates_pair;');
    raw.execute('DROP TABLE exchange_rates;');
    raw.execute('DROP TABLE primary_currency_settings;');
    raw.execute('ALTER TABLE money_transactions DROP COLUMN currency_code;');
    raw.execute('ALTER TABLE finance_entries DROP COLUMN currency_code;');
    raw.execute(
      "INSERT INTO app_settings (id, language_code, theme_mode, updated_at) "
      "VALUES ('singleton', 'ar', 'dark', 300);",
    );
    raw.execute('PRAGMA user_version = 5;');
    return raw;
  }

  AppDatabase openUpgraded(Database raw) {
    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);
    return db;
  }

  test('v5 -> v6 creates both notification tables and the unique '
      'index', () async {
    final raw = await createV5Database();
    final db = openUpgraded(raw);

    expect(await db.select(db.notificationPreferences).get(), isEmpty);
    expect(await db.select(db.notificationHistory).get(), isEmpty);

    final index = await db
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type = 'index' "
          "AND name = 'idx_notification_history_source'",
        )
        .getSingle();
    expect(index.read<String>('sql'), contains('UNIQUE'));
  });

  test('v5 -> v6 leaves pre-existing rows untouched', () async {
    final raw = await createV5Database();
    final db = openUpgraded(raw);

    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.languageCode, 'ar');
    expect(settings.themeMode, 'dark');
    expect(await db.select(db.financeCategories).get(), hasLength(22));
  });

  test('schemaVersion is 7 (017 bumped it to 6; 018 to 7)', () {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 7);
  });
}
