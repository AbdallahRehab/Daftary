# Phase 0 Research: Household Budgets

All Technical Context unknowns from `plan.md` are resolved below. The spec (010) carries zero `NEEDS CLARIFICATION` markers. This document resolves the remaining technical/design decisions, explicitly reusing 007's precedents wherever they apply (constitution Refactoring Discipline) and honoring 007's own data-model.md instruction that Budgets read `Category`/`FinanceEntry` through its existing contracts.

## 1. Reading 007's data through its repository interfaces, not a new query path

**Decision**: `BudgetsRepositoryImpl` takes `FinanceRepository` and `CategoryRepository` (both 007, unchanged) as constructor dependencies and calls their existing methods (`getCategories`, and a period/category-scoped expense total — see Decision 2) to compute actual spend. It never queries `FinanceEntries`/`FinanceCategories` tables directly, and never introduces a second DAO over them.

**Rationale**: This is exactly what FR-016 requires and exactly what 007's own data-model.md flagged as the expected shape of this dependency ("Budgets... is specified to read `Category`... and aggregate `FinanceEntries`... through this feature's `FinanceRepository`/`CategoryRepository` contracts — it must not introduce a second categories table or a second spend-aggregation query path"). Depending on the interface (not `FinanceRepositoryImpl`) keeps `budgets` swappable/testable per constitution Principle VI/XVI and means 007 can evolve its internal storage without `budgets` noticing, as long as the interface contract holds.

**Alternatives considered**: A read-only SQL view or a second DAO joining `FinanceEntries` directly from `budgets`' data layer — rejected: bypasses 007's Domain layer entirely (a Clean Architecture Principle I violation — Data-to-Data reach-across is exactly the kind of coupling the layering rule exists to prevent) and duplicates aggregation logic 007 already owns and tests.

## 2. Category-and-period-scoped expense aggregation — extending `FinanceRepository`

**Decision**: `FinanceRepository` (007) gains one new, additive method: `getCategoryTotalForPeriod({required String categoryId, required DateRange period})`, implemented via the same SQL-aggregate technique 007's existing `getCategoryBreakdown`/`getSummary` already use (007 research.md Decision 6), just parameterized to a single category. `budgets` calls this once per budgeted category (or, for efficiency, a single call returning all categories' totals for the month reusing 007's existing `getCategoryBreakdown(period)` and filtering/joining client-side in Domain against the budget's allocated category IDs — see implementation-time choice note below) rather than 007 adding any budget-specific concept.

**Rationale**: This is a small, generically useful, additive extension to 007's existing repository (not a `budgets`-specific hack), matching the exact shape of 007's own `getSummary`/`getCategoryBreakdown` methods so it needs no new aggregation technique. It is also useful independent of `budgets` (e.g. a future "how much have I spent on X category so far" quick-look), which is a reasonable bar for adding it to 007 rather than working around 007's interface from outside.

**Alternatives considered**: Calling 007's existing `getCategoryBreakdown(period)` (already returns every category's total for a period) and simply filtering to the budget's categories in `budgets`' own Domain code, with no `FinanceRepository` change at all — a valid, slightly simpler alternative; documented here as the implementation's actual likely choice at task-planning time (Phase 2), since it requires zero change to 007 and 007's `getCategoryBreakdown` already returns exactly the shape needed (ordered per-category totals for a period). Either approach satisfies FR-016 and FR-005; `tasks.md` should default to reusing `getCategoryBreakdown` (zero 007 changes) unless per-category granularity/performance at scale later proves the single-category method necessary.

## 3. `Budget`/`BudgetCategoryAllocation` as new, independent tables

**Decision**: Two new `drift` tables, `Budgets` (one row per user-created month, unique on `month`) and `BudgetCategoryAllocations` (one row per category allocated within a budget, unique on `(budgetId, categoryId)`, `categoryId` a plain FK reference to 007's `FinanceCategories.id` with no ownership implied). No existing table gains a column.

**Rationale**: A budget is a planning artifact layered on top of 007's data, not a modification of it (FR-022) — keeping it in entirely new tables makes that boundary structurally obvious and trivially satisfies "MUST NOT alter... existing... data-model" by construction, the same reasoning 007 itself used for staying separate from `MoneyTransactions` (007 research.md Decision 1).

**Alternatives considered**: Storing planned amounts as a special `FinanceEntry` flag (e.g. `isPlanned: true`) — rejected: conflates two different concepts (a plan vs. a recorded real-world event) in one table, and would force every existing `FinanceEntry` query in 007 to filter out planned rows or risk incorrectly counting them as real spending — a correctness risk the constitution's Financial Domain Override treats seriously.

## 4. Trend view charting

**Decision**: `fl_chart` (grouped bar chart: planned vs. actual per month, per category or overall) for the spending trend view (FR-014).

**Rationale**: `fl_chart` is MIT-licensed, actively maintained, widely used in production Flutter apps, and directly supports the grouped-bar-with-axis-labels shape this view needs, including custom label widgets (for localized month names and RTL mirroring) without hand-rolling low-level `Canvas` code — a reasonable "don't over-engineer, prefer simplicity" choice (constitution Architectural Decision Rule) given a maintained package already fits the need well.

**Alternatives considered**: A hand-rolled `CustomPainter` bar chart — rejected as unjustified engineering effort for a P3 feature when a suitable, small, well-maintained dependency exists (constitution: "is there a simpler solution?" cuts toward reuse here, not toward avoiding a dependency at any cost). A heavier full charting suite (e.g. `syncfusion_flutter_charts`, commercial-licensed) — rejected: license cost/complexity disproportionate to this feature's one chart type.

## 5. Why `Budget`/`BudgetCategoryAllocation` edits don't need a `TransactionAuditEntry`-style audit log

**Decision**: Editing or deleting a `Budget`/`BudgetCategoryAllocation` simply updates/removes the row (with `updatedAt` bumped) — no parallel append-only audit table is introduced for budgets, unlike `MoneyTransaction`'s `TransactionAuditEntry` (001) or the OCR feature's reuse of that same mechanism (009).

**Rationale**: The constitution's Financial Domain Override requires traceability for **financial mutations** — money that actually moved. A `Budget`/`BudgetCategoryAllocation` is a plan/intention (what the user *wants* to spend), not a record of money moving; changing a planned amount from 6,000 to 6,500 EGP is not a financial event that needs a permanent audit trail the way silently altering a recorded transaction would be. Applying the audit-log pattern here anyway would be needless ceremony for data that is, by design, freely and frequently revised (a budget plan is expected to change monthly, even mid-month). This is a deliberate, documented narrowing of where that principle applies — not an oversight — consistent with the constitution's own instruction to explain non-obvious architectural decisions.

**Alternatives considered**: Reusing `TransactionAuditEntry`'s pattern for budgets too, for consistency's sake alone — rejected as applying a real, weighty requirement (permanent financial audit trail) to data that doesn't carry the same stakes, adding storage/complexity with no corresponding safety benefit; the constitution's own Architectural Decision Rule favors the simpler option here since nothing about correctness or user trust depends on a budget-plan's edit history being permanently retained.

## 6. Idempotency scope

**Decision**: `createBudget` and `addBudgetCategoryAllocation` take a caller-generated `idempotencyKey`, enforced via unique indexes (`Budgets.idempotency_key` and reuse of `Budgets(month)`'s own uniqueness plus `BudgetCategoryAllocations(budget_id, category_id)`'s uniqueness as a natural duplicate guard). `editBudget`/`deleteBudget`/`removeBudgetCategoryAllocation`/`copyBudgetToMonth` act on already-identified ids (or a target month whose own uniqueness constraint prevents a double-copy), so a retried call is naturally idempotent, exactly per 001/008/009's established convention.

**Rationale**: Directly satisfies FR-017 using the identical mechanism and reasoning already proven three times over in this codebase — no new idempotency pattern invented.

**Alternatives considered**: None seriously considered; direct reuse of an existing, working convention.
