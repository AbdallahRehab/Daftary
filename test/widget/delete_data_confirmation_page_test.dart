import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/data_privacy/domain/usecases/delete_all_user_data.dart';
import 'package:daftary/features/data_privacy/presentation/cubit/delete_account_cubit.dart';
import 'package:daftary/features/data_privacy/presentation/pages/delete_data_confirmation_page.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockDeleteAllUserData extends Mock implements DeleteAllUserData {}

class MockOnboardingCubit extends MockCubit<OnboardingState>
    implements OnboardingCubit {}

/// T034 / T051 — `DeleteDataConfirmationPage` with a *real*
/// `DeleteAccountCubit`, so typing genuinely drives the gate; the spy is
/// the `DeleteAllUserData` use case underneath it, which must never run
/// unless the user completes both deliberate steps.
void main() {
  late MockDeleteAllUserData deleteAllUserData;
  late MockOnboardingCubit onboardingCubit;

  setUp(() {
    deleteAllUserData = MockDeleteAllUserData();
    onboardingCubit = MockOnboardingCubit();
    when(() => onboardingCubit.initialize()).thenAnswer((_) async {});
    getIt.registerFactory<DeleteAccountCubit>(
      () => DeleteAccountCubit(deleteAllUserData, onboardingCubit),
    );
  });

  tearDown(() => getIt.reset());

  /// `/settings` -> `/settings/delete-data`, plus `/` and `/settings/export`
  /// placeholders — the same shape as the real Settings branch.
  GoRouter buildRouter() => GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('HOME_PLACEHOLDER')),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/settings/delete-data'),
              child: const Text('SETTINGS_PLACEHOLDER'),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: 'delete-data',
            builder: (_, _) => const DeleteDataConfirmationPage(),
          ),
          GoRoute(
            path: 'export',
            builder: (_, _) => const Scaffold(body: Text('EXPORT_PLACEHOLDER')),
          ),
        ],
      ),
    ],
  );

  Future<AppLocalizations> pumpPage(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: buildRouter(),
        theme: theme ?? buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('SETTINGS_PLACEHOLDER'));
    await tester.pumpAndSettle();
    return lookupAppLocalizations(locale);
  }

  Finder confirmButton(AppLocalizations l10n) =>
      find.widgetWithText(FilledButton, l10n.deleteDataConfirmAction);

  bool isEnabled(WidgetTester tester, Finder button) =>
      tester.widget<FilledButton>(button).onPressed != null;

  Future<void> typePhrase(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
  }

  testWidgets('the permanent warning is visible before any input (FR-014)', (
    tester,
  ) async {
    final l10n = await pumpPage(tester);

    expect(find.text(l10n.deleteDataTitle), findsOneWidget);
    expect(find.text(l10n.deleteDataWarningTitle), findsOneWidget);
    expect(find.text(l10n.deleteDataWarningMessage), findsOneWidget);
    expect(
      find.text(l10n.deleteDataConfirmLabel(l10n.deleteDataConfirmPhrase)),
      findsOneWidget,
    );
    expect(isEnabled(tester, confirmButton(l10n)), isFalse);
  });

  testWidgets('the delete button stays disabled until the typed phrase '
      'matches exactly (FR-015)', (tester) async {
    final l10n = await pumpPage(tester);
    final button = confirmButton(l10n);

    await typePhrase(tester, 'DELET');
    expect(isEnabled(tester, button), isFalse);

    await typePhrase(tester, 'delete');
    expect(isEnabled(tester, button), isFalse);

    await typePhrase(tester, 'DELETE');
    expect(isEnabled(tester, button), isTrue);

    await typePhrase(tester, 'DELETE!');
    expect(isEnabled(tester, button), isFalse);

    // Tapping a disabled button must not reach the wipe.
    await tester.tap(button);
    await tester.pumpAndSettle();
    verifyNever(() => deleteAllUserData());
  });

  testWidgets('cancel before confirming leaves all data untouched (FR-020)', (
    tester,
  ) async {
    final l10n = await pumpPage(tester);
    await typePhrase(tester, 'DELETE');

    await tester.tap(find.text(l10n.deleteDataCancelAction));
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS_PLACEHOLDER'), findsOneWidget);
    verifyNever(() => deleteAllUserData());
    verifyNever(() => onboardingCubit.initialize());
  });

  testWidgets('navigating back before confirming leaves all data untouched '
      '(FR-020)', (tester) async {
    await pumpPage(tester);
    await typePhrase(tester, 'DELETE');

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS_PLACEHOLDER'), findsOneWidget);
    verifyNever(() => deleteAllUserData());
  });

  testWidgets('"export first" opens the export screen without deleting', (
    tester,
  ) async {
    final l10n = await pumpPage(tester);

    await tester.tap(find.text(l10n.deleteDataExportFirstAction));
    await tester.pumpAndSettle();

    expect(find.text('EXPORT_PLACEHOLDER'), findsOneWidget);
    verifyNever(() => deleteAllUserData());
  });

  testWidgets('confirming shows progress, then resets onboarding and goes '
      'to "/"', (tester) async {
    final completer = Completer<Either<Failure, Unit>>();
    when(() => deleteAllUserData()).thenAnswer((_) => completer.future);
    final l10n = await pumpPage(tester);
    await typePhrase(tester, 'DELETE');

    await tester.tap(confirmButton(l10n));
    await tester.pump();

    expect(find.text(l10n.deleteDataInProgress), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const Right(unit));
    await tester.pumpAndSettle();

    verify(() => deleteAllUserData()).called(1);
    verify(() => onboardingCubit.initialize()).called(1);
    expect(find.text('HOME_PLACEHOLDER'), findsOneWidget);
  });

  testWidgets('a rapid double tap deletes only once (FR-021)', (tester) async {
    when(() => deleteAllUserData()).thenAnswer((_) async => const Right(unit));
    final l10n = await pumpPage(tester);
    await typePhrase(tester, 'DELETE');

    await tester.tap(confirmButton(l10n));
    await tester.tap(confirmButton(l10n), warnIfMissed: false);
    await tester.pumpAndSettle();

    verify(() => deleteAllUserData()).called(1);
  });

  testWidgets('a failed wipe says nothing was removed and offers a retry', (
    tester,
  ) async {
    when(
      () => deleteAllUserData(),
    ).thenAnswer((_) async => const Left(CacheFailure('boom')));
    final l10n = await pumpPage(tester);
    await typePhrase(tester, 'DELETE');

    await tester.tap(confirmButton(l10n));
    await tester.pumpAndSettle();

    expect(find.text(l10n.deleteDataError), findsOneWidget);
    expect(find.text('HOME_PLACEHOLDER'), findsNothing);
    verifyNever(() => onboardingCubit.initialize());

    final retry = find.widgetWithText(FilledButton, l10n.retry);
    expect(isEnabled(tester, retry), isTrue);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    verify(() => deleteAllUserData()).called(2);
  });

  testWidgets('Arabic: RTL, localized copy, and the Arabic phrase is the one '
      'that unlocks deletion', (tester) async {
    final l10n = await pumpPage(tester, locale: const Locale('ar'));

    expect(l10n.deleteDataConfirmPhrase, 'حذف');
    expect(find.text(l10n.deleteDataWarningMessage), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(TextField))),
      TextDirection.rtl,
    );

    final button = confirmButton(l10n);
    await typePhrase(tester, 'DELETE');
    expect(isEnabled(tester, button), isFalse);

    await typePhrase(tester, 'حذف');
    expect(isEnabled(tester, button), isTrue);
  });

  testWidgets('renders in dark mode without errors', (tester) async {
    final l10n = await pumpPage(tester, theme: buildDarkTheme());

    expect(tester.takeException(), isNull);
    expect(find.text(l10n.deleteDataWarningTitle), findsOneWidget);
  });
}
