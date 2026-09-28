import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/data_privacy/domain/services/cloud_copy_eraser.dart';
import 'package:fpdart/fpdart.dart';

/// A [CloudCopyEraser] for a device with no cloud copy: records what it was
/// asked, then runs the local wipe — or, with [failWith], stops before it
/// the way an unreachable cloud does.
class FakeCloudCopyEraser implements CloudCopyEraser {
  FakeCloudCopyEraser({this.failWith});

  final Failure? failWith;
  final List<bool> eraseRequests = [];

  @override
  Future<Either<Failure, Unit>> wipe({
    required bool eraseCloudCopy,
    required Future<Either<Failure, Unit>> Function() wipeLocalData,
  }) async {
    eraseRequests.add(eraseCloudCopy);
    final failure = failWith;
    if (failure != null) return Left(failure);
    return wipeLocalData();
  }
}
