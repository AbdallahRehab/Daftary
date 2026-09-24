import '../../../../core/error/failure.dart';

/// The entered PIN does not match the stored credential.
class IncorrectPinFailure extends Failure {
  const IncorrectPinFailure([super.message = 'Incorrect PIN']);
}

/// Too many wrong PINs — PIN entry is refused until the cooldown ends
/// (FR-013). [remainingCooldown] drives the lock screen's countdown.
class PinLockedOutFailure extends Failure {
  const PinLockedOutFailure(
    this.remainingCooldown, [
    super.message = 'PIN entry is temporarily locked',
  ]);

  final Duration remainingCooldown;

  @override
  List<Object?> get props => [message, remainingCooldown];
}

/// The confirmation entry did not match the first entry during PIN setup or
/// change. A Presentation/Cubit-level check — nothing is persisted.
class PinMismatchFailure extends Failure {
  const PinMismatchFailure([super.message = 'The PINs do not match']);
}

/// The device has no biometric hardware or nothing enrolled (FR-005/FR-007).
class BiometricUnavailableFailure extends Failure {
  const BiometricUnavailableFailure([
    super.message = 'Biometric authentication is unavailable',
  ]);
}
