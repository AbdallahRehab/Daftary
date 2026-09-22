# Phase 1 Data Model: Occasions / Social Money

Derived from the spec's Key Entities section and the Phase 0 research decisions (extend `MoneyTransaction` rather than a parallel ledger, `countsTowardBalance` flag, SQL-aggregate totals, cascade soft-delete). All money fields are integer minor units (piastres) via the existing `Money` type; all timestamps are UTC `DateTime`. Fields/behavior inherited unchanged from 001's `MoneyTransaction` are noted, not restated in full — see `specs/001-money-relationships-tracking/data-model.md` for the authoritative baseline.

## Entity: Occasion (NEW)

A named social event the user tracks money around.

| Field | Type | Rules |
|---|---|---|
| `id` | `String` (UUID) | Primary key, generated client-side on creation |
| `idempotencyKey` | `String` (UUID) | **Unique index.** Client-generated once per creation save action; a retried insert with the same key is a no-op that returns the existing row (FR-019) |
| `name` | `String` | Required, non-empty after trim (FR-001) |
| `date` | `DateTime` (date-only) | Required (FR-001); may be in the future (Edge Cases: upcoming/pre-planned occasions) |
| `type` | `String` | Required before the occasion is "complete" (FR-002); one of the standard set (`wedding`, `engagement`, `birthday`, `newbornSebou`, `condolence`, `celebration`, `other`) or free-text custom, same pattern as `Person.relationshipTag` (research.md Decision 6) |
| `notes` | `String?` | Optional free text (FR-001) |
| `isArchived` | `bool` | Default `false`. `true` hides the occasion from the default list but preserves full detail/history (FR-014) |
| `createdAt` | `DateTime` | Set once on creation |
| `updatedAt` | `DateTime` | Updated on every occasion-level edit (name/date/type/notes, FR-012) |
| `deletedAt` | `DateTime?` | Soft-delete tombstone; `null` means active. Set only via `DeleteOccasion`'s cascade (FR-013, research.md Decision 5) |

**Validation rules**:
- `name` MUST be non-empty (trimmed).
- `type` MUST be non-empty (trimmed) before the occasion can be saved as complete (FR-002).

**Derived (not stored)**: `OccasionSummary` (see below), computed from this occasion's non-deleted, linked `MoneyTransaction` rows — never cached as mutable columns (research.md Decision 4), mirroring 001's `PersonBalance`.

**Lifecycle**: `active → archived → active` (restore, FR-014) `→ deleted` (FR-013, cascades to all linked contributions — see Relationships). An occasion may be deleted regardless of whether it has participants (unlike `Person`, which is protected once it has history) — deleting an Occasion is always an explicit, named, confirmed cascade (FR-013), not a silent block-and-suggest-archive like `Person`.

## Entity: MoneyTransaction (EXTENDED — see 001 for the unchanged baseline)

Two new fields added to the existing entity; all other fields, validation rules, and state transitions from 001 are unchanged.

| Field | Type | Rules |
|---|---|---|
| `occasionId` | `String?` (FK → `Occasion.id`) | `null` for every transaction not tied to an occasion (the vast majority, unchanged from 001). Non-null only when `kind = occasionContribution` (FR-005) |
| `countsTowardBalance` | `bool` | Default `true`. For `kind = occasionContribution` rows only, may default to `false` when created under a `condolence`-type occasion, per the user's choice at entry time (FR-018, research.md Decision 3). Ignored (always effectively `true`) for every other `kind` |

**New enum value**: `TransactionKind` gains `occasionContribution` alongside the existing `initialExchange`/`repayment` (001). Like `kind` generally, `occasionContribution` is fixed at creation — reclassifying means delete + re-create, consistent with 001's Clarifications.

**Validation rules (additive to 001's)**:
- If `kind = occasionContribution`, `occasionId` MUST be non-null and MUST reference an existing, non-deleted `Occasion`.
- If `kind != occasionContribution`, `occasionId` MUST be `null` (a regular or repayment transaction is never linked to an occasion).
- The existing 001 rules (positive amount, decimal precision, Arabic-Indic numeral normalization, no self-transactions) apply unchanged to occasion-contribution rows.
- The same person MAY have more than one `occasionContribution` row for the same `occasionId` (Edge Cases: initial gift plus a later top-up), each a distinct row.

**Balance computation (updated)**: `PersonBalance.netMinorUnits` (001 formula) adds one filter predicate: only rows where `kind != occasionContribution` **or** `countsTowardBalance = true` are included in the SUM. `OverviewSummary` requires no separate change — it is already built entirely from `PersonBalance` (001 data-model.md), so the fix applies automatically.

## Entity: OccasionAttachment (NEW)

An optional photo linked to an Occasion (not to an individual participant contribution — research.md/Assumptions: attachments belong to the event as a whole).

| Field | Type | Rules |
|---|---|---|
| `id` | `String` (UUID) | Primary key |
| `occasionId` | `String` (FK → `Occasion.id`) | Required |
| `filePath` | `String` | Local file-system path within the app's private sandboxed storage directory (research.md Decision 7); never a remote URL |
| `createdAt` | `DateTime` | Set once when the attachment is added |
| `deletedAt` | `DateTime?` | Soft-delete tombstone; `null` means active. Set when the user removes an attachment after confirmation (FR-017) |

**Validation rules**:
- `filePath` MUST point to a file the app itself wrote (copied into its own sandboxed directory at attach time) — never a reference to a transient OS picker cache path that could disappear.

## Value Object: OccasionSummary *(derived, not persisted)*

Computed on demand from an `Occasion`'s non-deleted, linked `MoneyTransaction` rows (`kind = occasionContribution`).

| Field | Type | Derivation |
|---|---|---|
| `occasionId` | `String` | — |
| `totalReceivedMinorUnits` | `int` | `SUM(amount WHERE direction = received)` over non-deleted rows linked to this occasion (FR-007) |
| `totalGivenMinorUnits` | `int` | `SUM(amount WHERE direction = given)` over the same rows (FR-007) |
| `netMinorUnits` | `int` | `totalReceivedMinorUnits − totalGivenMinorUnits` (FR-007) |
| `settlementStatus` | enum `settled` \| `moreReceived` \| `moreGiven` | `settled` when `netMinorUnits == 0`; otherwise labeled with the outstanding direction and `abs(netMinorUnits)` (FR-008) |
| `participantCount` | `int` | Count of distinct `personId` values among linked rows, for the "no participants yet" vs. populated distinction (FR-020) |

## Value Object: OccasionParticipantRow *(derived, not persisted)*

One row shown in an Occasion's participant list (FR-016) — joins a linked `MoneyTransaction` with its `Person` and, per FR-009, that person's own independently-computed overall status.

| Field | Type | Derivation |
|---|---|---|
| `transactionId` | `String` | The underlying `MoneyTransaction.id` — the single source of truth also editable from the person's own profile (FR-010) |
| `personId` / `personName` | `String` | From the linked `Person` |
| `amountMinorUnits` | `int` | From the linked `MoneyTransaction` |
| `direction` | `TransactionDirection` | From the linked `MoneyTransaction` |
| `note` | `String?` | From the linked `MoneyTransaction` |
| `personOverallStatus` | enum `theyOweYou` \| `youOweThem` \| `settled` | The person's full `PersonBalance.status` (001), computed from **all** of that person's transactions, not just this occasion (FR-009 — never a separate occasion-only balance) |

**Rule**: `personOverallStatus` is deliberately the person's whole-history status, not a per-row/per-occasion status, because the spec (FR-009) explicitly requires the two views to never contradict each other — there is only ever one "does this person owe me" answer in the whole app.

## Relationships

```
Occasion (1) ──< (many) MoneyTransaction [kind=occasionContribution] (many) >── (1) Person
Occasion (1) ──< (many) OccasionAttachment
```

- A `MoneyTransaction` with `kind = occasionContribution` belongs to exactly one `Occasion` and exactly one `Person` (both required, unlike a regular transaction which only requires a `Person`).
- Deleting an `Occasion` soft-deletes every `MoneyTransaction` row with that `occasionId` in the same DB transaction (research.md Decision 5) — an `Occasion` is never left with dangling references, and a contribution row is never left pointing at a deleted occasion.
- `OccasionSummary` and `OccasionParticipantRow` are read-model views over the tables above — they are not separate write paths, exactly like `PersonBalance`/`OverviewSummary` in 001.

## Drift Schema Sketch (for Phase 2 task planning, not exhaustive DDL)

```
Table Occasions (
  id TEXT PRIMARY KEY,
  idempotency_key TEXT NOT NULL,
  name TEXT NOT NULL,
  date INTEGER NOT NULL,                    -- epoch millis, date-only
  type TEXT NOT NULL,
  notes TEXT NULL,
  is_archived BOOLEAN NOT NULL DEFAULT FALSE,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER NULL
)
UNIQUE INDEX idx_occasions_idempotency_key ON Occasions(idempotency_key)
INDEX idx_occasions_date ON Occasions(date)
INDEX idx_occasions_type ON Occasions(type)

-- Additive columns on the EXISTING MoneyTransactions table (001):
ALTER TABLE MoneyTransactions ADD COLUMN occasion_id TEXT NULL REFERENCES Occasions(id);
ALTER TABLE MoneyTransactions ADD COLUMN counts_toward_balance BOOLEAN NOT NULL DEFAULT TRUE;
-- kind column's accepted text values widen to include 'occasionContribution' (app-layer enforced)
INDEX idx_transactions_occasion_id ON MoneyTransactions(occasion_id, deleted_at)

Table OccasionAttachments (
  id TEXT PRIMARY KEY,
  occasion_id TEXT NOT NULL REFERENCES Occasions(id),
  file_path TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  deleted_at INTEGER NULL
)
INDEX idx_occasion_attachments_occasion_id ON OccasionAttachments(occasion_id, deleted_at)
```
