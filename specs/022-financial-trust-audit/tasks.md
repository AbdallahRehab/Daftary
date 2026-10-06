---
description: "Tasks for 022 Financial Trust Audit: the audit document plus settled remediation waves (revised after /speckit-analyze)"
---

# Tasks: Financial Trust Audit

**Input**: `/specs/022-financial-trust-audit/` — [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md), [checklists/acceptance.md](checklists/acceptance.md)

**Tests**: Required. Every bug fix starts with a test that **fails on current `main`** and passes after the fix. Every change to financial logic is also covered by the calculation catalogue (Phase 2) and the upgrade snapshot (T012).

**Format**: `- [ ] T### [P?] [US#?] Description with file path`, then indented fields: **Type · Priority · Layer**, **Expected**, **Accept**, **Tests**, **Deps**.

- `[P]` means the task can run in parallel: it touches different files and depends on nothing unfinished.
- Priority: **P0** financial correctness, data corruption or security · **P1** major function · **P2** important UX or testing · **P3** minor.

**Sync rollout order (binding, plan S0; revised 2026-10-06 after the US8 review)**: the B1 repair needs schema v12, which ships with D2, so R1 and R2 are merged into **one release, 1.1.0**:
1. You deploy migration **025** (T055).
2. You deploy migration **026** (T067).
3. Release **1.1.0** (all of US6–US9).

Both migrations are safe before any 1.1.0 install exists: 025 only switches savings conflicts on for app versions ≥ 1.1.0, its `sync_pull` keeps filtering what v1.0.1 can't read, and 026 only adds a branch, keeps `sync_pull` unchanged and adds `sync_pull_v2`, which old apps never call. Installed v1.0.1 apps must keep syncing throughout (CHK163).

**Out of scope until the owner decides** (no tasks): plan C1 (Q1), C2 (Q2), and the "block over-repayment" variant of A2 (Q3). **Not scheduled**: D3, G3, G4, H1–H6.

---

## Phase 1: Setup

- [X] T001 Create branch `022-financial-trust-audit` from `main` and commit `specs/022-financial-trust-audit/` as it is
  - **Type · Priority · Layer**: Chore · P2 · Repo
  - **Expected**: Work happens on the feature branch.
  - **Accept**: `git branch --show-current` prints `022-financial-trust-audit`, and the tree is clean after the commit.
  - **Tests**: none
  - **Deps**: none
- [X] T002 Record the baseline in `specs/022-financial-trust-audit/quickstart.md` (run `fvm flutter test`, `fvm flutter analyze`, `dart format --set-exit-if-changed .`)
  - **Type · Priority · Layer**: QA · P2 · Tooling
  - **Expected**: There is a known-green baseline.
  - **Accept**: Tests pass at 3,699 or more, analyze shows 0 issues, format exits 0. If anything differs, stop and report.
  - **Tests**: the existing suite
  - **Deps**: T001

---

## Phase 2: Foundational — calculation catalogue (plan F2, Wave 0)

**Purpose**: Pin today's correct numbers *before* any fix. Cases for known defects use `skip: 'Known fail <ID>'` and are switched back on by the task that fixes them. **⚠️ No US6–US9 task starts until this phase is green.**

- [X] T003 [P] Add a shared fixture builder (people, transactions, finance entries, budgets, occasions, savings; today = 2026-10-05; in-memory DB through `test/helpers/test_daos.dart`) at `test/helpers/catalogue_fixtures.dart`
  - **Type · Priority · Layer**: QA automation · P1 · Test
  - **Expected**: One line per fact.
  - **Accept**: It builds the CHK013 and CHK068 data sets. No production code changes.
  - **Tests**: used by T004–T012
  - **Deps**: T002
- [X] T004 [P] Person-balance catalogue in `test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart`
  - **Type · Priority · Layer**: Regression · P1 · Domain/Data
  - **Expected**: Exact nets through `TransactionsRepositoryImpl.getPersonBalance`.
  - **Accept**: CHK011–CHK017 and CHK029–CHK032 all pass. Examples: received 2,000 + gave 500 → −150000 minor; 3 × 333.33 against 1,000 → +1 minor.
  - **Tests**: this is the test
  - **Deps**: T003
- [X] T005 [P] Overview catalogue in `test/features/transactions/domain/catalogue/overview_catalogue_test.dart`
  - **Type · Priority · Layer**: Regression · P1 · Domain/Data
  - **Expected**: Totals are never netted together and never partial; archived people are included.
  - **Accept**: CHK004, CHK018, CHK019, CHK021 and CHK082 pass.
  - **Tests**: this is the test
  - **Deps**: T003
- [X] T006 [P] Repayment catalogue in `test/features/transactions/domain/catalogue/repayment_catalogue_test.dart`
  - **Type · Priority · Layer**: Regression · P0 · Data
  - **Expected**: The inferred direction is correct.
  - **Accept**: CHK023, CHK024 and CHK026's balance outcome pass. The cases `Known fail A1` (a direction edit is rejected) and `Known fail B2` are present and skipped.
  - **Tests**: this is the test
  - **Deps**: T003
- [X] T007 [P] Occasion catalogue in `test/features/occasions/domain/catalogue/occasion_totals_catalogue_test.dart`
  - **Type · Priority · Layer**: Regression · P1 · Domain/Data
  - **Expected**: Totals come only from occasion rows; condolence money doesn't count; deleting an occasion removes its contributions.
  - **Accept**:
    - CHK068 (800/200/+600), CHK069, CHK071, CHK072, CHK073 (Ahmed back to his balance without the wedding) and CHK083 pass.
    - CHK070 is asserted as current behavior (−50000), with the comment `⏸ Q1`.
  - **Tests**: this is the test
  - **Deps**: T003
- [X] T008 [P] Finance-summary catalogue in `test/features/finance/domain/catalogue/finance_summary_catalogue_test.dart`
  - **Type · Priority · Layer**: Regression · P1 · Domain/Data
  - **Expected**: Income and expense are kept separate from person and savings money; net can be negative.
  - **Accept**: CHK036–CHK042 and CHK075 pass. 1,000 income − 1,500 expense → net −50000.
  - **Tests**: this is the test
  - **Deps**: T003
- [X] T009 [P] Budget catalogue in `test/features/budgets/domain/catalogue/budget_catalogue_test.dart`
  - **Type · Priority · Layer**: Regression · P1 · Domain/Data
  - **Expected**: Exact thresholds; the overall figure covers budgeted lines only; month boundaries hold.
  - **Accept**: CHK047–CHK057 and CHK084 pass. Examples: 1,799.99 → onTrack; 1,800.00 → nearFull; 2,000.01 → overBudget (−1 minor); overall spent 1,300.00 with unbudgeted 250.00 shown separately.
  - **Tests**: this is the test
  - **Deps**: T003
- [X] T010 [P] Savings catalogue in `test/features/savings/domain/catalogue/savings_catalogue_test.dart`
  - **Type · Priority · Layer**: Regression · P1 · Domain
  - **Expected**: Matches `DefaultSavingsCalculator` and the repository.
  - **Accept**: CHK058–CHK067 pass: 2027-07-05; 1,500.00 with a 3-month shortfall; 333.34; divide by 1 inside the current month; a withdrawal over the balance is rejected; remaining 0 once achieved; the USD contribution is locked at 4,850.00.
  - **Tests**: this is the test
  - **Deps**: T003
- [X] T011 [P] Amount-input catalogue in `test/core/money/amount_input_catalogue_test.dart`
  - **Type · Priority · Layer**: Regression · P2 · Core
  - **Expected**: One rule set for `NumeralParser` plus `CurrencyFormatter.parse`.
  - **Accept**: CHK116 and CHK136–CHK139 pass. "١٬٥٠٠" is present with `skip: 'Known fail RF-07'`.
  - **Tests**: this is the test
  - **Deps**: T002
- [X] T012 Upgrade-safety snapshot in `test/core/database/upgrade_financial_snapshot_test.dart`, with the snapshot in `test/core/database/fixtures/financial_snapshot_v11.json`
  - **Type · Priority · Layer**: Regression · P0 · Persistence
  - **Expected**: Seed the T003 data at `schemaVersion` 11, save every person balance, overview total, budget actual and savings figure as JSON, reopen through the migration path, and compare.
  - **Accept**: Passes now. **Note**: at v11 no migration runs yet, so it only starts protecting once T064 raises the schema to 12. From then on it must pass *without* regenerating the JSON.
  - **Tests**: this is the test
  - **Deps**: T003

**Checkpoint**: the quickstart Wave 0 command is green, with only the documented skips.

---

## Phase 3: User Story 1 — Verified financial-correctness findings (P1) 🎯 MVP

- [X] T013 [US1] Create `specs/022-financial-trust-audit/audit.md` with the heading skeleton from `contracts/audit-report.md`
  - **Type · Priority · Layer**: Docs · P1 · Audit
  - **Expected**: 20 sections plus the decisions heading.
  - **Accept**: `grep -c '^## ' audit.md` = 20, and the closing H1 is present.
  - **Tests**: none
  - **Deps**: T002
- [X] T014 [US1] Write §4 Financial Logic Assessment in `specs/022-financial-trust-audit/audit.md`, one FinancialFigure record per user-visible figure
  - **Type · Priority · Layer**: Docs · P1 · Audit
  - **Expected**: Every figure is defined in plain language, and each cites the catalogue test (T004–T010) that pins it.
  - **Accept**: Covers every figure listed in data-model Part 1 (SC-001).
  - **Tests**: n/a
  - **Deps**: T013, T004–T010
- [X] T015 [US1] Write §16 Critical Bugs and §14 Incorrect Features in `specs/022-financial-trust-audit/audit.md`, including the count of repayments already flipped, from the quickstart Track 1 step 4 query (research R8)
  - **Type · Priority · Layer**: Docs · P0 · Audit
  - **Expected**: P0/P1 items have reproduction steps, expected vs actual, `verifiedBy` and impact. Every PF-01…PF-12, RF-01…RF-07 and analysis C1/C2 appears with its status (SC-005).
  - **Accept**: The flipped-repayment count is stated (0 is a valid answer), and the remedy given is "delete and record again".
  - **Tests**: n/a
  - **Deps**: T013
- [X] T016 [US1] Write §3 Accounting Assessment and §6 Data Model Assessment in `specs/022-financial-trust-audit/audit.md`
  - **Type · Priority · Layer**: Docs · P1 · Audit
  - **Expected**: The FR-004 and FR-005 concept table, and the data-model verdict.
  - **Accept**: Every concept has a row. Refund, adjustment, transfer, write-off, opening balance and linking a repayment to a debt are each classified as now, later or none, with a reason.
  - **Tests**: n/a
  - **Deps**: T013
- [ ] T017 [US1] Run the 29 FR-006 flows on an emulator (AR/EN × light/dark) and record them in §5 of `specs/022-financial-trust-audit/audit.md`
  - **Type · Priority · Layer**: Manual QA · P1 · Audit
  - **Expected**: Every flow has an outcome.
  - **Accept**: 29 of 29 (SC-002). Flows 28 and 29 are marked "traced, not executed" if no dev project is linked.
  - **Tests**: manual
  - **Deps**: T013
- [X] T018 [US1] Write §9 QA (the stale-state trace), §10 Security & Privacy and §11 Offline/Sync in `specs/022-financial-trust-audit/audit.md`
  - **Type · Priority · Layer**: Docs · P1 · Audit
  - **Expected**: Each section cites evidence. §10 includes the **AI grounding check**: every figure the assistant states comes from a deterministic tool in `lib/features/ai_assistant/domain/tools/`, and the risk of the assistant doing arithmetic in its prose is recorded (RF-06, FR-013).
  - **Accept**: The §11 table lists all 14 entity types with their server policy, plus the older-app findings (analysis C1/C2) and the rollout order.
  - **Tests**: n/a
  - **Deps**: T013

---

## Phase 4: User Story 2 — Test scenarios with exact numbers (P1)

- [X] T019 [US2] Write §17 Test Scenarios in `specs/022-financial-trust-audit/audit.md`, linking every CHK item to its TestScenario fields, with `automated` = a test path or "gap"
  - **Type · Priority · Layer**: Docs/QA · P1 · Audit
  - **Expected**: At least 5 scenarios per critical calculation (SC-004).
  - **Accept**: The "gap" rows are counted.
  - **Tests**: n/a
  - **Deps**: T004–T011, T013
- [ ] T020 [US2] Run `checklists/acceptance.md` against v1.0.1 and record each result in a table at the end of §17 in `specs/022-financial-trust-audit/audit.md`. Leave the checklist boxes for the reviewer to tick
  - **Type · Priority · Layer**: Manual QA · P1 · Audit
  - **Expected**: There is a baseline result.
  - **Accept**: 168 of 168 have a result. Any failure not already tagged becomes a new RF-xx in research.md.
  - **Tests**: manual
  - **Deps**: T019

---

## Phase 5: User Story 3 — Accountant traceability review (P2)

- [X] T021 [US3] Write §12, §18 and §19 in `specs/022-financial-trust-audit/audit.md`, in plain language with no code paths
  - **Type · Priority · Layer**: Docs · P2 · Audit
  - **Expected**: Each need is marked met, partly met or missing, with its backlog ID.
  - **Accept**: Reconciliation of one person, one occasion and one budget month is walked through using CHK081–CHK084 (SC-007). Every concept proposed is labelled user-visible or internal and justified.
  - **Tests**: n/a
  - **Deps**: T020

---

## Phase 6: User Story 4 — Terminology and Arabic/RTL review (P2)

- [X] T022 [US4] Write §7 and §8 in `specs/022-financial-trust-audit/audit.md`, including the full TerminologyEntry table (with `arbKey`) for every money-related key in `lib/core/l10n/app_ar.arb`
  - **Type · Priority · Layer**: Docs · P2 · Audit
  - **Expected**: The single source for T077 and T078.
  - **Accept**: Every `arbKey` exists in both ARB files. The `personDetailSettled`/`occasionSettlementSettled` clash is listed. The RTL issues from T017 are listed per screen.
  - **Tests**: n/a
  - **Deps**: T017
- [ ] T023 [US4] **Owner sign-off gate**: have a native Egyptian Arabic speaker review the §8 table, then record the owner's approve or amend decision per row in a `Decision` column of §8 in `specs/022-financial-trust-audit/audit.md`
  - **Type · Priority · Layer**: Decision · P2 · Product
  - **Expected**: Only approved values are applied (plan E1 gate).
  - **Accept**: Every row is marked "approved", "amended to …" or "keep current". The date and approver are recorded.
  - **Tests**: n/a
  - **Deps**: T022

---

## Phase 7: User Story 5 — Backlog and owner decisions (P3)

- [X] T024 [US5] Write §1, §2, §13, §15, §20 (BacklogItem with every FR-016 field, IDs A1…H6, S0, E5, E6) and "DECISIONS REQUIRED FROM ME" (S1 and E1 recorded as answered; Q1–Q3 with options, a recommendation and the impact of each answer) in `specs/022-financial-trust-audit/audit.md`
  - **Type · Priority · Layer**: Docs · P2 · Audit
  - **Expected**: The audit is complete.
  - **Accept**: At most 7 decisions. Every finding of P2 or higher maps to at least one backlog ID, and back.
  - **Tests**: n/a
  - **Deps**: T014–T023
- [X] T025 [US5] Check `audit.md` against `contracts/audit-report.md` and fix any gaps in `specs/022-financial-trust-audit/audit.md`
  - **Type · Priority · Layer**: QA · P2 · Audit
  - **Expected**: The contract is satisfied.
  - **Accept**: "Contract check: pass" is written under the closing heading.
  - **Tests**: n/a
  - **Deps**: T024

**Checkpoint**: Track 1 is done and shareable.

---

## Phase 8: User Story 6 — Ledger correctness fixes (P1)

**Goal**: Plan A1, A2, B2 and E6. **Independent test**: CHK026, CHK028, CHK091, CHK167 and CHK168, with the catalogue still green.

### Tests first (each must FAIL on current code)

- [X] T026 [P] [US6] Add group `A1 repayment direction is fixed` to `test/features/transactions/data/repositories/transactions_repository_impl_test.dart`
  - **Type · Priority · Layer**: Bug test · P0 · Data
  - **Expected**: Changing the direction of a repayment → `Left(ValidationFailure)`, with the row, audit and outbox unchanged. Changing amount, date or note on a repayment still works. Changing the direction of an initial exchange or occasion contribution still works.
  - **Accept**: The first case fails on `main`.
  - **Tests**: this is the test
  - **Deps**: Phase 2
- [X] T027 [P] [US6] Add widget test `test/features/transactions/presentation/pages/transaction_form_repayment_edit_test.dart`
  - **Type · Priority · Layer**: Bug test · P0 · Presentation
  - **Expected**: Editing a repayment shows no enabled direction `SegmentedButton`, and shows the direction label plus `repaymentDirectionLockedHint`. An initial exchange keeps the control enabled. Run in AR/EN and light/dark, and check the hint has a screen-reader label.
  - **Accept**: Fails on `main`.
  - **Tests**: this is the test
  - **Deps**: Phase 2
- [X] T028 [P] [US6] Add pure tests `test/features/transactions/domain/services/repayment_preview_test.dart`
  - **Type · Priority · Layer**: Logic test · P1 · Domain
  - **Expected**: `RepaymentPreview.of(balance, amount, context)` gives:
    - owes +100000, repay 40000 EGP → resulting +60000;
    - repay 100000 → 0;
    - repay 150000 → −50000 with `flips`;
    - you owe −70000, repay 70000 → 0;
    - **owes +1000000, repay 100.00 USD at rate 48.50 → resulting +515000**;
    - **50.00 GBP with no rate → `blocked`**;
    - a blocked balance → `blocked`.
  - **Accept**: Fails to compile until T033.
  - **Tests**: this is the test
  - **Deps**: Phase 2
- [X] T029 [P] [US6] Add Cubit tests (`bloc_test`, `mocktail`) in `test/features/transactions/presentation/cubit/repayment_form_cubit_test.dart`
  - **Type · Priority · Layer**: State test · P1 · Presentation
  - **Expected**:
    - The Cubit subscribes to `WatchPersonBalance` and `WatchConversionContext`.
    - `submit()` does nothing until both have emitted.
    - When `preview.flips`, the first `submit()` emits `needsFlipConfirmation: true` without calling `RecordRepayment`; `confirmFlip()` calls it once with the same idempotency key.
    - Both subscriptions are cancelled in `close()`.
  - **Accept**: Fails on `main`.
  - **Tests**: this is the test
  - **Deps**: Phase 2
- [X] T030 [P] [US6] Add a B2 case to `test/features/transactions/data/repositories/transactions_repository_impl_test.dart`
  - **Type · Priority · Layer**: Bug test · P3 · Data
  - **Expected**: Given a blocked opposite-direction balance, a repayment in GBP (no rows) → `Left(RatesMissingFailure)`, and no row is inserted.
  - **Accept**: Fails on `main`.
  - **Tests**: this is the test
  - **Deps**: Phase 2
- [X] T031 [P] [US6] Add E6 tests: a repository test for `countLaterRepayments(personId, fromDate)` in `transactions_repository_impl_test.dart`, and a widget test `test/features/transactions/presentation/widgets/delete_transaction_confirm_dialog_test.dart`
  - **Type · Priority · Layer**: Feature test · P2 · Data/Presentation
  - **Expected**: Deleting the 1,000 row while a later 400 repayment exists → the dialog shows "1 later payback" and the resulting "You owe Ahmed 400.00". With no later repayments, the dialog is unchanged.
  - **Accept**: Fails on `main`.
  - **Tests**: this is the test
  - **Deps**: Phase 2

### Implementation

- [X] T032 [US6] In `TransactionsRepositoryImpl.editTransaction` (`lib/features/transactions/data/repositories/transactions_repository_impl.dart`), return `Left(ValidationFailure('Repayment direction is fixed'))` when `existing.kind == TransactionKind.repayment.dbValue && direction.dbValue != existing.direction`, before any write
  - **Type · Priority · Layer**: Bug fix · P0 · Data
  - **Expected**: Matches contract A1.
  - **Accept**: T026 passes, and the A1 catalogue case passes once un-skipped.
  - **Tests**: T026, T006
  - **Deps**: T026
- [X] T033 [US6] Create `RepaymentPreview` in `lib/features/transactions/domain/services/repayment_preview.dart`
  - **Type · Priority · Layer**: Feature · P1 · Domain
  - **Expected**: Fields `outstanding`, `resulting`, `flips`, `blocked`. It converts the repayment into the primary currency with `CurrencyConverter` and the given `ConversionContext` (never 1:1). Integer minor units only, no Flutter imports.
  - **Accept**: T028 passes.
  - **Tests**: T028
  - **Deps**: T028
- [X] T034 [P] [US6] Add ARB keys to both ARB files and run `fvm flutter gen-l10n`
  - **Type · Priority · Layer**: L10n · P1 · Presentation
  - **Expected**: Keys:
    - `repaymentDirectionLockedHint` (ar "اتجاه السداد بيتحدد من الرصيد. لتغييره احذف السداد وسجّله تاني");
    - `repaymentOutstanding` ({amount});
    - `repaymentFlipConfirmTitle`;
    - `repaymentFlipConfirmMessage` ({name}, {amount});
    - `repaymentPreviewUnavailable`;
    - `deleteLaterRepaymentsWarning` ({count}, {result}), with ICU plural forms.
  - **Accept**: `gen-l10n` succeeds with nothing left untranslated.
  - **Tests**: via T027, T031, T037
  - **Deps**: none
- [X] T035 [US6] Lock the direction for repayment edits: in `TransactionFormCubit.directionChanged` (`lib/features/transactions/presentation/cubit/transaction_form_cubit.dart`), ignore changes when editing a repayment. In `lib/features/transactions/presentation/pages/transaction_form_page.dart`, show the direction as read-only text plus the hint
  - **Type · Priority · Layer**: Bug fix · P0 · Presentation
  - **Expected**: The control can't be reached.
  - **Accept**: T027 passes.
  - **Tests**: T027
  - **Deps**: T032, T034
- [X] T036 [US6] Extend `repayment_form_state.dart` (`preview`, `balanceLoaded`, `needsFlipConfirmation`, through `copyWith`) and `repayment_form_cubit.dart` (inject `WatchPersonBalance` and `WatchConversionContext`, add `confirmFlip()`, cancel both subscriptions in `close()`) in `lib/features/transactions/presentation/cubit/`
  - **Type · Priority · Layer**: Feature · P1 · State
  - **Expected**: Matches contract A2.
  - **Accept**: T029 passes, and `dart run build_runner build --delete-conflicting-outputs` succeeds.
  - **Tests**: T029
  - **Deps**: T033, T029
- [X] T037 [US6] In `lib/features/transactions/presentation/pages/repayment_form_page.dart`, show the outstanding amount, the preview (or `repaymentPreviewUnavailable`), and `AppConfirmDialog` when a flip needs confirming (through `BlocListener`). Add `test/features/transactions/presentation/pages/repayment_form_page_test.dart`
  - **Type · Priority · Layer**: UX · P1 · Presentation
  - **Expected**: CHK026, CHK028 and CHK168 pass.
  - **Accept**: The widget test covers:
    - 400 → no dialog;
    - 1,500 → dialog; cancel saves 0 rows; confirm saves 1 row;
    - USD → 5,150.00;
    - GBP → no number shown.

    It runs in AR/EN with RTL render assertions (the repo has no image golden tests), and checks the dialog buttons are at least 48dp and have screen-reader labels.
  - **Tests**: widget test plus golden
  - **Deps**: T036, T034
- [X] T038 [US6] Make `_repaymentDirection` (`lib/features/transactions/data/repositories/transactions_repository_impl.dart`) return `Either`. When the status is unknown and the repayment currency has no net, return `Left(RatesMissingFailure(balance.missingRatesFor))`. `recordRepayment` folds the result
  - **Type · Priority · Layer**: Bug fix · P3 · Data
  - **Expected**: Matches contract B2.
  - **Accept**: T030 passes, and the B2 catalogue case passes once un-skipped.
  - **Tests**: T030, T006
  - **Deps**: T030
- [X] T039 [US6] Implement E6 in `lib/features/transactions/data/datasources/transactions_dao.dart`, `transactions_repository{,_impl}.dart` (`countLaterRepayments`), a `@injectable` use case `count_later_repayments.dart`, and `lib/features/transactions/presentation/widgets/delete_transaction_confirm_dialog.dart`
  - **Type · Priority · Layer**: Improvement · P2 · Data/Presentation
  - **Expected**: A warning plus the resulting balance. Deleting is never blocked.
  - **Accept**: T031 passes, and CHK167 passes.
  - **Tests**: T031
  - **Deps**: T031, T034
- [X] T040 [US6] Remove the `A1` and `B2` skips in `test/features/transactions/domain/catalogue/repayment_catalogue_test.dart`, then run the transactions and catalogue tests
  - **Type · Priority · Layer**: Regression · P0 · Test
  - **Expected**: There are no US6 skips left.
  - **Accept**: Green.
  - **Tests**: the catalogue
  - **Deps**: T032, T038

---

## Phase 9: User Story 7 — Sync and date integrity, release R1 (P1)

**Goal**: Plan S0, A3 and B1, without breaking v1.0.1. **Independent test**: CHK110, CHK111, CHK163, CHK164 and CHK165.

### Tests first (each must FAIL on current code)

- [x] T041 [P] [US7] Add an unknown-type case to `test/core/sync/remote/sync_remote_data_source_test.dart`
  - **Type · Priority · Layer**: Bug test · P0 · Data (sync)
  - **Expected**: A pull page of 3 changes where the middle one has `entity_type: 'future_type'` → 2 `PulledChange`s, and `maxRevision` equals the last row's revision.
  - **Accept**: Fails on `main` (`FormatException`).
  - **Tests**: this is the test
  - **Deps**: Phase 2
- [x] T042 [P] [US7] Add `parseLocalDay` cases to `test/core/sync/sync_mapper_registry_test.dart`
  - **Type · Priority · Layer**: Bug test · P2 · Data (sync)
  - **Expected**: `occurred_on: '2026-10-01'` → `DateTime(2026,10,1).millisecondsSinceEpoch`. When it is missing, fall back to `occurred_at`.
  - **Accept**: Fails to compile until T047.
  - **Tests**: this is the test
  - **Deps**: Phase 2
- [x] T043 [P] [US7] Add cross-timezone cases to `test/features/transactions/data/sync/money_transaction_sync_mapper_test.dart` and `test/features/finance/data/sync/finance_entry_sync_mapper_test.dart` (create the latter if absent)
  - **Type · Priority · Layer**: Bug test · P2 · Data (sync)
  - **Expected**: `fromWire` of `{occurred_on: 2026-10-01, occurred_at: 2026-09-30T21:00:00Z, tz_offset_minutes: 180}` gives local midnight of 2026-10-01.
  - **Accept**: Fails under `TZ=UTC` on `main`.
  - **Tests**: this is the test
  - **Deps**: Phase 2
- [x] T044 [P] [US7] Add `test/core/sync/sync_b1_repull_test.dart`
  - **Type · Priority · Layer**: Bug test · P2 · Data (sync)
  - **Expected**:
    - Given a local row dated 2026-09-30 whose server row has `occurred_on 2026-10-01`, the cursor at 500 and the flag unset, after one sync cycle the row shows 2026-10-01, the flag is set, and a second cycle does no full re-pull.
    - A row with a pending outbox operation keeps its local value.
  - **Accept**: Fails on `main`.
  - **Tests**: this is the test
  - **Deps**: Phase 2
- [x] T045 [P] [US7] Add `test/features/cloud_sync/data/cloud_sync_repository_savings_conflict_test.dart`
  - **Type · Priority · Layer**: Bug test · P0 · Data
  - **Expected**: A `sync_conflicts` row for `savings_contribution` (local 1,000, server 1,200) → `watchSyncConflicts` emits 1 item of type `savingsContribution` with direction `contribution`. `keepTheirs` applies the server value and keeps the local payload in `conflict_resolutions`.
  - **Accept**: Fails on `main`.
  - **Tests**: this is the test
  - **Deps**: Phase 2

### Implementation

- [x] T046 [US7] In `_parseChange` (`lib/core/sync/remote/sync_remote_data_source.dart`), return `null` for an unknown `entity_type`. The page parser drops the nulls but still uses the raw page's highest revision for `maxRevision`. Add `SyncEvent.unknownEntitySkipped` (type name only, no row data) in `lib/core/sync/sync_logger.dart`
  - **Type · Priority · Layer**: Bug fix · P0 · Data (sync)
  - **Expected**: Matches contract S0.
  - **Accept**: T041 passes, CHK164 passes, and `test/core/sync/sync_log_scrub_test.dart` is still green.
  - **Tests**: T041
  - **Deps**: T041
- [x] T047 [US7] Add `static int parseLocalDay(Map<String, Object?> json, {String dayField = 'occurred_on', String instantField = 'occurred_at'})` to `SyncWire` in `lib/core/sync/sync_mapper_registry.dart`
  - **Type · Priority · Layer**: Bug fix · P2 · Data (sync)
  - **Expected**: Turns `yyyy-MM-dd` into local `DateTime(y,m,d)`, falls back to `parseInstant`, and sends a malformed day through `_bad`.
  - **Accept**: T042 passes.
  - **Tests**: T042
  - **Deps**: T042
- [x] T048 [US7] Use `SyncWire.parseLocalDay(json)` for `date` in `lib/features/transactions/data/sync/money_transaction_sync_mapper.dart` and `lib/features/finance/data/sync/finance_entry_sync_mapper.dart`
  - **Type · Priority · Layer**: Bug fix · P2 · Data (sync)
  - **Expected**: Matches contract B1.
  - **Accept**: T043 passes under `TZ=UTC` and `TZ=Africa/Cairo`, and `test/core/sync` is green.
  - **Tests**: T043
  - **Deps**: T047, T043
- [x] T049 [US7] **(Deferred into the schema v12 bump, T064: the only sync-state store is the `sync_state` table, so the flag needs a `b1_repull_done` column. Decided 2026-10-06.)** Add the one-time repair (research R7): a `b1RepullDone` flag in the sync state store (`lib/core/sync/local/sync_local_store.dart`, plus its state row or table column through the existing sync-state persistence). At the start of a cycle in `lib/core/sync/sync_engine.dart`, if the flag is unset, set the pull cursor to 0 **and** the flag in one write (so a failed or interrupted re-pull resumes from its saved cursor instead of restarting from 0), then run the cycle
  - **Type · Priority · Layer**: Bug fix · P2 · Data (sync)
  - **Expected**: Matches the contract B1 repair. The applier's existing skip of rows with pending or conflicted operations is unchanged.
  - **Accept**: T044 passes, CHK165 passes, and `test/performance/sync_upload_perf_test.dart` is still green.
  - **Tests**: T044
  - **Deps**: T048, T044
- [x] T050 [US7] Add `savingsContribution('savings_contribution')` to `ConflictEntityType`, and `contribution` and `withdrawal` to `ConflictDirection`, in `lib/features/cloud_sync/domain/entities/sync_conflict_item.dart`
  - **Type · Priority · Layer**: Feature · P0 · Domain
  - **Expected**: The enum covers every type that uses the financial policy.
  - **Accept**: Every exhaustive `switch` is updated, and the analyzer is clean.
  - **Tests**: T045
  - **Deps**: T045
- [x] T051 [US7] Map `savings_contribution` payloads to `ConflictVersion` in `lib/features/cloud_sync/data/repositories/cloud_sync_repository_impl.dart`, taking field names from `lib/features/savings/data/sync/savings_contribution_sync_mapper.dart` `toWire`
  - **Type · Priority · Layer**: Feature · P0 · Data
  - **Expected**: Amount, currency, date, contribution or withdrawal, note, deleted.
  - **Accept**: T045 passes.
  - **Tests**: T045
  - **Deps**: T050
- [x] T052 [US7] Add `conflictDirectionContribution` and `conflictDirectionWithdrawal` (ar/en) to both ARB files, render them in `lib/features/cloud_sync/presentation/widgets/conflict_resolution_sheet.dart`, and add `test/features/cloud_sync/presentation/conflict_resolution_sheet_savings_test.dart`
  - **Type · Priority · Layer**: UX/L10n · P0 · Presentation
  - **Expected**: Both versions are shown.
  - **Accept**: Widget test plus golden in AR/EN and light/dark, with screen-reader labels on both choices.
  - **Tests**: widget test
  - **Deps**: T051
- [x] T053 [US7] In `test/core/sync/fakes/fake_sync_remote.dart`, make the savings policy depend on `appVersion` (`financial` at 1.1.0 or above, `lww` below), mirroring migration 025. Add `test/core/sync/sync_engine_savings_conflict_test.dart`
  - **Type · Priority · Layer**: QA automation · P0 · Sync
  - **Expected**: At 1.1.0, two stale pushes → a blocked op plus a conflict; resolving either way leaves 0 open conflicts and 1 resolution. At 1.0.1 → applied.
  - **Accept**: Green, and `sync_engine_conflict_test.dart` is unchanged and green.
  - **Tests**: this is the test
  - **Deps**: T051
- [x] T054 [US7] Prepare release R1: set `version: 1.1.0+3` in `pubspec.yaml`, and record "R1 = 1.1.0" in `specs/022-financial-trust-audit/quickstart.md`
  - **Type · Priority · Layer**: Chore · P0 · Release
  - **Expected**: A fixed version string that migration 025 compares against.
  - **Accept**: `DeviceInfo.appVersion` reports `1.1.0` in a debug build (check the existing device-info test).
  - **Tests**: the existing device-info test
  - **Deps**: T046–T053
- [x] T055 [US7] Create `supabase/migrations/20261005090000_025_savings_contribution_conflicts.sql`
  - **Type · Priority · Layer**: Backend · P0 · Sync server
  - **Expected**:
    - Adds `public.app_version_at_least(p_version text, p_min text) returns boolean` (`immutable`). It splits each version on `.` and `+`, compares the numeric parts, and returns false when either version is null or unparsable.
    - Includes `create or replace function public.sync_push(uuid, text, text, jsonb)`, copied **verbatim** from `20260930090000_023_savings_goals_sync.sql`. The only change: in the `savings_contribution` branch, `v_policy := case when public.app_version_at_least(p_app_version, '1.1.0') then 'financial' else 'lww' end`.
    - Repeats the comment, revoke and grant statements exactly.
  - **Accept**: Diffing against 023 shows only the helper and that line. **You deploy it after R1 has shipped** (rollout step 2). The quickstart SQL checks show `applied` for 1.0.1 and `conflict` for 1.1.0.
  - **Tests**: quickstart SQL checks plus T053
  - **Deps**: T054

**SQL (2026-10-06, local Supabase via Docker)**: `supabase db reset` applied 021→026 cleanly; `supabase test db` 9 files / 316 tests PASS, including the new `supabase/tests/025_savings_contribution_conflicts.test.sql` (version gate, stale-edit conflict, delete-only not already_applied, sync_pull hides savings resolutions). Three older expectations were updated to intended behaviour: 021 (unknown_entity no longer ledgered, 026), 022 (DELETE on occasions revoked since 024 — pre-existing), 026 (forged owner_id is re-stamped, so the insert fails on the FK).

**Result (2026-10-06)**: format exit 0; analyze no issues; full suite 4,022 passed / 1 skipped (opt-in fixture regeneration) / 0 failed; `TZ=UTC` sync suites 266 passed; no `Known fail` skips remain.

**Checkpoint**: R1 can be released. Then you deploy 025. CHK110, CHK111, CHK163 (025 part), CHK164 and CHK165 pass.

---

## Phase 10: User Story 8 — Traceability and complete export, release R2 (P2; D2 is P1)

**Goal**: Plan C3, D2 and D1. **Independent test**: CHK079, CHK087, CHK088, CHK094 and CHK163 (026 part).

### Change history (C3)

- [x] T056 [P] [US8] Add `watchAuditHistory` tests to `test/features/transactions/data/repositories/transactions_repository_watch_test.dart`
  - **Type · Priority · Layer**: Feature test · P2 · Data
  - **Expected**: Create, edit (1,000 → 800) and delete give 3 entries in `changedAt` order, with the edit entry's previous amount 100000. The stream re-emits on a new edit.
  - **Accept**: Fails (missing method).
  - **Tests**: this is the test
  - **Deps**: Phase 2
- [x] T057 [US8] Add `getAuditEntriesFor(transactionId)` (ordered by `changedAt`) to `lib/features/transactions/data/datasources/transactions_dao.dart`, and `watchAuditHistory(String transactionId)` to `transactions_repository.dart` and its implementation (`_db.watchEither({_db.transactionAuditEntries}, …)`)
  - **Type · Priority · Layer**: Feature · P2 · Data/Domain
  - **Expected**: Read-only.
  - **Accept**: T056 passes.
  - **Tests**: T056
  - **Deps**: T056
- [x] T058 [US8] Add the use cases `lib/features/transactions/domain/usecases/watch_transaction_audit_history.dart` and `lib/features/savings/domain/usecases/watch_contribution_audit_history.dart`, the latter with `watchContributionAuditHistory` in `savings_repository.dart`, its implementation and `savings_dao.dart`
  - **Type · Priority · Layer**: Feature · P2 · Domain/Data
  - **Expected**: The same shape for both.
  - **Accept**: A savings repository test mirroring T056 passes.
  - **Tests**: the new savings test
  - **Deps**: T057
- [x] T059 [P] [US8] Add the ARB keys `changeHistoryTitle`, `changeHistoryCreated`, `changeHistoryEdited`, `changeHistoryDeleted`, `changeHistoryRestored`, `changeHistoryEmpty` (ar/en; the `changeHistoryPreviousValue` key was dropped as unused), then run `gen-l10n`
  - **Type · Priority · Layer**: L10n · P2 · Presentation
  - **Expected**: Translated.
  - **Accept**: `gen-l10n` succeeds.
  - **Tests**: via T060 and T061
  - **Deps**: none
- [x] T060 [US8] Create **one** generic `ChangeHistoryCubit` in `lib/core/design_system/change_history/change_history_cubit.dart`, which takes a `Stream<Either<Failure, List<ChangeHistoryRow>>>` and has immutable loading, success, empty and failure states. Add the `ChangeHistoryRow(label, timestamp, fields)` model and `bloc_test` tests in `test/core/design_system/change_history_cubit_test.dart`
  - **Type · Priority · Layer**: State · P2 · Presentation
  - **Expected**: Serves all three features, with no duplicated Cubits (plan, constitution).
  - **Accept**: Tests cover every state transition and that the subscription is cancelled on close.
  - **Tests**: Cubit tests
  - **Deps**: T059
- [x] T061 [US8] Create `AppChangeHistorySheet` in `lib/core/design_system/change_history/app_change_history_sheet.dart`. Dates go through `lib/core/date/`, and all copy comes from ARB
  - **Type · Priority · Layer**: UI · P2 · Presentation
  - **Expected**: A read-only list with loading, empty and error states.
  - **Accept**: `test/core/design_system/app_change_history_sheet_test.dart` passes in AR/EN and light/dark with RTL render/semantic assertions (repo has no image goldens; CI is ubuntu), each row has a screen-reader label, and targets are at least 48dp.
  - **Tests**: widget test
  - **Deps**: T060
- [x] T062 [US8] Tapping the "Edited" marker opens the sheet: map domain audit entries to `ChangeHistoryRow` in `lib/features/transactions/presentation/widgets/transaction_list_tile.dart` and `lib/features/savings/presentation/widgets/contribution_list_tile.dart`
  - **Type · Priority · Layer**: Feature · P2 · Presentation
  - **Expected**: CHK087 and CHK088 pass.
  - **Accept**: Tile widget tests pass. Rows show the earlier amount with currency, direction, date and note.
  - **Tests**: widget tests
  - **Deps**: T058, T061

### Income/expense history (D2, P1 because of the constitution)

- [x] T063 [P] [US8] Add tests to `test/features/finance/data/repositories/finance_repository_impl_test.dart`
  - **Type · Priority · Layer**: Bug test · P1 · Data
  - **Expected**: Each action appends exactly one `finance_entry_audits` row in the same transaction as the change:
    - add → `created` (previous values null);
    - edit 300 → 450 → `edited` (previous 30000);
    - edit an expense into an income category → `edited`, with `previous_values_json` holding the previous `type` (`expense`) and `categoryId` (RF-08);
    - delete → `deleted`;
    - restore → `restored`.
  - **Accept**: Fails on `main`.
  - **Tests**: this is the test
  - **Deps**: Phase 2
- [x] T064 [US8] Add the Drift table `FinanceEntryAudits` **and the column `sync_state.b1_repull_done` (bool, default false; needed by T049)** to `lib/core/database/app_database.dart`
  - **Type · Priority · Layer**: Persistence · P1 · Data
  - **Expected**:
    - Columns: `id` text PK, `financeEntryId` text, `changeType` text ∈ {`created`, `edited`, `deleted`, `restored`}, `previousValuesJson` text nullable, `changedAt` int.
    - `schemaVersion` goes from 11 to 12.
    - The migration step goes in `lib/core/database/migrations/v12_finance_entry_audits.dart`.
    - Then run `build_runner`.
  - **Accept**: `test/core/database/v12_migration_test.dart` (v11 → v12: the table exists and existing rows are unchanged) passes, and T012 passes **without** regenerating its JSON.
  - **Tests**: migration test, T012
  - **Deps**: T063
- [x] T065 [US8] Add `financeEntryAudit('finance_entry_audit', 2)` to `lib/core/sync/sync_entity_type.dart`, create `lib/features/finance/data/sync/finance_entry_audit_sync_mapper.dart` mirroring `transaction_audit_sync_mapper.dart`, register it, and update `test/core/sync/table_classification_guard_test.dart` and `test/core/sync/sync_entity_type_test.dart`
  - **Type · Priority · Layer**: Sync · P1 · Data
  - **Expected**: Append-only sync.
  - **Accept**: The guard tests and a mapper round-trip test pass.
  - **Tests**: mapper plus guard tests
  - **Deps**: T064
- [x] T066 [US8] Write the audit rows inside the existing Drift transaction of `addEntry`, `editEntry`, `deleteEntry` and `restoreEntry` in `lib/features/finance/data/repositories/finance_repository_impl.dart` (DAO in `finance_dao.dart`), queued through the outbox as `finance_entry_audit`
  - **Type · Priority · Layer**: Feature · P1 · Data
  - **Expected**: Matches the contract for D2.
  - **Accept**: T063 passes, and T008 is green.
  - **Tests**: T063, T008
  - **Deps**: T064, T065
- [X] T067 [US8] Create `supabase/migrations/20261005100000_026_finance_entry_audits.sql`
  - **Type · Priority · Layer**: Backend · P1 · Sync server
  - **Expected**:
    - The table `public.finance_entry_audits`, with `owner_id`, `revision`, RLS policies, the `sync_stamp` trigger, an index and grants, all mirroring `transaction_audit_entries`.
    - `sync_push` copied verbatim from 025, plus `when 'finance_entry_audit'` (policy `append`, business fields `finance_entry_id, change_type, previous_values, changed_at`).
    - `sync_pull(bigint,int)` **unchanged in output** (an explicit filter excludes `finance_entry_audit`).
    - A new `sync_pull_v2(bigint,int)` returns every type, with the same grants.
  - **Accept**: The diff shows only these additions. **You deploy it before R2** (rollout step 3). All quickstart SQL checks for 026 pass, including RLS (CHK148).
  - **Tests**: quickstart SQL checks
  - **Deps**: T055
- [x] T068 [US8] R2 client: call `sync_pull_v2` in `lib/core/sync/remote/sync_remote_data_source.dart`, and update `test/core/sync/fakes/fake_sync_remote.dart` and `test/core/sync/remote/sync_remote_data_source_test.dart` (the RPC name is checked)
  - **Type · Priority · Layer**: Sync · P1 · Data
  - **Expected**: R2 receives history rows, and v1.0.1 and R1 never do.
  - **Accept**: Tests pass. CHK163 (026 part) passes on devices after rollout.
  - **Tests**: remote data source test
  - **Deps**: T065, T067
- [x] T069 [US8] Add the `watchEntryAuditHistory` read in `lib/features/finance/domain/repositories/finance_repository.dart` and its implementation, and wire the "Edited" marker in `lib/features/finance/presentation/widgets/finance_entry_list_tile.dart` to `AppChangeHistorySheet` through `ChangeHistoryCubit`
  - **Type · Priority · Layer**: Feature · P1 · Presentation/Data
  - **Expected**: CHK094 passes.
  - **Accept**: Repository and widget tests pass.
  - **Tests**: repository plus widget tests
  - **Deps**: T061, T066

### Complete export (D1)

- [x] T070 [P] [US8] Add `test/features/data_privacy/export_sections_test.dart`
  - **Type · Priority · Layer**: Feature test · P2 · Domain
  - **Expected**: The export of the T003 data contains `occasions`, `occasion_contributions`, `budgets`, `budget_allocations`, `savings_goals`, `savings_contributions`, `exchange_rates`, `transaction_changes`, `savings_contribution_changes` and `finance_entry_changes`, in that order, after the existing sections. The existing sections are byte-identical to `test/features/data_privacy/fixtures/export_v1_0_1_sections.csv`, captured from `main`.
  - **Accept**: Fails on `main` (sections missing). The byte-identical part passes.
  - **Tests**: this is the test
  - **Deps**: Phase 2
- [x] T071 [US8] Add "list all" reads only where none exist: `getAllBudgets()` plus allocations in `budgets_repository.dart` and its implementation, `getAllGoalsWithContributions()` in `savings_repository.dart` and its implementation, and history reads with no filter. Reuse `getOccasionsList` (archived included) and the existing exchange-rate read
  - **Type · Priority · Layer**: Feature · P2 · Data
  - **Expected**: Plain reads with no business logic.
  - **Accept**: Each has a repository test with 2 or more rows, and its archived/deleted rule is documented.
  - **Tests**: repository tests
  - **Deps**: T057, T058, T066
- [x] T072 [US8] Extend `ExportUserData` (`lib/features/data_privacy/domain/usecases/export_user_data.dart`): keep "every read before any write" and the `.part` file followed by a rename, and append the sections in T070's order
  - **Type · Priority · Layer**: Feature · P2 · Domain
  - **Expected**: Matches contract D1.
  - **Accept**: T070 passes, `export_read_only_test.dart` and `export_no_network_test.dart` are green, and CHK079 passes.
  - **Tests**: T070 plus the existing tests
  - **Deps**: T070, T071

---

## Phase 11: User Story 9 — Plain wording and safe input (P2)

**Goal**: Plan E1 (after sign-off), E3, E5 and C4. **Independent test**: CHK035, CHK092, CHK103 and CHK117.

- [x] T073 [P] [US9] Add the case "١٬٥٠٠" → "1,500" to `test/core/money/numeral_parser_test.dart`
  - **Type · Priority · Layer**: Bug test · P3 · Core
  - **Expected**: `٬` (U+066C) maps to `,`.
  - **Accept**: Fails on `main`.
  - **Tests**: this is the test
  - **Deps**: Phase 2
- [x] T074 [US9] Map `'٬'` to `','` in `lib/core/money/numeral_parser.dart`, and update the doc comment
  - **Type · Priority · Layer**: Bug fix · P3 · Core
  - **Expected**: Every amount form accepts it.
  - **Accept**: T073 passes, the RF-07 skip is removed from T011 and it passes, and CHK117 passes.
  - **Tests**: T073, T011
  - **Deps**: T073
- [x] T075 [P] [US9] Add tests for confirming a currency change in edit mode to `test/features/transactions/presentation/cubit/transaction_form_cubit_test.dart` and `test/features/finance/presentation/cubit/finance_entry_form_cubit_test.dart`
  - **Type · Priority · Layer**: UX test · P2 · State
  - **Expected**: In edit mode, `currencyChanged(USD)` sets `pendingCurrency` and leaves `currency` alone; `confirmCurrencyChange()` applies it; `cancelCurrencyChange()` clears it. Create mode is unchanged.
  - **Accept**: Fails on `main`.
  - **Tests**: this is the test
  - **Deps**: Phase 2
- [x] T076 [US9] Implement `pendingCurrency` and confirm/cancel in both form Cubits and states. `transaction_form_page.dart` and `finance_entry_form_page.dart` show `AppConfirmDialog` through `BlocListener`, using ARB keys `editCurrencyConfirmTitle` and `editCurrencyConfirmMessage` ({amount}, {from}, {to})
  - **Type · Priority · Layer**: UX · P2 · Presentation/L10n
  - **Expected**: Matches contract E3, and CHK092 passes.
  - **Accept**: T075 passes. Widget tests for both pages in AR/EN pass, with 48dp dialog buttons and screen-reader labels.
  - **Tests**: T075 plus widget tests
  - **Deps**: T075
- [ ] T077 [P] [US9] Add `test/core/l10n/terminology_consistency_test.dart`
  - **Type · Priority · Layer**: L10n test · P2 · Presentation
  - **Expected**: In both locales, `personDetailSettled != occasionSettlementSettled`, and every row of the **approved** §8 table has its approved value.
  - **Accept**: Fails on `main`.
  - **Tests**: this is the test
  - **Deps**: T023
- [ ] T078 [US9] Apply the **approved** §8 values (only the ARB *values*; no key renames and no placeholder changes) to `lib/core/l10n/app_ar.arb` and `lib/core/l10n/app_en.arb`, run `gen-l10n`, regenerate the affected goldens, and review every diff
  - **Type · Priority · Layer**: L10n/UX · P2 · Presentation
  - **Expected**: CHK035 passes.
  - **Accept**: T077 passes. Golden diffs appear only on screens that show a changed key, checked in RTL and LTR.
  - **Tests**: T077 plus goldens
  - **Deps**: T077
- [x] T079 [P] [US9] Add `findPossibleDuplicate` tests to `test/features/transactions/data/repositories/transactions_repository_impl_test.dart`
  - **Type · Priority · Layer**: Feature test · P3 · Data
  - **Expected**: Same person, amount, currency, direction and date on an active row → match; deleted rows are ignored; otherwise null.
  - **Accept**: Fails (missing method).
  - **Tests**: this is the test
  - **Deps**: Phase 2
- [x] T080 [US9] Implement `findPossibleDuplicate` (DAO, repository) and the create-mode flow in `TransactionFormCubit.submit()` (`possibleDuplicate`, then `confirmDuplicate()` with the **same idempotency key**). The page shows `AppConfirmDialog` with ARB keys `transactionDuplicateTitle` and `transactionDuplicateMessage`
  - **Type · Priority · Layer**: Improvement · P3 · Data/Presentation
  - **Expected**: CHK103 passes, and CHK100 still gives exactly 1 row.
  - **Accept**: T079 passes. Cubit tests (confirm → 1 row, cancel → 0) and a widget test pass.
  - **Tests**: T079 plus Cubit and widget tests
  - **Deps**: T079

---

## Phase 12: Polish & cross-cutting

- [X] T081 [P] Update the "Operating Context" in `PRODUCT.md` to what's shipped: optional cloud sync with an email account, and 008–015 and 018 built (plan G1)
  - **Type · Priority · Layer**: Docs · P2 · Docs
  - **Expected**: There is no "no backend, sync, account" statement.
  - **Accept**: Every module listed matches a folder in `lib/features/`.
  - **Tests**: n/a
  - **Deps**: none
- [X] T082 [P] Amend `specs/001-money-relationships-tracking/spec.md` FR-015 with "except the direction of a repayment, which is fixed at creation", plus a dated Clarifications bullet (plan G2)
  - **Type · Priority · Layer**: Docs · P2 · Docs
  - **Expected**: Spec 001 agrees with contract A1.
  - **Accept**: There is no contradiction.
  - **Tests**: n/a
  - **Deps**: T032
- [X] T083 [P] Add a step to `.github/workflows/ci.yml` that runs `TZ=UTC flutter test test/core/sync test/features/transactions/data/sync test/features/finance/data/sync`
  - **Type · Priority · Layer**: CI · P2 · Tooling
  - **Expected**: The B1 regression is caught whatever the machine's time zone.
  - **Accept**: The CI run on the branch shows the step green.
  - **Tests**: CI
  - **Deps**: T048
- [X] T084 [P] Re-validate `specs/022-financial-trust-audit/checklists/requirements.md` against the revised spec (US6–US9, the amended FR-002, SC-008)
  - **Type · Priority · Layer**: Docs · P3 · Spec
  - **Expected**: The spec quality checklist is current.
  - **Accept**: Every item is re-evaluated, and a dated note is added.
  - **Tests**: n/a
  - **Deps**: none
- [X] T085 Run the full gates: `fvm flutter test` (at least 3,699 plus the new tests, 0 failures), `fvm flutter analyze` (0 issues), `dart format --set-exit-if-changed .`, and the `TZ=UTC` sync run
  - **Type · Priority · Layer**: Regression · P0 · All
  - **Expected**: CHK158–CHK161 pass.
  - **Accept**: All green, and no `Known fail` skips are left for A1, B2 or RF-07.
  - **Tests**: the full suite
  - **Deps**: T040, T049, T053, T068, T072, T074, T076, T078, T080
- [ ] T086 Re-run `checklists/acceptance.md` on the branch build, and update §17's results table and the backlog statuses in `specs/022-financial-trust-audit/audit.md`
  - **Type · Priority · Layer**: Manual QA · P1 · Audit
  - **Expected**: Every former known-fail handled by US6–US9 passes. CHK020, CHK070 and CHK026's variant stay `⏸`, and CHK166 stays a known gap.
  - **Accept**: 0 failures other than those. Sync items run after the rollout, or are marked "not deployed".
  - **Tests**: manual
  - **Deps**: T085, T025
- [ ] T087 Run the upgrade check (CHK162): install v1.0.1 with data, upgrade to the branch build, and compare every figure with the T012 method
  - **Type · Priority · Layer**: Regression · P0 · Persistence
  - **Expected**: Everything matches to 0.01.
  - **Accept**: A diff of 0 is recorded in audit §9.
  - **Tests**: manual plus T012
  - **Deps**: T085
- [ ] T088 Run the older-app check from quickstart (CHK163): v1.0.1 and the branch build on the same account, after 025 and 026 are deployed
  - **Type · Priority · Layer**: Regression · P0 · Sync
  - **Expected**: v1.0.1 has 0 errors and 0 stuck items, and the newer app shows the savings conflict.
  - **Accept**: The result is recorded in audit §11.
  - **Tests**: manual
  - **Deps**: T055, T067, T068

---

## Dependencies & Execution Order

```text
Phase 1 ─► Phase 2 catalogue (blocks US6–US9)
  ├─► US1 ─► US2 ─► US3
  │     └─► US4 (T022 ─► T023 owner sign-off) ─► US5
  ├─► US6 ledger fixes (no schema, no sync)
  ├─► US7 S0 + B1 + A3 client ─► T054 release R1 ─► T055 migration 025 (you deploy)
  ├─► US8 C3 ─► D2 (T064–T066) ─► T067 migration 026 (you deploy) ─► T068 release R2 ─► D1
  └─► US9 (T077/T078 wait for T023 sign-off)
Phase 12 after the stories chosen for release
```

- **Release grouping**:
  - **R1 (1.1.0)** = US6, US7 and US9, plus C3's read-only history sheet (T056–T062) if it is ready.
  - **R2** = all of D2 (T063–T069) and D1 (T070–T072).
  - D2 ships whole in R2. Its history rows must never be uploaded before migration 026 exists, and 026 is deployed before R2 is released.
- **Migrations**: 025 (T055) before 026 (T067), because 026 copies 025's `sync_push`.

## Parallel Opportunities

- **Phase 2**: T004–T011 in parallel after T003.
- **US6**: T026–T031 and T034 together; then T032, T033, T038 and T039.
- **US7**: T041–T045 together; then T046 and T047 in parallel.
- **US8**: T056, T059, T063 and T070 together.
- **US9**: T073, T075 and T079 together. T077 starts after T023.
- **Across stories**: US6 and US7 can be built in parallel. They share only the two ARB files.

## Implementation Strategy

1. **MVP**: T001–T018. The audit findings are backed by a green catalogue.
2. **R1**: US6, US7 and US9 (E3/E5/C4, plus E1 once T023 is signed off). Release 1.1.0, then deploy 025.
3. **Audit completion**: US2–US5 in parallel with the fixes.
4. **R2**: US8. Deploy 026, then release R2.
5. **After Q1–Q3**: run `/speckit-tasks` again, or open a new feature, for C1, C2 and the A2 variant.

## Notes

- **Task count**: 88. By phase: Setup 2 · Foundational 10 · US1 6 · US2 2 · US3 1 · US4 2 · US5 2 · US6 15 · US7 15 · US8 17 · US9 8 · Polish 8.
- **Failing-first pairs**: A1 (T026/T027 → T032/T035), A2 (T028/T029 → T033/T036), B2 (T030 → T038), E6 (T031 → T039), S0 (T041 → T046), B1 (T042/T043/T044 → T047/T048/T049), A3 (T045 → T050/T051), D2 (T063 → T066), D1 (T070 → T072), RF-07 (T073 → T074), E3 (T075 → T076), E1 (T077 → T078), C4 (T079 → T080).
- **No new runtime dependencies.** Three forward migrations (025, 026, plus the v12 Drift migration). Applied migrations are never edited.
