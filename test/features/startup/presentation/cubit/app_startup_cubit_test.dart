import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/security/app_lifecycle_observer.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/features/startup/presentation/cubit/app_startup_cubit.dart';
import 'package:daftary/features/startup/presentation/cubit/app_startup_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsCubit extends Mock implements SettingsCubit {}

class _MockOnboardingCubit extends Mock implements OnboardingCubit {}

class _MockAppLifecycleObserver extends Mock implements AppLifecycleObserver {}

const _budget = Duration(milliseconds: 50);

const _preparing = AppStartupState(status: AppStartupStatus.preparing);
const _appearanceResolved = AppStartupState(
  status: AppStartupStatus.preparing,
  appearanceResolved: true,
);
const _ready = AppStartupState(
  status: AppStartupStatus.ready,
  appearanceResolved: true,
);

void main() {
  late _MockSettingsCubit settings;
  late _MockOnboardingCubit onboarding;
  late _MockAppLifecycleObserver appLock;

  setUp(() {
    settings = _MockSettingsCubit();
    onboarding = _MockOnboardingCubit();
    appLock = _MockAppLifecycleObserver();
    when(() => appLock.initialize()).thenAnswer((_) async {});
    when(() => settings.initialize()).thenAnswer((_) async {});
    when(() => onboarding.initialize()).thenAnswer((_) async {});
  });

  AppStartupCubit buildCubit() =>
      AppStartupCubit(settings, onboarding, appLock, timeout: _budget);

  test('initial state is idle with nothing resolved', () {
    expect(buildCubit().state, const AppStartupState());
  });

  group('G1 emission order', () {
    blocTest<AppStartupCubit, AppStartupState>(
      'start() emits preparing, then appearanceResolved, then ready',
      build: buildCubit,
      act: (cubit) => cubit.start(),
      expect: () => [_preparing, _appearanceResolved, _ready],
      verify: (_) {
        verifyInOrder([
          () => settings.initialize(),
          () => onboarding.initialize(),
        ]);
      },
    );
  });

  group('G2 start() is idempotent', () {
    blocTest<AppStartupCubit, AppStartupState>(
      'concurrent start() calls run each step once',
      build: buildCubit,
      act: (cubit) => Future.wait([cubit.start(), cubit.start()]),
      expect: () => [_preparing, _appearanceResolved, _ready],
      verify: (_) {
        verify(() => settings.initialize()).called(1);
        verify(() => onboarding.initialize()).called(1);
      },
    );

    blocTest<AppStartupCubit, AppStartupState>(
      'sequential start() calls run each step once and emit nothing more',
      build: buildCubit,
      act: (cubit) async {
        await cubit.start();
        await cubit.start();
      },
      expect: () => [_preparing, _appearanceResolved, _ready],
      verify: (_) {
        verify(() => settings.initialize()).called(1);
        verify(() => onboarding.initialize()).called(1);
      },
    );
  });

  group('G3 a throwing step fails without rethrowing', () {
    blocTest<AppStartupCubit, AppStartupState>(
      'settings throwing emits failed(error) before appearance resolves',
      build: buildCubit,
      setUp: () {
        when(
          () => settings.initialize(),
        ).thenAnswer((_) async => throw Exception('settings'));
      },
      act: (cubit) => cubit.start(),
      expect: () => [
        _preparing,
        const AppStartupState(
          status: AppStartupStatus.failed,
          failure: StartupFailure.error,
        ),
      ],
      verify: (_) {
        verifyNever(() => onboarding.initialize());
      },
    );

    blocTest<AppStartupCubit, AppStartupState>(
      'onboarding throwing emits failed(error) with appearance resolved',
      build: buildCubit,
      setUp: () {
        when(
          () => onboarding.initialize(),
        ).thenAnswer((_) async => throw Exception('onboarding'));
      },
      act: (cubit) => cubit.start(),
      expect: () => [
        _preparing,
        _appearanceResolved,
        const AppStartupState(
          status: AppStartupStatus.failed,
          appearanceResolved: true,
          failure: StartupFailure.error,
        ),
      ],
    );
  });

  group('G4 budget', () {
    blocTest<AppStartupCubit, AppStartupState>(
      'a step that never completes emits failed(timeout)',
      build: buildCubit,
      setUp: () {
        when(
          () => onboarding.initialize(),
        ).thenAnswer((_) => Completer<void>().future);
      },
      act: (cubit) => cubit.start(),
      expect: () => [
        _preparing,
        _appearanceResolved,
        const AppStartupState(
          status: AppStartupStatus.failed,
          appearanceResolved: true,
          failure: StartupFailure.timeout,
        ),
      ],
    );
  });

  group('G5 retry after an error', () {
    blocTest<AppStartupCubit, AppStartupState>(
      're-runs only the failed step, not the completed one',
      build: buildCubit,
      setUp: () {
        var calls = 0;
        when(() => onboarding.initialize()).thenAnswer((_) async {
          calls++;
          if (calls == 1) throw Exception('first attempt');
        });
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.retry();
      },
      expect: () => [
        _preparing,
        _appearanceResolved,
        const AppStartupState(
          status: AppStartupStatus.failed,
          appearanceResolved: true,
          failure: StartupFailure.error,
        ),
        const AppStartupState(
          status: AppStartupStatus.preparing,
          appearanceResolved: true,
          isRetry: true,
        ),
        const AppStartupState(
          status: AppStartupStatus.ready,
          appearanceResolved: true,
          isRetry: true,
        ),
      ],
      verify: (_) {
        verify(() => settings.initialize()).called(1);
        verify(() => onboarding.initialize()).called(2);
      },
    );
  });

  group('G6 retry after a timeout', () {
    late Completer<void> pending;

    blocTest<AppStartupCubit, AppStartupState>(
      'joins the still-pending step instead of restarting it',
      build: buildCubit,
      setUp: () {
        pending = Completer<void>();
        when(() => onboarding.initialize()).thenAnswer((_) => pending.future);
      },
      act: (cubit) async {
        await cubit.start();
        final retrying = cubit.retry();
        pending.complete();
        await retrying;
      },
      expect: () => [
        _preparing,
        _appearanceResolved,
        const AppStartupState(
          status: AppStartupStatus.failed,
          appearanceResolved: true,
          failure: StartupFailure.timeout,
        ),
        const AppStartupState(
          status: AppStartupStatus.preparing,
          appearanceResolved: true,
          isRetry: true,
        ),
        const AppStartupState(
          status: AppStartupStatus.ready,
          appearanceResolved: true,
          isRetry: true,
        ),
      ],
      verify: (_) {
        verify(() => settings.initialize()).called(1);
        verify(() => onboarding.initialize()).called(1);
      },
    );
  });

  group('G7 retry() outside failed is a no-op', () {
    blocTest<AppStartupCubit, AppStartupState>(
      'in idle',
      build: buildCubit,
      act: (cubit) => cubit.retry(),
      expect: () => const <AppStartupState>[],
      verify: (_) {
        verifyNever(() => settings.initialize());
        verifyNever(() => onboarding.initialize());
      },
    );

    blocTest<AppStartupCubit, AppStartupState>(
      'in preparing',
      build: buildCubit,
      act: (cubit) async {
        final starting = cubit.start();
        await cubit.retry();
        await starting;
      },
      expect: () => [_preparing, _appearanceResolved, _ready],
      verify: (_) {
        verify(() => settings.initialize()).called(1);
        verify(() => onboarding.initialize()).called(1);
      },
    );

    blocTest<AppStartupCubit, AppStartupState>(
      'in ready',
      build: buildCubit,
      seed: () => _ready,
      act: (cubit) => cubit.retry(),
      expect: () => const <AppStartupState>[],
      verify: (_) {
        verifyNever(() => settings.initialize());
        verifyNever(() => onboarding.initialize());
      },
    );
  });

  group('G8 whenReady', () {
    test('completes once startup reaches ready', () async {
      final cubit = buildCubit();
      final whenReady = cubit.whenReady;
      unawaited(cubit.start());
      await expectLater(whenReady, completes);
      expect(cubit.state.isReady, isTrue);
      await cubit.close();
    });

    test('completes immediately when already ready', () async {
      final cubit = buildCubit();
      await cubit.start();
      await expectLater(cubit.whenReady, completes);
      await cubit.close();
    });

    test('completes without error when closed before ready', () async {
      when(
        () => onboarding.initialize(),
      ).thenAnswer((_) => Completer<void>().future);
      final cubit = buildCubit();
      unawaited(cubit.start());
      final whenReady = cubit.whenReady;
      await cubit.close();
      await expectLater(whenReady, completes);
      expect(cubit.state.isReady, isFalse);
    });
  });

  group('G9 App Lock (015)', () {
    test('is not ready until the cold-launch lock state is resolved, so the '
        'router never mounts ahead of the lock screen', () async {
      final lockResolved = Completer<void>();
      when(() => appLock.initialize()).thenAnswer((_) => lockResolved.future);
      final cubit = buildCubit();
      addTearDown(cubit.close);

      unawaited(cubit.start());
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.isReady, isFalse);

      lockResolved.complete();
      await cubit.whenReady;
      expect(cubit.state.isReady, isTrue);
      verify(() => appLock.initialize()).called(1);
    });

    test('a failed lock read fails startup (fail closed), and retry runs it '
        'again', () async {
      var calls = 0;
      when(() => appLock.initialize()).thenAnswer((_) async {
        if (calls++ == 0) throw StateError('keychain unavailable');
      });
      final cubit = buildCubit();
      addTearDown(cubit.close);

      await cubit.start();
      expect(cubit.state.isFailed, isTrue);

      await cubit.retry();
      expect(cubit.state.isReady, isTrue);
      verify(() => appLock.initialize()).called(2);
    });
  });
}
