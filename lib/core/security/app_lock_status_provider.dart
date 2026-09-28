/// What `AppLifecycleObserver` needs to know about App Lock, inverted so
/// `core/security` never imports the `app_lock` feature (constitution
/// Principle II). Implemented by `features/app_lock`.
abstract class AppLockStatusProvider {
  /// The configured inactivity timeout when App Lock is enabled, or `null`
  /// when it is disabled (or has never been configured). Read fresh on every
  /// call — never cached — so a timeout change takes effect on the very next
  /// backgrounding (FR-025).
  Future<Duration?> lockTimeoutIfEnabled();
}
