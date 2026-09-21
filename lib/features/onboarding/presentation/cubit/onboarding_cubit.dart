import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/onboarding_repository.dart';
import '../../domain/usecases/resolve_onboarding_status.dart';
import 'onboarding_state.dart';

/// Drives the app-startup onboarding gate and the onboarding flow's own
/// completion/skip actions. Root-scoped (like `SettingsCubit`), since the
/// router's global `redirect:` needs to read its state at every navigation.
@lazySingleton
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._resolveOnboardingStatus, this._onboardingRepository)
    : super(const OnboardingState());

  final ResolveOnboardingStatus _resolveOnboardingStatus;
  final OnboardingRepository _onboardingRepository;

  /// Resolves the FR-001/FR-010a startup gate. Awaited in `main.dart`
  /// before `runApp`, alongside `SettingsCubit.initialize()`.
  Future<void> initialize() async {
    final gateStatus = await _resolveOnboardingStatus();
    emit(
      state.copyWith(
        status: switch (gateStatus) {
          OnboardingGateStatus.showOnboarding =>
            OnboardingLoadStatus.showOnboarding,
          OnboardingGateStatus.mainApp => OnboardingLoadStatus.mainApp,
        },
      ),
    );
  }

  /// The user finished the last onboarding screen (FR-007). Calls the
  /// repository directly — no wrapper use case, per contracts/
  /// onboarding_repository.md and plan.md's Constitution Check
  /// (Principle V), matching existing precedent
  /// (`TransactionFormCubit`/`ArchivedPeopleCubit`).
  Future<void> completeOnboarding() async {
    await _onboardingRepository.completeOnboarding();
    emit(state.copyWith(status: OnboardingLoadStatus.mainApp));
  }

  /// The user explicitly skipped onboarding from any screen (FR-006). The
  /// repository does not distinguish the reason from a normal completion,
  /// per data-model.md's deliberately minimal flag.
  Future<void> skipOnboarding() async {
    await _onboardingRepository.completeOnboarding();
    emit(state.copyWith(status: OnboardingLoadStatus.mainApp));
  }
}
