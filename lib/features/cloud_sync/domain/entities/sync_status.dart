import 'package:equatable/equatable.dart';

import 'sync_runtime_status.dart';

/// A persistent sync problem the Settings sync page explains on its own,
/// beyond what [SyncRuntimeStatus] says.
enum SyncProblem {
  /// A row downloaded from the cloud could not be read on this device (a
  /// newer app version wrote it, or it is damaged). Downloading waits; no
  /// data is skipped or lost. Updating the app usually fixes it.
  unreadableCloudData,
}

/// 021: everything the Settings sync page shows (contracts/dart-interfaces.md
/// §4, FR-040).
class SyncStatus extends Equatable {
  const SyncStatus({
    required this.runtime,
    required this.enabled,
    required this.noticeShown,
    required this.pending,
    required this.failed,
    required this.conflicts,
    required this.isAnonymous,
    this.available = true,
    this.lastSuccessAt,
    this.linkedEmailMasked,
    this.problem,
  });

  final SyncRuntimeStatus runtime;

  /// The user's switch (FR-041).
  final bool enabled;
  final bool noticeShown;
  final DateTime? lastSuccessAt;
  final int pending;
  final int failed;
  final int conflicts;
  final bool isAnonymous;

  /// False when this build has no cloud configuration: sync can never run.
  final bool available;

  /// For example `a***@g***.com`; the raw email is never kept here.
  final String? linkedEmailMasked;

  /// Set while the last cycle stopped on a known persistent problem.
  final SyncProblem? problem;

  SyncStatus copyWith({
    SyncRuntimeStatus? runtime,
    bool? enabled,
    bool? noticeShown,
    int? pending,
    int? failed,
    int? conflicts,
    bool? isAnonymous,
    bool? available,
  }) {
    return SyncStatus(
      runtime: runtime ?? this.runtime,
      enabled: enabled ?? this.enabled,
      noticeShown: noticeShown ?? this.noticeShown,
      pending: pending ?? this.pending,
      failed: failed ?? this.failed,
      conflicts: conflicts ?? this.conflicts,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      available: available ?? this.available,
      lastSuccessAt: lastSuccessAt,
      linkedEmailMasked: linkedEmailMasked,
      problem: problem,
    );
  }

  @override
  List<Object?> get props => [
    runtime,
    enabled,
    noticeShown,
    lastSuccessAt,
    pending,
    failed,
    conflicts,
    isAnonymous,
    available,
    linkedEmailMasked,
    problem,
  ];
}
