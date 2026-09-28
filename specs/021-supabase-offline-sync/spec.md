# Feature Specification: Offline-First Cloud Sync (Supabase)

**Feature Branch**: `021-supabase-offline-sync`

**Created**: 2026-09-27

**Status**: Draft

**Input**: User description: "Integrate Supabase into the existing Flutter app and evolve it into an Offline-First application (local DB as source of truth, sync engine with idempotent queue, conflict resolution, RLS, migration of existing local data, analytics-ready schema). Supabase URL https://nnrmghwqihqnmtnuxzoq.supabase.co; anon key via secure config (no secrets in source). Do not implement; analyze the existing codebase first and produce a complete spec."

> **Product-direction note**: `specs/ROADMAP-PLAN.md` (2026-09-22) records a confirmed decision that Daftary stays local-only with no backend, and lists "V3.5 Cloud Backup & Multi-Device Sync" as **dropped**. This feature reverses that decision. The roadmap MUST be updated to match when this spec is accepted. Until then, the two documents contradict each other.

---

## 1. Current Architecture Assessment

*Based on the codebase at commit `fbce88f`.*

| Area | Finding | Consequence for this feature |
|------|---------|------------------------------|
| Architecture | Feature-first Clean Architecture (`lib/features/<f>/{data,domain,presentation}`), enforced by the constitution (Principles I, II, VI). | Sync goes into the Data layer, behind the existing repository contracts. Domain and Presentation do not learn about the cloud. |
| State management | `flutter_bloc` Cubits, one per screen or form (for example `PersonListCubit`, `PersonDetailCubit`, `OverviewCubit`, `FinanceHistoryCubit`). | Keep this approach. No second state paradigm. |
| DI | `get_it` + `injectable` (`lib/core/di`). | New sync services are registered the same way. |
| Local persistence | **Already exists**: one Drift/SQLite database (`lib/core/database/app_database.dart`), file `daftary.sqlite`, **schema version 8**, with a migration ladder covering v1→v8. | Reuse and extend it; do not replace it. This feature is a v9 migration that only adds things. |
| Data access | One DAO per feature (`people_dao`, `transactions_dao`, `finance_dao`, `currency_dao`, `settings_dao`, `onboarding_dao`, `notifications_dao`) behind `*RepositoryImpl`. | DAOs remain the local data source. The sync layer reads and writes through them or alongside them. |
| Read model | Repositories return **one-shot `Future<Either<Failure, T>>`**. There are no reactive streams in any repository. After a mutation, screens refresh by calling reload imperatively (specs 004 and 005). | Changes applied by sync would not appear on screens that are already open. Selected read paths need a way to notify screens of local changes (see FR-030 to FR-033). |
| Errors | Typed `Failure` hierarchy (`ValidationFailure`, `CacheFailure`, `NotFoundFailure`, `UnknownFailure`, …) with `fpdart` `Either`. | Add sync, network and auth failure types in the same style. |
| Money | Integer minor units plus an ISO 4217 `currencyCode` on every monetary row. Exchange rates are stored as integer `rateMicros`. There is no floating-point money anywhere. | The cloud representation keeps integers exactly. |
| IDs | Client-generated UUID text primary keys (`uuid` package). Money transactions and finance entries also carry a **unique `idempotencyKey`**. Seeded finance categories use **fixed ids** (`seed_<key>`) that are the same on every install. | Client ids stay stable across sync. Seeded ids collide between users, so a cloud record's identity MUST be scoped to its owner. |
| Deletes | Money transactions and finance entries are **soft-deleted** (`deletedAt`). Transaction edits and deletes append rows to `TransactionAuditEntries`. People are **archived**, or **hard-deleted** only when they have no transactions. Finance categories are archived or hard-deleted. Exchange rates are hard-deleted. | Hard deletes must turn into tombstones that sync can carry. |
| Timestamps | Local epoch milliseconds (`createdAt`, `updatedAt`, `editedAt`, `deletedAt`, `date`). | These are device clock values. They cannot be trusted for ordering between devices. |
| Auth / identity | **None.** There is no login and no user id, and the app has a single implicit owner. | Syncing requires a per-user identity (see FR-040 and Clarification Q1). |
| Networking | **None.** There is no HTTP client, no connectivity detection and no secure-storage package. | New dependencies are required (§20). |
| Features not yet implemented | Specs 008–016 (occasions, OCR, budgets, savings goals, dashboard, reports, AI, app lock) have **no tables yet**. Insight sources for budgets and savings are stubbed as "unavailable". | Out of scope here. Each of those features MUST adopt the sync contract when it is built (FR-006). |

### Local tables and their sync classification

| Local table | Domain meaning | Sync? |
|-------------|----------------|-------|
| `people` | Counterparties in money relationships | **Yes** (financial context) |
| `money_transactions` | Money given or received, and repayments | **Yes** (critical financial) |
| `transaction_audit_entries` | Append-only history of edits and deletes | **Yes** (append-only) |
| `finance_categories` | Income and expense categories | **Yes** |
| `finance_entries` | Personal income and expense records | **Yes** (critical financial) |
| `exchange_rates` | Manual FX rates, unique per currency pair | **Yes** |
| `primary_currency_settings` | The user's reporting currency | **Yes** (per user) |
| `app_settings` | Language, theme, Liquid Glass | **No**: device preference |
| `onboarding_status` | Device onboarding completion | **No**: device state |
| `notification_preferences` / `notification_history` | OS permission, quiet hours, cooldown bookkeeping | **No**: device state |

---

## Clarifications

### Session 2026-09-27

*Q1–Q3 were first taken as assumed recommended answers when planning started. The user confirmed all three on 2026-09-27, after implementation.*

- Q: How should a user's cloud data be tied to them, given the app has no login today? → A (confirmed by the user 2026-09-27): Silent anonymous sign-in on the first online launch. An optional "Link email" (one-time code) in Settings upgrades the **same** user id, which enables restore and a second device. Signing into an existing account on a device merges that device's local data into the account. Sign-out is out of scope.
- Q: Is sync on automatically after the upgrade, or opt-in? → A (confirmed by the user 2026-09-27): On by default. A one-time, dismissible notice explains it, and a switch in Settings turns it off. While sync is off, no network request is made, but local changes are still queued, so turning sync on later uploads everything.
- Q: Do a person's phone number and notes go to the cloud? → A (confirmed by the user 2026-09-27): Yes, both are synced and protected by owner-only row-level security. The avatar file path is never synced.
- Q: What does the user see offline, while pending, while syncing, and on failure or conflict? → A (codebase-derived): Existing screens are unchanged. There is a sync section in Settings (status, last sync, pending, failed and conflict counts, "Sync now", the on/off switch, "Link email"). The only per-record marker is a small conflict badge on a transaction or finance entry that is in conflict. Tapping it opens the keep-mine / keep-theirs choice.
- Q: Do the 004/005 "appears only after reload" fixes need separate work? → A (codebase-derived): No. The affected Cubits switch from imperative `load()`/`refresh()`-after-mutation to watching local-database changes (FR-031). That covers user edits and sync-applied changes in one mechanism.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Everything keeps working with no connection (Priority: P1)

A user opens Daftary with no internet (airplane mode, poor signal, or a cloud outage). They add a person, record money given and received, edit and delete transactions, archive and restore people, add income and expense entries, and change exchange rates. Everything behaves exactly as it does today, with no errors, spinners or blocked actions. After closing and reopening the app while still offline, all of the data is still there.

**Why this priority**: Daftary is used today as a fully offline app. Any regression in offline behavior breaks existing users. This story is the non-negotiable baseline.

**Independent Test**: With networking disabled from a clean install and from an upgraded install, run the existing integration flows (`money_relationships_flows_test`, `finance_flows_test`, `currency_flows_test`, `archive_state_refresh_flow_test`). Then force-stop, relaunch and verify every record.

**Acceptance Scenarios**:

1. **Given** the device is offline, **When** the user creates a person and a transaction, **Then** both are saved and shown immediately, and balances update as they do today.
2. **Given** offline changes were made, **When** the app is killed and relaunched offline, **Then** every change is still present and still marked as waiting to sync.
3. **Given** the cloud service is down while the device has internet, **When** the user performs any action, **Then** the action succeeds locally and the user sees no blocking error.

---

### User Story 2 - Offline changes reach the cloud automatically (Priority: P1)

A user who made changes offline regains connectivity. Without doing anything, their pending changes are uploaded. Nothing is duplicated, lost or reordered, even if the connection drops halfway through or the app is closed during upload.

**Why this priority**: This is the core value of the feature: data protected off-device without extra effort from the user.

**Independent Test**: Make N offline mutations of every type, restore connectivity, and verify that the cloud holds exactly N effects with identical amounts, currencies, dates and ids. Repeat with the connection cut mid-upload, and with the app killed mid-upload.

**Acceptance Scenarios**:

1. **Given** 10 pending transactions, **When** connectivity returns, **Then** exactly 10 transactions exist in the cloud, with the same ids and amounts.
2. **Given** an upload succeeded in the cloud but the confirmation never reached the device, **When** the upload is retried, **Then** no duplicate is created and the local record becomes "synced".
3. **Given** a transaction was created and then edited while offline, **When** it syncs, **Then** the cloud holds the final edited values plus the audit history.
4. **Given** a transient failure occurs, **When** the retry policy runs, **Then** the operation is retried with backoff and eventually succeeds without user action.

---

### User Story 3 - Existing data is backed up on upgrade (Priority: P1)

A long-time user updates the app. All of their existing people, transactions, audit history, finance categories, entries, exchange rates and primary currency are kept locally untouched. Once sync becomes available, all of it is uploaded without creating duplicates.

**Why this priority**: The request explicitly forbids data loss for existing users. The upgrade is the moment of highest risk.

**Independent Test**: Build a schema-v8 database with representative data (following the pattern of the existing v4→v5 migration test), upgrade it, and verify that the local rows are byte-identical in their business fields. Then run the initial upload twice and verify cloud counts equal local counts.

**Acceptance Scenarios**:

1. **Given** a v8 database with data, **When** the app upgrades, **Then** every existing row is still present and readable, and is marked as not yet synced.
2. **Given** the initial upload was interrupted at 40%, **When** it resumes, **Then** it continues without duplicating the 40% already uploaded.
3. **Given** the migration fails partway, **When** the app starts, **Then** the database is left at the previous consistent state and the app still opens.

---

### User Story 4 - Remote changes appear without reloading (Priority: P2)

A user uses the same account on a second device, or restores onto a new device. Changes made elsewhere are downloaded when the app is online, merged into the local data, and appear on screen, including on screens that are already open, without the user pulling to refresh or reopening the screen.

**Why this priority**: Required for restore and multi-device use. It is secondary to protecting local data.

**Independent Test**: Insert or modify cloud records for the user directly. Bring the app online with Person Detail, Person List and Overview open, and verify that the changes appear without navigation.

**Acceptance Scenarios**:

1. **Given** Person Detail is open, **When** a sync downloads a new transaction for that person, **Then** the list and balance update without user action.
2. **Given** a person was archived on another device, **When** sync completes, **Then** they move from the active list to the archived list.
3. **Given** a record was deleted on another device, **When** sync completes, **Then** it disappears locally. Financial records are soft-deleted, never purged.

---

### User Story 5 - Conflicts on financial records are never silently resolved (Priority: P2)

The same transaction or finance entry is edited on two devices before either syncs. Instead of one edit silently overwriting the other, the app keeps both versions, flags the record as conflicted, and lets the user choose which version to keep.

**Why this priority**: The constitution forbids silent loss of financial data. Conflicts are rare (single user), so this is P2.

**Independent Test**: Create a divergent edit of one transaction locally and in the cloud, sync, and verify: the record is flagged; both versions can be seen; choosing either one resolves the conflict and syncs; the conflict-resolution history records the discarded version.

**Acceptance Scenarios**:

1. **Given** a local edit and a remote edit of the same transaction, **When** sync runs, **Then** the record is marked conflicted and neither version is discarded.
2. **Given** a conflicted record, **When** the user picks "keep mine", **Then** the local version is uploaded as a new revision and the remote version is kept in the conflict-resolution history.
3. **Given** a non-financial field conflict (for example a person's notes), **When** sync runs, **Then** it resolves automatically by the defined rule, with no prompt.

---

### User Story 6 - Sync status is visible but unobtrusive (Priority: P3)

In Settings, the user can see whether their data is backed up, when the last successful sync happened, how many changes are waiting, and any conflicts or permanently failed items. From there they can trigger "Sync now". Existing screens keep their current design.

**Why this priority**: This builds trust and supports diagnosis. The app is fully usable without it.

**Independent Test**: Put the app into each state (up to date, pending, syncing, offline, failed, conflict) and verify that the Settings section shows each one correctly in Arabic and in English.

**Acceptance Scenarios**:

1. **Given** 3 pending changes and no connection, **When** the user opens Settings, **Then** they see "3 changes waiting", "offline", and the last sync time.
2. **Given** a sync is already running, **When** the user taps "Sync now", **Then** no second sync starts.

---

### Edge Cases

- **Connected but unreachable**: Wi-Fi without internet access, a captive portal, or a cloud outage. The network is reported as present but requests fail. This is treated as a transient failure with backoff. The app is never blocked.
- **Upload succeeded, response lost**: A retry MUST be idempotent (keyed by the client id plus the operation id). The result is "already applied" and counts as success.
- **App killed mid-sync**: Queue entries that were "in flight" return to "pending" on the next start. Entries that were already applied resolve as idempotent success.
- **Created then deleted offline before any upload**:
  - *Money transactions and finance entries*: the create and the soft delete are both uploaded, because the audit trail must be kept.
  - *A person with no transactions*: the pending operations cancel out and nothing is uploaded.
- **Edited offline while a remote delete exists**: For financial records this is a conflict. The user chooses to restore with their edit or accept the delete. For people and categories, the delete wins only if the local edit is older than the delete. Otherwise the record is restored. The exact rule is in §10.
- **Hard-delete of a person who gained transactions on another device**: The server rejects the delete (a person with transactions cannot be deleted, FR-017 of spec 001). Locally the person is restored, archive is offered, and the queue entry is closed as a rejected-by-rule outcome.
- **Seeded categories**: Every install creates `seed_*` categories with the same ids. Across two devices for one user they MUST merge into one per id, never duplicate. Between two different users they MUST NOT collide. Unmodified ("pristine") seed rows are never uploaded as changes, so a fresh device cannot overwrite a category renamed on another device.
- **Exchange rate for the same pair created on two devices with different ids**: The currency pair is the natural key. They merge into one rate, with the later server-accepted write winning. No duplicate pairs.
- **Duplicate-looking people created on two devices** (same name, different ids): They are kept as two people. The existing rule "never silently merge" (spec 001 FR-003) still applies.
- **Clock skew**: A device clock that is wrong MUST NOT decide conflict outcomes or download ordering. Server-assigned revisions are used for both.
- **App version skew**: An older app build syncing a record that a newer build extended. Unknown cloud fields MUST be preserved and not wiped by the older client.
- **Very large backlog**: Thousands of pending operations, for example the initial upload of a heavy user. Upload is batched, resumable and non-blocking for the UI.
- **Session expired or revoked**: Sync pauses with an auth-failure state, local use continues, and sync resumes after the session is renewed. No local data is discarded.
- **Access rejected by row-level security**: This is treated as permanent for that operation (no hot retry loop). The operation is marked failed with a diagnostic code and surfaced in the status view.
- **Invalid data rejected by the server** (constraint violation): Marked failed with a reason code. The local record is kept. Other operations continue.
- **Queue ordering dependencies**: A transaction MUST NOT upload before its person, an entry before its category, or an audit entry before its transaction. A failed parent holds back its dependents only, not the whole queue.
- **Reinstall or new device**: The local database is empty and restore comes from the cloud. This depends on the identity model (Clarification Q1).
- **Storage full**: A local write fails with a `CacheFailure`, as it does today. The sync queue never becomes a partial write that is out of step with the business row (one atomic local transaction).

---

## Requirements *(mandatory)*

### Functional Requirements

#### 3. Offline-first behavior

- **FR-001**: The local database MUST remain the only source that screens read from. No screen, Cubit or use case may read directly from, or depend on, the cloud service.
- **FR-002**: Every create, update, delete, archive, restore and repayment MUST complete against local storage alone and report success to the user without waiting for the network.
- **FR-003**: A business write and its sync-queue entry MUST be recorded in the **same atomic local transaction**. Either both are saved or neither is.
- **FR-004**: The app MUST start, navigate and perform every existing flow with no network and with the cloud unreachable, with no added latency beyond today's local behavior.
- **FR-005**: The data in scope for sync is: people, money transactions, transaction audit entries, finance categories, finance entries, exchange rates and primary currency. Device preferences (language, theme, Liquid Glass, onboarding completion, notification preferences and history) MUST stay local-only.
- **FR-006**: Any future feature that adds user-owned financial data (budgets, savings goals, occasions, and so on) MUST adopt the same sync contract (stable id, owner, revision, tombstone, queue).

#### 4. Local database strategy

- **FR-007**: The existing local database MUST be extended through an additive schema migration (v8 → v9). Existing tables, columns, data and file location MUST NOT be dropped, renamed or recreated.
- **FR-008**: Every synced record MUST carry local sync metadata: sync state (`synced`, `pending`, `failed`, `conflict`), the last known server revision, and the time of the last successful sync.
- **FR-009**: Hard deletes of synced record types (person, finance category, exchange rate) MUST leave a local tombstone until the delete is confirmed by the cloud. Money transactions and finance entries keep their existing soft-delete.
- **FR-010**: The local database MUST keep one download cursor per owner: the highest server revision already applied. Server revisions are allocated per owner and commit in order, so a single cursor covers every synced type without gaps.

#### 5. Cloud data model (see §6 for the schema)

- **FR-011**: Every cloud record MUST belong to exactly one owner. The owner is part of the record's identity, so identical client ids from different owners never collide.
- **FR-012**: Cloud records MUST keep the client-generated id unchanged. The server MUST NOT reassign ids.
- **FR-013**: Money MUST be stored as integer minor units plus an ISO 4217 currency code. Exchange rates MUST be stored as integer micros. Floating-point or decimal-rounded money is prohibited.
- **FR-014**: Every cloud record MUST carry a server-assigned, monotonically increasing revision, and server timestamps for when it was received and last changed. The client's own timestamps (`created_at`, `edited_at`, `deleted_at`, `date`) are kept as business data, separate from the server's.
- **FR-015**: Cloud deletes of any synced type MUST be soft (tombstoned) so other devices can learn about them. Financial records MUST NEVER be physically purged by sync.
- **FR-016**: The cloud MUST enforce the same integrity rules as the app: positive amounts; a valid direction and kind; a category type that matches the entry type; a unique idempotency key per owner; a unique exchange-rate pair per owner; one primary currency per owner; a transaction whose person belongs to the same owner; and no hard delete of a person who has transactions.

#### 6/8. Synchronization

- **FR-017**: A dedicated sync process MUST perform **upload** (drain the local queue) and then **download** (apply remote changes since the cursor) in one sync cycle.
- **FR-018**: Only one sync cycle may run at a time per app process. A trigger that arrives while a cycle is running MUST be merged into one follow-up cycle, not started in parallel.
- **FR-019**: A sync cycle MUST be triggered by: app launch, app returning to the foreground, connectivity restored, a local write (debounced, default 3 s), a periodic timer while in the foreground (default 5 min), and the manual "Sync now".
- **FR-020**: Download MUST be incremental. Only records with a server revision above the stored cursor are fetched, in pages (default 500). Full-table downloads are allowed only for first-time restore.
- **FR-021**: Applying downloaded records MUST be atomic per page, and MUST NOT overwrite a local record that has pending unsynced changes. Such cases go to conflict handling (§10).
- **FR-022**: Downloaded tombstones MUST remove or hide the record locally using the same semantics the app already uses: soft-delete for financial records, removal for people, categories and rates.
- **FR-023**: Background sync while the app is terminated is **not required**. Sync runs while the app is open.

#### 9. Sync queue

- **FR-024**: Every pending local change MUST be kept as a queue entry containing: operation id (unique, used as the idempotency key), entity type, entity id, operation type (`upsert` or `delete`), a snapshot of the record at enqueue time, the base server revision the change was made against, the enqueue time, attempt count, last attempt time, next eligible attempt time, status (`pending`, `in_flight`, `failed`, `conflict`, `done`), and an error **code**. The error code MUST NOT contain the record's contents.
- **FR-025**: Consecutive pending operations on the same record MUST be combined where this is safe: create followed by update becomes a single create with the latest snapshot, and update followed by update becomes the latest update. Coalescing MUST NOT drop audit entries, and MUST NOT combine a financial record's create and delete into nothing.
- **FR-026**: The queue MUST be processed in dependency order: people and categories first, then transactions and entries, then audit entries. It is FIFO within each type.
- **FR-027**: Every upload MUST be idempotent. Replaying the same operation any number of times MUST produce the same cloud state, with no duplicate rows and no duplicate audit entries.
- **FR-028**: Transient failures (network, timeout, 5xx, rate limit) MUST be retried with exponential backoff and jitter (default: base 5 s, cap 15 min). There is no limit on the number of attempts while the failure stays transient.
- **FR-029**: Permanent failures (validation, access rejected by row-level security, a rule violation) MUST mark the operation as `failed` without hot retry. They MUST be visible in the sync status view with a user-readable reason, and MUST be retryable after the cause is fixed (for example after re-authentication). A failed operation MUST NOT block unrelated operations.

#### 7. Repository and reactive reads

- **FR-030**: Repository contracts in the Domain layer MUST NOT expose cloud concepts. Sync MUST be invisible to use cases, except for a separate, dedicated sync-status contract.
- **FR-031**: Screens showing synced data MUST update automatically when the underlying local data changes, whether the change comes from a user action or from sync. This applies at least to: Person List, Archived People, Person Detail (history and balance), Overview, Finance History, Finance Month Summary, Category Management, and the Exchange Rate List.
- **FR-032**: The existing refresh-after-mutation behavior from specs 004 and 005 MUST keep working. Automatic updates MUST NOT cause duplicate list entries, flicker or loss of scroll position.
- **FR-033**: Balance and overview calculations MUST remain deterministic and local (constitution Principle VIII), computed from local data only.

#### 10. Conflict resolution

- **FR-034**: Conflicts MUST be detected by comparing the base revision in a pending operation with the current server revision. Device timestamps MUST NOT be used to detect or resolve conflicts.
- **FR-035**: **Money transactions and finance entries**: when an update or delete from the device is based on a stale revision, and the server version has changed business fields, the record MUST go into the `conflict` state. The server version and the local version are both kept, and the user resolves it (keep mine, keep theirs). Until the user resolves it, the local version is shown and the record is marked. Every resolution MUST be written to an append-only, synced **conflict-resolution history**, which records the discarded version. Existing audit change types are not extended, because older clients reject unknown audit types. Audit entries recorded for a local edit that is later discarded ("keep theirs") are still uploaded unchanged. They truthfully record that the edit happened, and the conflict-resolution record, which references the same transaction id, records that it was discarded. Audit history is never rewritten or deleted.
- **FR-036**: **Transaction audit entries**: append-only, so they never conflict. Duplicates are prevented by id.
- **FR-037**: **People, finance categories, primary currency**: resolved automatically, at record level, by **last-write-wins in server-accepted order**. Exceptions:
  - (a) Archive and unarchive follow the same rule.
  - (b) A delete loses against a concurrent edit (the record is restored).
  - (c) A person delete is rejected if the person has any transaction.
  - (d) A category delete falls back to archive if any entry references it.
- **FR-038**: **Exchange rates**: the currency pair is the natural key, and a rate's id is derived from it (existing random ids are rewritten by the v9 migration; nothing references them), resolved by last-write-wins in server-accepted order. Creating the same pair on two devices converges to one rate.
- **FR-039**: Resolving a conflict MUST create a new revision that is uploaded through the normal queue. No path may discard a financial record's version without recording it in the conflict-resolution history.

#### 12. Identity, security and row-level security

- **FR-040**: Every synced cloud record MUST be linked to an authenticated owner identity. The identity is created by a silent anonymous sign-in on the first online launch, with no screen shown. Settings offers an optional "Link email" (one-time code) that keeps the same owner id. On another device, signing in with that email merges the device's local data into the account. Local data is never deleted by an identity change.
- **FR-041**: Cloud sync MUST be on by default. A one-time, dismissible notice explains it. A Settings switch turns it off, and while it is off the app makes no network request. Local changes MUST still be queued while sync is off.
- **FR-042**: Every cloud table MUST have row-level security enabled, with policies that let a user read and write **only** rows they own. Ownership MUST be derived from the authenticated session on the server, never trusted from the client payload.
- **FR-043**: The app MUST use only the project URL and the **publishable (anon) key**. These are supplied at build time through environment configuration (development, staging and production), MUST NOT be committed to source control, and MUST NOT appear in business logic. Service-role keys, database passwords and other privileged credentials MUST NEVER be present in the app or its repository.
- **FR-044**: Session tokens MUST be stored in the platform's secure storage (constitution Principle XII), not in plain preferences.
- **FR-045**: The data sent to the cloud MUST be limited to what is needed to restore the user's data. The local file path of a person's avatar image is device-specific, is not uploaded, and is not synced. Uploading the image file itself is out of scope. A person's phone number and notes ARE synced, protected by FR-042.
- **FR-046**: Aggregate and analytics views in the cloud MUST enforce the same owner-only row-level security as the tables beneath them.

#### 13. Migration of existing data

- **FR-047**: On upgrade, the v9 migration MUST: add the sync metadata and queue structures; mark every existing synced-type row as `pending`; and enqueue it for upload. It MUST NOT change any business field.
- **FR-048**: The migration MUST run inside the existing migration mechanism, so a failure rolls back to v8 and the app still opens with the v8 data (matching the existing migration practice).
- **FR-049**: The initial upload MUST be batched, resumable and idempotent (FR-027). Re-running it after an interruption MUST NOT duplicate records.
- **FR-050**: The first sync for an identity that already has cloud data (restore or second device) MUST merge: download remote records, upload local-only records, and resolve id collisions per §10 (seeded categories merge by id).

#### 11. Connectivity

- **FR-051**: The app MUST observe changes in network connectivity and use them only as a **hint** to schedule sync. A successful cloud request is the only proof that the cloud is reachable.
- **FR-052**: When the network is reported as absent, the sync process MUST NOT attempt requests. It MUST resume on the next "network available" signal or on the next trigger.
- **FR-053**: When the connection is unstable (flapping), the triggers MUST be coalesced (FR-018), and backoff state MUST persist across triggers so that flapping does not cause a request storm.
- **FR-054**: Every cloud request MUST have a timeout (default 20 s). A timeout counts as a transient failure.

#### 15. Error handling

- **FR-055**: The Data layer MUST map sync errors to typed failures: no network, cloud unavailable, timeout, authentication failure, access rejected by row-level security, validation or constraint rejection, conflict, duplicate (already applied, which is treated as success), download failure, and partial sync.
- **FR-056**: No sync error may surface as a blocking error on an existing screen. Sync errors appear only in the sync status view, as localized, user-friendly messages in Arabic and English.
- **FR-057**: A partial sync (some operations succeed, some fail) MUST commit the successes, keep the failures queued, and advance the download cursor only past pages that were fully applied.

#### 16. Observability

- **FR-058**: The sync process MUST emit structured log events for: sync started, sync completed or aborted (with duration), operations uploaded, records downloaded, operations failed (with error code and entity type), retry scheduled (with delay), conflict detected (with entity type), and cursor advanced.
- **FR-059**: Logs MUST NEVER contain amounts, names, phone numbers, notes, tokens or keys. They may contain entity types, counts, opaque record ids, error codes and durations. Verbose sync logging MUST be disabled in production builds.
- **FR-060**: The app MUST record on each device: last sync attempt, last successful sync, pending count, failed count and conflict count. This supports the status view and diagnostics.

#### 14. Analytics readiness

- **FR-061**: The cloud schema MUST support, without any schema change, owner-scoped calculation of: total given, total received, net and outstanding balances (per currency and per person), transaction counts, number of people (active and archived), people with outstanding balances, the most active relationships, transaction frequency by day, month and year, the distribution of transaction kind and direction, income and expense by category and period, the average transaction amount, and archived and deleted counts.
- **FR-062**: Each record MUST keep both the client-recorded time (when the user performed the action) and the server-received time. The gap between them measures offline activity.
- **FR-063**: The cloud MUST provide owner-scoped aggregate views for monthly activity and totals so that future reports do not need to download raw rows. **No analytics UI is built in this feature.**
- **FR-064**: A minimal per-device record (device id, platform, app version, first seen, last sync) MAY be stored to diagnose sync and understand usage patterns. It MUST NOT include hardware identifiers, location, contacts or behavioral tracking.

### Key Entities

- **Owner**: The authenticated identity that owns all cloud data. It holds no profile data beyond what the identity provider requires.
- **Person**: A counterparty with a name, optional phone, relationship tag, notes and archived flag. It has many Money Transactions.
- **Money Transaction**: An amount in minor units with a currency, a direction (given or received), a kind (initial exchange or repayment), a business date, an optional note, an idempotency key, and edited and deleted markers. It belongs to one Person.
- **Transaction Audit Entry**: An immutable record of an edit or delete of a Money Transaction, holding the previous values. Conflict resolutions are also recorded here.
- **Finance Category**: An income or expense label (seeded or user-created) with an icon key and an archived flag.
- **Finance Entry**: A personal income or expense amount with a currency and a date. It belongs to one Finance Category.
- **Exchange Rate**: A manual rate for a currency pair, stored as an integer scaled by 10^6.
- **Primary Currency**: The owner's single reporting currency.
- **Sync Queue Entry** (local only): One pending change awaiting upload, with retry and status bookkeeping.
- **Sync Cursor** (local only): The highest server revision applied, per entity type.
- **Conflict Resolution Record** (synced, append-only): the entity type and id, the side chosen, the discarded version, and when it was resolved.
- **Sync Conflict** (local only): The paired local and server versions of a financial record awaiting the user's decision.
- **Device** (cloud, optional): A diagnostic record per install.

---

## 6. Cloud Schema *(design constraint requested by stakeholder)*

The logical design is below. **[contracts/supabase-schema.md](contracts/supabase-schema.md) is the authoritative definition.** Where this summary differs (for example, the contract adds `occurred_at` and `tz_offset_minutes` next to `occurred_on`, and indexes `(owner_id, person_id)`), the contract wins.

**Common columns on every synced table**:

- `owner_id uuid not null`: defaults to the authenticated user and is enforced by row-level security.
- `id text not null`: the client id. **Primary key is `(owner_id, id)`**.
- `revision bigint not null`: set by the server on every write from one global sequence, and indexed as `(owner_id, revision)` for incremental download.
- `client_created_at`, `client_updated_at timestamptz`: from the device (business and analytics time).
- `server_created_at`, `server_updated_at timestamptz`: set by the server.
- `deleted_at timestamptz null`: the tombstone.
- `last_modified_by_device uuid null`: diagnostic.

| Table | Business columns | Constraints and indexes |
|-------|------------------|-------------------------|
| `people` | `name`, `normalized_name`, `phone_number`?, `relationship_tag`, `notes`?, `is_archived` | idx `(owner_id, normalized_name)`, idx `(owner_id, is_archived)` |
| `money_transactions` | `person_id`, `amount_minor bigint > 0`, `currency_code char(3)`, `direction` (given/received), `kind` (initialExchange/repayment), `occurred_on` (business date), `note`, `edited_at`, `idempotency_key` | FK `(owner_id, person_id) → people`; **unique `(owner_id, idempotency_key)`**; idx `(owner_id, person_id, deleted_at)`, idx `(owner_id, occurred_on)` |
| `transaction_audit_entries` | `transaction_id`, `change_type`, `previous_values jsonb`, `changed_at` | FK → `money_transactions`; insert-only (update and delete denied by policy) |
| `finance_categories` | `name`, `normalized_name`, `type` (income/expense), `icon_key`, `is_default`, `is_archived` | idx `(owner_id, normalized_name, type)` |
| `finance_entries` | `category_id`, `type`, `amount_minor bigint > 0`, `currency_code`, `occurred_on`, `note`, `edited_at`, `idempotency_key` | FK → categories; unique `(owner_id, idempotency_key)`; idx `(owner_id, occurred_on)`, idx `(owner_id, category_id)`; the type must match the category (trigger) |
| `exchange_rates` | `currency_code`, `relative_to_currency_code`, `rate_micros bigint > 0` | **unique `(owner_id, currency_code, relative_to_currency_code)`** where not deleted |
| `primary_currency` | `currency_code` | PK `owner_id` (one row per owner) |
| `devices` (optional) | `platform`, `app_version`, `first_seen_at`, `last_sync_at` | PK `(owner_id, device_id)` |

**Server functions**:

- An idempotent, version-checked **upsert** per entity (or one batched RPC). It takes the operation id and base revision, and returns `applied`, `already_applied`, `conflict` (with the server row) or `rejected` (with a reason code).
- An operation-id ledger that makes replays no-ops.
- Triggers that assign `revision` and `server_updated_at`.
- A guard that blocks deleting a person who has transactions.
- A guard that turns a category delete into archive while entries reference it.

**Analytics views** (security invoker, owner-scoped): monthly totals by owner, currency and direction; balance per person and currency; monthly income and expense by category; counts of activity per day.

---

## 17. Testing Strategy

| Layer | Must cover |
|-------|------------|
| Local DB (unit, in-memory database) | Create, read, update, delete, archive, restore for every synced type; each write enqueues exactly one coalesced operation atomically; tombstones; a v8→v9 migration test built from a raw v8 file, following the existing v4→v5 test pattern |
| Queue (unit) | Coalescing rules; dependency ordering; backoff schedule; in-flight recovery after a crash; that a failed parent blocks only its dependents |
| Sync process (unit, fake remote) | Upload of pending operations; download since the cursor; pagination; idempotent replay (the same operation 3 times gives 1 row); response lost after commit; partial success; cursor advance only on full pages; single-flight guard; every failure-type mapping |
| Conflicts (unit) | Financial edit/edit, edit/delete, delete/edit; auto-resolution for people and categories; exchange-rate pair convergence; seeded-category merge; that a person delete is rejected when a remote transaction exists; audit entry on resolution |
| Connectivity (unit) | offline→online triggers sync; online→offline aborts cleanly; flapping coalesces; "network present but cloud unreachable" is treated as transient |
| Cubits (bloc_test) | Affected Cubits emit updated state when local data changes from sync; no duplicate emissions |
| Cloud (database tests) | Row-level security: user A cannot read or write user B's rows in any table or view; the unique and check constraints; that the idempotent upsert behaves as specified |
| Integration (device) | All existing integration flows pass offline; create, update and delete offline, then restart offline and verify data; reconnect → the cloud matches; interrupted initial upload resumes without duplicates |
| Regression | The entire existing test suite passes unchanged, apart from mechanical updates required by the new dependency injection |

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of existing user flows complete successfully with the device offline, with no user-visible error and no added delay compared with the current release.
- **SC-002**: 0 business records lost or altered by the upgrade, across a migration test corpus that includes the largest realistic dataset (≥ 5,000 transactions).
- **SC-003**: 0 duplicate transactions or entries in the cloud after any combination of retries, crashes and connectivity drops in the test matrix.
- **SC-004**: Pending changes begin uploading within 10 seconds of connectivity returning while the app is open, and 1,000 pending changes finish uploading within 60 seconds on a typical 4G connection.
- **SC-005**: Changes made on another device appear on an open screen within 10 seconds of a sync completing, without user action.
- **SC-006**: 100% of concurrent edits to financial records result in a visible conflict that the user can resolve. 0 are silently overwritten.
- **SC-007**: In testing, 0 rows belonging to another user can be read or written through the app's credentials.
- **SC-008**: 0 secrets and 0 financial or personal values appear in source control or in production logs (verified by a repository scan and a log review).
- **SC-009**: The existing test suite and Android and iOS release builds pass with no UI or design change to existing screens (the only UI added is the Settings sync section).
- **SC-010**: Every analytics question listed in FR-061 can be answered by a single owner-scoped query against the cloud schema.

---

## 19. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| This reverses the roadmap's "no backend" decision and the local-only promise made to existing users | Trust, privacy expectations | Clarification Q2 (opt-in vs default); update ROADMAP-PLAN; a clear disclosure in the app |
| Identity loss (for example anonymous identity plus reinstall) disconnects the user from their cloud copy | The backup is unreachable | Clarification Q1; offer account linking |
| Repositories are Future-based; adding reactive reads touches many Cubits | Regression risk against the 004/005 fixes | Limit to the screens in FR-031; bloc_test coverage; keep the imperative reload path |
| Seeded category ids are the same everywhere | Primary key collisions between users | Owner-scoped primary key (FR-011) |
| Hard-delete semantics (people, categories, rates) have no history | A delete cannot be propagated | Tombstones (FR-009, FR-015) |
| Device clock skew | Wrong ordering or conflict outcomes | Server revisions only (FR-014, FR-034) |
| Large initial upload on older, heavy installs | Slow or failed first sync | Batching and resumable upload (FR-049) |
| App version skew between devices | Newer fields wiped by older clients | Server merges payloads and preserves unknown fields; version-gated schema changes |
| Supabase free-tier limits or project pausing | Sync unavailable | Offline-first design tolerates the outage; surfaced in the status view |

---

## 20. Dependencies and Package Changes

| Package | Purpose | Notes |
|---------|---------|-------|
| `supabase_flutter` | Cloud client, authentication, session | Requested by stakeholder. Used only inside the Data layer's remote data source. |
| `connectivity_plus` | Hint that network connectivity has changed (FR-051) | Not proof of reachability. |
| `flutter_secure_storage` | Session storage (FR-044) | Plugs into the client's session-storage hook. |
| *(existing)* `drift`, `sqlite3_flutter_libs`, `uuid`, `fpdart`, `get_it`/`injectable`, `flutter_bloc` | Reused | No replacement. |

**Build configuration**: The URL and publishable key are supplied at build time from an environment file that is excluded from git. A template file with placeholder values is committed.

**Tooling (dev only, optional)**: Supabase CLI for schema migrations and row-level security tests. The `supabase/agent-skills` package is already available in this environment as the `supabase` and `supabase-postgres-best-practices` skills, so no install is needed.

**Supabase Realtime**: **Not used in this feature.** Daftary has a single owner per dataset. Remote changes only come from that same user's other devices, and that user is rarely active on two devices at the same moment. Pulling on launch, foreground, reconnect, local write and a 5-minute timer delivers remote changes within seconds of use, without holding a permanent socket (which costs battery and data and needs reconnect handling). The download path is designed so that Realtime can later act as just one more trigger, without architectural change.

---

## Assumptions

- The Supabase project exists at `https://nnrmghwqihqnmtnuxzoq.supabase.co`, and its publishable key will be supplied by the team through the environment configuration, not in the spec or the repository.
- Supabase **Anonymous Sign-ins** can be enabled on the project if Q1 resolves that way.
- One owner has at most a handful of devices. Shared or family finances between different owners remain out of scope (roadmap V3.6).
- Sync runs only while the app is in the foreground. OS background-fetch scheduling is out of scope.
- Avatar image files are not uploaded. A synced person arrives on a new device without an avatar.
- There is no cloud data yet, so no cloud-side migration of legacy data is needed.
- The default values for timers, backoff, page size and timeouts may be tuned during planning without re-specification.
- The minimal Settings sync section is the only UI change. It follows the existing design system and the Arabic/English localization rules.

---
