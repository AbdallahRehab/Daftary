import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/sms_capability.dart';
import '../../domain/entities/sms_import_failures.dart';
import '../../domain/services/sms_inbox_gateway.dart';

/// The inbox port where no inbox can be read: iOS, macOS and the host
/// platform of `flutter test`. Never touches a channel.
///
/// No injectable annotation: `SmsPlatformModule` chooses it (discovery
/// di.md), so the type is never registered twice.
class UnavailableSmsInboxGateway implements SmsInboxGateway {
  const UnavailableSmsInboxGateway();

  @override
  Future<SmsCapability> getCapability() async => SmsCapability.unavailable;

  @override
  Future<Either<Failure, List<InboxSmsMessage>>> queryInbox({
    required List<String> senders,
    required DateTime afterDate,
    int? afterId,
    int limit = 200,
  }) async => const Left(SmsCapabilityUnavailableFailure());
}
