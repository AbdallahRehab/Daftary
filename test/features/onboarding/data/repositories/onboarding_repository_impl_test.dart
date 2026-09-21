import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/features/onboarding/data/datasources/onboarding_dao.dart';
import 'package:daftary/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  late AppDatabase db;
  late OnboardingRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = OnboardingRepositoryImpl(OnboardingDao(db));
  });

  tearDown(() => db.close());

  test(
    'isOnboardingComplete returns Right(false) when no row exists yet',
    () async {
      final result = await repository.isOnboardingComplete();

      expect(result, const Right<Object, bool>(false));
    },
  );

  test(
    'persist-then-read-back returns Right(true) after completeOnboarding',
    () async {
      final completeResult = await repository.completeOnboarding();
      expect(completeResult.isRight(), isTrue);

      final readResult = await repository.isOnboardingComplete();

      expect(readResult, const Right<Object, bool>(true));
    },
  );

  test(
    'a second completeOnboarding call is a no-op success (idempotency)',
    () async {
      final first = await repository.completeOnboarding();
      final second = await repository.completeOnboarding();

      expect(first.isRight(), isTrue);
      expect(second.isRight(), isTrue);
      final readResult = await repository.isOnboardingComplete();
      expect(readResult, const Right<Object, bool>(true));
    },
  );
}
