# Phase 1 Data Model: Multi-Currency Support

## Entity: Currency (NEW, bundled static content — research.md Decision 1)

| Field | Type | Notes |
|---|---|---|
| `code` | `String` | ISO 4217 code, e.g. `EGP`, `USD`. Primary key within the catalog. |
| `symbol` | `String` | Display symbol, e.g. `E£`, `$` (locale-appropriate; both `ar`/`en` display forms bundled per currency). |
| `nameEn` / `nameAr` | `String` | Localized display name, e.g. "Egyptian Pound" / "جنيه مصري." |
| `minorUnitsPerMajor` | `int` | Standard smallest-unit divisor for this currency (100 for EGP/USD/EUR — no zero-decimal or three-decimal currencies in the starter set, per spec.md Assumptions' small starter list, though the field exists for correctness/future extension). |
| `isRemovable` | `bool` | `false` only for `EGP` (spec.md Key Entities: "EGP... cannot be removed"); `true` for every other catalog entry. |

## Entity: PrimaryCurrencySetting (NEW, `drift` table)

Single record per device.

| Field | Type | Notes |
|---|---|---|
| `currencyCode` | `String` (FK to `Currency.code`) | Defaults to `EGP` (FR-005). |
| `updatedAt` | `DateTime` | When the user last changed it. |

## Entity: ExchangeRate (NEW, `drift` table)

One row per non-primary currency the user has configured a rate for.

| Field | Type | Notes |
|---|---|---|
| `currencyCode` | `String` (FK to `Currency.code`) | The non-primary currency this rate converts FROM. |
| `relativeToCurrencyCode` | `String` (FK to `Currency.code`) | The primary currency this rate converts TO, at the time the rate was set — stored explicitly (not assumed to always be "whatever the current primary is") so a rate remains correctly interpretable even if the primary currency later changes again (FR-012's forced-rate-on-switch flow creates a *new* `ExchangeRate` row for the new primary pairing, never silently reinterprets an old one). |
| `rate` | `double` (or a fixed-precision decimal representation — task-planning decision) | "1 unit of `currencyCode` = `rate` units of `relativeToCurrencyCode`." MUST be `> 0` (FR-006). |
| `lastUpdatedAt` | `DateTime` | Shown to the user per FR-007. |

**Uniqueness**: `UNIQUE(currencyCode, relativeToCurrencyCode)` — upserted (never duplicated) when the user edits a rate for the same pairing.

## Extended Entity: MoneyTransaction (001) — currency-aware

| Field (new/changed) | Type | Notes |
|---|---|---|
| `amount` | `Money` (now currency-aware, research.md Decision 2) | Was a bare integer-minor-units field; now carries `currencyCode` alongside `minorUnits` as one inseparable value (FR-004). |

Migration: every pre-existing row's `amount.currencyCode` is set to `EGP` explicitly (FR-002) — no schema-level nullability is introduced; the column is `NOT NULL` from the moment it's added, backfilled in the same migration step.

## Extended Entity: FinanceEntry (007) — currency-aware

Same shape/migration treatment as `MoneyTransaction` above, applied to `FinanceEntry.amount`.

## Extended Entity: Occasion Contribution (008) — currency-aware

Same treatment, applied to the occasion-contribution record's amount field (008's own spec models a contribution as an extended `MoneyTransaction` — see 008's data-model.md for its exact shape; this feature's migration touches whichever concrete field that resolves to, without altering 008's own contribution-vs-balance-exclusion logic, per FR-017).

## Extended Entity: Budget (010) — currency-aware

| Field (new/changed) | Type | Notes |
|---|---|---|
| `limitMinorUnits` / planned amount | `Money` (now currency-aware) | Same treatment as above, applied per budgeted category line. |

Actual spend (derived from `FinanceEntry`) is already currency-aware transitively once 007's migration lands — `GetBudgetOverview`-equivalent's own aggregation composes `CurrencyConverter` to normalize actual-spend `FinanceEntry` amounts (potentially several currencies) against the budget line's own planned-amount currency, or against the primary currency for the aggregate summary (FR-008).

## Extended Entity: SavingsGoal / SavingsContribution (011) — currency-aware, one currency per goal

| Field (new/changed) | Type | Notes |
|---|---|---|
| `SavingsGoal.targetAmountMinorUnits` | `Money` (now currency-aware) | The goal's own currency, set at creation — the "one currency per goal" rule (spec.md Assumptions/FR-011). |
| `SavingsContribution.amountMinorUnits` | `Money` (now currency-aware) | If logged in a different currency than its goal's own currency, converted to the goal's currency AT LOG TIME using the configured rate (spec.md Edge Cases) — the stored `SavingsContribution` row itself, per FR-010, still separately preserves the amount/currency the user actually entered (two fields: `enteredAmount: Money`, `goalCurrencyAmount: Money` — the latter is what `GetSavingsGoalDetail`'s existing progress math sums, the former is what the contribution's own history row displays, satisfying both FR-010 and FR-011 simultaneously). |

`ProjectSavingsCompletion`/the what-if calculator (011) operates exclusively on `goalCurrencyAmount` figures, already normalized to one currency by the time it runs — it never calls `CurrencyConverter` itself (FR-011, plan.md Project Structure).

## Relationships

```text
Currency ──1:N── ExchangeRate (as currencyCode)
Currency ──1:N── ExchangeRate (as relativeToCurrencyCode)
Currency ──1:1── PrimaryCurrencySetting

Currency ──1:N── MoneyTransaction.amount.currencyCode          (001)
Currency ──1:N── FinanceEntry.amount.currencyCode               (007)
Currency ──1:N── OccasionContribution.amount.currencyCode        (008)
Currency ──1:N── Budget.plannedAmount.currencyCode                (010)
Currency ──1:N── SavingsGoal.targetAmount.currencyCode              (011, one per goal)
Currency ──1:N── SavingsContribution.{enteredAmount,goalCurrencyAmount}.currencyCode  (011)
```

## Drift Schema Sketch (for Phase 2 task planning, not exhaustive DDL)

```text
PrimaryCurrencySetting (single row, id fixed e.g. 'default')
  id TEXT PRIMARY KEY
  currency_code TEXT NOT NULL DEFAULT 'EGP'
  updated_at INTEGER NOT NULL

ExchangeRates
  id TEXT PRIMARY KEY
  currency_code TEXT NOT NULL
  relative_to_currency_code TEXT NOT NULL
  rate REAL NOT NULL              -- or a fixed-precision integer-scaled representation,
                                   -- task-planning decision per constitution Principle VIII's
                                   -- "no careless floating point" — likely stored as a scaled
                                   -- integer (e.g. rate * 1_000_000) rather than REAL, finalized
                                   -- at implementation time
  last_updated_at INTEGER NOT NULL
  UNIQUE INDEX idx_exchange_rates_pair (currency_code, relative_to_currency_code)

-- Additive columns on existing tables (one migration step each, research.md Decision 3):
MoneyTransactions          + currency_code TEXT NOT NULL DEFAULT 'EGP'   (001)
FinanceEntries              + currency_code TEXT NOT NULL DEFAULT 'EGP'   (007)
<occasion contribution table> + currency_code TEXT NOT NULL DEFAULT 'EGP' (008)
Budgets                     + currency_code TEXT NOT NULL DEFAULT 'EGP'   (010, per planned-amount line)
SavingsGoals                + currency_code TEXT NOT NULL DEFAULT 'EGP'   (011)
SavingsContributions        + entered_currency_code TEXT NOT NULL DEFAULT 'EGP',
                             + goal_currency_amount_minor_units INTEGER NOT NULL DEFAULT 0
                               (backfilled = amount_minor_units for pre-existing rows, since
                               their entered and goal currency were always the same EGP, per
                               FR-002)                                    (011)
```

All six table changes plus the two new tables ship in one coordinated `schemaVersion` increment (research.md Decision 3), each individually tested and each backfilling pre-existing rows to explicit `EGP` (FR-002) — never left `NULL`/ambiguous.
