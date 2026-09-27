/// 021: what the sync machinery is doing right now, as the Domain layer
/// sees it (contracts/dart-interfaces.md §4). The Data layer maps the core
/// scheduler state onto it, so the Domain never imports `lib/core/sync`.
enum SyncRuntimeStatus {
  idle,
  syncing,
  offline,
  backingOff,
  authRequired,
  disabled,
}
