import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/data/platform/sms_channel_client.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// T064 — canned replies through the test binary messenger
/// (sms-platform-channel §2-§3). Every value is synthetic.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methods = MethodChannel(SmsChannelClient.methodChannelName);
  const events = EventChannel(SmsChannelClient.eventChannelName);
  final calls = <MethodCall>[];
  late SmsChannelClient client;

  void reply(Object? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(() {
    calls.clear();
    client = SmsChannelClient();
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockStreamHandler(events, null);
  });

  test('channel names match the contract', () {
    expect(SmsChannelClient.methodChannelName, 'com.daftary.daftary/sms');
    expect(
      SmsChannelClient.eventChannelName,
      'com.daftary.daftary/sms/shared_text',
    );
  });

  test('constructing the client makes no call', () {
    reply((_) => null);
    SmsChannelClient();
    expect(calls, isEmpty);
  });

  test('getCapabilities returns the map', () async {
    reply((_) => {'readSmsDeclared': true, 'sdkInt': 35});
    final result = await client.getCapabilities();
    expect(result.getOrElse((_) => {}), {
      'readSmsDeclared': true,
      'sdkInt': 35,
    });
    expect(calls.single.method, 'getCapabilities');
  });

  test('queryInbox shapes the arguments and reads the rows', () async {
    reply(
      (_) => [
        {
          'id': 7,
          'address': 'BANKX',
          'date': 1000,
          'body': 'Synthetic body',
          'truncated': false,
        },
      ],
    );
    final result = await client.queryInbox(
      senders: const ['BANKX'],
      afterDate: 500,
      afterId: 3,
      limit: 200,
    );
    expect(result.getOrElse((_) => []).single['id'], 7);
    expect(calls.single.method, 'queryInbox');
    expect(calls.single.arguments, {
      'senders': ['BANKX'],
      'afterDate': 500,
      'afterId': 3,
      'limit': 200,
    });
  });

  test('an empty page is an empty list', () async {
    reply((_) => <Object?>[]);
    final result = await client.queryInbox(
      senders: const ['BANKX'],
      afterDate: 0,
      limit: 10,
    );
    expect(result.getOrElse((_) => [{}]), isEmpty);
  });

  group('error codes map to typed, content-free failures (§3)', () {
    final cases = <String, Matcher>{
      'unavailable': isA<SmsCapabilityUnavailableFailure>(),
      'permission_denied': isA<SmsPermissionFailure>().having(
        (f) => f.status,
        'status',
        SmsPermissionStatus.denied,
      ),
      'query_failed': isA<SmsInboxQueryFailure>(),
      'invalid_args': isA<SmsInboxQueryFailure>(),
      'no_activity': isA<SmsPermissionFailure>(),
      'request_in_progress': isA<SmsPermissionFailure>(),
      'something_new': isA<UnknownFailure>(),
    };
    for (final entry in cases.entries) {
      test(entry.key, () async {
        reply(
          (_) => throw PlatformException(
            code: entry.key,
            message: 'Body 4111 from BANKX',
            details: 'Synthetic body',
          ),
        );
        final failure = (await client.queryInbox(
          senders: const ['BANKX'],
          afterDate: 0,
          limit: 1,
        )).getLeft().toNullable();
        expect(failure, entry.value);
        expect(failure!.message, isNot(contains('4111')));
        expect(failure.toString(), isNot(contains('BANKX')));
        expect(failure.toString(), isNot(contains('Synthetic')));
      });
    }

    test('a missing plugin is unavailable', () async {
      // No handler registered: MissingPluginException.
      final failure = (await client.getPermissionState())
          .getLeft()
          .toNullable();
      expect(failure, isA<SmsCapabilityUnavailableFailure>());
    });

    test('a malformed reply is a failure, not a crash', () async {
      reply((_) => 'not a map');
      final failure = (await client.getCapabilities()).getLeft().toNullable();
      expect(failure, isA<Failure>());
      reply((_) => ['not a row']);
      final rows = await client.queryInbox(
        senders: const ['BANKX'],
        afterDate: 0,
        limit: 1,
      );
      expect(rows.isLeft(), isTrue);
    });
  });

  test('getInitialSharedText returns null or the share', () async {
    reply((_) => null);
    expect((await client.getInitialSharedText()).getOrElse((_) => {}), isNull);
    reply((_) => {'text': 'Synthetic share', 'truncated': false});
    expect(
      (await client.getInitialSharedText()).getOrElse((_) => null)?['text'],
      'Synthetic share',
    );
  });

  test('shared-text events: maps pass, malformed events are dropped', () async {
    messenger.setMockStreamHandler(
      events,
      MockStreamHandler.inline(
        onListen: (arguments, sink) {
          sink
            ..success({'text': 'Synthetic share', 'truncated': false})
            ..success('garbage')
            ..error(code: 'x', message: 'Synthetic')
            ..endOfStream();
        },
      ),
    );
    final received = await client.sharedTextEvents().toList();
    expect(received, [
      {'text': 'Synthetic share', 'truncated': false},
    ]);
  });
}
