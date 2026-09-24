import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/security/app_lifecycle_observer.dart';
import 'package:daftary/features/app_lock/domain/usecases/recover_via_biometric.dart';
import 'package:daftary/features/app_lock/domain/usecases/wipe_all_local_data.dart';
import 'package:daftary/features/app_lock/presentation/cubit/forgot_pin_cubit.dart';
import 'package:daftary/features/app_lock/presentation/pages/forgot_pin_page.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockRecoverViaBiometric extends Mock implements RecoverViaBiometric {}

class MockWipeAllLocalData extends Mock implements WipeAllLocalData {}

class MockOnboardingCubit extends MockCubit<OnboardingState>
    implements OnboardingCubit {}

class MockAppLifecycleObserver extends Mock implements AppLifecycleObserver {}

/// 015 US4 — `ForgotPinPage` + `WipeConfirmationPage` with a real
/// `ForgotPinCubit`, pushed from a lock-screen stand-in the way the real
/// lock screen pushes it inside `AppLockGate`'s Navigator.
void main() {
  late MockRecoverViaBiometric recover;
  late MockWipeAllLocalData wipe;
  late MockOnboardingCubit onboarding;
  late MockAppLifecycleObserver observer;

  setUp(() {
    recover = MockRecoverViaBiometric();
    wipe = MockWipeAllLocalData();
    onboarding = MockOnboardingCubit();
    observer = MockAppLifecycleObserver();
    when(() => onboarding.initialize()).thenAnswer((_) async {});
    when(() => onboarding.state).thenReturn(
      const OnboardingState(status: OnboardingLoadStatus.showOnboarding),
    );
    when(() => wipe()).thenAnswer((_) async => const Right(unit));
    getIt
      ..registerFactory<ForgotPinCubit>(
        () => ForgotPinCubit(recover, wipe, onboarding),
      )
      ..registerSingleton<OnboardingCubit>(onboarding)
      ..registerSingleton<AppLifecycleObserver>(observer);
  });

  tearDown(() => getIt.reset());

  Future<AppLocalizations> pumpFromLockScreen(
    WidgetTester tester, {
    required bool biometricAvailable,
  }) async {
    when(
      () => recover.isAvailable(),
    ).thenAnswer((_) async => biometricAvailable);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ForgotPinPage()),
              ),
              child: const Text('LOCK_SCREEN'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('LOCK_SCREEN'));
    await tester.pumpAndSettle();
    return lookupAppLocalizations(const Locale('en'));
  }

  Finder eraseButton(AppLocalizations l10n) =>
      find.widgetWithText(FilledButton, l10n.appLockWipeConfirmAction);

  testWidgets('biometric available: offered first, with the wipe as the '
      'only alternative', (tester) async {
    final l10n = await pumpFromLockScreen(tester, biometricAvailable: true);

    expect(find.text(l10n.appLockForgotBiometricTitle), findsOneWidget);
    expect(find.text(l10n.appLockForgotBiometricAction), findsOneWidget);
    expect(find.text(l10n.appLockForgotChooseWipeAction), findsOneWidget);
    expect(find.text(l10n.appLockForgotWipeMessage), findsNothing);
  });

  testWidgets('biometric unavailable: straight to the wipe explanation; '
      'backing out from every screen wipes nothing', (tester) async {
    final l10n = await pumpFromLockScreen(tester, biometricAvailable: false);

    expect(find.text(l10n.appLockForgotWipeMessage), findsOneWidget);
    expect(find.text(l10n.appLockForgotBiometricAction), findsNothing);

    await tester.tap(find.text(l10n.appLockForgotWipeContinueAction));
    await tester.pumpAndSettle();
    expect(find.text(l10n.appLockWipeWarningMessage), findsOneWidget);
    expect(tester.widget<FilledButton>(eraseButton(l10n)).onPressed, isNull);

    await tester.enterText(
      find.byType(TextField),
      l10n.deleteDataConfirmPhrase,
    );
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(eraseButton(l10n)).onPressed, isNotNull);

    await tester.tap(find.text(l10n.appLockWipeCancelAction));
    await tester.pumpAndSettle();
    expect(find.text(l10n.appLockForgotWipeMessage), findsOneWidget);

    await tester.tap(find.text(l10n.appLockForgotBackAction));
    await tester.pumpAndSettle();
    expect(find.text('LOCK_SCREEN'), findsOneWidget);
    verifyNever(() => wipe());
    verifyNever(() => observer.unlock());
  });

  testWidgets('typed phrase + erase wipes once, then dismisses the lock '
      'screen', (tester) async {
    final l10n = await pumpFromLockScreen(tester, biometricAvailable: false);
    await tester.tap(find.text(l10n.appLockForgotWipeContinueAction));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      l10n.deleteDataConfirmPhrase,
    );
    await tester.pumpAndSettle();

    await tester.tap(eraseButton(l10n));
    // Not pumpAndSettle: in the real app the unlock removes this whole
    // Navigator; here the in-progress spinner simply keeps spinning.
    await tester.pump();
    await tester.pump();

    verify(() => wipe()).called(1);
    verify(() => onboarding.initialize()).called(1);
    verify(() => observer.unlock()).called(1);
  });
}
