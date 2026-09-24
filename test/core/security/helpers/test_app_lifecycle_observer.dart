import 'package:daftary/core/security/app_lifecycle_observer.dart';
import 'package:daftary/core/security/app_lock_status_provider.dart';

/// App Lock status for services that only need an [AppLifecycleObserver] to
/// wrap an external activity (share sheet, picker, cropper) in tests.
class FixedAppLockStatusProvider implements AppLockStatusProvider {
  FixedAppLockStatusProvider([this.timeout]);

  /// `null` = App Lock disabled.
  Duration? timeout;

  @override
  Future<Duration?> lockTimeoutIfEnabled() async => timeout;
}

/// A real [AppLifecycleObserver], never attached to `WidgetsBinding`, so a
/// test can drive `didChangeAppLifecycleState` itself.
AppLifecycleObserver testAppLifecycleObserver({Duration? lockTimeout}) =>
    AppLifecycleObserver(FixedAppLockStatusProvider(lockTimeout));
