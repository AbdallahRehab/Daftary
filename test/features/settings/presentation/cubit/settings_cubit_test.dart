import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/device/device_locale_provider.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/domain/entities/app_theme_mode.dart';
import 'package:daftary/features/settings/domain/repositories/settings_repository.dart';
import 'package:daftary/features/settings/domain/usecases/change_language.dart';
import 'package:daftary/features/settings/domain/usecases/change_theme_mode.dart';
import 'package:daftary/features/settings/domain/usecases/get_language_preference.dart';
import 'package:daftary/features/settings/domain/usecases/get_theme_mode_preference.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockDeviceLocaleProvider extends Mock implements DeviceLocaleProvider {}

void main() {
  late MockSettingsRepository settingsRepository;
  late MockDeviceLocaleProvider deviceLocaleProvider;

  setUpAll(() {
    registerFallbackValue(AppLanguage.english);
    registerFallbackValue(AppThemeMode.system);
  });

  setUp(() {
    settingsRepository = MockSettingsRepository();
    deviceLocaleProvider = MockDeviceLocaleProvider();
    when(
      () => settingsRepository.getThemeModePreference(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => settingsRepository.getLanguagePreference(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => deviceLocaleProvider.currentLocale(),
    ).thenReturn(const Locale('en'));
  });

  SettingsCubit buildCubit() => SettingsCubit(
    GetLanguagePreference(settingsRepository),
    ChangeLanguage(settingsRepository),
    deviceLocaleProvider,
    GetThemeModePreference(settingsRepository),
    ChangeThemeMode(settingsRepository),
  );

  group('changeLanguage', () {
    blocTest<SettingsCubit, SettingsState>(
      'synchronously emits the new language',
      build: buildCubit,
      setUp: () {
        when(
          () => settingsRepository.setLanguagePreference(any()),
        ).thenAnswer((_) async => const Right(unit));
      },
      act: (cubit) => cubit.changeLanguage(AppLanguage.arabic),
      expect: () => [const SettingsState(language: AppLanguage.arabic)],
      verify: (_) {
        verify(
          () => settingsRepository.setLanguagePreference(AppLanguage.arabic),
        ).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'sets isPersistFailing only after the retried write also fails (FR-008)',
      build: buildCubit,
      setUp: () {
        when(
          () => settingsRepository.setLanguagePreference(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('disk full')));
      },
      act: (cubit) => cubit.changeLanguage(AppLanguage.arabic),
      expect: () => [
        const SettingsState(language: AppLanguage.arabic),
        const SettingsState(
          language: AppLanguage.arabic,
          isPersistFailing: true,
        ),
      ],
      verify: (_) {
        verify(
          () => settingsRepository.setLanguagePreference(AppLanguage.arabic),
        ).called(2);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'does not flag isPersistFailing when the retry succeeds',
      build: buildCubit,
      setUp: () {
        var callCount = 0;
        when(() => settingsRepository.setLanguagePreference(any())).thenAnswer((
          _,
        ) async {
          callCount++;
          return callCount == 1
              ? const Left(CacheFailure('transient'))
              : const Right(unit);
        });
      },
      act: (cubit) => cubit.changeLanguage(AppLanguage.arabic),
      expect: () => [const SettingsState(language: AppLanguage.arabic)],
    );

    blocTest<SettingsCubit, SettingsState>(
      'toggling the language back and forth 10 times causes no crash and '
      'ends in a consistent state (SC-006)',
      build: buildCubit,
      setUp: () {
        when(
          () => settingsRepository.setLanguagePreference(any()),
        ).thenAnswer((_) async => const Right(unit));
      },
      act: (cubit) async {
        for (var i = 0; i < 10; i++) {
          await cubit.changeLanguage(
            i.isEven ? AppLanguage.arabic : AppLanguage.english,
          );
        }
      },
      // Each toggle alternates to a genuinely different language, so
      // exactly 10 states are expected — no duplicated/collapsed emissions
      // and no extras from a crash or stray retry.
      expect: () => List.generate(
        10,
        (i) => SettingsState(
          language: i.isEven ? AppLanguage.arabic : AppLanguage.english,
        ),
      ),
      verify: (cubit) {
        expect(cubit.state.language, AppLanguage.english);
        expect(cubit.state.isPersistFailing, isFalse);
      },
    );
  });

  group('initialize', () {
    blocTest<SettingsCubit, SettingsState>(
      'resolves to the persisted preference when one exists',
      build: buildCubit,
      setUp: () {
        when(
          () => settingsRepository.getLanguagePreference(),
        ).thenAnswer((_) async => const Right(AppLanguage.arabic));
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [const SettingsState(language: AppLanguage.arabic)],
    );

    blocTest<SettingsCubit, SettingsState>(
      'falls back to the Arabic device locale when no preference is persisted',
      build: buildCubit,
      setUp: () {
        when(
          () => settingsRepository.getLanguagePreference(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => deviceLocaleProvider.currentLocale(),
        ).thenReturn(const Locale('ar'));
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [const SettingsState(language: AppLanguage.arabic)],
    );

    blocTest<SettingsCubit, SettingsState>(
      'falls back to English when the device locale is neither ar nor en '
      '(e.g. French)',
      build: buildCubit,
      setUp: () {
        when(
          () => settingsRepository.getLanguagePreference(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => deviceLocaleProvider.currentLocale(),
        ).thenReturn(const Locale('fr'));
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [const SettingsState(language: AppLanguage.english)],
    );

    blocTest<SettingsCubit, SettingsState>(
      'resolves persisted AppThemeMode.dark exactly',
      build: buildCubit,
      setUp: () {
        when(
          () => settingsRepository.getThemeModePreference(),
        ).thenAnswer((_) async => const Right(AppThemeMode.dark));
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [const SettingsState(themeMode: AppThemeMode.dark)],
    );

    blocTest<SettingsCubit, SettingsState>(
      'resolves persisted AppThemeMode.light exactly',
      build: buildCubit,
      setUp: () {
        when(
          () => settingsRepository.getThemeModePreference(),
        ).thenAnswer((_) async => const Right(AppThemeMode.light));
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [const SettingsState(themeMode: AppThemeMode.light)],
    );

    blocTest<SettingsCubit, SettingsState>(
      'resolves to AppThemeMode.system when nothing is persisted (FR-011)',
      build: buildCubit,
      setUp: () {
        when(
          () => settingsRepository.getThemeModePreference(),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [const SettingsState()],
    );
  });

  group('changeThemeMode', () {
    blocTest<SettingsCubit, SettingsState>(
      'synchronously emits the new theme mode',
      build: buildCubit,
      setUp: () {
        when(
          () => settingsRepository.setThemeModePreference(any()),
        ).thenAnswer((_) async => const Right(unit));
      },
      act: (cubit) => cubit.changeThemeMode(AppThemeMode.dark),
      expect: () => [const SettingsState(themeMode: AppThemeMode.dark)],
      verify: (_) {
        verify(
          () => settingsRepository.setThemeModePreference(AppThemeMode.dark),
        ).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'sets isThemeModePersistFailing only after the retried write also fails',
      build: buildCubit,
      setUp: () {
        when(
          () => settingsRepository.setThemeModePreference(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('disk full')));
      },
      act: (cubit) => cubit.changeThemeMode(AppThemeMode.dark),
      expect: () => [
        const SettingsState(themeMode: AppThemeMode.dark),
        const SettingsState(
          themeMode: AppThemeMode.dark,
          isThemeModePersistFailing: true,
        ),
      ],
      verify: (_) {
        verify(
          () => settingsRepository.setThemeModePreference(AppThemeMode.dark),
        ).called(2);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'does not flag isThemeModePersistFailing when the retry succeeds',
      build: buildCubit,
      setUp: () {
        var callCount = 0;
        when(() => settingsRepository.setThemeModePreference(any())).thenAnswer(
          (_) async {
            callCount++;
            return callCount == 1
                ? const Left(CacheFailure('transient'))
                : const Right(unit);
          },
        );
      },
      act: (cubit) => cubit.changeThemeMode(AppThemeMode.dark),
      expect: () => [const SettingsState(themeMode: AppThemeMode.dark)],
    );
  });
}
