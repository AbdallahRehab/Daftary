import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/failure.dart';
import '../../domain/services/share_service.dart';

/// [ShareService] over `share_plus` — the only file in the codebase that
/// imports `package:share_plus/share_plus.dart` (contracts/export_user_data.md).
@LazySingleton(as: ShareService)
class SharePlusService implements ShareService {
  SharePlusService() : _sharePlus = SharePlus.instance;

  /// Lets a test substitute the plugin without a platform channel.
  @visibleForTesting
  SharePlusService.withSharePlus(this._sharePlus);

  final SharePlus _sharePlus;

  @override
  Future<Either<Failure, Unit>> shareFile({
    required String filePath,
    String? subject,
  }) async {
    try {
      // Every [ShareResultStatus] means the sheet was presented: `dismissed`
      // is the user backing out, which is not an error (spec Edge Cases), and
      // `unavailable` is a platform that cannot report what was chosen.
      await _sharePlus.share(
        ShareParams(files: [XFile(filePath)], subject: subject),
      );
      return const Right(unit);
    } on PlatformException catch (e) {
      return Left(ShareFailure('Could not open the share sheet: ${e.message}'));
    } catch (e) {
      return Left(ShareFailure('Could not open the share sheet: $e'));
    }
  }
}
