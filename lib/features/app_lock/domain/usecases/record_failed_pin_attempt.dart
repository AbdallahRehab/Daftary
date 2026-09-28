import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/lockout_state.dart';
import '../repositories/app_lock_repository.dart';

@injectable
class RecordFailedPinAttempt {
  const RecordFailedPinAttempt(this._repository);

  final AppLockRepository _repository;

  /// Counts one wrong PIN and applies the escalating cooldown (FR-013),
  /// returning the persisted [LockoutState] (FR-015).
  ///
  /// Takes no parameters on purpose: the attempted PIN can never be passed
  /// in, so it can never be stored or logged by this path (FR-016). Call it
  /// only after `VerifyPin` reported `UnlockOutcome.incorrectPin` — never
  /// after a failed biometric attempt (FR-008).
  Future<Either<Failure, LockoutState>> call() =>
      _repository.recordFailedPinAttempt();
}
