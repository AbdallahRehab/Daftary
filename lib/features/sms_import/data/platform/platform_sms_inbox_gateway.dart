import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/sms_capability.dart';
import '../../domain/entities/sms_import_failures.dart';
import '../../domain/services/sms_inbox_gateway.dart';
import 'sms_channel_client.dart';

/// The Android inbox port (sms-platform-channel §2.1, §2.4, §6).
///
/// - [getCapability] asks the plugin once whether READ_SMS is declared by
///   the installed package and keeps the answer: the manifest cannot change
///   while the process lives. A failed reply is "not declared" and is not
///   kept, so a later call asks again.
/// - [queryInbox] short-circuits to [SmsCapabilityUnavailableFailure] when
///   READ_SMS is not declared, so a build without the capability never
///   makes an inbox call (invariant 5). It validates the arguments with the
///   plugin's own rules before invoking, and maps each row to an
///   [InboxSmsMessage]. A violated rule is an [SmsInboxQueryFailure] and no
///   call is made.
///
/// Nothing is logged, and no failure carries a sender, an address or a
/// body. No injectable annotation: `SmsPlatformModule` chooses it, on
/// Android only.
class PlatformSmsInboxGateway implements SmsInboxGateway {
  PlatformSmsInboxGateway(this._channel);

  final SmsChannelClient _channel;
  SmsCapability? _capability;

  /// The plugin's argument bounds (§2.4).
  static const int maxSenders = 200;
  static const int maxSenderLength = 32;
  static const int maxLimit = 200;

  @override
  Future<SmsCapability> getCapability() async {
    final known = _capability;
    if (known != null) return known;
    final reply = await _channel.getCapabilities();
    return reply.match(
      // Selected on Android only, so sharing stays available.
      (_) => const SmsCapability(readSmsDeclared: false, isAndroid: true),
      (map) {
        final declared = map['readSmsDeclared'];
        return _capability = SmsCapability(
          readSmsDeclared: declared is bool && declared,
          isAndroid: true,
        );
      },
    );
  }

  @override
  Future<Either<Failure, List<InboxSmsMessage>>> queryInbox({
    required List<String> senders,
    required DateTime afterDate,
    int? afterId,
    int limit = 200,
  }) async {
    if (!(await getCapability()).available) {
      return const Left(SmsCapabilityUnavailableFailure());
    }
    final afterMillis = afterDate.millisecondsSinceEpoch;
    if (!_validSenders(senders) ||
        limit < 1 ||
        limit > maxLimit ||
        afterMillis < 0 ||
        (afterId != null && afterId < 0)) {
      return const Left(SmsInboxQueryFailure());
    }
    final reply = await _channel.queryInbox(
      senders: senders,
      afterDate: afterMillis,
      afterId: afterId,
      limit: limit,
    );
    return reply.flatMap((rows) {
      final messages = <InboxSmsMessage>[];
      for (final row in rows) {
        final message = _decode(row);
        if (message == null) {
          return Left(SmsChannelErrorCode.malformedReply.failure);
        }
        messages.add(message);
      }
      return Right(messages);
    });
  }

  /// Non-empty, at most [maxSenders], each 1..[maxSenderLength] characters,
  /// canonical upper-case with no whitespace. Dart normalizes; this only
  /// rejects, exactly like the plugin.
  static bool _validSenders(List<String> senders) {
    if (senders.isEmpty || senders.length > maxSenders) return false;
    for (final sender in senders) {
      if (sender.isEmpty || sender.length > maxSenderLength) return false;
      if (sender != sender.toUpperCase()) return false;
      if (sender.contains(RegExp(r'\s'))) return false;
    }
    return true;
  }

  static InboxSmsMessage? _decode(Map<String, Object?> row) {
    final id = row['id'];
    final address = row['address'];
    final date = row['date'];
    final body = row['body'];
    final truncated = row['truncated'];
    if (id is! int || address is! String || date is! int || body is! String) {
      return null;
    }
    return InboxSmsMessage(
      id: id,
      address: address,
      date: DateTime.fromMillisecondsSinceEpoch(date),
      body: body,
      truncated: truncated is bool && truncated,
    );
  }

  @override
  String toString() => 'PlatformSmsInboxGateway()';
}
