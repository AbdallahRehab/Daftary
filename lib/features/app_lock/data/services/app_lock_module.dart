import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

/// Registers the `local_auth` plugin handle for App Lock's data layer only,
/// so no other feature can take a dependency on it by accident.
@module
abstract class AppLockModule {
  @lazySingleton
  LocalAuthentication get localAuthentication => LocalAuthentication();
}
