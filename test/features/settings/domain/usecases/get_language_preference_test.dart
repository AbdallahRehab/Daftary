import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/domain/repositories/settings_repository.dart';
import 'package:daftary/features/settings/domain/usecases/get_language_preference.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;
  late GetLanguagePreference useCase;

  setUp(() {
    repository = MockSettingsRepository();
    useCase = GetLanguagePreference(repository);
  });

  test('delegates to the repository and returns its result', () async {
    when(
      () => repository.getLanguagePreference(),
    ).thenAnswer((_) async => const Right(AppLanguage.arabic));

    final result = await useCase();

    expect(result, const Right<Object, AppLanguage?>(AppLanguage.arabic));
  });

  test(
    'returns null when the repository has no persisted preference',
    () async {
      when(
        () => repository.getLanguagePreference(),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase();

      expect(result, const Right<Object, AppLanguage?>(null));
    },
  );
}
