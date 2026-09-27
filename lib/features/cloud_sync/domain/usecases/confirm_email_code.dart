import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/cloud_sync_repository.dart';

/// 021 US6: confirms the code sent by `RequestEmailCode`. Linking keeps the
/// account; signing in switches to the existing one, and its data is merged
/// on the next sync (research.md Decision 11).
@injectable
class ConfirmEmailCode {
  const ConfirmEmailCode(this._repository);

  final CloudSyncRepository _repository;

  Future<Either<Failure, Unit>> call(
    String email,
    String code, {
    required bool linkCurrent,
  }) {
    final token = code.trim();
    if (!RegExp(r'^\d{6,10}$').hasMatch(token)) {
      return Future.value(
        const Left(EmailAuthFailure(EmailAuthErrorReason.invalidCode)),
      );
    }
    return _repository.confirmEmailCode(
      email.trim().toLowerCase(),
      token,
      linkCurrent: linkCurrent,
    );
  }
}
