# Daftary Roadmap Implementation Plan (V1.5 → V2 → V3)

**Created**: 2026-09-22
**Status**: Draft — planning only, nothing in this document has been implemented
**Scope**: This is a program-level plan spanning multiple future features, most of which do not have their own `/speckit-specify` spec yet. It complements, and does not replace, the per-feature artifacts under `specs/<NNN-feature>/` (`spec.md`/`plan.md`/`research.md`/`data-model.md`/`contracts/`/`tasks.md`). **007-income-expense-tracking already has a complete spec + plan** (see `specs/007-income-expense-tracking/`) and is treated here as V1.5's first, already-planned feature. Every other feature below still needs its own `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` cycle before implementation starts — this document is the map that sequences those cycles and keeps them architecturally consistent with each other.

## ✅ Working Assumptions — Confirmed by Product Owner (2026-09-22)

The `/speckit-clarify` pass raised 5 architecture-defining questions. The product owner has now confirmed 4 of them (via direct Q&A); the 5th (Savings accounting) was a low-risk default that was never contested and is treated as confirmed by implementation (spec 011 already ships it).

| # | Question | Confirmed answer | Where it matters |
|---|---|---|---|
| 1 | V1.5/V2/V3 phase assignment | **Confirmed**: proposed dependency-driven order (this document) — used as-is | Entire roadmap sequencing |
| 2 | Occasion money vs. Person balance | **Confirmed**: new nullable `occasionId` on `MoneyTransactions`, excluded from balance aggregation | Occasions §V2.1 (spec 008) |
| 3 | AI Assistant provider/backend | **Confirmed**: bring-your-own-key, secure on-device storage, no backend | AI Assistant §V2.5 (not yet spec'd — next up) |
| 4 | OCR: on-device vs. cloud | **Confirmed**: on-device only (ML Kit / Vision), swappable provider interface | OCR §V2.4 (spec 009) |
| 5 | Savings contribution accounting | **Confirmed** (uncontested default): separate `SavingsContribution` entity, excluded from Income/Expense totals | Savings §V2.3 (spec 011) |

**Backend decision — confirmed 2026-09-22: no backend.** Daftary stays a fully local, offline-only, single-device app. **V3.5 Cloud Backup/Sync and V3.6 Family/Shared Finances are dropped from the active roadmap** (not deferred — out of scope unless the product direction changes later). Every other item in this document (V1.5/V2, plus V3.1/3.2/3.3/3.4) is unaffected and fully spec'd.

---

## 1. Current Implementation Analysis

**Implemented (V1)** — treated as a stable foundation, not touched except where explicitly noted:

| Feature | Location | Notes |
|---|---|---|
| People | `lib/features/people/` | Contacts, relationship tag (free text), archive/restore, duplicate-name detection |
| Transactions | `lib/features/transactions/` | Person-to-person `given`/`received`, `initialExchange`/`repayment`, soft-delete + audit trail, idempotency keys, Overview totals |
| Settings | `lib/features/settings/` | Language (`AppLanguage`), theme (`AppThemeMode`) |
| Onboarding | `lib/features/onboarding/` | First-launch intro sequence |

**Shared infrastructure available for reuse** (do not duplicate):

- `core/database/app_database.dart` — single `drift`/SQLite `AppDatabase`, additive-migration convention (`schemaVersion` 1→4 already), plus `balance_queries.dart` (cross-feature balance aggregation, extension on `AppDatabase`)
- `core/money/` — `Money` (integer minor units), `EgpFormatter`, `numeral_parser.dart` (Arabic-Indic digit normalization) — reusable by every future money-handling feature
- `core/design_system/` — `tokens.dart`, `AppButton`, `AppTextField`, `AppDateField`, `AppCard`, `AppConfirmDialog`, `AppEmptyView`, `AppIconBadge`
- `core/di/` — `get_it` + `injectable` codegen (`injection.dart`, `injection.config.dart`, `register_module.dart`)
- `core/error/failure.dart` — typed `Failure` hierarchy, `fpdart` `Either<Failure, T>` result flow
- `core/l10n/` — `gen_l10n` ARB (`app_en.arb`/`app_ar.arb`), `device/device_locale_provider.dart`
- `core/routing/app_router.dart` + `main_shell.dart` — `go_router` `StatefulShellRoute.indexedStack`, 3 branches today (People/Overview/Settings)

**Architecturally significant gap found during analysis**: the app has **zero networking, zero backend, zero camera/OCR, zero secure-storage dependency** in `pubspec.yaml` today. It is a fully local, offline-only, single-device app. This is the direct cause of clarify questions 3 and 4 — AI Assistant and OCR are the first two features in this entire roadmap that need something the app has never needed before (network access, and either a camera or a secrets vault). Every other planned feature (Occasions, Budgets, Savings, Reports) fits the existing local-only shape without any new capability class.

**Partially implemented**: "Dashboard" exists only as `OverviewPage` (balance totals) — no quick actions, no income/expense snapshot, no insights section (see Home Dashboard, §V1.5.2).

**Missing entirely** (this document's subject): Income & Expense Tracking (007, spec+plan done), Home Dashboard, Reports & Data/Privacy Controls, Occasions, Budgets, Savings, OCR, AI Assistant, and the V3 items in §4.

---

## 2. V1.5 — Core Product Expansion

### V1.5.1 — Income & Expense Tracking ✅ spec'd + planned

Already fully specified (`specs/007-income-expense-tracking/spec.md`) and planned (`plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`). Summarized here only for roadmap completeness — see those files for the full detail (screens, entities, BLoC, task-level detail is generated by `/speckit-tasks` against that spec, not duplicated here).

- **Objective**: personal income/expense entries with customizable categories, separate from person-to-person `MoneyTransactions`.
- **New feature module**: `lib/features/finance/` (`FinanceEntry`, `Category` entities; `FinanceRepository`, `CategoryRepository`).
- **New tables**: `FinanceEntries`, `FinanceCategories` (schema v4→v5).
- **Establishes**: the `Category` vocabulary Budgets (§V2.2) reads from, and the `FinanceRepository` aggregation Budgets/Reports/AI Assistant all reuse — this is why it must ship first.

### V1.5.2 — Home Dashboard

**Objective**: turn the existing `OverviewPage` into the product's real "financial snapshot + quick actions" home, per `docs/project.txt` §12, without disrupting the existing People-as-first-tab navigation muscle memory.

**Dependency**: V1.5.1 (needs `GetFinanceSummary` for the income/expense card).

**Screens**: 1 — the existing `/overview` route, extended (not replaced) in place.

**Sections** (progressive disclosure, per the brief — do not overload):
- Financial Snapshot: existing owed-to-me/owed-by-me totals (reuse `GetOverview`, unchanged) + this-month income/expense/net (reuse `GetFinanceSummary` from 007, unchanged) side by side.
- Quick Actions: Add Expense, Add Income, Add Person, Add Money Received/Given (all reuse existing routes/forms — no new forms built here). Add Occasion and Scan Paper actions are added later, wired but hidden/disabled behind a feature flag until §V2.1/§V2.4 ship, so this screen's layout doesn't need rework each time a V2 feature lands.
- Insights: an honest empty state ("Insights arrive once the AI Assistant is set up") until §V2.5 ships — **never a fake/static insight**, matching the product brief's explicit instruction and the constitution's non-authoritative-AI principle.
- Upcoming: an honest empty state until Budgets/Savings (§V2.2/§V2.3) exist to populate it.

**Domain/Data**: no new entities or tables. One new use case: `GetDashboardSnapshot` (Domain) — coordinates `GetOverview` + `GetFinanceSummary` in parallel; justified as a use case (not a bare passthrough) because it's genuine multi-repository coordination per constitution Principle V.

**BLoC**: `DashboardCubit` (replaces `OverviewCubit` 1:1, or `OverviewCubit` is renamed/extended — decided at that feature's own `/speckit-plan`).

**Navigation**: no new route; `/overview` is relabeled "Home" in the tab bar. **Open IA question** (see §9 and Blockers): whether People stays tab 1 or Home becomes tab 1 is a product call, not an architecture one — flagged for a lightweight decision when this feature is specified.

**States**: loading (both aggregates in flight), success, partial-error (one aggregate fails, show the other + inline retry for the failed card — never block the whole screen on one failure), empty (brand-new install, zero people and zero finance entries: a single combined first-run empty state, not two separate ones).

**Localization/RTL/theme**: reuses existing `Overview` i10n keys + adds finance-snapshot and quick-action labels; no new localization pattern.

### V1.5.3 — Reports & Data/Privacy Controls

**Objective**: give the user spending/income trend visibility over time (`docs/project.txt` §12 "Insights"/§35 "Reports" screen) and the privacy controls §16 explicitly requires (data export, account/data deletion) — bundled into one V1.5 slot because both are low-architectural-risk, high-trust-value, and neither blocks or is blocked by any other roadmap item.

**Dependency**: V1.5.1 (Reports reads `FinanceRepository`; export includes `FinanceEntries`/`Category` alongside existing `People`/`MoneyTransactions`).

**Screens**: `ReportsPage` (category breakdown + a simple monthly income/expense trend, reusing `GetCategoryBreakdown`/`GetSummary` across multiple periods — no new aggregation query, just multiple calls to the existing one), `DataExportPage` (choose scope → generate → share via OS share sheet), a "Delete My Data" confirmation flow inside `SettingsPage`.

**New use cases**: `GetSpendingTrend` (Domain, calls `GetSummary` once per period in a range — coordination, not new SQL), `ExportUserData` (serializes People/Transactions/FinanceEntries/Categories/Settings to CSV), `DeleteAllUserData` (wipes every table, resets Onboarding so the app behaves like a fresh install — never a partial wipe).

**New dependency required**: a share-sheet package (e.g. `share_plus`) to hand the exported file to the OS share/save flow — no existing capability covers this; justified as the minimal addition for a hard privacy requirement (`docs/project.txt` §16), not a nice-to-have.

**Validation/confirmation**: `DeleteAllUserData` requires a strong, explicit, typed-confirmation dialog (constitution Financial Domain Override — this is the single most destructive action in the app) before executing; irreversible, no undo.

**States**: Reports — loading/empty (no data yet)/success/error with retry; Export — idle/generating/ready-to-share/error; Delete — confirmation → in-progress (blocking, short) → success (returns to Onboarding) → error (nothing partially deleted — must be transactional).

**Localization/RTL/theme**: chart labels, export/delete copy, all ar/en; charts must mirror correctly in RTL (axis/legend direction) — see §7.

---

## 3. V2 — Major Features

Build order within V2 (dependency-driven, per clarify Q1 assumption): **Occasions → Budgets → Savings → OCR → AI Assistant**. Occasions has no hard dependency on V1.5.1 and could technically be built in parallel with it, but is sequenced after V1.5 to respect your explicit "V1 → V1.5 → V2 → V3, do not jump ahead" instruction.

### V2.1 — Occasions

**Objective**: let the user create an Occasion (e.g. "Ahmed's Wedding"), associate People, record money given/received tied to it, and see totals/history — **without** inventing a second transaction system, and **without** corrupting the existing person-balance ("who owes whom") calculation with money that was never meant to be repaid.

**Dependencies**: People, Transactions (both existing, V1). Independent of V1.5.

**The core design decision** (clarify Q2, assumed Option A): add a **nullable `occasion_id`** column to the existing `MoneyTransactions` table (FK → new `Occasions.id`), and modify the three balance-aggregation queries in `core/database/balance_queries.dart` (`netBalanceMinorUnitsForPerson`, `netBalanceMinorUnitsForAllPeople`, `lastActivityMillisForAllPeople`) to add `AND occasion_id IS NULL` to the existing `WHERE deleted_at IS NULL` clause. Occasion-linked transactions remain fully visible in that person's transaction history (a separate, unfiltered query already exists — `GetPersonHistory` is unaffected) but are excluded from "who owes whom." This is a minimal, surgical, justified change to stable code (constitution Refactoring Discipline: "improve it incrementally rather than leaving the bad pattern in place" — the *bad pattern* being that, without this change, every wedding gift would silently and incorrectly become a debt).

**Correction (post-`/speckit-analyze`, 2026-09-22)**: this document originally assumed no new `TransactionKind` would be introduced. `specs/008-occasions-social-money/plan.md`'s actual, more-considered design **does** widen `TransactionKind` with a new `occasionContribution` value plus a `countsTowardBalance` column, rather than only a nullable `occasionId` tag on an existing `initialExchange` kind. That spec/plan is authoritative — this paragraph is retained only as a record of the original (superseded) assumption. **Consequence**: this reopens the blast radius the original assumption said it was avoiding — every existing `TransactionKind`-switch site in the People/Transactions UI (icons, formatters, filters, history rendering) must be audited and updated for the new kind. `specs/008-occasions-social-money/tasks.md` MUST include an explicit task enumerating and updating every such call site before 008 is considered done; confirm this at 008's own implementation kickoff if it is not already itemized.

**New entities**:
- `Occasion`: `id`, `name` (required), `occasionType` (free-text + suggested chips — wedding/engagement/birthday/newborn (سبوع)/condolence/celebration/family/other — **not** a closed enum, per the brief's explicit instruction not to assume Egyptian terminology; mirrors the existing `Person.relationshipTag` pattern), `date`, `notes`, `isArchived`, `createdAt`, `updatedAt`.
- No new transaction/contribution entity — a contribution *is* a `MoneyTransaction` with `occasionId` set.

**New use cases**: `CreateOccasion`, `EditOccasion`, `ArchiveOccasion`/`DeleteOccasion` (delete only if zero linked transactions, else archive-only — same branching precedent as `Category` removal in 007 and `Person` archiving in V1), `AddOccasionContribution` (thin wrapper around the **existing** `AddTransaction` use case with `occasionId` supplied — reuses person duplicate-detection via the **existing** `FindPossibleDuplicatePerson`, does not reimplement it), `GetOccasionDetails` (totals given/received + participant list, derived from `MoneyTransactions WHERE occasion_id = ?`), `GetOccasions` (list, filter by type/date/archived).

**Screens**: `OccasionsListPage`, `OccasionFormPage` (create/edit), `OccasionDetailPage` (totals, participant list, per-occasion transaction history, "Add Contribution" CTA reusing the existing transaction-form person picker).

**BLoC**: `OccasionListCubit`, `OccasionFormCubit`, `OccasionDetailCubit`.

**Navigation**: `/occasions`, `/occasions/new`, `/occasions/:id`, `/occasions/:id/edit`. This is the point in the roadmap where a genuine 4th bottom-nav tab becomes defensible (Occasions is a primary pillar per the brief, not a secondary feature) — see §9 for the full navigation-architecture note; not a blocker for building the feature itself, which can ship nested under Home's quick actions first and be promoted to a tab later without any code change beyond `app_router.dart`/`main_shell.dart`.

**Validation**: `name` required non-empty; `date` required; contribution amount `> 0` (reuses existing `MoneyTransaction` validation); at least implicit — an occasion can exist with zero contributions (create-then-add-later flow).

**States**: list — loading/empty ("No occasions yet — create one for your next wedding, birthday, or gathering")/success/error; detail — loading/empty (occasion exists, zero contributions yet)/success/error; search/filter by type and archived status.

**Localization/RTL/theme**: occasion-type chip labels ar/en; totals formatting reuses `core/money`; date reuses existing date-field component.

### V2.2 — Budgets

**Objective**: monthly, per-category expense limits with progress/alerts, reading spend from the **existing** V1.5.1 `FinanceRepository` — never a second spend-aggregation path.

**Dependency (hard)**: V1.5.1 (`Category`, `FinanceEntry`, `FinanceRepository.getCategoryBreakdown`). Cannot start before V1.5.1 ships — this is the dependency your original task instructions flagged as needing explicit identification, and it's why Budgets is sequenced after Income/Expense Tracking rather than earlier.

**New entity**: `Budget` — `id`, `categoryId` (FK → `Category`, must be an **expense**-type category), `limitMinorUnits` (`> 0`), `periodMonth` (which calendar month this limit applies to, recurring behavior at creation time = "apply to future months too" vs. one-off — default: recurring, editable per month going forward), `isArchived`, `createdAt`, `updatedAt`. One active budget per `(categoryId, periodMonth)` — duplicates rejected, same shape as 007's duplicate-category-name check.

**New use cases**: `CreateBudget`, `EditBudget`, `RemoveBudget` (archive-if-has-history else delete, same precedent as Category/Person/Occasion), `GetBudgetOverview` (joins `Budget` rows for the current period with `FinanceRepository.getCategoryBreakdown(period)` — **calls the existing 007 use case, does not duplicate its SQL**), computes planned/actual/remaining/percentage-used per category and an aggregate total.

**Screens**: `BudgetOverviewPage` (progress bars per category, aggregate planned/actual/remaining, warning badges), `BudgetFormPage` (pick an expense category not already budgeted this period, set a limit).

**BLoC**: `BudgetOverviewCubit`, `BudgetFormCubit`.

**Alerts**: deterministic, threshold-based (e.g. 80%/100% of limit), computed client-side from `GetBudgetOverview` — **no AI involvement** (constitution Principle VIII). In-app badge/banner for V2; a push/local *notification* for an over-budget category is deferred to V3 (§4) since the app has no notification infrastructure yet and it isn't worth adding just for this one alert type in isolation — bundled with Savings-goal and bill reminders into one V3 notifications epic instead.

**Currency**: EGP only, matching the rest of the app — no new currency handling.

**States**: empty (no budgets set for this month — CTA to create one, and this state is distinct from "no expense categories exist," which shouldn't be reachable since 007 seeds defaults), loading, success, per-card over-budget warning, error with retry.

### V2.3 — Savings

**Objective**: savings goals with target amount/date, contributions, and progress — kept deliberately **separate** from the Income/Expense ledger (clarify Q5, assumed Option A) so a contribution never double-counts as "spending."

**Dependency**: none on V1.5.1 or Budgets — independently buildable, sequenced here per the roadmap order in §1 of this doc, not because of a technical blocker.

**New entities**:
- `SavingsGoal`: `id`, `name`, `targetAmountMinorUnits` (`> 0`), `targetDate` (nullable), `icon`/label (free text like `Occasion.occasionType`, e.g. "New Car," "Wedding," "Emergency Fund"), `isArchived`, `createdAt`, `updatedAt`. `currentAmountMinorUnits` and `isCompleted` are **derived** (summed from contributions / `current >= target`), never stored mutable columns — same "never cache a value that can drift" principle already applied to `PersonBalance` in V1.
- `SavingsContribution`: `id`, `goalId` (FK), `amountMinorUnits` (`> 0`), `date`, `note`, `createdAt`, `editedAt`, `deletedAt` (soft-delete, same shape as `FinanceEntry`).

**New use cases**: `CreateSavingsGoal`, `EditSavingsGoal`, `RemoveSavingsGoal` (archive-if-has-contributions else delete), `AddContribution`, `EditContribution`, `DeleteContribution`, `GetSavingsGoalDetail` (progress + contribution history), `GetSavingsGoals` (list), `ProjectSavingsCompletion` — a **deterministic** calculator (not AI) directly answering the brief's §6 questions ("how much per month," "what if I add 1,000 more," "how long until goal") via simple arithmetic over `(target - current) / monthlyRate`.

**Screens**: `SavingsGoalsListPage`, `SavingsGoalFormPage`, `SavingsGoalDetailPage` (progress ring/bar, projected-completion display, contribution history, "Add Contribution" CTA, an interactive "what if I save X more/month" input backed by `ProjectSavingsCompletion`).

**BLoC**: `SavingsGoalListCubit`, `SavingsGoalFormCubit`, `SavingsGoalDetailCubit`.

**Completion behavior**: reaching/exceeding the target flips the goal to a completed visual state with a positive micro-interaction (confetti/checkmark, respecting reduced-motion settings) — the goal is **not** auto-archived; the user can keep contributing past target or raise the target.

**States**: empty (no goals — "Set your first savings goal"), loading, success, completed (distinct celebratory state), error with retry.

### V2.4 — OCR Scanning

**Objective**: Camera/Upload → Crop → OCR → Extract → Review/Edit → Save, producing **existing** `MoneyTransaction` rows (via the existing `AddTransaction` use case) — never a parallel transaction system, never an auto-saved transaction without confirmation (constitution Principle X, non-negotiable).

**Dependency**: People, Transactions (existing). **Correction (post-`/speckit-analyze`, 2026-09-22)**: this was originally described as an optional/soft dependency on Occasions. `specs/009-ocr-paper-entry/plan.md`'s actual design hard-reuses `core/media/AttachmentPickerService`, which is introduced by 008 — 009 cannot compile or ship before 008 is implemented. This is a genuine blocking dependency, not an optional enhancement; the implementation wave order below (008 in Wave 3, 009 in Wave 4) already satisfies it and should be treated as intentional sequencing, not coincidence.

**Architecture decision** (clarify Q4, assumed Option A): **on-device OCR only** — Google ML Kit text recognition on Android, Apple Vision (via a platform channel or an ML-Kit-equivalent plugin) on iOS — behind an `OcrService` interface so a cloud/backend provider can be substituted later without touching the rest of the flow. No backend is introduced for this feature.

**New dependencies required** (all justified — no existing capability covers camera/OCR): `camera` (capture), `image_picker` (upload-existing-photo alternative), an on-device OCR plugin (e.g. `google_mlkit_text_recognition`), a crop/rotate widget or minimal custom crop UI.

**Flow, mapped to entities/use cases**:
1. **Capture/Upload** — `CaptureOrPickImage` use case; requests camera permission **contextually** at this exact step (constitution: never all at startup), with a clear rationale shown on denial and a link to app settings.
2. **Crop/Adjust** — presentation-only image manipulation, no domain entity.
3. **OCR** — `ExtractTextFromImage` use case → `OcrService.extractText(imagePath)`. Failure (no text detected / very poor image quality) surfaces a retry-or-manual-entry state, never a silent empty result.
4. **Parse** — `ParseTransactionCandidates` use case: deterministic Dart parsing of the raw OCR text into candidate rows (name, amount, inferred direction), **reusing the existing `core/money/numeral_parser.dart`** for Arabic-Indic/Western digit normalization — no new numeral-parsing logic. Each candidate gets a simple deterministic confidence flag (not an ML score) based on whether a valid amount and a plausible name were both extracted.
5. **Review/Edit** — `OcrReviewPage`: every field editable, low-confidence rows visually flagged, **reuses the existing `FindPossibleDuplicatePerson`** so a scanned name matches an existing Person instead of always creating a new one.
6. **Confirm/Save** — `ConfirmAndSaveScannedTransactions`: each confirmed row is saved independently via the **existing** `AddTransaction` use case with its own idempotency key (rows are independent transactions, not one atomic batch — a partial success with a per-row summary is acceptable and clearer than an all-or-nothing failure).

**Privacy** (`docs/project.txt` §16): the captured image lives only in the app's cache directory for the duration of the review flow and is deleted immediately after save or cancel — never retained long-term, never uploaded anywhere (on-device OCR means it never leaves the device at all).

**Entities**: **Correction (post-`/speckit-analyze`, 2026-09-22)**: this document originally assumed no new persisted table (ephemeral session data only). `specs/009-ocr-paper-entry/plan.md`'s actual design persists two tables — `OcrScans` and `CandidateEntries` — plus `source`/`ocr_scan_id` columns on `MoneyTransactions`, for audit/dedup reasons this document didn't anticipate. That spec/plan is authoritative; see the corrected migration table in §13.

**States**: permission-denied, capture-ready, cropping, OCR-processing (loading), OCR-failed (retry/manual-entry), review (with per-row confidence flags), saving, partial-success summary, full-success.

### V2.5 — AI Assistant

**Objective**: a real, non-fake financial Q&A assistant answering from the user's actual local data — **never** the source of truth for a calculation (constitution Principle VIII/IX, already written for exactly this).

**Dependency**: benefits from every prior feature existing as real data to answer from (Transactions, Occasions, Budgets, Savings, Income/Expense) — this is *why* it is sequenced last in V2, not because of a technical blocker on any single one of them.

**Architecture decision** (clarify Q3, assumed Option A): **bring-your-own-key**. The user enters their own API key for a provider of their choice in Settings; it is stored via OS secure storage (Keychain/Keystore — new `flutter_secure_storage` dependency, justified: no existing secure-storage capability exists), never hardcoded, never an app-owned secret. This is the **only feature in the entire app that makes a network call**, and it is called out explicitly here so that decision stays visible and isolated rather than quietly expanding the app's network footprint.

**Layering** (maps directly onto constitution Principle IX, which was written in anticipation of exactly this feature):

```text
ChatPage (Presentation)
  → ChatCubit (Presentation state)
    → AskFinancialQuestion (Domain use case)
      → FinancialContextBuilder (Domain use case — assembles a structured,
         minimal snapshot by calling EXISTING use cases: GetFinanceSummary,
         GetCategoryBreakdown, GetPersonBalance, GetBudgetOverview,
         GetSavingsGoalDetail — never raw DB access)
      → AIAssistantRepository (Domain interface)
        → AIAssistantRepositoryImpl (Data)
          → AIService (Data interface — swappable provider)
            → AnthropicAIService / [user's chosen provider] (Data, holds the
               HTTP call; reads the API key from secure storage, never from
               source code or a build-time constant)
```

**Function/tool calling, not a raw data dump**: the model is given a small set of structured tools (`getCategorySpend`, `getPersonBalance`, `getSavingsProjection`, `getBudgetStatus`, etc.), each of which calls an **existing** deterministic use case — the model never receives (and cannot request) more data than a given question needs, and it never performs the arithmetic itself.

**Scope for V2 (deliberately)**: **read-only / Q&A and insights only.** The model answers questions and can proactively surface a deterministically-computed observation (e.g., "you spent 18% more on restaurants this month" — a real number from `GetCategoryBreakdown`, phrased by the model, not invented by it). It **cannot** create, edit, or delete any record in V2. A future "AI proposes an action, user confirms, then an existing use case runs" mode (mirroring OCR's human-in-the-loop pattern exactly) is a natural, low-risk extension once Q&A is proven — scoped to V3 (§4.5) rather than V2, to keep V2's first AI release small and reviewable, consistent with "do not add AI just because it sounds cool."

**Conversation state**: one continuous, clearable local conversation history (`AIConversations`/`AIMessages` tables) — not multi-thread for V2; simpler UX, matches the "someone who remembers my money for me" framing, and multi-thread can be added later without a data-model change (just a `conversationId` grouping already present in the table shape).

**Privacy/consent**: AI Assistant is off by default; enabling it requires entering a provider API key and accepting an explicit data-sharing disclosure (Settings). Can be disabled at any time, which stops all outbound calls immediately (`docs/project.txt` §16, a direct requirement).

**Offline behavior**: this is the one feature that inherently needs a network connection. Offline → a clear, friendly "AI Assistant needs an internet connection" state; the rest of the app is completely unaffected and remains fully offline-capable as before.

**Screens**: `AIAssistantEntryPoint` (Home quick action/nav), `ChatPage`, `AISettingsPage` (provider choice, secure API-key entry, consent toggle, clear-conversation action).

**BLoC**: `ChatCubit`, `AISettingsCubit`.

**Error handling**: typed failures (`InvalidApiKeyFailure`, `RateLimitFailure`, `NetworkFailure`, `ProviderFailure`) surfaced as friendly localized messages with retry — never a raw exception or raw provider error string shown to the user.

---

## 4. V3 — Advanced Roadmap

Lighter detail by design — each of these is genuinely further out, and several depend on a decision (whether this product ever introduces a backend) that nothing in V1.5/V2 requires making. Detailed screen-by-screen/task-by-task planning for these will happen at their own `/speckit-plan` time, closer to when they're actually next in line.

### V3.1 — App Lock (Biometric/PIN) & Screenshot Protection
**Prerequisites**: none technical; purely additive security hardening. **Architecture**: `local_auth` (biometric) + a PIN stored as a salted hash in secure storage (reuses the `flutter_secure_storage` dependency introduced by AI Assistant, §V2.5 — sequencing AI Assistant before this means the dependency is already justified/present rather than added twice); platform-channel screenshot-protection flags (`FLAG_SECURE` on Android, an overlay on iOS). **Why V3, not sooner**: `docs/project.txt` §15 asks for this, but nothing in V1.5/V2 requires it, and it's better justified once the app holds a genuinely large amount of sensitive data (Occasions, Budgets, Savings, AI conversation history) than at the current, smaller V1 surface.

### V3.2 — Financial Education & Wealth Planning
**Prerequisites**: none. **This directly implements `docs/project.txt` §9's own recommended safer MVP alternative** to a personalized investment-advice feature — curated static/CMS-free educational content, saving-strategy explanations, and deterministic scenario calculators (e.g., compound-growth "what if" calculators, reusing the same deterministic-calculator pattern as `ProjectSavingsCompletion`, §V2.3), explicitly **never** personalized investment recommendations, to avoid the regulatory/legal risk the brief itself flags.

### V3.3 — Proactive Insights & Reminders/Notifications
**Prerequisites**: V2.5 (AI Assistant, for proactive insight phrasing) and V2.2/V2.3 (Budgets/Savings, as the data source for "you're close to your budget limit" / "you're behind on your savings goal" reminders). **New dependency**: a local-notifications package (`flutter_local_notifications`) — the app's first use of OS-level scheduled notifications; still no backend/push-notification service required, everything is scheduled locally from data already on-device.

### V3.4 — Multi-Currency Support
**Prerequisites**: none blocking, but touches `core/money/Money` (currently implicitly EGP-only) and every screen that formats an amount — genuinely cross-cutting, which is exactly why it's deferred rather than threaded through V1.5/V2 as a moving target. **Architecture direction**: add a currency code alongside every stored minor-unit amount, an explicit "primary currency" setting for totals/aggregation, and a conversion-rate source decision (static/manual vs. a rate-fetching service — the latter would be this app's second-ever network dependency after AI Assistant).

### V3.5 — Cloud Backup & Multi-Device Sync — **DROPPED (2026-09-22)**
Product owner confirmed Daftary stays local-only, no backend. This item is out of scope, not deferred.

### V3.6 — Family / Shared Finances — **DROPPED (2026-09-22)**
Depended entirely on V3.5. Out of scope for the same reason.

---

## 5. Dependency Graph

```text
V1 (existing): People ─────────────┬─────────────────────────────────────────┐
               Transactions ───────┤                                         │
               Settings, Onboarding│                                         │
                                    │                                         │
V1.5.1 Income & Expense (007) ◄────┘  (independent of People/Transactions)   │
        │                                                                    │
        ├──► V1.5.2 Home Dashboard  (also reads Transactions' GetOverview)   │
        │                                                                    │
        ├──► V1.5.3 Reports & Data/Privacy  (also exports Transactions/People)
        │                                                                    │
        └──► V2.2 Budgets  (reads Category + FinanceRepository)             │
                                                                              │
V2.1 Occasions ◄───────────────────────────────────────────── People, Transactions
        │ (adds occasionId to MoneyTransactions; optional tag target for OCR)│
        │                                                                    │
V2.3 Savings  (independent — no dependency on 007, Budgets, or Occasions)    │
                                                                              │
V2.4 OCR  ◄───────────────────────────────────────────────── People, Transactions
        │ HARD dependency on V2.1 Occasions (reuses core/media/AttachmentPickerService,│
        │ corrected 2026-09-22 — was previously described as optional)       │
        │                                                                    │
V2.5 AI Assistant ◄── reads from ALL of: Transactions, 007, Occasions,       │
        │             Budgets, Savings (the more of these exist, the more   │
        │             useful it is — hence last in V2)                      │
        │                                                                    │
V3.1 App Lock ◄── reuses flutter_secure_storage introduced by V2.5           │
V3.2 Financial Education (independent; one optional graceful-degrading soft       │
        read of V2.3 Savings for a pre-fill convenience, not a hard dependency)   │
V3.3 Proactive Insights/Reminders ◄── V2.5, V2.2, V2.3                       │
V3.4 Multi-Currency (independent, but touches core/money used by everything)│
V3.5 Cloud Backup/Sync ── DROPPED (no backend, confirmed 2026-09-22)        │
V3.6 Family/Shared Finances ── DROPPED (depended on V3.5)
```

This is **not** the generic `People → Transactions → Occasions → Budgets/Savings → AI` chain suggested as an example in your prompt — the actual graph is shallower and more parallel than that: Savings has no dependency on Budgets or 007 at all, and Occasions/OCR both depend only on the existing V1 foundation, not on any V1.5/V2 sibling. The one genuinely hard new-feature-on-new-feature dependency in the whole roadmap is **Budgets → 007 (Income & Expense Tracking)**, which is exactly why 007 was built first.

---

## 6. Architecture Plan

Every feature in this document maps onto the same layering already established by `people`/`transactions`/`finance` (007) — **no new architectural pattern is introduced anywhere in V1.5/V2/V3**:

```text
UI (Page/Widget)
  → BLoC/Cubit (Presentation state; immutable, copyWith, one per screen/flow)
    → UseCase (Domain; a named business action, not a bare repository passthrough)
      → Repository interface (Domain)
        → RepositoryImpl (Data)
          → DataSource / DAO (Data; drift for local tables, a *Service interface for
             OCR/AI where the underlying implementation is genuinely swappable)
```

The only two features that add a **new kind of leaf dependency** below the DataSource layer are OCR (`OcrService` → on-device ML Kit/Vision) and AI Assistant (`AIService` → the user's chosen provider's HTTP API) — both already isolated behind an interface in Domain, per constitution Principle IX/X, so swapping either implementation later never touches a BLoC, use case, or screen.

**Integration with existing modules**: every new feature's use cases call **existing** use cases/repositories wherever the data already exists (Occasions calls `AddTransaction`/`FindPossibleDuplicatePerson`; Budgets calls `FinanceRepository.getCategoryBreakdown`; OCR calls `AddTransaction`/`FindPossibleDuplicatePerson`; AI Assistant calls nearly everything) rather than re-implementing a query or a validation rule. This is the concrete, per-feature answer to §4 ("Avoid duplicated sources of truth").

---

## 7. Data & Domain Plan

**Cross-feature relationship map**:

```text
Person ──1:N── MoneyTransaction ──N:1── Occasion   (occasionId nullable FK, V2.1)
                     │
                     └── excluded from balance aggregation when occasionId IS NOT NULL

Category ──1:N── FinanceEntry                       (007, unchanged by later features)
Category ──1:1(per period)── Budget                 (V2.2, reads FinanceEntry via
                                                       FinanceRepository, never duplicates it)

SavingsGoal ──1:N── SavingsContribution              (V2.3, deliberately NOT joined to
                                                       FinanceEntry or MoneyTransaction)

AIConversation ──1:N── AIMessage                     (V2.5, reads everything above
                                                       read-only through existing use cases,
                                                       writes nothing to any of it in V2)
```

**No entity in this roadmap is a duplicated source of truth for another**: `Person`/`MoneyTransaction` (debt), `Category`/`FinanceEntry` (personal cash flow), `SavingsGoal`/`SavingsContribution` (earmarked money), and `Budget` (a limit *over* `FinanceEntry`, not a separate ledger) are four distinct, non-overlapping concepts, each with exactly one table pair owning it. `Occasion` does not get its own transaction table — it tags the existing one.

**Migration requirements**: every addition in this document is a new table or a single new nullable column on an existing table, added via the existing additive `schemaVersion`/`onUpgrade` pattern (`app_database.dart`) — summarized per-feature in §10. No existing column is ever altered or removed, and no existing table's meaning changes.

---

## 8. Navigation Plan

**Current**: 3 `StatefulShellRoute` branches — People (tab 1, also home `/`), Overview (tab 2), Settings (tab 3).

**V1.5**: no new branch. Overview becomes "Home" (§V1.5.2) in place; Income/Expense (007) and Reports/Export nest new routes under the existing People branch (matching 007's own `research.md` Decision 9), reachable from Home's quick actions.

**V2**: Occasions is the first feature in the roadmap that plausibly earns a dedicated tab (see §9). Budgets and Savings are proposed to live under a shared "Finance" area alongside Income/Expense (reachable from Home, not a new tab each) rather than each claiming a tab — three new tabs across one roadmap phase would be a worse navigation experience than one well-organized "Finance" section. OCR is an action (Scan Paper), not a destination — launched from Home's quick actions or from within Transactions/Finance, never a tab. AI Assistant gets its own entry point (a quick action + a persistent, low-emphasis affordance, e.g. a chat icon) but likely not a full tab, to keep the tab bar from growing indefinitely.

**Deep-link considerations**: none required for V1.5/V2 (no sharing-a-link use case identified in the brief); revisit if Cloud Backup/Sync (V3.5) introduces cross-device or cross-user scenarios.

**Back navigation / unsaved changes**: every new form screen follows the existing `TransactionFormPage`/`PersonFormPage` precedent for unsaved-changes prompts — no new pattern needed.

---

## 9. UI/UX Plan

Every new screen in this roadmap must visually and behaviorally match the existing `people`/`transactions` experience: same `core/design_system` components first, new components only when a genuine new visual need appears (a category chip, a progress ring, a chat bubble) and only promoted to `core/` once a second feature needs the same one (constitution Principle XV — already applied this way in 007's plan).

**New shared-component candidates likely to emerge and get promoted to `core/`** (not built speculatively ahead of need): a category/type chip (first needed by 007, reused by Budgets), a progress bar/ring (first needed by Budgets, reused by Savings), an icon picker (first needed by 007, reused by Occasions/Savings for their free-text-type chips).

**Every screen**, without exception, needs: loading, empty, error (with retry), and success states; primary CTA + secondary actions clearly distinguished; confirmation dialogs for anything destructive (delete, archive-with-history, data wipe); validation with localized, specific error messages; success feedback (snackbar/inline, never a silent save); animations that are intentional (state changes, not decoration) and respect reduced-motion settings.

**Arabic/English, RTL/LTR**: no new localization *mechanism* — every feature adds keys to the existing `app_en.arb`/`app_ar.arb` and follows the existing RTL-mirroring precedent already proven across `people`/`transactions`/`onboarding`. The two genuinely new RTL risk areas in this roadmap are **charts** (Reports' trend chart, Budgets' progress bars — axis direction, legend position, and percentage-fill direction must all mirror in RTL, not just labels) and **chat bubbles** (AI Assistant — message alignment must follow reading direction, not a hardcoded left/right).

**Light/dark mode**: no new theming mechanism; every new color (category chips, budget-warning colors, income/expense distinction colors, chat bubble colors) must be a design token, not a hardcoded value, and must be checked in both modes before a feature is considered done.

**Accessibility**: semantic labels on every new interactive element (especially icon-only quick actions and chart elements, which are the easiest to accidentally ship screen-reader-inaccessible); sufficient contrast on all new colors (budget-warning red/amber especially); income/expense/over-budget/completed-goal states must never be conveyed by color alone — always paired with an icon or text label.

**Open navigation-architecture question** (not a blocker for any single feature, but worth a deliberate pass before V2 ships broadly): whether the final tab bar becomes Home/People/Occasions/Settings (4 tabs, Finance nested) or something else. Recommended: revisit this once Occasions is built and real, rather than guessing now.

---

## 10. Implementation Phases (overview — see §11 for the task breakdown)

### Phase 0 — Foundation & Preparation (before any V1.5 feature code)
- Confirm/adjust this document's 5 working assumptions (see §"Working Assumptions" and "Blockers / Unresolved Decisions" at the end of this document).
- No shared-component or migration work is needed *ahead of* 007 — 007's own plan already covers its migration (v4→v5).

### Phase 1 — V1.5 (dependency order: 007 → Home Dashboard → Reports/Data Privacy)
1. `/speckit-tasks` + `/speckit-implement` for 007 (spec+plan already done).
2. `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement` for Home Dashboard.
3. Same cycle for Reports & Data/Privacy Controls.

### Phase 2 — V2 Core (dependency order: Occasions → Budgets → Savings → OCR → AI Assistant)
Each feature runs its own full `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement` → `/speckit-analyze` cycle. Budgets' `/speckit-specify` cannot start meaningfully before V1.5.1 is *implemented* (not just planned), since its acceptance scenarios need real `Category`/`FinanceEntry` data to test against.

### Phase 3 — V3
Each item gets its own spec cycle when it becomes next in line; §4 intentionally stops short of task-level detail for all six.

### Phase 4 — Stabilization (after each phase, not only at the very end)
Integration/regression testing, RTL/LTR verification, light/dark verification, performance testing (especially list/history screens as data volume grows across Occasions/Finance/Budgets/Savings simultaneously), error-state audit, `flutter analyze`/`flutter format`/`flutter build` gates. Run this after **every** feature, not just once at the end of V3 — a stabilization pass deferred to "the end" on a roadmap this size would surface compounding regressions too late to cheaply fix.

---

## 11. Task Breakdown

Epic-level tasks — the same granularity as the worked example in your prompt (`V2-OCC-001` … `V2-OCC-005`), not micro-tasks. This is enough for another developer to execute feature-by-feature without rediscovering the architecture; each feature's own future `/speckit-tasks` run (against that feature's own `plan.md`/`data-model.md`, once it exists) will expand these into fully granular tasks the way `/speckit-tasks` already will for 007. **007's own tasks are not duplicated here** — run `/speckit-tasks` directly against `specs/007-income-expense-tracking/plan.md`, which is already complete.

**Note (added 2026-09-22, from `/speckit-analyze`)**: all 12 features (007–018) now have complete, real `tasks.md` files (812 tasks total, see §17) that supersede the epic-level sketch tables below in every case of detail conflict — e.g. 008's real `tasks.md` has 89 tasks against the 14-row `V2-OCC-*` sketch here, and reflects 008's actual design (`occasionContribution` TransactionKind, not the nullable-`occasionId`-only design originally sketched below). Treat the tables in this section as historical scaffolding, not the current source of truth; always read the feature's own `specs/<NNN>/tasks.md` first.

Within every feature below, unless a task's row says otherwise: **Acceptance** = the code compiles, satisfies the referenced contract/entity shape from §2/§3, passes `flutter analyze`, and (for Domain/Data tasks) has passing unit tests; (for Presentation tasks) matches the states listed in §2/§3 and passes its widget/Cubit test. **Tests required** = unit tests for Domain/Data rows, `bloc_test`+`mocktail` for Cubit rows, widget tests for screen rows, and one `integration_test/<feature>_flows_test.dart` at the end of each feature covering its User Stories end-to-end (§12).

### V1.5.2 — Home Dashboard

| Task ID | Phase | Description | Files/modules | Depends on |
|---|---|---|---|---|
| `V15-DASH-001` | Domain | `GetDashboardSnapshot` use case coordinating `GetOverview` + `GetFinanceSummary` | `lib/features/transactions/domain/usecases/` (or a new small `dashboard` feature folder if the coordination doesn't belong inside `transactions`) | 007 implemented |
| `V15-DASH-002` | Presentation | `DashboardCubit` (loading/success/partial-error/empty states, §2) | `presentation/cubit/` | `V15-DASH-001` |
| `V15-DASH-003` | Presentation | Extend `OverviewPage` → Home: snapshot cards, quick-action row (existing routes only), insights/upcoming empty states | `presentation/pages/overview_page.dart` | `V15-DASH-002` |
| `V15-DASH-004` | Navigation | Relabel `/overview` tab "Home"; add feature-flagged (hidden) Occasions/Scan-Paper quick-action slots | `core/routing/`, `main_shell.dart` | `V15-DASH-003` |
| `V15-DASH-005` | i10n | Add Home/quick-action/insights/upcoming ARB keys (ar/en) | `core/l10n/app_en.arb`, `app_ar.arb` | `V15-DASH-003` |
| `V15-DASH-006` | Tests | `integration_test/dashboard_flows_test.dart` | — | all above |

### V1.5.3 — Reports & Data/Privacy Controls

| Task ID | Phase | Description | Files/modules | Depends on |
|---|---|---|---|---|
| `V15-RPT-001` | Domain | `GetSpendingTrend` use case (multi-period `GetSummary` coordination) | `features/finance/domain/usecases/` | 007 implemented |
| `V15-RPT-002` | Domain | `ExportUserData` use case (CSV serialization of People/Transactions/FinanceEntries/Categories/Settings) | new `features/data_privacy/domain/usecases/` | People, Transactions, 007 implemented |
| `V15-RPT-003` | Domain | `DeleteAllUserData` use case (atomic full wipe + Onboarding reset) | `features/data_privacy/domain/usecases/` | — |
| `V15-RPT-004` | Data | Wire `share_plus` (new dependency) for the OS share/save sheet | `pubspec.yaml`, `features/data_privacy/data/` | `V15-RPT-002` |
| `V15-RPT-005` | Presentation | `ReportsPage` + `ReportsCubit` (trend chart, category breakdown, loading/empty/error) | `features/finance/presentation/` | `V15-RPT-001` |
| `V15-RPT-006` | Presentation | `DataExportPage` + export Cubit (idle/generating/ready/error) | `features/data_privacy/presentation/` | `V15-RPT-004` |
| `V15-RPT-007` | Presentation | "Delete My Data" confirmation flow inside `SettingsPage` | `features/settings/presentation/` | `V15-RPT-003` |
| `V15-RPT-008` | i10n | Reports/export/delete ARB keys (ar/en); verify chart RTL mirroring | `core/l10n/` | `V15-RPT-005`, `006` |
| `V15-RPT-009` | Tests | `integration_test/reports_data_privacy_flows_test.dart` | — | all above |

### V2.1 — Occasions

| Task ID | Phase | Description | Files/modules | Depends on |
|---|---|---|---|---|
| `V2-OCC-001` | Data | Migration: add `Occasions` table + nullable `occasion_id` FK column on `MoneyTransactions` (schema vN→vN+1) | `core/database/app_database.dart` | none |
| `V2-OCC-002` | Data | Update `balance_queries.dart`'s 3 queries to add `AND occasion_id IS NULL` | `core/database/balance_queries.dart` | `V2-OCC-001` |
| `V2-OCC-003` | Domain | `Occasion` entity + `OccasionRepository` contract | `features/occasions/domain/` | `V2-OCC-001` |
| `V2-OCC-004` | Data | `OccasionsDao` + `OccasionRepositoryImpl` | `features/occasions/data/` | `V2-OCC-003` |
| `V2-OCC-005` | Domain | `CreateOccasion`, `EditOccasion`, `ArchiveOccasion`/`DeleteOccasion` use cases | `features/occasions/domain/usecases/` | `V2-OCC-004` |
| `V2-OCC-006` | Domain | `AddOccasionContribution` (wraps existing `AddTransaction` + `FindPossibleDuplicatePerson`) | `features/occasions/domain/usecases/` | `V2-OCC-004`, existing `transactions`/`people` use cases |
| `V2-OCC-007` | Domain | `GetOccasionDetails` (totals + participants from `MoneyTransactions WHERE occasion_id = ?`), `GetOccasions` (list/filter) | `features/occasions/domain/usecases/` | `V2-OCC-004` |
| `V2-OCC-008` | Presentation | `OccasionListCubit` + `OccasionsListPage` (empty/loading/success/error, search/filter by type/archived) | `features/occasions/presentation/` | `V2-OCC-007` |
| `V2-OCC-009` | Presentation | `OccasionFormCubit` + `OccasionFormPage` (create/edit, free-text type chips) | `features/occasions/presentation/` | `V2-OCC-005` |
| `V2-OCC-010` | Presentation | `OccasionDetailCubit` + `OccasionDetailPage` (totals, participants, history, Add Contribution CTA reusing the transaction-form person picker) | `features/occasions/presentation/` | `V2-OCC-006`, `007` |
| `V2-OCC-011` | Navigation | `/occasions`, `/occasions/new`, `/occasions/:id`, `/occasions/:id/edit` | `core/routing/app_router.dart` | `V2-OCC-008..010` |
| `V2-OCC-012` | i10n | Occasion-type chip labels + all new screen strings (ar/en) | `core/l10n/` | `V2-OCC-008..010` |
| `V2-OCC-013` | Tests | **Regression test**: occasion-tagged transactions excluded from person balance / Overview totals (the single highest-value test in V2, §12) | `test/core/database/` | `V2-OCC-002` |
| `V2-OCC-014` | Tests | `integration_test/occasions_flows_test.dart` | — | all above |

### V2.2 — Budgets

| Task ID | Phase | Description | Files/modules | Depends on |
|---|---|---|---|---|
| `V2-BUD-001` | Data | Migration: add `Budgets` table | `core/database/app_database.dart` | 007 implemented |
| `V2-BUD-002` | Domain | `Budget` entity + `BudgetRepository` contract | `features/budgets/domain/` | `V2-BUD-001` |
| `V2-BUD-003` | Data | `BudgetsDao` + `BudgetRepositoryImpl` | `features/budgets/data/` | `V2-BUD-002` |
| `V2-BUD-004` | Domain | `CreateBudget`, `EditBudget`, `RemoveBudget` (archive-if-has-history else delete) | `features/budgets/domain/usecases/` | `V2-BUD-003` |
| `V2-BUD-005` | Domain | `GetBudgetOverview` (joins `Budget` + **existing** `FinanceRepository.getCategoryBreakdown`) | `features/budgets/domain/usecases/` | `V2-BUD-003`, 007's `FinanceRepository` |
| `V2-BUD-006` | Presentation | `BudgetOverviewCubit` + `BudgetOverviewPage` (progress bars, aggregate totals, warning badges) | `features/budgets/presentation/` | `V2-BUD-005` |
| `V2-BUD-007` | Presentation | `BudgetFormCubit` + `BudgetFormPage` (category picker excluding already-budgeted, limit input) | `features/budgets/presentation/` | `V2-BUD-004` |
| `V2-BUD-008` | Navigation | `/budgets`, `/budgets/new`, `/budgets/:id/edit`, nested under the Finance area (§9) | `core/routing/app_router.dart` | `V2-BUD-006..007` |
| `V2-BUD-009` | i10n | Budget screen strings + warning-threshold copy (ar/en) | `core/l10n/` | `V2-BUD-006..007` |
| `V2-BUD-010` | Tests | `integration_test/budgets_flows_test.dart` | — | all above |

### V2.3 — Savings

| Task ID | Phase | Description | Files/modules | Depends on |
|---|---|---|---|---|
| `V2-SAV-001` | Data | Migration: add `SavingsGoals` + `SavingsContributions` tables | `core/database/app_database.dart` | none |
| `V2-SAV-002` | Domain | `SavingsGoal`, `SavingsContribution` entities + `SavingsRepository` contract | `features/savings/domain/` | `V2-SAV-001` |
| `V2-SAV-003` | Data | `SavingsDao` + `SavingsRepositoryImpl` | `features/savings/data/` | `V2-SAV-002` |
| `V2-SAV-004` | Domain | `CreateSavingsGoal`, `EditSavingsGoal`, `RemoveSavingsGoal` | `features/savings/domain/usecases/` | `V2-SAV-003` |
| `V2-SAV-005` | Domain | `AddContribution`, `EditContribution`, `DeleteContribution` | `features/savings/domain/usecases/` | `V2-SAV-003` |
| `V2-SAV-006` | Domain | `GetSavingsGoalDetail` (derived current amount/completion), `GetSavingsGoals`, `ProjectSavingsCompletion` (deterministic calculator) | `features/savings/domain/usecases/` | `V2-SAV-003` |
| `V2-SAV-007` | Presentation | `SavingsGoalListCubit` + `SavingsGoalsListPage` (empty/loading/success/error) | `features/savings/presentation/` | `V2-SAV-006` |
| `V2-SAV-008` | Presentation | `SavingsGoalFormCubit` + `SavingsGoalFormPage` | `features/savings/presentation/` | `V2-SAV-004` |
| `V2-SAV-009` | Presentation | `SavingsGoalDetailCubit` + `SavingsGoalDetailPage` (progress, projection "what-if" input, contribution history, completed state + micro-interaction) | `features/savings/presentation/` | `V2-SAV-005..006` |
| `V2-SAV-010` | Navigation | `/savings`, `/savings/new`, `/savings/:id`, `/savings/:id/edit` | `core/routing/app_router.dart` | `V2-SAV-007..009` |
| `V2-SAV-011` | i10n | Savings screen strings, goal-type free-text chips (ar/en) | `core/l10n/` | `V2-SAV-007..009` |
| `V2-SAV-012` | Tests | `integration_test/savings_flows_test.dart` | — | all above |

### V2.4 — OCR Scanning

| Task ID | Phase | Description | Files/modules | Depends on |
|---|---|---|---|---|
| `V2-OCR-001` | Data | Add `camera`, `image_picker`, on-device OCR plugin, crop-widget dependencies | `pubspec.yaml` | none |
| `V2-OCR-002` | Data | `OcrService` interface + `MlKitOcrService` implementation | `features/ocr/data/services/` | `V2-OCR-001` |
| `V2-OCR-003` | Domain | `OcrCandidateRow`/`OcrScanSession` (ephemeral) entities | `features/ocr/domain/entities/` | none |
| `V2-OCR-004` | Domain | `CaptureOrPickImage`, `ExtractTextFromImage` use cases (contextual camera-permission request) | `features/ocr/domain/usecases/` | `V2-OCR-002` |
| `V2-OCR-005` | Domain | `ParseTransactionCandidates` (reuses `core/money/numeral_parser.dart`; deterministic confidence heuristic) | `features/ocr/domain/usecases/` | `V2-OCR-004` |
| `V2-OCR-006` | Domain | `ConfirmAndSaveScannedTransactions` (per-row, reuses **existing** `AddTransaction` + `FindPossibleDuplicatePerson`) | `features/ocr/domain/usecases/` | existing `transactions`/`people` use cases |
| `V2-OCR-007` | Presentation | `OcrScanCubit` + capture/crop screen (permission-denied/ready/cropping/processing/failed states) | `features/ocr/presentation/` | `V2-OCR-004` |
| `V2-OCR-008` | Presentation | `OcrReviewCubit` + `OcrReviewPage` (per-row edit, confidence flags, duplicate-person matching, partial-success summary) | `features/ocr/presentation/` | `V2-OCR-005..006` |
| `V2-OCR-009` | Platform | Image cache-cleanup on save/cancel; camera/photo-library permission strings (`Info.plist`/`AndroidManifest.xml`) | platform config | `V2-OCR-007..008` |
| `V2-OCR-010` | Navigation | Scan-Paper quick action wired to `/ocr/scan` route | `core/routing/app_router.dart` | `V2-OCR-007` |
| `V2-OCR-011` | i10n | Capture/review/error-state strings (ar/en) | `core/l10n/` | `V2-OCR-007..008` |
| `V2-OCR-012` | Tests | `integration_test/ocr_flows_test.dart` (device/emulator with camera required) | — | all above |

### V2.5 — AI Assistant

| Task ID | Phase | Description | Files/modules | Depends on |
|---|---|---|---|---|
| `V2-AI-001` | Data | Add `flutter_secure_storage` + minimal HTTP client dependency | `pubspec.yaml` | none |
| `V2-AI-002` | Data | Migration: `AIConversations`, `AIMessages` tables | `core/database/app_database.dart` | none |
| `V2-AI-003` | Domain | `AIAssistantRepository` contract; `AIService` interface | `features/ai_assistant/domain/`, `data/services/` | `V2-AI-001` |
| `V2-AI-004` | Data | Concrete `AIService` implementation for the chosen provider(s); secure API-key storage wiring | `features/ai_assistant/data/services/` | `V2-AI-003` |
| `V2-AI-005` | Domain | `FinancialContextBuilder` + tool-call handlers (`getCategorySpend`, `getPersonBalance`, `getSavingsProjection`, `getBudgetStatus`) — each calling an **existing** use case | `features/ai_assistant/domain/usecases/` | `GetFinanceSummary`, `GetCategoryBreakdown`, `GetPersonBalance`, `GetBudgetOverview`, `GetSavingsGoalDetail` all implemented |
| `V2-AI-006` | Domain | `AskFinancialQuestion` use case (orchestrates context builder + repository call) | `features/ai_assistant/domain/usecases/` | `V2-AI-004..005` |
| `V2-AI-007` | Presentation | `AISettingsCubit` + `AISettingsPage` (provider choice, secure key entry, consent toggle, clear-conversation) | `features/ai_assistant/presentation/` | `V2-AI-004` |
| `V2-AI-008` | Presentation | `ChatCubit` + `ChatPage` (message list, RTL-aware bubble alignment, offline state, typed-failure messages) | `features/ai_assistant/presentation/` | `V2-AI-006` |
| `V2-AI-009` | Navigation | AI entry point (quick action + persistent affordance) | `core/routing/app_router.dart`, `main_shell.dart` | `V2-AI-007..008` |
| `V2-AI-010` | i10n | Chat/settings/error strings (ar/en) | `core/l10n/` | `V2-AI-007..008` |
| `V2-AI-011` | Tests | `integration_test/ai_assistant_flows_test.dart` (mocked `AIService`) | — | all above |

---

## 12. Testing Strategy

Identical three-tier shape to 007 (`plan.md` Technical Context/Constitution Check), applied per feature:

- **Unit tests**: every use case, repository (against an in-memory `drift` DB), mapper, and validator — especially the highest-risk business rules per feature: Occasions' balance-exclusion filter (a wrong `WHERE` clause here silently corrupts every existing balance — deserves its own explicit regression test asserting occasion-tagged transactions are excluded); Budgets' spend-vs-limit math; Savings' completion/projection calculator; OCR's deterministic parsing/confidence heuristic; AI Assistant's `FinancialContextBuilder` (must never leak more data than a tool call requested).
- **BLoC tests**: `bloc_test` + `mocktail`, covering initial/loading/success/error/edge-case transitions for every new Cubit.
- **Integration tests**: one `integration_test/<feature>_flows_test.dart` per feature, covering its P1/P2 user stories end-to-end, exactly like 007's `finance_flows_test.dart`. Add one **cross-feature** integration test once Occasions ships: "an occasion-tagged transaction never appears in a person's balance or the Overview totals" — this is the single highest-value regression test in all of V2, since it's the one place a future refactor could silently reintroduce the bug this roadmap is specifically designed to avoid.
- **UI verification**: Arabic/English, RTL/LTR, light/dark, small/large screens — for every new screen, no exceptions.

---

## 13. Migration & Backward Compatibility

| Feature | Schema change | Existing data risk |
|---|---|---|
| 007 Income & Expense | +2 tables (`FinanceEntries`, `FinanceCategories`), v4→v5 | None — no existing table touched |
| Home Dashboard | none | None — read-only aggregation |
| Reports & Data Privacy | none (Export/Delete are read/administrative operations) | `DeleteAllUserData` is the one operation with real risk — must be atomic (all-or-nothing) and behind a strong confirmation, never partially wipe |
| Occasions | +1 table (`Occasions`), +1 nullable column (`occasion_id`) on `MoneyTransactions` | **The only schema change in this entire roadmap that touches an existing table.** A nullable column defaulting to `NULL` on every existing row is safe by construction — every existing `MoneyTransaction` remains `occasion_id IS NULL`, so the new balance-query filter (`AND occasion_id IS NULL`) changes nothing for any pre-existing row. This must be the single most carefully tested migration in the roadmap precisely because it's the only one that isn't purely additive-by-table. |
| Budgets | +1 table (`Budgets`) | None |
| Savings | +2 tables (`SavingsGoals`, `SavingsContributions`) | None |
| OCR | **Corrected 2026-09-22**: Yes — adds `OcrScans` + `CandidateEntries` tables, plus `source`/`ocr_scan_id` columns on `MoneyTransactions` (originally assumed ephemeral-only; superseded by `specs/009-ocr-paper-entry/plan.md`) | None — additive only |
| AI Assistant | +2 tables (`AIConversations`, `AIMessages`) | None |

**General rule carried through the whole roadmap** (already established by `app_database.dart`'s v1→v4 history): every schema change is a `schemaVersion` bump with an additive `onUpgrade` step; no existing column is ever renamed, retyped, or removed; no existing user loses a Person, a Transaction, or a balance because of any feature in this document.

---

## 14. Performance & Security Considerations

- **Large lists**: Occasions' participant/transaction lists, Finance history, Budget category lists, Savings contribution history — all use `ListView.builder`/pagination consistent with the existing `transactions` history screen, never load-everything-into-memory.
- **Image handling (OCR)**: captured images compressed before OCR processing; cache-directory storage only, deleted post-flow (§V2.4) — both a performance and a privacy requirement simultaneously.
- **AI response handling**: requests time out with a friendly retry, never an indefinite spinner; responses are never trusted for a number the app can compute itself (Principle VIII) — the model only ever *narrates* a number the app already validated.
- **Local storage efficiency**: new tables get the same kind of targeted indexes 007 already specifies (`data-model.md`) — category/date/person/occasion lookups, not full-table scans, as data volume grows across every new feature simultaneously.
- **Secrets**: the AI provider API key is the **only** secret this entire roadmap introduces, and it lives exclusively in OS secure storage, never in source, logs, or crash reports (constitution Principle XII — logging must never include it).
- **Network usage**: AI Assistant is the only feature with any network calls in V1.5/V2; the app remains otherwise 100% offline-capable through the end of V2. This should be explicitly re-verified (e.g., a network-request-audit pass) once AI Assistant ships, precisely because it's easy for a "just this one HTTP call" feature's dependency to accidentally get reused somewhere it shouldn't.

---

## 15. Acceptance Criteria (per feature, high-level — full FR-level criteria live in each feature's own spec.md)

**Occasions**: user can create/edit/archive an occasion; can add contributions tied to existing or new people (reusing duplicate detection); occasion totals (given/received) are correct; **existing person balances and the Overview totals are provably unaffected by occasion-tagged transactions**; empty/loading/error states work; Arabic/English, RTL/LTR, light/dark all verified.

**Budgets**: user can set one budget per expense category per month; spend is read from 007's existing data with zero duplicated aggregation logic; progress/remaining/percentage-used are correct; over-limit warning appears at the right threshold; editing/removing works with the archive-vs-delete branching; all states/localization verified.

**Savings**: user can create a goal, contribute to it, see correct progress and a correct projected-completion date; contributions never appear in Income/Expense totals; completion state triggers correctly at target; all states/localization verified.

**OCR**: user can capture/upload → crop → get extracted candidate rows → edit every field → confirm → see real `MoneyTransaction` rows created; nothing is ever auto-saved without confirmation; camera-permission-denied, OCR-failure, and low-confidence paths are all handled with a clear next action; captured images are deleted after the flow ends; all states/localization verified.

**AI Assistant**: user can enable it (own API key + consent), ask a financial question, and get an answer sourced from real local data via existing use cases; the model never computes a number itself and never modifies any record in V2; disabling it stops all network calls immediately; offline state is clear and does not affect the rest of the app; all states/localization verified.

**Home Dashboard / Reports & Data Privacy**: financial snapshot and quick actions are correct and reuse existing aggregations with zero duplicated queries; export produces a complete, accurate file covering every user data table; account/data deletion is atomic and irreversible-with-confirmation; all states/localization verified.

---

## 16. Definition of Done

Identical to the constitution's existing Definition of Done (`.specify/memory/constitution.md`), applied to every feature in this document without exception: architecture correct (layering, DI, repository pattern); UI implemented with complete loading/empty/error/success states; Arabic/English and RTL/LTR both verified; light/dark both verified; validation and confirmation dialogs present wherever destructive or financial; accessibility considered; offline behavior handled (or, for AI Assistant specifically, a clear online-required state); appropriate unit/BLoC/integration tests exist and pass; `flutter analyze`/`flutter format`/`flutter build` all pass; no existing V1/V1.5/V2 functionality regresses (verified by the cross-feature integration test in §11 for Occasions specifically, and by full regression per Phase 4 in §10 generally); no sensitive data leakage (API keys, financial values in logs); reusable and maintainable, not merely compiling.

---

## Blockers / Unresolved Decisions

1. **The 5 clarify questions from 2026-09-22 are still unanswered.** This entire document is built on their recommended (Option A) defaults. Confirm or override before `/speckit-specify` runs for Occasions (Q2), OCR (Q4), Savings (Q5), or AI Assistant (Q3) — Home Dashboard/Reports/Budgets are unaffected by any of the 5 and can proceed regardless.
2. ~~Whether this product ever gets a backend at all~~ — **Resolved 2026-09-22: no backend.** V3.5 (Cloud Backup/Sync) and V3.6 (Family/Shared Finances) are dropped from the roadmap as a result (see §4).
3. **Final bottom-navigation architecture** (§9) is explicitly left open until Occasions is real — recommended to revisit then rather than lock in now.
4. **Budget period model** (§V2.2) assumes a simple recurring monthly limit per category, matching the brief's own example exactly; if multi-period (weekly/yearly) budgets turn out to matter, that's a scope addition to confirm before Budgets' own `/speckit-specify`, not something this document invents unprompted.
5. **OCR's on-device Arabic-handwriting accuracy ceiling** is a known, accepted limitation of Option A (Q4) — the manual review/correction screen exists specifically to absorb it, but it's worth setting expectations that on-device recognition of handwritten Arabic notes will be materially weaker than printed text, before that feature's UX is judged against it.
6. ~~`specs/011-savings-goals/plan.md` reuses `fl_chart`...~~ — **Resolved 2026-09-22.** `plan.md`'s "Primary Dependencies" line had drifted out of sync with `research.md` Decision 4, which already correctly specifies a custom progress widget (no charting library). Both files are now consistent: 011 adds zero new `pubspec.yaml` dependencies and has no ordering dependency on 010. Wave 3 (§17) runs 008 ‖ 011 in parallel as originally planned, unconditionally.

**Recommended next step**: answer/confirm the 5 clarify questions (or explicitly accept all recommended defaults), then run `/speckit-tasks` for 007 (its spec+plan are already complete) to start Phase 1.

---

## 17. Consolidated Status (as of 2026-09-22, post-spec-wave)

All `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` cycles below are **complete on disk**. No implementation code has been written yet (`app_database.dart` is still `schemaVersion 4`; `git status` shows only new files under `specs/`).

| Spec | Feature | Tier | Tasks | Adds a DB migration? |
|---|---|---|---|---|
| 001–006 | People, Localization, Dark Mode, Txn/Archive Refresh, Onboarding | V1 (implemented) | — | — |
| 007 | Income & Expense Tracking | V1.5 | 83 | Yes — v4→v5 (`FinanceEntries`, `FinanceCategories`) |
| 008 | Occasions / Social Money | V2 | 89 | Yes — adds `Occasions` + nullable `occasion_id` FK on `MoneyTransactions` |
| 009 | OCR Paper-to-Transaction | V2 | 75 | **Yes (corrected 2026-09-22)** — `OcrScans`, `CandidateEntries`, + 2 columns on `MoneyTransactions` |
| 010 | Household Budgets | V2 | 64 | Yes — adds `Budgets` |
| 011 | Savings Goals | V2 | 63 | Yes — adds `SavingsGoals`, `SavingsContributions` |
| 012 | Home Dashboard | V1.5 | 47 | No |
| 013 | Reports & Data/Privacy | V1.5 | 55 | No |
| 014 | AI Financial Assistant | V2 | 84 | Yes — adds `AIConversations`, `AIMessages` |
| 015 | App Lock & Screenshot Protection | V3 | 84 | No (secure storage only) |
| 016 | Financial Education & Wealth Planning | V3 | 58 | No |
| 017 | Proactive Insights & Reminders | V3 | 51 | **Yes (corrected 2026-09-22)** — adds `NotificationPreferences` + `NotificationHistory`, bumps `schemaVersion` (previously omitted from this table and from the shared-file contention map below) |
| 018 | Multi-Currency Support | V3 | 59 | **Yes — touches every existing money-bearing table** (001/007/008/010/011) |

**Total new tasks specified: ~812**, across 12 features.

**Dropped, not blocked**: V3.5 Cloud Backup/Sync and V3.6 Family/Shared Finances are out of scope — confirmed 2026-09-22 that Daftary stays local-only, no backend. All 12 remaining active roadmap items (everything above) are fully spec'd; the roadmap now has no open product questions blocking it.

**Implementation status**: on hold at the product owner's request — specs are ready for review; no code will be written until explicitly told to proceed (see §17 for the implementation sequencing plan when that time comes).

### Shared-file contention map (read before parallelizing implementation)

Unlike the spec-writing phase (safely parallelized via `SPECIFY_FEATURE_DIRECTORY` isolation), **implementation cannot be naively parallelized** — 5 features write to the same physical files:

| Shared file | Touched by |
|---|---|
| `core/database/app_database.dart` (`schemaVersion`, table defs, migrations) | 007, 008, **009 (added 2026-09-22 — `OcrScans`/`CandidateEntries`, see §13)**, 010, 011, 014, **017 (added 2026-09-22 — `NotificationPreferences`/`NotificationHistory`, previously omitted here)**, **018 (every table)** |
| `core/database/balance_queries.dart` | 008 (occasion-exclusion mechanism — corrected 2026-09-22 to `occasionContribution` `TransactionKind` + `countsTowardBalance` column, see §V2.1), 018 (currency-aware aggregation) |
| `core/routing/app_router.dart` + `main_shell.dart` | 012, 008, 010, 011, 009, 014, 015 (all add routes/nav) |
| `core/l10n/app_en.arb` / `app_ar.arb` | every single feature |
| `core/money/Money` | 018 turns this into a breaking change for 001/007/008/010/011 |
| `pubspec.yaml` | **008 (added 2026-09-22 — `image_picker` for occasion attachments)**, 009 (camera/OCR), **010 (added 2026-09-22 — `fl_chart` for budget progress bars)**, **011 (soft, reuses 010's `fl_chart` — see Blockers item 6)**, 013 (`share_plus`), 014 (`flutter_secure_storage`+HTTP), 015 (`local_auth`), 017 (`flutter_local_notifications`) |

**Implication**: two agents cannot safely implement, say, Budgets (010) and Savings (011) in parallel if both are independently bumping `schemaVersion` and both editing the ARB files — last-write-wins will silently drop one agent's migration or string keys. This is the code-level equivalent of the `.specify/feature.json` race from the spec-writing phase, except there is no `SPECIFY_FEATURE_DIRECTORY`-style override available for a shared Dart source file — a real merge conflict, not just a pointer race.

### Recommended foundation + sequencing strategy

1. **Foundation task (single-owner, not parallelized)**: one migration, `schemaVersion 4→5`, adding *all* of 007/008/**009**/010/011/014/**017**'s tables (**corrected 2026-09-22**: 009's `OcrScans`/`CandidateEntries` and 017's `NotificationPreferences`/`NotificationHistory` were originally omitted from this list — see §13 and the shared-file contention map) and 008's balance-exclusion mechanism at once (table definitions can be written independently per feature, but the migration step and `schemaVersion` bump itself must be a single coordinated edit). This turns 7 features' "add my own migration" into 1 foundation task + 7 independent "write my DAO against an already-existing table" tasks — eliminating the single biggest parallelization hazard.
2. **Route/nav registration and ARB-key additions**: batch similarly — either one agent owns `app_router.dart`/`main_shell.dart`/ARB files per implementation wave and applies each feature's additions sequentially (fast, since it's mechanical), or features are implemented in small non-overlapping batches (e.g. 2 at a time) with a human/agent merge step between batches rather than true full concurrency.
3. **Multi-Currency (018) must be its own dedicated pass**, after every other V1.5/V2 feature is implemented and stable — never in parallel with any of them, exactly as its own spec's "largest/riskiest" self-assessment concluded. Do not schedule it alongside anything else.
4. **Everything below the shared-file layer** — Domain use cases, BLoC/Cubit, screens/widgets specific to one feature's own `lib/features/<name>/` folder, and that feature's own unit/widget tests — genuinely is independent per feature and safe to parallelize once its foundation migration (if any) already exists.

### Proposed implementation wave order

| Wave | Features | Parallel? | Rationale |
|---|---|---|---|
| 0 | Foundation migration (schemaVersion 5: FinanceEntries/Categories, Occasions + `occasionContribution` TransactionKind/`countsTowardBalance`, **OcrScans/CandidateEntries + MoneyTransactions columns (009, added 2026-09-22)**, Budgets, SavingsGoals/Contributions, AIConversations/Messages, **NotificationPreferences/NotificationHistory (017, added 2026-09-22)**) | N/A — single task | Eliminates the #1 shared-file conflict up front |
| 1 | 007 Income & Expense | Solo | Everything else in V1.5/V2 reads its `Category`/`FinanceRepository` |
| 2 | 012 Home Dashboard, 013 Reports & Data/Privacy | Parallel (both read-only aggregations over 007, touch disjoint new folders) | No shared new-file writes between the two |
| 3 | 008 Occasions, 011 Savings Goals | **Parallel (resolved 2026-09-22 — see Blockers item 6)**: 011 introduces zero new `pubspec.yaml` dependencies — its goal-progress indicator is a custom `LinearProgressIndicator`/`CustomPainter` widget, not `fl_chart` (confirmed against `specs/011-savings-goals/research.md` Decision 4). No ordering constraint against 010/Wave 4 remains. | Independent domains, disjoint files below the foundation layer |
| 4 | 010 Budgets | Solo (**corrected 2026-09-22**: OCR moved out of this wave — see below) | Reads 007 |
| 4b | 009 OCR | **Sequential, after 008 (Wave 3) — corrected 2026-09-22**: OCR hard-reuses `core/media/AttachmentPickerService`, introduced by Occasions (008); this was previously described as an optional dependency and mistakenly paired with Budgets as a parallel wave. | Hard dependency on 008, not 010 |
| 5 | 014 AI Assistant | Solo | Reads from every prior feature's use cases — least useful, most likely to need rework, if built before they exist |
| 6 | 015 App Lock, 016 Financial Education | Parallel (both fully additive, zero dependency on V2 data) | Independent, low-risk |
| 7 | 017 Proactive Insights | Solo | Depends on 010/011 (and optionally 014) already being real |
| 8 | 018 Multi-Currency | Solo, dedicated pass | Touches every prior feature's schema/UI — see above |
| 9 | Full regression + stabilization | N/A | Constitution Definition of Done, applied app-wide |

This is slower than "12 agents at once" but is the difference between a working app and a corrupted schema/router/ARB file in a financial application. Route/nav and ARB additions within a parallel wave (2, 3, 4, 6) still need a lightweight sequential merge step for those specific shared files even though the domain/BLoC/UI code is written in parallel.
