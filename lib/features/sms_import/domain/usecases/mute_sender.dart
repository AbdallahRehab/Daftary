import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/sms_sender_mute.dart';
import '../repositories/sms_import_settings_repository.dart';

/// "Stop suggesting from this sender" (FR-065). Offered only for items
/// with a sender (scan and catch-up), never for paste or share.
///
/// One transaction: the canonical upper-case sender is muted and every
/// pending item from it is deleted with no tombstone, so no pending item
/// and no stored content from that sender remains (invariant 8). Later
/// scans leave the sender out of the allow-list. Returns how many pending
/// items were deleted. A blank sender is a `ValidationFailure`.
@injectable
class MuteSender {
  MuteSender(this._settings);

  final SmsImportSettingsRepository _settings;

  Future<Either<Failure, int>> call(String senderId) async {
    if (canonicalSmsSenderId(senderId).isEmpty) {
      return const Left(ValidationFailure('sms_sender_empty'));
    }
    return _settings.muteSender(senderId);
  }
}
