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

  test('a glass-only upsertPreference preserves an existing languageCode '
      'and themeMode (020 data-model.md Write semantics)', () async {
    await dao.upsertPreference(
      languageCode: AppLanguage.arabic.code,
      themeMode: 'dark',
      updatedAt: 1,
    );

    await dao.upsertPreference(
      glassEnabled: false,
      glassTransparency: 'high',
      glassIntensity: 'low',
      updatedAt: 2,
    );

    final row = await dao.getPreference();
    expect(row!.languageCode, AppLanguage.arabic.code);
    expect(row.themeMode, 'dark');
    expect(row.glassEnabled, isFalse);
    expect(row.glassTransparency, 'high');
    expect(row.glassIntensity, 'low');
    expect(row.updatedAt, 2);
  });

  test('a theme-only upsertPreference preserves all three glass '
      'columns', () async {
    await dao.upsertPreference(
      glassEnabled: false,
      glassTransparency: 'high',
      glassIntensity: 'low',
      updatedAt: 1,
    );

    await dao.upsertPreference(themeMode: 'light', updatedAt: 2);

    final row = await dao.getPreference();
    expect(row!.themeMode, 'light');
    expect(row.glassEnabled, isFalse);
    expect(row.glassTransparency, 'high');
    expect(row.glassIntensity, 'low');
  });

  test('a glass-only upsertPreference on a brand-new row defaults '
      'languageCode to English', () async {
    await dao.upsertPreference(
      glassEnabled: true,
      glassTransparency: 'medium',
      glassIntensity: 'high',
      updatedAt: 1,
    );

    final row = await dao.getPreference();
    expect(row!.languageCode, AppLanguage.english.code);
    expect(row.themeMode, null);
    expect(row.glassEnabled, isTrue);
    expect(row.glassTransparency, 'medium');
    expect(row.glassIntensity, 'high');
  });
}
