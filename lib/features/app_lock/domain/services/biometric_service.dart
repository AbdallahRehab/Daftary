/// Device biometric authentication (contracts/app_lock_repository.md).
///
/// Never throws to the caller (FR-007): every platform error is caught by
/// the implementation and reported as `false`.
abstract class BiometricService {
  /// Whether the device has biometric hardware AND at least one biometric
  /// enrolled. Queried live on every call — never cached.
  Future<bool> isAvailable();

  /// Presents the OS biometric prompt. `true` only on a genuine successful
  /// authentication; cancelled, failed, or errored prompts return `false`
  /// and never reach the PIN lockout counter (FR-008).
  Future<bool> authenticate({required String localizedReason});
}
