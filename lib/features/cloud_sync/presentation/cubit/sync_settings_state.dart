import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/sync_failed_item.dart';
import '../../domain/entities/sync_runtime_status.dart';
import '../../domain/entities/sync_status.dart';

enum SyncSettingsLoadStatus { loading, ready, failure }

/// Immutable state for `SyncSettingsCubit` (constitution Principle IV).
class SyncSettingsState extends Equatable {
  const SyncSettingsState({
    this.loadStatus = SyncSettingsLoadStatus.loading,
    this.status,
    this.failedItems = const [],
    this.isRequestingSync = false,
    this.isTogglingEnabled = false,
    this.isRetrying = false,
    this.actionFailure,
  });

  final SyncSettingsLoadStatus loadStatus;

  /// The live status; null until the first read.
  final SyncStatus? status;

  /// The changes the cloud refused, oldest first.
  final List<SyncFailedItem> failedItems;
  final bool isRequestingSync;
  final bool isTogglingEnabled;
  final bool isRetrying;

  /// Why the last action failed; cleared by the next action.
  final Failure? actionFailure;

  /// "Sync now" is disabled while a cycle runs, while sync is off or
  /// unavailable, and while a request is being sent (FR-019).
  bool get canSyncNow {
    final s = status;
    return s != null &&
        s.available &&
        s.enabled &&
        s.runtime != SyncRuntimeStatus.syncing &&
        !isRequestingSync;
  }

  SyncSettingsState copyWith({
    SyncSettingsLoadStatus? loadStatus,
    SyncStatus? status,
    List<SyncFailedItem>? failedItems,
    bool? isRequestingSync,
    bool? isTogglingEnabled,
    bool? isRetrying,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return SyncSettingsState(
      loadStatus: loadStatus ?? this.loadStatus,
      status: status ?? this.status,
      failedItems: failedItems ?? this.failedItems,
      isRequestingSync: isRequestingSync ?? this.isRequestingSync,
      isTogglingEnabled: isTogglingEnabled ?? this.isTogglingEnabled,
      isRetrying: isRetrying ?? this.isRetrying,
      actionFailure: clearActionFailure
          ? null
          : actionFailure ?? this.actionFailure,
    );
  }

  @override
  List<Object?> get props => [
    loadStatus,
    status,
    failedItems,
    isRequestingSync,
    isTogglingEnabled,
    isRetrying,
    actionFailure,
  ];
}
