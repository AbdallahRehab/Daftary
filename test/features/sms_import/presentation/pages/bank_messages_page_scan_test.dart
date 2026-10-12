import 'dart:async';

import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/presentation/pages/bank_messages_page.dart';
import 'package:daftary/features/sms_import/presentation/widgets/sms_import_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';
import '../../helpers/scan_presentation.dart';
import '../../helpers/widget_harness.dart';

/// T120 — the hub's scan state on `BankMessagesPage`: Scan now, progress
/// with Cancel, the content-free summary and its in-memory Skipped list,
/// the permission banner and the Turn on card. Without the capability the
/// page is the paste-only list. Every value is synthetic.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  late FixedClock clock;
  late FakeSmsImportRepository repository;
  late HubScanDeps deps;

  setUp(() {
    clock = FixedClock(DateTime(2026, 3, 10, 12));
    repository = FakeSmsImportRepository(clock: clock);
  });
  tearDown(() async {
    await repository.close();
    await deps.settings.close();
  });

  Future<void> pumpHub(
    WidgetTester tester, {
    bool capability = true,
    bool enabled = true,
    SmsPermissionStatus permission = SmsPermissionStatus.granted,
    bool startScan = false,
    Locale locale = const Locale('en'),
    ThemeData? theme,
    bool settle = true,
  }) async {
    deps = HubScanDeps(
      capability: capability,
      settings: FakeSmsImportSettingsRepository(
        settings: SmsImportSettings(isEnabled: enabled),
      ),
    );
    deps.permissions.status = permission;
    await pumpSmsPage(
      tester,
      BankMessagesPage(
        cubit: buildBankMessagesCubit(repository, clock, deps: deps),
        startScan: startScan,
      ),
      locale: locale,
      theme: theme,
      settle: settle,
    );
  }

  ScanSummary sampleSummary() => ScanSummary(
    scanned: 6,
    recognized: 4,
    createdPending: 3,
    ready: 2,
    needsReview: 1,
    nonTransactional: 1,
    unreadable: 1,
    skipped: [
      SkippedEntry(
        reason: SkipReason.notRecognized,
        bankId: 'nbe',
        receivedAt: DateTime(2026, 3, 9),
      ),
      const SkippedEntry(reason: SkipReason.noAmount, bankId: 'cib'),
    ],
  );

  testWidgets('without the capability: paste-only, no scan or permission UI', (
    tester,
  ) async {
    await pumpHub(tester, capability: false);
    expect(find.text(en.smsImportScanNow), findsNothing);
    expect(find.byKey(const ValueKey('bank_messages_turn_on')), findsNothing);
    expect(find.text(en.smsImportPermissionDeniedBanner), findsNothing);
    expect(find.text(en.smsImportPasteTitle), findsOneWidget);
    expect(deps.permissions.statusChecks, 0);
  });

  testWidgets('Scan now shows the summary; Skipped lists bank, date, reason', (
    tester,
  ) async {
    await pumpHub(tester);
    deps.scan.result = Right(sampleSummary());
    await tester.tap(find.text(en.smsImportScanNow));
    await tester.pumpAndSettle();
    expect(deps.scan.calls, 1);
    expect(find.text(en.smsImportScanFound(6)), findsOneWidget);
    expect(find.text(en.smsImportScanReady(2)), findsOneWidget);
    expect(find.text(en.smsImportScanNeedReview(1)), findsOneWidget);
    expect(find.text(en.smsImportScanSkipped(1)), findsOneWidget);
    expect(find.text(en.smsImportScanUnreadable(1)), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sms_scan_show_skipped')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sms_skipped_list')), findsOneWidget);
    expect(find.text(en.smsImportScanSkippedNote), findsOneWidget);
    expect(find.text(SmsImportLabels.bank(en, 'nbe')), findsOneWidget);
    expect(
      find.textContaining(en.smsImportScanSkipReason('notRecognized')),
      findsOneWidget,
    );
    expect(find.textContaining(en.smsImportScanSkippedNoDate), findsOneWidget);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('the summary can be dismissed and is gone for good', (
    tester,
  ) async {
    await pumpHub(tester);
    deps.scan.result = Right(sampleSummary());
    await tester.tap(find.text(en.smsImportScanNow));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(en.smsImportScanDismiss));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sms_scan_summary_card')), findsNothing);
  });

  testWidgets('a running scan shows progress and Cancel; the list stays', (
    tester,
  ) async {
    repository.seed([buildPendingImport()]);
    await pumpHub(tester);
    deps.scan
      ..progress = [12]
      ..gate = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('bank_messages_scan_now')));
    await tester.pump();
    expect(find.byKey(const ValueKey('sms_scan_progress')), findsOneWidget);
    expect(find.text(en.smsImportScanProgress(12)), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pending_import_card_pending-1')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('sms_scan_cancel')));
    expect(deps.scan.lastToken!.isCancelled, isTrue);
    deps.scan.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportScanCancelled), findsOneWidget);
  });

  testWidgets('a failed scan says what was processed and offers Retry', (
    tester,
  ) async {
    await pumpHub(tester);
    deps.scan
      ..progress = [3]
      ..result = const Left(SmsInboxQueryFailure());
    await tester.tap(find.text(en.smsImportScanNow));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('bank_messages_scan_failure')),
      findsOneWidget,
    );
    expect(find.text(en.smsImportScanInterrupted(3)), findsOneWidget);
    expect(find.text(en.smsImportScanRetry), findsOneWidget);
  });

  testWidgets('revoked: the banner keeps pending items and offers paste', (
    tester,
  ) async {
    repository.seed([buildPendingImport()]);
    await pumpHub(tester, permission: SmsPermissionStatus.revoked);
    expect(find.text(en.smsImportPermissionRevokedBanner), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pending_import_card_pending-1')),
      findsOneWidget,
    );
    expect(find.text(en.smsImportScanNow), findsNothing);
    await tester.tap(find.text(en.smsImportPermissionPasteInstead));
    await tester.pumpAndSettle();
    expect(find.text('paste-route'), findsOneWidget);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('Turn on again opens the enable flow, never a prompt', (
    tester,
  ) async {
    await pumpHub(tester, permission: SmsPermissionStatus.revoked);
    await tester.tap(find.text(en.smsImportPermissionTurnOnAgain));
    await tester.pumpAndSettle();
    expect(find.text('enable-route'), findsOneWidget);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('off: the Turn on card opens the enable flow', (tester) async {
    await pumpHub(
      tester,
      enabled: false,
      permission: SmsPermissionStatus.denied,
    );
    expect(find.byKey(const ValueKey('bank_messages_turn_on')), findsOneWidget);
    await tester.tap(find.text(en.smsImportScanTurnOn));
    await tester.pumpAndSettle();
    expect(find.text('enable-route'), findsOneWidget);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('a resume re-checks the permission without prompting', (
    tester,
  ) async {
    await pumpHub(tester);
    final checks = deps.permissions.statusChecks;
    deps.permissions.status = SmsPermissionStatus.revoked;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(deps.permissions.statusChecks, checks + 1);
    expect(find.text(en.smsImportPermissionRevokedBanner), findsOneWidget);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('Settings "Scan now" (startScan) scans once on open', (
    tester,
  ) async {
    await pumpHub(tester, startScan: true);
    expect(deps.scan.calls, 1);
  });

  testWidgets('startScan does nothing when the scan is not allowed', (
    tester,
  ) async {
    await pumpHub(
      tester,
      startScan: true,
      permission: SmsPermissionStatus.denied,
    );
    expect(deps.scan.calls, 0);
    expect(deps.permissions.requests, 0);
  });

  for (final locale in smsLocales) {
    for (final theme in smsThemes) {
      testWidgets('scan summary renders in ${locale.name} / ${theme.name}', (
        tester,
      ) async {
        await pumpHub(tester, locale: locale.locale, theme: theme.theme);
        deps.scan.result = Right(sampleSummary());
        await tester.tap(
          find.text(lookupAppLocalizations(locale.locale).smsImportScanNow),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('sms_scan_summary_card')),
          findsOneWidget,
        );
        expectTapTargets(
          tester,
          find.byKey(const ValueKey('sms_scan_summary_card')),
        );
      });
    }
  }
}
