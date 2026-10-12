import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/sms_permission_status.dart';
import '../../domain/services/sms_permission_service.dart';

/// The permission port where READ_SMS does not exist: iOS, macOS and the
/// host platform of `flutter test`. Every status is
/// [SmsPermissionStatus.unavailable] and nothing is ever prompted
/// (sms-platform-channel §6). Never touches a channel.
///
/// No injectable annotation: `SmsPlatformModule` chooses it.
class UnavailableSmsPermissionService implements SmsPermissionService {
  const UnavailableSmsPermissionService();

  @override
  Future<Either<Failure, SmsPermissionStatus>> getStatus() async =>
      const Right(SmsPermissionStatus.unavailable);

  @override
  Future<Either<Failure, SmsPermissionStatus>> request({
    required bool previouslyRequested,
  }) async => const Right(SmsPermissionStatus.unavailable);

  /// A no-op: there is no SMS permission to guide the user to here.
  @override
  Future<Either<Failure, Unit>> openAppInfo() async => const Right(unit);
}
