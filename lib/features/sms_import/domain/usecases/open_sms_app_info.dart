import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../services/sms_permission_service.dart';

/// Opens this app's system App info screen (domain-interfaces §5.1): the
/// path out of `permanentlyDenied` and `restrictedBlocked` (FR-070,
/// FR-072). Prompts nothing. A thin wrapper so cubits depend on use cases
/// only (plan, Complexity Tracking).
@injectable
class OpenSmsAppInfo {
  OpenSmsAppInfo(this._permissions);

  final SmsPermissionService _permissions;

  Future<Either<Failure, Unit>> call() => _permissions.openAppInfo();
}
