# Phase 1 Data Model: Proactive Insights & Reminders/Notifications

## Entity: NotificationPreference (NEW, `drift` table)

Single record per device (not a list).

| Field | Type | Notes |
|---|---|---|
| `isEnabled` | `bool` | Whether this feature is on at all. Default `false` (FR-010). |
| `budgetWarningsEnabled` | `bool` | Independently toggleable (FR-009). Default `true` once `isEnabled` is first turned on. |
| `savingsCheckInsEnabled` | `bool` | Independently toggleable (FR-009). Default `true` once `isEnabled` is first turned on. |
| `quietHoursStart` | `TimeOfDay?` (stored as minutes-since-midnight `int?`) | `null` = no quiet hours configured (Assumptions: off by default). |
| `quietHoursEnd` | `TimeOfDay?` (stored as minutes-since-midnight `int?`) | Paired with `quietHoursStart`; both null or both set. |
| `osPermissionGranted` | `bool` | Last-known OS permission state, refreshed whenever checked (FR-012) — not the source of truth for the OS's actual permission (always re-verified live before scheduling), but used to drive the settings UI's denied-state banner without an extra async round-trip on every render. |

## Entity: NotificationHistoryEntry (NEW, `drift` table)

One row per (source, applicable period) — the cooldown/re-notification bookkeeping described in FR-015/FR-016.

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | Primary key. |
| `sourceType` | enum: `budgetCategory`, `savingsGoal` | Discriminates which threshold-band vocabulary applies. |
| `sourceId` | `String` | The `Budget`+category composite key (010) or `SavingsGoal.id` (011) this row tracks. |
| `applicablePeriod` | `String?` | For `budgetCategory`: the budget's month (e.g. `2026-09`), since a new month resets the band (FR-016). `null` for `savingsGoal` (goals aren't month-scoped). |
| `lastNotifiedBand` | `ThresholdBand` (enum, stored as string) | The band value at the last notification for this source+period — compared against the newly-computed band on each recomputation; a notification is generated only when the newly-computed band differs from this stored value (research.md Decision 2/spec Assumptions). |
| `lastNotifiedAt` | `DateTime` | For diagnostics/testing (SC-003's "exactly one notification" assertion), not itself part of the cooldown logic (which is band-based, not time-based). |

**Uniqueness**: `UNIQUE(sourceType, sourceId, applicablePeriod)` — upserted (never duplicated) on each recomputation, satisfying constitution Principle XI's idempotency expectation even though this is local-only bookkeeping, not a financial mutation.

## Value Object: ThresholdBand *(enum, not independently persisted — stored as a field on NotificationHistoryEntry)*

```text
For sourceType = budgetCategory:  belowWarning | nearLimit | exceeded
For sourceType = savingsGoal:     onPace | behindPace | aheadOfPace | achieved | noEstimateAvailable
```

`noEstimateAvailable` (FR-005) and any goal with `isAchieved` already true before this feature ever evaluated it never produce a notification on the *first* transition into that state from "unknown" — only a transition between two states that were both previously known and different triggers a notification, avoiding a spurious first-ever "achievement" notification for a goal that was already complete when the user first enabled this feature (an edge case beyond spec's own FR-006 wording, resolved here for implementation clarity).

## Value Object: ComposedNotification *(ephemeral, not persisted)*

| Field | Type | Notes |
|---|---|---|
| `title` | `String` | Localized, populated from a `gen_l10n` parameterized template (research.md Decision 3). |
| `body` | `String` | Localized, same. |
| `deepLinkTarget` | `NotificationDeepLinkTarget` | `{type: budgetCategory | savingsGoal, id: String}` — consumed by `HandleNotificationTap` (FR-014). |

## Relationships

```text
NotificationPreference  — single record, no relationships (device-level config)

NotificationHistoryEntry ──N:1(logical, not FK-enforced)── Budget category (010, external feature)
NotificationHistoryEntry ──N:1(logical, not FK-enforced)── SavingsGoal (011, external feature)
```

**Deliberately no foreign-key constraint** from `NotificationHistoryEntry.sourceId` into 010's/011's own tables: this feature's own `drift` migration must not take a hard schema dependency on tables owned by another feature's migration (which may not even be applied yet in a given build, since 010/011 are specified-but-not-necessarily-implemented at the time this feature is specified, per spec.md Assumptions' "Dependency posture"). A stale `sourceId` (pointing at a since-deleted budget/goal) is handled gracefully at read time (spec Edge Cases: tapping a stale notification shows a "no longer exists" state), not prevented at the schema level.

## Drift Schema Sketch (for Phase 2 task planning, not exhaustive DDL)

```text
NotificationPreferences (single row, id fixed e.g. 'default')
  id TEXT PRIMARY KEY
  is_enabled INTEGER NOT NULL DEFAULT 0
  budget_warnings_enabled INTEGER NOT NULL DEFAULT 1
  savings_check_ins_enabled INTEGER NOT NULL DEFAULT 1
  quiet_hours_start_minutes INTEGER NULL
  quiet_hours_end_minutes INTEGER NULL
  os_permission_granted INTEGER NOT NULL DEFAULT 0

NotificationHistory
  id TEXT PRIMARY KEY
  source_type TEXT NOT NULL          -- 'budgetCategory' | 'savingsGoal'
  source_id TEXT NOT NULL
  applicable_period TEXT NULL        -- e.g. '2026-09', null for savingsGoal
  last_notified_band TEXT NOT NULL
  last_notified_at INTEGER NOT NULL  -- unix millis
  UNIQUE INDEX idx_notification_history_source (source_type, source_id, applicable_period)
```

Both tables are additive; `AppDatabase.schemaVersion` increments by 1 from whatever value it holds when this feature is implemented (after 007/010/011's own prior increments). Zero changes to any existing table, including `Budgets`/`SavingsGoals`/`SavingsContributions` owned by 010/011.
