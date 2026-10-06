# Contract: Track 2 behavior changes (before and after)

Every change to observable behavior Track 2 makes. Anything not listed here MUST behave exactly as it does today; the 3,699-test baseline, the calculation catalogue and the upgrade snapshot must stay green (spec SC-008).

## A1 — `TransactionsRepository.editTransaction`

| Input | Before | After |
| --- | --- | --- |
| `kind = repayment`, direction unchanged, amount/date/note changed | Right(updated) | Right(updated), unchanged |
| `kind = repayment`, **direction changed** | Right(updated): the debt grows | **Left(ValidationFailure)**; the row and audit are unchanged; nothing is queued for sync |
| `kind = initialExchange` or `occasionContribution`, direction changed | Right(updated) | Right(updated), unchanged |

UI: in edit mode, a repayment shows direction as read-only text plus a hint: "to change the direction, delete this payback and record it again". Repayments flipped before this fix are counted in the audit (research R8) and are not rewritten.

## A2 — Repayment form (primary currency EGP)

| Balance | Repayment | Before | After |
| --- | --- | --- | --- |
| They owe you 1,000.00 EGP | 400.00 EGP | saved | shows "Remaining: 1,000.00" → saved; the preview says 600.00 remains |
| They owe you 1,000.00 EGP | 1,000.00 EGP | saved | saved; the preview says settled |
| They owe you 1,000.00 EGP | 1,500.00 EGP | saved silently; the balance flips | **confirmation** ("You will owe Ahmed 500.00") → saved on confirm, nothing on cancel |
| They owe you 10,000.00 EGP, USD = 48.50 | 100.00 USD | saved | the preview says 5,150.00 EGP remains (converted with the balance's own rates) |
| They owe you 10,000.00 EGP, no GBP rate | 50.00 GBP | saved | preview `blocked` (no number shown); saving is still allowed |
| Blocked on a rate | any | saved | per-currency outstanding amounts shown; no flip preview; saved |

## A3 + S0 — `sync_push` for `savings_contribution` (migration 025)

| `p_app_version` | Upsert with a stale `base_revision` | Before | After |
| --- | --- | --- | --- |
| below R1 (e.g. `1.0.1`) | yes | applied (last write wins) | **unchanged**: applied (last write wins) |
| R1 or later | yes | applied (last write wins) | **`conflict`**: the op is blocked and shown in the sync conflicts list |
| any | current `base_revision` | applied | applied |
| any | same `op_id` replayed | ledger result | unchanged |

## S0 — Downloads

| Situation | Before | After |
| --- | --- | --- |
| R1+ app downloads a page containing an unknown `entity_type` | the whole page fails (`FormatException`) | the unknown row is skipped and logged without data; the other rows are applied; the cursor advances past it |
| v1.0.1 calls `sync_pull(bigint,int)` after 026 | — | gets exactly today's types; never `finance_entry_audit` |
| R2 calls `sync_pull_v2(bigint,int)` | — | gets every type, including `finance_entry_audit` |
| v1.0.1 calls `sync_pull(bigint,int)` after 025 | — | `conflict_resolution` rows whose `entity_type` is `savings_contribution` are not served (v1.0.1 rejects them and the page would fail). When v1.0.1 is retired, a later migration drops this filter and bumps those rows' revisions (a no-op update firing `sync_stamp`); otherwise devices already past the cursor never receive them. |

## B1 — Download of `money_transaction` and `finance_entry`

| Wire | Device TZ | Before | After |
| --- | --- | --- | --- |
| `occurred_on=2026-10-01`, `occurred_at=2026-09-30T21:00Z`, `tz=+180` | +120 | date 30 Sep | **date 1 Oct** |
| same | +180 | 1 Oct | 1 Oct |
| `occurred_on` missing | any | from `occurred_at` | from `occurred_at`, unchanged |

**Repair**: the first sync after upgrading resets the download cursor to 0 once (flag `b1_repull_done`). Rows with pending local changes or open conflicts are skipped by the applier, as they are today. Afterwards, previously shifted rows show their original day, **except** rows that were edited on a device while their day was shifted: that edit already uploaded the shifted day, so the server holds it and the re-pull keeps it.

## B2 — `recordRepayment` with unknown direction and no net in the repayment currency

Before: recorded as "given". After: `Left(RatesMissingFailure)`, and no row is inserted.

## C3 / D2 — New reads

`watchAuditHistory(transactionId)`, `watchContributionAuditHistory(contributionId)` and `watchEntryAuditHistory(entryId)` return `Stream<Either<Failure, List<…>>>` ordered by `changedAt` ascending. An empty list means there are no recorded changes. They never write.

## D2 — Income and expense changes

Create, edit, delete and restore of an income or expense entry each append one `finance_entry_audits` row (`created`, `edited`, `deleted`, `restored`) in the same transaction. Totals are unchanged.

## D1 — Export file

New CSV sections are appended **after** the existing ones, in the existing format: `occasions`, `occasion_contributions` (by reference), `budgets`, `budget_allocations`, `savings_goals`, `savings_contributions`, `exchange_rates`, `transaction_changes`, `savings_contribution_changes`, `finance_entry_changes`. The existing sections are unchanged byte for byte.

## E3 — Currency change while editing

| Mode | Action | Before | After |
| --- | --- | --- | --- |
| edit | pick another currency | applied immediately (same digits, new currency) | confirmation "recorded as X {to} without conversion"; cancel keeps the original |
| create | pick a currency | applied | applied, unchanged |

## E5 — Amount parsing

"١٬٥٠٠" was rejected before; it is now saved as 1,500.00. Every other input is unchanged.

## E6 — Deleting a transaction with later repayments

The confirmation adds "{n} later paybacks exist; the balance will become {result}". Deleting is never blocked.

## C4 — Possible duplicate

Create mode only: the same person, amount, currency, direction and date as an active row → a confirmation appears (only regular exchanges, kind = initial exchange, are compared; repayments and occasion contributions never trigger it), and confirming saves exactly 1 row with the same idempotency key. Saving is never blocked.

## E1 — Copy

Only ARB **values** change, and only to the values in the §8 table the owner approved. No ARB key is renamed.
