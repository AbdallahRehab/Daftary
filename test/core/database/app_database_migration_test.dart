import 'package:daftary/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/v9_fixture.dart';

void main() {
  test('a fresh install starts directly at schemaVersion 3 with the '
      'themeMode column present and nullable', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            id: 'singleton',
            languageCode: 'en',
            updatedAt: 1,
          ),
        );

    final row = await (db.select(
      db.appSettings,
    )..where((t) => t.id.equals('singleton'))).getSingle();

    expect(row.themeMode, null);
  });

  test('upgrading from schemaVersion 2 leaves themeMode NULL on an '
      'existing row', () async {
    final executor = NativeDatabase.memory();

    // Simulate a pre-003 (schemaVersion 2) database: the AppSettings
    // table exists without the themeMode column, and a row is already
    // present (an upgrading user who already picked a language).
    await executor.ensureOpen(_NoopUser());
    await executor.runCustom('''
        CREATE TABLE app_settings (
          id TEXT NOT NULL PRIMARY KEY,
          language_code TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''', const []);
    await executor.runInsert(
      "INSERT INTO app_settings (id, language_code, updated_at) "
      "VALUES ('singleton', 'ar', 1);",
      const [],
    );
    await executor.runCustom('PRAGMA user_version = 2;', const []);

    // Opening AppDatabase against this same executor triggers
    // MigrationStrategy.onUpgrade(m, 2, 3), which adds the nullable
    // themeMode column without touching existing data.
    final db = AppDatabase.forTesting(executor);
    addTearDown(db.close);

    final row = await (db.select(
      db.appSettings,
    )..where((t) => t.id.equals('singleton'))).getSingle();

    expect(row.languageCode, 'ar');
    expect(row.themeMode, null);
  });

  test('upgrading from schemaVersion 7 adds the three glass columns as NULL '
      'and preserves languageCode/themeMode (020 data-model.md)', () async {
    // A schemaVersion-7 database, built by letting drift create today's
    // schema and then dropping exactly what 020 added — same approach as
    // migration_currency_support_test.dart, so the fixture can't drift
    // from the real v7 tables.
    final raw = sqlite3.openInMemory();
    final bootstrap = AppDatabase.forTesting(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    );
    await bootstrap.select(bootstrap.appSettings).get();
    await bootstrap.close();

    raw.execute('ALTER TABLE app_settings DROP COLUMN glass_enabled;');
    raw.execute('ALTER TABLE app_settings DROP COLUMN glass_transparency;');
    raw.execute('ALTER TABLE app_settings DROP COLUMN glass_intensity;');
    // 021 (v9) additions, so the upgrade runs through v9 for real.
    dropSyncSupportAdditions(raw);
    raw.execute(
      'INSERT INTO app_settings (id, language_code, theme_mode, updated_at) '
      "VALUES ('singleton', 'ar', 'dark', 1);",
    );
    raw.execute('PRAGMA user_version = 7;');

    // Opening AppDatabase against this same handle triggers
    // MigrationStrategy.onUpgrade(m, 7, 8).
    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);

    final row = await (db.select(
      db.appSettings,
    )..where((t) => t.id.equals('singleton'))).getSingle();

    expect(db.schemaVersion, 10);
    expect(raw.select('PRAGMA user_version').single.values.single, 10);
    final columns = [
      for (final c in raw.select('PRAGMA table_info("app_settings")'))
        c['name'] as String,
    ];
    expect(
      columns,
      containsAll(['glass_enabled', 'glass_transparency', 'glass_intensity']),
    );
    expect(row.languageCode, 'ar');
    expect(row.themeMode, 'dark');
    expect(row.glassEnabled, null);
    expect(row.glassTransparency, null);
    expect(row.glassIntensity, null);
  });
}

class _NoopUser extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}

  @override
  int get schemaVersion => 2;
}
