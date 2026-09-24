import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_lock_failures.dart';
import '../repositories/app_lock_repository.dart';

@injectable
class ChangePin {
  const ChangePin(this._repository);

  final AppLockRepository _repository;

  /// Replaces the existing PIN with [newPin] (FR-023) and resets the
  /// lockout state. The caller must already have re-authenticated with the
  /// current PIN or biometrics — this use case does not verify anything.
  ///
  /// When [confirmation] is given it must equal [newPin], otherwise nothing
  /// is persisted and a [PinMismatchFailure] is returned.
  Future<Either<Failure, Unit>> call(String newPin, {String? confirmation}) {
    if (confirmation != null && confirmation != newPin) {
      return Future.value(const Left(PinMismatchFailure()));
    }
    return _repository.changePin(newPin);
  }
}
