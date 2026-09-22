# Contract: Financial Query Tools

This is the feature's most important contract — the literal, testable boundary between "the model narrates a real number" (required) and "the model invents or computes a number" (forbidden by constitution Principle VIII and spec FR-006). Every tool below is a thin Dart function in `lib/features/ai_assistant/domain/tools/`, each wrapping **exactly one existing, unmodified use case** from another feature. A tool function contains **zero arithmetic, zero date-range math beyond passing through what the caller/use case already resolves, and zero string formatting of a money value beyond what the wrapped use case's own entity already provides**. Every tool returns a `ToolResult` (data-model.md) whose `foundData` flag is `false`, never a fabricated zero, when the wrapped use case genuinely has nothing to report.

Each tool is declared to the provider (via `AIService.sendTurn`'s `availableTools`, `ai_service.md`) with a name, a short description, and a minimal typed-argument schema — the exact JSON-schema encoding is a Phase 2/implementation detail; what is fixed here is the *set* of tools, their inputs, and which existing use case each one calls.

## `getCategorySpend`

- **Wraps**: `GetCategoryBreakdown` (007-income-expense-tracking) — optionally narrowed client-side (by the tool, not the model) to the single requested category from the full breakdown list the use case already returns; no new aggregation is performed.
- **Arguments**: `period` (`"thisMonth"` | `"lastMonth"` | an explicit `{start, end}` date range — resolved the same way 007's own period presets already are, research.md 007 Decision 6), `categoryName?` (optional — omitted means "all categories," used by `getTopSpendingCategory` below).
- **Result data**: list of `{category, amountMinorUnits, shareOfPeriodTotalPercent}`, exactly as `GetCategoryBreakdown` returns per category.
- **Answers**: "How much did I spend on food this month?", "اعمللي ملخص مالي للشهر" (category portion).
- **foundData = false when**: no expense entries exist for the resolved period at all (not merely zero for one category — a genuine zero for an existing tracked category is still `foundData = true` with `amountMinorUnits = 0`, since that is a real, meaningful answer, not missing data).

## `getTopSpendingCategory`

- **Wraps**: `GetCategoryBreakdown` (007) — the tool selects the highest-amount entry from the already-returned, already-sorted-descending list; it does not independently compare amounts using its own logic beyond reading list order the use case already guarantees (per 007's own contract, category breakdown is returned descending by amount).
- **Arguments**: `period`.
- **Result data**: `{category, amountMinorUnits, shareOfPeriodTotalPercent}` for the single top category.
- **Answers**: "أنا بصرف أكتر فلوسي فين؟" (where do I spend the most).
- **foundData = false when**: zero expense entries exist for the period.

## `compareSpendingAcrossPeriods`

- **Wraps**: `GetFinanceSummary` (007), called twice — once per period — by the tool; the *comparison* (difference, percentage change) is the one narrow exception allowed to live in the tool layer, and only as a direct, simple, already-computed-inputs subtraction/percentage between two values **each of which individually came from an unmodified `GetFinanceSummary` call** — never an estimate, never involving any value not itself already returned by that use case. This mirrors the roadmap's own precedent (`GetSpendingTrend`, ROADMAP-PLAN.md §V1.5.3, is itself just "multiple calls to the existing one," not new aggregation).
- **Arguments**: `periodA`, `periodB`.
- **Result data**: `{periodATotalMinorUnits, periodBTotalMinorUnits, differenceMinorUnits, percentChange}`.
- **Answers**: "هل أنا زودت مصاريفي عن الشهر اللي فات؟" (did my spending increase vs. last month).
- **foundData = false when**: either period has zero recorded entries (a meaningful comparison cannot be honestly stated without both sides).

## `getPersonBalance`

- **Wraps**: `GetPersonBalance` (001-money-relationships-tracking).
- **Arguments**: `personName` (resolved to a `Person.id` by the tool via an exact/close case-insensitive name match against the existing People list — reusing the same lookup the app's own person picker already performs, not a new fuzzy-matching algorithm).
- **Result data**: `{personName, netMinorUnits, status}` (`status` exactly as `PersonBalance.status` — `theyOweYou` | `youOweThem` | `settled`).
- **Answers**: a specific named "does X owe me" / "do I owe X" question.
- **foundData = false when**: no person matching `personName` exists (User Story 3, Acceptance Scenario 2 — "cannot find that person").

## `getOwedOverview`

- **Wraps**: `GetOverview` (001-money-relationships-tracking).
- **Arguments**: none.
- **Result data**: `{totalOwedToUserMinorUnits, totalUserOwesMinorUnits, peopleTheyOweYou: [{personName, netMinorUnits}], peopleYouOweThem: [{personName, netMinorUnits}]}`, exactly as `OverviewSummary` already returns.
- **Answers**: "مين لسه عليه فلوس ليا؟" / "أنا لسه عليا فلوس لمين؟" (who owes me / who do I owe).
- **foundData = false when**: zero people recorded at all (a brand-new install).

## `getBudgetStatus`

- **Wraps**: `GetBudgetForMonth` (010-household-budgets).
- **Arguments**: `month` (defaults to the current calendar month if omitted).
- **Result data**: `{categories: [{category, plannedMinorUnits, actualMinorUnits, remainingMinorUnits, percentUsed, state}], totalPlannedMinorUnits, totalActualMinorUnits, isOverBudget}`, exactly as `GetBudgetForMonth` already computes (010 spec FR-005/FR-006).
- **Answers**: "أقدر أوفر كام الشهر ده؟" (budget-status component), any direct budget-status question.
- **foundData = false when**: no budget exists for the resolved month (010 spec's own empty state).

## `getSavingsGoalStatus`

- **Wraps**: `GetGoalDetail` (011-savings-goals).
- **Arguments**: `goalName` (resolved by name, same approach as `getPersonBalance`; omitted means "summarize all active goals," in which case the tool instead calls `GetSavingsOverview`).
- **Result data**: `{goalName, targetMinorUnits, currentMinorUnits, remainingMinorUnits, monthlyContributionMinorUnits?, estimatedMonthsToCompletion?, isAchieved}`, exactly as `GetGoalDetail`/`GetSavingsOverview` already compute (011 spec FR-004/FR-010).
- **Answers**: general "how are my savings goals doing" questions.
- **foundData = false when**: no goal matching `goalName` exists, or (when summarizing) the user has zero goals at all (User Story 3, Acceptance Scenario 1 — "no savings goal on record").

## `getSavingsProjection`

- **Wraps**: `CalculateWhatIfMonthlyContribution` (011-savings-goals) — a pure, already-deterministic what-if calculator; the tool passes the model-requested hypothetical monthly amount straight through to it and returns its result unchanged. This tool **never runs the projection math itself** — it only ever hands the existing calculator's own output back.
- **Arguments**: `goalName`, `hypotheticalMonthlyAmountMinorUnits`.
- **Result data**: `{goalName, hypotheticalMonthlyAmountMinorUnits, projectedMonthsToCompletion, projectedCompletionDate}`, exactly as `CalculateWhatIfMonthlyContribution` returns (011 spec FR-013).
- **Answers**: "لو عايز أوفر 50 ألف جنيه خلال سنة أعمل إيه؟" (what do I need to do to save X within a timeframe) — the tool call's arguments are derived by the model from the user's stated target/timeframe, but the returned *figure* is always the calculator's own output, never the model's.
- **foundData = false when**: `goalName` doesn't match an existing goal (this tool never operates on a goal that doesn't exist — it cannot fabricate a target amount).

## `getOccasionTotals`

- **Wraps**: `GetOccasionDetail` / `GetOccasionsList` (008-occasions-social-money).
- **Arguments**: `occasionName?` (a specific occasion, resolved by name) or omitted for a list of recent occasions.
- **Result data**: `{occasionName, totalReceivedMinorUnits, totalGivenMinorUnits, netMinorUnits}` per occasion, exactly as 008's own totals (008 data-model.md).
- **Answers**: occasion-specific questions (e.g. "how much did I receive at Ahmed's wedding?").
- **foundData = false when**: no occasion matching the request exists, or zero occasions recorded at all.

---

**What is deliberately NOT a tool**: anything requiring the model to invent a figure with no backing use case — e.g. a personalized investment return projection (explicitly out of scope, spec Assumptions/"No personalized investment advice"), an estimate of future income, or "how much should I spend on X" as a normative recommendation rather than a report of existing planned/actual data. A question landing on any of these MUST route to the honest-decline path (spec User Story 3), never to an improvised tool call.

**Cross-cutting rule for every tool above**: `personName`/`goalName`/`occasionName`/`categoryName` resolution never returns a *partial-match guess* silently — an ambiguous or unmatched name always yields `foundData = false` (with the ambiguity/non-match reason preserved in the tool's result for the model to relay honestly), never a best-guess substitution to a different person/goal/occasion/category than the one named.
