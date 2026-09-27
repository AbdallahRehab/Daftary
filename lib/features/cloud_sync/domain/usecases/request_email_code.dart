import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/cloud_sync_repository.dart';

/// 021 US6: sends a one-time code to [email] — to link it to this device's
/// account ([linkCurrent]) or to sign in to an existing account.
@injectable
class RequestEmailCode {
  const RequestEmailCode(this._repository);

  final CloudSyncRepository _repository;

  Future<Either<Failure, Unit>> call(
    String email, {
    required bool linkCurrent,
  }) {
    final normalized = email.trim().toLowerCase();
    if (!isValidEmail(normalized)) {
      return Future.value(
        const Left(EmailAuthFailure(EmailAuthErrorReason.invalidEmail)),
      );
    }
    return _repository.requestEmailCode(normalized, linkCurrent: linkCurrent);
  }

  /// A light shape check; the cloud has the final word.
  static bool isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
}
