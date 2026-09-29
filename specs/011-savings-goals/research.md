# Phase 0 Research: Savings Goals

All Technical Context unknowns from `plan.md` are resolved below. The spec (011) carries zero `NEEDS CLARIFICATION` markers. This document resolves the remaining technical/design decisions, explicitly reusing precedents from 001/007/008/010 wherever they apply (constitution Refactoring Discipline).

## 1. `SavingsCalculator` as a pure, DB-free Domain service

**Decision**: All completion-estimate/required-contribution/what-if math lives in one pure Dart class, `SavingsCalculator`, in `lib/features/savings/domain/services/savings_calculator.dart` — functions take plain values (`Money remaining`, `Money monthlyContribution`, `DateTime asOf`, etc.) and return plain values, with no repository, database, or Flutter dependency anywhere in the call chain.

**Rationale**: This is what makes constitution Principle VIII's determinism requirement independently, exhaustively verifiable — a reviewer (or an automated test suite) can confirm every formula's correctness against the spec's own worked examples (FR-010/FR-011) without needing a database, a widget tree, or a device. It is also what structurally guarantees a "what if" exploration (FR-013/FR-014) cannot accidentally have a side effect: `CalculateWhatIfMonthlyContribution`/`CalculateWhatIfCompletionDate` call only this pure service and never touch `SavingsRepository` at all, while `ApplyWhatIfScenario` is the one and only use case that writes — the separation is structural, not just a naming convention.

**Alternatives considered**: Computing these figures inline in `GetGoalDetail`'s use case body or in a Cubit — rejected: harder to unit-test exhaustively in isolation from repository/DI wiring, and blurs the "explore vs. commit" boundary FR-015 depends on being unambiguous.

## 2. Deriving `currentAmount` from `SavingsContribution` rows (not a stored field)

**Decision**: `SavingsGoal` has no `currentAmountMinorUnits` column at all. A goal's current amount is always computed as `SUM(SavingsContributions.amount WHERE type=contribution) − SUM(SavingsContributions.amount WHERE type=withdrawal)` over that goal's non-deleted rows, via SQL aggregate — the same technique already proven for `PersonBalance` (001), `OccasionSummary` (008), and `BudgetSummary` (010).

**Rationale**: Directly implements the spec's own explicitly-reasoned key decision (FR-004) and keeps this feature consistent with a pattern now established four times over in this codebase: a running total is always a read-model computed from an append-only, individually-editable history, never a field the user or the UI can overwrite directly. This is what makes SC-002 ("zero discrepancies... across at least 50 logged entries") true by construction rather than by discipline.

**Alternatives considered**: A stored `currentAmountMinorUnits` column, incrementally updated on every contribution/withdrawal write — rejected per the same reasoning 001/008/010 already rejected it: a cached total can drift from its source history under a missed update path, a failed migration, or a manual DB fix, and the constitution's Financial Domain Override treats that risk as unacceptable for a figure users will plan around.

## 3. `SavingsGoal` "starting amount already saved" at creation

**Decision**: Creating a goal with a non-zero "starting amount" (FR-001 Acceptance Scenario 2, e.g. the worked "35,000 EGP already saved" example) is implemented as `CreateSavingsGoal` inserting the goal row **and** one initial `SavingsContribution` row (type `contribution`, dated to the goal's creation date, with a system-generated note such as "starting amount") in the same DB transaction — not a separate field on `SavingsGoal`.

**Rationale**: Keeps Decision 2's rule ("current amount is always derived from contributions, no exceptions") true without a special case; the starting amount is simply the goal's first logged contribution, visible in its history like any other (FR-008), which is also more honest to the user than a number that appeared with no corresponding history row.

**Alternatives considered**: A separate `startingAmountMinorUnits` field on `SavingsGoal`, added to the contribution-sum at read time — rejected: reintroduces exactly the kind of stored/derived-value split Decision 2 exists to avoid, and would need its own edit/audit story distinct from `SavingsContribution`'s, for no real benefit.

## 4. Progress visualization — reuse `fl_chart` (010) or build a simple custom widget?

**Decision**: A goal's progress indicator (percentage-toward-target) is implemented as a simple custom `LinearProgressIndicator`-based or `CustomPainter`-based ring/bar widget in `core/design_system` if it's judged generically reusable at implementation time, or directly in `features/savings/presentation/widgets/` otherwise — not via `fl_chart`. `fl_chart` (010's dependency) remains available for reuse should a future need for actual multi-point charting arise in this feature (e.g. a savings-rate trend over time), but a single goal's percentage-toward-target does not need a charting library at all.

**Rationale**: A single-value progress indicator is well within Flutter's own `LinearProgressIndicator`/simple `CustomPainter` capability and does not need a charting package's grouped-bar/axis machinery (unlike 010's genuine multi-month, multi-series trend view) — avoiding an unnecessary dependency on a library already in the project for a different, unrelated reason is the simpler, more honest choice here (constitution: "prefer the simplest architecture that can scale," "is there a simpler solution?").

**Alternatives considered**: Using `fl_chart`'s pie/gauge widgets for the progress ring merely because the package is already a project dependency — rejected as pulling in more of an already-present library's surface area than the actual need justifies; "it's already a dependency" is not by itself a reason to reach for it over a five-line custom widget.

**Confirmed 2026-09-22** (`/speckit-analyze`): this decision was flagged as ambiguous because `plan.md`'s Primary Dependencies line had drifted out of sync with this section (it read "reuses `fl_chart`"). `plan.md` has been corrected to match this section — 011 adds **zero** new `pubspec.yaml` dependencies and has no ordering dependency on 010.

## 5. Withdrawal validation — block over-withdrawal rather than allow a negative balance

**Decision**: `LogWithdrawal` validates `withdrawalAmount <= currentAmount` (computed via Decision 2's live aggregate) at the moment of logging, and rejects with `WithdrawalExceedsBalanceFailure` if not — unlike 001's `recordRepayment`, which deliberately *does* allow an amount larger than the outstanding balance and lets the sign flip.

**Rationale**: These are genuinely different real-world situations, and the spec is explicit about the difference (FR-006, Edge Cases): a debt repayment flipping sign has real meaning (the direction of who-owes-whom reverses, which is a valid state 001 models on purpose). A savings goal's current amount going negative has no real-world meaning — you cannot have saved less than zero — so blocking it is the correct domain rule here, not an inconsistency with 001's different rule for a different domain concept.

**Alternatives considered**: Allowing a negative `currentAmount` for symmetry with 001's repayment rule — rejected as the spec's own Edge Cases section explicitly calls for rejection with a clear explanation instead, and a negative "money saved" figure would be confusing and meaningless to display.

## 6. "Achieved" status: derived and reversible, never a stored flag

**Decision**: `SavingsGoal.isAchieved` is not a stored column; it is derived at read time as `currentAmount (Decision 2) >= targetAmount`, recomputed on every read, exactly like `PersonBalance.status`/`OccasionSummary.settlementStatus`/`BudgetCategoryLine.status` in prior specs. This means editing/deleting a contribution that brings the current amount back below target automatically un-marks the goal as achieved (FR-018), with no separate "un-achieve" action needed.

**Rationale**: A stored `isAchieved` boolean would need its own update-on-every-mutation discipline and could drift (e.g. if a contribution is deleted via a path that forgets to also flip the flag) — deriving it removes that entire class of bug, consistent with this codebase's now-standard approach to every derived status field.

**Alternatives considered**: A stored, one-way "achieved" flag that never reverts even if `currentAmount` later drops below target (treating "achieved" as a permanent milestone rather than a live state) — considered but rejected in favor of the spec's own explicit FR-018 requirement that a later withdrawal can reverse it; a permanent-milestone version would need an explicit product decision to diverge from FR-018 and was not asked for.

## 7. Idempotency scope

**Decision**: `createSavingsGoal`, `logContribution`, and `logWithdrawal` each take a caller-generated `idempotencyKey`, enforced via unique indexes, mirroring 001/008/009/010's established convention exactly. `editSavingsGoal`/`deleteSavingsGoal`/`archiveSavingsGoal`/`restoreSavingsGoal`/`editContribution`/`deleteContribution`/`applyWhatIfScenario` all act on an already-identified id, so a retried call is naturally idempotent.

**Rationale**: Directly satisfies FR-022 using the identical mechanism and reasoning already proven four times over in this codebase — no new idempotency pattern invented.

**Alternatives considered**: None seriously considered; direct reuse of an existing, working convention.

---

## Post-merge re-baseline (2026-09-29)

Decisions 8-13 were added by `/speckit-analyze` after 014/017/018/020/021 merged into `main`. They supersede anything above that assumed a local-only, single-currency feature.

## 8. Sync: adopt the 021 contract like occasions and budgets

**Decision**: `SavingsGoals`, `SavingsContributions` and `SavingsContributionAudits` are synced tables. Each gets a `SyncEntityType` (`savingsGoal` rank 0, `savingsContribution` rank 1, `savingsContributionAudit` rank 2), a `SyncMapper` under `lib/features/savings/data/sync/`, and a Supabase table in a new migration (`023_savings_goals_sync`) with the same columns, `sync_stamp` trigger, RLS policies and `(owner_id, revision)` index as 022's `occasions`/`budgets`. The migration replaces `sync_push`/`sync_pull`/`sync_delete_all` so they know the three new entity types. Every local write enqueues an outbox row in the same drift transaction, exactly as `BudgetsDao` does.

**Rationale**: 021 FR-006 requires it, and `table_classification_guard_test.dart` fails until every table in `allTables` is either synced or listed in `localOnlyTables`. Savings data is user-owned financial data, so local-only is not an option.

**Alternatives considered**: Listing the tables in `localOnlyTables` — rejected; a user's goals would silently not follow them to a new device, contradicting 021's promise.

## 9. Currency: one per goal, convert at log time

**Decision**: Follows 018's data model for 011. `SavingsGoals.currency_code` is set at creation (default: primary currency) and never edited. `SavingsContributions` stores `amount_minor_units` in the goal's currency (the only figure progress sums) plus `entered_amount_minor_units` and `entered_currency_code`. When they differ, `LogContribution`/`LogWithdrawal`/`EditContribution` convert through 018's `CurrencyConverter` using the current `ConversionContext`; a missing rate returns `RatesMissingFailure` and nothing is written. `SavingsCalculator` never converts — it only ever sees goal-currency integers.

The overview total (FR-019) converts each goal's current amount into the primary currency at read time. A goal needing a missing rate is returned with `isBlocked` and `missingRatesFor`, is excluded from the total, and the total carries `isIncomplete` — the same shape as 010's `UnbudgetedCategorySpend`.

**Rationale**: Freezing the converted figure at log time is what makes "progress never silently changes" true; the overview is the one place that must span currencies, so it converts at read time like budgets do.

**Alternatives considered**: Converting every entry at read time — rejected; a rate edit would move every goal's progress with no user action.

## 10. Contribution audit trail

**Decision**: A new `SavingsContributionAudits` table (`id`, `contribution_id`, `change_type` `edited|deleted`, `previous_values_json`, `changed_at`), a copy of 001's `TransactionAuditEntries`. `EditContribution` and `DeleteContribution` write the audit row and the change in one drift transaction. Audit rows are append-only and never read by progress math.

**Rationale**: The constitution's Financial Domain Override requires every financial mutation to be traceable with audit metadata. `editedAt` alone loses the prior amount.

**Alternatives considered**: Following 007 (`editedAt` only) — rejected; 007's gap is not a precedent to copy (constitution Governance: undocumented deviations are defects).

## 11. Month counting and rounding

**Decision**: `core/date` gains `wholeMonthsBetween(DateTime from, DateTime to)` = `(to.year − from.year) × 12 + (to.month − from.month)`, minus 1 when `to.day < from.day`, and `addCalendarMonths(DateTime, int)` (clamps to the month's last day). `SavingsCalculator` floors months-remaining at 1 and uses ceiling integer division for both estimated months and required monthly contribution.

**Rationale**: Calendar months match how users think about "10 months from now"; integer ceiling keeps Principle VIII (no floating point for money).

## 12. Navigation

**Decision**: Routes go in the People shell branch, next to `/occasions` and `/budgets`; Home gets a Savings card (like the Budgets card) and Home's Upcoming section lists active goals with a target date. Static paths `/savings/new` and `/savings/archived` are declared before `/savings/:goalId`. `/savings/:goalId` is already the deep-link target of `notification_tap_router.dart` (017), so that path is fixed.

**Rationale**: Mirrors 008/010's research Decision 9 — sections reached from Home, not a fourth tab.

## 13. Integrations that are already waiting

**Decision**: When this feature lands, it ships with the adapters other features reserved for it:
- 017: `SavingsRepositoryInsightsSource implements SavingsInsightsSource`, replacing `UnavailableSavingsInsightsSource` in DI; maps `GoalProgress`/`EstimatedCompletion` to `SavingsGoalSnapshot`.
- 014: `getSavingsGoalStatus` (wraps `GetGoalDetail`/`GetSavingsOverview`) and `getSavingsProjection` (wraps `CalculateWhatIfMonthlyContribution`) added to `ToolCatalog`.
- 012: Home's `UpcomingPlaceholderCard` is replaced by real upcoming goals when any exist.
- 018: `DriftCurrencyUsageChecker` gains `EXISTS` clauses for `savings_goals.currency_code` and `savings_contributions.entered_currency_code`.
- 013: `deleteAllUserData` deletes the three tables (audits → contributions → goals).
- 020: every savings page uses the shared adaptive app bar and `showAppModalSheet`.

**Rationale**: Each of these is a documented placeholder in the code pointing at 011; leaving them out would ship a feature the rest of the app can't see. All are read-only uses of this feature's Domain layer, so FR-026's independence still holds.
