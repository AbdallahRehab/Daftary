import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_capability.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_scan_counts.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/usecases/open_sms_app_info.dart';
import 'package:daftary/features/sms_import/domain/usecases/update_sms_import_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fakes.dart';

// 023 T109: the thin settings and permission use cases.
void main() {
  group('GetSmsPermissionStatus', () {
    test('prompt-free: reports the service status', () async {
      final permissions = FakeSmsPermissionService(
        status: SmsPermissionStatus.revoked,
      );
      final use = GetSmsPermissionStatus(
        GetSmsCapability(FakeSmsInboxGateway()),
        permissions,
      );
      expect(
        await use(),
        const Right<Failure, SmsPermissionStatus>(SmsPermissionStatus.revoked),
      );
      expect(permissions.statusChecks, 1);
      expect(permissions.requests, 0);
    });

    test('capability off: unavailable without a permission call', () async {
      final permissions = FakeSmsPermissionService();
      final use = GetSmsPermissionStatus(
        GetSmsCapability(
          FakeSmsInboxGateway(capability: SmsCapability.unavailable),
        ),
        permissions,
      );
      expect(
        await use(),
        const Right<Failure, SmsPermissionStatus>(
          SmsPermissionStatus.unavailable,
        ),
      );
      expect(permissions.statusChecks, 0);
    });
  });

  test('OpenSmsAppInfo opens App info and prompts nothing', () async {
    final permissions = FakeSmsPermissionService();
    expect(
      await OpenSmsAppInfo(permissions)(),
      const Right<Failure, Unit>(unit),
    );
    expect(permissions.appInfoOpens, 1);
    expect(permissions.requests, 0);
  });

  group('UpdateSmsImportPreferences', () {
    test('writes each change', () async {
      final settings = FakeSmsImportSettingsRepository();
      final update = UpdateSmsImportPreferences(settings);
      await update(const ScanWindowChanged(ScanWindow.days90));
      await update(const CountCashChanged(true));
      await update(const OnboardingDismissed());
      expect(settings.settings.scanWindow, ScanWindow.days90);
      expect(settings.settings.countCashWithdrawals, isTrue);
      expect(settings.settings.onboardingDismissed, isTrue);
      expect(settings.settings.isEnabled, isFalse);
    });
  });

  test('GetScanCounts returns the content-free counters (FR-102)', () async {
    final settings = FakeSmsImportSettingsRepository(
      settings: const SmsImportSettings(
        scannedCount: 9,
        recognizedCount: 5,
        addedCount: 2,
        ignoredCount: 1,
      ),
    );
    expect(
      await GetScanCounts(settings)(),
      const Right<Failure, SmsImportCounts>(
        SmsImportCounts(scanned: 9, recognized: 5, added: 2, ignored: 1),
      ),
    );
  });
}
