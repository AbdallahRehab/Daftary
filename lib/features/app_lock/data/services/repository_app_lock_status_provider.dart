import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/security/app_lock_status_provider.dart';
import '../../domain/repositories/app_lock_repository.dart';

/// Answers `core/security`'s [AppLockStatusProvider] from
/// [AppLockRepository], read fresh on every call (FR-025).
///
/// A configuration that cannot be read is reported as "disabled": failing
/// closed here would show a lock screen that could not verify a PIN either
/// (same unreadable storage), locking the user out of their own data.
@LazySingleton(as: AppLockStatusProvider)
class RepositoryAppLockStatusProvider implements AppLockStatusProvider {
  RepositoryAppLockStatusProvider(this._repository);

  final AppLockRepository _repository;

  @override
  Future<Duration?> lockTimeoutIfEnabled() async {
    final result = await _repository.getConfig();
    return result.fold((failure) {
      if (kDebugMode) {
        debugPrint('App Lock config unavailable: ${failure.runtimeType}');
      }
      return null;
    }, (config) => config.isEnabled ? config.inactivityTimeout.duration : null);
  }
}
