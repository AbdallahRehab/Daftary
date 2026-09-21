import 'package:equatable/equatable.dart';

/// Presentation-layer load status for [OnboardingState]. Distinct from the
/// domain-layer `OnboardingGateStatus` (only `showOnboarding`/`mainApp`) —
/// `resolving` is this Cubit's own pre-resolution loading state, covering
/// the brief startup window before `ResolveOnboardingStatus.call()`
/// returns, and has no domain equivalent.
enum OnboardingLoadStatus { resolving, showOnboarding, mainApp }

/// Immutable state for [OnboardingCubit] (constitution Principle IV).
class OnboardingState extends Equatable {
  const OnboardingState({this.status = OnboardingLoadStatus.resolving});

  final OnboardingLoadStatus status;

  OnboardingState copyWith({OnboardingLoadStatus? status}) {
    return OnboardingState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => [status];
}
