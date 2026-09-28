import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

import '../../domain/services/biometric_service.dart';

/// [BiometricService] over the `local_auth` plugin.
///
/// Never throws (FR-007): every plugin error — no hardware, nothing
/// enrolled, OS lockout, user cancel, a missing platform implementation —
/// is caught here and reported as `false`. Errors are logged by type/code
/// only, in debug builds.
@LazySingleton(as: BiometricService)
class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService(this._auth);

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      // Queried live on every call — enrolment can change while the app is
      // backgrounded (spec Assumptions).
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on LocalAuthException catch (e) {
      _log('isAvailable', e.code.name);
      return false;
    } on PlatformException catch (e) {
      _log('isAvailable', e.code);
      return false;
    } on MissingPluginException {
      _log('isAvailable', 'missingPlugin');
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        // Biometric only: the device passcode is not an App Lock unlock
        // method — the in-app PIN is the fallback (FR-006/FR-007).
        biometricOnly: true,
      );
    } on LocalAuthException catch (e) {
      _log('authenticate', e.code.name);
      return false;
    } on PlatformException catch (e) {
      _log('authenticate', e.code);
      return false;
    } on MissingPluginException {
      _log('authenticate', 'missingPlugin');
      return false;
    }
  }

  void _log(String operation, String code) {
    if (kDebugMode) {
      debugPrint('LocalAuthBiometricService.$operation failed: $code');
    }
  }
}
