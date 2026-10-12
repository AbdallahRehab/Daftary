import 'package:injectable/injectable.dart';

import '../entities/sms_capability.dart';
import '../services/sms_inbox_gateway.dart';

/// Whether this build and platform can read the SMS inbox (research
/// Decision 3, sms-platform-channel §2.1). The only way domain and
/// presentation learn availability: neither branches on the platform.
/// Never throws and never prompts.
@injectable
class GetSmsCapability {
  GetSmsCapability(this._gateway);

  final SmsInboxGateway _gateway;

  Future<SmsCapability> call() => _gateway.getCapability();
}
