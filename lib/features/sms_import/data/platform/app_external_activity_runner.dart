import 'package:injectable/injectable.dart';

import '../../../../core/security/app_lifecycle_observer.dart';
import '../../domain/services/external_activity_runner.dart';

/// [ExternalActivityRunner] over `AppLifecycleObserver.runExternalActivity`,
/// so the permission dialog's pause never counts as leaving the app
/// (sms-platform-channel §2.3).
@LazySingleton(as: ExternalActivityRunner)
class AppExternalActivityRunner implements ExternalActivityRunner {
  AppExternalActivityRunner(this._observer);

  final AppLifecycleObserver _observer;

  @override
  Future<T> run<T>(Future<T> Function() body) =>
      _observer.runExternalActivity(body);
}
