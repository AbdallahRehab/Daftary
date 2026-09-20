import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/domain/repositories/settings_repository.dart';
import 'package:daftary/features/settings/domain/usecases/change_language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;
  late ChangeLanguage useCase;

  setUpAll(() {
    registerFallbackValue(AppLanguage.english);
  });

  setUp(() {
    repository = MockSettingsRepository();
    useCase = ChangeLanguage(repository);
  });

  test(
    'returns true and writes once when the first attempt succeeds',
    () async {
      when(
        () => repository.setLanguagePreference(any()),
      ).thenAnswer((_) async => const Right(unit));

      final succeeded = await useCase(AppLanguage.arabic);

      expect(succeeded, isTrue);
      verify(
        () => repository.setLanguagePreference(AppLanguage.arabic),
      ).called(1);
    },
  );

  test(
    'retries exactly once and returns true when the retry succeeds (FR-008)',
    () async {
      var callCount = 0;
      when(() => repository.setLanguagePreference(any())).thenAnswer((_) async {
        callCount++;
        return callCount == 1
            ? const Left(CacheFailure('transient'))
            : const Right(unit);
      });

      final succeeded = await useCase(AppLanguage.arabic);

      expect(succeeded, isTrue);
      verify(
        () => repository.setLanguagePreference(AppLanguage.arabic),
      ).called(2);
    },
  );

  test(
    'returns false after retrying once when both attempts fail (FR-008)',
    () async {
      when(
        () => repository.setLanguagePreference(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('disk full')));

      final succeeded = await useCase(AppLanguage.arabic);

      expect(succeeded, isFalse);
      verify(
        () => repository.setLanguagePreference(AppLanguage.arabic),
      ).called(2);
    },
  );
}
