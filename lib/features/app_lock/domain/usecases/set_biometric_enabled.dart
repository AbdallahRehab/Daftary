import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_lock_failures.dart';
import '../repositories/app_lock_repository.dart';
import '../services/biometric_service.dart';

@injectable
class SetBiometricEnabled {
  const SetBiometricEnabled(this._repository, this._biometricService);

  final AppLockRepository _repository;
  final BiometricService _biometricService;

  /// Adds ([enabled] `true`) or removes biometric unlock (FR-024).
  ///
  /// Enabling first asks the device, live, whether biometrics are usable
  /// (hardware present and something enrolled, FR-005); if not, returns a
  /// [BiometricUnavailableFailure] and changes nothing (FR-007). Disabling
  /// never needs the device, so it always goes through.
  Future<Either<Failure, Unit>> call(bool enabled) async {
    if (enabled && !await _biometricService.isAvailable()) {
      return const Left(
        BiometricUnavailableFailure(
          'No biometrics are enrolled on this device, or it has no '
          'biometric hardware',
        ),
      );
    }
    return _repository.setBiometricEnabled(enabled);
  }
}
