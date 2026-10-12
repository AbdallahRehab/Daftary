import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_settings_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_settings_state.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';
import '../../helpers/scan_presentation.dart';

/// T141 (revocation on resume) and T143 — the permission is revoked in
/// system settings while the app is in the background. On resume the hub
/// and Settings re-read the status (prompt-free): the "permission off"
/// state shows, pending items stay reviewable, scanning stops being
/// offered, and nothing ever re-prompts (FR-012, FR-070, US8-2).
void main() {
  late FixedClock clock;
  late FakeSmsImportRepository repository;
  late HubScanDeps deps;

  setUp(() {
    clock = FixedClock(DateTime(2026, 4, 10, 12));
    repository = FakeSmsImportRepository(clock: clock);
    deps = HubScanDeps(
      capability: true,
      settings: FakeSmsImportSettingsRepository(
        settings: const SmsImportSettings(isEnabled: true),
      ),
    );
    deps.permissions.status = SmsPermissionStatus.granted;
  });
  tearDown(() async {
    await deps.settings.close();
    await repository.close();
  });

  group('hub (BankMessagesCubit)', () {
    late BankMessagesCubit cubit;
    tearDown(() => cubit.close());

    test('revoked on resume: banner, pending items kept, no scan, no '
        'prompt', () async {
      repository.seed([
        buildPendingImport(createdAt: clock.now()),
        buildPendingImport(
          id: 'pending-2',
          fingerprint: 'fp-2',
          createdAt: clock.now(),
        ),
      ]);
      cubit = buildBankMessagesCubit(repository, clock, deps: deps);
      await cubit.open();
      expect(cubit.state.canScan, isTrue);
      expect(cubit.state.bannerStatus, isNull);
      final checksBefore = deps.permissions.statusChecks;

      // Revoked in system settings while backgrounded; the page's
      // AppLifecycleListener calls this on resume.
      deps.permissions.status = SmsPermissionStatus.revoked;
      await cubit.refreshScanContext();

      expect(deps.permissions.statusChecks, greaterThan(checksBefore));
      expect(cubit.state.permission, SmsPermissionStatus.revoked);
      expect(cubit.state.bannerStatus, SmsPermissionStatus.revoked);
      expect(cubit.state.canScan, isFalse);
      expect(cubit.state.status, BankMessagesStatus.ready);
      expect(cubit.state.items.map((i) => i.id), ['pending-1', 'pending-2']);
      expect(repository.rows.values.every((r) => r.isPending), isTrue);

      // Scan now is not run, and nothing prompts, however often it resumes.
      await cubit.scan();
      await cubit.refreshScanContext();
      await cubit.refreshScanContext();
      expect(deps.scan.calls, 0);
      expect(deps.permissions.requests, 0);
      expect(deps.settings.settings.permissionRequested, isFalse);
    });

    test('granted again in App info: the banner goes away on the next '
        'resume, still without a prompt', () async {
      deps.permissions.status = SmsPermissionStatus.revoked;
      cubit = buildBankMessagesCubit(repository, clock, deps: deps);
      await cubit.open();
      expect(cubit.state.bannerStatus, SmsPermissionStatus.revoked);
      deps.permissions.status = SmsPermissionStatus.granted;
      await cubit.refreshScanContext();
      expect(cubit.state.bannerStatus, isNull);
      expect(cubit.state.canScan, isTrue);
      expect(deps.permissions.requests, 0);
    });
  });

  group('Settings (BankMessagesSettingsCubit)', () {
    late BankMessagesSettingsCubit cubit;
    tearDown(() => cubit.close());

    test('revoked on resume: "Permission off", the scan rows hidden, the '
        'feature left on and no prompt', () async {
      cubit = buildSettingsCubit(deps);
      await cubit.open();
      expect(cubit.state.statusLabel, SmsImportStatusLabel.on);
      expect(cubit.state.showScanSection, isTrue);

      deps.permissions.status = SmsPermissionStatus.revoked;
      await cubit.refreshPermission();

      expect(cubit.state.permission, SmsPermissionStatus.revoked);
      expect(cubit.state.statusLabel, SmsImportStatusLabel.permissionOff);
      expect(cubit.state.showScanSection, isFalse);
      // Revocation is not a Turn off: the user's choice and the pending
      // items are untouched (FR-012).
      expect(cubit.state.isEnabled, isTrue);
      expect(deps.settings.settings.isEnabled, isTrue);
      expect(deps.permissions.requests, 0);
    });
  });
}
