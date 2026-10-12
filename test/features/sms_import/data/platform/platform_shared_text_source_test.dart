import 'package:daftary/features/sms_import/data/platform/platform_shared_text_source.dart';
import 'package:daftary/features/sms_import/data/platform/sms_channel_client.dart';
import 'package:daftary/features/sms_import/data/platform/sms_platform_module.dart';
import 'package:daftary/features/sms_import/data/platform/unavailable_shared_text_source.dart';
import 'package:daftary/features/sms_import/domain/services/shared_text_source.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// T095 — `PlatformSharedTextSource` over the shared-text channel
/// (sms-platform-channel §2.5, §2.6, §6). Works in a build without the
/// READ_SMS capability: it never calls an inbox or permission method.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methods = MethodChannel(SmsChannelClient.methodChannelName);
  const events = EventChannel(SmsChannelClient.eventChannelName);
  final calls = <String>[];
  late PlatformSharedTextSource source;

  /// The plugin of a capability-off build: no READ_SMS, the inbox and
  /// permission methods answer `unavailable`, and the cold-start share is
  /// returned once.
  void capabilityOffPlugin({Map<String, Object?>? initial}) {
    var pending = initial;
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'getCapabilities':
          return {'readSmsDeclared': false, 'sdkInt': 34};
        case 'getInitialSharedText':
          final value = pending;
          pending = null;
          return value;
        default:
          throw PlatformException(code: 'unavailable');
      }
    });
  }

  setUp(() {
    calls.clear();
    source = PlatformSharedTextSource(SmsChannelClient());
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockStreamHandler(events, null);
  });

  test('the cold-start share is returned once', () async {
    capabilityOffPlugin(
      initial: {'text': 'Synthetic share', 'truncated': false, 'seq': 1},
    );
    expect(
      await source.takeInitial(),
      const SharedText(text: 'Synthetic share'),
    );
    expect(await source.takeInitial(), isNull);
    expect(calls, ['getInitialSharedText', 'getInitialSharedText']);
  });

  test('works with readSmsDeclared = false and makes no inbox or '
      'permission call', () async {
    capabilityOffPlugin(initial: {'text': 'Synthetic', 'truncated': false});
    messenger.setMockStreamHandler(
      events,
      MockStreamHandler.inline(
        onListen: (arguments, sink) {
          sink
            ..success({'text': 'Warm', 'truncated': false, 'seq': 2})
            ..endOfStream();
        },
      ),
    );
    expect((await source.takeInitial())!.text, 'Synthetic');
    expect((await source.stream.toList()).single.text, 'Warm');
    expect(
      calls.where(
        (m) =>
            m == 'getPermissionState' ||
            m == 'requestPermission' ||
            m == 'queryInbox',
      ),
      isEmpty,
    );
  });

  test('the truncated flag is carried', () async {
    capabilityOffPlugin(
      initial: {'text': 'x' * 10001, 'truncated': true, 'seq': 1},
    );
    final shared = await source.takeInitial();
    expect(shared!.truncated, isTrue);
    expect(shared.text.length, 10001);
  });

  test('a repeated seq is delivered once across both paths', () async {
    capabilityOffPlugin(
      initial: {'text': 'Synthetic', 'truncated': false, 'seq': 5},
    );
    messenger.setMockStreamHandler(
      events,
      MockStreamHandler.inline(
        onListen: (arguments, sink) {
          sink
            ..success({'text': 'Synthetic', 'truncated': false, 'seq': 5})
            ..success({'text': 'Next', 'truncated': false, 'seq': 6})
            ..success({'text': 'Next', 'truncated': false, 'seq': 6})
            ..endOfStream();
        },
      ),
    );
    expect((await source.takeInitial())!.text, 'Synthetic');
    expect((await source.stream.toList()).map((s) => s.text), ['Next']);
  });

  test('malformed or empty payloads are dropped', () async {
    capabilityOffPlugin(initial: {'text': 42, 'truncated': false});
    expect(await source.takeInitial(), isNull);
    messenger.setMockStreamHandler(
      events,
      MockStreamHandler.inline(
        onListen: (arguments, sink) {
          sink
            ..success({'text': '', 'truncated': false})
            ..success({'truncated': true})
            ..success({'text': 'Kept', 'truncated': 'yes'})
            ..endOfStream();
        },
      ),
    );
    final received = await source.stream.toList();
    expect(received, [const SharedText(text: 'Kept')]);
  });

  test('no plugin (MissingPluginException) is "no share"', () async {
    expect(await source.takeInitial(), isNull);
  });

  test('a channel error is "no share", never a throw', () async {
    messenger.setMockMethodCallHandler(methods, (call) async {
      throw PlatformException(code: 'boom', message: 'Synthetic');
    });
    expect(await source.takeInitial(), isNull);
  });

  test('the module selects it on Android only', () {
    final client = SmsChannelClient();
    expect(
      selectForPlatform<SharedTextSource>(
        isAndroid: true,
        android: () => PlatformSharedTextSource(client),
        other: () => const UnavailableSharedTextSource(),
      ),
      isA<PlatformSharedTextSource>(),
    );
    expect(
      selectForPlatform<SharedTextSource>(
        isAndroid: false,
        android: () => PlatformSharedTextSource(client),
        other: () => const UnavailableSharedTextSource(),
      ),
      isA<UnavailableSharedTextSource>(),
    );
  });

  test('toString carries no text', () async {
    capabilityOffPlugin(initial: {'text': 'Secret text', 'truncated': false});
    final shared = await source.takeInitial();
    expect(shared.toString(), isNot(contains('Secret')));
    expect(source.toString(), isNot(contains('Secret')));
  });
}
