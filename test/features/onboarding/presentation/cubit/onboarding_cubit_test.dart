import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:daftary/features/onboarding/domain/usecases/resolve_onboarding_status.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockResolveOnboardingStatus extends Mock
    implements ResolveOnboardingStatus {}

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  late MockResolveOnboardingStatus resolveOnboardingStatus;
  late MockOnboardingRepository onboardingRepository;

  setUp(() {
    resolveOnboardingStatus = MockResolveOnboardingStatus();
    onboardingRepository = MockOnboardingRepository();
  });

  OnboardingCubit buildCubit() =>
      OnboardingCubit(resolveOnboardingStatus, onboardingRepository);

  blocTest<OnboardingCubit, OnboardingState>(
    'initialize() emits showOnboarding for a fresh install',
    build: buildCubit,
    setUp: () {
      when(
        () => resolveOnboardingStatus(),
      ).thenAnswer((_) async => OnboardingGateStatus.showOnboarding);
    },
    act: (cubit) => cubit.initialize(),
    expect: () => [
      const OnboardingState(status: OnboardingLoadStatus.showOnboarding),
    ],
  );

  blocTest<OnboardingCubit, OnboardingState>(
    'initialize() resolves directly to mainApp, with no intermediate '
    'showOnboarding emission, when already complete (US3)',
    build: buildCubit,
    setUp: () {
      when(
        () => resolveOnboardingStatus(),
      ).thenAnswer((_) async => OnboardingGateStatus.mainApp);
    },
    act: (cubit) => cubit.initialize(),
    expect: () => [const OnboardingState(status: OnboardingLoadStatus.mainApp)],
  );

  blocTest<OnboardingCubit, OnboardingState>(
    'completeOnboarding() calls the repository and emits mainApp',
    build: buildCubit,
    setUp: () {
      when(
        () => onboardingRepository.completeOnboarding(),
      ).thenAnswer((_) async => const Right(unit));
    },
    act: (cubit) => cubit.completeOnboarding(),
    expect: () => [const OnboardingState(status: OnboardingLoadStatus.mainApp)],
    verify: (_) {
      verify(() => onboardingRepository.completeOnboarding()).called(1);
    },
  );

  blocTest<OnboardingCubit, OnboardingState>(
    'skipOnboarding() calls the repository and emits mainApp, exactly like '
    'completeOnboarding()',
    build: buildCubit,
    setUp: () {
      when(
        () => onboardingRepository.completeOnboarding(),
      ).thenAnswer((_) async => const Right(unit));
    },
    act: (cubit) => cubit.skipOnboarding(),
    expect: () => [const OnboardingState(status: OnboardingLoadStatus.mainApp)],
    verify: (_) {
      verify(() => onboardingRepository.completeOnboarding()).called(1);
    },
  );
}
