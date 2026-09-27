/// 021: why a sync cycle was requested (plan §8 "Triggers").
enum SyncTrigger {
  /// App startup, once startup is ready.
  launch,

  /// The app came back to the foreground.
  resumed,

  /// The device reported a network again.
  connectivityRestored,

  /// A local write queued an outbox operation (debounced 3 s).
  localWrite,

  /// The 5-minute foreground timer.
  periodic,

  /// "Sync now" in Settings. Ignores a pending backoff delay.
  manual,

  /// The sync switch was turned on.
  enabled,

  /// A backoff delay has elapsed.
  backoffElapsed,
}

/// 021: the scheduler's runtime status (contracts/dart-interfaces.md §1).
/// `cloud_sync/data` maps it to the domain `SyncRuntimeStatus`; core never
/// imports a feature.
enum SchedulerState {
  idle,
  syncing,
  offline,
  backingOff,
  authRequired,
  disabled,
}
