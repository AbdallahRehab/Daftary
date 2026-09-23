import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/features/settings/data/datasources/settings_dao.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SettingsDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SettingsDao(db);
  });

  tearDown(() => db.close());

  test('getPreference returns null when no row exists yet', () async {
    final result = await dao.getPreference();

    expect(result, null);
  });

  test('a theme-only upsertPreference does not clobber an existing '
      'languageCode (research.md Decision 3)', () async {
    await dao.upsertPreference(
      languageCode: AppLanguage.arabic.code,
      updatedAt: 1,
    );

    await dao.upsertPreference(themeMode: 'dark', updatedAt: 2);

    final row = await dao.getPreference();
    expect(row!.languageCode, AppLanguage.arabic.code);
    expect(row.themeMode, 'dark');
  });

  test('a language-only upsertPreference does not clobber an existing '
      'themeMode (research.md Decision 3)', () async {
    await dao.upsertPreference(themeMode: 'dark', updatedAt: 1);

    await dao.upsertPreference(
      languageCode: AppLanguage.arabic.code,
      updatedAt: 2,
    );

    final row = await dao.getPreference();
    expect(row!.themeMode, 'dark');
    expect(row.languageCode, AppLanguage.arabic.code);
  });

  test('a theme-only upsertPreference on a brand-new row defaults languageCode '
      'to English', () async {
    await dao.upsertPreference(themeMode: 'dark', updatedAt: 1);

    final row = await dao.getPreference();
    expect(row!.languageCode, AppLanguage.english.code);
    expect(row.themeMode, 'dark');
  });
}
