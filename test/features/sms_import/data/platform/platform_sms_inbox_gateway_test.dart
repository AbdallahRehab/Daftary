import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/data/platform/platform_sms_inbox_gateway.dart';
import 'package:daftary/features/sms_import/data/platform/sms_channel_client.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_capability.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/services/sms_inbox_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// 023 T107: the channel contract of `PlatformSmsInboxGateway`
/// (sms-platform-channel §2.1, §2.4, §6). The exact arguments sent are
/// recorded and canned replies are fed back. Every value is synthetic.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methods = MethodChannel(SmsChannelClient.methodChannelName);
  final calls = <MethodCall>[];
  late PlatformSmsInboxGateway gateway;

  /// Replies to `getCapabilities` with [declared] and to `queryInbox` with
  /// [inbox].
  void reply({bool declared = true, Object? Function(MethodCall call)? inbox}) {
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      return switch (call.method) {
        'getCapabilities' => {
          'readSmsDeclared': declared,
          'sdkInt': 35,
          'isStoreInstall': null,
        },
        'queryInbox' => inbox?.call(call) ?? const <Object?>[],
        _ => throw MissingPluginException(),
      };
    });
  }

  List<MethodCall> inboxCalls() =>
      calls.where((c) => c.method == 'queryInbox').toList();

  Map<String, Object?> row(int id, int date, {bool truncated = false}) => {
    'id': id,
    'address': 'BANKX',
    'date': date,
    'body': 'synthetic body $id',
    'truncated': truncated,
  };

  setUp(() {
    calls.clear();
    gateway = PlatformSmsInboxGateway(SmsChannelClient());
  });
  tearDown(() => messenger.setMockMethodCallHandler(methods, null));

  group('getCapability', () {
    test('READ_SMS declared -> available on Android', () async {
      reply();
      final capability = await gateway.getCapability();
      expect(
        capability,
        const SmsCapability(readSmsDeclared: true, isAndroid: true),
      );
      expect(capability.available, isTrue);
    });

    test('not declared -> unavailable, but shares still work', () async {
      reply(declared: false);
      final capability = await gateway.getCapability();
      expect(capability.available, isFalse);
      expect(capability.canReceiveShares, isTrue);
    });

    test('asked once: the manifest cannot change in-process', () async {
      reply();
      await gateway.getCapability();
      await gateway.getCapability();
      expect(calls.where((c) => c.method == 'getCapabilities'), hasLength(1));
    });

    test('a failed reply is "not declared" and is asked again', () async {
      messenger.setMockMethodCallHandler(methods, (call) async {
        calls.add(call);
        throw PlatformException(code: 'boom');
      });
      expect((await gateway.getCapability()).available, isFalse);
      expect((await gateway.getCapability()).available, isFalse);
      expect(calls, hasLength(2));
    });

    test('no plugin (MissingPluginException) -> not declared', () async {
      expect((await gateway.getCapability()).available, isFalse);
    });
  });

  group('queryInbox', () {
    test('capability off: short-circuits, no inbox call', () async {
      reply(declared: false);
      final result = await gateway.queryInbox(
        senders: const ['BANKX'],
        afterDate: DateTime(2026),
      );
      expect(
        result.getLeft().toNullable(),
        const SmsCapabilityUnavailableFailure(),
      );
      expect(inboxCalls(), isEmpty);
    });

    test('shapes the arguments exactly', () async {
      reply();
      final after = DateTime.fromMillisecondsSinceEpoch(1772000000000);
      await gateway.queryInbox(
        senders: const ['BANKX', 'BANKY'],
        afterDate: after,
        afterId: 41,
        limit: 50,
      );
      expect(inboxCalls().single.arguments, {
        'senders': ['BANKX', 'BANKY'],
        'afterDate': 1772000000000,
        'afterId': 41,
        'limit': 50,
      });
    });

    test('first page: afterId null, default limit 200', () async {
      reply();
      await gateway.queryInbox(
        senders: const ['BANKX'],
        afterDate: DateTime.fromMillisecondsSinceEpoch(0),
      );
      final args = inboxCalls().single.arguments as Map;
      expect(args['afterId'], isNull);
      expect(args['limit'], 200);
      expect(args['afterDate'], 0);
    });

    test('maps rows to InboxSmsMessage in order', () async {
      reply(
        inbox: (_) => [
          row(7, 1772000000000),
          row(8, 1772000000500, truncated: true),
        ],
      );
      final result = await gateway.queryInbox(
        senders: const ['BANKX'],
        afterDate: DateTime(2026),
      );
      final messages = result.getOrElse((_) => const []);
      expect(messages, [
        InboxSmsMessage(
          id: 7,
          address: 'BANKX',
          date: DateTime.fromMillisecondsSinceEpoch(1772000000000),
          body: 'synthetic body 7',
        ),
        InboxSmsMessage(
          id: 8,
          address: 'BANKX',
          date: DateTime.fromMillisecondsSinceEpoch(1772000000500),
          body: 'synthetic body 8',
          truncated: true,
        ),
      ]);
    });

    test('page boundary: a full page is returned whole, then the next '
        'page continues from the last (date, id)', () async {
      final pageOne = [for (var i = 1; i <= 3; i++) row(i, 1000 + i)];
      final pageTwo = [row(4, 1004)];
      reply(
        inbox: (call) =>
            (call.arguments as Map)['afterId'] == null ? pageOne : pageTwo,
      );
      final first = (await gateway.queryInbox(
        senders: const ['BANKX'],
        afterDate: DateTime.fromMillisecondsSinceEpoch(1000),
        limit: 3,
      )).getOrElse((_) => const []);
      expect(first, hasLength(3));
      final last = first.last;
      final second = (await gateway.queryInbox(
        senders: const ['BANKX'],
        afterDate: last.date,
        afterId: last.id,
        limit: 3,
      )).getOrElse((_) => const []);
      expect(second.map((m) => m.id), [4]);
      final args = inboxCalls().last.arguments as Map;
      expect(args['afterDate'], 1003);
      expect(args['afterId'], 3);
    });

    test('empty page -> Right(empty)', () async {
      reply(inbox: (_) => const <Object?>[]);
      final result = await gateway.queryInbox(
        senders: const ['BANKX'],
        afterDate: DateTime(2026),
      );
      expect(result.getOrElse((_) => [_sentinel]), isEmpty);
    });

    test('a null reply is an empty page', () async {
      messenger.setMockMethodCallHandler(methods, (call) async {
        if (call.method == 'getCapabilities') {
          return {'readSmsDeclared': true, 'sdkInt': 35};
        }
        return null;
      });
      final result = await gateway.queryInbox(
        senders: const ['BANKX'],
        afterDate: DateTime(2026),
      );
      expect(result.getOrElse((_) => [_sentinel]), isEmpty);
    });

    for (final (code, expected) in <(String, Failure)>[
      (
        'permission_denied',
        const SmsPermissionFailure(SmsPermissionStatus.denied),
      ),
      ('query_failed', const SmsInboxQueryFailure()),
      ('invalid_args', const SmsInboxQueryFailure()),
      ('unavailable', const SmsCapabilityUnavailableFailure()),
    ]) {
      test('platform $code -> $expected', () async {
        reply(
          inbox: (_) => throw PlatformException(
            code: code,
            message: 'synthetic detail that must not leak',
          ),
        );
        final result = await gateway.queryInbox(
          senders: const ['BANKX'],
          afterDate: DateTime(2026),
        );
        final failure = result.getLeft().toNullable();
        expect(failure, expected);
        expect(failure!.message, isNot(contains('synthetic')));
      });
    }

    test('a malformed row fails the page', () async {
      reply(
        inbox: (_) => [
          row(1, 1000),
          {'id': 'x', 'address': 'BANKX', 'date': 1, 'body': 'b'},
        ],
      );
      final result = await gateway.queryInbox(
        senders: const ['BANKX'],
        afterDate: DateTime(2026),
      );
      expect(result.isLeft(), isTrue);
    });

    group('argument rules are checked before any inbox call', () {
      Future<Either<Failure, List<InboxSmsMessage>>> query({
        List<String> senders = const ['BANKX'],
        int limit = 200,
        int? afterId,
        DateTime? afterDate,
      }) => gateway.queryInbox(
        senders: senders,
        afterDate: afterDate ?? DateTime(2026),
        afterId: afterId,
        limit: limit,
      );

      final cases =
          <String, Future<Either<Failure, List<InboxSmsMessage>>> Function()>{
            'empty sender list': () => query(senders: const []),
            'oversized sender list (201)': () =>
                query(senders: [for (var i = 0; i < 201; i++) 'BANK$i']),
            'empty sender': () => query(senders: const ['']),
            'sender over 32 characters': () => query(senders: ['B' * 33]),
            'lower-case sender': () => query(senders: const ['BankX']),
            'sender with a space': () => query(senders: const ['BANK X']),
            'limit 0': () => query(limit: 0),
            'limit 201': () => query(limit: 201),
            'negative afterId': () => query(afterId: -1),
            'afterDate before the epoch': () =>
                query(afterDate: DateTime.fromMillisecondsSinceEpoch(-1)),
          };
      for (final entry in cases.entries) {
        test(entry.key, () async {
          reply();
          final result = await entry.value();
          expect(result.getLeft().toNullable(), const SmsInboxQueryFailure());
          expect(inboxCalls(), isEmpty);
        });
      }

      test('the bounds themselves are accepted (200 senders of 32, '
          'limit 1 and 200)', () async {
        reply();
        final senders = [
          for (var i = 0; i < 200; i++) 'B${i.toString().padLeft(31, '0')}',
        ];
        expect((await query(senders: senders, limit: 1)).isRight(), isTrue);
        expect((await query(limit: 200)).isRight(), isTrue);
        expect(inboxCalls(), hasLength(2));
      });
    });
  });

  test('toString carries no content', () {
    expect(gateway.toString(), 'PlatformSmsInboxGateway()');
  });
}

final _sentinel = InboxSmsMessage(
  id: -1,
  address: '',
  date: DateTime(2000),
  body: '',
);
