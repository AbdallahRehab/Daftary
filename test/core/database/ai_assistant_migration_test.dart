// `hide isNull`: drift re-exports a column helper of that name, which would
// otherwise shadow the matcher this file uses.
import 'package:daftary/core/database/app_database.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// T008 — the v8→v9 migration that adds 014's three AI assistant tables.
///
/// Same raw-`sqlite3`-handle technique as the 008/009/010 migration tests.
/// Only the tables the `beforeOpen` category seed touches are created — the
/// upgrade step itself reads and alters no existing table.
void main() {
  Database createV8Database() {
    final raw = sqlite3.openInMemory();
    raw.execute('''
      CREATE TABLE finance_categories (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        normalized_name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0 CHECK (is_default IN (0, 1)),
        is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    raw.execute(
      "INSERT INTO finance_categories (id, name, normalized_name, type, icon, "
      "is_default, is_archived, created_at, updated_at) "
      "VALUES ('c1', 'Groceries', 'groceries', 'expense', 'cart', 0, 0, "
      "100, 100);",
    );
    raw.execute('PRAGMA user_version = 8;');
    return raw;
  }

  test('a v8 database upgrades to v9 with all three AI tables and the '
      'message index, leaving existing data untouched', () async {
    final raw = createV8Database();
    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);

    expect(await db.select(db.aiConversations).get(), isEmpty);
    expect(await db.select(db.aiMessages).get(), isEmpty);
    expect(await db.select(db.aiSettings).get(), isEmpty);
    expect(db.schemaVersion, greaterThanOrEqualTo(9));

    final index = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'idx_ai_messages_conversation_created'",
        )
        .get();
    expect(index, hasLength(1));

    // The proactive-observation de-dup marker (T074) ships in the same,
    // not-yet-released v9 table.
    final settingsColumns = await db
        .customSelect('PRAGMA table_info(ai_settings)')
        .get();
    expect(
      settingsColumns.map((c) => c.read<String>('name')),
      contains('last_observation_key'),
    );

    final category = await (db.select(
      db.financeCategories,
    )..where((c) => c.id.equals('c1'))).getSingle();
    expect(category.name, 'Groceries');
  });

  test('AI settings defaults to disabled with no stored credential', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db
        .into(db.aiSettings)
        .insert(AiSettingsCompanion.insert(id: 'singleton', updatedAt: 1));
    final row = await db.select(db.aiSettings).getSingle();
    expect(row.isEnabled, isFalse);
    expect(row.hasStoredCredential, isFalse);
    expect(row.consentAcceptedAt, isNull);
    expect(row.lastObservationKey, isNull);
  });
}
