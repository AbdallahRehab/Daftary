import 'package:daftary/features/settings/domain/entities/app_theme_mode.dart';
import 'package:daftary/features/settings/domain/repositories/settings_repository.dart';
import 'package:daftary/features/settings/domain/usecases/get_theme_mode_preference.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;
  late GetThemeModePreference useCase;

  setUp(() {
    repository = MockSettingsRepository();
    useCase = GetThemeModePreference(repository);
  });

  test('delegates to the repository and returns its result', () async {
    when(
      () => repository.getThemeModePreference(),
    ).thenAnswer((_) async => const Right(AppThemeMode.dark));

    final result = await useCase();

    expect(result, const Right<Object, AppThemeMode?>(AppThemeMode.dark));
  });

  test(
    'returns null when the repository has no persisted preference',
    () async {
      when(
        () => repository.getThemeModePreference(),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase();

      expect(result, const Right<Object, AppThemeMode?>(null));
    },
  );
}
