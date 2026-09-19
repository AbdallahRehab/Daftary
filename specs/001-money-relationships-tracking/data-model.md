# Phase 1 Data Model: Money Relationships Tracking

Derived from the spec's Key Entities section, the Clarifications session, and the Phase 0 research decisions (integer-minor-unit money, soft-delete/audit traceability, idempotency keys, local-only Drift/SQLite storage). All money fields are integer minor units (piastres); all timestamps are UTC `DateTime`.

## Entity: Person

A person the user has a money relationship with.

| Field | Type | Rules |
|---|---|---|
| `id` | `String` (UUID) | Primary key, generated client-side on creation |
| `name` | `String` | Required, non-empty after trim (FR-001). Normalized (lowercased, whitespace-collapsed) copy indexed for duplicate-name matching (FR-003, Clarifications) |
| `phoneNumber` | `String?` | Optional (FR-001) |
| `avatarPath` | `String?` | Optional local file path/reference (FR-001) |
| `relationshipTag` | `String?` | Optional; one of `family`/`friend`/`colleague`/`customer`/`supplier`/`other` or a free-text custom tag (FR-001) |
| `notes` | `String?` | Optional free text (FR-001) |
| `isArchived` | `bool` | Default `false`. `true` hides the person from active lists/selection but preserves full history (FR-017, FR-018) |
| `createdAt` | `DateTime` | Set once on creation |
| `updatedAt` | `DateTime` | Updated on every profile edit (FR-015-adjacent — profile edits, not transaction edits) |

**Validation rules**:
- `name` MUST be non-empty (trimmed).
- Before insert, the repository runs the FR-003 duplicate check: does any existing active-or-archived person's normalized name exactly match, start with, or get contained within (or vice versa) the new normalized name? If so, the use case returns a `PossibleDuplicateFound` outcome (not an error) so the Presentation layer can show the warning and let the user pick the existing person instead (never a silent auto-merge, per the spec's edge case).

**Derived (not stored)**: `PersonBalance` (see below) and `RelationshipStatus` (`theyOweYou` / `youOweThem` / `settled`), computed from this person's non-deleted `MoneyTransaction` rows — never cached as a mutable column, so it can never drift out of sync with history (Key Entities: "Person Balance").

**Lifecycle**: `active → archived → active` (restore, FR-018). A person is **never hard-deleted** once they have any transaction history (FR-017); a person with zero transactions may be hard-deleted (implied by FR-017's "who has any recorded transactions" qualifier — a person with none is not protected).

## Entity: MoneyTransaction

A single recorded money event between the user and one `Person`.

| Field | Type | Rules |
|---|---|---|
| `id` | `String` (UUID) | Primary key |
| `idempotencyKey` | `String` (UUID) | **Unique index.** Client-generated once per user-initiated save action; a retried insert with the same key is a no-op that returns the existing row (FR-020, SC-006) |
| `personId` | `String` (FK → `Person.id`) | Required — every transaction belongs to exactly one person; recording against the user themself is rejected at the use-case level (Edge Cases) |
| `amountMinorUnits` | `int` | Required, `> 0` (FR-005: zero/negative rejected with an explanation) |
| `direction` | enum `given` \| `received` | Required (FR-004) |
| `kind` | enum `initialExchange` \| `repayment` | Required at creation; **immutable after creation** (Clarifications) — reclassifying means delete + re-create |
| `date` | `DateTime` (date-only) | Defaults to today, user-editable (FR-004) |
| `note` | `String?` | Optional (FR-004) |
| `createdAt` | `DateTime` | Set once on creation |
| `editedAt` | `DateTime?` | Set on every field edit (amount/direction/date/note); `null` means never edited. Presence drives the "edited" UI marker (FR-015) |
| `deletedAt` | `DateTime?` | Soft-delete tombstone; `null` means active. A non-null row is excluded from balance/overview computation and from the person's visible history, and is not restorable via any UI (FR-016's "cannot be undone" is a UX promise; the tombstone exists solely for the constitution's audit-trail requirement — see research.md §6) |

**Validation rules**:
- `amountMinorUnits > 0` — zero/negative amounts are rejected before persistence (FR-005).
- A repayment (`kind = repayment`) may exceed the person's current outstanding balance; the use case accepts it and lets the resulting balance flip sign/direction rather than blocking (FR-012).
- Decimal input (e.g. 150.50 EGP) is converted to its exact integer piastre count (15050) at the input boundary — no floating-point intermediate step (FR-006).
- Arabic-Indic and Western numerals are normalized to the same numeric value before validation (FR-023).

**State transitions**: `created → [edited]* → [deleted]`. Edits update `editedAt` and mutable fields (never `kind`, `id`, `idempotencyKey`, `personId`, `createdAt`). Deletion sets `deletedAt` after an explicit confirm-cannot-be-undone step (FR-016) and never mutates `amountMinorUnits`/`direction`/`date`/`note` in place — a hard-delete-in-place is never performed, which is what keeps the audit trail truthful.

## Entity: TransactionAuditEntry

Append-only log satisfying the constitution's "every financial mutation MUST be traceable via IDs, timestamps, audit metadata" requirement and SC-007.

| Field | Type | Rules |
|---|---|---|
| `id` | `String` (UUID) | Primary key |
| `transactionId` | `String` (FK → `MoneyTransaction.id`) | Required |
| `changeType` | enum `created` \| `edited` \| `deleted` | Required |
| `previousValuesJson` | `String?` | For `edited`/`deleted`: a JSON snapshot of the fields as they were *before* this change (amount, direction, date, note). `null` for `created` |
| `changedAt` | `DateTime` | Required, set by the use case at the moment of the mutation |

**Rules**: One row is appended per create/edit/delete — never updated or removed. This table is written by the same repository method/DB transaction that writes the `MoneyTransaction` change, so the two can never go out of sync (no separate "logging step" that could be skipped).

## Value Object: PersonBalance *(derived, not persisted)*

Computed on demand from a `Person`'s non-deleted `MoneyTransaction` rows.

| Field | Type | Derivation |
|---|---|---|
| `personId` | `String` | — |
| `netMinorUnits` | `int` | `SUM(amountMinorUnits WHERE direction = received) − SUM(amountMinorUnits WHERE direction = given)`, over non-deleted rows. Positive ⇒ they owe you; negative ⇒ you owe them; zero ⇒ settled (FR-008) |
| `status` | enum `theyOweYou` \| `youOweThem` \| `settled` | Derived solely from `netMinorUnits`'s sign (FR-009) — no independent "mark as settled" state exists (Assumptions) |

**Rule**: Never stored as a mutable column on `Person` — always recomputed from source `MoneyTransaction` rows (Key Entities), which is what guarantees SC-002 (zero discrepancy vs. full history, including for people with 50+ transactions).

## Value Object: OverviewSummary *(derived, not persisted)*

Computed on demand across all people for User Story 4 / FR-013.

| Field | Type | Derivation |
|---|---|---|
| `totalOwedToUserMinorUnits` | `int` | Sum of `netMinorUnits` over all people (active **and** archived, per Clarifications) where `netMinorUnits > 0` |
| `totalUserOwesMinorUnits` | `int` | Sum of `abs(netMinorUnits)` over all people (active **and** archived) where `netMinorUnits < 0` |
| `peopleTheyOweYou` | `List<PersonSummary>` | People with `netMinorUnits > 0`, most-recent-activity first |
| `peopleYouOweThem` | `List<PersonSummary>` | People with `netMinorUnits < 0` |
| `settledCount` | `int` | Count of people with `netMinorUnits == 0` |

**Rule**: Archived people with a non-zero balance are included in both totals and their respective list (Clarifications: "archiving only hides a person from the active people list; their balance keeps counting in overview totals until it reaches zero").

## Relationships

```
Person (1) ──< (many) MoneyTransaction (1) ──< (many) TransactionAuditEntry
```

- Deleting a `Person` is only possible when they have zero `MoneyTransaction` rows (including soft-deleted ones, to keep audit history attributable); otherwise the delete is blocked and the UI offers archiving instead (FR-017).
- `PersonBalance` and `OverviewSummary` are read-model views over the two tables above — they are not separate write paths.

## Drift Schema Sketch (for Phase 2 task planning, not exhaustive DDL)

```
Table People (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  normalized_name TEXT NOT NULL,           -- indexed, for FR-003 matching
  phone_number TEXT NULL,
  avatar_path TEXT NULL,
  relationship_tag TEXT NULL,
  notes TEXT NULL,
  is_archived BOOLEAN NOT NULL DEFAULT FALSE,
  created_at INTEGER NOT NULL,             -- epoch millis
  updated_at INTEGER NOT NULL
)
INDEX idx_people_normalized_name ON People(normalized_name)

Table MoneyTransactions (
  id TEXT PRIMARY KEY,
  idempotency_key TEXT NOT NULL,
  person_id TEXT NOT NULL REFERENCES People(id),
  amount_minor_units INTEGER NOT NULL,
  direction TEXT NOT NULL,                 -- 'given' | 'received'
  kind TEXT NOT NULL,                      -- 'initialExchange' | 'repayment'
  date INTEGER NOT NULL,
  note TEXT NULL,
  created_at INTEGER NOT NULL,
  edited_at INTEGER NULL,
  deleted_at INTEGER NULL
)
UNIQUE INDEX idx_transactions_idempotency_key ON MoneyTransactions(idempotency_key)
INDEX idx_transactions_person_id ON MoneyTransactions(person_id, deleted_at)

Table TransactionAuditEntries (
  id TEXT PRIMARY KEY,
  transaction_id TEXT NOT NULL REFERENCES MoneyTransactions(id),
  change_type TEXT NOT NULL,               -- 'created' | 'edited' | 'deleted'
  previous_values_json TEXT NULL,
  changed_at INTEGER NOT NULL
)
INDEX idx_audit_transaction_id ON TransactionAuditEntries(transaction_id)
```
