import '../../../../core/error/failure.dart';

/// The OS has not granted (or has since revoked) notification permission,
/// so nothing can be delivered (FR-012).
class NotificationPermissionDeniedFailure extends Failure {
  const NotificationPermissionDeniedFailure(super.message);
}

/// The platform failed to show or schedule a notification. Rare, and
/// surfaced only for diagnostics — it never stops a recomputation pass from
/// handling its remaining candidates (contracts/notification_engine.md).
class NotificationSchedulingFailure extends Failure {
  const NotificationSchedulingFailure(super.message);
}
