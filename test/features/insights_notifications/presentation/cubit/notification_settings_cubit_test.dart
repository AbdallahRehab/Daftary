import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_preference.dart';
import 'package:daftary/features/insights_notifications/domain/repositories/notification_preference_repository.dart';
import 'package:daftary/features/insights_notifications/domain/services/notification_scheduler.dart';
import 'package:daftary/features/insights_notifications/domain/usecases/request_notification_permission.dart';
import 'package:daftary/features/insights_notifications/domain/usecases/set_notification_preferences.dart';
import 'package:daftary/features/insights_notifications/presentation/cubit/notification_settings_cubit.dart';
import 'package:daftary/features/insights_notifications/presentation/cubit/notification_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationScheduler extends Mock implements NotificationScheduler {}

class MockNotificationPreferenceRepository extends Mock
    implements NotificationPreferenceRepository {}

void main() {
  late MockNotificationScheduler scheduler;
  late MockNotificationPreferenceRepository repository;

  /// The repository mock behaves like real storage: saves are read back.
  late NotificationPreference stored;
  late bool osGranted;

  setUpAll(() => registerFallbackValue(NotificationPreference.defaults));

  setUp(() {
    scheduler = MockNotificationScheduler();
    repository = MockNotificationPreferenceRepository();
    stored = NotificationPreference.defaults;
    osGranted = false;
    when(
      () => repository.getPreference(),
    ).thenAnswer((_) async => Right(stored));
    when(() => repository.savePreference(any())).thenAnswer((invocation) async {
      stored = invocation.positionalArguments.first as NotificationPreference;
      return Right(stored);
    });
    when(() => scheduler.hasPermission()).thenAnswer((_) async => osGranted);
  });

  NotificationSettingsCubit build() => NotificationSettingsCubit(
    SetNotificationPreferences(repository),
    RequestNotificationPermission(scheduler, repository),
  );

  NotificationSettingsState ready(NotificationPreference preference) =>
      NotificationSettingsState(
        status: NotificationSettingsStatus.ready,
        preference: preference,
      );

  const enabledGranted = NotificationPreference(
    isEnabled: true,
    budgetWarningsEnabled: true,
    savingsCheckInsEnabled: true,
    osPermissionGranted: true,
  );

  test('starts loading', () {
    expect(build().state, const NotificationSettingsState());
  });

  group('load', () {
    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'first open shows the feature off by default and never prompts',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [ready(NotificationPreference.defaults)],
      verify: (_) {
        verifyNever(() => scheduler.requestPermission());
        expect(build().state.showPermissionDeniedBanner, isFalse);
      },
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'refreshes a permission revoked in device settings (FR-012)',
      setUp: () {
        stored = enabledGranted;
        osGranted = false;
      },
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        ready(enabledGranted.copyWith(osPermissionGranted: false)),
      ],
      verify: (cubit) {
        expect(cubit.state.showPermissionDeniedBanner, isTrue);
        expect(stored.osPermissionGranted, isFalse);
      },
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'emits loadFailure when the preference cannot be read',
      setUp: () => when(
        () => repository.getPreference(),
      ).thenAnswer((_) async => const Left(CacheFailure('read'))),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const NotificationSettingsState(
          status: NotificationSettingsStatus.loadFailure,
        ),
      ],
    );
  });

  group('setEnabled', () {
    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'enabling requests permission at that moment and persists the grant',
      setUp: () => when(
        () => scheduler.requestPermission(),
      ).thenAnswer((_) async => true),
      build: build,
      seed: () => ready(NotificationPreference.defaults),
      act: (cubit) => cubit.setEnabled(true),
      expect: () => [
        ready(
          NotificationPreference.defaults,
        ).copyWith(isRequestingPermission: true),
        ready(
          NotificationPreference.defaults.copyWith(osPermissionGranted: true),
        ),
        ready(enabledGranted),
      ],
      verify: (cubit) {
        verify(() => scheduler.requestPermission()).called(1);
        expect(stored, enabledGranted);
        expect(cubit.state.showPermissionDeniedBanner, isFalse);
      },
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'a denial keeps the feature enabled and shows the denied banner',
      setUp: () => when(
        () => scheduler.requestPermission(),
      ).thenAnswer((_) async => false),
      build: build,
      seed: () => ready(NotificationPreference.defaults),
      act: (cubit) => cubit.setEnabled(true),
      expect: () => [
        ready(
          NotificationPreference.defaults,
        ).copyWith(isRequestingPermission: true),
        ready(NotificationPreference.defaults),
        ready(NotificationPreference.defaults.copyWith(isEnabled: true)),
      ],
      verify: (cubit) {
        expect(cubit.state.showPermissionDeniedBanner, isTrue);
        expect(stored.isEnabled, isTrue);
        expect(stored.osPermissionGranted, isFalse);
      },
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'enabling with permission already granted does not prompt again',
      setUp: () => stored = enabledGranted.copyWith(isEnabled: false),
      build: build,
      seed: () => ready(enabledGranted.copyWith(isEnabled: false)),
      act: (cubit) => cubit.setEnabled(true),
      expect: () => [ready(enabledGranted)],
      verify: (_) => verifyNever(() => scheduler.requestPermission()),
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'disabling persists isEnabled=false, which stops all future delivery',
      setUp: () => stored = enabledGranted,
      build: build,
      seed: () => ready(enabledGranted),
      act: (cubit) => cubit.setEnabled(false),
      expect: () => [ready(enabledGranted.copyWith(isEnabled: false))],
      verify: (_) {
        // The engine gates every pass on the stored preference's isEnabled
        // flag, so the persisted value is what stops delivery.
        expect(stored.isEnabled, isFalse);
        verifyNever(() => scheduler.requestPermission());
      },
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'is ignored before the preference has loaded',
      build: build,
      act: (cubit) => cubit.setEnabled(true),
      expect: () => <NotificationSettingsState>[],
      verify: (_) => verifyNever(() => scheduler.requestPermission()),
    );
  });

  group('category toggles', () {
    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'budget warnings toggle independently',
      setUp: () => stored = enabledGranted,
      build: build,
      seed: () => ready(enabledGranted),
      act: (cubit) => cubit.setBudgetWarningsEnabled(false),
      expect: () => [
        ready(enabledGranted.copyWith(budgetWarningsEnabled: false)),
      ],
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'savings check-ins toggle independently',
      setUp: () => stored = enabledGranted,
      build: build,
      seed: () => ready(enabledGranted),
      act: (cubit) => cubit.setSavingsCheckInsEnabled(false),
      expect: () => [
        ready(enabledGranted.copyWith(savingsCheckInsEnabled: false)),
      ],
    );
  });

  group('quiet hours', () {
    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'turning quiet hours on pre-fills the suggested 22:00–08:00 window',
      setUp: () => stored = enabledGranted,
      build: build,
      seed: () => ready(enabledGranted),
      act: (cubit) => cubit.setQuietHoursEnabled(true),
      expect: () => [
        ready(
          enabledGranted.copyWith(quietHoursStart: 1320, quietHoursEnd: 480),
        ),
      ],
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'setting a custom window persists it',
      setUp: () => stored = enabledGranted,
      build: build,
      seed: () => ready(enabledGranted),
      act: (cubit) => cubit.setQuietHours(start: 23 * 60 + 30, end: 7 * 60),
      expect: () => [
        ready(
          enabledGranted.copyWith(quietHoursStart: 1410, quietHoursEnd: 420),
        ),
      ],
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'turning quiet hours off clears the window',
      setUp: () => stored = enabledGranted.copyWith(
        quietHoursStart: 1320,
        quietHoursEnd: 480,
      ),
      build: build,
      seed: () => ready(
        enabledGranted.copyWith(quietHoursStart: 1320, quietHoursEnd: 480),
      ),
      act: (cubit) => cubit.setQuietHoursEnabled(false),
      expect: () => [ready(enabledGranted)],
      verify: (_) => expect(stored.hasQuietHours, isFalse),
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'a zero-length window is rejected and flagged as a failed save',
      setUp: () => stored = enabledGranted,
      build: build,
      seed: () => ready(enabledGranted),
      act: (cubit) => cubit.setQuietHours(start: 60, end: 60),
      expect: () => [ready(enabledGranted).copyWith(isSaveFailing: true)],
      verify: (_) => expect(stored, enabledGranted),
    );
  });

  blocTest<NotificationSettingsCubit, NotificationSettingsState>(
    'a failed save keeps the last persisted preference and flags the failure',
    setUp: () {
      stored = enabledGranted;
      when(
        () => repository.savePreference(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('write')));
    },
    build: build,
    seed: () => ready(enabledGranted),
    act: (cubit) => cubit.setBudgetWarningsEnabled(false),
    expect: () => [ready(enabledGranted).copyWith(isSaveFailing: true)],
  );

  blocTest<NotificationSettingsCubit, NotificationSettingsState>(
    'refreshPermission picks up a grant made in device settings',
    setUp: () {
      stored = NotificationPreference.defaults.copyWith(isEnabled: true);
      osGranted = true;
    },
    build: build,
    seed: () =>
        ready(NotificationPreference.defaults.copyWith(isEnabled: true)),
    act: (cubit) => cubit.refreshPermission(),
    expect: () => [ready(enabledGranted)],
    verify: (_) => verifyNever(() => scheduler.requestPermission()),
  );
}
