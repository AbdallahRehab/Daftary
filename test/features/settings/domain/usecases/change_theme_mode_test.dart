import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/settings/domain/entities/app_theme_mode.dart';
import 'package:daftary/features/settings/domain/repositories/settings_repository.dart';
import 'package:daftary/features/settings/domain/usecases/change_theme_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;
  late ChangeThemeMode useCase;

  setUpAll(() {
    registerFallbackValue(AppThemeMode.system);
  });

  setUp(() {
    repository = MockSettingsRepository();
    useCase = ChangeThemeMode(repository);
  });

  test(
    'returns true and writes once when the first attempt succeeds',
    () async {
      when(
        () => repository.setThemeModePreference(any()),
      ).thenAnswer((_) async => const Right(unit));

      final succeeded = await useCase(AppThemeMode.dark);

      expect(succeeded, isTrue);
      verify(
        () => repository.setThemeModePreference(AppThemeMode.dark),
      ).called(1);
    },
  );

  test(
    'retries exactly once and returns true when the retry succeeds',
    () async {
      var callCount = 0;
      when(() => repository.setThemeModePreference(any())).thenAnswer((
        _,
      ) async {
        callCount++;
        return callCount == 1
            ? const Left(CacheFailure('transient'))
            : const Right(unit);
      });

      final succeeded = await useCase(AppThemeMode.dark);

      expect(succeeded, isTrue);
      verify(
        () => repository.setThemeModePreference(AppThemeMode.dark),
      ).called(2);
    },
  );

  test('returns false after retrying once when both attempts fail', () async {
    when(
      () => repository.setThemeModePreference(any()),
    ).thenAnswer((_) async => const Left(CacheFailure('disk full')));

    final succeeded = await useCase(AppThemeMode.dark);

    expect(succeeded, isFalse);
    verify(
      () => repository.setThemeModePreference(AppThemeMode.dark),
    ).called(2);
  });
}
