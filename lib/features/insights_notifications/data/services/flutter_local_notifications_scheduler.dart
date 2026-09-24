import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/error/failure.dart';
import '../../domain/entities/composed_notification.dart';
import '../../domain/entities/notification_failures.dart';
import '../../domain/services/notification_scheduler.dart';

/// [NotificationScheduler] over `flutter_local_notifications`.
///
/// The plugin is constructor-injected (registered in `RegisterModule`) so
/// tests can substitute a mock and never touch a real OS notification
/// center. It is initialized lazily on first use, with every OS permission
/// prompt disabled at initialization — permission is only ever requested
/// through [requestPermission] (FR-011).
///
/// Only Android, iOS and macOS are supported; on any other platform the
/// scheduler reports no permission and delivers nothing.
@LazySingleton(as: NotificationScheduler)
class FlutterLocalNotificationsScheduler implements NotificationScheduler {
  FlutterLocalNotificationsScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<NotificationDeepLinkTarget> _taps =
      StreamController<NotificationDeepLinkTarget>.broadcast();
  Future<void>? _initialization;

  static const String channelId = 'insights_reminders';
  static const String _channelName = 'Insights & reminders';
  static const String _channelDescription =
      'Budget-limit warnings and savings-goal check-ins';

  static const DarwinInitializationSettings _darwinSettings =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      _channelName,
      channelDescription: _channelDescription,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  bool get _isSupported => switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS => !kIsWeb,
    _ => false,
  };

  @override
  Stream<NotificationDeepLinkTarget> get taps => _taps.stream;

  @override
  Future<bool> requestPermission() async {
    if (!_isSupported) return false;
    try {
      await _ensureInitialized();
      final granted = switch (defaultTargetPlatform) {
        TargetPlatform.android =>
          await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission(),
        TargetPlatform.iOS =>
          await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true),
        _ =>
          await _plugin
              .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true),
      };
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    if (!_isSupported) return false;
    try {
      await _ensureInitialized();
      final enabled = switch (defaultTargetPlatform) {
        TargetPlatform.android =>
          await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled(),
        TargetPlatform.iOS =>
          (await _plugin
                  .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin
                  >()
                  ?.checkPermissions())
              ?.isEnabled,
        _ =>
          (await _plugin
                  .resolvePlatformSpecificImplementation<
                    MacOSFlutterLocalNotificationsPlugin
                  >()
                  ?.checkPermissions())
              ?.isEnabled,
      };
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Either<Failure, Unit>> scheduleOrDeliver(
    ComposedNotification notification, {
    DateTime? deliverAt,
  }) async {
    if (!await hasPermission()) {
      return const Left(
        NotificationPermissionDeniedFailure(
          'Notification permission is not granted',
        ),
      );
    }
    final payload = notification.deepLinkTarget.encode();
    // One id per source (and month, for budgets): a newer notification about
    // the same thing replaces the older one instead of stacking beside it.
    final id = notificationIdFor(payload);
    try {
      if (deliverAt != null && deliverAt.isAfter(DateTime.now())) {
        // An absolute instant, so UTC is exact and needs no local-zone
        // lookup; the OS still fires at the right local wall-clock time.
        await _plugin.zonedSchedule(
          id: id,
          scheduledDate: tz.TZDateTime.from(deliverAt, tz.UTC),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: notification.title,
          body: notification.body,
          payload: payload,
        );
      } else {
        await _plugin.show(
          id: id,
          title: notification.title,
          body: notification.body,
          notificationDetails: _details,
          payload: payload,
        );
      }
      return const Right(unit);
    } catch (e) {
      return Left(NotificationSchedulingFailure('Failed to deliver: $e'));
    }
  }

  @override
  Future<NotificationDeepLinkTarget?> launchTarget() async {
    if (!_isSupported) return null;
    try {
      await _ensureInitialized();
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      return NotificationDeepLinkTarget.decode(
        details.notificationResponse?.payload,
      );
    } catch (_) {
      return null;
    }
  }

  /// Decodes a tapped notification's payload onto [taps]. Exposed so tests
  /// can drive it the way the plugin's tap callback does.
  @visibleForTesting
  void handleResponse(NotificationResponse response) {
    final target = NotificationDeepLinkTarget.decode(response.payload);
    if (target != null && !_taps.isClosed) _taps.add(target);
  }

  /// Closes [taps]. The scheduler lives for the app's lifetime, so only
  /// tests call this.
  @visibleForTesting
  Future<void> dispose() => _taps.close();

  Future<void> _ensureInitialized() {
    return _initialization ??= _plugin
        .initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: _darwinSettings,
            macOS: _darwinSettings,
          ),
          onDidReceiveNotificationResponse: handleResponse,
        )
        .then<void>((_) {})
        .catchError((Object e) {
          // Let the next call retry rather than caching the failure.
          _initialization = null;
          throw e;
        });
  }

  /// A stable 31-bit id derived from [payload] (FNV-1a) — `String.hashCode`
  /// is not guaranteed stable across app runs, and a notification scheduled
  /// in one run must be replaceable in the next.
  @visibleForTesting
  static int notificationIdFor(String payload) {
    var hash = 0x811c9dc5;
    for (final unit in payload.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}
