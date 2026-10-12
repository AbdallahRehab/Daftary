import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/sms_permission_status.dart';
import '../services/sms_permission_service.dart';
import 'get_sms_capability.dart';

/// The READ_SMS permission state, prompt-free (domain-interfaces §5.1).
/// Used on resume to detect revocation (FR-070); mirrors the `refresh()`
/// of `request_notification_permission.dart`. Never prompts.
///
/// Without the capability it is [SmsPermissionStatus.unavailable] and no
/// permission call is made.
@injectable
class GetSmsPermissionStatus {
  GetSmsPermissionStatus(this._capability, this._permissions);

  final GetSmsCapability _capability;
  final SmsPermissionService _permissions;

  Future<Either<Failure, SmsPermissionStatus>> call() async {
    final capability = await _capability();
    if (!capability.available) {
      return const Right(SmsPermissionStatus.unavailable);
    }
    return _permissions.getStatus();
  }
}
