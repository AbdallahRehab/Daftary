import 'package:equatable/equatable.dart';

import 'sync_runtime_status.dart';

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
    this.lastSuccessAt,
    this.linkedEmailMasked,
  });

  final SyncRuntimeStatus runtime;
  final bool enabled;
  final bool noticeShown;
  final DateTime? lastSuccessAt;
  final int pending;
  final int failed;
  final int conflicts;
  final bool isAnonymous;

  /// For example `a***@g***.com`; the raw email is never kept here.
  final String? linkedEmailMasked;

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
    linkedEmailMasked,
  ];
}
