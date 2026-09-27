import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/sync_conflict_item.dart';

enum SyncConflictsStatus { loading, success, failure }

/// Immutable state for `SyncConflictsCubit` (constitution Principle IV).
class SyncConflictsState extends Equatable {
  const SyncConflictsState({
    this.status = SyncConflictsStatus.loading,
    this.items = const [],
    this.resolving = const {},
    this.failure,
    this.resolveFailure,
  });

  final SyncConflictsStatus status;

  /// The open conflicts, oldest first.
  final List<SyncConflictItem> items;

  /// Keys ([keyOf]) of the records whose resolution is in progress; their
  /// buttons are disabled so a double tap never resolves twice.
  final Set<String> resolving;

  /// Why the list could not be read.
  final Failure? failure;

  /// Why the last resolution failed; cleared by the next attempt.
  final Failure? resolveFailure;

  static String keyOf(ConflictEntityType type, String entityId) =>
      '${type.wire}|$entityId';

  /// The open conflict of one record, or null — the row badge.
  SyncConflictItem? itemFor(ConflictEntityType type, String entityId) {
    for (final item in items) {
      if (item.entityType == type && item.entityId == entityId) return item;
    }
    return null;
  }

  bool isResolving(SyncConflictItem item) =>
      resolving.contains(keyOf(item.entityType, item.entityId));

  SyncConflictsState copyWith({
    SyncConflictsStatus? status,
    List<SyncConflictItem>? items,
    Set<String>? resolving,
    Failure? failure,
    Failure? resolveFailure,
  }) {
    return SyncConflictsState(
      status: status ?? this.status,
      items: items ?? this.items,
      resolving: resolving ?? this.resolving,
      failure: failure,
      resolveFailure: resolveFailure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    resolving,
    failure,
    resolveFailure,
  ];
}
