import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/security/app_lifecycle_observer.dart';
import '../../domain/services/share_service.dart';

/// [ShareService] over `share_plus` — the only file in the codebase that
/// imports `package:share_plus/share_plus.dart` (contracts/export_user_data.md).
///
/// The sheet runs as an app-initiated external activity (015 FR-010): on
/// Android it can fully background the app, which must not start App Lock's
/// inactivity timer and greet the user with a lock screen on return.
@LazySingleton(as: ShareService)
class SharePlusService implements ShareService {
  SharePlusService(this._lifecycle) : _sharePlus = SharePlus.instance;

  /// Lets a test substitute the plugin without a platform channel.
  @visibleForTesting
  SharePlusService.withSharePlus(this._sharePlus, this._lifecycle);

  final SharePlus _sharePlus;
  final AppLifecycleObserver _lifecycle;

  @override
  Future<Either<Failure, Unit>> shareFile({
    required String filePath,
    String? subject,
  }) async {
    try {
      // Every [ShareResultStatus] means the sheet was presented: `dismissed`
      // is the user backing out, which is not an error (spec Edge Cases), and
      // `unavailable` is a platform that cannot report what was chosen.
      await _lifecycle.runExternalActivity(
        () => _sharePlus.share(
          ShareParams(files: [XFile(filePath)], subject: subject),
        ),
      );
      return const Right(unit);
    } on PlatformException catch (e) {
      return Left(ShareFailure('Could not open the share sheet: ${e.message}'));
    } catch (e) {
      return Left(ShareFailure('Could not open the share sheet: $e'));
    }
  }
}
