import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_capability.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/usecases/enable_sms_import.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/usecases/request_sms_permission.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fakes.dart';

// 023 T108/T109: EnableSmsImport (explanation precondition, request once,
// enable only on granted, never scans).
void main() {
  late FakeSmsInboxGateway gateway;
  late FakeSmsPermissionService permissions;
  late FakeSmsImportSettingsRepository settings;
  late FakeExternalActivityRunner runner;
  late EnableSmsImport enable;

  setUp(() {
    gateway = FakeSmsInboxGateway();
    permissions = FakeSmsPermissionService();
    settings = FakeSmsImportSettingsRepository();
    runner = FakeExternalActivityRunner();
    final capability = GetSmsCapability(gateway);
    enable = EnableSmsImport(
      GetSmsPermissionStatus(capability, permissions),
      RequestSmsPermission(capability, permissions, settings, runner),
      settings,
    );
  });

  Future<Either<Failure, EnableResult>> run({
    ScanWindow window = ScanWindow.days90,
    bool acknowledged = true,
  }) => enable(window: window, explanationAcknowledged: acknowledged);

  test('without the acknowledged explanation: ValidationFailure, no prompt, '
      'nothing written (FR-005)', () async {
    final result = await run(acknowledged: false);
    expect(result.getLeft().toNullable(), EnableSmsImport.explanationRequired);
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    expect(permissions.requests, 0);
    expect(permissions.statusChecks, 0);
    expect(settings.settings.permissionRequested, isFalse);
    expect(settings.settings.isEnabled, isFalse);
  });

  test('granted: persists permissionRequested, sets the window and '
      'enables', () async {
    permissions.requestResult = SmsPermissionStatus.granted;
    final result = await run(window: ScanWindow.days7);
    expect(
      result,
      const Right<Failure, EnableResult>(
        EnableResult(status: SmsPermissionStatus.granted, enabled: true),
      ),
    );
    expect(permissions.requests, 1);
    expect(runner.runs, 1);
    expect(settings.settings.permissionRequested, isTrue);
    expect(settings.settings.isEnabled, isTrue);
    expect(settings.settings.scanWindow, ScanWindow.days7);
  });

  for (final status in [
    SmsPermissionStatus.denied,
    SmsPermissionStatus.permanentlyDenied,
    SmsPermissionStatus.restrictedBlocked,
  ]) {
    test('$status: stays off, returns the status for guidance, asked '
        'once', () async {
      permissions.requestResult = status;
      final result = await run();
      expect(
        result,
        Right<Failure, EnableResult>(
          EnableResult(status: status, enabled: false),
        ),
      );
      expect(permissions.requests, 1);
      expect(settings.settings.permissionRequested, isTrue);
      expect(settings.settings.isEnabled, isFalse);
      expect(settings.settings.scanWindow, ScanWindow.days30);
    });
  }

  test('already granted: enables without showing the dialog again', () async {
    permissions.status = SmsPermissionStatus.granted;
    final result = await run();
    expect(result.getRight().toNullable()?.enabled, isTrue);
    expect(permissions.requests, 0);
    expect(runner.runs, 0);
  });

  test('capability unavailable: refused, no prompt', () async {
    gateway.capability = SmsCapability.unavailable;
    final result = await run();
    expect(
      result.getLeft().toNullable(),
      const SmsCapabilityUnavailableFailure(),
    );
    expect(permissions.requests, 0);
    expect(settings.settings.isEnabled, isFalse);
  });

  test('never starts a scan', () async {
    permissions.requestResult = SmsPermissionStatus.granted;
    await run();
    expect(gateway.calls, isEmpty);
  });
}
