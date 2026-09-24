import 'package:daftary/features/insights_notifications/data/services/flutter_local_notifications_scheduler.dart';
import 'package:daftary/features/insights_notifications/domain/entities/composed_notification.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_failures.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_source_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class _MockIOSPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}

/// T014 — [FlutterLocalNotificationsScheduler] against a mocked plugin: no
/// platform channel is ever reached, so no real OS notification is posted
/// during a test run (plan.md Testability gate).
void main() {
  late _MockPlugin plugin;
  late _MockAndroidPlugin android;
  late FlutterLocalNotificationsScheduler scheduler;

  const budgetNotification = ComposedNotification(
    title: 'Food is close to its limit',
    body: "You've used 92% of your Food budget this month.",
    deepLinkTarget: NotificationDeepLinkTarget(
      type: NotificationSourceType.budgetCategory,
      id: 'cat-food',
      applicablePeriod: '2026-09',
    ),
  );
  const budgetPayload = 'budgetCategory:cat-food@2026-09';

  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(tz.TZDateTime.utc(2026));
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });

  void stubShow() {
    when(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
  }

  void verifyNeverShown() {
    verifyNever(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
        payload: any(named: 'payload'),
      ),
    );
  }

  setUp(() {
    plugin = _MockPlugin();
    android = _MockAndroidPlugin();
    scheduler = FlutterLocalNotificationsScheduler(plugin);
    addTearDown(scheduler.dispose);

    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(android);
    when(() => android.areNotificationsEnabled()).thenAnswer((_) async => true);
    stubShow();
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
  });

  group('permission (Android)', () {
    test('requestPermission asks the OS and returns its answer', () async {
      when(
        () => android.requestNotificationsPermission(),
      ).thenAnswer((_) async => true);

      expect(await scheduler.requestPermission(), isTrue);
      verify(() => android.requestNotificationsPermission()).called(1);
    });

    test('a null answer is reported as not granted', () async {
      when(
        () => android.requestNotificationsPermission(),
      ).thenAnswer((_) async => null);
      expect(await scheduler.requestPermission(), isFalse);
    });

    test('hasPermission checks live without prompting', () async {
      when(
        () => android.areNotificationsEnabled(),
      ).thenAnswer((_) async => false);

      expect(await scheduler.hasPermission(), isFalse);
      verifyNever(() => android.requestNotificationsPermission());
    });

    test('initialization never prompts for permission (FR-011) and happens '
        'once', () async {
      await scheduler.hasPermission();
      await scheduler.hasPermission();

      final settings =
          verify(
                () => plugin.initialize(
                  settings: captureAny(named: 'settings'),
                  onDidReceiveNotificationResponse: any(
                    named: 'onDidReceiveNotificationResponse',
                  ),
                ),
              ).captured.single
              as InitializationSettings;
      expect(settings.android, isNotNull);
      expect(settings.iOS!.requestAlertPermission, isFalse);
      expect(settings.iOS!.requestBadgePermission, isFalse);
      expect(settings.iOS!.requestSoundPermission, isFalse);
    });
  });

  group('permission (iOS)', () {
    late _MockIOSPlugin ios;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      ios = _MockIOSPlugin();
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(ios);
    });

    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('requestPermission requests alert, badge and sound', () async {
      when(
        () => ios.requestPermissions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).thenAnswer((_) async => true);

      expect(await scheduler.requestPermission(), isTrue);
      verify(
        () => ios.requestPermissions(alert: true, badge: true, sound: true),
      ).called(1);
    });

    test('hasPermission reads checkPermissions().isEnabled', () async {
      when(() => ios.checkPermissions()).thenAnswer(
        (_) async => const NotificationsEnabledOptions(
          isEnabled: true,
          isSoundEnabled: true,
          isAlertEnabled: true,
          isBadgeEnabled: true,
          isProvisionalEnabled: false,
          isCriticalEnabled: false,
          isProvidesAppNotificationSettingsEnabled: false,
        ),
      );
      expect(await scheduler.hasPermission(), isTrue);
    });
  });

  test('unsupported platforms report no permission and never touch the '
      'plugin', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(await scheduler.requestPermission(), isFalse);
    expect(await scheduler.hasPermission(), isFalse);
    verifyZeroInteractions(plugin);
  });

  group('scheduleOrDeliver', () {
    test('with no deliverAt, shows immediately with the encoded deep-link '
        'payload', () async {
      final result = await scheduler.scheduleOrDeliver(budgetNotification);

      expect(result.isRight(), isTrue);
      verify(
        () => plugin.show(
          id: FlutterLocalNotificationsScheduler.notificationIdFor(
            budgetPayload,
          ),
          title: budgetNotification.title,
          body: budgetNotification.body,
          notificationDetails: any(named: 'notificationDetails'),
          payload: budgetPayload,
        ),
      ).called(1);
      verifyNever(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('with a future deliverAt (quiet-hours deferral), schedules for that '
        'exact instant', () async {
      final deliverAt = DateTime.now().add(const Duration(hours: 9));

      final result = await scheduler.scheduleOrDeliver(
        budgetNotification,
        deliverAt: deliverAt,
      );

      expect(result.isRight(), isTrue);
      final scheduled =
          verify(
                () => plugin.zonedSchedule(
                  id: any(named: 'id'),
                  scheduledDate: captureAny(named: 'scheduledDate'),
                  notificationDetails: any(named: 'notificationDetails'),
                  androidScheduleMode: any(named: 'androidScheduleMode'),
                  title: budgetNotification.title,
                  body: budgetNotification.body,
                  payload: budgetPayload,
                ),
              ).captured.single
              as tz.TZDateTime;
      expect(
        scheduled.millisecondsSinceEpoch,
        deliverAt.millisecondsSinceEpoch,
      );
      verifyNeverShown();
    });

    test('a deliverAt already in the past shows immediately', () async {
      await scheduler.scheduleOrDeliver(
        budgetNotification,
        deliverAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      verify(
        () => plugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test('without permission, returns NotificationPermissionDeniedFailure '
        'and delivers nothing', () async {
      when(
        () => android.areNotificationsEnabled(),
      ).thenAnswer((_) async => false);

      final result = await scheduler.scheduleOrDeliver(budgetNotification);

      expect(
        result.getLeft().toNullable(),
        isA<NotificationPermissionDeniedFailure>(),
      );
      verifyNeverShown();
    });

    test('a platform error is a NotificationSchedulingFailure, not a '
        'throw', () async {
      when(
        () => plugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenThrow(Exception('boom'));

      final result = await scheduler.scheduleOrDeliver(budgetNotification);

      expect(
        result.getLeft().toNullable(),
        isA<NotificationSchedulingFailure>(),
      );
    });
  });

  group('tap handling', () {
    NotificationResponse tap(String payload) => NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: payload,
    );

    test("the plugin's tap callback emits decoded targets on taps and drops "
        'undecodable payloads', () async {
      await scheduler.hasPermission();
      final onTap =
          verify(
                () => plugin.initialize(
                  settings: any(named: 'settings'),
                  onDidReceiveNotificationResponse: captureAny(
                    named: 'onDidReceiveNotificationResponse',
                  ),
                ),
              ).captured.single
              as DidReceiveNotificationResponseCallback;

      final emitted = expectLater(
        scheduler.taps,
        emitsInOrder([
          const NotificationDeepLinkTarget(
            type: NotificationSourceType.savingsGoal,
            id: 'goal-1',
          ),
          budgetNotification.deepLinkTarget,
        ]),
      );

      onTap(tap('not-a-deep-link'));
      onTap(tap('savingsGoal:goal-1'));
      onTap(tap(budgetPayload));

      await emitted;
    });

    test('launchTarget decodes the notification that launched the '
        'app', () async {
      when(() => plugin.getNotificationAppLaunchDetails()).thenAnswer(
        (_) async => NotificationAppLaunchDetails(
          true,
          notificationResponse: tap('savingsGoal:goal-9'),
        ),
      );

      expect(
        await scheduler.launchTarget(),
        const NotificationDeepLinkTarget(
          type: NotificationSourceType.savingsGoal,
          id: 'goal-9',
        ),
      );
    });

    test('launchTarget is null when a notification did not launch the '
        'app', () async {
      when(
        () => plugin.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => const NotificationAppLaunchDetails(false));

      expect(await scheduler.launchTarget(), isNull);
    });
  });

  group('NotificationDeepLinkTarget payload encoding', () {
    test('round-trips both target types', () {
      const targets = [
        NotificationDeepLinkTarget(
          type: NotificationSourceType.budgetCategory,
          id: 'c1',
          applicablePeriod: '2026-09',
        ),
        NotificationDeepLinkTarget(
          type: NotificationSourceType.budgetCategory,
          id: 'c1',
        ),
        NotificationDeepLinkTarget(
          type: NotificationSourceType.savingsGoal,
          id: '5b7c0a1e-0000-4000-8000-000000000000',
        ),
      ];
      for (final target in targets) {
        expect(NotificationDeepLinkTarget.decode(target.encode()), target);
      }
      expect(targets.first.encode(), 'budgetCategory:c1@2026-09');
      expect(targets[1].encode(), 'budgetCategory:c1');
    });

    test('rejects missing or unrecognized payloads', () {
      for (final payload in [
        null,
        '',
        'budgetCategory',
        'budgetCategory:',
        'unknownType:abc',
        ':abc',
      ]) {
        expect(
          NotificationDeepLinkTarget.decode(payload),
          isNull,
          reason: '$payload',
        );
      }
    });
  });

  test('notification ids are stable per payload and non-negative', () {
    final id = FlutterLocalNotificationsScheduler.notificationIdFor(
      'savingsGoal:goal-1',
    );
    expect(
      FlutterLocalNotificationsScheduler.notificationIdFor(
        'savingsGoal:goal-1',
      ),
      id,
    );
    expect(id, greaterThanOrEqualTo(0));
    expect(
      FlutterLocalNotificationsScheduler.notificationIdFor(
        'savingsGoal:goal-2',
      ),
      isNot(id),
    );
  });
}
