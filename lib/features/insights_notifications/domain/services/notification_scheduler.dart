import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/composed_notification.dart';

/// The platform notification boundary (contracts/notification_engine.md).
/// The only Domain-visible way to reach the OS notification system.
abstract class NotificationScheduler {
  /// Requests OS notification permission and returns whether it was
  /// granted. Called only when the user first enables the feature (FR-011),
  /// never at startup.
  Future<bool> requestPermission();

  /// A live (uncached) permission check, used to refresh
  /// `NotificationPreference.osPermissionGranted` (FR-012).
  Future<bool> hasPermission();

  /// Shows [notification] now, or — when [deliverAt] is in the future, as
  /// for a quiet-hours deferral (FR-013) — schedules it for then. The
  /// platform payload carries [ComposedNotification.deepLinkTarget] so a
  /// tap can be resolved (FR-014). Re-checks permission live first and
  /// returns a `NotificationPermissionDeniedFailure` without delivering
  /// when it is missing; a platform error is a
  /// `NotificationSchedulingFailure`.
  Future<Either<Failure, Unit>> scheduleOrDeliver(
    ComposedNotification notification, {
    DateTime? deliverAt,
  });

  /// Every notification the user taps while the app is running, already
  /// decoded. Taps on payloads that no longer decode are dropped.
  Stream<NotificationDeepLinkTarget> get taps;

  /// The notification whose tap cold-started the app, if any — [taps] only
  /// covers taps received after the app is running.
  Future<NotificationDeepLinkTarget?> launchTarget();
}
