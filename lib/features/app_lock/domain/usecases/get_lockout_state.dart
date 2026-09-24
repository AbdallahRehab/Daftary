import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/lockout_state.dart';
import '../repositories/app_lock_repository.dart';

@injectable
class GetLockoutState {
  const GetLockoutState(this._repository);

  final AppLockRepository _repository;

  /// The persisted failed-attempt count and cooldown end (FR-015), read when
  /// the lock screen appears so a relaunch can't skip an active cooldown.
  Future<Either<Failure, LockoutState>> call() => _repository.getLockoutState();
}
