import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_lock_config.dart';
import '../repositories/app_lock_repository.dart';

/// Persists a new inactivity timeout (FR-011/FR-025).
///
/// Takes effect from the *next* backgrounding only: `AppLifecycleObserver`
/// reads the timeout fresh each time the app is paused, so a timer that is
/// already running keeps the value it started with.
@injectable
class SetInactivityTimeout {
  const SetInactivityTimeout(this._repository);

  final AppLockRepository _repository;

  Future<Either<Failure, Unit>> call(InactivityTimeout timeout) =>
      _repository.setInactivityTimeout(timeout);
}
