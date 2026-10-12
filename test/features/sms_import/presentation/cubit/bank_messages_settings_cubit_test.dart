import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_home_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_settings_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fakes.dart';
import '../../helpers/scan_presentation.dart';

/// T118 — `BankMessagesSettingsCubit` (ui-contract §3.1) and the Home
/// onboarding cubit (T122). Neither ever prompts.
void main() {
  group('BankMessagesSettingsCubit', () {
    late HubScanDeps deps;
    late BankMessagesSettingsCubit cubit;

    void build({bool capability = true, SmsImportSettings? settings}) {
      deps = HubScanDeps(
        capability: capability,
        settings: FakeSmsImportSettingsRepository(
          settings: settings ?? const SmsImportSettings(),
        ),
      );
      cubit = buildSettingsCubit(deps);
    }

    tearDown(() async {
      await cubit.close();
      await deps.settings.close();
    });

    test(
      'loads capability, status, settings and counts; never prompts',
      () async {
        build(
          settings: const SmsImportSettings(
            isEnabled: true,
            scannedCount: 7,
            addedCount: 2,
          ),
        );
        deps.permissions.status = SmsPermissionStatus.granted;
        await cubit.open();
        final s = cubit.state;
        expect(s.status, BankMessagesSettingsStatus.ready);
        expect(s.capabilityAvailable, isTrue);
        expect(s.permission, SmsPermissionStatus.granted);
        expect(s.counts.scanned, 7);
        expect(s.counts.added, 2);
        expect(s.statusLabel, SmsImportStatusLabel.on);
        expect(s.showScanSection, isTrue);
        expect(deps.permissions.requests, 0);
      },
    );

    test('without the capability no permission call is made and the scan '
        'section is hidden', () async {
      build(capability: false);
      await cubit.open();
      expect(cubit.state.capabilityAvailable, isFalse);
      expect(cubit.state.permission, SmsPermissionStatus.unavailable);
      expect(cubit.state.showScanSection, isFalse);
      expect(deps.permissions.statusChecks, 0);
      expect(deps.permissions.requests, 0);
    });

    test('status labels', () async {
      build(settings: const SmsImportSettings(isEnabled: true));
      deps.permissions.status = SmsPermissionStatus.revoked;
      await cubit.open();
      expect(cubit.state.statusLabel, SmsImportStatusLabel.permissionOff);
      expect(cubit.state.showScanSection, isFalse);

      deps.permissions.status = SmsPermissionStatus.restrictedBlocked;
      await cubit.refreshPermission();
      expect(cubit.state.statusLabel, SmsImportStatusLabel.blocked);

      await deps.settings.setEnabled(false);
      await pumpEventQueue();
      deps.permissions.status = SmsPermissionStatus.denied;
      await cubit.refreshPermission();
      expect(cubit.state.statusLabel, SmsImportStatusLabel.off);
    });

    test(
      'window and cash toggle write through the preferences use case',
      () async {
        build(settings: const SmsImportSettings(isEnabled: true));
        await cubit.open();
        await cubit.setWindow(ScanWindow.days7);
        await cubit.setCountCashWithdrawals(true);
        await pumpEventQueue();
        expect(deps.settings.settings.scanWindow, ScanWindow.days7);
        expect(deps.settings.settings.countCashWithdrawals, isTrue);
        expect(cubit.state.settings.scanWindow, ScanWindow.days7);
        expect(cubit.state.submitting, isNull);
      },
    );

    test('a failed write raises saveFailed once, then clears', () async {
      build();
      await cubit.open();
      deps.settings.nextFailure = const CacheFailure('x');
      await cubit.setCountCashWithdrawals(true);
      expect(cubit.state.saveFailed, isTrue);
      expect(cubit.state.submitting, isNull);
      cubit.saveFailureShown();
      expect(cubit.state.saveFailed, isFalse);
    });

    test('a write while another runs is ignored (double tap)', () async {
      build();
      await cubit.open();
      final first = cubit.setWindow(ScanWindow.days7);
      final second = cubit.setWindow(ScanWindow.days90);
      await Future.wait([first, second]);
      expect(deps.settings.settings.scanWindow, ScanWindow.days7);
    });

    test('Open App info opens it and prompts nothing', () async {
      build();
      await cubit.open();
      await cubit.openAppInfo();
      expect(deps.permissions.appInfoOpens, 1);
      expect(deps.permissions.requests, 0);
    });

    test('a settings read failure shows the error state', () async {
      build();
      final failing = _FailingSettings();
      await cubit.close();
      cubit = buildSettingsCubit(
        HubScanDeps(capability: true, settings: failing),
      );
      await cubit.open();
      expect(cubit.state.status, BankMessagesSettingsStatus.error);
      await failing.close();
    });
  });

  group('BankMessagesHomeCubit', () {
    late HubScanDeps deps;
    late BankMessagesHomeCubit cubit;

    setUp(() {
      deps = HubScanDeps(capability: true);
      cubit = buildHomeCubit(deps);
    });
    tearDown(() async {
      await cubit.close();
      await deps.settings.close();
    });

    test('onboarding shows while off and not dismissed', () async {
      cubit.open();
      await pumpEventQueue();
      expect(cubit.state.showOnboarding, isTrue);
      await deps.settings.setEnabled(true);
      await pumpEventQueue();
      expect(cubit.state.showOnboarding, isFalse);
    });

    test('Dismiss is permanent', () async {
      cubit.open();
      await pumpEventQueue();
      await cubit.dismiss();
      await pumpEventQueue();
      expect(deps.settings.settings.onboardingDismissed, isTrue);
      expect(cubit.state.showOnboarding, isFalse);
      expect(deps.permissions.requests, 0);
    });

    test('a failed dismiss keeps the card', () async {
      cubit.open();
      await pumpEventQueue();
      deps.settings.nextFailure = const CacheFailure('x');
      await cubit.dismiss();
      expect(cubit.state.showOnboarding, isTrue);
      expect(cubit.state.dismissing, isFalse);
    });
  });
}

/// Settings whose stream fails.
class _FailingSettings extends FakeSmsImportSettingsRepository {
  @override
  Stream<Either<Failure, SmsImportSettings>> watchSettings() =>
      Stream.value(const Left(CacheFailure('sms_settings_read_failed')));
}
