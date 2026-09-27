import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/settings/domain/entities/glass_appearance.dart';
import 'package:daftary/features/settings/domain/entities/glass_level.dart';
import 'package:daftary/features/settings/domain/repositories/settings_repository.dart';
import 'package:daftary/features/settings/domain/usecases/change_glass_appearance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;
  late ChangeGlassAppearance useCase;

  const appearance = GlassAppearance(
    enabled: false,
    transparency: GlassLevel.high,
    intensity: GlassLevel.low,
  );

  setUpAll(() {
    registerFallbackValue(GlassAppearance.defaults);
  });

  setUp(() {
    repository = MockSettingsRepository();
    useCase = ChangeGlassAppearance(repository);
  });

  test(
    'returns true and writes once when the first attempt succeeds',
    () async {
      when(
        () => repository.setGlassAppearancePreference(any()),
      ).thenAnswer((_) async => const Right(unit));

      final succeeded = await useCase(appearance);

      expect(succeeded, isTrue);
      verify(
        () => repository.setGlassAppearancePreference(appearance),
      ).called(1);
    },
  );

  test(
    'retries exactly once and returns true when the retry succeeds',
    () async {
      var callCount = 0;
      when(() => repository.setGlassAppearancePreference(any())).thenAnswer((
        _,
      ) async {
        callCount++;
        return callCount == 1
            ? const Left(CacheFailure('transient'))
            : const Right(unit);
      });

      final succeeded = await useCase(appearance);

      expect(succeeded, isTrue);
      verify(
        () => repository.setGlassAppearancePreference(appearance),
      ).called(2);
    },
  );

  test('returns false after retrying once when both attempts fail', () async {
    when(
      () => repository.setGlassAppearancePreference(any()),
    ).thenAnswer((_) async => const Left(CacheFailure('disk full')));

    final succeeded = await useCase(appearance);

    expect(succeeded, isFalse);
    verify(() => repository.setGlassAppearancePreference(appearance)).called(2);
  });
}
