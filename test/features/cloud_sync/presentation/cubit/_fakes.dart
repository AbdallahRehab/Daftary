import 'package:daftary/features/cloud_sync/domain/entities/sync_runtime_status.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:daftary/features/cloud_sync/domain/repositories/cloud_sync_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockCloudSyncRepository extends Mock implements CloudSyncRepository {}

/// A status with sensible defaults for cubit and page tests.
SyncStatus syncStatus({
  SyncRuntimeStatus runtime = SyncRuntimeStatus.idle,
  bool enabled = true,
  bool noticeShown = true,
  int pending = 0,
  int failed = 0,
  int conflicts = 0,
  bool isAnonymous = true,
  bool available = true,
  DateTime? lastSuccessAt,
  String? linkedEmailMasked,
  SyncProblem? problem,
}) => SyncStatus(
  runtime: runtime,
  enabled: enabled,
  noticeShown: noticeShown,
  pending: pending,
  failed: failed,
  conflicts: conflicts,
  isAnonymous: isAnonymous,
  available: available,
  lastSuccessAt: lastSuccessAt,
  linkedEmailMasked: linkedEmailMasked,
  problem: problem,
);
