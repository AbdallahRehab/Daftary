import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

/// Hands a local file to the OS's own share/save sheet (FR-010), isolating
/// the platform plugin behind a swappable interface (constitution
/// Principle VI, contracts/export_user_data.md "Contract: ShareService").
abstract class ShareService {
  /// Presents the OS share sheet for [filePath]. Returns success once the
  /// sheet has been presented — NOT once the user has necessarily completed
  /// a share: dismissing the sheet is a normal, non-error outcome (spec
  /// Edge Cases). Returns [ShareFailure] only when the sheet could not be
  /// shown at all.
  Future<Either<Failure, Unit>> shareFile({
    required String filePath,
    String? subject,
  });
}

/// The OS share sheet could not be presented (a platform error). The
/// generated file itself is untouched, so the caller can simply offer the
/// share action again.
class ShareFailure extends Failure {
  const ShareFailure(super.message);
}
