import 'package:daftary/features/sms_import/data/platform/unavailable_sms_inbox_gateway.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_capability.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

/// `GetSmsCapability` (used by the Home quick action, T098): reads only the
/// gateway and never branches on the platform itself.
void main() {
  test('Android with READ_SMS declared is available', () async {
    final gateway = FakeSmsInboxGateway();
    final capability = await GetSmsCapability(gateway)();
    expect(capability.available, isTrue);
    expect(gateway.calls, isEmpty, reason: 'no inbox read');
  });

  test('Android without READ_SMS is unavailable, shares still work', () async {
    final gateway = FakeSmsInboxGateway(
      capability: const SmsCapability(readSmsDeclared: false, isAndroid: true),
    );
    final capability = await GetSmsCapability(gateway)();
    expect(capability.available, isFalse);
    expect(capability.canReceiveShares, isTrue);
  });

  test('iOS and macOS (unavailable adapter) are unavailable', () async {
    final capability = await GetSmsCapability(
      const UnavailableSmsInboxGateway(),
    )();
    expect(capability.available, isFalse);
  });
}
