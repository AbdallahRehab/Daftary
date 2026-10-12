import 'package:daftary/features/sms_import/data/platform/system_clipboard_reader.dart';
import 'package:daftary/features/sms_import/data/platform/unavailable_shared_text_source.dart';
import 'package:daftary/features/sms_import/data/platform/unavailable_sms_inbox_gateway.dart';
import 'package:daftary/features/sms_import/data/platform/unavailable_sms_permission_service.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_capability.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// T063 — the iOS/macOS ports never touch a channel, and the clipboard is
/// read only when asked.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const sms = MethodChannel('com.daftary.daftary/sms');
  final smsCalls = <MethodCall>[];

  setUp(() {
    smsCalls.clear();
    messenger.setMockMethodCallHandler(sms, (call) async {
      smsCalls.add(call);
      return null;
    });
  });
  tearDown(() {
    messenger
      ..setMockMethodCallHandler(sms, null)
      ..setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('the inbox gateway is unavailable and never queries', () async {
    const gateway = UnavailableSmsInboxGateway();
    expect(await gateway.getCapability(), SmsCapability.unavailable);
    expect((await gateway.getCapability()).available, isFalse);
    final result = await gateway.queryInbox(
      senders: const ['BANKX'],
      afterDate: DateTime(2026),
    );
    expect(
      result.getLeft().toNullable(),
      isA<SmsCapabilityUnavailableFailure>(),
    );
    expect(smsCalls, isEmpty);
  });

  test('the permission service never prompts', () async {
    const service = UnavailableSmsPermissionService();
    expect(
      (await service.getStatus()).getOrElse((_) => SmsPermissionStatus.granted),
      SmsPermissionStatus.unavailable,
    );
    expect(
      (await service.request(
        previouslyRequested: false,
      )).getOrElse((_) => SmsPermissionStatus.granted),
      SmsPermissionStatus.unavailable,
    );
    expect((await service.openAppInfo()).isRight(), isTrue);
    expect(smsCalls, isEmpty);
  });

  test('the shared-text source is empty', () async {
    const source = UnavailableSharedTextSource();
    expect(await source.takeInitial(), isNull);
    expect(await source.stream.toList(), isEmpty);
    expect(smsCalls, isEmpty);
  });

  group('SystemClipboardReader', () {
    final clipboardReads = <MethodCall>[];
    void clipboard(Object? Function() reply) {
      clipboardReads.clear();
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') {
          clipboardReads.add(call);
          return reply();
        }
        return null;
      });
    }

    test('reads plain text only when asked', () async {
      clipboard(() => {'text': 'Synthetic text'});
      const reader = SystemClipboardReader();
      expect(clipboardReads, isEmpty);
      expect(await reader.readText(), 'Synthetic text');
      expect(clipboardReads.single.arguments, Clipboard.kTextPlain);
    });

    test('empty or missing text is null', () async {
      clipboard(() => {'text': ''});
      expect(await const SystemClipboardReader().readText(), isNull);
      clipboard(() => null);
      expect(await const SystemClipboardReader().readText(), isNull);
    });

    test('a platform error reads as empty', () async {
      clipboard(() => throw PlatformException(code: 'denied'));
      expect(await const SystemClipboardReader().readText(), isNull);
    });
  });
}
