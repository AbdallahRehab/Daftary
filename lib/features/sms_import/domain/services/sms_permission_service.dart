import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/sms_permission_status.dart';

/// The READ_SMS permission (sms-platform-channel §6). Only READ_SMS is ever
/// requested (FR-069, FR-073).
abstract class SmsPermissionService {
  /// Prompt-free. Detects revocation on resume (FR-070).
  Future<Either<Failure, SmsPermissionStatus>> getStatus();

  /// Prompts at most once per call. Called only by `RequestSmsPermission`,
  /// which wraps it in an external-activity guard and persists
  /// `permissionRequested` first (FR-002).
  ///
  /// [previouslyRequested] is the persisted `permissionRequested` flag as
  /// it was BEFORE this request was recorded. The caller reads it before
  /// persisting, because the adapter would otherwise only ever see `true`
  /// and could not tell "never asked" from "permanently denied"
  /// (`classifySmsPermission`, sms-platform-channel §2.3).
  Future<Either<Failure, SmsPermissionStatus>> request({
    required bool previouslyRequested,
  });

  /// Opens this app's system App info screen (restricted-settings and
  /// permanently-denied guidance).
  Future<Either<Failure, Unit>> openAppInfo();
}
