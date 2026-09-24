import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/app_lock_repository.dart';

/// Turns App Lock off (FR-026) and deletes the stored PIN credential and
/// lockout state (FR-027), so a later re-enable always starts from a fresh
/// PIN setup. The caller has already confirmed and re-authenticated.
///
/// Deliberately does not touch `ScreenshotProtectionService`: screen-capture
/// protection is independent of App Lock and stays on (FR-020).
@injectable
class DisableAppLock {
  const DisableAppLock(this._repository);

  final AppLockRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.disableAppLock();
}
