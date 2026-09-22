# Phase 0 Research: Occasions / Social Money

All Technical Context unknowns from `plan.md` are resolved below. The spec (008) already carries zero `NEEDS CLARIFICATION` markers. This document resolves the remaining technical/design decisions needed to start Phase 1 design, explicitly reusing the precedents set by spec 001 (`people`/`transactions`) and spec 007 (`finance`) wherever they apply, per the constitution's Refactoring Discipline.

## 1. Occasion contributions: extend `MoneyTransaction` vs. a new parallel table

**Decision**: An Occasion participant contribution is stored as an ordinary row in the existing `MoneyTransactions` table, gaining two new nullable columns (`occasion_id`, `counts_toward_balance`) and one new `TransactionKind` enum value (`occasionContribution`).

**Rationale**: This is the opposite call from 007's Decision 1 (which correctly kept `FinanceEntries` separate from `MoneyTransactions`), and deliberately so: `FinanceEntry` has no person and no debt semantics, so merging it would have been a forced, meaningless fit. An Occasion contribution is the *exact same concept* as an existing `MoneyTransaction` — money moving between the user and one `Person`, on a date, in a direction — plus one extra piece of context (which event it happened at). Modeling it as a second, parallel "OccasionContribution" record type would require either (a) computing `PersonBalance`/`OverviewSummary` as a UNION of two tables everywhere they're queried (duplicating and risking divergence of the balance formula that is 001's core trust guarantee, FR-008/SC-002), or (b) accepting that a person's balance and their occasion history could disagree — explicitly rejected by this feature's spec (User Story 2, FR-005, FR-009). Extending the existing table keeps exactly one balance formula, one audit mechanism, one idempotency mechanism, for both existing and occasion-linked money.

**Alternatives considered**: A separate `OccasionContributions` table with its own foreign keys to `Person` and `Occasion`, reconciled into `PersonBalance` via a UNION query — rejected per above (duplicated/divergence-prone balance logic, and doubles the audit-trail mechanism the constitution's Financial Domain Override requires). A generic polymorphic "ledger" spanning `MoneyTransactions`/`FinanceEntries`/`OccasionContributions` — rejected as premature abstraction (same reasoning as 007 Decision 1); nothing today needs to query all three as one collection, and `FinanceEntries` genuinely has different semantics (no person) that would force nullable/unioned fields on everything.

## 2. Database schema addition and migration

**Decision**: Two new `drift` tables (`Occasions`, `OccasionAttachments`) added to `AppDatabase`. The existing `MoneyTransactions` table gains two additive nullable/defaulted columns: `occasion_id TEXT NULL REFERENCES Occasions(id)` and `counts_toward_balance BOOLEAN NOT NULL DEFAULT TRUE`; the `kind` column's accepted value set widens to include `'occasionContribution'` (drift enum-as-text columns don't require a migration to widen — only application code needs deployment, but the `onUpgrade` step still runs to add the two columns and the two new tables). `schemaVersion` increments by 1 from whatever value it holds when this feature is implemented; the migration step follows the exact `if (from < N) { ... }` additive pattern already used for every prior version bump in `app_database.dart` (see 007 research.md Decision 2 for the established convention). No existing row, column type, or index is altered or dropped.

**Rationale**: Matches the codebase's proven, low-risk additive-migration convention. Nullable `occasion_id` with `DEFAULT NULL` means every pre-existing `MoneyTransactions` row remains valid with zero backfill needed — it simply isn't linked to any occasion, which is exactly correct (it never was one).

**Alternatives considered**: A join table (`OccasionParticipants`) mapping `occasionId` + `transactionId` instead of a column on `MoneyTransactions` — rejected as unnecessary indirection: the relationship is strictly one occasion contribution → at most one occasion, never many, so a direct nullable FK is simpler, indexable, and matches how `personId` already works on the same table (constitution: prefer the simpler option with the best overall balance).

## 3. The `countsTowardBalance` flag and the condolence default (FR-018)

**Decision**: `MoneyTransactions.counts_toward_balance` is a per-row boolean, defaulting to `true` for every kind except: rows created as part of a condolence-type Occasion default to `false` unless the user explicitly overrides it at entry time (per-occasion override, FR-018). `PersonBalance`'s existing SUM query (001 data-model.md) adds one `AND (kind != 'occasionContribution' OR counts_toward_balance = TRUE)` predicate; `OverviewSummary` inherits the fix automatically since it's built from `PersonBalance`.

**Rationale**: This is the minimal, additive change that supports the spec's documented cultural-accuracy decision (condolence money isn't a reciprocal social debt in Egyptian custom) without introducing a second balance-calculation code path. The flag lives on the transaction row (not derived at query time from occasion type) so that a user's explicit per-occasion override (FR-018) is itself just a normal field edit, not special-cased logic — and so the flag's value is stable and auditable even if the parent Occasion's type is later changed (FR-012 allows editing an occasion's type after creation; the already-created contributions' `countsTowardBalance` values are not retroactively changed by that edit, avoiding a surprising balance jump from an unrelated edit).

**Alternatives considered**: Deriving "counts toward balance" purely from the parent Occasion's current type at query time (no stored column) — rejected: it would mean editing an occasion's type from "wedding" to "condolence" silently changes every participant's historical balance with no explicit action or audit trail on the affected `MoneyTransaction` rows, violating the constitution's "financial records MUST NEVER be silently modified."

## 4. Occasion totals and settlement status computation

**Decision**: `OccasionSummary` (totalReceived, totalGiven, net, settlementStatus) is computed on demand by a SQL aggregate query (`SUM(amount) FILTER (WHERE direction = 'received')`, `SUM(...) WHERE direction = 'given'`) over non-deleted `MoneyTransactions` rows where `occasion_id = :id` — mirroring `PersonBalance`'s existing aggregate-query approach (001 data-model.md) exactly, never a client-side loop-and-sum over a fetched list, and never a stored/cached total column on `Occasions`.

**Rationale**: Directly satisfies FR-007/FR-008's "recalculated immediately whenever a participant entry is added, edited, or removed" with zero risk of a cached total drifting from source rows — the same guarantee 001 already established for `PersonBalance` (SC-002: "zero discrepancies"). Reusing the identical SQL-aggregate technique means the `OccasionsDao` query is a near copy of the existing `TransactionsDao` balance query, which is easy to review against the proven original.

**Alternatives considered**: Storing/incrementing `totalReceived`/`totalGiven` columns on `Occasions` on every write — rejected per 001's own established rule (Key Entities: "Person Balance... always recalculated from source transactions rather than stored as an independently editable value, so it can never silently drift out of sync") and constitution Principle VIII.

## 5. Occasion deletion cascade (FR-013, Edge Cases)

**Decision**: `DeleteOccasion` is a single DB transaction that (a) soft-deletes (via the existing `deletedAt` tombstone) every `MoneyTransaction` row with that `occasion_id`, appending a `deleted` `TransactionAuditEntry` for each (reusing 001's existing per-transaction audit mechanism verbatim), then (b) soft-deletes the `Occasion` row itself. The use case first counts affected participants and returns that count to the caller so the confirmation dialog can name it (FR-013's "names how many participant contributions will be removed") before the user confirms and the actual deletion call is made.

**Rationale**: Reuses the exact soft-delete + audit-entry mechanism 001 already built and tested for individual transaction deletion — no new deletion/audit pattern is invented. Wrapping both steps in one DB transaction guarantees the cascade can never partially apply (e.g., contributions deleted but the occasion left behind, or vice versa), consistent with the constitution's Financial Domain Override on traceability and correctness.

**Alternatives considered**: Deleting the `Occasion` row and leaving its contributions' `occasion_id` dangling (nulled or orphaned) — rejected: explicitly ruled out by the spec's Edge Cases ("an occasion is never left as a dangling reference inside a person's history") and would silently change what a person's history displays without an explicit, confirmed user action on those specific transactions.

## 6. Occasion type modeling (standard set + custom)

**Decision**: `OccasionType` is modeled as a string field (not a closed Dart `enum`) with a small constant list of standard values (`wedding`, `engagement`, `birthday`, `newbornSebou`, `condolence`, `celebration`, `other`) used to drive the picker UI and localized labels, plus free-text custom values accepted the same way `Person.relationshipTag` already accepts a standard set or free text (001 data-model.md). The `condolence` value is the one recognized by Decision 3's default-flag logic; any other value (standard or custom) defaults `countsTowardBalance` to `true`.

**Rationale**: Directly mirrors the already-proven `relationshipTag` pattern in `people` (constitution Code Review Mode: "does it duplicate existing code? is there a simpler solution?") rather than inventing a second customization mechanism. Using a string (not a closed enum) means adding a new standard type later, if ever needed, is a data/localization change, not a schema migration.

**Alternatives considered**: A closed Dart `enum OccasionType` with no custom option — rejected: directly contradicts FR-002 ("or define a custom type") and the product brief's explicit instruction not to assume Egyptian occasion terminology is exhaustive.

## 7. Attachment storage and the new `image_picker`-class dependency

**Decision**: Occasion photo attachments are captured/selected via a new `core/media/AttachmentPickerService` abstraction (Domain-facing interface, Data-layer implementation wrapping an `image_picker`-class plugin), storing only a local file-system path reference in the new `OccasionAttachments` table (`file_path`, `created_at`) — the image bytes themselves live in the app's private sandboxed storage directory (via `path_provider`, the same package already used for the SQLite file), never uploaded anywhere, consistent with FR-017 and the constitution's Security & Secrets principle (local-only, no cloud dependency for a feature with no AI/OCR/network component).

**Rationale**: `core/media/` is introduced now (not deferred) because the upcoming OCR feature's own first step is also photo capture/selection (`docs/project.txt` §3, steps 1-3) — building the picker abstraction here, and only here, means OCR's plan can depend on and extend it rather than duplicating a second capture flow, which is the constitution's Feature-First Modularity principle working as intended ("only move into `core/` when genuinely shared across two or more features... and represents a real cross-cutting concern"): the sharing is concrete and already-planned, not speculative.

**Alternatives considered**: Building the attachment picker directly inside `features/occasions/` and letting the future OCR feature copy/duplicate it — rejected as a predictable near-term duplication given the OCR spec (not yet written at plan time, but already scoped in this same roadmap tier) is known to need the identical capability next.

## 8. Idempotency scope

**Decision**: `createOccasion` and `addParticipantContribution` each take a caller-generated `idempotencyKey` (same UUID-per-save-action convention as `MoneyTransactions.idempotencyKey`), enforced via a unique index — `Occasions.idempotency_key` (new) and the existing `MoneyTransactions.idempotency_key` unique index (already covers the new `occasionContribution` kind with no change needed). `editOccasion`/`editParticipantContribution`/`deleteOccasion`/`removeParticipantContribution` act on an already-identified id, so a retried call is naturally idempotent (same edit/delete applied twice is a no-op), exactly as established in 001 research/data-model for `editTransaction`/`deleteTransaction`.

**Rationale**: Directly satisfies FR-019 using the identical mechanism and reasoning already proven for ordinary transactions (001 contracts/transactions_repository.md, "Idempotency note") — no new idempotency pattern invented.

**Alternatives considered**: None seriously considered; this is a direct reuse of an existing, working convention.
