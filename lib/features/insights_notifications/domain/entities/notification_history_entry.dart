import 'package:equatable/equatable.dart';

import 'notification_source_type.dart';

/// A classification of one source's current state (data-model.md). Only a
/// *change* of band between two evaluations produces a notification
/// (FR-015) — the band itself is never a trigger.
enum ThresholdBand {
  // Budget categories (010).
  belowWarning,
  nearLimit,
  exceeded,

  // Savings goals (011).
  onPace,
  behindPace,
  aheadOfPace,
  achieved,
  noEstimateAvailable,
}

/// Cooldown bookkeeping for one (source, applicable period): the band this
/// source was in the last time it was notified about (FR-015/FR-016).
class NotificationHistoryEntry extends Equatable {
  const NotificationHistoryEntry({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.lastNotifiedBand,
    required this.lastNotifiedAt,
    this.applicablePeriod,
  });

  final String id;
  final NotificationSourceType sourceType;

  /// The category id (010) or `SavingsGoal.id` (011). Deliberately not a
  /// foreign key — a stale id is handled at read time (data-model.md).
  final String sourceId;

  /// `'YYYY-MM'` for [NotificationSourceType.budgetCategory], so a new
  /// month starts from no history (FR-016); `null` for savings goals.
  final String? applicablePeriod;

  final ThresholdBand lastNotifiedBand;

  /// Diagnostics/testing only — the cooldown is band-based, not
  /// time-based.
  final DateTime lastNotifiedAt;

  @override
  List<Object?> get props => [
    id,
    sourceType,
    sourceId,
    applicablePeriod,
    lastNotifiedBand,
    lastNotifiedAt,
  ];
}
