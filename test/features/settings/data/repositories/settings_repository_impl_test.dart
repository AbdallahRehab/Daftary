import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/settings/data/datasources/settings_dao.dart';
import 'package:daftary/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/domain/entities/app_theme_mode.dart';
import 'package:daftary/features/settings/domain/entities/glass_appearance.dart';
import 'package:daftary/features/settings/domain/entities/glass_level.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsDao extends Mock implements SettingsDao {}

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SettingsRepositoryImpl(SettingsDao(db));
  });

  tearDown(() => db.close());

  test('getLanguagePreference returns null when no row exists yet', () async {
    final result = await repository.getLanguagePreference();

    expect(result, const Right<Object, AppLanguage?>(null));
  });

  test('getThemeModePreference returns null when no row exists yet', () async {
    final result = await repository.getThemeModePreference();

    expect(result, const Right<Object, AppThemeMode?>(null));
  });

  test('getThemeModePreference returns null when the column is NULL on an '
      'existing row (upgraded from schemaVersion 2)', () async {
    await repository.setLanguagePreference(AppLanguage.english);

    final result = await repository.getThemeModePreference();

    expect(result, const Right<Object, AppThemeMode?>(null));
  });

  test('persists then reads back a theme mode preference '
      '(restart-persistence)', () async {
    final setResult = await repository.setThemeModePreference(
      AppThemeMode.dark,
    );
    expect(setResult.isRight(), isTrue);

    final getResult = await repository.getThemeModePreference();

    expect(getResult.getOrElse((_) => null), AppThemeMode.dark);
  });

  test(
    'a theme-only write does not clobber a previously persisted language',
    () async {
      await repository.setLanguagePreference(AppLanguage.arabic);
      await repository.setThemeModePreference(AppThemeMode.dark);

      final language = await repository.getLanguagePreference();

      expect(language.getOrElse((_) => null), AppLanguage.arabic);
    },
  );

  test(
    'a language-only write does not clobber a previously persisted theme',
    () async {
      await repository.setThemeModePreference(AppThemeMode.dark);
      await repository.setLanguagePreference(AppLanguage.arabic);

      final theme = await repository.getThemeModePreference();

      expect(theme.getOrElse((_) => null), AppThemeMode.dark);
    },
  );

  test(
    'persists then reads back a language preference (restart-persistence)',
    () async {
      final setResult = await repository.setLanguagePreference(
        AppLanguage.arabic,
      );
      expect(setResult.isRight(), isTrue);

      final getResult = await repository.getLanguagePreference();

      expect(getResult.isRight(), isTrue);
      expect(getResult.getOrElse((_) => null), AppLanguage.arabic);
    },
  );

  test(
    'overwrites a previously persisted preference on the next write',
    () async {
      await repository.setLanguagePreference(AppLanguage.arabic);
      await repository.setLanguagePreference(AppLanguage.english);

      final result = await repository.getLanguagePreference();

      expect(result.getOrElse((_) => null), AppLanguage.english);
    },
  );

  group('glass appearance (020 contracts/settings_repository.md)', () {
    test('getGlassAppearancePreference returns null when no row exists '
        'yet', () async {
      final result = await repository.getGlassAppearancePreference();

      expect(result, const Right<Object, GlassAppearance?>(null));
    });

    test('a row whose glass columns are all NULL (upgraded install) '
        'resolves to the defaults', () async {
      await repository.setLanguagePreference(AppLanguage.arabic);

      final result = await repository.getGlassAppearancePreference();

      expect(
        result,
        const Right<Object, GlassAppearance?>(GlassAppearance.defaults),
      );
    });

    test('an unknown stored transparency falls back to that field\'s '
        'default only', () async {
      await db
          .into(db.appSettings)
          .insert(
            AppSettingsCompanion.insert(
              id: 'singleton',
              languageCode: AppLanguage.english.code,
              glassEnabled: const Value(false),
              glassTransparency: const Value('bogus'),
              glassIntensity: const Value('high'),
              updatedAt: 1,
            ),
          );

      final result = await repository.getGlassAppearancePreference();

      expect(
        result.getOrElse((_) => null),
        const GlassAppearance(
          enabled: false,
          transparency: GlassLevel.medium,
          intensity: GlassLevel.high,
        ),
      );
    });

    test('persists then reads back a glass appearance, without clobbering '
        'language or theme', () async {
      const appearance = GlassAppearance(
        enabled: false,
        transparency: GlassLevel.high,
        intensity: GlassLevel.low,
      );
      await repository.setLanguagePreference(AppLanguage.arabic);
      await repository.setThemeModePreference(AppThemeMode.dark);

      final setResult = await repository.setGlassAppearancePreference(
        appearance,
      );
      expect(setResult.isRight(), isTrue);

      final glass = await repository.getGlassAppearancePreference();
      final language = await repository.getLanguagePreference();
      final theme = await repository.getThemeModePreference();

      expect(glass.getOrElse((_) => null), appearance);
      expect(language.getOrElse((_) => null), AppLanguage.arabic);
      expect(theme.getOrElse((_) => null), AppThemeMode.dark);
    });

    group('with a mocked DAO', () {
      late MockSettingsDao dao;
      late SettingsRepositoryImpl mockedRepository;

      setUp(() {
        dao = MockSettingsDao();
        mockedRepository = SettingsRepositoryImpl(dao);
      });

      test('a DAO throw on read resolves to Left(CacheFailure)', () async {
        when(() => dao.getPreference()).thenThrow(Exception('boom'));

        final result = await mockedRepository.getGlassAppearancePreference();

        expect(result.getLeft().toNullable(), isA<CacheFailure>());
      });

      test('setGlassAppearancePreference writes all three columns in one '
          'upsertPreference call', () async {
        when(
          () => dao.upsertPreference(
            glassEnabled: any(named: 'glassEnabled'),
            glassTransparency: any(named: 'glassTransparency'),
            glassIntensity: any(named: 'glassIntensity'),
            updatedAt: any(named: 'updatedAt'),
          ),
        ).thenAnswer((_) async {});

        final result = await mockedRepository.setGlassAppearancePreference(
          const GlassAppearance(
            enabled: false,
            transparency: GlassLevel.high,
            intensity: GlassLevel.low,
          ),
        );

        expect(result.isRight(), isTrue);
        verify(
          () => dao.upsertPreference(
            glassEnabled: false,
            glassTransparency: 'high',
            glassIntensity: 'low',
            updatedAt: any(named: 'updatedAt'),
          ),
        ).called(1);
        verifyNoMoreInteractions(dao);
      });

      test('a DAO throw on write resolves to Left(CacheFailure)', () async {
        when(
          () => dao.upsertPreference(
            glassEnabled: any(named: 'glassEnabled'),
            glassTransparency: any(named: 'glassTransparency'),
            glassIntensity: any(named: 'glassIntensity'),
            updatedAt: any(named: 'updatedAt'),
          ),
        ).thenThrow(Exception('disk full'));

        final result = await mockedRepository.setGlassAppearancePreference(
          GlassAppearance.defaults,
        );

        expect(result.getLeft().toNullable(), isA<CacheFailure>());
      });
    });
  });
}
