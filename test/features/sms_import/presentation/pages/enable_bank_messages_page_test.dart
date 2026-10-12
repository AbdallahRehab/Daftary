import 'dart:async';

import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/presentation/pages/enable_bank_messages_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';
import '../../helpers/scan_presentation.dart';
import '../../helpers/widget_harness.dart';

/// T123 — `EnableBankMessagesPage` (ui-contract §3.2): the explanation
/// comes before any prompt (FR-005), opening never prompts (FR-002), one
/// screen per permission outcome with the paste fallback (FR-012), the
/// numbered restricted-settings guidance and the re-check on return from
/// App info (FR-072), the 7/30/90 window, the scan and its summary.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  late HubScanDeps deps;
  late FakeSmsImportRepository repository;

  setUp(() {
    deps = HubScanDeps(capability: true);
    repository = FakeSmsImportRepository();
  });
  tearDown(() async {
    await deps.settings.close();
    await repository.close();
  });

  Future<void> pumpEnable(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
    double textScale = 1,
  }) => pumpSmsPage(
    tester,
    EnableBankMessagesPage(
      cubit: buildEnableFlowCubit(deps, repository: repository),
    ),
    locale: locale,
    theme: theme,
    textScale: textScale,
  );

  Future<void> continueFromExplain(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('sms_enable_continue'));
    await tester.scrollUntilVisible(
      button,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  void resume(WidgetTester tester) {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  testWidgets('the explanation says what is read, never done, how to stop; '
      'opening never prompts', (tester) async {
    await pumpEnable(tester);
    expect(find.byKey(const ValueKey('sms_enable_explain')), findsOneWidget);
    expect(find.text(en.smsImportEnableWhatIsRead), findsOneWidget);
    expect(find.text(en.smsImportEnableNever), findsOneWidget);
    expect(find.text(en.smsImportEnableTurnOff), findsOneWidget);
    expect(find.text(en.smsImportEnablePasteInstead), findsOneWidget);
    expect(deps.permissions.requests, 0);
    // A resume before Continue prompts nothing either.
    resume(tester);
    await tester.pumpAndSettle();
    expect(deps.permissions.requests, 0);
  });

  testWidgets('Not now leaves without a prompt', (tester) async {
    await pumpEnable(tester);
    await tester.tap(find.text(en.smsImportEnableNotNow));
    await tester.pumpAndSettle();
    expect(find.text('hub-route'), findsOneWidget);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('Paste instead opens the paste screen', (tester) async {
    await pumpEnable(tester);
    await tester.tap(find.text(en.smsImportEnablePasteInstead));
    await tester.pumpAndSettle();
    expect(find.text('paste-route'), findsOneWidget);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('Continue asks once; granted shows the 7/30/90 window', (
    tester,
  ) async {
    await pumpEnable(tester);
    await continueFromExplain(tester);
    expect(deps.permissions.requests, 1);
    expect(deps.settings.settings.isEnabled, isTrue);
    expect(find.text(en.smsImportEnableWindowTitle), findsOneWidget);
    for (final days in [7, 30, 90]) {
      expect(find.byKey(ValueKey('sms_scan_window_$days')), findsOneWidget);
      expect(find.text(en.smsImportEnableWindowDays(days)), findsOneWidget);
    }
  });

  testWidgets('denied: why, Try again once, and paste or share', (
    tester,
  ) async {
    deps.permissions.requestResult = SmsPermissionStatus.denied;
    await pumpEnable(tester);
    await continueFromExplain(tester);
    expect(
      find.byKey(const ValueKey('sms_enable_step_denied')),
      findsOneWidget,
    );
    expect(find.text(en.smsImportPermissionDeniedDetail), findsOneWidget);
    expect(find.text(en.smsImportPermissionPasteInstead), findsOneWidget);
    // No silent re-prompt on resume (FR-012).
    resume(tester);
    await tester.pumpAndSettle();
    expect(deps.permissions.requests, 1);

    await tester.tap(find.text(en.smsImportPermissionTryAgain));
    await tester.pumpAndSettle();
    expect(deps.permissions.requests, 2);
    expect(find.text(en.smsImportPermissionTryAgain), findsNothing);
    expect(find.text(en.smsImportPermissionPasteInstead), findsOneWidget);
  });

  testWidgets('permanently denied: App info, granted there advances on '
      'return without a prompt', (tester) async {
    deps.permissions.requestResult = SmsPermissionStatus.permanentlyDenied;
    await pumpEnable(tester);
    await continueFromExplain(tester);
    expect(
      find.byKey(const ValueKey('sms_enable_step_permanentlyDenied')),
      findsOneWidget,
    );
    expect(find.text(en.smsImportPermissionPermanentDetail), findsOneWidget);
    expect(find.text(en.smsImportPermissionPasteInstead), findsOneWidget);
    await tester.tap(find.text(en.smsImportPermissionOpenAppInfo));
    await tester.pumpAndSettle();
    expect(deps.permissions.appInfoOpens, 1);

    deps.permissions.status = SmsPermissionStatus.granted;
    resume(tester);
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportEnableWindowTitle), findsOneWidget);
    expect(deps.permissions.requests, 1);
  });

  testWidgets('restricted: the App info -> Permissions path is offered '
      'after the steps too (spike S4 fallback)', (tester) async {
    deps.permissions.requestResult = SmsPermissionStatus.restrictedBlocked;
    await pumpEnable(tester);
    await continueFromExplain(tester);
    final alt = find.text(en.smsImportRestrictedAltPath);
    expect(alt, findsOneWidget);
    expect(
      tester.getTopLeft(alt).dy,
      greaterThan(tester.getTopLeft(find.text(en.smsImportRestrictedStep4)).dy),
    );
    expect(deps.permissions.requests, 1);
  });

  testWidgets('restricted: numbered steps, App info, Try again, paste', (
    tester,
  ) async {
    deps.permissions.requestResult = SmsPermissionStatus.restrictedBlocked;
    await pumpEnable(tester);
    await continueFromExplain(tester);
    expect(
      find.byKey(const ValueKey('sms_enable_step_restricted')),
      findsOneWidget,
    );
    expect(find.text(en.smsImportRestrictedTitle), findsOneWidget);
    for (final step in [
      en.smsImportRestrictedStep1,
      en.smsImportRestrictedStep2,
      en.smsImportRestrictedStep3,
      en.smsImportRestrictedStep4,
    ]) {
      expect(find.text(step), findsOneWidget);
    }
    expect(find.text(en.smsImportPermissionPasteInstead), findsOneWidget);

    await tester.tap(find.text(en.smsImportPermissionOpenAppInfo));
    await tester.pumpAndSettle();
    expect(deps.permissions.appInfoOpens, 1);
    // Back from App info, still not granted: re-checked, no prompt.
    final checks = deps.permissions.statusChecks;
    deps.permissions.status = SmsPermissionStatus.denied;
    resume(tester);
    await tester.pumpAndSettle();
    expect(deps.permissions.statusChecks, checks + 1);
    expect(deps.permissions.requests, 1);
    expect(
      find.byKey(const ValueKey('sms_enable_step_restricted')),
      findsOneWidget,
    );

    // Step 4: the user taps Try again, which is an explicit request.
    deps.permissions.requestResult = SmsPermissionStatus.granted;
    await tester.tap(find.text(en.smsImportPermissionTryAgain));
    await tester.pumpAndSettle();
    expect(deps.permissions.requests, 2);
    expect(find.text(en.smsImportEnableWindowTitle), findsOneWidget);
  });

  testWidgets('the window choice is scanned; the summary is content-free', (
    tester,
  ) async {
    repository.seed([buildPendingImport(id: 'p-1')]);
    deps.scan.result = Right(
      ScanSummary(
        scanned: 4,
        createdPending: 1,
        needsReview: 1,
        nonTransactional: 3,
        skipped: [
          SkippedEntry(
            reason: SkipReason.notRecognized,
            bankId: 'nbe',
            receivedAt: DateTime(2026, 3, 9),
          ),
        ],
      ),
    );
    await pumpEnable(tester);
    await continueFromExplain(tester);
    await tester.tap(find.byKey(const ValueKey('sms_scan_window_7')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sms_enable_scan')));
    await tester.pumpAndSettle();
    expect(deps.scan.windows, [ScanWindow.days7]);
    expect(deps.settings.settings.scanWindow, ScanWindow.days7);
    expect(find.text(en.smsImportEnableDoneTitle), findsOneWidget);
    expect(find.text(en.smsImportScanFound(4)), findsOneWidget);
    expect(find.text(en.smsImportScanNeedReview(1)), findsOneWidget);
    expect(find.text(en.smsImportScanSkipped(3)), findsOneWidget);
    expect(find.text(en.smsImportScanShowSkipped), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sms_enable_review_now')));
    await tester.pumpAndSettle();
    expect(find.text('review-p-1'), findsOneWidget);
  });

  testWidgets('scanning shows progress and Cancel keeps what was found', (
    tester,
  ) async {
    deps.scan
      ..progress = [8]
      ..gate = Completer<void>();
    await pumpEnable(tester);
    await continueFromExplain(tester);
    await tester.tap(find.byKey(const ValueKey('sms_enable_scan')));
    await tester.pump();
    expect(find.text(en.smsImportScanProgress(8)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sms_scan_cancel')));
    deps.scan.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportScanCancelled), findsOneWidget);
    // Nothing was created: no Review now, only Close.
    expect(find.byKey(const ValueKey('sms_enable_review_now')), findsNothing);
    await tester.tap(find.text(en.smsImportEnableClose));
    await tester.pumpAndSettle();
    expect(find.text('hub-route'), findsOneWidget);
  });

  testWidgets('a failed scan names what was processed and offers Retry', (
    tester,
  ) async {
    deps.scan
      ..progress = [5]
      ..result = const Left(SmsInboxQueryFailure());
    await pumpEnable(tester);
    await continueFromExplain(tester);
    await tester.tap(find.byKey(const ValueKey('sms_enable_scan')));
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportScanFailedTitle), findsOneWidget);
    expect(find.text(en.smsImportScanInterrupted(5)), findsOneWidget);
    deps.scan.result = Right(ScanSummary(scanned: 5));
    await tester.tap(find.text(en.smsImportEnableRetry));
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportEnableDoneTitle), findsOneWidget);
  });

  testWidgets('without the capability: paste only, no permission mention', (
    tester,
  ) async {
    await deps.settings.close();
    deps = HubScanDeps();
    await pumpEnable(tester);
    expect(find.text(en.smsImportEnableUnavailableTitle), findsOneWidget);
    expect(find.text(en.smsImportEnableContinue), findsNothing);
    expect(find.text(en.smsImportPermissionDeniedBanner), findsNothing);
    await tester.tap(find.text(en.smsImportPasteTitle));
    await tester.pumpAndSettle();
    expect(find.text('paste-route'), findsOneWidget);
    expect(deps.permissions.requests, 0);
    expect(deps.permissions.statusChecks, 0);
  });

  for (final locale in smsLocales) {
    for (final theme in smsThemes) {
      testWidgets('explain and restricted render in ${locale.name} / '
          '${theme.name}', (tester) async {
        deps.permissions.requestResult = SmsPermissionStatus.restrictedBlocked;
        await pumpEnable(tester, locale: locale.locale, theme: theme.theme);
        expect(tester.takeException(), isNull);
        expectTapTargets(tester, find.byType(EnableBankMessagesPage));
        await continueFromExplain(tester);
        expect(tester.takeException(), isNull);
        final l10n = lookupAppLocalizations(locale.locale);
        expect(find.text(l10n.smsImportRestrictedStep1), findsOneWidget);
        expectTapTargets(tester, find.byType(EnableBankMessagesPage));
      });
    }
  }

  testWidgets('200% text: the restricted guidance does not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    deps.permissions.requestResult = SmsPermissionStatus.restrictedBlocked;
    await pumpEnable(tester, textScale: 2, locale: const Locale('ar'));
    expect(tester.takeException(), isNull);
    await continueFromExplain(tester);
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('sms_enable_step_restricted')),
      findsOneWidget,
    );
  });
}
