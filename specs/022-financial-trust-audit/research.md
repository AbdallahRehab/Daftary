# Research: Financial Trust Audit — verified root causes

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-10-05

Phase 0 output. Each entry below was checked against the code on `main` (v1.0.1) by reading it. Nothing here was inferred from file names. The "Status" column resolves the seeds in [preliminary-findings.md](preliminary-findings.md) (SC-005). New findings use IDs `RF-xx`.

## 1. Seed verification

| Seed | Status | Verified root cause | Evidence |
| --- | --- | --- | --- |
| PF-01 Repayment direction when settled or overpaid | **Partially confirmed** | When the person is settled, the repayment button is hidden, so that path is guarded in the UI. Over-repayment flipping the balance is *intended* (001 FR-012), but the repayment form shows no outstanding amount, no preview of the resulting balance and no warning before the flip. | `person_detail_page.dart` (button behind `status != settled`); `repayment_form_page.dart` (no balance or outstanding reference); `_repaymentDirection` in `transactions_repository_impl.dart` |
| PF-02 Repayment direction editable | **Confirmed** | 001 FR-015 lets users edit "amount, direction, date, note" with no exception for repayments, and the code does exactly that. The `SegmentedButton<TransactionDirection>` in `transaction_form_page.dart` is always enabled. `TransactionFormCubit.submit()` passes `state.direction` to `EditTransaction`. `TransactionsRepositoryImpl.editTransaction` writes `direction` without checking `existing.kind`. A repayment flipped to the debt's own direction makes the debt grow by twice the amount and still shows "سداد". | the three files named; 001 spec FR-015 |
| PF-03 Social money mixed with loans | **Confirmed (by design)** | The `counts_toward_balance` flag defaults to *true* for every occasion type except condolence (008 FR-018). The balance SQL includes every row where the flag is true. So a gift received at a wedding makes the giver show under "إجمالي المستحق عليك". This is a product-policy question (Owner decision Q1), not a code defect. | `balance_queries.dart`; 008 FR-018 |
| PF-04 Exchange rates revalue history | **Confirmed, plus an inconsistency** | `ExchangeRates` holds one current rate per currency (no effective date). Person balances, overview totals, finance totals, budget actuals and occasion totals convert at **today's** rate on every read. **Savings contributions convert at the rate in effect when the entry is saved or edited (not the entry's own date)** and store both figures (011 FR-028; `savings_repository_impl.dart:403,456-458`; corrected 2026-10-05 per audit NF-02). The app therefore uses two different revaluation policies at once. | `app_database.dart` `ExchangeRates`; `person_balance_calculator.dart`; `log_contribution.dart` |
| PF-05 Change history hidden | **Confirmed** | `TransactionAuditEntries` and `SavingsContributionAudits` are written on every create, edit and delete, and synced (append-only). No widget or cubit reads them. | no reference under `lib/features/*/presentation` |
| PF-06 "تمت التسوية" means two things | **Confirmed** | `personDetailSettled` and `occasionSettlementSettled` are both "تمت التسوية". The occasion status is `totalReceived − totalGiven` across *all* participants: a net of money in and out for the event, not a settlement. | `app_ar.arb`; `occasion_summary.dart` |
| PF-07 Formal wording | **Confirmed** | "إجمالي المستحق لك/عليك", "تسجيل سداد" and "أعطيت/استلمت" (with no purpose given) are shipped copy. They are correct but formal. Wording only. | `app_ar.arb` |
| PF-08 Date shifts across devices | **Partially confirmed** | On the same device, dates are stable (`DateTime.fromMillisecondsSinceEpoch` applies the timezone rules of that instant). **Across devices in different time zones:** push sends `occurred_on` and `tz_offset_minutes`, but pull rebuilds `date` from the `occurred_at` *instant* (`SyncWire.parseInstant(json['occurred_at'])`). A row saved at local midnight on a UTC+3 device is read as 23:00 the previous day on a UTC+2 device. It then shows one day earlier and can **fall into the previous month for budgets and reports**. Money transactions and finance entries are affected. Savings contributions send only an instant (`'date'`), with no calendar day. | `money_transaction_sync_mapper.dart:57`; `finance_entry_sync_mapper.dart:48`; `savings_contribution_sync_mapper.dart:34,62`; `sync_mapper_registry.dart` `occurrence()` |
| PF-09 Repayment not linked to a debt | **Confirmed (by design)** | Running-net model, per the spec Clarifications. Classified as Optional future feature (H1). | `MoneyTransaction` |
| PF-10 PRODUCT.md out of date | **Confirmed** | It says "no backend, sync, account" and lists 008–015 as not built. All of them are shipped. | `PRODUCT.md` |
| PF-11 Sync conflict coverage | **Confirmed gap** | The server push RPC gives the `financial` (manual-conflict) policy only to `money_transaction` and `finance_entry`. **`savings_contribution` is last-write-wins** (migration 023 comment: "the app's conflict screen only knows money transactions and finance entries"). If two devices edit the same contribution offline, one amount is overwritten without the user being shown anything. The append-only contribution audit keeps only the value *before each device's own edit*, so the overwritten intermediate value (e.g. 500 → 600 on A, 500 → 700 on B; 600 lost) appears nowhere (audit F-SYNC-03). `exchange_rate` and `primary_currency` are also last-write-wins; these are settings, and acceptable (see Decision R4). | `supabase/migrations/20260930090000_023_savings_goals_sync.sql` lines 13–16, 250–300 |
| PF-12 Archived people inside totals | **Refuted** | The overview person rows show an archived marker (`home_page.dart:391`, `PersonSummary.isArchived`). The archived portion of a total can be traced. | `home_page.dart` |

## 2. New verified findings

| ID | Finding | Root cause | Evidence | Severity |
| --- | --- | --- | --- | --- |
| RF-01 | The currency of an existing transaction can be changed on edit. The amount *digits* are kept, so "1,000 EGP" becomes "1,000 USD" with no confirmation. | `CurrencyPicker` is shown and enabled in edit mode; `editTransaction` writes `currencyCode`. Allowed by 018 FR-004 ("the user directly editing that record"), but there is no guard against a mis-tap. | `transaction_form_page.dart:234`; repository `editTransaction` | P2 |
| RF-02 | Income and expense edits keep no previous values. A changed expense can't be explained later. | There is no `finance_entry_audits` table. Only `edited_at` is stored. People transactions and savings contributions do have audits. | `app_database.dart` (audit tables: transactions and savings only) | P2 |
| RF-03 | Data export leaves out occasions, budgets and allocations, savings goals and contributions, exchange rates, and all change history. | `ExportUserData` (013) composes only the people, transactions, finance, categories and settings repositories. Modules 008/010/011 were added after it and never wired in. | `export_user_data.dart` | P2 |
| RF-04 | Repayment direction is arbitrary in one corner case. When the converted balance is blocked with opposite-direction currencies, and the repayment's currency has no rows for that person, the direction defaults to "given". | The fallback in `_repaymentDirection` treats "no positive net in this currency" as "you owe them". | `transactions_repository_impl.dart` `_repaymentDirection` | P3 |
| RF-05 | There is no possible-duplicate warning for transactions (same person, amount, direction and date). | Not specified in 001. Only *person* duplicates are detected. Technical duplicates are fully prevented by the idempotency key (unique index plus a single-flight submit), as verified. | `transaction_form_cubit.dart` (`idempotencyKey`, `isSubmitting` guard); `transactions_dao.dart` `insertTransactionIdempotent` | P3 (Improvement) |
| RF-07 | Amounts typed with the Arabic thousands separator `٬` (U+066C), for example "١٬٥٠٠", are rejected as invalid. | `NumeralParser.toWesternDigits` converts Arabic-Indic digits and `٫` but not `٬`. `CurrencyFormatter.parse` then strips only `,` and whitespace. | `numeral_parser.dart`; `currency_formatter.dart` `parse` | P3 |
| RF-08 | An income/expense entry can switch type on edit (pick a category of the other type). A 1,000.00 EGP expense edited into income moves the net by 2,000.00 EGP, and with RF-02 no previous value is kept. | The edit form keeps the Expense/Income toggle enabled; the repository re-derives `type` from the category (`finance_entry_form_page.dart:156-171`, `finance_entry_form_cubit.dart:59`, `finance_repository_impl.dart:88-92`). Allowed by 007's design, but untraceable today. | found by the Opus audit review, 2026-10-05 | P2 (P1 while RF-02 is open) |
| RF-09 | The people list shows the true "no people yet / add a person" empty state when a search or filter matches nobody. | No separate no-results state (audit UX-13). | audit §7 | P3 |
| RF-10 | The export screen promises "a complete copy of your data", but the export leaves out occasions, budgets, savings, rates and history (RF-03). | Copy predates 008–011 (audit UX-14). | `exportDescription` in the ARB files | P2 |
| RF-11 | The delete-all-data warning doesn't mention savings goals or exchange rates, although the wipe deletes them. | Copy predates 011/018 (audit UX-15). | `deleteDataWarningMessage` in the ARB files | P3 |
| RF-06 | The AI assistant gets its figures from deterministic tools (`get_person_balance_tool`, `get_budget_status_tool`, …). It can still do free-text arithmetic on top of them, for example adding two balances in a sentence. | Tool results are grounded, but the model's prose is not checked against them. | `lib/features/ai_assistant/domain/tools/*` | P3 (audit to measure) |

## 3. Areas verified as sound (no fix planned)

These were checked so the plan does not "fix" working behavior (FR-001, constitution "Refactoring Discipline"):

- **Money representation**: integer minor units throughout, with a 12-digit whole-part cap to prevent int64 overflow (`currency_formatter.dart`). Budget percentages are display-only, and threshold comparisons are done in integers (`budgetStatusFor`).
- **Technical duplicates**: idempotency key per form open, a unique index, a single-flight `submit()`, and an idempotent insert that doesn't write a second audit or outbox row.
- **Stale state**: every list, detail and total cubit for people, transactions, overview, dashboard, finance, budgets, occasions and savings subscribes to Drift `watch` streams (`watchEither` over the tables it depends on). Archive and restore and new rows propagate without manual refresh. Features 004 and 005 already fixed the earlier stale-state defects.
- **Error copy**: `FailureMessage.messageFor` maps every `Failure` to localized text. The raw `$e` inside `CacheFailure` messages never reaches the UI.
- **Sync for transactions and finance entries**: base-revision conflicts are blocked into `sync_conflicts`. `ConflictResolver.keepMine/keepTheirs` keeps the discarded side in `conflict_resolutions`, so no version is ever lost.
- **Savings maths**: pure, integer-only, rounds up, and is guarded against divide-by-zero (`savings_calculator.dart`). A withdrawal larger than the balance is rejected (`WithdrawalExceedsBalanceFailure`).
- **Budget actuals**: computed only from finance expense entries. `finance_dao.dart` never joins `money_transactions` (spec Clarification on income and expense separation holds).
- **Delete guards**: a person with transactions can only be archived (also enforced on the server: `person_has_transactions`).

## 4. Decisions

### R1 — Lock the direction of a repayment in edit at both the repository and the UI
- **Decision**: `editTransaction` returns `ValidationFailure` when `existing.kind == repayment` and `direction != existing.direction`. The form shows direction as read-only for a repayment.
- **Rationale**: The repository guard is the real fix (Domain/Data own the rules, constitution Principle V). The UI change only removes a control that would always fail. The same pattern already exists for `kind`.
- **Alternatives**: UI-only (rejected: sync replay or a future caller could bypass it). Recomputing direction from the balance on edit (rejected: the balance at edit time is not the balance at record time).

### R2 — Rebuild the calendar date from `occurred_on` on pull
- **Decision**: For money transactions and finance entries, `fromWire` builds `date` as local midnight of `occurred_on`, falling back to `occurred_at` when `occurred_on` is absent. Savings contributions are out of scope for the client-only fix because the wire carries no calendar day; they go into G3.
- **Rationale**: The calendar day is what the user picked, and it is already on the wire. No schema or migration change is needed.
- **Alternatives**: Storing UTC dates locally (rejected: a migration that touches every row, and a bigger blast radius).

### R3 — Move `savings_contribution` to the `financial` conflict policy
- **Decision**: A new forward migration (`025_…`) replaces the push function so that `savings_contribution` uses `v_policy := 'financial'` **only for app versions that can show the conflict** (`p_app_version` of at least R1; see R6). The client conflict list and resolution sheet learn to render that entity type.
- **Rationale**: This is the same mechanism already proven for two entity types (smallest correct change). Migrations are never edited in place (repo convention).
- **Alternatives**: Leave it as last-write-wins and only show the audit history (rejected: the spec Clarification says a silent last-write-wins on money is P0).

### R4 — Keep `exchange_rate` and `primary_currency` as last-write-wins
- **Rationale**: These are *settings*, not ledger records. They already show "last updated". A manual-conflict flow for a setting would be heavy for little benefit. How historical revaluation behaves depends on Owner decision Q2, not on the sync policy.
- **Recorded in**: spec Clarifications (an explicit, reversible decision), so it no longer contradicts the P0 rule about silent last-write-wins on money.

### R6 — Protect installed older apps on the server side
- **Finding**: `_parseChange` (`sync_remote_data_source.dart:104-106`) throws on an unknown `entity_type`, which fails the whole download page. A v1.0.1 app parks a conflict for a type its conflict screen doesn't know where nothing ever shows it (`sync_local_store.dart` `_block` plus `ConflictEntityType.tryFromWire`).
- **Decision**: Installed apps can't be patched, so the server adapts:
  - `sync_push` gates new policies on `p_app_version`, which it already receives;
  - the existing `sync_pull(bigint, int)` keeps its exact set of types;
  - a new `sync_pull_v2` serves newer apps.
  
  New apps also skip unknown types, so this never recurs.
- **Alternatives**: A minimum-app-version setting (rejected: v1.0.1 never reads it). Forcing users to update (rejected: it isn't possible offline-first, and it's hostile).

**Update 2026-10-06**: the release plan became a single 1.1.0 release deployed after migrations 025 and 026 (the B1 repair needs the v12 schema that ships with D2). The server-side protections above are unchanged.

### R7 — Repair dates that were already shifted (B1)
- **Finding**: The download position only moves forward, so rows downloaded with a shifted date are never fetched again.
- **Decision**: Reset the download position to 0 once, behind a stored flag (`sync_state.b1_repull_done`), the first time the fixed app syncs. `SyncApplier` already skips rows with pending local changes or open conflicts (`sync_applier.dart:120-135`), so no local work is overwritten.
- **Alternatives**: Recompute dates locally (rejected: the local row doesn't keep `occurred_on`). Accept the gap (rejected: wrong budget months would stay forever).

### R8 — Detect repayments already flipped by the A1 defect
- **Decision**: A repayment counts as "flipped by edit" when one of its `edited` audit entries has a `previous_values_json.direction` different from the row's current direction. This is exact, because the audit stores the old direction on every edit. The audit (§16) reports the count. No data is rewritten automatically (Financial Domain Override). The UI tells the user to delete the row and record it again.

### R5 — Work that depends on owner decisions is planned but kept separate
- C1 (social money) depends on Q1. C2 (rate policy) depends on Q2. A3/E2 (over-repayment) depends on Q3: the plan implements the policy-neutral part (a preview plus a confirmation) and holds anything that would change the 001 FR-012 behavior.
