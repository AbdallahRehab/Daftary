# Phase 1 Data Model: Savings Goals

Derived from the spec's Key Entities section and the Phase 0 research decisions (derived current amount, starting amount as a first contribution, blocked over-withdrawal, derived reversible achieved status). All money fields are integer minor units (piastres) via the existing `Money` type; all timestamps are UTC `DateTime`. This feature shares no entity with, and adds no column to, any existing feature's tables (001/007/008/009/010).

## Entity: SavingsGoal (NEW)

A named target the user is saving toward.

| Field | Type | Rules |
|---|---|---|
| `id` | `String` (UUID) | Primary key |
| `idempotencyKey` | `String` (UUID) | **Unique index.** Client-generated once per creation save action; a retried insert with the same key is a no-op returning the existing row (FR-022) |
| `name` | `String` | Required, non-empty after trim (FR-001) |
| `type` | `String?` | Optional; one of the standard set (`emergencyFund`, `newCar`, `wedding`, `vacation`, `newPhone`, `homeFurniture`, `education`, `other`) or `null` for a plain custom-named goal with no type — cosmetic only (Assumptions), same free-form pattern as `Person.relationshipTag`/`Occasion.type` |
| `targetAmountMinorUnits` | `int` | Required, `> 0` (FR-002) |
| `monthlyContributionMinorUnits` | `int?` | Optional; if present, `> 0` (FR-002 — zero/negative rejected, but the field itself may be entirely absent) |
| `targetDate` | `DateTime?` (date-only) | Optional; if present, MUST be strictly after the current date at the time it is set (FR-003) |
| `isArchived` | `bool` | Default `false`. `true` hides the goal from the active goals list/overview while preserving it (FR-020) |
| `createdAt` | `DateTime` | Set once on creation |
| `updatedAt` | `DateTime` | Updated on every edit (name/type/target/monthly contribution/target date, archive/restore) |
| `deletedAt` | `DateTime?` | Soft-delete tombstone; set only when a zero-contribution-history goal is permanently deleted (FR-021) |

**Validation rules**:
- `name` MUST be non-empty (trimmed). No uniqueness constraint (Assumptions — unlike `Person`).
- `targetAmountMinorUnits > 0` (FR-002).
- `monthlyContributionMinorUnits`, if present, MUST be `> 0`.
- `targetDate`, if present, MUST be strictly after "today" at the moment it is set or edited (FR-003) — enforced at write time, not continuously (a target date that was valid when set and has since passed through normal calendar progression is not retroactively rejected; it simply means the goal is now overdue, which the completion display should reflect honestly, not error on).
- At least one of `monthlyContributionMinorUnits`/`targetDate` MAY be absent at creation (FR-001 Acceptance Scenario 6) — a goal with neither is valid, just without an estimated-completion figure until one is set (FR-010/FR-011 both require at least one to be present).

**Derived (not stored)**: `currentAmountMinorUnits` (research.md Decision 2), `remainingMinorUnits`, `percentageProgress`, `isAchieved` (research.md Decision 6), `estimatedCompletion` — see `GoalProgress` below. None of these are stored columns.

**Lifecycle**: `active → archived → active` (restore, FR-020). A goal with zero `SavingsContribution` rows may be hard-deleted (`active → deleted`, FR-021); a goal with any contribution/withdrawal history is never hard-deleted, only archived — identical rule shape to `Person` (001).

## Entity: SavingsContribution (NEW)

A single logged deposit or withdrawal against one `SavingsGoal`.

| Field | Type | Rules |
|---|---|---|
| `id` | `String` (UUID) | Primary key |
| `idempotencyKey` | `String` (UUID) | **Unique index.** Per FR-022/research.md Decision 7 |
| `goalId` | `String` (FK → `SavingsGoal.id`) | Required |
| `type` | enum `contribution` \| `withdrawal` | Required (FR-005/FR-006) |
| `amountMinorUnits` | `int` | Required, `> 0` regardless of `type` — direction is carried by `type`, never by sign (FR-007) |
| `date` | `DateTime` (date-only) | Defaults to today, user-editable (FR-005) |
| `note` | `String?` | Optional; system-generated note (e.g. "Starting amount") for the initial contribution created alongside a new goal with a non-zero starting amount (research.md Decision 3) |
| `createdAt` | `DateTime` | Set once on creation |
| `editedAt` | `DateTime?` | Set on any field edit (FR-009); `null` means never edited |
| `deletedAt` | `DateTime?` | Soft-delete tombstone; `null` means active (FR-009's delete path) |

**Validation rules**:
- `amountMinorUnits > 0` for both `contribution` and `withdrawal` rows (FR-007).
- A `withdrawal` row is rejected at write time if `amountMinorUnits` exceeds the goal's current computed balance (Decision 2's live aggregate, evaluated over all *other* non-deleted rows for that goal) — `WithdrawalExceedsBalanceFailure` (FR-006, research.md Decision 5). An *edit* to an existing withdrawal is validated the same way, excluding the row being edited from the "current balance" check against itself.
- Same decimal-precision and maximum-amount ceiling as `MoneyTransaction`/`FinanceEntry` (FR-007).

**State transitions**: `created → [edited]* → [deleted]`. Mirrors `MoneyTransaction`'s (001) and `FinanceEntry`'s (007) shape exactly: `type` is fixed at creation (not offered as an edit field — reclassifying a contribution as a withdrawal or vice versa means delete + re-create, same convention as `MoneyTransaction.kind`).

## Value Object: GoalProgress *(derived, not persisted)*

Computed on demand for one `SavingsGoal`, combining its stored fields with its `SavingsContribution` history via `SavingsCalculator` (research.md Decision 1).

| Field | Type | Derivation |
|---|---|---|
| `goalId` | `String` | — |
| `currentAmountMinorUnits` | `int` | `SUM(amount WHERE type=contribution) − SUM(amount WHERE type=withdrawal)` over non-deleted `SavingsContribution` rows for this goal (research.md Decision 2) |
| `remainingMinorUnits` | `int` | `max(0, targetAmountMinorUnits − currentAmountMinorUnits)` — never negative; an over-achieved goal shows `0` remaining, not a negative figure |
| `percentageProgress` | `double` | `min(100, currentAmountMinorUnits / targetAmountMinorUnits * 100)` — capped at 100% for display even when over-achieved |
| `isAchieved` | `bool` | `currentAmountMinorUnits >= targetAmountMinorUnits` (FR-017, research.md Decision 6 — reversible, not stored) |
| `estimatedCompletion` | `EstimatedCompletion?` | See below. `null` when the goal has neither `monthlyContributionMinorUnits` nor `targetDate` set, or when already achieved (nothing left to estimate) |

## Value Object: EstimatedCompletion *(derived, not persisted)*

| Field | Type | Derivation |
|---|---|---|
| `estimatedMonths` | `int?` | When `monthlyContributionMinorUnits` is set: `ceil(remainingMinorUnits / monthlyContributionMinorUnits)` (FR-010, Assumptions: always rounded up). `null` if `monthlyContributionMinorUnits` is not set. |
| `estimatedDate` | `DateTime?` | `today + estimatedMonths` (calendar-month arithmetic via `core/date`), when `estimatedMonths` is present |
| `requiredMonthlyContributionMinorUnits` | `int?` | When `targetDate` is set: `ceil(remainingMinorUnits / monthsBetween(today, targetDate))` (FR-011). `null` if `targetDate` is not set. `monthsBetween` uses whole calendar months remaining, minimum `1` (a target date within the current month still requires at least one month's worth of contribution, never a division by zero) |
| `hasShortfall` | `bool` | `true` when both `monthlyContributionMinorUnits` and `targetDate` are set and `estimatedDate` falls after `targetDate` (FR-012) — triggers the "honest mismatch" display, never silently resolved |
| `shortfallMonths` | `int?` | When `hasShortfall`, the whole-month gap between `estimatedDate` and `targetDate`, for the "you'll reach this N months after your target" message (FR-012) |

## Value Object: WhatIfResult *(ephemeral, not persisted)*

Produced by `CalculateWhatIfMonthlyContribution`/`CalculateWhatIfCompletionDate` (FR-013/FR-014). Never written to the database — exists only for the duration of the calculator interaction (Key Entities: "What-If Scenario").

| Field | Type | Derivation |
|---|---|---|
| `hypotheticalMonthlyContributionMinorUnits` | `int?` | The what-if input (for the "what if I save X more" direction) or the calculated result (for the "what contribution do I need by date Y" direction) |
| `hypotheticalTargetDate` | `DateTime?` | The what-if input (for the "by date Y" direction) or the calculated result (for the "what if I save X more" direction) |
| `estimatedMonths` | `int?` | Recomputed via the same `SavingsCalculator` formulas as `EstimatedCompletion`, applied to the hypothetical input instead of the goal's real stored fields |

**Rule**: Applying a `WhatIfResult` (FR-015, `ApplyWhatIfScenario`) is the *only* write path that can set `SavingsGoal.monthlyContributionMinorUnits`/`targetDate` from a what-if exploration — `CalculateWhatIfMonthlyContribution`/`CalculateWhatIfCompletionDate` never call `SavingsRepository` at all (research.md Decision 1), which is what makes this rule structurally, not just behaviorally, true.

## Relationships

```
SavingsGoal (1) ──< (many) SavingsContribution
```

- No relationship to `Person`, `MoneyTransaction`, `Occasion`, `Category`, `FinanceEntry`, or `Budget` — this feature is entirely independent (FR-026, Assumptions).
- Deleting a `SavingsGoal` is only possible when it has zero `SavingsContribution` rows (including soft-deleted ones, to keep any residual audit trail attributable, mirroring 001's identical rule for `Person`); otherwise the delete is blocked and the UI offers archiving instead (FR-021).
- `GoalProgress`/`EstimatedCompletion` are read-model views over `SavingsGoal` + `SavingsContribution` — not separate write paths. `WhatIfResult` is not persisted at all.

## Drift Schema Sketch (for Phase 2 task planning, not exhaustive DDL)

```
Table SavingsGoals (
  id TEXT PRIMARY KEY,
  idempotency_key TEXT NOT NULL,
  name TEXT NOT NULL,
  type TEXT NULL,
  target_amount_minor_units INTEGER NOT NULL,
  monthly_contribution_minor_units INTEGER NULL,
  target_date INTEGER NULL,
  is_archived BOOLEAN NOT NULL DEFAULT FALSE,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER NULL
)
UNIQUE INDEX idx_savings_goals_idempotency_key ON SavingsGoals(idempotency_key)

Table SavingsContributions (
  id TEXT PRIMARY KEY,
  idempotency_key TEXT NOT NULL,
  goal_id TEXT NOT NULL REFERENCES SavingsGoals(id),
  type TEXT NOT NULL,                       -- 'contribution' | 'withdrawal'
  amount_minor_units INTEGER NOT NULL,
  date INTEGER NOT NULL,
  note TEXT NULL,
  created_at INTEGER NOT NULL,
  edited_at INTEGER NULL,
  deleted_at INTEGER NULL
)
UNIQUE INDEX idx_savings_contributions_idempotency_key ON SavingsContributions(idempotency_key)
INDEX idx_savings_contributions_goal_id ON SavingsContributions(goal_id, deleted_at)
```

**No changes to any existing table** — this feature is purely additive at the schema level and shares no foreign key with any table outside its own two (FR-026).
