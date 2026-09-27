# Contract: Dart Interfaces

**Feature**: 021-supabase-offline-sync

These are the signatures that `/speckit-tasks` and the implementation must satisfy. The bodies are left out. The names follow the existing conventions: `*Repository` / `*RepositoryImpl`, `*Dao`, use cases named as verbs, and `Either<Failure, T>` from `fpdart`.

---

## 1. Core infrastructure (`lib/core/`, cross-cutting per constitution II)

```dart
// lib/core/config/cloud_config.dart
class CloudConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}

// lib/core/database/watch_tables.dart
extension WatchTables on AppDatabase {
  /// Emits once immediately, then (debounced 50 ms) whenever any of [tables] is written.
  Stream<void> changesOf(Set<TableInfo> tables);
}

// lib/core/error/failure.dart — ADDED subclasses (existing ones untouched)
class NetworkFailure extends Failure { … }
class TimeoutFailure extends Failure { … }
class ServerFailure extends Failure { … }
class UnauthorizedFailure extends Failure { … }
class ForbiddenFailure extends Failure { … }
class SyncRejectedFailure extends Failure { final String reason; … }
class SyncConflictFailure extends Failure { … }

// lib/core/sync/sync_entity_type.dart
enum SyncEntityType { person, moneyTransaction, transactionAudit, financeCategory,
  financeEntry, exchangeRate, primaryCurrency, conflictResolution }
// .wire ('person', 'money_transaction', …), .rank (0..3)

// lib/core/sync/local/sync_outbox.dart  — used by feature DAOs INSIDE their transaction
abstract class SyncOutbox {
  Future<void> recordUpsert(SyncEntityType type, String id, Map<String, Object?> payload);
  Future<void> recordDelete(SyncEntityType type, String id, Map<String, Object?> lastKnownPayload);
}

// lib/core/sync/local/sync_local_store.dart — the engine's view of the local sync tables
abstract class SyncLocalStore {
  Future<List<OutboxOp>> nextBatch({required int limit, required DateTime now}); // rank→FIFO, skips ops whose parent is failed/blocked
  Future<void> markInFlight(List<String> opIds);
  Future<void> resetInFlight();                                              // on startup
  Future<void> applyPushResults(List<PushResult> results, DateTime now);     // one transaction
  Future<void> rescheduleBatch(List<String> opIds, Duration delay, String errorCode);
  Future<SyncStateRow> readState();
  Future<void> writeState(SyncStateRow Function(SyncStateRow) update);
  Stream<SyncCounts> watchCounts();                                          // pending/failed/conflict
}

// lib/core/sync/local/sync_applier.dart
abstract class SyncApplier {
  /// Applies one pulled page atomically and advances the cursor (contracts/sync-rpc.md §4).
  Future<void> applyPage(PullPage page);
}

// lib/core/sync/remote/sync_remote_data_source.dart — the ONLY class that touches SupabaseClient for data
abstract class SyncRemoteDataSource {
  Future<List<PushResult>> push(List<OutboxOp> ops, DeviceInfo device);   // throws SyncRemoteException
  Future<PullPage> pull({required int since, int limit = 500});
}

// lib/core/sync/remote/cloud_auth_data_source.dart
abstract class CloudAuthDataSource {
  String? get currentUserId;
  bool get isAnonymous;
  Future<String> ensureSession();                    // signInAnonymously if none
  Future<void> requestEmailLinkCode(String email);   // updateUser(email)
  Future<void> confirmEmailLink(String email, String code);
  Future<void> requestSignInCode(String email);      // signInWithOtp
  Future<String> confirmSignIn(String email, String code); // returns new uid
}

// lib/core/sync/connectivity_monitor.dart
abstract class ConnectivityMonitor {
  Stream<bool> get hasNetwork;      // hint only (research Decision 13)
  Future<bool> currentHasNetwork();
}

// lib/core/sync/sync_engine.dart
class SyncEngine {
  /// One cycle: ensureSession → push batches until empty/blocked → pull pages until !hasMore.
  Future<SyncCycleOutcome> runCycle();
}

// lib/core/sync/sync_scheduler.dart — the single-flight gate (FR-018/019/053)
@lazySingleton
class SyncScheduler {
  Future<void> start();          // lifecycle, connectivity, periodic timer, outbox-change listeners
  void request(SyncTrigger reason); // coalesces; never runs two cycles
  Stream<SchedulerState> get status; // core type: idle | syncing | offline | backingOff | authRequired | disabled
  // cloud_sync/data maps SchedulerState → the domain enum SyncRuntimeStatus. The Domain layer never imports lib/core/sync (constitution I; core must not import features).
  Future<void> dispose();
}

// lib/core/sync/sync_logger.dart
enum SyncEvent { syncStarted, uploadStarted, uploadSuccess, uploadFailed, downloadStarted,
  downloadSuccess, conflict, retryScheduled, syncCompleted, syncAborted, migrationEnqueued, cursorAdvanced }
enum SyncLogField { entityType, count, durationMs, errorCode, delayMs, revision, opId }
abstract class SyncLogger { void event(SyncEvent e, {Map<SyncLogField, Object> fields}); }
```

## 2. Per-feature sync mappers (in each feature's `data/sync/`)

```dart
/// Converts between a local Drift row and the wire payload (contracts/sync-rpc.md §1).
abstract class SyncMapper<Row> {
  SyncEntityType get type;
  Map<String, Object?> toWire(Row row);
  Insertable<Row> fromWire(Map<String, Object?> json, {Row? existingLocal});
}
```

| Feature | Files |
| --- | --- |
| people | `person_sync_mapper.dart`, which leaves out `avatarPath` and keeps the local value on apply |
| transactions | `money_transaction_sync_mapper.dart`, `transaction_audit_sync_mapper.dart` |
| finance | `finance_category_sync_mapper.dart`, `finance_entry_sync_mapper.dart` |
| currency | `exchange_rate_sync_mapper.dart`, `primary_currency_sync_mapper.dart` |
| cloud_sync | `conflict_resolution_sync_mapper.dart` |

These are registered in `SyncMapperRegistry` (core), and `SyncApplier` resolves mappers by type.

## 3. Reactive read additions to existing repository contracts (FR-031)

The existing `get*` methods stay. Each new `watch*` method re-runs the same query whenever the listed tables change.

```dart
// PeopleRepository
Stream<Either<Failure, List<Person>>> watchActivePeople({String? nameQuery, RelationshipStatus? statusFilter});
Stream<Either<Failure, List<Person>>> watchArchivedPeople({String? nameQuery});
// TransactionsRepository
Stream<Either<Failure, List<MoneyTransaction>>> watchPersonHistory(String personId);
Stream<Either<Failure, PersonBalance>> watchPersonBalance(String personId);
Stream<Either<Failure, Map<String, PersonBalance>>> watchPersonBalances(List<String> personIds);
Stream<Either<Failure, OverviewSummary>> watchOverview();
// FinanceRepository
Stream<Either<Failure, List<FinanceEntry>>> watchHistory({FinanceHistoryFilter? filter, required int limit});
Stream<Either<Failure, FinancePeriodTotals>> watchSummaryTotals(DateRange period);
// CategoryRepository
Stream<Either<Failure, List<Category>>> watchCategories(/* same params as getCategories */);
// CurrencyRepository
Stream<Either<Failure, List<ExchangeRate>>> watchExchangeRates();
Stream<Either<Failure, String>> watchPrimaryCurrency();
```

Tables watched:

- Balances and overview watch `money_transactions`, `people`, `exchange_rates` and `primary_currency_settings`, because conversion depends on the rates.
- History watches `money_transactions` and `sync_record_meta`, so the conflict badge updates too.

Each watch use case is a thin `Watch*` class. Constitution V allows this because it is the Domain-layer seam the Cubits depend on.

## 4. `cloud_sync` feature (domain contract, the only sync API that Presentation sees)

```dart
// lib/features/cloud_sync/domain/entities/sync_status.dart
// lib/features/cloud_sync/domain/entities/sync_runtime_status.dart
enum SyncRuntimeStatus { idle, syncing, offline, backingOff, authRequired, disabled }

class SyncStatus extends Equatable {
  final SyncRuntimeStatus runtime; final bool enabled; final bool noticeShown;
  final DateTime? lastSuccessAt; final int pending, failed, conflicts;
  final bool isAnonymous; final String? linkedEmailMasked; // "a***@g***.com", never the raw email in logs
}
class SyncConflictItem extends Equatable { entityType, entityId, localSummary, serverSummary, detectedAt }

// lib/features/cloud_sync/domain/repositories/cloud_sync_repository.dart
abstract class CloudSyncRepository {
  Stream<SyncStatus> watchStatus();
  Future<Either<Failure, Unit>> syncNow();
  Future<Either<Failure, Unit>> setEnabled(bool enabled);
  Future<Either<Failure, Unit>> markNoticeShown();
  Future<Either<Failure, Unit>> retryFailed();
  Stream<List<SyncConflictItem>> watchConflicts();
  Future<Either<Failure, Unit>> resolveConflict(String entityType, String entityId, ConflictChoice choice);
  Future<Either<Failure, Unit>> requestEmailCode(String email, {required bool linkCurrent});
  Future<Either<Failure, Unit>> confirmEmailCode(String email, String code, {required bool linkCurrent});
  Stream<bool> watchHasConflict(String entityType, String entityId); // row badge
}
```

**Use cases**: `WatchSyncStatus`, `SyncNow`, `SetSyncEnabled`, `AcknowledgeSyncNotice`, `RetryFailedSync`, `WatchSyncConflicts`, `ResolveSyncConflict`, `RequestEmailCode`, `ConfirmEmailCode`.

**Cubits**:

- `SyncSettingsCubit` (status and the toggle).
- `SyncConflictsCubit` (list and resolve).
- `EmailLinkCubit` (the email and code form, with the states initial, codeSent, verifying, success and failure).
- `SyncNoticeCubit` (shows the one-time notice).

## 5. UI contract (the only visible changes)

| Surface | Change |
| --- | --- |
| `SettingsPage` | One new `_SettingsSection` with a `ListTile` titled "Cloud backup & sync", subtitled with the status, which opens `SyncSettingsPage`. |
| `SyncSettingsPage` (new route `/settings/sync`) | Shows: the status line; the last sync time; the pending, failed and conflict counts; the "Sync now" button (disabled while syncing); the enabled switch; the "Link email" or "Sign in to existing account" action; a list of failed items with Retry; a list of conflicts. |
| `ConflictResolutionSheet` (new) | Shows the two versions side by side (amount, date, note, direction) with "Keep mine" and "Keep theirs" buttons. |
| Transaction row in `PersonDetailPage`, entry row in `FinanceHistoryPage` | A small conflict icon badge, shown only when `watchHasConflict` is true. Tapping it opens the sheet. |
| One-time notice | A dismissible bottom sheet shown once after startup is ready, only when `CloudConfig.isConfigured` is true and the notice has not been shown yet. |

All strings go in `app_en.arb` and `app_ar.arb` (constitution XIII), and all components come from `lib/core/design_system`.
