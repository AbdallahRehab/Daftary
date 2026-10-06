# Data Model: Financial Trust Audit

**Plan**: [plan.md](plan.md) · **Date**: 2026-10-05

There are two parts. Part 1 is the shape of the audit records that go into `audit.md` (Track 1). Part 2 is the *minimal* change to the app's data model that Track 2 proposes. Every change there is tied to a verified finding in [research.md](research.md).

## Part 1 — Audit records (Track 1, document only)

| Entity | Fields | Rules |
| --- | --- | --- |
| **Finding** | `id` (`F-<area>-NN`), `area` (accounting, logic, data, ux, rtl, qa, security, sync, reporting), `type` (Bug, Missing requirement, Improvement, Optional future feature), `severity` (P0–P3), `evidence` (screen, flow or `path:line`), `expected`, `actual`, `verifiedBy` (executed, traced, or test), `impact`, `recommendation`, `backlogIds[]` | `verifiedBy` is required. P0/P1 need reproduction steps (SC-003). Must not describe behavior that doesn't exist (FR-001). |
| **FinancialFigure** | `name` (AR/EN), `screen(s)`, `definition` (plain language), `rule` (formula), `inputs`, `increases`, `decreases`, `onEdit`, `onDelete`, `onArchive`, `onRateChange`, `traceable` (yes, partial, no), `findingIds[]` | One per user-visible figure (SC-001). |
| **TestScenario** | `id` (`TS-<calc>-NN`), `covers`, `category`, `preconditions`, `steps`, `inputs`, `expectedOutputs` (number plus AR/EN label), `automated` (existing test path, or "gap") | At least 5 per critical calculation (SC-004). |
| **TerminologyEntry** | `currentAr`, `currentEn`, `proposedAr`, `proposedEn`, `why`, `audience`, `decision` (change or keep), `arbKey` | `arbKey` must exist in `app_ar.arb`. |
| **BacklogItem** | `id` (plan IDs A1…H6), `title`, `type`, `severity`, `current`, `expected`, `businessReason`, `technicalReason`, `acceptanceCriteria[]`, `dependencies[]`, `priority` (wave) | Every Finding of P2 or higher maps to at least one BacklogItem. |
| **OwnerDecision** | `id` (S1, Q1–Q3…), `question`, `options[]`, `recommended`, `impactPerOption` | At most 7 (SC-006). |

## Part 2 — Proposed app data model changes (Track 2)

Everything else stays exactly as it is. The current model (integer minor units, per-row currency, idempotency keys, soft-delete tombstones, append-only audits and sync metadata) was verified as sound (research §3).

### 2.1 No schema change (logic and read-path only)

| Item | Entity | Change |
| --- | --- | --- |
| A1 | `MoneyTransaction` | New invariant: `kind == repayment ⇒ direction is immutable after creation`. Enforced in the repository's `editTransaction`. |
| A2 | — (derived) | `RepaymentPreview { outstanding: Money?, resulting: Money?, flips: bool, blocked: bool }`. A pure Domain value; never stored. The repayment amount is converted into the primary currency with the balance's own `ConversionContext`. If its currency has no rate, `blocked = true`. |
| B1 repair | local sync state | One flag, `b1_repull_done` (bool, default false), in the existing sync state store. |
| E6 | — (derived) | `laterRepaymentCount(personId, fromDate)`: a count of active repayments dated on or after the row being deleted. |
| B1 | Sync wire | The read path changes: `date ← localMidnight(occurred_on) ?? occurred_at`. The wire format is unchanged. |
| C1 (if Q1 = B) | `PersonBalance`, `OverviewSummary` | Add a derived `socialNet: Money?` (from occasion contributions where `counts_toward_balance = 1`). The existing `net` becomes the *loan* net (all other rows). No column is added; the existing `kind` and `counts_toward_balance` columns are enough. |
| C3 | `TransactionAuditEntry` (exists) | Becomes readable: `watchAuditHistory(transactionId)` returns a list ordered by `changedAt`. A shared `ChangeHistoryRow(label, timestamp, fields)` view model feeds one generic `ChangeHistoryCubit`. |

### 2.2 Backend-only changes

| Item | Change |
| --- | --- |
| A3 + S0 | Migration `025`: in `sync_push`, `savings_contribution` uses `financial` when `p_app_version ≥ 1.1.0`, otherwise `lww` (today's behavior for v1.0.1). It adds the helper `public.app_version_at_least(p_version text, p_min text) returns boolean`, which compares dotted numeric versions; a null or unparsable version counts as false. No table change. |
| S0 + D2 | Migration `026`: `sync_pull(bigint,int)` keeps today's set of types exactly (no `finance_entry_audit`). The new `sync_pull_v2(bigint,int)`, with the same grants, returns every type. |

### 2.3 Schema changes (each becomes its own reviewed migration)

| Item | Table / field | Type | Sync | Notes |
| --- | --- | --- | --- | --- |
| D2 | `finance_entry_audits` (`id`, `finance_entry_id`, `change_type` ∈ {`created`, `edited`, `deleted`, `restored`}, `previous_values_json` (null for `created`), `changed_at`) | new local + server table | new entity `finance_entry_audit`, `append` policy, rank 2; served only by `sync_pull_v2` | Mirrors `TransactionAuditEntries`. `restored` is new because finance entries can be restored, and it stores the tombstone's values. Written in the same Drift transaction as the change. |
| C2 (if Q2 = hybrid) | `finance_entries.rate_micros_at_entry` | `int?` | new business field | Filled at creation from the current rate. Old rows are backfilled with the current rate and flagged `rate_backfilled = 1`, so reports can label them honestly. |
| G3 | savings contribution wire: `occurred_on`, `tz_offset_minutes` | wire + server columns | existing entity | Lets B1's fix extend to savings. |

### State transitions affected

- **Repayment row**: `created(direction inferred) → edited(amount | date | note only) → deleted(soft)`. A direction edit is rejected (A1).
- **Savings contribution (sync)**: `pending → applied | conflict(blocked) → resolved(keepMine | keepTheirs)`. The same lifecycle as money transactions (A3).
