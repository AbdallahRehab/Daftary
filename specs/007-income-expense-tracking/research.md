# Phase 0 Research: Income & Expense Tracking

All Technical Context unknowns from `plan.md` are resolved below. The spec (007) already carries zero `NEEDS CLARIFICATION` markers — every product ambiguity was resolved with a documented default in its Assumptions section. This document resolves the remaining *technical/design* decisions needed to start Phase 1 design, and explicitly reuses the precedents already set by spec 001 (`people`/`transactions`) wherever they apply, per the constitution's Refactoring Discipline ("do not duplicate existing infrastructure").

## 1. Relationship to the existing `MoneyTransactions` table/feature

**Decision**: `FinanceEntries` is a brand-new table/feature, structurally parallel to (never merged with, never a subtype of) `MoneyTransactions`.

**Rationale**: `MoneyTransactions` is permanently anchored to a `Person` (`personId` is `NOT NULL`, `references People(id)`) and its `direction`/`kind` enums encode debt semantics (given/received, initial exchange/repayment) that feed the person balance calculation. Income/expense entries have no person and no debt semantics — forcing them through the same table would mean making `personId` nullable and reinterpreting `direction` for a second, unrelated meaning, which is exactly the kind of unnecessary refactor of stable, working code the constitution's Refactoring Discipline and the user's own instructions prohibit. Keeping them separate also makes FR-023 ("MUST NOT alter... the existing person-to-person Transactions data model") trivially true by construction rather than something to verify.

**Alternatives considered**: Extending `MoneyTransactions` with a nullable `personId` and a new `kind` (`income`/`expense`) — rejected: touches a shipped, tested feature (spec 001) for no benefit, and would make every existing balance query need a `personId IS NOT NULL` guard it doesn't need today. A generic polymorphic "ledger" table covering both concepts — rejected as speculative/premature abstraction (constitution: "no unjustified abstractions"); nothing today needs to query both concepts through one interface, and Budgets/AI (later features) are specified to read from `FinanceEntries`/`Category`, not from a merged ledger.

## 2. Database schema addition and migration

**Decision**: Two new `drift` tables added to the existing `AppDatabase`: `FinanceCategories` and `FinanceEntries`. `schemaVersion` bumps 4 → 5; the `onUpgrade` migration adds `if (from < 5) { await m.createTable(financeCategories); await m.createTable(financeEntries); }`, then seeds the default category rows (Decision 3) inside that same migration step. No existing table is altered.

**Rationale**: Matches the exact additive-migration pattern already used for `AppSettings` (v2), `themeMode` (v3), and `OnboardingStatus` (v4) in `app_database.dart` — a proven, low-risk convention for this codebase. Seeding defaults inside the migration (rather than lazily on first repository read) guarantees every existing installed user gets the starter categories exactly once, deterministically, with no "first app-open after update" race.

**Alternatives considered**: A separate database/file for finance data — rejected, adds a second connection/lifecycle to manage for no isolation benefit (single local SQLite file is the established pattern, research.md Decision 11 in spec 001). Lazy seeding on first `GetCategories()` call — rejected, harder to test deterministically and risks a visible empty-state flash before seeding completes.

## 3. Default category seeding

**Decision**: A fixed, versioned seed list (12 expense + 6 income categories, taken verbatim from `docs/project.txt` §4) is inserted as ordinary rows (`isDefault = true`, `isArchived = false`) during the v5 migration. They are editable/archivable like any other category (FR-009/FR-010) — "default" only means "pre-populated," not "protected."

**Rationale**: Directly satisfies FR-006 ("available immediately on first use, without requiring the user to create any category"). Using real rows (not a hardcoded enum switched on in the UI) keeps `CategoryManagementCubit` and the category picker ignorant of any "default vs custom" branching — they only ever deal with `Category` entities from the repository, which is simpler and matches how `Person.relationshipTag` was deliberately left as free-form data rather than an enum.

**Alternatives considered**: A hardcoded `enum DefaultCategory` merged with a separate custom-category table at query time — rejected, doubles the code paths every screen must handle (list, pick, rename, archive) for no real benefit, and would make "rename a default category" (FR-009) awkward since enums aren't mutable.

## 4. Category removal: archive vs. hard delete

**Decision**: `CategoryRepository.removeCategory(id)` checks (via a `COUNT(*)` against `FinanceEntries.categoryId`) whether the category has ever been used. Zero uses → hard `DELETE`. One or more uses → set `isArchived = true` (never deleted). Identical branching logic to `ArchivePerson`/hard-delete-eligibility already established in `people`.

**Rationale**: Directly implements FR-010/FR-011 and the constitution's "financial records MUST NEVER be silently modified" — an entry's category must always resolve to a real row so its name/icon can render in history, forever, even after removal from active use. Reuses the exact `isArchived` boolean pattern already proven on `People`, keeping the codebase's vocabulary for "soft-remove but preserve history" consistent across features (constitution Code Review Mode: "does it duplicate existing code? is there a simpler solution?").

**Alternatives considered**: Always soft-archive, never hard-delete — rejected, would let a user accumulate unlimited never-used accidental categories with no way to actually remove them, which the spec's User Story 4 (Acceptance Scenario 5) explicitly requires to be a real delete. A `categoryName` string snapshot stored directly on each `FinanceEntry` (denormalized, so the category row could always be deleted) — rejected, breaks FR-009 (renaming a category must retroactively update all past entries), which requires a live foreign key, not a point-in-time copy.

## 5. Duplicate category name check (FR-008)

**Decision**: Before insert, the repository normalizes the candidate name (trim, collapse whitespace, lowercase — same normalization already implemented for `Person.normalizedName` in `people`) and checks for an existing **active** (non-archived) category of the same `type` with an identical normalized name. A match returns a `DuplicateCategoryFailure` the Cubit surfaces as a validation message pointing at the existing category.

**Rationale**: Reuses `people`'s exact normalized-name-matching approach (`idx_people_normalized_name` precedent) rather than inventing a new string-comparison convention. Scoping the check to `type` (income vs. expense) and to *active* categories only is required so that re-creating a category with the same name as one the user already archived is allowed — archiving is an active choice to retire a name, not a permanent reservation of it.

**Alternatives considered**: Case-sensitive exact match only — rejected, trivially defeated by "Groceries" vs. "groceries," which is exactly the near-duplicate the spec's edge case is guarding against. Blocking duplicate names across both income and expense types — rejected, "Gift" is a perfectly reasonable category name for both an income source and an expense, and the spec's edge case explicitly scopes the check "for the same type."

## 6. Period selection and totals calculation

**Decision**: Periods are computed as inclusive date ranges (`[startDate, endDate]`, both `DateTime` at day granularity) resolved by the Domain layer, not by raw month-number string matching: "this month" = first day of the device's current month to today; "last month" = the full previous calendar month; "custom range" = user-picked `[start, end]`. `GetFinanceSummary(period)` and `GetFinanceHistory(filter)` both run a single `SUM(amountMinorUnits) ... WHERE date BETWEEN ? AND ? AND deletedAt IS NULL GROUP BY type` (and a second `GROUP BY categoryId` query for the breakdown) against `drift`, mirroring the SQL-aggregate approach `GetOverview` already uses in `transactions` rather than summing in Dart.

**Rationale**: Directly satisfies FR-014/FR-015/FR-016 and SC-003's zero-rounding-discrepancy requirement (an SQL `SUM` over integer minor units cannot drift). Keeping period-range math in Domain (not Presentation) keeps it unit-testable without a widget tree, and keeps "what does 'this month' mean" defined in exactly one place.

**Alternatives considered**: Loading all entries for the period into Dart and summing/grouping client-side — rejected, works at small scale but does the same category of work `GetOverview` already deliberately avoids doing in Dart, and fails the SC-006-equivalent performance ceiling faster as entry count grows.

## 7. Idempotent save / duplicate-entry protection

**Decision**: Identical mechanism to `MoneyTransactions.idempotencyKey` (spec 001, Decision 5) — the Presentation layer generates a UUID idempotency key on "Save," disables the control immediately, and `FinanceEntries.idempotencyKey` carries a `UNIQUE` index; a retried insert with the same key is a no-op returning the existing row.

**Rationale**: Directly implements FR-021, and reusing the exact proven mechanism from `transactions` is strictly simpler than inventing a second duplicate-protection strategy for what is the same underlying problem (constitution: "avoid... unjustified abstractions," but equally "avoid... duplicated shared components" — here the *pattern* is reused, not a shared code module, since the two tables are intentionally separate per Decision 1).

**Alternatives considered**: UI-only debounce — rejected for the same reason spec 001 rejected it (doesn't survive a process restart mid-retry).

## 8. Edit/delete traceability and undo

**Decision**: `FinanceEntries` carries `createdAt`, `editedAt` (nullable), `deletedAt` (nullable soft-delete tombstone) — same shape as `MoneyTransactions`. Unlike `transactions` (whose deletion is presented as permanent, per spec 001's FR-016), this feature's spec (FR-020) explicitly requires a short-window **undo** after delete. `DeleteFinanceEntry` commits the soft-delete (`deletedAt = now`) immediately — it is not deferred — and the Presentation layer separately shows a ~5-second undo affordance; tapping it calls a new `RestoreFinanceEntry` use case that un-sets `deletedAt`. If the undo window simply expires (or the app is backgrounded/killed during it), the delete already committed and nothing further happens — there is no "pending, not-yet-committed" state to lose.

**Rationale**: Satisfies FR-020 while reusing the exact `deletedAt` column shape already proven on `MoneyTransactions`, and is safe by construction against process death during the undo window — a delayed-commit design (only writing `deletedAt` once the undo window expires) was considered but rejected precisely because it introduces a "delete not yet persisted" state that a kill/crash could silently lose, which the constitution's Financial Domain Override treats as unacceptable for a financial mutation.

**Alternatives considered**: Delayed commit — hold the deletion in memory for the undo window and only call `DeleteFinanceEntry` once it expires — rejected for the process-death risk above. A dedicated `PendingDeletion` table to persist the undo window across app restarts — rejected as disproportionate complexity for a 5-second UX affordance (constitution: prefer the simplest option with the best overall balance).

## 9. Navigation placement

**Decision**: A new `/finance` route added to the existing People `StatefulShellBranch` (the same branch that already hosts `/transactions/new`, `/people/:id`, etc.) rather than a fourth bottom-navigation tab, with an entry point surfaced from the Overview tab (a "This Month" finance summary card linking into it) and from a quick-action. Final tab-bar iconography/labels are a UI-polish detail decided at the widget-implementation step, not a routing-architecture one.

**Rationale**: The spec leaves exact placement as an Assumption ("decided at planning time"). Avoiding a fourth bottom-nav tab now keeps the tab bar stable while the roadmap still has Occasions/Budgets/Savings pending — those will very likely also want a presence in navigation, and deciding the app's final information architecture piecemeal, one tab per feature, risks an unreviewed cluttered bottom nav by V2. A single additional route nested in the existing People branch is the minimal, reversible choice; the Home Dashboard feature (next in the V1.5 plan) is the right place to make a holistic navigation-architecture decision once more of the roadmap's shape is known.

**Alternatives considered**: New fourth bottom-nav tab now — rejected as premature per above. Nested only under Settings — rejected, buries a P1 daily-use feature behind a low-frequency screen.

## 10. Category icon/color representation

**Decision**: `Category.icon` stores a string key from a fixed, curated icon set (e.g. `'groceries'`, `'rent'`, `'salary'`, `'other'`) mapped to a `Material`/`Cupertino`-agnostic icon glyph and a design-token color by a small `CategoryIconRegistry` in `features/finance/presentation/widgets/` — not a raw `IconData` codepoint or a free-form hex color persisted per category.

**Rationale**: Persisting a raw `IconData`/hex color would violate constitution Principle XV (no hardcoded design values scattered per-record) and couple stored data to a specific icon font's codepoints across app versions/icon-font upgrades. A string key is stable, themeable (light/dark colors derive from the design system, not the stored value), and gives custom categories (FR-007) a bounded, curated picker rather than an unbounded color/icon picker that would be harder to keep legible in both RTL and dark mode.

**Alternatives considered**: Free-form color picker + icon font codepoint stored per category — rejected per Principle XV and for the dark-mode/RTL-legibility risk noted above.

## 11. Testing approach specifics

**Decision**: Same three-tier approach as `transactions` (spec 001, Decision unchanged): use-case/repository unit tests against an in-memory `drift` DB, Cubit tests with `bloc_test`/`mocktail`, and one `integration_test/finance_flows_test.dart` covering this feature's User Stories 1-5 end-to-end. Category archive/delete branching (Decision 4) and the duplicate-name check (Decision 5) get dedicated repository-level unit tests since they are this feature's highest-risk business rules.

**Rationale**: Constitution Principle XVI; consistency with the established testing shape avoids introducing a second testing convention for no reason.

**Alternatives considered**: None — this is a direct precedent reuse, not an open design question.
