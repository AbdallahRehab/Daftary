import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

/// What wiping this device does to its cloud copy (021 × 013/015). Bound by
/// the cloud-sync feature's data layer; this feature only sees the port.
///
/// Wiping only the local tables would not be enough: with the cloud session
/// still on the device, the next sync would download everything back.
abstract class CloudCopyEraser {
  /// Runs [wipeLocalData] with no sync cycle running or able to start, after
  /// dealing with the cloud copy:
  ///
  /// - [eraseCloudCopy] `true` ("Delete my data", 013): deletes this
  ///   account's cloud copy, then ends the cloud session on this device. If
  ///   the cloud cannot be reached, returns the failure **without** running
  ///   [wipeLocalData], so nothing anywhere was removed.
  /// - `false` (App Lock's Forgot-PIN wipe, 015): only ends the cloud
  ///   session, so the data can come back solely through an email sign-in —
  ///   never just by holding the phone.
  ///
  /// With no cloud copy to reach (cloud sync not configured, switched off,
  /// or never signed in), it only drops any stored session and runs
  /// [wipeLocalData].
  Future<Either<Failure, Unit>> wipe({
    required bool eraseCloudCopy,
    required Future<Either<Failure, Unit>> Function() wipeLocalData,
  });
}
