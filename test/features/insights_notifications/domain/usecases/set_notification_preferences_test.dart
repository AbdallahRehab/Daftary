import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_preference.dart';
import 'package:daftary/features/insights_notifications/domain/repositories/notification_preference_repository.dart';
import 'package:daftary/features/insights_notifications/domain/usecases/set_notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationPreferenceRepository extends Mock
    implements NotificationPreferenceRepository {}

void main() {
  late MockNotificationPreferenceRepository repository;
  late SetNotificationPreferences setPreferences;

  const stored = NotificationPreference(
    isEnabled: false,
    budgetWarningsEnabled: true,
    savingsCheckInsEnabled: true,
    osPermissionGranted: true,
  );

  setUpAll(() => registerFallbackValue(NotificationPreference.defaults));

  setUp(() {
    repository = MockNotificationPreferenceRepository();
    setPreferences = SetNotificationPreferences(repository);
    when(
      () => repository.getPreference(),
    ).thenAnswer((_) async => const Right(stored));
    when(() => repository.savePreference(any())).thenAnswer(
      (invocation) async =>
          Right(invocation.positionalArguments.first as NotificationPreference),
    );
  });

  NotificationPreference savedPreference() =>
      verify(() => repository.savePreference(captureAny())).captured.single
          as NotificationPreference;

  test('persists enabling the feature', () async {
    final result = await setPreferences(
      const NotificationPreferenceSettings(
        isEnabled: true,
        budgetWarningsEnabled: true,
        savingsCheckInsEnabled: true,
      ),
    );

    expect(
      result,
      Right<Failure, NotificationPreference>(stored.copyWith(isEnabled: true)),
    );
    expect(savedPreference(), stored.copyWith(isEnabled: true));
  });

  test('persists disabling the feature', () async {
    when(
      () => repository.getPreference(),
    ).thenAnswer((_) async => Right(stored.copyWith(isEnabled: true)));

    await setPreferences(
      const NotificationPreferenceSettings(
        isEnabled: false,
        budgetWarningsEnabled: true,
        savingsCheckInsEnabled: true,
      ),
    );

    expect(savedPreference().isEnabled, isFalse);
  });

  test('persists each category toggle independently', () async {
    await setPreferences(
      const NotificationPreferenceSettings(
        isEnabled: true,
        budgetWarningsEnabled: false,
        savingsCheckInsEnabled: true,
      ),
    );

    final saved = savedPreference();
    expect(saved.budgetWarningsEnabled, isFalse);
    expect(saved.savingsCheckInsEnabled, isTrue);
  });

  test('persists a quiet-hours window that crosses midnight', () async {
    await setPreferences(
      const NotificationPreferenceSettings(
        isEnabled: true,
        budgetWarningsEnabled: true,
        savingsCheckInsEnabled: true,
        quietHoursStart: 22 * 60,
        quietHoursEnd: 8 * 60,
      ),
    );

    final saved = savedPreference();
    expect(saved.quietHoursStart, 22 * 60);
    expect(saved.quietHoursEnd, 8 * 60);
  });

  test('persists clearing the quiet-hours window', () async {
    when(() => repository.getPreference()).thenAnswer(
      (_) async =>
          Right(stored.copyWith(quietHoursStart: 60, quietHoursEnd: 120)),
    );

    await setPreferences(
      const NotificationPreferenceSettings(
        isEnabled: true,
        budgetWarningsEnabled: true,
        savingsCheckInsEnabled: true,
      ),
    );

    expect(savedPreference().hasQuietHours, isFalse);
  });

  test('preserves the stored OS permission state', () async {
    await setPreferences(
      const NotificationPreferenceSettings(
        isEnabled: true,
        budgetWarningsEnabled: true,
        savingsCheckInsEnabled: false,
      ),
    );

    expect(savedPreference().osPermissionGranted, isTrue);
  });

  group('rejects invalid quiet hours without saving', () {
    for (final (label, start, end) in [
      ('only a start', 22 * 60, null),
      ('only an end', null, 8 * 60),
      ('a negative minute', -1, 8 * 60),
      ('a minute past the end of the day', 22 * 60, 24 * 60),
      ('a zero-length window', 60, 60),
    ]) {
      test(label, () async {
        final result = await setPreferences(
          NotificationPreferenceSettings(
            isEnabled: true,
            budgetWarningsEnabled: true,
            savingsCheckInsEnabled: true,
            quietHoursStart: start,
            quietHoursEnd: end,
          ),
        );

        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
        verifyNever(() => repository.savePreference(any()));
      });
    }
  });

  test('returns the repository failure when the read fails', () async {
    when(
      () => repository.getPreference(),
    ).thenAnswer((_) async => const Left(CacheFailure('read')));

    final result = await setPreferences(
      const NotificationPreferenceSettings(
        isEnabled: true,
        budgetWarningsEnabled: true,
        savingsCheckInsEnabled: true,
      ),
    );

    expect(
      result,
      const Left<Failure, NotificationPreference>(CacheFailure('read')),
    );
    verifyNever(() => repository.savePreference(any()));
  });

  test('returns the repository failure when the save fails', () async {
    when(
      () => repository.savePreference(any()),
    ).thenAnswer((_) async => const Left(CacheFailure('write')));

    final result = await setPreferences(
      const NotificationPreferenceSettings(
        isEnabled: true,
        budgetWarningsEnabled: true,
        savingsCheckInsEnabled: true,
      ),
    );

    expect(result.isLeft(), isTrue);
  });
}
