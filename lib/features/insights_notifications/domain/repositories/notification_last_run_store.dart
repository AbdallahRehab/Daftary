/// When `NotificationEngine.run()` last completed — the bookkeeping behind
/// the foreground catch-up's "more than 6 hours since the last
/// recomputation" rule (research.md Decision 4).
abstract class NotificationLastRunStore {
  /// `null` when no pass has completed yet (in this process, for the
  /// in-memory implementation).
  Future<DateTime?> read();

  Future<void> write(DateTime completedAt);
}
