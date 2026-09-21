import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:daftary/features/onboarding/domain/usecases/resolve_onboarding_status.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

class MockPeopleRepository extends Mock implements PeopleRepository {}

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

void main() {
  late MockOnboardingRepository onboardingRepository;
  late MockPeopleRepository peopleRepository;
  late MockTransactionsRepository transactionsRepository;
  late ResolveOnboardingStatus useCase;

  setUp(() {
    onboardingRepository = MockOnboardingRepository();
    peopleRepository = MockPeopleRepository();
    transactionsRepository = MockTransactionsRepository();
    useCase = ResolveOnboardingStatus(
      onboardingRepository,
      peopleRepository,
      transactionsRepository,
    );
  });

  test('already-complete short-circuits to mainApp', () async {
    when(
      () => onboardingRepository.isOnboardingComplete(),
    ).thenAnswer((_) async => const Right(true));

    final result = await useCase();

    expect(result, OnboardingGateStatus.mainApp);
    verifyNever(() => peopleRepository.hasAnyPerson());
    verifyNever(() => transactionsRepository.hasAnyTransaction());
  });

  test(
    'a Person-only install auto-completes onboarding and returns mainApp',
    () async {
      when(
        () => onboardingRepository.isOnboardingComplete(),
      ).thenAnswer((_) async => const Right(false));
      when(
        () => peopleRepository.hasAnyPerson(),
      ).thenAnswer((_) async => const Right(true));
      when(
        () => transactionsRepository.hasAnyTransaction(),
      ).thenAnswer((_) async => const Right(false));
      when(
        () => onboardingRepository.completeOnboarding(),
      ).thenAnswer((_) async => const Right(unit));

      final result = await useCase();

      expect(result, OnboardingGateStatus.mainApp);
      verify(() => onboardingRepository.completeOnboarding()).called(1);
    },
  );

  test('a MoneyTransaction-only install auto-completes onboarding and returns '
      'mainApp', () async {
    when(
      () => onboardingRepository.isOnboardingComplete(),
    ).thenAnswer((_) async => const Right(false));
    when(
      () => peopleRepository.hasAnyPerson(),
    ).thenAnswer((_) async => const Right(false));
    when(
      () => transactionsRepository.hasAnyTransaction(),
    ).thenAnswer((_) async => const Right(true));
    when(
      () => onboardingRepository.completeOnboarding(),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase();

    expect(result, OnboardingGateStatus.mainApp);
    verify(() => onboardingRepository.completeOnboarding()).called(1);
  });

  test(
    'an archived-person-only install auto-completes onboarding (hasAnyPerson '
    'covers archived too)',
    () async {
      when(
        () => onboardingRepository.isOnboardingComplete(),
      ).thenAnswer((_) async => const Right(false));
      when(
        () => peopleRepository.hasAnyPerson(),
      ).thenAnswer((_) async => const Right(true));
      when(
        () => transactionsRepository.hasAnyTransaction(),
      ).thenAnswer((_) async => const Right(false));
      when(
        () => onboardingRepository.completeOnboarding(),
      ).thenAnswer((_) async => const Right(unit));

      final result = await useCase();

      expect(result, OnboardingGateStatus.mainApp);
    },
  );

  test('a soft-deleted-transaction-only install auto-completes onboarding '
      '(hasAnyTransaction covers soft-deleted too)', () async {
    when(
      () => onboardingRepository.isOnboardingComplete(),
    ).thenAnswer((_) async => const Right(false));
    when(
      () => peopleRepository.hasAnyPerson(),
    ).thenAnswer((_) async => const Right(false));
    when(
      () => transactionsRepository.hasAnyTransaction(),
    ).thenAnswer((_) async => const Right(true));
    when(
      () => onboardingRepository.completeOnboarding(),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase();

    expect(result, OnboardingGateStatus.mainApp);
  });

  test('a genuinely empty install returns showOnboarding with nothing '
      'persisted', () async {
    when(
      () => onboardingRepository.isOnboardingComplete(),
    ).thenAnswer((_) async => const Right(false));
    when(
      () => peopleRepository.hasAnyPerson(),
    ).thenAnswer((_) async => const Right(false));
    when(
      () => transactionsRepository.hasAnyTransaction(),
    ).thenAnswer((_) async => const Right(false));

    final result = await useCase();

    expect(result, OnboardingGateStatus.showOnboarding);
    verifyNever(() => onboardingRepository.completeOnboarding());
  });

  test('a Failure from isOnboardingComplete fails open to mainApp', () async {
    when(
      () => onboardingRepository.isOnboardingComplete(),
    ).thenAnswer((_) async => const Left(CacheFailure('DB unavailable')));

    final result = await useCase();

    expect(result, OnboardingGateStatus.mainApp);
  });

  test(
    'a Failure from hasAnyPerson/hasAnyTransaction fails open to mainApp',
    () async {
      when(
        () => onboardingRepository.isOnboardingComplete(),
      ).thenAnswer((_) async => const Right(false));
      when(
        () => peopleRepository.hasAnyPerson(),
      ).thenAnswer((_) async => const Left(CacheFailure('DB unavailable')));
      when(
        () => transactionsRepository.hasAnyTransaction(),
      ).thenAnswer((_) async => const Right(false));

      final result = await useCase();

      expect(result, OnboardingGateStatus.mainApp);
    },
  );
}
