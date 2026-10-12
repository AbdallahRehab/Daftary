import 'dart:io';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_capability.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:daftary/features/sms_import/domain/usecases/request_sms_permission.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fakes.dart';

/// Records whether `permissionRequested` was already persisted when the
/// dialog was shown.
class _OrderCheckingPermissions extends FakeSmsPermissionService {
  _OrderCheckingPermissions(this.settings)
    : super(requestResult: SmsPermissionStatus.denied);

  final FakeSmsImportSettingsRepository settings;
  bool? persistedBeforeDialog;

  @override
  Future<Either<Failure, SmsPermissionStatus>> request({
    required bool previouslyRequested,
  }) {
    persistedBeforeDialog = settings.settings.permissionRequested;
    return super.request(previouslyRequested: previouslyRequested);
  }
}

// 023 T108/T109: RequestSmsPermission is the only caller of request().
void main() {
  late FakeSmsInboxGateway gateway;
  late FakeSmsImportSettingsRepository settings;
  late FakeExternalActivityRunner runner;

  setUp(() {
    gateway = FakeSmsInboxGateway();
    settings = FakeSmsImportSettingsRepository();
    runner = FakeExternalActivityRunner();
  });

  RequestSmsPermission build(FakeSmsPermissionService permissions) =>
      RequestSmsPermission(
        GetSmsCapability(gateway),
        permissions,
        settings,
        runner,
      );

  test('persists permissionRequested BEFORE the dialog, inside the external '
      'activity guard, and returns the status', () async {
    final permissions = _OrderCheckingPermissions(settings);
    final result = await build(permissions)();
    expect(
      result,
      const Right<Failure, SmsPermissionStatus>(SmsPermissionStatus.denied),
    );
    expect(permissions.persistedBeforeDialog, isTrue);
    expect(settings.settings.permissionRequested, isTrue);
    expect(permissions.requests, 1);
    expect(runner.runs, 1);
  });

  test('passes the flag as it was BEFORE this request was persisted '
      '(T107: "never asked" vs "asked before")', () async {
    final permissions = FakeSmsPermissionService(
      requestResult: SmsPermissionStatus.denied,
    );
    final request = build(permissions);
    await request();
    await request();
    expect(permissions.previouslyRequestedLog, [false, true]);
  });

  test(
    'previouslyRequested is true when the flag was already stored',
    () async {
      settings = FakeSmsImportSettingsRepository(
        settings: const SmsImportSettings(permissionRequested: true),
      );
      final permissions = FakeSmsPermissionService();
      await build(permissions)();
      expect(permissions.previouslyRequestedLog, [true]);
    },
  );

  test('refused when the capability is unavailable: no dialog, nothing '
      'persisted', () async {
    gateway.capability = SmsCapability.unavailable;
    final permissions = FakeSmsPermissionService();
    final result = await build(permissions)();
    expect(
      result.getLeft().toNullable(),
      const SmsCapabilityUnavailableFailure(),
    );
    expect(permissions.requests, 0);
    expect(runner.runs, 0);
    expect(settings.settings.permissionRequested, isFalse);
  });

  test('a failed settings write stops before the dialog', () async {
    settings.nextFailure = const CacheFailure('write_failed');
    final permissions = FakeSmsPermissionService();
    final result = await build(permissions)();
    expect(result.isLeft(), isTrue);
    expect(permissions.requests, 0);
  });

  test('a platform failure is passed through', () async {
    final permissions = FakeSmsPermissionService()
      ..nextFailure = const SmsPermissionFailure(SmsPermissionStatus.denied);
    final result = await build(permissions)();
    expect(
      result.getLeft().toNullable(),
      const SmsPermissionFailure(SmsPermissionStatus.denied),
    );
  });

  test('guard: no other lib file calls SmsPermissionService.request() '
      '(FR-002)', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final path = file.path.replaceAll(r'\', '/');
      if (path.endsWith('domain/usecases/request_sms_permission.dart')) {
        continue;
      }
      final source = file.readAsStringSync();
      if (!source.contains('SmsPermissionService')) continue;
      if (RegExp(r'\.request\b(?!Permission)').hasMatch(source)) {
        offenders.add(path);
      }
    }
    expect(offenders, isEmpty);
  });
}
