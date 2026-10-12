import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/sms_capability.dart';

/// Reads allow-listed messages from the SMS inbox (sms-platform-channel §6).
/// Implemented by `PlatformSmsInboxGateway` on Android and by an
/// unavailable adapter elsewhere.
abstract class SmsInboxGateway {
  /// Capability and platform check; never throws, never prompts.
  Future<SmsCapability> getCapability();

  /// One keyset page of allow-listed messages strictly after the cursor.
  /// [limit] is 1..200; [senders] is canonical and non-empty. A page shorter
  /// than [limit] means the inbox is exhausted for this cursor.
  Future<Either<Failure, List<InboxSmsMessage>>> queryInbox({
    required List<String> senders,
    required DateTime afterDate,
    int? afterId,
    int limit = 200,
  });
}

/// One message as read from the inbox provider.
class InboxSmsMessage extends Equatable {
  const InboxSmsMessage({
    required this.id,
    required this.address,
    required this.date,
    required this.body,
    this.truncated = false,
  });

  /// The provider `_id`.
  final int id;

  /// The raw address as stored by the provider.
  final String address;

  /// Receipt time.
  final DateTime date;

  /// The message body. Never logged, never in [toString].
  final String body;

  /// Truncated by the platform at 4,000 characters.
  final bool truncated;

  @override
  List<Object?> get props => [id, address, date, body, truncated];

  @override
  String toString() =>
      'InboxSmsMessage(length: ${body.length}, truncated: $truncated)';
}
