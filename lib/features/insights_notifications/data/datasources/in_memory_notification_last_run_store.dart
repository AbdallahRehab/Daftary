import 'package:injectable/injectable.dart';

import '../../domain/repositories/notification_last_run_store.dart';

/// Process-lifetime [NotificationLastRunStore]. The app has no key-value
/// store dependency and this feature adds no table for a single timestamp,
/// so a cold start always counts as "overdue" — which only costs one
/// idempotent recomputation pass (contracts/notification_engine.md
/// Idempotency note), since unchanged bands never re-notify.
@LazySingleton(as: NotificationLastRunStore)
class InMemoryNotificationLastRunStore implements NotificationLastRunStore {
  DateTime? _lastRun;

  @override
  Future<DateTime?> read() async => _lastRun;

  @override
  Future<void> write(DateTime completedAt) async => _lastRun = completedAt;
}
