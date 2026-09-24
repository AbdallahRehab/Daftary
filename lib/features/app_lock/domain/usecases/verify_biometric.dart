import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/lockout_state.dart';
import '../repositories/app_lock_repository.dart';
import '../services/biometric_service.dart';

@injectable
class VerifyBiometric {
  const VerifyBiometric(this._repository, this._biometricService);

  final AppLockRepository _repository;
  final BiometricService _biometricService;

  /// Runs the OS biometric prompt, showing [localizedReason].
  ///
  /// - Device can't do biometrics right now (enrollment removed, hardware
  ///   gone, OS lockout) -> [UnlockOutcome.biometricUnavailable], so the
  ///   caller falls back to PIN entry (FR-007).
  /// - Cancelled or not recognized -> [UnlockOutcome.biometricFailed]. This
  ///   never reaches the PIN failed-attempt counter (FR-008).
  /// - Success -> resets the PIN lockout exactly like a correct PIN
  ///   (FR-014) and returns [UnlockOutcome.success]. Deliberately works
  ///   during a PIN cooldown: the cooldown only gates PIN entry.
  Future<Either<Failure, UnlockAttemptResult>> call({
    required String localizedReason,
  }) async {
    if (!await _biometricService.isAvailable()) {
      return const Right(
        UnlockAttemptResult(outcome: UnlockOutcome.biometricUnavailable),
      );
    }
    final authenticated = await _biometricService.authenticate(
      localizedReason: localizedReason,
    );
    if (!authenticated) {
      return const Right(
        UnlockAttemptResult(outcome: UnlockOutcome.biometricFailed),
      );
    }
    final reset = await _repository.resetLockout();
    return reset.map((_) => const UnlockAttemptResult.success());
  }
}
