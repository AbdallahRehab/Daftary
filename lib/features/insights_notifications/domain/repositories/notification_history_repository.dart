import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/notification_history_entry.dart';
import '../entities/notification_source_type.dart';

/// Domain/Data boundary for the cooldown bookkeeping (FR-015/FR-016).
abstract class NotificationHistoryRepository {
  /// The history row for one (source, period), or `Right(null)` when that
  /// source has never been notified about in [applicablePeriod] — e.g. a
  /// budget category at the start of a new month (FR-016).
  Future<Either<Failure, NotificationHistoryEntry?>> find(
    NotificationSourceType sourceType,
    String sourceId,
    String? applicablePeriod,
  );

  /// Records [entry] as its (source, period)'s last-notified band. Inserts
  /// when no row exists; updates the band and timestamp when the stored
  /// band differs; leaves the stored row untouched when the band is the
  /// same. Never creates a second row for the same (source, period) —
  /// [entry]'s `id` is used only on first insert. Returns the row as
  /// stored.
  Future<Either<Failure, NotificationHistoryEntry>> upsert(
    NotificationHistoryEntry entry,
  );
}
