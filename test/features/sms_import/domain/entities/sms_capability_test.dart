import 'package:daftary/features/sms_import/domain/entities/sms_capability.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// 023 T024: `available == readSmsDeclared && isAndroid`.
void main() {
  test('available only when READ_SMS is declared on Android', () {
    for (final declared in [false, true]) {
      for (final android in [false, true]) {
        final capability = SmsCapability(
          readSmsDeclared: declared,
          isAndroid: android,
        );
        expect(capability.available, declared && android);
        expect(capability.canReceiveShares, android);
      }
    }
  });

  test('the unavailable constant', () {
    expect(SmsCapability.unavailable.available, isFalse);
    expect(SmsCapability.unavailable.canReceiveShares, isFalse);
  });

  test('equality', () {
    expect(
      const SmsCapability(readSmsDeclared: true, isAndroid: true),
      const SmsCapability(readSmsDeclared: true, isAndroid: true),
    );
  });

  test('permission statuses', () {
    expect(SmsPermissionStatus.values, [
      SmsPermissionStatus.granted,
      SmsPermissionStatus.denied,
      SmsPermissionStatus.permanentlyDenied,
      SmsPermissionStatus.restrictedBlocked,
      SmsPermissionStatus.revoked,
      SmsPermissionStatus.unavailable,
    ]);
  });

  test('install source from the wire; unknown -> unknown', () {
    expect(SmsInstallSource.fromWire('store'), SmsInstallSource.store);
    expect(SmsInstallSource.fromWire('notStore'), SmsInstallSource.notStore);
    expect(SmsInstallSource.fromWire('unknown'), SmsInstallSource.unknown);
    expect(SmsInstallSource.fromWire(null), SmsInstallSource.unknown);
    expect(SmsInstallSource.fromWire('play'), SmsInstallSource.unknown);
  });
}
