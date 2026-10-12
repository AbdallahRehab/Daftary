/// App Lock state, as the SMS domain needs it. Catch-up and shared-text
/// routing wait for unlock.
abstract class LockStatus {
  bool get isLocked;

  /// Emits on every change.
  Stream<bool> get changes;
}
