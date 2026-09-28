import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_lock_failures.dart';
import '../repositories/app_lock_repository.dart';
import '../services/biometric_service.dart';

/// The Forgot-PIN path's non-destructive branch (FR-017): a genuine
/// biometric re-authentication that entitles the user to set a new PIN via
/// `ChangePin` with zero data loss (contracts/app_lock_repository.md).
///
/// Touches nothing but App Lock's own lockout state — a successful
/// biometric check is a genuine authentication, so it clears the PIN
/// lockout exactly as a biometric unlock does (FR-014). The PIN credential
/// itself is only replaced by the `ChangePin` call that follows.
@injectable
class RecoverViaBiometric {
  const RecoverViaBiometric(this._repository, this._biometricService);

  final AppLockRepository _repository;
  final BiometricService _biometricService;

  /// Whether this recovery can be offered at all: the user turned biometric
  /// unlock on AND the device can still perform it right now (enrolment is
  /// queried live, never cached). A storage error answers `false`, leaving
  /// only the wipe path — never a recovery that could not work.
  Future<bool> isAvailable() async {
    final config = await _repository.getConfig();
    final enabled = config.match((_) => false, (c) => c.isBiometricEnabled);
    return enabled && await _biometricService.isAvailable();
  }

  /// `Right(true)` only after a genuine successful biometric check — the
  /// caller may then call `ChangePin`. `Right(false)` when the prompt was
  /// cancelled or failed (never counted against the PIN lockout, FR-008).
  /// `Left(BiometricUnavailableFailure)` when [isAvailable] would be false.
  Future<Either<Failure, bool>> call({required String localizedReason}) async {
    if (!await isAvailable()) return const Left(BiometricUnavailableFailure());
    final authenticated = await _biometricService.authenticate(
      localizedReason: localizedReason,
    );
    if (!authenticated) return const Right(false);
    final reset = await _repository.resetLockout();
    return reset.map((_) => true);
  }
}
