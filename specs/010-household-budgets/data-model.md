# Phase 1 Data Model: Household Budgets

Derived from the spec's Key Entities section and the Phase 0 research decisions (new independent tables, no audit log for plans, `getCategoryBreakdown` reuse). All money fields are integer minor units (piastres) via the existing `Money` type; all timestamps are UTC `DateTime`. `Category`/`FinanceEntry` (007) are read, never written, by this feature beyond reusing 007's own category-management flow for inline creation — see `specs/007-income-expense-tracking/data-model.md` for their authoritative definition.

## Entity: Budget (NEW)

A user's spending plan for one calendar month.

| Field | Type | Rules |
|---|---|---|
| `id` | `String` (UUID) | Primary key |
| `idempotencyKey` | `String` (UUID) | **Unique index.** Client-generated once per creation save action; a retried insert with the same key is a no-op returning the existing row (FR-017) |
| `month` | `String` (`YYYY-MM`) | Required. **Unique index** — at most one `Budget` per calendar month (Assumptions: "one budget per calendar month") |
| `expectedIncomeMinorUnits` | `int?` | Optional (FR-003); purely a reference figure, never aggregated from `FinanceEntry` income rows (research.md/Assumptions) |
| `createdAt` | `DateTime` | Set once on creation |
| `updatedAt` | `DateTime` | Updated on every edit (planned-amount change, allocation add/remove, expected-income change) |
| `deletedAt` | `DateTime?` | Soft-delete tombstone; set on explicit delete (FR-011). No audit-log entry is written for this (research.md Decision 5) — a plain tombstone is sufficient since a `Budget` is a plan, not a financial mutation |

**Validation rules**:
- `month` MUST be a valid `YYYY-MM` value; a second `Budget` for the same `month` is rejected (surfaced as `BudgetAlreadyExistsForMonthFailure` — the caller should route the user to editing the existing one instead).
- `expectedIncomeMinorUnits`, if present, MUST be `>= 0` (a negative expected income is meaningless; zero is allowed, e.g. a month with no income planned).

**Derived (not stored)**: `BudgetSummary` (see below) and the per-allocation `BudgetCategoryStatus`, computed from this budget's `BudgetCategoryAllocation` rows plus 007's `FinanceEntry` data for the same month — never cached as mutable columns, mirroring every prior derived-value-object precedent in this codebase (001's `PersonBalance`, 008's `OccasionSummary`).

**Lifecycle**: `active → deleted` (FR-011, one-way — no restore is specified; recreating a budget for the same month after deletion is allowed since the unique-month constraint only applies to non-deleted rows).

## Entity: BudgetCategoryAllocation (NEW)

One category's planned amount within a `Budget`.

| Field | Type | Rules |
|---|---|---|
| `id` | `String` (UUID) | Primary key |
| `budgetId` | `String` (FK → `Budget.id`) | Required |
| `categoryId` | `String` (FK → `FinanceCategories.id`, 007) | Required. MUST reference a `Category` whose `type = expense` (FR-001 — Budgets scope to expense categories only, per Assumptions) |
| `plannedAmountMinorUnits` | `int` | Required, `>= 0` (FR-002 — zero allowed, negative rejected) |
| `createdAt` | `DateTime` | Set once when the allocation is added |
| `updatedAt` | `DateTime` | Updated when `plannedAmountMinorUnits` changes |

**Validation rules**:
- `(budgetId, categoryId)` MUST be unique — a category can only be allocated once per budget (FR-017's "duplicating a category allocation" guard); adjusting an existing allocation's amount is an edit (FR-010), not a second row.
- `plannedAmountMinorUnits >= 0` (FR-002).
- `categoryId` MAY reference an archived `Category` once already allocated (FR-021 — archived categories keep displaying correctly in an existing budget); the *picker* for adding a *new* allocation excludes archived categories (mirrors 007's own FR-011 exclusion rule, enforced in Domain/Presentation, not by a DB constraint).

**Lifecycle**: `created → [amount edited]* → [removed]?` (FR-010). Removal is a hard delete of the allocation row (not a soft-delete/tombstone — research.md Decision 5: no audit trail needed for plan data), which is safe because the row carries no financial history of its own, only a plan figure; the `FinanceEntry` rows that were counted against it are entirely unaffected and simply become "unbudgeted" for that month afterward (FR-007, Edge Cases).

## Value Object: BudgetSummary *(derived, not persisted)*

Computed on demand for one `Budget`, combining its `BudgetCategoryAllocation` rows with 007's expense data for the same month.

| Field | Type | Derivation |
|---|---|---|
| `budgetId` | `String` | — |
| `totalPlannedMinorUnits` | `int` | `SUM(BudgetCategoryAllocation.plannedAmountMinorUnits)` over this budget's allocations (FR-006) |
| `totalActualMinorUnits` | `int` | `SUM` of each allocated category's actual spend for the month, via 007's `CategoryRepository`/`FinanceRepository` (research.md Decision 2) — never a second aggregation path |
| `totalRemainingMinorUnits` | `int` | `totalPlannedMinorUnits − totalActualMinorUnits` (may be negative — over budget overall, FR-009) |
| `overallPercentageUsed` | `double?` | `totalActualMinorUnits / totalPlannedMinorUnits * 100`; `null` (displayed as "n/a", not divide-by-zero) when `totalPlannedMinorUnits = 0` |
| `isOverBudgetOverall` | `bool` | `totalActualMinorUnits > totalPlannedMinorUnits` (FR-009) |
| `categoryBreakdown` | `List<BudgetCategoryLine>` | One per allocation, see below |
| `unbudgetedSpending` | `List<UnbudgetedCategorySpend>` | Expense categories with actual spend in this month that are **not** part of this budget's allocations (FR-007), each with `categoryId`/`categoryName`/`amountMinorUnits`, sourced from 007's `getCategoryBreakdown(period)` filtered to categories absent from this budget's allocation set |

## Value Object: BudgetCategoryLine *(derived, not persisted)*

One row of the per-category breakdown (FR-005).

| Field | Type | Derivation |
|---|---|---|
| `allocationId` | `String` | The underlying `BudgetCategoryAllocation.id` |
| `categoryId` / `categoryName` / `categoryIcon` | — | From the referenced `Category` (007), resolved even if archived (FR-021) |
| `plannedAmountMinorUnits` | `int` | From the allocation |
| `actualAmountMinorUnits` | `int` | This category's non-deleted `FinanceEntry` (type=expense) sum for the budget's month (007) |
| `remainingMinorUnits` | `int` | `plannedAmountMinorUnits − actualAmountMinorUnits` |
| `percentageUsed` | `double?` | `actualAmountMinorUnits / plannedAmountMinorUnits * 100`; `null` when `plannedAmountMinorUnits = 0` (FR-002's Edge Case: a zero-planned category with any spend is immediately over budget, not a percentage) |
| `status` | enum `onTrack` \| `nearFull` \| `overBudget` | `overBudget` when `actualAmountMinorUnits > plannedAmountMinorUnits` (including any spend against a zero-planned allocation); else `nearFull` when `percentageUsed >= 90`; else `onTrack` (FR-008, Assumptions: 90% default threshold) |

## Value Object: BudgetTrendPoint *(derived, not persisted)*

One month's data point in the trend view (FR-014), either for one category or aggregated overall.

| Field | Type | Derivation |
|---|---|---|
| `month` | `String` (`YYYY-MM`) | — |
| `plannedMinorUnits` | `int` | That month's `Budget`'s planned total (overall) or one allocation's planned amount (per-category); `0` if no `Budget` exists for that month |
| `actualMinorUnits` | `int` | That month's actual spend (overall total or one category), computed via 007 exactly as in `BudgetSummary`/`BudgetCategoryLine`, independent of whether a `Budget` row exists for that month (spending can be shown even for a month with no plan) |

**Rule**: The trend view requires at least 2 months with a `Budget` row to render (FR-014's "not enough history" state) — a month with only expense data but no `Budget` does not count toward that minimum, since there is nothing to compare "actual" against for that month.

## Relationships

```
Budget (1) ──< (many) BudgetCategoryAllocation (many) >── (1) Category [007, read-only FK]
Budget (1) ──.month (unique)
BudgetCategoryAllocation ──(read, not FK-joined for writes)──> FinanceEntry [007, via CategoryRepository/FinanceRepository, period+category scoped]
```

- `BudgetCategoryAllocation.categoryId` is a plain reference into 007's `FinanceCategories` table — this feature never writes to that table directly (only via 007's existing `CategoryRepository.createCategory` when the user creates a new category inline from the allocation picker, FR-001).
- No FK exists from `FinanceEntries` back to `Budgets`/`BudgetCategoryAllocations` — the "actual spend" relationship is computed at query time by matching `categoryId` + date-within-month, never stored as a link on the `FinanceEntry` row itself (FR-022 — this feature adds no column to 007's tables).
- `BudgetSummary`/`BudgetCategoryLine`/`BudgetTrendPoint` are read-model views composed from `Budgets`/`BudgetCategoryAllocations` plus 007's repositories — not separate write paths.

## Drift Schema Sketch (for Phase 2 task planning, not exhaustive DDL)

```
Table Budgets (
  id TEXT PRIMARY KEY,
  idempotency_key TEXT NOT NULL,
  month TEXT NOT NULL,                      -- 'YYYY-MM'
  expected_income_minor_units INTEGER NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER NULL
)
UNIQUE INDEX idx_budgets_idempotency_key ON Budgets(idempotency_key)
UNIQUE INDEX idx_budgets_month ON Budgets(month) WHERE deleted_at IS NULL

Table BudgetCategoryAllocations (
  id TEXT PRIMARY KEY,
  budget_id TEXT NOT NULL REFERENCES Budgets(id),
  category_id TEXT NOT NULL REFERENCES FinanceCategories(id),
  planned_amount_minor_units INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
UNIQUE INDEX idx_budget_allocations_budget_category ON BudgetCategoryAllocations(budget_id, category_id)
INDEX idx_budget_allocations_budget_id ON BudgetCategoryAllocations(budget_id)
```

**No changes to any existing table** (`People`, `MoneyTransactions`, `TransactionAuditEntries`, `Occasions`, `OccasionAttachments`, `OcrScans`, `CandidateEntries`, `FinanceCategories`, `FinanceEntries`) — this feature is purely additive at the schema level (FR-022).
