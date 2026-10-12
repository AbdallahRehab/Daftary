import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart' show Bidi;

import '../../../../core/error/failure.dart';
import '../entities/sms_import_failures.dart';
import '../entities/sms_value_types.dart';
import '../repositories/sms_import_repository.dart';

/// The masked original of a still-pending item, with the direction it is
/// written in (FR-045, FR-091). `OriginalUnavailableFailure` when the item
/// is decided, has no original, or the original cannot be decrypted.
///
/// The text is returned to the caller only; it is never stored, logged or
/// cached here.
@injectable
class ShowOriginalMessage {
  ShowOriginalMessage(this._repository);

  final SmsImportRepository _repository;

  Future<Either<Failure, OriginalMessage>> call(String id) async {
    final result = await _repository.openOriginal(id);
    return result.match(
      (failure) => Left(
        failure is CacheFailure ? failure : const OriginalUnavailableFailure(),
      ),
      (text) =>
          Right(OriginalMessage(text: text, direction: directionOf(text))),
    );
  }

  /// The direction of the first strong character, independent of the app
  /// locale (ui-contract §8.3). With no strong character the overall
  /// estimate of `Bidi.detectRtlDirectionality` decides.
  static TextDirectionHint directionOf(String text) {
    if (Bidi.startsWithRtl(text)) return TextDirectionHint.rtl;
    if (Bidi.startsWithLtr(text)) return TextDirectionHint.ltr;
    return Bidi.detectRtlDirectionality(text)
        ? TextDirectionHint.rtl
        : TextDirectionHint.ltr;
  }
}
