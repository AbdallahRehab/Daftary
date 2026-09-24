import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_lock_failures.dart';
import '../entities/lockout_state.dart';
import '../repositories/app_lock_repository.dart';

@injectable
class VerifyPin {
  const VerifyPin(this._repository);

  final AppLockRepository _repository;

  /// Checks [pin] against the stored credential:
  /// - match -> [UnlockOutcome.success] (the repository resets the lockout,
  ///   FR-014);
  /// - mismatch -> [UnlockOutcome.incorrectPin]. The failed-attempt counter
  ///   is NOT touched here: the caller runs `RecordFailedPinAttempt`, which
  ///   never receives the PIN (FR-016);
  /// - active cooldown -> [UnlockAttemptResult.lockedOut] with the time
  ///   left, without the PIN even being compared (FR-013).
  ///
  /// Anything else (no PIN stored, storage error) stays a `Left`.
  Future<Either<Failure, UnlockAttemptResult>> call(String pin) async {
    final result = await _repository.verifyPin(pin);
    return result.match(
      (failure) => failure is PinLockedOutFailure
          ? Right(UnlockAttemptResult.lockedOut(failure.remainingCooldown))
          : Left(failure),
      (matches) => Right(
        matches
            ? const UnlockAttemptResult.success()
            : const UnlockAttemptResult(outcome: UnlockOutcome.incorrectPin),
      ),
    );
  }
}
