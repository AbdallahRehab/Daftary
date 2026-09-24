import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_preference.dart';
import 'package:daftary/features/insights_notifications/domain/repositories/notification_preference_repository.dart';
import 'package:daftary/features/insights_notifications/domain/services/notification_scheduler.dart';
import 'package:daftary/features/insights_notifications/domain/usecases/request_notification_permission.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationScheduler extends Mock implements NotificationScheduler {}

class MockNotificationPreferenceRepository extends Mock
    implements NotificationPreferenceRepository {}

void main() {
  late MockNotificationScheduler scheduler;
  late MockNotificationPreferenceRepository repository;
  late RequestNotificationPermission requestPermission;

  setUpAll(() => registerFallbackValue(NotificationPreference.defaults));

  setUp(() {
    scheduler = MockNotificationScheduler();
    repository = MockNotificationPreferenceRepository();
    requestPermission = RequestNotificationPermission(scheduler, repository);
    when(
      () => repository.getPreference(),
    ).thenAnswer((_) async => const Right(NotificationPreference.defaults));
    when(() => repository.savePreference(any())).thenAnswer(
      (invocation) async =>
          Right(invocation.positionalArguments.first as NotificationPreference),
    );
  });

  test('never prompts for permission merely by being constructed', () {
    verifyZeroInteractions(scheduler);
    verifyZeroInteractions(repository);
  });

  group('call', () {
    test('prompts once and persists a granted permission', () async {
      when(() => scheduler.requestPermission()).thenAnswer((_) async => true);

      final result = await requestPermission();

      verify(() => scheduler.requestPermission()).called(1);
      verifyNever(() => scheduler.hasPermission());
      final expected = NotificationPreference.defaults.copyWith(
        osPermissionGranted: true,
      );
      verify(() => repository.savePreference(expected)).called(1);
      expect(result, Right<Failure, NotificationPreference>(expected));
    });

    test('persists a denied permission as not granted', () async {
      when(() => repository.getPreference()).thenAnswer(
        (_) async => Right(
          NotificationPreference.defaults.copyWith(
            isEnabled: true,
            osPermissionGranted: true,
          ),
        ),
      );
      when(() => scheduler.requestPermission()).thenAnswer((_) async => false);

      final result = await requestPermission();

      final saved =
          verify(() => repository.savePreference(captureAny())).captured.single
              as NotificationPreference;
      expect(saved.osPermissionGranted, isFalse);
      expect(saved.isEnabled, isTrue, reason: 'other settings are untouched');
      expect(result.getRight().toNullable()?.osPermissionGranted, isFalse);
    });

    test('skips the write when the stored state already matches', () async {
      when(() => scheduler.requestPermission()).thenAnswer((_) async => false);

      final result = await requestPermission();

      verifyNever(() => repository.savePreference(any()));
      expect(
        result,
        const Right<Failure, NotificationPreference>(
          NotificationPreference.defaults,
        ),
      );
    });

    test('surfaces a repository failure', () async {
      when(() => scheduler.requestPermission()).thenAnswer((_) async => true);
      when(
        () => repository.getPreference(),
      ).thenAnswer((_) async => const Left(CacheFailure('read')));

      final result = await requestPermission();

      expect(result.getLeft().toNullable(), const CacheFailure('read'));
    });
  });

  group('refresh', () {
    test('checks live without prompting and persists a revocation', () async {
      when(() => repository.getPreference()).thenAnswer(
        (_) async => Right(
          NotificationPreference.defaults.copyWith(osPermissionGranted: true),
        ),
      );
      when(() => scheduler.hasPermission()).thenAnswer((_) async => false);

      final result = await requestPermission.refresh();

      verifyNever(() => scheduler.requestPermission());
      expect(result.getRight().toNullable()?.osPermissionGranted, isFalse);
      verify(() => repository.savePreference(any())).called(1);
    });

    test('persists a permission granted from device settings', () async {
      when(() => scheduler.hasPermission()).thenAnswer((_) async => true);

      final result = await requestPermission.refresh();

      verifyNever(() => scheduler.requestPermission());
      expect(result.getRight().toNullable()?.osPermissionGranted, isTrue);
    });
  });
}
