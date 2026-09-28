import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_lock_failures.dart';
import '../repositories/app_lock_repository.dart';

@injectable
class SetPin {
  const SetPin(this._repository);

  final AppLockRepository _repository;

  /// Stores [pin] as the first PIN (FR-002/FR-003). Does NOT enable App
  /// Lock — the caller runs `EnableAppLock` afterwards.
  ///
  /// When [confirmation] is given it must equal [pin], otherwise nothing is
  /// persisted and a [PinMismatchFailure] is returned (FR-002's "entered
  /// twice, both entries matching", enforced at the use-case boundary too).
  /// A PIN that isn't 4-6 digits yields the repository's
  /// `ValidationFailure`.
  ///
  /// A credential left behind by an abandoned setup (App Lock never got
  /// enabled, so it protects nothing) is replaced rather than rejected, so
  /// retrying the setup flow can't get stuck. While App Lock is enabled the
  /// existing PIN is never overwritten here — that is `ChangePin`'s job,
  /// behind re-authentication (FR-023).
  Future<Either<Failure, Unit>> call(String pin, {String? confirmation}) async {
    if (confirmation != null && confirmation != pin) {
      return const Left(PinMismatchFailure());
    }
    final config = await _repository.getConfig();
    return config.match((failure) async => Left(failure), (config) {
      if (config.hasPin && !config.isEnabled) {
        return _repository.changePin(pin);
      }
      return _repository.setPin(pin);
    });
  }
}
