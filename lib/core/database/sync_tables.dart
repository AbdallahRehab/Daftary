import 'package:drift/drift.dart';

// 021 Offline-First Cloud Sync — the local sync tables (data-model.md §2).
// They live beside the business tables in the same `AppDatabase`, so a
// business write and its outbox row always commit in one transaction
// (research.md Decisions 2 and 3). None of them touches a business column.
//
// Every timestamp is epoch milliseconds, like the business tables.

/// `sync_outbox`: operations waiting to be uploaded (FR-024).
///
/// `status` is `pending` | `in_flight` | `failed` | `blocked_conflict`; a
/// row is deleted once the server acknowledges it.
@DataClassName('SyncOutboxRow')
@TableIndex(
  name: 'idx_outbox_ready',
  columns: {#status, #dependsOnRank, #createdAt},
)
@TableIndex(
  name: 'idx_outbox_entity',
  columns: {#entityType, #entityId, #status},
)
class SyncOutboxEntries extends Table {
  @override
  String get tableName => 'sync_outbox';

  /// UUID v4 generated at enqueue; the idempotency key sent to the server.
  TextColumn get opId => text()();

  /// A `SyncEntityType.wire` value.
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();

  /// `upsert` | `delete`.
  TextColumn get opType => text()();

  /// The full record snapshot in the wire shape (contracts/sync-rpc.md §1).
  TextColumn get payloadJson => text()();

  /// The server revision the change was made against; null = never synced.
  IntColumn get baseRevision => integer().nullable()();

  /// `SyncEntityType.rank`: parents upload before children.
  IntColumn get dependsOnRank => integer()();
  TextColumn get status => text()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  IntColumn get lastAttemptAt => integer().nullable()();

  /// Null = eligible now.
  IntColumn get nextAttemptAt => integer().nullable()();

  /// A code only (e.g. `network`); never record contents.
  TextColumn get errorCode => text().nullable()();

  /// FIFO order within a rank.
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {opId};
}

/// `sync_record_meta`: the sync state of each local record (FR-008).
///
/// `state` is `synced` | `pending` | `failed` | `conflict`.
@DataClassName('SyncRecordMetaRow')
@TableIndex(name: 'idx_meta_state', columns: {#state})
class SyncRecordMeta extends Table {
  @override
  String get tableName => 'sync_record_meta';

  TextColumn get entityType => text()();
  TextColumn get entityId => text()();

  /// The last revision the server confirmed.
  IntColumn get serverRevision => integer().nullable()();
  TextColumn get state => text()();
  IntColumn get lastSyncedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {entityType, entityId};
}

/// `sync_conflicts`: open manual conflicts on financial records (FR-035).
/// At most one open conflict per record (`resolved_at IS NULL`).
@DataClassName('SyncConflictRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX idx_conflicts_open '
  'ON sync_conflicts (entity_type, entity_id) WHERE resolved_at IS NULL',
)
class SyncConflicts extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();

  /// The local version the user edited.
  TextColumn get localPayloadJson => text()();

  /// The server row returned by `sync_push`.
  TextColumn get serverPayloadJson => text()();

  /// The base revision to use for "keep mine".
  IntColumn get serverRevision => integer()();
  IntColumn get detectedAt => integer()();
  IntColumn get resolvedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `conflict_resolutions`: synced, append-only record of how each manual
/// conflict was resolved (research.md Decision 8).
@DataClassName('ConflictResolutionRow')
class ConflictResolutions extends Table {
  TextColumn get id => text()();

  /// `money_transaction` | `finance_entry`.
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();

  /// `local` | `server`.
  TextColumn get chosenSide => text()();
  TextColumn get discardedValuesJson => text()();
  IntColumn get resolvedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `sync_state`: the device's sync bookkeeping. Single-row table — the app
/// always reads/writes the fixed `id` `'singleton'` (FR-010, FR-060).
@DataClassName('SyncStateRow')
class SyncState extends Table {
  @override
  String get tableName => 'sync_state';

  TextColumn get id => text()();

  /// FR-041: sync is on by default.
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Whether the one-time sync notice has been shown (Q2).
  BoolColumn get noticeShown => boolean().withDefault(const Constant(false))();

  /// The `auth.uid()` the download cursor belongs to; null = adopt the first.
  TextColumn get ownerId => text().nullable()();

  /// A UUID generated on first run.
  TextColumn get deviceId => text()();

  /// The single download cursor.
  IntColumn get lastPulledRevision =>
      integer().withDefault(const Constant(0))();

  /// Set in the same transaction that enqueues the pre-existing data; the
  /// only guard against a second bootstrap (data-model.md §3).
  BoolColumn get bootstrapEnqueued =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get initialUploadDone =>
      boolean().withDefault(const Constant(false))();
  IntColumn get lastAttemptAt => integer().nullable()();
  IntColumn get lastSuccessAt => integer().nullable()();

  /// Drives backoff; persists across triggers.
  IntColumn get consecutiveFailures =>
      integer().withDefault(const Constant(0))();
  TextColumn get lastErrorCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
