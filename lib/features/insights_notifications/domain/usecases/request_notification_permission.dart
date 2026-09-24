import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/notification_preference.dart';
import '../repositories/notification_preference_repository.dart';
import '../services/notification_scheduler.dart';

/// Owns the stored `osPermissionGranted` flag (FR-011, FR-012).
///
/// [call] is the only path in the app that triggers the OS permission
/// prompt, and it runs only when explicitly invoked — the settings screen
/// invokes it at the moment the user turns the feature on, never at
/// startup. [refresh] is the prompt-free counterpart: a live check that
/// keeps the stored flag honest when permission was granted or revoked
/// from the device settings while the app was elsewhere.
@injectable
class RequestNotificationPermission {
  const RequestNotificationPermission(this._scheduler, this._repository);

  final NotificationScheduler _scheduler;
  final NotificationPreferenceRepository _repository;

  /// Shows the OS permission prompt (where the platform still allows it)
  /// and persists the outcome. Returns the preference as stored.
  Future<Either<Failure, NotificationPreference>> call() async {
    final granted = await _scheduler.requestPermission();
    return _persist(granted);
  }

  /// Re-reads the permission state live, without prompting, and persists
  /// it only when it differs from what is stored. Returns the (possibly
  /// updated) stored preference.
  Future<Either<Failure, NotificationPreference>> refresh() async {
    final granted = await _scheduler.hasPermission();
    return _persist(granted);
  }

  Future<Either<Failure, NotificationPreference>> _persist(bool granted) async {
    final current = await _repository.getPreference();
    return current.fold((failure) async => Left(failure), (stored) {
      if (stored.osPermissionGranted == granted) {
        return Future.value(Right(stored));
      }
      return _repository.savePreference(
        stored.copyWith(osPermissionGranted: granted),
      );
    });
  }
}
