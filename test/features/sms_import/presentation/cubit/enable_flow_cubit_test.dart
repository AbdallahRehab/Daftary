import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/presentation/cubit/enable_flow_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/enable_flow_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';
import '../../helpers/scan_presentation.dart';

/// T118 — `EnableFlowCubit`: explanation before any prompt (FR-005), no
/// prompt on open or resume (FR-002, FR-012), the classified outcomes, the
/// App info return (FR-072), the window and the scan (FR-006, FR-007).
void main() {
  late HubScanDeps deps;
  late FakeExternalActivityRunner runner;
  late EnableFlowCubit cubit;

  EnableFlowCubit build({FakeSmsImportRepository? repository}) =>
      buildEnableFlowCubit(deps, runner: runner, repository: repository);

  setUp(() {
    deps = HubScanDeps(capability: true);
    runner = FakeExternalActivityRunner();
    cubit = build();
  });
  tearDown(() async {
    await cubit.close();
    await deps.settings.close();
  });

  test('open shows the explanation and never prompts', () async {
    await cubit.open();
    expect(cubit.state.step, EnableFlowStep.explain);
    expect(deps.permissions.requests, 0);
  });

  test('open without the capability shows the paste-only step', () async {
    deps = HubScanDeps();
    await cubit.close();
    cubit = build();
    await cubit.open();
    expect(cubit.state.step, EnableFlowStep.unavailable);
    expect(deps.permissions.requests, 0);
    expect(deps.permissions.statusChecks, 0);
  });

  test('nothing but Continue on the explanation can prompt', () async {
    await cubit.open();
    // Try again and resume are no-ops before the explanation.
    await cubit.tryAgain();
    await cubit.onResumed();
    await cubit.startScan();
    expect(deps.permissions.requests, 0);
    expect(deps.scan.calls, 0);

    await cubit.acknowledgeAndContinue();
    expect(deps.permissions.requests, 1);
    // Inside the external-activity runner, so App Lock ignores it.
    expect(runner.runs, 1);
  });

  test(
    'granted enables with the default window and shows the window step',
    () async {
      await cubit.open();
      await cubit.acknowledgeAndContinue();
      expect(cubit.state.step, EnableFlowStep.window);
      expect(cubit.state.window, ScanWindow.days30);
      expect(deps.settings.settings.isEnabled, isTrue);
      expect(deps.settings.settings.permissionRequested, isTrue);
    },
  );

  test('already granted enables without a second prompt', () async {
    deps.permissions.status = SmsPermissionStatus.granted;
    await cubit.open();
    await cubit.acknowledgeAndContinue();
    expect(cubit.state.step, EnableFlowStep.window);
    expect(deps.permissions.requests, 0);
  });

  for (final (result, step) in [
    (SmsPermissionStatus.denied, EnableFlowStep.denied),
    (SmsPermissionStatus.permanentlyDenied, EnableFlowStep.permanentlyDenied),
    (SmsPermissionStatus.restrictedBlocked, EnableFlowStep.restricted),
  ]) {
    test(
      '${result.name} leaves the import off and shows ${step.name}',
      () async {
        deps.permissions.requestResult = result;
        await cubit.open();
        await cubit.acknowledgeAndContinue();
        expect(cubit.state.step, step);
        expect(deps.settings.settings.isEnabled, isFalse);
      },
    );
  }

  test('denied offers Try again once, never on its own', () async {
    deps.permissions.requestResult = SmsPermissionStatus.denied;
    await cubit.open();
    await cubit.acknowledgeAndContinue();
    expect(cubit.state.canTryAgain, isTrue);
    // Resuming the app does not re-prompt (FR-012).
    await cubit.onResumed();
    expect(deps.permissions.requests, 1);

    await cubit.tryAgain();
    expect(deps.permissions.requests, 2);
    expect(cubit.state.step, EnableFlowStep.denied);
    expect(cubit.state.canTryAgain, isFalse);
    await cubit.tryAgain();
    expect(deps.permissions.requests, 2);
  });

  test('Try again after a denial can still be granted', () async {
    deps.permissions.requestResult = SmsPermissionStatus.denied;
    await cubit.open();
    await cubit.acknowledgeAndContinue();
    deps.permissions.requestResult = SmsPermissionStatus.granted;
    await cubit.tryAgain();
    expect(cubit.state.step, EnableFlowStep.window);
  });

  test('restricted: App info, then a resume while still blocked re-checks '
      'without a prompt and keeps Try again', () async {
    deps.permissions.requestResult = SmsPermissionStatus.restrictedBlocked;
    await cubit.open();
    await cubit.acknowledgeAndContinue();
    await cubit.openAppInfo();
    expect(deps.permissions.appInfoOpens, 1);
    final checks = deps.permissions.statusChecks;

    deps.permissions.status = SmsPermissionStatus.denied;
    await cubit.onResumed();
    expect(deps.permissions.statusChecks, checks + 1);
    expect(deps.permissions.requests, 1);
    expect(cubit.state.step, EnableFlowStep.restricted);
    expect(cubit.state.canTryAgain, isTrue);

    // The user follows step 4 and taps Try again.
    deps.permissions.requestResult = SmsPermissionStatus.granted;
    await cubit.tryAgain();
    expect(deps.permissions.requests, 2);
    expect(cubit.state.step, EnableFlowStep.window);
  });

  test('permanently denied: granted in App info advances on resume without '
      'a prompt (FR-072)', () async {
    deps.permissions.requestResult = SmsPermissionStatus.permanentlyDenied;
    await cubit.open();
    await cubit.acknowledgeAndContinue();
    await cubit.openAppInfo();
    deps.permissions.status = SmsPermissionStatus.granted;
    await cubit.onResumed();
    expect(cubit.state.step, EnableFlowStep.window);
    expect(deps.permissions.requests, 1);
    expect(deps.settings.settings.isEnabled, isTrue);
  });

  test('a resume without App info does not even re-check', () async {
    deps.permissions.requestResult = SmsPermissionStatus.permanentlyDenied;
    await cubit.open();
    await cubit.acknowledgeAndContinue();
    final checks = deps.permissions.statusChecks;
    await cubit.onResumed();
    expect(deps.permissions.statusChecks, checks);
  });

  test('a failed enable shows the error step; Retry asks again', () async {
    deps.permissions.nextFailure = const CacheFailure('x');
    await cubit.open();
    await cubit.acknowledgeAndContinue();
    expect(cubit.state.step, EnableFlowStep.error);
    expect(cubit.state.failedWhileScanning, isFalse);
    await cubit.retry();
    expect(cubit.state.step, EnableFlowStep.window);
  });

  group('window and scan', () {
    Future<void> toWindow() async {
      await cubit.open();
      await cubit.acknowledgeAndContinue();
      expect(cubit.state.step, EnableFlowStep.window);
    }

    test('the chosen window is saved and scanned', () async {
      await toWindow();
      cubit.selectWindow(ScanWindow.days90);
      deps.scan.result = Right(
        ScanSummary(scanned: 4, createdPending: 2, ready: 1, needsReview: 1),
      );
      await cubit.startScan();
      expect(deps.scan.windows, [ScanWindow.days90]);
      expect(deps.settings.settings.scanWindow, ScanWindow.days90);
      expect(cubit.state.step, EnableFlowStep.done);
      expect(cubit.state.summary!.createdPending, 2);
    });

    test('progress is reported while scanning', () async {
      await toWindow();
      final states = <EnableFlowState>[];
      final sub = cubit.stream.listen(states.add);
      deps.scan.progress = const [1, 2, 3];
      await cubit.startScan();
      await pumpEventQueue();
      await sub.cancel();
      expect(
        states
            .where((s) => s.step == EnableFlowStep.scanning)
            .map((s) => s.processed),
        containsAllInOrder([0, 1, 2, 3]),
      );
    });

    test('cancel ends the scan with a cancelled summary (FR-007)', () async {
      await toWindow();
      deps.scan.gate = Completer<void>();
      final running = cubit.startScan();
      await pumpEventQueue();
      expect(cubit.state.step, EnableFlowStep.scanning);
      cubit.cancelScan();
      deps.scan.gate!.complete();
      await running;
      expect(deps.scan.lastToken!.isCancelled, isTrue);
      expect(cubit.state.step, EnableFlowStep.done);
      expect(cubit.state.summary!.cancelled, isTrue);
    });

    test(
      'a scan failure keeps the processed count and can be retried',
      () async {
        await toWindow();
        deps.scan
          ..progress = const [5]
          ..result = const Left(SmsInboxQueryFailure());
        await cubit.startScan();
        expect(cubit.state.step, EnableFlowStep.error);
        expect(cubit.state.failedWhileScanning, isTrue);
        expect(cubit.state.processed, 5);
        deps.scan.result = Right(ScanSummary(scanned: 5));
        await cubit.retry();
        expect(cubit.state.step, EnableFlowStep.done);
        expect(deps.scan.calls, 2);
      },
    );

    test('closing the page cancels a running scan', () async {
      await toWindow();
      deps.scan.gate = Completer<void>();
      unawaited(cubit.startScan());
      await pumpEventQueue();
      await cubit.close();
      expect(deps.scan.lastToken!.isCancelled, isTrue);
      deps.scan.gate!.complete();
    });
  });

  test('firstPendingId is the first item in review order, or null', () async {
    final repository = FakeSmsImportRepository();
    await cubit.close();
    cubit = build(repository: repository);
    expect(await cubit.firstPendingId(), isNull);
    repository.seed([buildPendingImport(id: 'p-1')]);
    expect(await cubit.firstPendingId(), 'p-1');
    await repository.close();
  });

  test('the state prints no content', () {
    final state = EnableFlowState(
      step: EnableFlowStep.done,
      summary: ScanSummary(
        scanned: 2,
        skipped: [
          SkippedEntry(
            reason: SkipReason.noAmount,
            bankId: 'nbe',
            receivedAt: DateTime(2026, 3, 4),
          ),
        ],
      ),
    );
    expect(state.toString(), isNot(contains('nbe')));
  });
}
