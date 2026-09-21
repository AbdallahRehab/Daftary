import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

/// Domain/Data boundary for whether onboarding has been completed
/// (constitution Principle VI). This feature has no network layer, so this
/// interface itself is the contract Presentation and Data both depend on.
abstract class OnboardingRepository {
  /// Whether onboarding has already been completed or skipped on this
  /// install. `Right(false)` covers both "no row exists yet" and an
  /// explicit `isComplete = false` row.
  Future<Either<Failure, bool>> isOnboardingComplete();

  /// Marks onboarding complete (finished normally, explicitly skipped, or
  /// auto-detected via FR-010a — the repository does not distinguish the
  /// reason). Idempotent: calling it again after it is already `true` is a
  /// no-op success.
  Future<Either<Failure, Unit>> completeOnboarding();
}
