import 'package:daftary/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

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
