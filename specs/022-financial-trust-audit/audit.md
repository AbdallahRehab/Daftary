# Daftary Financial Trust Audit

**Feature**: 022 · **Baseline**: `main` at v1.0.1 (`c86e2df`), 3,699 tests passing, schema version 11 (`lib/core/database/app_database.dart:735`) · **Written**: 2026-10-05 (Track 1 findings describe v1.0.1; the US6 fixes named in section 1 were implemented on the branch afterwards and Opus-reviewed)

**How to read the evidence tags.** `code-traced` = I read the code path and wrote down what it does. `test` = an existing automated test asserts it. `traced, not executed` = no emulator or backend was available in this environment, so nothing here was run on a device. A bare file name is unique under `lib/` (or `test/` for `_test.dart`); line numbers refer to v1.0.1 (`c86e2df`) and may have moved in files changed on this branch.

**Naming note.** The sync analysis findings C1/C2 (older-app risks) share their letters with plan items C1/C2 (social money, exchange-rate policy). In this document the analysis findings are written **AN-C1** and **AN-C2**; plan items keep their plan names.

## 1. Executive Summary

- **Verdict.** The ledger arithmetic is sound: every one of the 27 user-visible figures is a deterministic, integer-based calculation (section 4); no stale-state defect was found (section 9); a missing exchange rate blocks a figure instead of guessing it.
- **Findings.** 8 findings are P0 or P1 (section 16): **4 P0** (A1 repayment direction editable; S0 two latent older-app sync failures; A3 savings edits overwrite silently) and **4 P1** (A2 over-repayment without a preview; C1 social money inside loans; C2 two exchange-rate policies; D2 no history for income and expense edits). Ten more are P2; the rest are P3 (section 14; the UX and RTL issues in sections 7 and 8 map to the same backlog items).
- **Three biggest trust risks.** (1) A repayment could be edited into a new debt with no trace (A1; fixed on the branch, Opus-reviewed). (2) Several figures can change with no edit and no explanation: an exchange-rate change revalues past income, expense and budget totals (C2), income and expense edits and type switches leave no history (D2, RF-08), and two devices can silently overwrite a savings amount (A3). (3) A wrong deploy order could stop sync for every installed v1.0.1 app (S0).
- **Test baseline.** v1.0.1: 3,699 tests passed, none covering an A or B defect. Branch after all fixes: full suite 4,078 passed, 1 skipped (opt-in fixture regeneration), 0 failed; the `TZ=UTC` sync suites 266 passed; analyze 0 issues; format clean; no Known-fail skips remain. Also run: the SQL tests for migrations 025 and 026 (`supabase test db`, 316 of 316 passed locally on 2026-10-06; T067 ticked). Not run: emulator and device flows (T017, T020, T086-T088).
- **Status of the fixes.** Implemented on the branch and reviewed (Opus: approve): S0, A1, A2 (with E2, E4), A3 (client plus migration 025; SQL tests passed locally, not yet deployed), B1 (with the one-time repair), B2, C3, C4, D1, D2 (migration 026; SQL tests passed locally, not yet deployed), E3, E5, E6, F2, F3, G1, G2. Implemented in the convergence pass, not yet reviewed: E7 (T097) and F4 (T092). Still open: E1 and E8 (owner wording sign-off, T023), E9 (Q4), G3, G4, H1-H6; C1 (Q1), C2 (Q2) and the blocking variant of A2 (Q3) wait for the owner.
- **Release order is binding.** Deploy migration 025, then migration 026, then release app 1.1.0 (one release: the B1 date repair needs schema v12, which ships with D2). Migration 025 also filters `conflict_resolutions` out of `sync_pull` for v1.0.1 (the review found a v1.0.1 pull stall otherwise); 026 adds `sync_pull_v2`, used by 1.1.0 (section 11.4). The user runs `supabase db push`.
- **Reporting and reconciliation.** One person, one occasion and one budget month were walked through (section 12): totals reconcile to their rows. The gaps are a per-person statement with a running balance, a visible change history, a currency filter, and an incomplete export (backlog D3, C3, D1).
- **Wording.** One Arabic label means two things ("تمت التسوية"), and several accounting words reach consumers. 35 wording changes are proposed in section 8 and wait for the owner (E1, native-speaker review).
- **Decisions needed from you:** E1 (wording sign-off), Q1 (social money), Q2 (exchange-rate valuation), Q3 (over-repayment), Q4 (type switch on edit). S1 is answered.
- **Not executed.** No emulator or development backend was available. Flows (section 5) are `traced, not executed`; the device run of the acceptance checklist (T020) and the emulator flows (T017) are still owed.


## 2. Current Product Assessment

**What it is.** A local-first personal money notebook for Egyptian users: people and money given or received, repayments, occasions (نقوط), income and expense, budgets, savings goals, reports, a home dashboard, OCR entry, an AI assistant, app lock, multi-currency, and optional cloud sync. Everything is stored on the device; sync is optional and uses the user's own cloud project.

**Against its own sources of truth (FR-003).**

| Source | What it says | What ships | Verdict |
| --- | --- | --- | --- |
| PRODUCT.md | No backend, sync or account; occasions, OCR, budgets and savings not built | All of them are built; sync and accounts are optional features (PF-10) | Out of date (G1) |
| 001 spec FR-015 | Direction is editable on edit | True for every kind, including repayments | Now wrong for repayments (A1, G2) |
| 011 and 018 specs | Savings entries use a rate "on the contribution date" | The rate in effect when the entry is saved or edited (NF-02) | Wording to correct |
| Constitution (Financial Domain Override) | Every financial mutation traceable | People transactions and savings: yes (history stored, not shown). Income and expense: no | Partly met (C3, D2) |
| Spec Clarifications (single running net per person) | No debt-by-debt tracking | As specified | Met |

**Strengths (verified).** Exact money arithmetic; idempotent saves; soft deletes with audit for people transactions and savings; per-row currency; a blocked-not-guessed rule for missing rates; one live data stream per screen; manual conflict resolution for transactions and income and expense with both versions kept; a complete wipe guarded by a test; AI answers drawn from deterministic tools.

**Weaknesses.** Edits are not always explainable (no history screen, none at all for income and expense). A rate change silently revalues history. Savings sync is last-write-wins. Wording mixes two Arabic registers and uses accounting terms. Export is incomplete. One Arabic label ("تمت التسوية") carries two meanings, the clearest wording clash.

**Maturity by area.**

| Area | State |
| --- | --- |
| People, balances, repayments | Correct arithmetic; one P0 (A1) and one P1 (A2) addressed on the branch, Opus-reviewed |
| Occasions | Correct totals; policy question on social money (Q1) |
| Income, expense, categories | Correct totals; no edit history (D2); type switchable on edit (RF-08) |
| Budgets | Correct thresholds in whole numbers; no drill-down from a line to its expenses |
| Savings | Correct, integer-only; sync gap (A3); partial total disclosed (NF-03) |
| Currency | Blocking rule sound; two valuation policies (C2) |
| Sync | Safe for transactions and income and expense; savings gap; latent older-app risks (S0) |
| Reporting and export | Totals trace to rows; export incomplete (D1); no statement (D3) |
| Security and privacy | Sound for a local PIN and wipe; database not encrypted at rest (accepted); Android backup setting unverified (NF-06) |


## 3. Accounting Assessment

Plain terms used below. **Net balance** = what you gave a person minus what you received from them, counting only live (not deleted) rows (`lib/core/database/balance_queries.dart`). **Reversible** = the user can undo it in the app, with a trace left behind. **Need** = whether the product needs this concept now, later or never (FR-005). **Sync** values: `financial` = if two devices change the same record, the app shows both versions and the user chooses; `lww` (last write wins) = the later upload silently replaces the earlier one; `append` = history rows that are only ever added. **Soft delete** = the row is hidden from all figures but kept. **Idempotency key** = a hidden ID per form that stops a retried save from creating a second row.

### 3.1 Concepts the product has (FR-004)

Edit means the fields the form allows: amount, direction, date, note and currency for a people transaction (`transaction_form_page.dart:195,234`); amount, category (**including a category of the other type, which turns an expense into income or the reverse**), date, note and currency for an income or expense entry (`finance_entry_form_page.dart:156-171`, `finance_repository_impl.dart:88-92`). Delete is a soft delete (the row stays, marked deleted) with an audit row for people transactions and savings entries (`transactions_repository_impl.dart:182-212`, `savings_repository_impl.dart:505-530`) and **no** audit row for income and expense (RF-02).

| Concept | Meaning | Effect on balances | Reversible | Partial | Edit | Delete | Offline | Sync | Need |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Given (أعطيت, I gave) | Money the user handed to a person (`kind = initialExchange`, `direction = given`) | Raises that person's net (they owe you more, or you owe them less) | Yes: delete, or edit with audit | n/a | Allowed (incl. direction, currency: RF-01) | Soft delete + audit; no warning when later repayments depend on it (E6) | Yes, local DB is the source of truth | `financial` policy: base-revision conflict, user picks a side | Now (exists) |
| Received (استلمت, I received) | Money received from a person | Lowers the net (they owe you less, or you owe them more) | Yes, as above | n/a | As above | As above | Yes | `financial` | Now (exists) |
| Repayment, partial (سداد) | Money paid back against a running net; direction is inferred, never typed (`_repaymentDirection`, `transactions_repository_impl.dart:361`) | Moves the net toward zero by exactly the amount | Yes: delete. **Edit can flip its direction (A1, P0)** | Yes: any amount; the balance is one running net, not per debt | Amount, date, note OK. Direction editable: defect (A1). Currency editable without conversion (RF-01, E3) | Soft delete + audit | Yes | `financial` | Now (exists). Fix A1 |
| Repayment, full | A repayment equal to the outstanding net | Net becomes 0, status "تمت التسوية" / "Settled" | Yes | Yes | As above | As above | Yes | `financial` | Now (exists) |
| Over-repayment | A repayment larger than the outstanding net | The net changes sign (the other person now owes), by design (001 FR-012); the form shows no outstanding amount or preview (A2) | Yes | n/a | As above | As above | Yes | `financial` | Now (exists). A2 adds a preview; blocking it waits on Q3 |
| Occasion contribution, counting (نقطة, social money) | A gift given or received at an event, stored as a people transaction linked to an occasion (`kind = occasionContribution`, `counts_toward_balance = 1`) | **Included** in the person's loan net (PF-03), so a wedding gift received shows as "you owe them" | Yes | n/a | Via the occasion screen; direction editable | Soft delete; deleting the occasion soft-deletes its rows (`occasions_repository_impl.dart:149-157`) | Yes | `financial` (it is a `money_transaction`) | Now (exists). Policy question Q1 (C1) |
| Occasion contribution, non-counting (condolence default) | Same row type with `counts_toward_balance = 0` | **Excluded** from every person balance and overview total (`balance_queries.dart` predicate); still counted in the occasion's own totals | Yes | n/a | As above | As above | Yes | `financial` | Now (exists) |
| Settlement ("تمت التسوية") | **Not stored.** A derived status meaning the person's net is exactly 0. For an occasion the same words mean money in = money out (PF-06) | Derived from the net, never an independent record | n/a | n/a | n/a | n/a | n/a | n/a | Now (exists) as wording; E1 separates the two meanings |
| Net balance | `Σ given − Σ received` per currency, converted into the primary currency | The person's headline figure | n/a (derived) | n/a | Recomputed live | Recomputed live | Yes | Recomputed from synced rows | Now (exists) |
| Owed-to-me total (إجمالي المستحق لك) | Σ of positive person nets, never netted against what you owe | Overview figure | n/a | n/a | Live | Live | Yes | Derived | Now (exists); wording E1 |
| I-owe total (إجمالي المستحق عليك) | Σ of negative person nets, as a positive number | Overview figure | n/a | n/a | Live | Live | Yes | Derived | Now (exists); wording E1 |
| Income | Money earned, a finance entry of an income category | Income total and net (income − expense); **never** touches a person balance or savings (`finance_dao.dart` has no join to `money_transactions`) | Yes: delete, then restore | n/a | Allowed; no history kept (RF-02) | Soft delete, restorable, no audit (RF-02) | Yes | `financial` | Now (exists). D2 adds history |
| Expense | Money spent, a finance entry of an expense category | Expense total, net, and the category's budget actual | Yes | n/a | As above | As above | Yes | `financial` | Now (exists). D2 |
| Category | A label for entries; type income or expense | Groups totals and breakdown; archiving keeps old entries counted (`finance_dao.dart` breakdown joins archived categories) | Archive and restore | n/a | Rename | Archive only when entries exist (`countEntriesForCategory`) | Yes | `lww` | Now (exists) |
| Budget allocation | A planned amount for one expense category in one month, in the budget's own currency | Defines "planned" and therefore remaining, percentage and status; changes no money | Yes (edit or remove) | n/a | Planned amount editable | Hard delete locally; a delete op on the server | Yes | `lww` (a plan, not a recorded fact) | Now (exists) |
| Unbudgeted spending | Expense in the month in a category without an allocation | Shown beside, not inside, the overall budget actual | n/a (derived) | n/a | Live | Live | Yes | Derived | Now (exists) |
| Savings contribution | Money set aside toward a goal; stored twice: as entered and converted into the goal's currency | Raises the goal's current amount | Yes: edit or delete (delete refused if it would take the balance below 0) | n/a | Re-converted at the rate in effect at edit time; the prior values go to the audit row (`savings_repository_impl.dart:456-457`) | Soft delete + audit | Yes | **`lww`: two devices can silently overwrite each other (A3, P0 by the sync rule)** | Now (exists). Fix A3 |
| Savings withdrawal | Money taken back out of a goal | Lowers the current amount; refused when larger than the balance (`WithdrawalExceedsBalanceFailure`) | Yes | n/a | As above | As above | Yes | `lww` (same gap) | Now (exists) |
| Exchange rate | One current rate per currency pair (`ExchangeRates`: no effective date) | Every foreign-currency figure is re-valued at this rate on every read, except savings entries (see 3.3) | Yes (set again) | n/a | Overwrites the previous rate; no history | Removing a rate blocks figures that need it | Yes | `lww` (accepted for a setting, R4) | Now (exists). Policy question Q2 |
| Primary currency | The currency all totals are shown in | Changes the unit of every total; switching without a rate for the old currency is refused while it is in use (`set_primary_currency.dart:65-80`) | Yes | n/a | Settable | n/a | Yes | `lww` | Now (exists) |

**Duplicates.** A retried save cannot create a second row: each form open carries an idempotency key, the key has a unique index, the insert is idempotent and writes no second audit or sync row (`transaction_form_cubit.dart`, `transactions_dao.dart` `insertTransactionIdempotent`; verified in research §3). A *possible* duplicate (same person, amount, direction, date) is not detected (RF-05, C4).

### 3.2 Concepts the product does not have (FR-005)

| Concept | Meaning | Today | Need | Reason |
| --- | --- | --- | --- | --- |
| Refund | Money returned for a purchase or loan | An expense can be edited or deleted; a loan refund is a repayment | **None** | No bookkeeping need for the target user (PRODUCT.md: not an accounting tool); income plus edit covers the rare case |
| Adjustment or correction | A dated entry that corrects a past figure | Edit and soft delete with audit for people transactions and savings | **None as a new type** | Corrections already exist as edit/delete. They are only trustworthy once the history is visible (C3) and recorded for income/expense (D2) |
| Transfer | Money moved between the user's own accounts or wallets | The app has no accounts or wallets | **None** | Would turn the product into an ERP (spec constraint) |
| Gift as distinct from a loan | Money given with no expectation of return | Only inside occasions (`counts_toward_balance`); outside occasions every row is a loan | **Now** (decision-dependent) | PF-03: social money is mixed into "إجمالي المستحق عليك". The split is C1 and waits for Owner decision Q1 |
| Opening balance | An existing debt when the user starts using the app | Record a dated "given" or "received" with a note | **Later** (H3) | A workaround exists and costs one entry |
| Forgive a debt (write-off) | Closing a balance without payment | The user must fake a repayment, which then distorts the repayment history | **Later** (H2) | Real but infrequent; an explicit kind is cleaner than a fake repayment |
| Link a repayment to a specific debt | "This 400.00 EGP pays the 1,000.00 EGP from March" | Not possible; one running net per person (spec Clarifications, PF-09) | **Later** (H1) | Needed for debt ageing, not for "how much is owed" |

### 3.3 Accountant observations

1. **Two valuation policies at once** (PF-04). Every figure except savings entries is converted at *today's* rate on every read; savings entries are converted once, at the rate in effect when saved/edited. In accounting terms: amounts owed to/by a person and money held in a savings goal are *monetary balances*, and restating them at today's (closing) rate is the normal treatment, so the people balances and overview totals behave as an accountant expects. Income, expense and budget actuals are *flows of a past period*; an accountant expects them at the rate of the day they happened, so revaluing them changes last month's figures with no edit (the actual deviation). Savings are mixed: an entry in another currency is converted into the goal's currency once, at the rate when saved or edited, and never restated; the goal's own balance is then restated into the primary currency at today's rate on the savings overview (FF-27). Occasion totals are built from the same rows as the people balances, so valuing them differently from those balances would break the cross-check in section 12.4. Owner decision Q2 should therefore be framed as 'flows at transaction-date rate, balances at today's rate' vs 'everything at today's rate'. (Evidence: `app_database.dart` `ExchangeRates`; `person_balance_calculator.dart`; `savings_repository_impl.dart:403`.)
2. **Savings rate timing (NF-02).** Savings entries use the rate in effect *when the entry is saved or edited*; the entry's `date` plays no part, so a back-dated entry still uses today's rate. research.md PF-04 was corrected to match on 2026-10-05.
3. **No single net position.** The product never nets what is owed to you against what you owe (by design); the two totals are separate numbers. Daftary is single-entry, so there is no double-entry ledger and no trial balance to tie out; reconciliation is per person (FF-01) and per occasion (FF-08).

## 4. Financial Logic Assessment

### 4.0 Rules that apply to every figure

- Amounts are integers in minor units (piastres, cents); a 12-digit whole-part cap prevents overflow (`currency_formatter.dart`). Verified sound (research §3).
- Conversion into the primary currency uses one current rate per pair, rounds half-up away from zero, and is exact (`BigInt`, `currency_converter.dart`). A missing rate never falls back to 1:1: the figure is **blocked** (shown as unknown) and never partially summed, except for the savings overview total (observation NF-03, section 14).
- Live updates: each figure is a Drift watch stream that re-reads when any table it depends on changes (section 9).
- "Pinned by" names the catalogue test planned in tasks.md. Paths are the T004-T010 files; all seven exist on the branch.

Catalogue files: **P** = `test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart` (T004) · **OV** = `.../overview_catalogue_test.dart` (T005) · **RP** = `.../repayment_catalogue_test.dart` (T006) · **OC** = `test/features/occasions/domain/catalogue/occasion_totals_catalogue_test.dart` (T007) · **FN** = `test/features/finance/domain/catalogue/finance_summary_catalogue_test.dart` (T008) · **BG** = `test/features/budgets/domain/catalogue/budget_catalogue_test.dart` (T009) · **SV** = `test/features/savings/domain/catalogue/savings_catalogue_test.dart` (T010).

### 4.1 People

**FF-01 Person net balance (الرصيد)** · screens: person detail, people list, home overview
- Definition: how much one person owes you (positive) or you owe them (negative), in your primary currency.
- Rule: per currency, `SUM(amount WHERE direction = given) − SUM(amount WHERE direction = received)` over rows with `deleted_at IS NULL` and not a non-counting occasion contribution (`lib/core/database/balance_queries.dart`). Zero nets are dropped; each non-zero currency net is converted once at today's rate and summed (`person_balance_calculator.dart`). Status is the sign: positive "they owe you" (لك عندهم), negative "you owe them" (عليك لهم), zero "Settled" (تمت التسوية).
- Inputs: the person's live transactions, `exchange_rates`, `primary_currency_settings`.
- Increases: a new "given"; deleting a "received"; editing a "given" up or a "received" down.
- Decreases: a new "received" (including repayments from them); deleting a "given".
- Edit: recalculated live; changing direction moves the net by 2 × amount; changing currency keeps the digits (RF-01).
- Delete: soft-deleted rows drop out. Deleting a debt while later repayments remain flips the sign (E6).
- Archive: archiving the person does **not** change the net; the person stays in overview totals and shows an archived marker (`home_page.dart:391`; PF-12 refuted).
- Rate change: the foreign-currency part is re-valued immediately at the new rate.
- Blocked case: a missing rate makes `net = null` and shows the unconverted per-currency nets with a "rate needed" banner; the status is still known when all native nets point the same way (`person_balance.dart`).
- Traceable: **yes** for rows (person history lists every row); **partial** for *why a row changed*, because the audit history is stored but has no screen (PF-05, C3).
- Pinned by: **P** (CHK011-CHK017, CHK029-CHK032). Findings: PF-01, PF-02, PF-03, PF-04, PF-05.

**FF-02 Repayment direction (inferred)** · screen: repayment form (no visible figure; it decides the sign of the saved row)
- Definition: whether a "سداد" is stored as received or given.
- Rule: if the person's status is "they owe you" the repayment is **received**; every other status, including settled, is **given** (`_repaymentDirection`, `transactions_repository_impl.dart:361-377`). When the status is unknown (nets in two currencies pointing opposite ways with a missing rate) the sign of the net in the repayment's own currency decides; no positive net there means **given** (RF-04). With nets in two currencies pointing opposite ways and all rates present, the current rate decides the converted sign and therefore the inferred direction.
- Inputs: the person's current converted balance.
- Increases/decreases: moves the net toward zero if the payer is the debtor; creates a new debt in the other direction if the status was settled or the amount exceeds what is owed.
- Edit: **direction is editable after the fact (A1)**, so the stored direction can be changed to the debt's own direction.
- Delete: removes the repayment and restores the earlier balance.
- Archive / rate change: none directly; a rate change can change which status the inference sees at *record time* only.
- Traceable: yes.
- Pinned by: **RP** (CHK023, CHK024, CHK026 balance outcome; the A1 and B2 cases are active on the branch (T040)). Findings: PF-01, PF-02, RF-04.

### 4.2 Overview

**FF-03 Total owed to you (إجمالي المستحق لك)** · screen: home overview
- Definition: the sum of everything people owe you, in the primary currency. Never reduced by what you owe.
- Rule: `Σ net` over all people (active **and archived**) whose status is "they owe you" (`_computeOverview`, `transactions_repository_impl.dart:274-355`). `null` (unknown) if any contributing person is blocked, or any person is rate-needed.
- Inputs: every person's FF-01.
- Increases: as FF-01 for those people. Decreases: as FF-01.
- Edit/Delete: live. Archive: no change (archived people stay in the total). Rate change: re-valued.
- Traceable: **yes** (grouped list of people with archived marker, sorted by latest activity).
- Pinned by: **OV** (CHK004, CHK018, CHK019, CHK021, CHK082).

**FF-04 Total you owe (إجمالي المستحق عليك)** · same rule with `Σ (−net)` over people whose status is "you owe them". Same inputs and effects. Pinned by **OV**.

**FF-05 Settled count** · not shown as a headline; used by the dashboard's "has people" check and by the AI overview tool (`dashboard_snapshot.dart:49-60`, `get_owed_overview_tool.dart:80`).
- Definition: number of people whose status is settled.
- Rule: `settledCount++` for every person row (active and archived) whose converted status is settled (`transactions_repository_impl.dart:325`). A person with **no transactions at all** has no nets, so counts as settled (observation NF-04).
- Edit/Delete: live. Archive: no change. Rate change: can move a person in or out only through a rate-blocked status.
- Traceable: partial (a count of people, no list of the settled).
- Pinned by: **OV** (CHK021). Existing: `transactions_repository_impl_test.dart:332`.

### 4.3 Occasions

**FF-06 Occasion total received (إجمالي المستلم)** · screen: occasion detail
- Definition: money received at the event from all participants.
- Rule: every non-deleted occasion row with `direction = received` is converted at today's rate and summed (`occasions_repository_impl.dart:255-300`). **Includes non-counting rows** (condolence). Each row is converted separately (see NF-05).
- Inputs: the occasion's rows, rates. Increases: a new received contribution. Decreases: deleting or editing one down.
- Edit/Delete: live (watch includes `moneyTransactions`). Deleting the occasion soft-deletes every row it owns (`:149-157`), which also removes them from person balances. Archive occasion: rows unchanged (`_setArchived` only toggles the flag). Rate change: re-valued.
- Traceable: yes (participant rows listed).
- Pinned by: **OC** (CHK068 800/200/+600, CHK069, CHK071-CHK073, CHK083).

**FF-07 Occasion total given (إجمالي المدفوع)** · the mirror of FF-06 for `direction = given`. Pinned by **OC**.

**FF-08 Occasion net / outstanding** · `totalReceived − totalGiven`; the screen shows its absolute value (`occasion_summary.dart`). Pinned by **OC**.

**FF-09 Occasion status** · three outcomes. Net 0: "تمت التسوية" / "Settled". Net > 0: "استلمت {amount} أكثر مما دفعت" / "{amount} more received than given". Net < 0: "دفعت {amount} أكثر مما استلمت" / "{amount} more given than received" (`app_ar.arb:565-567`, `app_en.arb`). This is a money-in versus money-out comparison for the event, not a settlement between people (PF-06). It is separate from each person's own status, which is shown per participant from their whole-history balance (`occasions_repository_impl.dart` comment FR-009). Pinned by **OC**. Findings: PF-06.

Shared effects for FF-06 to FF-09: blocked when any contribution currency lacks a rate (`OccasionSummary.blocked`: the figures are placeholders and the page shows a rate-needed state).

### 4.4 Income and expense

**FF-10 Income total** · screens: finance summary, home snapshot, reports
- Definition: income recorded in the chosen period, in the primary currency.
- Rule: `SUM(amount) GROUP BY type, currency_code` where `deleted_at IS NULL` and `date BETWEEN period.start AND period.end` (`finance_dao.dart:225-257`), then each currency sum is converted at today's rate (`get_finance_summary.dart`). Blocked when a rate is missing.
- Inputs: income entries, rates. Increases: new income; edit up; restore. Decreases: delete; edit down.
- Edit: live; moving the date moves the amount between periods; changing currency keeps the digits (RF-01 applies to the finance form too, `finance_entry_form_page.dart:193`, `finance_repository_impl.dart:94`). Delete: soft delete, restorable. Archive (category): entries remain counted. Rate change: re-valued at today's rate (C2).
- Traceable: yes to rows (history list); **no** to previous values (RF-02).
- Pinned by: **FN** (CHK036-CHK042, CHK075).

**FF-11 Expense total** · same rule with `type = expense`. Same effects. Pinned by **FN**.

**FF-12 Net (income − expense)** · `FinanceSummary.net = totalIncome − totalExpense`; can be negative (1,000.00 EGP income − 1,500.00 EGP expense = −500.00 EGP); `null` when blocked. Independent of people and savings money. Edit: switching an entry's type on edit moves the net by 2 × amount (by design per 007; with RF-02 it leaves no trace). Pinned by **FN**.

**FF-13 Category share (حصة الفئة)** · screens: category breakdown chart and bar
- Definition: what fraction of the period's spending (or income, per the chosen type) one category is.
- Rule: category converted total ÷ sum of all category totals in the same breakdown, a fraction from 0 to 1; 0 when the period total is 0; `null` when any category is blocked (`get_category_breakdown.dart:91-114`). Display only.
- Inputs, increases, decreases: as FF-10/11 for that category and for all others (a share falls when another category grows).
- Edit/Delete/Archive/Rate: live; an archived category still appears with its name and icon; a rate change re-weights foreign entries.
- Traceable: yes (breakdown rows to entries).
- Pinned by: **FN** (planned; confirm the share case when T008 lands).

### 4.5 Budgets

**FF-14 Budget planned** · screen: budget month. The allocation's `plannedAmountMinorUnits` in the budget's own currency (fixed when the budget was created, `budgets_repository_impl.dart:37-39`); the total is their sum. Never converted. Edit: live. Delete (allocation): removes the line. Rate/archive: none. Traceable: yes. Pinned by **BG** (CHK047-CHK057, CHK084).

**FF-15 Budget actual (المصروف الفعلي)** · for a budgeted category: expense entries dated inside the calendar month (`BudgetMonth.toDateRange`), summed per currency and converted into the budget's currency at today's rate (`budgets_repository_impl.dart:640-680`); no expense means a known 0. **Overall actual sums budgeted lines only**; `null` if any line is blocked (`budget_summary.dart`). Inputs: expense entries only (never people money). Increases: a new expense in that category and month; edit up. Decreases: delete; edit down; moving the date or category out. Archive (category): the line stays with an archived marker. Rate change: re-valued. Traceable: partial (the category's expenses are visible in finance history, but there is no tap-through from the line). Pinned by **BG**.

**FF-16 Budget remaining** · `planned − actual`; negative when over. `null` when actual is blocked. Same effects as FF-15. Pinned by **BG** (1,799.99 → remaining 200.01; 2,000.01 → −0.01).

**FF-17 Budget percentage used** · `actual × 100 ÷ planned`, a display-only double; `null` when planned is 0 or actual is blocked (`budget_category_line.dart`, `budgetPercentageUsed`). Pinned by **BG**.

**FF-18 Budget status (الحالة)** · integer comparison, no floating point (`budgetStatusFor`): **over** (تجاوز الميزانية / Over budget) when `actual > planned`; **near limit** (يقترب من الحد / Near limit) when `planned > 0` and `actual × 100 ≥ planned × 90`; otherwise **on track** (ضمن الخطة / On track). Examples against 2,000.00 EGP: 1,799.99 on track; 1,800.00 near limit; 2,000.00 near limit; 2,000.01 over. Applies to each line and to the overall figure. Pinned by **BG**.

**FF-19 Unbudgeted spending** · expense categories in the month with no allocation and spend above 0 (or blocked), each converted into the budget's currency; the total is their sum or `null` (`budgets_repository_impl.dart:395-410`, `budget_summary.dart`). Shown separately and **not** part of overall actual. Increases: expense in an unallocated category. Decreases: delete, or adding an allocation (the spend moves into a line). Pinned by **BG** (overall 1,300.00 with unbudgeted 250.00 shown separately).

### 4.6 Savings

All savings figures use the goal's own currency; the overview total converts to the primary currency (`savings_repository_impl.dart:255-330`). The calculator is pure and integer-only (`savings_calculator.dart`).

**FF-20 Savings current amount** · `Σ contributions − Σ withdrawals` over live entries, in the goal's currency (`savings_dao.dart:166-190`). Each entry was converted into the goal's currency once, at the rate in effect when saved or edited, and both the entered and converted figures are stored. Increases: a contribution; edit up. Decreases: a withdrawal; deleting a contribution (refused if the balance would go below 0). Archive (goal): the goal leaves the default overview and its total; entries cannot be added until restored; edits are still allowed. Rate change: **no effect on the stored goal figure**; it only changes the overview's converted total. Traceable: yes (entry history) and audit rows exist (no screen, PF-05). Pinned by **SV** (CHK058-CHK067, incl. the USD contribution locked at 4,850.00).

**FF-21 Savings remaining** · `max(0, target − current)` (`GoalProgress.remainingMinorUnits`); 0 once achieved. Pinned by **SV**.

**FF-22 Savings progress (%)** · 0 if current ≤ 0; 100 if current ≥ target; else `current ÷ target × 100`. Display only. Pinned by **SV**.

**FF-23 Estimated months** · only when a monthly contribution above 0 is set and the goal is not achieved: `ceil(remaining ÷ monthly)`. Pinned by **SV** (333.34 case, divide-by-one case).

**FF-24 Estimated completion date** · today's calendar day plus the estimated months, with the day clamped to the month length (`addCalendarMonths`); `null` beyond 2,400,000 months. Pinned by **SV** (2027-07-05 example).

**FF-25 Required monthly contribution** · only when a target date is set: `ceil(remaining ÷ max(1, whole months between today and the target date))`. Pinned by **SV** (1,500.00 with a 3-month shortfall).

**FF-26 Shortfall (months late)** · only when both a monthly contribution and a target date exist: `estimatedMonths − max(1, monthsUntil(target))`, shown only if above 0 ("بهذا المعدل ستصل إليه متأخرًا عن تاريخك المستهدف بـ…"). Pinned by **SV**.

**FF-27 Total saved (overview)** · Σ of each non-archived goal's current amount converted at today's rate. A goal whose rate is missing is **left out** and an "incomplete" banner is shown (`savings_overview.dart`, `savings_overview_summary_card.dart:60-70`). An empty foreign-currency goal needs no rate (its current is 0). Rate change: re-valued. Observation NF-03: this is the one total that is shown partially rather than blocked. Pinned by **SV** (overview cases) and `test/widget/savings_overview_page_test.dart`.

### 4.7 Evidence summary

No figure in the product is computed by a model or by prose. All 27 records above are deterministic Domain or Data computations (section 10 covers the AI assistant, which can only narrate them).

## 5. Business Logic Assessment

**Execution status: every flow is `traced, not executed`.** No emulator or development backend was available. Expected and actual columns come from reading the code path and from existing tests. **T017 (emulator execution in AR/EN, light/dark) is still owed**; this table must not be read as an executed run.

**Flow list.** The Input line of spec.md abbreviates the list ("create person … sync after going online"). The 29 flows below are my reconstruction from FR-004 concepts and that span; flows 28 and 29 are the two sync flows, as tasks.md T017 expects. The owner should confirm the list.

| # | Flow | Expected | Actual (trace and tests) | Defect, backlog | Sev | Impact | Solution | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Create person | Saved, appears in list, duplicate name warned | As expected. `create_person_test.dart`, `find_possible_duplicate_person_test.dart`, `person_form_page_test.dart` | none | - | - | - | traced, not executed |
| 2 | Edit person | Name or phone changes; balances untouched | Only person fields written. `edit_person_test.dart` | none | - | - | - | traced, not executed |
| 3 | Archive person | Leaves active list; history and balance kept; still in overview totals with a marker | As expected (`home_page.dart:391`). `archive_restore_person_test.dart`, `archived_people_page_test.dart` | none (PF-12 refuted) | - | - | - | traced, not executed |
| 4 | Restore person | Returns to active list unchanged | As expected. `archive_restore_person_test.dart` | none | - | - | - | traced, not executed |
| 5 | Delete person | Allowed only with no history | `PersonHasTransactionsFailure` when any row exists, soft-deleted rows included (`people_dao.dart:131`); server also refuses (`person_has_transactions`). `delete_person_test.dart` | none | - | - | - | traced, not executed |
| 6 | Record "I gave" | Net rises by the amount; one row; retry never duplicates | As expected (idempotent insert, audit "created"). `add_transaction_test.dart`, `transactions_repository_impl_test.dart` | RF-05: no possible-duplicate warning (C4) | P3 | Same amount twice is accepted silently | C4 | traced, not executed |
| 7 | Record "I received" | Net falls by the amount | As expected. Same tests | RF-05 | P3 | as 6 | C4 | traced, not executed |
| 8 | Edit transaction | Amount, date, note editable; kind never changes | Direction and currency also editable for every kind, **including repayments** (`transaction_form_page.dart:195,234`; `transactions_repository_impl.dart:130-176` writes `direction` without checking `kind`). `edit_transaction_test.dart` has no repayment case | **A1 (PF-02)**; RF-01 currency edit (E3) | **P0**; P2 | A repayment flipped to the debt's direction makes the debt grow by twice the amount while the row still says "سداد" | A1 (repo guard + read-only direction), E3 | traced, not executed |
| 9 | Delete transaction | Row soft-deleted with audit; balance recalculated | As expected (`:182-212`). Deleting a debt leaves later repayments, which flip the balance with no warning. `delete_transaction_test.dart` | E6 (CHK032) | P2 | "Ahmed owes you 600.00 EGP" becomes "You owe Ahmed 400.00 EGP" with no explanation | E6 | traced, not executed |
| 10 | Partial repayment | Net falls by exactly the amount, direction inferred | `transactions_repository_impl_test.dart` AC1: 1,500.00 EGP to 1,000.00 EGP after 500.00 EGP | none | - | - | - | traced, not executed |
| 11 | Full repayment | Net 0, "تمت التسوية" | AC2: 1,500.00 EGP to 0.00 EGP | none | - | - | - | traced, not executed |
| 12 | Over-repayment | Warned before the balance reverses | AC3: owed 500.00 EGP + repayment 700.00 EGP gives "you owe 200.00 EGP" (intended, 001 FR-012). The form shows no outstanding amount or result (`repayment_form_page.dart` has no balance reference) | **A2 (PF-01)** | **P1** | A typo (7,000.00 EGP for 700.00 EGP) silently reverses who owes whom | A2/E2 | traced, not executed |
| 13 | View person balance and overview | Per-person net; two separate totals; blocked when a rate is missing | As expected. `get_person_balance_test.dart`, `get_overview_test.dart`, `home_page_test.dart`, `currency/cross_feature_blocking_consistency_test.dart` | PF-04 (rate policy), PF-03 (social money inside) | P1 | Totals move when a rate changes; wedding gifts look like debts | C2, C1 (Q2, Q1) | traced, not executed |
| 14 | Create occasion | Saved with type, date | As expected. `create_occasion_test.dart` | none | - | - | - | traced, not executed |
| 15 | Add counting contribution | Row linked to the occasion; person net changes | `counts_toward_balance` defaults to true except condolence (008 FR-018); the person's net moves. `add_participant_contribution_test.dart` | **PF-03** | **P1** (policy) | A gift received shows under "إجمالي المستحق عليك" with real loans | C1 (Q1) | traced, not executed |
| 16 | Add non-counting (condolence) contribution | Occasion totals change; person net does not | Excluded by the predicate in `balance_queries.dart`. `occasions_repository_impl_test.dart` | none | - | - | - | traced, not executed |
| 17 | Occasion totals and status | Received, given, net, status from occasion rows only | As expected (`occasions_repository_impl.dart:255-300`). `get_occasion_detail_test.dart` | PF-06: "تمت التسوية" reused for two meanings | P2 | Reads as "everyone is square" when it only means money in = money out | E1 | traced, not executed |
| 18 | Archive or delete occasion | Archive keeps rows; delete removes its contributions from all balances | As expected (`:149-157`, `_setArchived`). `archive_restore_occasion_test.dart`, `delete_occasion_test.dart` | none | - | - | - | traced, not executed |
| 19 | Add income | Raises income and net only | As expected; no person or savings effect (`isolation_from_transactions_test.dart`). `add_finance_entry_test.dart` | none | - | - | - | traced, not executed |
| 20 | Add expense | Raises expense, lowers net; counts toward the category budget | As expected. `add_finance_entry_test.dart`, `budgets_rates_and_live_test.dart` | none | - | - | - | traced, not executed |
| 21 | Edit, delete or restore an income or expense | Change is explainable later | Edit and soft delete work and restore exists, but no previous values are kept; currency is editable; type is also switchable on edit | **RF-02 (D2)**; RF-01 (E3) | P1 (constitution); P2 | An edited expense cannot be explained | D2, E3 | traced, not executed |
| 22 | Create budget and allocations | One budget per month, expense categories only, copy from a prior month | As expected. `create_budget_test.dart`, `add_budget_category_allocation_test.dart`, `copy_budget_to_month_test.dart` | none | - | - | - | traced, not executed |
| 23 | Budget actual, unbudgeted, status | Actual from expense entries only; exact thresholds; unbudgeted separate | As expected (`budgets_repository_impl.dart:395-410`, `budgetStatusFor`). `get_budget_for_month_test.dart`, `budget_month_live_update_test.dart` | PF-08 can move an expense into the wrong month across time zones | P2 | A budget month can show a different spend after sync from another time zone | B1 | traced, not executed |
| 24 | Create savings goal | Saved with target, optional monthly amount and date | As expected. `create_savings_goal_test.dart` | none | - | - | - | traced, not executed |
| 25 | Log, edit, delete a contribution or withdrawal | Balance changes; a withdrawal above the balance is rejected; edits audited | As expected (`savings_repository_impl.dart:378-530`). `log_contribution_withdrawal_test.dart`, `edit_delete_contribution_test.dart` | NF-02: rate used is save-time, not entry date | P3 | A back-dated foreign-currency entry uses today's rate | doc fix (no backlog) | traced, not executed |
| 26 | Savings projection and what-if | Deterministic dates, months and required monthly amount | As expected. `savings_calculator_test.dart`, `what_if_test.dart` | none | - | - | - | traced, not executed |
| 27 | Change an exchange rate or primary currency | History stays explainable; switching needs a rate while the old currency is in use | The switch rule holds (`set_primary_currency.dart:65-80`; `set_primary_currency_test.dart`). A rate change silently re-values every past people and finance figure | **PF-04** | **P1** (policy) | Last month's totals change without any edit | C2 (Q2), H4 | traced, not executed |
| 28 | Same record edited on two devices offline | A conflict is shown and the user chooses | True for transactions and income/expense (`sync_engine_conflict_test.dart`, `conflict_resolver_test.dart`, `cloud_sync_repository_conflict_test.dart`). **Not for savings contributions** (`lww`) | **A3 (PF-11)** | **P0** (rule) | One savings amount is silently overwritten | A3, S0 | traced, not executed (no dev project) |
| 29 | Sync after going online | Queued changes upload once; downloads apply; nothing applied twice | Outbox with server op ledger gives `already_applied` on retry (migration 023 lines 314-330); pull skips rows with pending local ops (`sync_applier.dart:118-135`). `sync_engine_push_test.dart`, `sync_engine_pull_test.dart`, `sync_engine_initial_upload_test.dart`. Dates are rebuilt from the instant (PF-08). An unknown `entity_type` fails the whole page (AN-C1) | **B1 (PF-08)**, **S0 (AN-C1)** | P2; P0 (latent) | A date can show one day earlier on a device in another time zone; a future type would stop download on installed apps | B1, S0 | traced, not executed (no dev project) |

## 6. Data Model Assessment

**Verdict: the current model is sound and can represent every concept in section 3.1. No restructuring is recommended.** Structural change is proposed only where a correctness or traceability problem was demonstrated (FR-008).

What was checked and held (research §3): integer minor units with per-row currency; idempotency keys with a unique index; soft-delete tombstones; append-only audits for people transactions and savings entries; per-record sync metadata (`sync_record_meta`, revisions) and a conflict log with both sides kept (`conflict_resolutions`); person hard-delete only when no row has ever existed (`people_dao.dart:131`); budget and goal deletion guards.

| FR-008 question | Answer | Evidence | Backlog |
| --- | --- | --- | --- |
| Rate at transaction time | **Absent for people and finance rows**; present for savings entries (entered and converted amounts are both stored). Needed only if Q2 selects historical valuation | `app_database.dart` `ExchangeRates` (no effective date); `savings_repository_impl.dart:418-430` | C2 (adds `rate_micros_at_entry`), H4 |
| Repayment-to-debt link | **Absent by design** (running net) | `MoneyTransaction` has no link column; spec Clarifications | H1 (later) |
| Reason for a change | Previous values are stored for people transactions and savings; **nothing at all for income and expense**; no free-text reason anywhere | `TransactionAuditEntries`, `SavingsContributionAudits` only (`app_database.dart` table list) | D2, C3 |
| Sync metadata | Present: revision, device id, op ledger, outbox, conflicts | `sync_tables.dart`; migration 021-023 | none |
| Calendar day of an event | Stored locally as local-midnight epoch milliseconds. On the wire, people transactions and finance entries carry `occurred_on` and `tz_offset_minutes`; **savings contributions carry only an instant** | `sync_mapper_registry.dart:118-125`; `savings_contribution_sync_mapper.dart:34,62` | B1, G3 |
| Immutability of `kind` | Enforced by the edit path (no `kind` write). **Direction of a repayment is not immutable** | `transactions_repository_impl.dart:130-176` | A1 |

Proposed model changes (data-model Part 2), each tied to a finding:

| Item | Change | Schema impact | Finding |
| --- | --- | --- | --- |
| A1 | Invariant: a repayment's direction is fixed after creation | none | PF-02 |
| A2, E6 | Derived values (repayment preview; count of later repayments) | none | PF-01, CHK032 |
| B1 | Read `occurred_on` first when pulling | none (wire unchanged) | PF-08 |
| A3, S0 | Migrations 025 and 026: version-gated conflict policy; `sync_pull_v2` | server functions only | AN-C1, AN-C2, PF-11 |
| D2 | New `finance_entry_audits` table and `finance_entry_audit` sync type | new local and server table | RF-02 |
| G3 | `occurred_on`, `tz_offset_minutes` for savings contributions | wire and server columns | PF-08 |
| C1, C2 | Derived `socialNet`; `rate_micros_at_entry` | none / one column | PF-03, PF-04 (**blocked on Q1, Q2**) |

Risks to record: the existing upgrade path has migration tests per feature (`test/core/database/*_migration_test.dart`), and T012 adds a financial snapshot that only starts protecting once schema 12 exists.

## 7. UX/UI Assessment

Method: I read the screens and cubits named below and the strings in `lib/core/l10n/app_ar.arb` and `app_en.arb`. Nothing here was observed on a device; every row is `code-reviewed, not observed on device`. The headline: the money screens show direction in words, block rather than guess when a rate is missing, and have loading, empty and error states. The issues are where a number can change without the user seeing why or being asked.

### 7.1 What works (evidence)

- Direction is carried by words and an icon, never by a minus sign or colour alone: the status sentences (`personDetailTheyOweYou`, `personDetailYouOweThem`, `personDetailSettled`), `BalanceStatusBadge` (`test/widget/balance_status_badge_test.dart` checks icon plus label).
- A missing exchange rate blocks the figure and names the currency, with an action to set it (`rateNeededTitle`, `rateNeededMessage`, `rateNeededAction`; `RateNeededBanner` in `person_detail_page.dart`).
- Empty states exist for people, a person's history, occasions, participants, income and expense, a month with no budget, savings and reports (`emptyPeopleTitle`, `historyEmptyTitle`, `occasionsEmptyTitle`, `occasionParticipantsEmptyTitle`, `financeEmptyTitle`, `budgetEmptyTitle`, `savingsOverviewEmptyTitle`, `reportsEmptyTitle`). Error states exist on the same screens (`homeOverviewLoadError`, `budgetLoadErrorTitle`, `savingsOverviewLoadErrorTitle`, `errorLoadTitle`, with a retry in `people_list_page.dart:174-186`).
- Destructive actions confirm and say the effect on balances (`deleteTransactionConfirmMessage`, `occasionDeleteConfirmMessage`, `occasionRemoveParticipantConfirmMessage`, `exchangeRateRemoveConfirm`).
- The savings and budget screens say when a total is partial or planned spending exceeds expected income (`savingsOverviewIncompleteTitle`, `budgetExceedsIncomeWarning`).

### 7.2 Issues

| ID | Issue | Evidence | Sev | Backlog | State |
| --- | --- | --- | --- | --- | --- |
| UX-01 | **Ambiguous direction.** "أعطيت / استلمت" (I gave / I received) never says why: loan, gift or payback. The same pair is used for a wedding gift and a loan | `directionGiven`, `directionReceived`; `transaction_form_page.dart:195` | P2 | E1 (wording), C1 (Q1) | Wording alone cannot fix it |
| UX-02 | **A repayment's direction can be edited.** The edit form shows a "سداد" chip and an enabled direction switch | `transaction_form_page.dart:195-199,213-221`; F-LOGIC-01 | P0 | A1, E4 | Fix in progress in the working tree (`repaymentDirectionLockedHint` exists; not in v1.0.1) |
| UX-03 | **No outstanding amount or preview on the repayment form;** an over-payment reverses the balance silently | `repayment_form_page.dart` on v1.0.1; F-LOGIC-02 | P1 | A2, E2 | Fix in progress (`repaymentOutstanding`, `repaymentFlipConfirmTitle`, `repaymentPreviewUnavailable` exist; not in v1.0.1) |
| UX-04 | **Deleting a debt that later repayments depend on gives no warning;** the balance flips to "you owe them" | `deleteTransactionConfirmMessage` says only "removed from history and balance"; CHK032 | P2 | E6 | Fix in progress (`deleteLaterRepaymentsWarning` exists) |
| UX-05 | **Changing the currency on edit asks nothing,** for a people transaction and for an income or expense: the digits stay, the currency changes | `transaction_form_page.dart:234`; `finance_entry_form_page.dart:193`; `finance_repository_impl.dart:94`; RF-01 | P2 | E3 | Open |
| UX-06 | **Income and expense can be switched to the other type on edit,** moving the net by 2 × the amount with no history | `finance_entry_form_page.dart:156-171`; `finance_repository_impl.dart:88-92`; RF-08, RF-02 | P2 (P1 while RF-02 is open) | D2 | Open |
| UX-07 | **One label, two meanings.** "تمت التسوية" is the person status and the occasion status; the occasion one only means money in = money out | `personDetailSettled`, `occasionSettlementSettled`, `filterSettled`; PF-06 | P2 | E1 | Open; owner gate T023 |
| UX-08 | **Accounting words on the consumer UI:** "إجمالي المستحق لك / عليك", "الصافي", "قيد مالي", "القيد", "مدخلات", "المحتسب" | rows marked change in 8.1; PF-07 | P2 | E1 | Open; owner gate T023 |
| UX-09 | **Wedding gifts appear in "total you owe"** with real loans | `balance_queries.dart`; PF-03 | P1 | C1 (Q1) | Held for the owner |
| UX-10 | **A rate change moves past totals with no notice.** The rate form saves without telling the user that history is revalued; savings goals do not move | `exchange_rate_form_page.dart` has no confirmation; PF-04 | P1 | C2 (Q2) | Held for the owner |
| UX-11 | **Change history is invisible.** The row shows "معدَّل / Edited" and nothing opens | `editedLabel`; PF-05 | P2 | C3 | Open |
| UX-12 | **Possible-duplicate warning is missing for a repeated amount.** Duplicate *people* are warned (`duplicateWarningTitle`); a repeated amount is not | RF-05 | P3 | C4 | Open |
| UX-13 | **No distinct "nothing matches" state on the people list.** When a search or a status filter matches nobody, the screen shows the true empty state ("Add a person to start…") with an add button. Finance and occasions have their own (`financeNoMatchTitle`, `occasionNoMatchTitle`) | `people_list_page.dart:188-195`; CHK132 | P3 | E7 (RF-09) | Fixed on the branch (T097) |
| UX-14 | **The export screen promises "a complete copy of your data"** but lists only people, transactions, income and expense, categories and settings: occasions, budgets, savings, rates and history are left out | `exportDescription` (en and ar); RF-03 | P2 | E8, D1 (RF-10) | Open. Until D1 ships the sentence should not say "complete" |
| UX-15 | **The delete-all warning omits savings goals and exchange rates,** which the wipe does remove | `deleteDataWarningMessage` against `data_wipe.dart` | P3 | E8 (RF-11) | Open; it errs on the safe side |
| UX-16 | **The savings overview shows a prominent total that leaves some goals out** (banner explains) while every other total is blocked | `savings_overview_summary_card.dart:60-70`; NF-03 | P3 | none | Disclosed |
| UX-17 | **The what-if screen is a snapshot** taken when it opens; it does not follow a remote edit while open | `what_if_cubit.dart` (one `GetGoalDetail`) | P3 | none | Open |

Steps for common tasks (code-reviewed): recording a repayment is two taps from the person page (`person_detail_page.dart:187-193` opens the form); recording "I gave / I received" is available from home quick actions (`homeQuickMoneyGiven`, `homeQuickMoneyReceived`). I found no step-count problem. Not checked on a device: touch targets (CHK151) and TalkBack sentences (CHK150), both `gap` in section 17.


## 8. Arabic/RTL Assessment

### 8.1 Terminology table

**Scope.** "Money-related" means every key that names, labels or explains a figure, a status, a direction, a conversion or an action on money in the ledger screens: people and balances, repayments, occasions, income and expense, budgets, savings, currency and rates, the sync conflict sheet and the export copy. Out of scope and listed at the end: education calculators (`finEdu*`), notification bodies, OCR, AI, seed category names and non-money form labels. All 125 individual `arbKey`s and the keys inside the family rows were checked to exist in both `app_ar.arb` and `app_en.arb`. Current values were read from the files, not recalled.

**Rules applied to each proposal:** plain everyday Egyptian Arabic where the current word is accounting jargon or ambiguous; natural English; no accounting terms on consumer screens. A row is **keep** when the current wording is already plain. Formal terms (receivable, payable, settlement) remain in the model and in sections 3, 18 and 19 only.

**Judgement calls against plan E1:** (a) the repayment *action* stays "تسجيل سداد" and only the form title says part-payment is allowed; (b) "اديت / خدت" is adopted for the direction pair, but the table says plainly that this alone does not solve PF-07, because the purpose (loan, gift or payback) is still not asked; (c) "الصافي / Net" becomes "الباقي / Left over", which needs the negative case spelled out in words (CHK040); (d) occasion total labels are changed to match the new direction verbs.

**Not applied yet.** This table proposes; it changes no file. Rows marked *change* take effect only after the owner's decision (T023, plan E1 gate). The test and checklist texts that quote current strings (CHK008, CHK014, CHK035, CHK118) must follow any accepted change. New US6 keys are present in the ARB files in the working tree (`repaymentDirectionLockedHint`, `repaymentOutstanding`, `repaymentFlipConfirmTitle`, `repaymentFlipConfirmMessage`, `repaymentPreviewUnavailable`, `deleteLaterRepaymentsWarning`); they are included above as "new (US6)".

| arbKey | current ar | current en | proposed ar | proposed en | why | audience | change / keep | Decision (owner, T023) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `filterTheyOweYou` | لك عندهم | They owe you | (same) | (same) | Already everyday; matches the proposed totals | consumer | keep |  |
| `filterYouOweThem` | عليك لهم | You owe them | (same) | (same) | Already everyday | consumer | keep |  |
| `filterSettled` | تمت التسوية | Settled | خالصين | All square | Person status only. Separates it from the occasion label (PF-06) | consumer | change |  |
| `personDetailTheyOweYou` | {name} مديون لك بمبلغ {amount} | {name} owes you {amount} | (same) | (same) | "مديون لك" is natural; the sentence states the direction in words (CHK118) | consumer | keep |  |
| `personDetailYouOweThem` | أنت مدين لـ {name} بمبلغ {amount} | You owe {name} {amount} | أنت مديون لـ {name} بمبلغ {amount} | (same) | "مدين" here but "مديون" in the sentence above: one register, the everyday one. CHK008/CHK014/CHK118 quote the current text and must follow | consumer | change |  |
| `personDetailSettled` | تمت التسوية | Settled | خالصين | All square | PF-06: stops sharing words with the occasion status; says the balance is zero | consumer | change |  |
| `overviewTotalOwedToYou` | إجمالي المستحق لك | Total owed to you | ليك عند الناس | Others owe you | "المستحق" is accounting wording (receivable); everyday phrase from plan E1 | consumer | change |  |
| `overviewTotalYouOwe` | إجمالي المستحق عليك | Total you owe | عليك للناس | You owe others | "المستحق عليك" is accounting wording (payable) | consumer | change |  |
| `overviewSectionTheyOweYou` | لك عندهم | They owe you | (same) | (same) | Everyday; sits well beside the proposed totals | consumer | keep |  |
| `overviewSectionYouOweThem` | عليك لهم | You owe them | (same) | (same) | Everyday | consumer | keep |  |
| `overviewAllSettledTitle` | كل شيء تمت تسويته | Everything is settled | كله خالص | All square with everyone | Follows the "خالصين" change; drops the passive "تمت تسويته" | consumer | change |  |
| `overviewAllSettledMessage` | ليس لديك أي أرصدة مستحقة مع أي شخص الآن. | You have no outstanding balances with anyone right now. | مفيش فلوس مستحقة بينك وبين حد دلوقتي. | Nobody owes you and you owe nobody right now. | Plain sentence, no "balances" jargon | consumer | change |  |
| `overviewTitle` | نظرة عامة | Overview | (same) | (same) | Neutral | consumer | keep |  |
| `directionGiven` | أعطيت | I gave | اديت | I gave | Everyday verb pair "اديت / خدت" (plan E1). The purpose (loan, gift, payback) is still not said: wording cannot fix PF-07 alone, the form needs to ask (links to Q1) | consumer | change |  |
| `directionReceived` | استلمت | I received | خدت | I got | Pair with "اديت". English "I got" is how people say it | consumer | change |  |
| `homeQuickMoneyReceived` | مبلغ استلمته | Money received | فلوس خدتها | Money I got | Aligns with the direction labels | consumer | change |  |
| `homeQuickMoneyGiven` | مبلغ أعطيته | Money given | فلوس اديتها | Money I gave | Aligns with the direction labels | consumer | change |  |
| `emptyPeopleMessage` | أضف شخصًا لتبدأ في تتبع الأموال التي تعطيها أو تستلمها معه. | Add a person to start tracking money you give or receive with them. | (same) | (same) | Clear. Register question is settled in 8.3, not per key | consumer | keep |  |
| `historyEmptyMessage` | سجّل معاملة مع {name} لتبدأ في تتبع رصيدك. | Record a transaction with {name} to start tracking your balance. | (same) | (same) | Clear | consumer | keep |  |
| `homeEmptyMessage` | تابع من عليه مال لك، وما عليك، وأين تذهب أموالك كل شهر — وكل ذلك على جهازك. | Keep track of who owes you, what you owe, and where your money goes each month — all on your device. | تابع مين ليك عنده فلوس ومين ليه عندك، وفلوسك بتروح فين كل شهر — وكله على جهازك. | (same) | "من عليه مال لك" reads as translated English; everyday rewording | consumer | change |  |
| `repaymentLabel` | سداد | Repayment | (same) | (same) | "سداد" is the common word for paying back | consumer | keep |  |
| `repaymentFormTitle` | تسجيل سداد | Record repayment | سداد جزء أو كل المبلغ | Pay back part or all | Tells the user that part-payment is allowed (PF-01 context) | consumer | change |  |
| `recordRepaymentAction` | تسجيل سداد | Record repayment | (same) | Record a payback | Keep the short Arabic action; English "repayment" is acceptable but "payback" matches the form | consumer | change |  |
| `repaymentOutstanding` | المتبقي: {amount} | Remaining: {amount} | (same) | (same) | New (US6); clear | consumer | keep |  |
| `repaymentFlipConfirmTitle` | المبلغ أكتر من المتبقي | This is more than what's left | (same) | (same) | New (US6); clear | consumer | keep |  |
| `repaymentFlipConfirmMessage` | مبلغ السداد ده أكتر من المتبقي مع {name}، فالرصيد هيتعكس بمقدار {amount}. تحب تحفظه برضه؟ | This repayment is more than the outstanding balance with {name}, so the balance will reverse by {amount}. S… | (same) | (same) | New (US6); states who ends up owing whom | consumer | keep |  |
| `repaymentPreviewUnavailable` | مش متاح لحد ما تحدد سعر الصرف | Unavailable until an exchange rate is set | (same) | (same) | New (US6) | consumer | keep |  |
| `repaymentDirectionLockedHint` | اتجاه السداد بيتحدد من الرصيد. لتغييره احذف السداد وسجّله تاني | A repayment's direction is set by the balance. To change it, delete the repayment and record it again. | (same) | (same) | New (US6); matches A1 | consumer | keep |  |
| `deleteLaterRepaymentsWarning` | {count, plural, =1{فيه سداد واحد اتسجل بعد المعاملة دي} =2{فيه سدادين اتسجلوا بعد المعاملة دي} few{فيه {cou… | {count, plural, =1{1 later payback was recorded after this transaction} other{{count} later paybacks were r… | (same) | (same) | New (US6); matches E6 | consumer | keep |  |
| `deleteTransactionConfirmMessage` | ستُحذف من سجل هذا الشخص ومن رصيده. لا يمكن التراجع عن ذلك. | It will be removed from this person's history and balance. This can't be undone. | (same) | (same) | Clear; "من رصيده" is understood | consumer | keep |  |
| `transactionFormCreateTitle` | تسجيل معاملة | Record transaction | (same) | (same) | "معاملة" is acceptable for a record with a person | consumer | keep |  |
| `recordTransactionAction` | تسجيل معاملة | Record transaction | (same) | (same) | As above | consumer | keep |  |
| `editedLabel` | معدَّل | Edited | (same) | (same) | Clear marker | consumer | keep |  |
| `occasionSettlementSettled` | تمت التسوية | Settled | الداخل = الخارج | Money in = money out | PF-06: this is not a settlement between people, it is money in versus money out for the event | consumer | change |  |
| `occasionSettlementMoreReceived` | استلمت {amount} أكثر مما دفعت | {amount} more received than given | خدت {amount} أكتر مما اديت | You got {amount} more than you gave | Align with the direction verbs; the English drops the passive "more received than given" | consumer | change |  |
| `occasionSettlementMoreGiven` | دفعت {amount} أكثر مما استلمت | {amount} more given than received | اديت {amount} أكتر مما خدت | You gave {amount} more than you got | As above | consumer | change |  |
| `occasionDetailTotalReceived` | إجمالي المستلم | Total received | اللي خدته | Received | "إجمالي المستلم" is ledger wording; keeps the same meaning (Σ of received rows) | consumer | change |  |
| `occasionDetailTotalGiven` | إجمالي المدفوع | Total given | اللي اديته | Given | As above | consumer | change |  |
| `occasionDetailNet` | الصافي | Net | الفرق | Difference | "الصافي" is accounting wording; the figure is received minus given | consumer | change |  |
| `occasionParticipantDirectionReceived` | استلمت منه | I received from them | خدت منه | (same) | Align with directionReceived | consumer | change |  |
| `occasionParticipantDirectionGiven` | أعطيته | I gave them | اديته | (same) | Align with directionGiven | consumer | change |  |
| `occasionParticipantDirectionLabel` | الاتجاه | Direction | (same) | (same) | "الاتجاه" is acceptable; the options say what happened | consumer | keep |  |
| `occasionParticipantCountsTowardBalanceLabel` | تُحتسب ضمن رصيده | Counts toward their balance | (same) | (same) | Revisit together with owner decision Q1 (social money vs loans) | consumer | keep |  |
| `occasionParticipantCountsTowardBalanceHint` | نقوط العزاء لا تُرد عادةً، لذا لا تُحتسب ضمن الرصيد افتراضيًا. فعّل هذا الخيار لاحتسابها مثل أي تبادل آخر. | Condolence money isn't expected to be paid back, so it stays out of the balance by default. Turn this on to… | (same) | (same) | Uses "نقوط" (everyday). Revisit with Q1 | consumer | keep |  |
| `occasionContributionBadge` | مناسبة | Occasion | (same) | (same) | Short tag | consumer | keep |  |
| `occasionRemoveParticipantConfirmMessage` | ستختفي أيضًا من سجل هذا الشخص ومن رصيده. لا يمكن التراجع عن هذا الإجراء. | It will also disappear from this person's history and balance. This can't be undone. | (same) | (same) | States the effect on the person's balance | consumer | keep |  |
| `occasionDeleteConfirmMessage` | {count, plural, =0{لا توجد مساهمات مسجلة في هذه المناسبة. لا يمكن التراجع عن هذا الإجراء.} =1{سيتم أيضًا حذ… | {count, plural, =0{This occasion has no contributions recorded yet. This can't be undone.} =1{This also rem… | (same) | (same) | States the effect (CHK073) | consumer | keep |  |
| `occasionArchiveConfirmMessage` | ستنتقل إلى المناسبات المؤرشفة. تبقى مساهماتها في سجل كل شخص وفي رصيده، ويمكنك استعادتها في أي وقت. | It moves to archived occasions. Its contributions stay in everyone's history and balances, and you can rest… | (same) | (same) | States that balances stay | consumer | keep |  |
| `occasionParticipantsEmptyMessage` | أضف أول شخص أعطى أو استلم نقوطًا في هذه المناسبة. | Add the first person who gave or received money at this occasion. | (same) | (same) | Everyday ("نقوطًا") | consumer | keep |  |
| `occasionsEmptyMessage` | أفراح وخطوبة وأعياد ميلاد وسبوع وعزاء — أنشئ مناسبة لتسجّل النقوط اللي أخدتها أو دفعتها فيها. | Weddings, engagements, birthdays, sebou celebrations, condolences — create an occasion to record who gave o… | (same) | (same) | Already colloquial and clear | consumer | keep |  |
| `financeTypeExpense` | مصروف | Expense | (same) | (same) | Everyday | consumer | keep |  |
| `financeTypeIncome` | دخل | Income | (same) | (same) | Everyday | consumer | keep |  |
| `financeSummaryTotalIncome` | إجمالي الدخل | Total income | (same) | (same) | Clear | consumer | keep |  |
| `financeSummaryTotalExpense` | إجمالي المصروفات | Total expenses | (same) | (same) | Clear | consumer | keep |  |
| `financeSummaryNet` | الصافي | Net | الباقي | Left over | "الصافي/Net" is accounting wording. When negative the screen must say it in words (CHK040: "صرفت أكتر من دخلك بـ 500.00 EGP") | consumer | change |  |
| `homeFinanceNet` | الصافي | Net | الباقي | Left over | Same term as above | consumer | change |  |
| `reportsNet` | الصافي | Net | الباقي | Left over | Same term as above | consumer | change |  |
| `financeEmptyTitle` | لا توجد مدخلات بعد | No entries yet | لسه مفيش دخل أو مصروفات | No income or expenses yet | "مدخلات" (inputs) is technical | consumer | change |  |
| `financeNoMatchTitle` | لا توجد مدخلات مطابقة | No matching entries | لا توجد حركات مطابقة | No matching entries | Keep consistent with the empty title wording | consumer | keep |  |
| `financeEntryFormEditTitle` | تعديل السجل | Edit entry | (same) | (same) | Clear | consumer | keep |  |
| `financeBreakdownShare` | {percent}٪ من الإجمالي | {percent}% of total | (same) | (same) | Clear | consumer | keep |  |
| `syncKindFinanceEntry` | قيد مالي | Finance entry | دخل أو مصروف | Income or expense | "قيد مالي" (financial entry) is accounting wording, shown in the conflict list | consumer | change |  |
| `syncKindTransaction` | معاملة | Transaction | (same) | (same) | Acceptable | consumer | keep |  |
| `syncKindSavingsContribution` | مبلغ ادخار | Savings entry | (same) | (same) | "مبلغ ادخار": see the savings family row | consumer | keep |  |
| `budgetPlannedLabel` | المخطط | Planned | (same) | (same) | Plain | consumer | keep |  |
| `budgetActualLabel` | المصروف | Spent | (same) | (same) | "المصروف / Spent" is plainer than "actual" | consumer | keep |  |
| `budgetRemainingLabel` | المتبقي | Remaining | (same) | (same) | Plain | consumer | keep |  |
| `budgetStatusOnTrack` | ضمن الخطة | On track | (same) | (same) | Plain; the three states are already worded for everyone | consumer | keep |  |
| `budgetStatusNearFull` | يقترب من الحد | Near limit | (same) | (same) | Plain | consumer | keep |  |
| `budgetStatusOverBudget` | تجاوز الميزانية | Over budget | (same) | (same) | Plain | consumer | keep |  |
| `budgetUnbudgetedTitle` | مصروفات خارج الميزانية | Unbudgeted spending | (same) | Spending outside the budget | English "Unbudgeted" is jargon; Arabic is already plain | consumer | change |  |
| `budgetUnbudgetedMessage` | ما أُنفق هذا الشهر في فئات غير مدرجة في ميزانيتك. | Spent this month in categories that aren't in your budget. | (same) | (same) | Plain | consumer | keep |  |
| `budgetUnbudgetedTotalLabel` | إجمالي خارج الميزانية | Total unbudgeted | (same) | Total outside the budget | Follows the title | consumer | change |  |
| `budgetPercentNotApplicable` | لا يوجد مبلغ مخطط | Nothing planned | (same) | (same) | Plain | consumer | keep |  |
| `budgetOverByAmount` | تجاوز بمقدار {amount} | {amount} over | (same) | (same) | Plain | consumer | keep |  |
| `budgetRemainingAmount` | متبقٍ {amount} | {amount} left | (same) | (same) | Plain | consumer | keep |  |
| `budgetExceedsIncomeWarning` | المصروفات المخططة تتجاوز الدخل المتوقع بمقدار {amount} | Planned spending exceeds expected income by {amount} | (same) | (same) | Plain | consumer | keep |  |
| `budgetExpectedIncomeLabel` | الدخل المتوقع (اختياري) | Expected income (optional) | (same) | (same) | Plain | consumer | keep |  |
| `budgetTrendOverPlan` | تجاوز المخطط | Over plan | (same) | (same) | Plain | consumer | keep |  |
| `budgetAllocationsHeader` | المصروفات المخططة حسب الفئة | Planned spending by category | (same) | (same) | Plain | consumer | keep |  |
| `budgetOverallTitle` | الإجمالي | Overall | (same) | (same) | Plain | consumer | keep |  |
| `savingsOverviewTotalLabel` | إجمالي المدخرات | Total saved | (same) | (same) | See the "ادخار / توفير" family row below | consumer | keep |  |
| `savingsProgressSavedLabel` | المدخر | Saved | (same) | (same) | Plain | consumer | keep |  |
| `savingsProgressRemainingLabel` | المتبقي | Remaining | (same) | (same) | Plain | consumer | keep |  |
| `savingsProgressTargetLabel` | المستهدف | Target | (same) | (same) | Plain | consumer | keep |  |
| `savingsProgressPercent` | تم ادخار {percent}٪ | {percent}% saved | (same) | (same) | Plain | consumer | keep |  |
| `savingsEstimateByContribution` | بمعدل {amount} شهريًا ستصل إليه خلال {duration}، في حدود {date}. | At {amount} a month, you'll reach it in {duration}, around {date}. | (same) | (same) | Plain; shows duration and date | consumer | keep |  |
| `savingsEstimateRequired` | لتصل إليه بحلول {date}، ادّخر {amount} شهريًا. | To reach it by {date}, save {amount} a month. | (same) | (same) | Plain | consumer | keep |  |
| `savingsEstimateShortfall` | بهذا المعدل ستصل إليه متأخرًا عن تاريخك المستهدف بـ{duration}. | At this rate, you'll reach this {duration} after your target date. | (same) | (same) | Plain | consumer | keep |  |
| `savingsGoalAchievedBadge` | تحقّق الهدف! | Goal reached! | (same) | (same) | Plain | consumer | keep |  |
| `savingsEntryContribution` | إيداع | Contribution | إضافة | Added | "إيداع" (bank deposit) does not match the action "إضافة مبلغ"; a goal is not an account | consumer | change |  |
| `savingsEntryWithdrawal` | سحب | Withdrawal | (same) | (same) | Plain | consumer | keep |  |
| `savingsEntryConvertedAmount` | المحتسب: {amount} | Counted as {amount} | بعد التحويل: {amount} | After conversion: {amount} | "المحتسب / Counted as" is unclear; says what happened | consumer | change |  |
| `savingsContributionConversionHint` | سيُحوَّل هذا المبلغ إلى {currency} بالسعر الحالي عند الحفظ. | This will be converted to {currency} at the current rate when you save. | (same) | (same) | Says the rate is applied at save time (matches NF-02) | consumer | keep |  |
| `savingsLogContributionAction` | إضافة مبلغ | Add money | (same) | (same) | Plain | consumer | keep |  |
| `savingsLogWithdrawalAction` | سحب | Withdraw | (same) | (same) | Plain | consumer | keep |  |
| `savingsOverviewIncompleteTitle` | الإجمالي غير مكتمل | Total incomplete | (same) | (same) | Plain; honest about the partial total (NF-03) | consumer | keep |  |
| `savingsOverviewIncompleteMessage` | لا يشمل الأهداف بعملة {currencies}. أضف سعر صرف {currencies} لاحتسابها. | It leaves out goals in {currencies}. Add an exchange rate for {currencies} to count them. | (same) | (same) | Plain | consumer | keep |  |
| `savingsOverviewNotInTotal` | غير محتسب في الإجمالي — يلزم سعر {currency} | Not in the total — needs a {currency} rate | (same) | (same) | Plain | consumer | keep |  |
| `savingsGoalStartingLabel` | المدخر حتى الآن (اختياري) | Already saved (optional) | (same) | (same) | Plain | consumer | keep |  |
| `savingsWithdrawalExceedsBalanceError` | لا يمكنك سحب أكثر مما ادخرته لهذا الهدف. | You can't withdraw more than this goal has saved. | (same) | (same) | Plain | consumer | keep |  |
| `savingsWhatIfPreviewNotice` | هذه معاينة فقط. يبقى هدفك كما هو ما لم تطبّقها. | This is only a preview. Your goal stays as it is unless you apply it. | (same) | (same) | Plain | consumer | keep |  |
| `savingsEntryDeleteConfirmTitle` | حذف هذا القيد؟ | Delete this entry? | حذف هذا المبلغ؟ | (same) | "القيد" (ledger entry) is accounting wording | consumer | change |  |
| `savingsEntryDeleteConfirmMessage` | سيُعاد حساب أرقام الهدف، ويُحتفظ بسجل لقيم هذا القيد. | The goal's figures will be recalculated. A record of the entry's values is kept. | سيُعاد حساب أرقام الهدف، ويُحتفظ بسجل لقيم هذا المبلغ. | (same) | Same: replace "القيد" | consumer | change |  |
| `savingsContributionFormEditTitle` | تعديل القيد | Edit entry | تعديل المبلغ | Edit amount | Same: replace "القيد"; English "entry" is acceptable but align | consumer | change |  |
| `savingsEntryActionsTooltip` | خيارات القيد | Entry options | خيارات المبلغ | (same) | Same: replace "القيد" | consumer | change |  |
| `rateNeededTitle` | الإجمالي غير متاح — يلزم سعر صرف | Total unavailable — exchange rate needed | (same) | (same) | Plain; says the records are safe | consumer | keep |  |
| `rateNeededMessage` | أضف سعر صرف لـ {currencies} لعرض هذا الإجمالي. سجلاتك آمنة ولم تتغير. | Add an exchange rate for {currencies} to see this total. Your records are safe and unchanged. | (same) | (same) | Plain | consumer | keep |  |
| `rateNeededAction` | تعيين سعر الصرف | Set exchange rate | (same) | (same) | Plain | consumer | keep |  |
| `budgetRateNeededBadge` | يلزم سعر صرف | Rate needed | (same) | (same) | Plain | consumer | keep |  |
| `primaryCurrencyLabel` | العملة الأساسية | Primary currency | (same) | (same) | Plain | consumer | keep |  |
| `primaryCurrencyDescription` | تُعرض كل الإجماليات والأرصدة بهذه العملة. | All totals and balances are shown in this currency. | (same) | (same) | Plain | consumer | keep |  |
| `primaryCurrencySwitchRateMessage` | لديك سجلات بعملة {previous}. أدخل قيمة واحد {previous} بعملة {next} حتى تظل إجمالياتك صحيحة. | You have records in {previous}. Enter how many {next} one {previous} is worth so your totals stay correct. | (same) | (same) | Plain | consumer | keep |  |
| `exchangeRatesTitle` | أسعار الصرف | Exchange rates | (same) | (same) | Plain | consumer | keep |  |
| `exchangeRateValueLabel` | قيمة 1 {from} بعملة {to} | Value of 1 {from} in {to} | (same) | (same) | Explicit about the direction of the rate | consumer | keep |  |
| `exchangeRateRemoveConfirm` | ستصبح الإجماليات التي تحتاج هذا السعر غير متاحة حتى تضيفه مرة أخرى. لن تتغير سجلاتك. | Totals that need this rate will be unavailable until you add it again. Your records won't change. | (same) | (same) | States the effect | consumer | keep |  |
| `exchangeRatesManualDisclosure` | أنت من يُدخل الأسعار ولا تُجلب تلقائيًا أبدًا. حدّثها متى شئت. | Rates are entered by you and never fetched automatically. Update them whenever you like. | (same) | (same) | Honest about manual rates; revisit with Q2 | consumer | keep |  |
| `syncConflictBadgeLabel` | تعارض | Conflict | (same) | (same) | Short; the sheet explains | consumer | keep |  |
| `syncConflictSheetTitle` | تم التعديل على جهازين | Changed on two devices | (same) | (same) | Says what happened in words | consumer | keep |  |
| `syncConflictSheetMessage` | تم تعديل هذا السجل على هذا الجهاز وعلى جهاز آخر. اختر النسخة التي تريد الاحتفاظ بها. تُحفظ النسخة الأخرى في… | This record was edited on this device and on another one. Choose the version to keep. The other version is … | (same) | (same) | Says the other version is kept | consumer | keep |  |
| `syncConflictKeepMine` | الاحتفاظ بنسختي | Keep mine | (same) | (same) | Plain | consumer | keep |  |
| `syncConflictKeepTheirs` | الاحتفاظ بالنسخة الأخرى | Keep theirs | (same) | (same) | Plain | consumer | keep |  |
| `errorSyncConflict` | تم تغيير هذا السجل على جهاز آخر. اختر النسخة التي تريد الاحتفاظ بها. | This record was changed on another device. Choose which version to keep. | (same) | (same) | Plain | consumer | keep |  |
| `exportDescription` | أنشئ ملف CSV واحدًا يحتوي على نسخة كاملة من بياناتك: الأشخاص والمعاملات وقيود الدخل والمصروفات والفئات والإ… | Create one CSV file containing a complete copy of your data: people, transactions, income and expense entri… | أنشئ ملف CSV واحدًا يحتوي على نسخة كاملة من بياناتك: الأشخاص والمعاملات وقيود الدخل والمصروفات والفئات والمناسبات والميزانيات وأهداف التوفير ومساهماتها وأسعار الصرف وسجل التعديلات والإعدادات. يُنشأ الملف على جهازك وأنت من يختار أين يرسله. | Create one CSV file containing a complete copy of your data: people, transactions, income and expense entries, categories, occasions, budgets, savings goals and contributions, exchange rates, change history, and settings. The file is created on your device and you choose where to send it. | Lists every `ExportSection` D1 now writes (people, transactions, income and expense, categories, settings, occasions and their contributions, budgets and allocations, savings goals and contributions, exchange rates, and the three change histories), so "complete" is true (RF-03, RF-10). Pending owner sign-off (T023) | consumer | change |  |
| `deleteDataWarningMessage` | سيؤدي هذا إلى حذف جميع الأشخاص والمعاملات والمناسبات والمسوحات وقيود الدخل والمصروفات والفئات والميزانيات والإعدادات من هذا الجهاز نهائيًا — ومن نسختك الاحتياطية السحابية أيضًا إن كنت تستخدمها. لا يمكن التراجع عن ذلك. يُنصح بتصدير بياناتك أولًا. | This will permanently delete all of your people, transactions, occasions, scans, income and expense entries, categories, budgets, and settings from this device — and your cloud backup, if you use one. This cannot be undone. Consider exporting your data first. | سيؤدي هذا إلى حذف جميع الأشخاص والمعاملات والمناسبات والمسوحات وقيود الدخل والمصروفات والفئات والميزانيات وأهداف التوفير وأسعار الصرف وسجل التعديلات ومحادثات المساعد والإعدادات من هذا الجهاز نهائيًا — ومن نسختك الاحتياطية السحابية أيضًا إن كنت تستخدمها. لا يمكن التراجع عن ذلك. يُنصح بتصدير بياناتك أولًا. | This will permanently delete all of your people, transactions, occasions, scans, income and expense entries, categories, budgets, savings goals, exchange rates, change history, assistant conversations, and settings from this device — and your cloud backup, if you use one. This cannot be undone. Consider exporting your data first. | `data_wipe.dart` also deletes savings goals and contributions, exchange rates, the three change histories, assistant conversations and notification settings, which the current text omits (RF-11, UX-15). Pending owner sign-off (T023) | consumer | change |  |
| `amountInvalidError` | أدخل مبلغًا أكبر من صفر، بحد أقصى 12 رقمًا | Enter an amount greater than zero, up to 12 digits | (same) | (same) | Plain; quoted by CHK136 | consumer | keep |  |
| *family:* ادخار → توفير (30 keys: `notificationSavingsAchievedBody`, `notificationSettingsEntrySubtitle`, `notificationSettingsMasterTitle`, `notificationSettingsMasterOffDescription`, `notificationSavingsCheckInsTitle`, `notificationPermissionRationaleMessage`, `notificationSavingsGoalNoLongerExists`, `syncKindSavingsGoal`, `syncKindSavingsContribution`, `syncKindSavingsContributionHistory`, `homeUpcomingPlaceholder`, `homeSavingsTitle`, `savingsGoalNotFoundError`, `savingsWithdrawalExceedsBalanceError`, `savingsGoalHasHistoryError`, `savingsGoalFormCreateTitle`, `savingsGoalStartingLabel`, `savingsGoalStartingHint`, `savingsProgressSavedLabel`, `savingsProgressPercent`, `savingsEstimateRequired`, `savingsGoalAchievedMessage`, `savingsOverviewTitle`, `savingsOverviewEmptyTitle`, `savingsOverviewTotalLabel`, `savingsWhatIfModeMonthly`, `savingsWhatIfCurrentRemaining`, `savingsWhatIfResultByMonthly`, `savingsWhatIfResultByMonthlyUndated`, `savingsWhatIfResultByDate`) | e.g. «أهداف الادخار», «إجمالي المدخرات», «ادّخر {amount} شهريًا» | e.g. "Savings goals" (English unchanged) | replace «ادخار / ادّخر / مدخر» with «توفير / وفّر / متوفّر» (e.g. «أهداف التوفير») | (same) | «ادخار» is the formal word; «توفير» is the everyday one (cf. the bank product «حساب توفير»). Broad change: **needs native-speaker confirmation** before use | consumer | change (pending native review) |  |
| *family:* «قيد / قيود» in savings (`savingsGoalArchivedNotice`, `savingsEntryActionsTooltip`, `savingsEntryDeleteConfirmTitle`, `savingsEntryDeleteConfirmMessage`, `savingsContributionFormEditTitle`) | «القيد», «القيود» | "entry" | «المبلغ», «المبالغ» (rows above for four of them; `savingsGoalArchivedNotice`: «تصحيح القيود السابقة» → «تصحيح المبالغ السابقة») | (same) | Ledger wording (see the savings rows) | consumer | change |  |
| *out of scope:* `finEdu*` (education calculators), `notification*` bodies, `ocr*`, `ai*`, `financeCategory*` seed names, form-field labels such as `nameLabel` | — | — | — | — | Do not name or label a ledger figure, or they inherit the decision of the term they reuse (notification and what-if sentences reuse «ادخار» and follow the savings family row) | consumer | keep |  |

**Counts:** 126 individual rows (37 *change*, 89 *keep*) plus two family rows (change) and one out-of-scope row. The `Decision` column is empty on purpose: it is for the owner to approve or amend each row (T023, native Egyptian Arabic review).

### 8.2 Voice (an owner question inside E1)

The ARB files already mix two registers. Most strings are formal Modern Standard Arabic ("أضف شخصًا لتبدأ في تتبع الأموال..."). The occasion strings and the new US6 strings are colloquial Egyptian ("النقوط اللي أخدتها", "اتجاه السداد بيتحدد من الرصيد", "تحب تحفظه برضه؟"). The proposals above use the everyday words only where the current word is jargon or ambiguous. **Recommendation:** pick one voice for money words (everyday words inside otherwise plain Arabic) and apply it to the whole app in one pass, instead of key by key.

### 8.3 RTL and Arabic findings

Everything below is `code-reviewed, not observed on device`. The repository has **no image golden files**; its "RTL/theme" tests assert layout and text, not pixels (so CHK161 has nothing to compare against yet).

| ID | Finding | Evidence | Sev | Backlog |
| --- | --- | --- | --- | --- |
| RTL-01 | **No bidirectional isolation of amounts or Latin names inside Arabic sentences.** Placeholders are inserted as plain text; only two places isolate (U+2066/U+2069): `sync_settings_page.dart:252` and `lockout_countdown_banner.dart:25`. The Unicode bidi algorithm usually keeps "1,500.00 EGP" in order, but punctuation placed after an amount or a Latin name at a sentence end can land on the wrong side. This is a risk, not a seen defect | `personDetailYouOweThem` ("... لـ {name} بمبلغ {amount}"), `budgetTrendMonthSummary`, `deleteLaterRepaymentsWarning` (ends with `{result}`); CHK122, CHK123 | P3 | none (verify on device first) |
| RTL-02 | **Amounts are always Western digits with the ISO code after the number,** also in Arabic (by design: "identical under RTL and LTR"). Input accepts Arabic digits (CHK116) but the display never uses them. A product decision, not a defect | `currency_formatter.dart:43-60` | P3 (observation) | none |
| RTL-03 | **Arabic thousands separator `٬` is rejected on input** (RF-07), which matters because the user is typing Arabic digits | `numeral_parser.dart`; `amount_input_catalogue_test.dart` (skipped) | P3 | E5 |
| RTL-04 | **Direction icons are fixed shapes** (`north_east` for given, `south_west` for received) and are not mirrored. They are always paired with words (segment labels), so meaning does not depend on them | `finance_snapshot_card.dart:72,80`, `contribution_list_tile.dart:83`, `transaction_form_page.dart:195` | none | none |
| RTL-05 | **Chevrons and the month navigator** use `Icons.chevron_left/right` for previous/next. Flutter's chevron icons mirror under RTL, and the "previous" button is first in the Row, so previous sits at the right in Arabic. Correct reading order; no test asserts it | `month_navigator.dart:53-77` | none | none |
| RTL-06 | **Charts handle RTL explicitly:** the monthly trend swaps the bar order (`monthly_trend_chart.dart:252-262`); the budget trend reverses months and moves the amount axis (`budget_trend_chart.dart:55-64,117,188-189`). Tests `budget_trend_chart_test.dart` and `reports_page_test.dart` render in Arabic | listed | none | none |
| RTL-07 | **Language-neutral fields force LTR** where needed: currency chip, e-mail and API-key fields | `currency_indicator_chip.dart:25`, `email_link_sheet.dart:96,119`, `ai_settings_page.dart:398-432` | none | none |
| RTL-08 | **Arabic plurals are written for 1, 2, few, many and other** (`occasionDeleteConfirmMessage`, `savingsOverviewGoalCount`, `savingsDurationMonths`, `deleteLaterRepaymentsWarning`). No test asserts them | `app_ar.arb` | P3 | none (CHK118 is `gap`) |
| RTL-09 | **The most-read money screens are not exercised in Arabic by widget tests:** `person_detail_page_test.dart`, `people_list_page_test.dart`, `balance_status_badge_test.dart`, `transaction_list_tile_test.dart`, `archived_people_page_test.dart` and `transaction_form_navigation_test.dart` contain no Arabic or RTL case. Covered: home (`home_page_test.dart`), occasions, savings, app lock, OCR, budgets, reports, finance entry form, and person and transaction rows at 200% text in Arabic (`hardening_layout_test.dart`) | grep of `test/widget` | P2 | F4 (fixed on the branch, T092: Arabic cases added) |
| RTL-10 | **Wording that reads as translated English in Arabic:** "من عليه مال لك" (`homeEmptyMessage`), "مدخلات" (`financeEmptyTitle`), "المحتسب" (`savingsEntryConvertedAmount`); covered by rows in 8.1 | table 8.1 | P3 | E1 |


## 9. QA Assessment

### 9.1 Stale-state trace (FR-007)

Method: for each list and total screen I read the cubit under `lib/features/*/presentation/cubit` and followed its use case to the repository `watch*` method. A "re-read" is a `watchEither(tables, query)`: it re-runs the query after every burst of writes (50 ms debounce) to any listed table and suppresses equal results (`lib/core/database/watch_tables.dart:63-79`). All are `code-traced`.

| Screen / figure | Cubit | Stream and tables it re-reads on | Stale-state outcome |
| --- | --- | --- | --- |
| Home: overview totals and groups | `dashboard_cubit.dart:95` | `WatchOverview` → `watchOverview()`: moneyTransactions, people, exchangeRates, primaryCurrencySettings (`transactions_repository_impl.dart:379-406`) | Live |
| Home: this-month finance | `dashboard_cubit.dart:103` | `WatchFinanceSummary` = totals stream (`entriesChanged`: financeEntries) combined with the conversion-context stream (`watch_finance_summary.dart`) | Live, including rate changes |
| Home: latest entry, upcoming goals | `dashboard_cubit.dart:114,128` | `WatchFinanceHistory(limit: 1)`, `WatchUpcomingSavingsGoals` | Live |
| People list (active) with balances | `person_list_cubit.dart:54,80` | `WatchActivePeople` then `WatchPersonBalances` (`_balanceTables`) | Live. Archive and restore, new rows and rate changes propagate (`people_repository_watch_test.dart`, `transactions_repository_watch_test.dart`) |
| Archived people | `archived_people_cubit.dart:36` | `WatchArchivedPeople` | Live |
| Person detail: balance, history, name | `person_detail_cubit.dart:75-88` | `WatchPerson`, `WatchPersonBalance` (`_balanceTables`), `WatchPersonHistory` (moneyTransactions), `WatchPrimaryCurrency`, occasion names | Live (`person_detail_remote_update_test.dart`) |
| Occasions list (active) | `occasions_list_cubit.dart:52,62` | `watchOccasionsList`: occasions table only | Live. The list tile shows no money total, so no other table is needed (no `summary` or `total` reference in `occasion_list_tile.dart`) |
| Archived occasions | `archived_occasions_cubit.dart:34` | `watchOccasionsList(includeArchived: true)` | Live |
| Occasion detail and totals | `occasion_detail_cubit.dart:66` | `watchOccasionDetail`: occasions, occasionAttachments, moneyTransactions, people, exchangeRates, primaryCurrencySettings (`occasions_repository_impl.dart:363-375`) | Live (`occasions_remote_update_test.dart`) |
| Finance history, summary, category chips | `finance_history_cubit.dart:114-127` | `watchHistory` (`entriesChanged`), `WatchFinanceSummary`, `WatchCategories` | Live |
| Reports (trend, breakdown) | `reports_cubit.dart:79,82,117` | `watchHasAnyEntry`, `WatchTrend`, `WatchBreakdown` (`categoryTotalsChanged`: financeEntries, financeCategories) | Live (`reports_remote_update_test.dart`) |
| Categories | `category_management_cubit.dart:51` | `WatchCategories(includeArchived: true)` | Live |
| Budget month | `budget_month_cubit.dart:58` | `watchBudgetForMonth`: budgets, budgetCategoryAllocations, financeEntries, financeCategories, exchangeRates, primaryCurrencySettings (`budgets_repository_impl.dart:551-560`) | Live (`budget_month_live_update_test.dart`) |
| Budget trend | `budget_trend_cubit.dart:60,96` | `WatchCategories`, `WatchBudgetTrend` | Live |
| Savings overview, archived goals | `savings_overview_cubit.dart:32`, `archived_goals_cubit.dart:31` | `watchSavingsOverview`: savingsGoals, savingsContributions, exchangeRates, primaryCurrencySettings (`savings_repository_impl.dart:337-342,362`) | Live |
| Savings goal detail | `goal_detail_cubit.dart:38` | `watchGoalDetail` (same tables); history and balance read in one transaction so they cannot disagree (`:535-560`) | Live |
| Exchange rates, primary currency | `exchange_rate_list_cubit.dart:39`, `primary_currency_cubit.dart:36` | `WatchPrimaryCurrency`, `WatchExchangeRates` | Live |
| Sync conflicts | `sync_conflicts_cubit.dart:27` | `WatchConflicts` | Live |

**One-shot reads that are not display totals** (checked, not defects): `budget_form_cubit.dart` (`GetBudgetForMonth`, to prefill a form), `goal_form_cubit.dart` and `contribution_form_cubit.dart` (prefill and validation), `what_if_cubit.dart` (`GetGoalDetail`: the what-if result is a snapshot of the goal at open time; it would not follow a remote edit while open: P3 observation, no backlog). The AI tools read once per call by design.

**Outcome (matches research §3).** Every list, detail and total cubit uses a single subscription to a Drift watch stream; I found no cubit that caches a total, no second state holder for the same screen, and no list that needs a manual refresh. Cubit state is immutable (`PersonListState` is Equatable with final fields). Duplicate entries are prevented at the data layer (section 3.1). No stale-state defect was found.

### 9.2 Test baseline

3,699 passing, 0 failing at `c86e2df` (quickstart.md). **No existing test covers any A or B defect** (plan Summary): `edit_transaction_test.dart` has no repayment case; no test applies a pull page with an unknown `entity_type` (`sync_remote_data_source_test.dart`, `sync_engine_pull_test.dart` contain no such case); no test exercises two devices in different time zones; no fake-remote test of a savings conflict exists (`sync_engine_conflict_test.dart` and `cloud_sync_repository_conflict_test.dart` never mention `savings_contribution`). The calculation catalogue (T003-T012) closes the calculation gap.

## 10. Security & Privacy Assessment

| Area | Finding | Evidence | Status |
| --- | --- | --- | --- |
| Local data at rest | Plain SQLite through Drift. No encryption package is declared (`pubspec.yaml` has `drift` and `sqlite3_flutter_libs` only). Protection relies on the device lock and OS sandbox. The AI key is not in the database; it is in secure storage | `pubspec.yaml:48-49,100`; `data_wipe.dart` comment | Accepted by design; record for the owner |
| App lock | Optional PIN: PBKDF2, 120,000 iterations, 16-byte salt, 32-byte key, minimum 4 digits; lockout policy; biometric optional | `pin_hasher.dart` (`Pbkdf2PinHasher`), `lockout_policy.dart` | Sound for a local PIN |
| Screenshots | Always-on foreground screenshot and screen-recording protection, independent of app lock | `main.dart:38`, `screenshot_protection_service.dart` | Sound |
| Android backup | `AndroidManifest.xml` sets no `allowBackup`, `fullBackupContent` or `dataExtractionRules`, and there is no `res/xml` folder. The platform default may let auto-backup copy the unencrypted database | `android/app/src/main/AndroidManifest.xml:30-35` | **Not verified on a device.** P3 observation NF-06; confirm on the release APK before relying on it |
| What syncs and where | Everything except `localOnlyTables` goes to the user's Supabase project, per-user rows (`owner_id`, row-level security). Local-only: app settings, onboarding, notification prefs and history, occasion photos, OCR scans and candidates, AI conversations and settings, and the sync tables themselves | `lib/core/sync/sync_entity_type.dart` (`localOnlyTables`); `table_classification_guard_test.dart` | As designed; PRODUCT.md still says "nothing leaves the device" (PF-10, G1) |
| Sync logging | Release builds log warnings and errors only, with named fields rather than row data | `sync_logger.dart`; `sync_log_scrub_test.dart` | Sound |
| Error text | Raw `$e` inside `CacheFailure` never reaches the UI; messages are localized | research §3; `failure_message.dart` | Sound |
| Export contents | Covers people, transactions, finance entries, categories and settings. **Omits occasions, budgets and allocations, savings goals and contributions, exchange rates and all change history.** The file is written as `.part` and renamed on completion | `export_user_data.dart:32-46,66-106` | **RF-02-class gap: RF-03 (P2), D1** |
| Data wipe | One transaction deletes every user table, then files, secure storage and (optionally) the cloud copy, then reseeds default categories. A guard test iterates `allTables` | `data_wipe.dart`; `data_wipe_test.dart:36,43,346` | Sound |
| AI assistant | Needs a stored credential and a consent timestamp before it is enabled. Tool results (figures plus the names a tool needs, such as person, category, goal) are sent to the provider the user chose | `ai_assistant_settings.dart`; `secure_credential_store_impl.dart` | Disclosed by consent; I did not inspect every tool's result fields |

### 10.1 AI grounding check (FR-013, constitution)

- **Every figure comes from a deterministic tool.** The assistant's tools in `lib/features/ai_assistant/domain/tools/` are thin wrappers over the same use cases the screens use: `get_person_balance_tool.dart` (`GetPersonBalance`), `get_owed_overview_tool.dart` (`GetOverview`), `get_budget_status_tool.dart` (`GetBudgetForMonth`), `get_occasion_totals_tool.dart` (`GetOccasionDetail`), `get_savings_goal_status_tool.dart` (`GetGoalDetail`, `GetSavingsOverview`), `get_savings_projection_tool.dart` (`GetSavingsOverview`), plus category spend, top category and period comparison. Each result names its `sourceUseCase`, and `GroundingRefsCodec` stores which tool and use case backed an answer. Tests: `budget_savings_occasion_tools_test.dart`, `finance_tools_test.dart`, `people_tools_test.dart`.
- **The assistant is read-only** and the system prompt forbids creating or editing records and forbids personalised investment advice (`system_prompt_builder.dart` rules 6-7). Unmatched or ambiguous names return `foundData: false`, never a guess (`get_person_balance_tool.dart` doc).
- **RF-06 (P3, to measure): prose arithmetic is instructed against, not enforced.** The prompt says "never add, subtract, multiply, divide, average, or otherwise compute a figure yourself" (rule 2) and "never add amounts in different currencies together" (rule 3). Nothing checks the model's reply against the tool values: `GroundingRef` records provenance only. A model that disobeys, for example summing two balances in a sentence, would show an ungrounded number with a grounded-looking source. Plan H6 proposes a post-check. No financial figure in the app depends on the assistant, so this does not affect any record.

## 11. Offline/Sync Assessment

### 11.1 Per-entity policy

Server policy is the `v_policy` in `sync_push` as last replaced by migration 023 (`supabase/migrations/20260930090000_023_savings_goals_sync.sql:255-306`); migration 024 only changes privileges. `lww` = the last push to arrive is applied and nothing is shown. `financial` = a push whose base revision is stale returns `conflict`; a push with no base revision is `already_applied` if its values equal the server row, otherwise `conflict`. The app stores both versions and asks the user. (For `lww` types, a *delete* with a stale base revision returns `superseded` and is not applied.) `append` = a second write of an existing id is ignored (`already_applied`).

| # | Wire type (`SyncEntityType`) | Rank | Server table | Server policy | Deletable by op | Client conflict screen (v1.0.1) | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `person` | 0 | people | lww | yes | no | Acceptable: name and notes; a person with history cannot be deleted (`person_has_transactions`) |
| 2 | `money_transaction` | 1 | money_transactions | **financial** | no (soft delete) | **yes** | Correct for money |
| 3 | `transaction_audit` | 2 | transaction_audit_entries | append | no | no | Correct (history is never rewritten) |
| 4 | `finance_category` | 0 | finance_categories | lww | yes (archives instead if entries exist) | no | Acceptable: labels |
| 5 | `finance_entry` | 1 | finance_entries | **financial** | no | **yes** | Correct for money |
| 6 | `exchange_rate` | 3 | exchange_rates | lww | yes | no | Acceptable for a setting (R4); valuation policy is Q2 |
| 7 | `primary_currency` | 3 | primary_currency | lww | no | no | Acceptable for a setting (R4) |
| 8 | `conflict_resolution` | 2 | conflict_resolutions | append | no | no | Correct (the discarded side is kept) |
| 9 | `occasion` | 0 | occasions | lww | no (soft) | no | Acceptable: the event record; its money rows are `money_transaction` (financial) |
| 10 | `budget` | 0 | budgets | lww | no (soft) | no | Acceptable: a plan, not a recorded fact |
| 11 | `budget_allocation` | 1 | budget_category_allocations | lww | yes (hard delete) | no | Acceptable: a planned amount |
| 12 | `savings_goal` | 0 | savings_goals | lww | no (soft) | no | Acceptable with a note: the target amount can be overwritten silently |
| 13 | `savings_contribution` | 1 | savings_contributions | **lww** | no (soft) | no | **Gap (A3, P0 by the sync rule): money, but last-write-wins** |
| 14 | `savings_contribution_audit` | 2 | savings_contribution_audits | append | no | no | Correct |

14 of 14 types listed (`lib/core/sync/sync_entity_type.dart:6-26`). Migration 023's own comment gives the reason for row 13: "the app's conflict screen only knows money transactions and finance entries" (`:13-16`); the screen's `ConflictEntityType` has exactly those two members (`sync_conflict_item.dart:6-8`).

**What is lost in the A3 case.** The audit does not save the overwritten value. Each device's audit row holds the value *before its own edit*, written at edit time (`savings_repository_impl.dart:_audit`). Two devices that both start at 500.00 EGP and edit to 600.00 and 700.00 each write an audit row with 500.00; the losing 600.00 appears in no audit and no conflict log. research.md PF-11 was updated on 2026-10-05 to state this.

### 11.2 Other duplicate, loss and partial-sync checks (FR-010)

- **Applied twice:** no. The server keeps an op ledger; a retried `op_id` returns `already_applied` with the stored revision (migration 023 `:314-330`); inserts for `financial` types also match on `idempotency_key`; `append` ignores a second write (`:385-387`).
- **Lost:** only via `lww` types, i.e. row 13 for money. Conflicts for rows 2 and 5 keep the discarded side (`ConflictResolver.keepMine/keepTheirs` writes `conflict_resolutions`; `conflict_resolver_test.dart`).
- **Pull over local work:** a pulled row is skipped when the record has pending local operations, and refreshes the conflict when one is blocked (`sync_applier.dart:118-135`).
- **Partial sync:** the download cursor only advances after a page is applied; a page with an unknown type throws and the cursor stays (AN-C1).

### 11.3 Older-app risks (analysis C1/C2)

| ID | Risk | Root cause | Trigger | Status |
| --- | --- | --- | --- | --- |
| **AN-C1** | Any record type the installed app does not know stops the whole download page for that account | `_parseChange` throws `FormatException('pull: unknown entity_type')` (`lib/core/sync/remote/sync_remote_data_source.dart:104-106`) | The server returns a new type, such as D2's `finance_entry_audit`, to a v1.0.1 install | **Confirmed, latent.** The current server returns no unknown types today. S0 (client skips unknown types; `sync_pull_v2` serves new types, deployed before app 1.1.0) removes it |
| **AN-C2** | A conflict on a type the conflict screen cannot show is parked invisibly, and that edit never syncs | `_block` writes a `sync_conflicts` row and sets the outbox entry to `blocked_conflict` (`lib/core/sync/local/sync_local_store.dart:250,274-330`), but `_toItem` drops types that `ConflictEntityType.tryFromWire` does not know (`cloud_sync_repository_impl.dart:106-108`) | The server starts returning `conflict` for `savings_contribution` to a v1.0.1 app | **Confirmed, latent.** Today the server answers `applied` for that type. It becomes live if A3's policy change ships without the version gate. The gate (migration 025, deployed before app 1.1.0) keeps v1.0.1 on `lww` |

### 11.4 Rollout order (binding, quickstart.md)

1. `supabase db push` migration **025**: savings conflicts apply only to app versions at or above 1.1.0 (older versions stay `lww`), and `sync_pull` filters `conflict_resolutions` rows for v1.0.1 (the review found a v1.0.1 pull stall from savings `conflict_resolution` rows otherwise). The user runs this.
2. `supabase db push` migration **026**: `sync_pull` keeps today's types; the new `sync_pull_v2` returns all, including `finance_entry_audit`.
3. Release app **1.1.0** (one release: S0, A3 client, B1 with the one-time repair, D2 history calling `sync_pull_v2`). The B1 repair needs schema v12, which ships with D2, so the earlier two-release plan (R1, then R2) collapsed into one.

Version reporting: release builds did not pass `DAFTARY_APP_VERSION` until this branch (fixed in `release-android.yml`), without which the server could not tell 1.1.0 from v1.0.1.

Reordering any step either breaks installed v1.0.1 apps (AN-C1, AN-C2) or makes the server reject a type it does not yet know.

**Verdict.** Transactions and income/expense sync is safe: no silent loss, no double-apply, and every conflict is kept. Savings contributions are the single money gap. Both older-app risks are latent and are closed by deploying 025 and 026 before the 1.1.0 app reaches users. Not executed: no development project was available (flows 28 and 29).

## 12. Reporting Assessment

Written for a reader with no code. "Reconcile" means: rebuild a figure by adding up the records behind it and reach the same number the app shows. Test names refer to checklist items (CHK) and the calculation catalogue; **the device run of the checklist (T020) is still pending**, so a "met" below means the logic is proved by an automated test, not yet observed on a phone.

### 12.1 Can each figure be traced to its records?

| Figure | Records you can see | Filters you can apply | Verdict |
| --- | --- | --- | --- |
| A person's balance | The person's full history (every row, with direction, kind, amount, currency, date, note, "Edited" marker) | None on the person's history: no date range, no currency filter, no running balance column | Partly met (D3) |
| Total owed to you / Total you owe | The grouped list of people that adds up to each total, archived people marked | Status (owes you, you owe, settled), name search | Met |
| An occasion's totals | The participant rows by direction | By the occasion itself | Met |
| Income, expense and net for a period | The history list | Type, category and date range | Met |
| A category's share | The breakdown by category | Then filter the history by category and dates by hand | Partly met |
| A budget line's actual and "unbudgeted" | Not a direct view; the user filters the income and expense history by category and month | Category and month | Partly met (no tap-through; CHK084 shows they agree) |
| A savings goal's amount | The goal's entry history (entered amount, converted amount, edited marker) | By the goal | Met |
| The total saved across goals | Each goal line; goals whose rate is missing are left out and flagged | None | Partly met (a disclosed partial total) |
| Any foreign-currency figure | The row keeps its own amount and currency | **No currency filter anywhere** | Partly met (missing) |

Filters available today: date range (income and expense, occasions), person (by opening the person), occasion, category, type, status. Not available: currency, and any filter on a person's own history.

### 12.2 Settlement, change history and export

- **Settlement history.** There is no separate settlement list. A repayment appears in the person's history labelled "سداد". There is no statement with a running balance (D3). *Partly met.*
- **Change history.** Earlier values are recorded for people transactions and savings entries and are synced, but no screen shows them (C3). Income and expense edits record nothing (D2). A deleted row stays stored; income and expense can be undone for a few seconds, and there is no "deleted items" view. *Partly met for people and savings; missing for income and expense.*
- **Export.** One CSV with people, transactions, income and expense, categories and settings, written on the device. It leaves out occasions, budgets, savings, rates and all change history, and it does not show the rate used for any conversion (RF-03, D1). The screen's own text calls it "complete" (RF-10, E8). *Partly met.*

### 12.3 Walk-through: reconcile one person (balance, FF-01)

Worked example from the catalogue (CHK029, CHK015, CHK081). Ahmed has: gave 1,000.00 EGP (a loan); then received 400.00 EGP, 250.00 EGP and 350.00 EGP as three repayments.

1. List Ahmed's history: four rows. Add "I gave" rows: 1,000.00 EGP. Add "I received" rows: 400.00 + 250.00 + 350.00 = 1,000.00 EGP.
2. Gave minus received = 0.00 EGP, and the app shows "تمت التسوية" / "Settled" (the proposed wording is «خالصين» / "All square").
3. Intermediate checks the tests assert: 600.00 EGP after the first repayment, 350.00 EGP after the second.
4. Rule to apply: rows marked "does not count toward the balance" (condolence money) are left out; deleted rows are left out; a foreign-currency row is converted at today's rate.

Evidence: the person-balance catalogue test pins CHK011 to CHK017 and CHK029 to CHK032, including a 50-row person (CHK015) that must match the sum "to 0.01 EGP" and the three-repayments-of-333.33 case that must show "owes you 0.01 EGP", never "Settled". CHK081 (do this for three people, one with occasion rows) is only partly automated; the multi-person run is a device step still pending (T020). Where this does *not* reconcile by eye: a person with a foreign-currency row when the rate has changed since the row was entered, because the app converts at today's rate and does not record the rate used (C2).

### 12.4 Walk-through: reconcile one occasion (FF-06 to FF-09)

Worked example (CHK068, CHK083). A wedding: Ahmed gave you 500.00 EGP, Mona gave you 300.00 EGP, and you gave Karim 200.00 EGP.

1. List the participant rows: three rows.
2. Money received = 500.00 + 300.00 = 800.00 EGP. Money given = 200.00 EGP.
3. Difference = 800.00 − 200.00 = 600.00 EGP, shown as «استلمت 600.00 أكثر مما دفعت» / "600.00 more received than given", with 3 participants.
4. Cross-check with each person: Ahmed's own page shows the same 500.00 EGP row once (CHK069); editing it to 450.00 EGP updates both screens and the wedding received total to 750.00 EGP.
5. Two traps to know: a condolence contribution appears in the occasion total but not in the person's balance (CHK071); and today the wedding gift also counts inside Ahmed's loan balance (CHK070, "you owe Ahmed 500.00 EGP"), which is the open decision Q1.

Evidence: the occasion catalogue test (CHK068 to CHK073, CHK083). Device run pending.

### 12.5 Walk-through: reconcile one budget month (FF-14 to FF-19)

Worked example (CHK057, CHK084, CHK039). October budget, Food planned 2,000.00 EGP and Transport planned 500.00 EGP (the checklist fixes only Food at 2,000.00; the Transport plan is illustrative). Expenses in October: Food 1,000.00, Transport 300.00, and Gifts 250.00 (no budget line).

1. Filter the income and expense history to expenses, category Food, 1 to 31 October: 1,000.00 EGP. The Food line must say 1,000.00 EGP spent, 50%, 1,000.00 EGP remaining, "ضمن الخطة" / "On track" (CHK047, CHK084).
2. Same for Transport: 300.00 EGP.
3. The overall card counts the budgeted lines only: 1,000.00 + 300.00 = 1,300.00 EGP (CHK057).
4. "Unbudgeted spending" shows Gifts 250.00 EGP on its own.
5. Tie-out to the month: 1,300.00 + 250.00 = 1,550.00 EGP, which is the month's total expense in the finance summary (the same expense records, nothing else). Income and loans never enter this figure (CHK038, CHK041, CHK042).
6. Month boundaries: an expense dated 31 October belongs to October, one dated 1 November to November (CHK054).

Where it can fail to tie: a foreign-currency expense after a rate change (converted at today's rate), or an expense moved to another month by the date shift on another time zone (B1). Evidence: the budget catalogue test (CHK047 to CHK057, CHK084) and the finance-summary catalogue test. Device run pending.

### 12.6 Reporting verdict

A user can rebuild every total from records the app shows, except three: a person's balance cannot be shown as a statement with a running balance (D3), a budget line has no direct drill-down, and a foreign-currency figure cannot be tied to the rate that produced it (C2). The export is not yet enough to reconcile everything outside the app (D1).


## 13. Missing Features

Only what a consumer money app of this scope needs; nothing here turns Daftary into an accounting system. Classified per FR-005.

| Missing | Why it matters (trust or correctness) | Class | Backlog |
| --- | --- | --- | --- |
| A visible change history | A changed balance cannot be explained (PF-05) | Needed now | C3 |
| History for income and expense edits | Constitution: every financial mutation traceable (RF-02) | Needed now | D2 |
| A decision on type switch on edit | The net can move by twice an amount with no trace (RF-08) | Needed now | E9 (Q4) |
| Separate social money | Gifts look like debts (PF-03) | Needed now | C1 (Q1) |
| One exchange-rate policy | Past totals move silently (PF-04) | Needed now | C2 (Q2) |
| A complete export | Reconciliation outside the app (RF-03) | Needed now | D1 |
| A per-person statement with a running balance | The minimum an accountant asks for | Soon | D3 |
| A currency filter and a date filter on a person's history | Tracing foreign-currency and period figures | Soon | D3 |
| A possible-duplicate warning | Accidental double entries (RF-05) | Soon | C4 |
| Savings conflict screen | Silent overwrite (PF-11) | Needed now | A3 |
| Link a repayment to a debt; ageing | "Which debt is still open?" (PF-09) | Optional later | H1 |
| Forgive a debt (write-off) | Replaces a fake repayment | Optional later | H2 |
| Opening balance | Starting with an existing debt; a workaround exists | Optional later | H3 |
| Exchange-rate history | Only if Q2 chooses full history | Optional later | H4 |
| A printable statement | Hand-off to an accountant | Optional later | H5 |
| Refund, transfer, double-entry ledger, chart of accounts, trial balance | No trust or correctness problem in this product | Not needed | none |


## 14. Incorrect Features

Every seed and finding with its verified status. Severity follows the spec tie-break (a wrong figure in normal use is P0; an unusual but possible sequence P1; a correct but misleading figure P2). "Source" shows where the status was verified; entries marked "this audit" are my own code reading, not research.md.

| ID | Type | Status | Severity | Summary | Backlog |
| --- | --- | --- | --- | --- | --- |
| PF-01 | Missing requirement | Partially confirmed | P1 | The repayment button is hidden when settled (`person_detail_page.dart:187`), but an over-repayment flips the balance with no outstanding amount or preview | A2, E2 |
| PF-02 | Bug | **Confirmed** | **P0** | Repayment direction is editable after creation and flips the debt | A1, E4, G2 |
| PF-03 | Missing requirement (policy) | Confirmed (by design) | P1 | Occasion gifts are in the loan balance (Q1) | C1 |
| PF-04 | Missing requirement (policy) | Confirmed, plus inconsistency | P1 | Today's rate everywhere except savings entries (Q2) | C2, H4 |
| PF-05 | Missing requirement | Confirmed | P2 | Audit history is stored, synced and never shown | C3 |
| PF-06 | Improvement (wording) | Confirmed | P2 | "تمت التسوية" means two things | E1 |
| PF-07 | Improvement (wording) | Confirmed | P2 | Formal wording and no purpose on أعطيت / استلمت | E1 |
| PF-08 | Bug | Partially confirmed | P2 | Date can shift a day across time zones on pull (`money_transaction_sync_mapper.dart:57`, `finance_entry_sync_mapper.dart:48`); savings send only an instant. Judgement flag: it can move spend into the wrong budget month after a time-zone change, which the tie-break could treat as P1 | B1, G3 |
| PF-09 | Optional future feature | Confirmed (by design) | P3 | A repayment is not linked to a debt | H1 |
| PF-10 | Improvement (docs) | Confirmed | P2 | PRODUCT.md says no backend, sync or account (`PRODUCT.md:29,75`) | G1 |
| PF-11 | Bug | Confirmed gap | **P0** (sync rule) | `savings_contribution` is last-write-wins | A3, S0 |
| PF-12 | Bug (refuted) | **Refuted** | - | Archived people carry a visible marker in the overview (`home_page.dart:391`) | none |
| RF-01 | Improvement | Confirmed; **wider than research states** | P2 | Currency changeable on edit for people transactions (`transaction_form_page.dart:234`) **and** income/expense (`finance_entry_form_page.dart:193`, `finance_repository_impl.dart:94`): research E3 left the finance form "to verify"; verified | E3 |
| RF-02 | Missing requirement | Confirmed | **P1** (spec Clarifications 'Change history'; research.md listed P2) | No history for income and expense edits; P1 per spec Clarifications and the constitution's Financial Domain Override (`constitution.md:383-389`) | D2 |
| RF-03 | Missing requirement | Confirmed | P2 | Export omits occasions, budgets, savings, rates and history | D1 |
| RF-04 | Bug | Confirmed | P3 | Blocked-currency fallback defaults to "given" (`_repaymentDirection`) | B2 |
| RF-05 | Improvement | Confirmed | P3 | No possible-duplicate warning | C4 |
| RF-06 | Improvement (risk) | Confirmed (prompt-only guard) | P3 | AI prose arithmetic is instructed against, not checked (section 10.1) | H6 |
| RF-07 | Bug | Confirmed | P3 | Arabic thousands separator `٬` rejected | E5 |
| RF-08 | Improvement | Confirmed (verified in this audit) | P2 (P1 while RF-02 is open) | Income/expense type is switchable on edit (a category of the other type): editing a 1,000.00 EGP expense into income moves net by 2,000.00 EGP with no history. Evidence: `finance_entry_form_page.dart:156-171`, `finance_entry_form_cubit.dart:59`, `finance_repository_impl.dart:88-92` | D2; owner may lock type like `kind` |
| RF-09 | Improvement | Confirmed (verified in this audit, was UX-13) | P3 | The people list shows the "add a person" empty state when a search or filter matches nobody (`people_list_page.dart:188-195`) | E7 |
| RF-10 | Bug (copy) | Confirmed (was UX-14) | P2 | The export screen promises "a complete copy of your data" but omits occasions, budgets, savings, rates and history (`exportDescription`) | E8, D1 |
| RF-11 | Bug (copy) | Confirmed (was UX-15) | P3 | The delete-all warning omits savings goals and exchange rates, which the wipe removes (`deleteDataWarningMessage`, `data_wipe.dart`) | E8 |
| AN-C1 | Bug (latent) | Confirmed | P0 (latent) | Unknown entity type fails the whole download page | S0 |
| AN-C2 | Bug (latent) | Confirmed | P0 (latent) | A conflict on a type the screen cannot show is invisible to v1.0.1 | S0, A3 |
| CHK032 | Improvement | Confirmed by trace | P2 | Deleting a debt leaves later repayments that flip the balance, with no warning | E6 |

Seeds and findings count: PF-01..PF-12 (12), RF-01..RF-11 (11), AN-C1, AN-C2 (2), plus E6 = 26 entries.

### 14.1 Additional observations from this audit (not in research.md)

| ID | Observation | Evidence | Severity | Backlog |
| --- | --- | --- | --- | --- |
| NF-02 | **Correction to PF-04's wording.** Savings entries convert at the rate in effect when saved or edited, not at the contribution date | `savings_repository_impl.dart:403,456-457,583-600` | P3 (documentation) | none; research.md corrected; fix the 011 spec wording |
| NF-03 | The savings overview total leaves out goals whose rate is missing and shows an incomplete banner, while every other total is blocked entirely. Disclosed, but a different rule | `savings_overview.dart:55-72`, `savings_overview_summary_card.dart:60-70` | P3 | none; owner may align it |
| NF-04 | "Settled count" includes people with no transactions and archived people | `transactions_repository_impl.dart:285,325` | P3 | none |
| NF-05 | Rounding granularity differs: person balances convert each currency's net once; finance totals convert each currency sum; occasion totals and budget category totals convert per-row or per-sum. With foreign currency the same money can differ by a minor unit between screens | `person_balance_calculator.dart`; `occasions_repository_impl.dart:260-267`; `get_finance_summary.dart` | P3 | none; relevant when C2 is designed |
| NF-06 | Android backup attributes are not set; the unencrypted database may be included in platform backup | `AndroidManifest.xml:30-35` | P3, unverified on a device | none; verify first |
| NF-07 | Editing a transaction reads its data only from in-memory route arguments; opening the edit route by link alone shows "not found" | `lib/core/routing/app_router.dart:144-148`, `transaction_edit_page.dart:37-46` | P3 | G4 |

**New findings during implementation (found and fixed on the branch; none is in research.md yet).**

| Finding | Fixed by |
| --- | --- |
| Release builds never passed `DAFTARY_APP_VERSION`, so the server could not tell app versions apart (the version gate in migration 025 depends on it) | `release-android.yml` |
| `conflict_resolutions` rejected savings entity types, on the client and in the server CHECK constraint | Client and migration fix |
| A v1.0.1 app stalled on pull when savings `conflict_resolution` rows reached it | Migration 025 filters them out of `sync_pull` |
| The repayment preview and the saved balance could differ by 0.01 with a foreign currency | `BalanceProjection` (shared rounding) |
| Deleting a finance entry twice could write two audit rows | Guard in the delete path |
| A v10 install could be left stuck after a failed mid-upgrade | Migration guards |

## 15. Recommended Improvements

In the order they should ship (this follows the waves in plan.md; nothing here changes the architecture).

1. **Safety net first (Wave 0):** the calculation catalogue and the upgrade snapshot (F2, on the branch); update PRODUCT.md and the 001 spec (G1, G2).
2. **Stop wrong balances (Wave 1):** lock the repayment direction (A1, on the branch), fix the blocked-currency fallback (B2, on the branch), make older apps survive new sync data (S0), and stop dates shifting across time zones (B1, with its one-time repair).
3. **Stop silent overwrites (Wave 2):** show savings conflicts (A3): deploy migration 025 first, then release app 1.1.0.
4. **Prevent entry mistakes (Wave 3):** repayment preview and confirmation (A2, on the branch), delete warning (E6, on the branch), currency-change confirmation (E3), Arabic thousands separator (E5), duplicate warning (C4), a "nothing matches" state on the people list (E7), accurate export and delete-all wording (E8), and the wording changes once the owner approves (E1).
5. **Make every change explainable (Wave 4):** the change-history sheet (C3), a history for income and expense (D2, with migration 026, in the single 1.1.0 release), and the complete export (D1).
6. **After the owner decides:** separate social money (C1, Q1); one rate policy (C2, Q2); the rule for type switches (E9, Q4).
7. **Later:** a per-person statement (D3); a date shown the same on savings entries (G3); the optional items H1 to H6 only if real use shows the need.

What to leave alone (verified sound, section 9 and research §3): money representation, idempotent saves, stale-state handling, error copy, transaction and income and expense sync, savings arithmetic, budget thresholds, delete guards.


## 16. Critical Bugs

Only P0 and P1. Each has reproduction steps, expected versus actual, how it was verified, and impact. `verifiedBy` is **code-traced** unless stated; no entry was executed on a device.

### F-LOGIC-01 · A repayment can be edited into a new debt (PF-02) · P0 · backlog A1, E4, G2
- **Reproduction** (from quickstart Track 1 step 3): (1) Create "Ahmed", record "I gave" 1,000.00 EGP; the balance shows Ahmed owes you 1,000.00 EGP. (2) Record a repayment (سداد) of 400.00 EGP; the balance is 600.00 EGP. (3) Open that repayment and switch the direction to "I gave", then save.
- **Expected:** a repayment's direction cannot change; the balance stays 600.00 EGP.
- **Actual:** the balance becomes 1,400.00 EGP (the debt grew by 2 × 400.00 EGP) and the row is still labelled "سداد".
- **verifiedBy:** code-traced. `SegmentedButton<TransactionDirection>` is always enabled (`transaction_form_page.dart:195-199`); `TransactionFormCubit.directionChanged` accepts any value (`transaction_form_cubit.dart:184`); `editTransaction` writes `direction` with no check of `existing.kind` (`transactions_repository_impl.dart:130-176`). No test covered it on v1.0.1; T026 and T027 now do (branch, Opus-reviewed).
- **Impact:** a wrong person balance and wrong overview totals through normal use; the user has no way to see why.
- **Already-flipped repayments (R8): Not counted — requires a user database; run quickstart Track 1 step 4 query.** No user database exists in this environment. The query is exact because every edit stores the previous direction in `transaction_audit_entries.previous_values_json` (`transactions_repository_impl.dart:145-150`). A count of 0 is a valid answer. **Remedy for any row it finds:** the user deletes that repayment and records it again; nothing is rewritten automatically (Financial Domain Override).

### F-SYNC-01 · Sync protocol: an unknown record type stops the download (AN-C1) · P0 (latent) · backlog S0
- **Reproduction** (needs a dev project, not executed): (1) Install v1.0.1 and sign in. (2) On the server add a row whose `entity_type` v1.0.1 does not know, or ship D2 before S0. (3) Trigger a sync.
- **Expected:** the unknown row is skipped and the rest downloads.
- **Actual:** `_parseChange` throws `FormatException('pull: unknown entity_type')` (`sync_remote_data_source.dart:104-106`) and the page fails, so every later change on that account stops arriving on that install.
- **verifiedBy:** code-traced; no test (section 9.2). **Impact:** silent stop of download for every installed app on the account. Latent today.

### F-SYNC-02 · Sync protocol: a conflict the app cannot display blocks that edit forever (AN-C2) · P0 (latent) · backlog S0, A3
- **Reproduction** (dev project, not executed): (1) On a development project, apply migrations 021-024, then change `v_policy` for `savings_contribution` in `sync_push` to `financial` (this simulates A3 shipped without the version gate). (2) Sign in with v1.0.1 on devices A and B; both show a 500.00 EGP contribution. (3) Take both offline; edit to 600.00 EGP on A and 700.00 EGP on B. (4) Sync A, then B. (5) On B open Sync conflicts: the list is empty, and the pending count stays above 0 after every later sync.
- **Expected:** the user sees the conflict.
- **Actual:** `_block` marks the outbox entry `blocked_conflict` and stores a `sync_conflicts` row, but the list drops the type (`cloud_sync_repository_impl.dart:106-108`), so no screen shows it and the edit never uploads.
- **verifiedBy:** code-traced. **Impact:** an edit that stays local forever with no notice. Latent until 025 is deployed without the gate.

### F-SYNC-03 · Savings contribution edits overwrite each other silently (PF-11) · P0 by the sync rule · backlog A3, S0
- **Reproduction** (dev project, not executed): (1) Two devices on one account both show contribution 500.00 EGP on goal "Car". (2) Both go offline. (3) Device A edits it to 600.00 EGP, device B to 700.00 EGP. (4) A syncs, then B syncs.
- **Expected:** the second device is told there is a conflict and chooses (as for transactions).
- **Actual:** the server applies B's push (`v_policy = 'lww'`, migration 023 `:299-301`); A downloads 700.00 EGP. No prompt on either device. The overwritten 600.00 EGP is recorded nowhere (section 11.1).
- **verifiedBy:** code-traced (migration SQL and `savings_repository_impl.dart:_audit`). **Impact:** a savings figure changes with no explanation and no way to recover the lost value.

### F-LOGIC-02 · Over-repayment silently reverses who owes whom (PF-01) · P1 · backlog A2, E2
- **Reproduction:** (1) Ahmed owes you 500.00 EGP. (2) Record a repayment of 7,000.00 EGP instead of 700.00 EGP and save.
- **Expected:** the form shows what is outstanding and what the result will be, and asks before the balance reverses.
- **Actual:** the form has no balance reference (`repayment_form_page.dart`, `repayment_form_cubit.dart`). The saved row is "received", so the balance becomes "you owe Ahmed 6,500.00 EGP". The reversal is intended (001 FR-012); the missing warning is the defect. The button is correctly hidden when the person is settled (`person_detail_page.dart:187`).
- **verifiedBy:** code-traced; `transactions_repository_impl_test.dart` AC3 asserts the flip. **Impact:** a typing slip creates a large false debt.

### F-ACCT-01 · Social money is mixed with loans (PF-03) · P1 (policy, Q1) · backlog C1
- **Reproduction:** (1) Create a wedding occasion. (2) Add Ahmed with a 500.00 EGP contribution "received" (counting is the default). (3) Open the home overview.
- **Expected:** to be decided (Q1): either a separate "مجاملات" line or kept as is.
- **Actual:** Ahmed shows under "إجمالي المستحق عليك" with real loans (`balance_queries.dart` filter; 008 FR-018).
- **verifiedBy:** code-traced; `occasions` repository tests. **Impact:** "I owe" is overstated by gifts the user does not consider debts. **Held until Owner decision Q1.**

### F-ACCT-02 · Exchange rate changes revalue history (PF-04) · P1 (policy, Q2) · backlog C2, H4
- **Reproduction:** (1) Record a 100.00 USD expense and set USD = 48.00 EGP; the month's expense total shows 4,800.00 EGP. (2) Change the rate to 50.00 EGP.
- **Expected:** to be decided (Q2).
- **Actual:** the same entry now counts 5,000.00 EGP in totals and budgets, with no edit and no record. A savings entry in USD logged earlier keeps the rate it was saved at.
- **verifiedBy:** code-traced (`ExchangeRates` has no date; converters read the current context). **Impact:** past totals move silently; two policies coexist. The people balances moving with the rate is standard for an amount owed; the income/expense and budget totals moving is the part an accountant would reject. **Held until Owner decision Q2.**

### F-ACCT-03 · No history for income and expense edits (RF-02) · P1 per spec Clarifications and constitution (research.md listed P2) · backlog D2
- **Reproduction:** (1) Record an expense of 150.00 EGP. (2) Edit it to 15.00 EGP. (3) Look for what it was.
- **Expected:** a visible previous value, as for people transactions (Financial Domain Override: every financial mutation traceable).
- **Actual:** only `edited_at` changes; no previous value is stored anywhere. Deleted entries are restorable but also unrecorded.
- **verifiedBy:** code-traced (`finance_repository_impl.dart:87-100`; no finance audit table in `app_database.dart`). **Impact:** a budget or total moved by an edit cannot be explained.

## 17. Test Scenarios

Every item of `checklists/acceptance.md` (CHK001-CHK168) has one `TestScenario` below, plus eight boundary scenarios added for SC-004 (marked `SC-004` in the covers column): **176 scenarios (168 CHK + 8 SC-004)**. `automated` is a test path that exists in the repository, a path followed by `(partial: ...)` when the test covers only part of the scenario, or `gap` when no test covers it. A scenario tagged `v1.0.1: ⚠ <ID>` is expected to fail on v1.0.1 until that backlog item ships; `⏸ Qn` waits on an owner decision. Amounts use the checklist's setup (primary currency EGP, today 2026-10-05). Catalogue paths are the files written for T004-T012; I opened them to map CHK ids (their group names carry the id).

**Currency and labels.** Every bare amount in this table is EGP (1,000.00 = 1,000.00 EGP) unless another currency is written. English labels stand for these Arabic values (from `app_ar.arb`): Settled = «تمت التسوية»; {name} owes you {amount} = «{name} مديون لك بمبلغ {amount}»; You owe {name} {amount} = «أنت مدين لـ {name} بمبلغ {amount}»; On track = «ضمن الخطة»; Near limit = «يقترب من الحد»; Over budget = «تجاوز الميزانية»; Repayment = «سداد»; Remaining: {amount} = «المتبقي: {amount}»; I gave / I received = «أعطيت» / «استلمت».

Critical calculations and their scenario counts (SC-004 needs at least 5 each): person balance and received/given 12 (BAL) · repayment 12 · overview 7 · occasion 9 · income/expense 14 · budget 14 · savings 12 · amount input 7. All are at or above 5.

### 17.1 Scenarios

| id | covers | category | preconditions, steps, inputs | expected output (number and AR/EN label) | automated |
| --- | --- | --- | --- | --- | --- |
| TS-PEOPLE-01 | CHK001 | happy | No people; add "Ahmed", no transactions | Ahmed listed with no refresh; status "تمت التسوية" / "Settled"; no amount | test/features/people/data/repositories/people_repository_watch_test.dart; test/features/people/presentation/cubit/person_list_cubit_test.dart |
| TS-PEOPLE-02 | CHK002 | negative | Ahmed exists; add "ahmed" and " Ahmed " | Duplicate warning "تكرار محتمل" / "Possible duplicate" lists Ahmed; use existing: 0 new people; create anyway: 1 | test/features/people/domain/usecases/find_possible_duplicate_person_test.dart |
| TS-PEOPLE-03 | CHK003 | negative | Add-person form, name "" or "   " | Not saved; people count unchanged; "أدخل الاسم" / "Enter a name" | test/features/people/domain/usecases/create_person_test.dart (empty-after-trim ValidationFailure) |
| TS-OVERVIEW-01 | CHK004 | regression | Ahmed owes 1,500.00 EGP; archive Ahmed | Leaves active list, in Archived; "Total owed to you" still 1,500.00 EGP; archived marker on his overview row | test/features/transactions/domain/catalogue/overview_catalogue_test.dart; test/features/people/domain/usecases/archive_restore_person_test.dart |
| TS-PEOPLE-04 | CHK005 | regression | Archived Ahmed (CHK004); restore | Back in active list, balance 1,500.00 EGP, same history rows (no duplicates) | test/features/people/domain/usecases/archive_restore_person_test.dart (partial: restore only, balance and history not asserted) |
| TS-PEOPLE-05 | CHK006 | negative | Ahmed has 1+ transactions: delete; Karim has 0: delete | Ahmed refused with archive suggestion; Karim deleted | test/features/people/domain/usecases/delete_person_test.dart |
| TS-PEOPLE-06 | CHK007 | consistency | Ahmed owes 1,500.00 EGP; rename "Ahmed Ali" | New name on list, detail, overview, occasion rows; balance 1,500.00 EGP | test/features/people/domain/usecases/edit_person_test.dart (partial: name write only) |
| TS-BAL-01 | CHK008 | happy | Ahmed no rows; "I received" 2,000.00 EGP | One row; "أنت مدين لـ Ahmed بمبلغ 2,000.00 EGP" / "You owe Ahmed 2,000.00 EGP"; "Total you owe" +2,000.00 EGP | test/features/transactions/data/repositories/transactions_repository_impl_test.dart (recordTransaction group); test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart (CHK014 same arithmetic); label text: gap |
| TS-BAL-02 | CHK009 | happy | Open record form; pick 2026-09-15; save | Default date 2026-10-05; saved row 2026-09-15, sorted by it | test/features/transactions/presentation/cubit/transaction_form_cubit_test.dart (partial) |
| TS-BAL-03 | CHK010 | happy | Note "سلفة للعربية"; then empty note | Saved exactly as typed; empty note accepted | test/features/transactions/presentation/cubit/transaction_form_cubit_test.dart (partial) |
| TS-BAL-04 | CHK011 | happy | Rate 1 USD = 48.50 EGP; "I received" 100.00 USD | Row shows 100.00 USD; "You owe Ahmed 4,850.00 EGP" | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart |
| TS-BAL-05 | CHK012 | happy | Mona; "I gave" 500.00 EGP | "مونا مديون لك..." form: "Mona owes you 500.00 EGP"; "Total owed to you" +500.00 EGP | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart |
| TS-BAL-06 | CHK013 | happy | Mona gave 2,000.00, received 500.00 | "Mona owes you 1,500.00 EGP" / "مديون لك بمبلغ 1,500.00 EGP" | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart |
| TS-BAL-07 | CHK014 | boundary | Ahmed received 2,000.00, gave 500.00 | "You owe Ahmed 1,500.00 EGP" (-150000 minor), not "Ahmed owes you" | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart |
| TS-BAL-08 | CHK015 | consistency | Ahmed with 50 mixed rows (fixed data set) | Balance = Σgiven − Σreceived to 0.01 EGP | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart |
| TS-BAL-09 | CHK016 | boundary | Karim gave 750.00, received 750.00 | "تمت التسوية" / "Settled"; no amount, no minus sign | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart |
| TS-BAL-10 | CHK017 | boundary | Karim gave 750.00, received 749.99 | "Karim owes you 0.01 EGP", not Settled | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart |
| TS-OVERVIEW-02 | CHK018 | consistency | Ahmed owes 1,500.00; you owe Mona 700.00; Karim settled | "إجمالي المستحق لك" / "Total owed to you" 1,500.00 EGP; "إجمالي المستحق عليك" / "Total you owe" 700.00 EGP; Karim counted settled; never netted to 800.00 | test/features/transactions/domain/catalogue/overview_catalogue_test.dart |
| TS-OVERVIEW-03 | CHK019 | negative | No USD rate; "I gave" 100.00 USD to Sara | Rate-needed notice with 100.00 USD; owed-to-you total blocked (null); no 1:1, none dropped | test/features/transactions/domain/catalogue/overview_catalogue_test.dart |
| TS-BAL-11 | CHK020 | regression | Sara gave 100.00 USD; rate 48.50 then 50.00 | 4,850.00 EGP then 5,000.00 EGP (today-rate valuation). Q2 | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart (current behaviour pinned; ⏸ Q2, the valuation policy is an owner decision) |
| TS-BAL-12 | SC-004 | boundary | "I gave" 999,999,999,999.99 EGP to Ahmed | "Ahmed owes you 999,999,999,999.99 EGP" / «Ahmed مديون لك بمبلغ 999,999,999,999.99 EGP»; no overflow | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart |
| TS-OVERVIEW-04 | CHK021 | negative | No USD rate; Sara gave 100.00 USD, received 1,000.00 EGP | Sara in neither "لك عندهم" nor "عليك لهم"; listed as rate needed; no badge | test/features/transactions/domain/catalogue/overview_catalogue_test.dart |
| TS-A11Y-01 | CHK022 | accessibility | TalkBack on a person balance | Full sentence incl. direction spoken (see CHK150) | gap |
| TS-REPAY-01 | CHK023 | happy | Ahmed owes 1,000.00; record repayment 1,000.00 | New row "I received", label "سداد" / "Repayment"; status Settled | test/features/transactions/domain/catalogue/repayment_catalogue_test.dart |
| TS-REPAY-02 | CHK024 | happy | You owe Mona 700.00; repay 700.00 | Row "I gave"; Settled | test/features/transactions/domain/catalogue/repayment_catalogue_test.dart |
| TS-REPAY-03 | CHK025 | negative | Karim settled; open Karim page | "Record repayment" action not shown | test/widget/person_detail_page_test.dart (partial: file covers the page; no assertion on the settled case confirmed) |
| TS-REPAY-04 | CHK026 | boundary | Ahmed owes 1,000.00; repayment 1,500.00 | Confirmation "You will owe Ahmed 500.00 EGP"; confirm: "You owe Ahmed 500.00 EGP"; cancel: nothing saved. v1.0.1: ⚠ A2, ⏸ Q3 | test/features/transactions/domain/catalogue/repayment_catalogue_test.dart (balance outcome); test/features/transactions/presentation/pages/repayment_form_page_test.dart (confirmation) |
| TS-REPAY-05 | CHK027 | negative | Edit a repayment row | Kind cannot change; stays "سداد" | test/features/transactions/domain/catalogue/repayment_catalogue_test.dart (CHK027 group) |
| TS-REPAY-06 | CHK028 | happy | Open repayment form for Ahmed (owes 1,000.00) | "المتبقي: 1,000.00 EGP" / "Remaining: 1,000.00 EGP" before typing. v1.0.1: ⚠ A2 | test/features/transactions/presentation/pages/repayment_form_page_test.dart |
| TS-REPAY-07 | CHK029 | happy | Ahmed owes 1,000.00; repay 400, 250, 350 | Balance 600.00 → 350.00 → Settled; 4 history rows in date order | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart |
| TS-REPAY-08 | CHK030 | boundary | Ahmed owes 1,000.00; three repayments of 333.33 | "Ahmed owes you 0.01 EGP", not Settled | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart |
| TS-REPAY-09 | CHK031 | boundary | Ahmed owes 1,000.00; repay 0.01 | Ahmed owes 999.99 EGP | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart |
| TS-REPAY-10 | CHK032 | regression | Gave 1,000.00, repayment 400.00; delete the 1,000.00 row | "You owe Ahmed 400.00 EGP" (documented current behavior; trust risk E6) | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart |
| TS-SETTLE-01 | CHK033 | happy | Person net exactly 0.00; "Settled" filter | "تمت التسوية" / "Settled" in both languages; listed with full history | test/features/people/data/repositories/people_repository_impl_test.dart (partial: status filter); label: gap |
| TS-OVERVIEW-05 | CHK034 | consistency | A person settles | Settled count +1; amount leaves both totals | test/features/transactions/data/repositories/transactions_repository_impl_test.dart (line 332: settledCount 1); test/features/transactions/domain/catalogue/overview_catalogue_test.dart (partial) |
| TS-SETTLE-02 | CHK035 | localization | Occasion money in = out; person net 0 | Two different labels equal to the approved §8 values. v1.0.1: ⚠ PF-06/E1 (same words "تمت التسوية") | gap |
| TS-FIN-01 | CHK036 | happy | Income 10,000.00 "Salary" 2026-10-01 | October: Income 10,000.00, Expense 0.00, Net 10,000.00; no person balance changes | test/features/finance/domain/catalogue/finance_summary_catalogue_test.dart |
| TS-FIN-02 | CHK037 | boundary | CHK036 + income 5,000.00 on 2026-11-01 | October 10,000.00; November 5,000.00 | test/features/finance/domain/catalogue/finance_summary_catalogue_test.dart |
| TS-BUDGET-01 | CHK038 | consistency | October budget; add income | No budget line actual changes | test/features/finance/domain/catalogue/finance_summary_catalogue_test.dart |
| TS-FIN-03 | CHK039 | happy | Income 10,000.00; Food 1,200.00; Transport 300.00 | Income 10,000.00; Expense 1,500.00; Net 8,500.00 | test/features/finance/domain/catalogue/finance_summary_catalogue_test.dart |
| TS-FIN-04 | CHK040 | boundary | Income 1,000.00; Expense 1,500.00 | Net -500.00 shown with words/label, not a bare number | test/features/finance/domain/catalogue/finance_summary_catalogue_test.dart (figure only); wording: gap |
| TS-FIN-05 | CHK041 | consistency | October Expense 1,500.00; "I gave" 1,000.00 to Ahmed | Expense stays 1,500.00 | test/features/finance/domain/catalogue/finance_summary_catalogue_test.dart |
| TS-FIN-06 | CHK042 | consistency | October Expense 1,500.00; savings contribution 2,000.00 | Expense stays 1,500.00 | test/features/finance/domain/catalogue/finance_summary_catalogue_test.dart |
| TS-FIN-07 | CHK043 | regression | Fresh install; restart; sync from second device | Each default category exactly once | test/features/finance/data/repositories/category_repository_impl_test.dart (22 starters); test/core/sync/sync_bootstrap_test.dart (partial) |
| TS-FIN-08 | CHK044 | negative | "Gym" exists; create "gym" and " Gym" | Rejected as duplicate; count unchanged | test/features/finance/domain/usecases/create_category_test.dart; test/features/finance/data/repositories/category_repository_impl_test.dart |
| TS-FIN-09 | CHK045 | happy | "Gym" 0 entries: remove; "Food" 1+ entries: remove | Gym deleted; Food archived, entries keep it | test/features/finance/domain/usecases/remove_category_test.dart |
| TS-FIN-10 | CHK046 | consistency | "Food" total 1,200.00; rename "Groceries" | All past entries show "Groceries"; total 1,200.00 | test/features/finance/domain/usecases/edit_category_test.dart |
| TS-BUDGET-02 | CHK047 | happy | Food planned 2,000.00; spent 1,000.00 | Used 50%; remaining 1,000.00; "ضمن الخطة" / "On track" | test/features/budgets/domain/catalogue/budget_catalogue_test.dart |
| TS-BUDGET-03 | CHK048 | boundary | Spent 1,800.00 | 90%; remaining 200.00; "يقترب من الحد" / "Near limit" | test/features/budgets/domain/catalogue/budget_catalogue_test.dart |
| TS-BUDGET-04 | CHK049 | boundary | Spent 1,799.99 | "ضمن الخطة" / "On track" (integer comparison) | test/features/budgets/domain/catalogue/budget_catalogue_test.dart |
| TS-BUDGET-05 | CHK050 | boundary | Spent 2,000.00 | 100%; remaining 0.00; "Near limit", not over | test/features/budgets/domain/catalogue/budget_catalogue_test.dart |
| TS-BUDGET-06 | CHK051 | boundary | Spent 2,000.01 | "تجاوز الميزانية" / "Over budget"; over by 0.01 EGP (remaining -0.01) | test/features/budgets/domain/catalogue/budget_catalogue_test.dart |
| TS-BUDGET-07 | CHK052 | boundary | Planned 0.00; spent 1.00 | "Over budget"; percentage n/a ("لا يوجد مبلغ مخطط" / "Nothing planned") | test/features/budgets/domain/catalogue/budget_catalogue_test.dart |
| TS-BUDGET-08 | CHK053 | happy | 250.00 in "Gifts" with no allocation | Under "مصروفات خارج الميزانية" / "Unbudgeted spending" 250.00; in no line | test/features/budgets/domain/catalogue/budget_catalogue_test.dart |
| TS-BUDGET-09 | CHK054 | boundary | Expense 2026-10-31 and 2026-11-01 | Counts in October and November respectively | test/features/budgets/domain/catalogue/budget_catalogue_test.dart |
| TS-BUDGET-10 | CHK055 | regression | Copy October budget to November | Same planned lines; November actuals from November only; October unchanged | test/features/budgets/domain/catalogue/budget_catalogue_test.dart |
| TS-BUDGET-11 | CHK056 | consistency | Food 1,000.00 edited to 1,900.00 | Line shows 1,900.00 and Near limit without leaving the screen | test/features/budgets/domain/catalogue/budget_catalogue_test.dart; test/features/budgets/presentation/budget_month_live_update_test.dart |
| TS-BUDGET-12 | CHK057 | consistency | Food 1,000.00, Transport 300.00 + unbudgeted 250.00 | Overall spent 1,300.00 (budgeted lines only); unbudgeted 250.00 separate | test/features/budgets/domain/catalogue/budget_catalogue_test.dart |
| TS-SAVINGS-01 | CHK058 | happy | Target 12,000.00; no contributions | Current 0.00; remaining 12,000.00; 0% | test/features/savings/domain/catalogue/savings_catalogue_test.dart |
| TS-SAVINGS-02 | CHK059 | happy | Contributions 2,000.00 + 1,000.00 | Current 3,000.00; remaining 9,000.00; 25% | test/features/savings/domain/catalogue/savings_catalogue_test.dart |
| TS-SAVINGS-03 | CHK060 | happy | Current 3,000.00; 1,000.00 a month; today 2026-10-05 | About 9 months; date 2027-07-05 | test/features/savings/domain/catalogue/savings_catalogue_test.dart |
| TS-SAVINGS-04 | CHK061 | boundary | Plus target date 2027-04-05 (6 whole months) | Needed per month 1,500.00; shortfall 3 months | test/features/savings/domain/catalogue/savings_catalogue_test.dart |
| TS-SAVINGS-05 | CHK062 | boundary | Remaining 1,000.00; target date 2027-01-05 | Needed per month 333.34 (rounded up) | test/features/savings/domain/catalogue/savings_catalogue_test.dart |
| TS-SAVINGS-06 | CHK063 | boundary | Target date 2026-10-20; remaining 9,000.00 | Needed 9,000.00 this month; no division error | test/features/savings/domain/catalogue/savings_catalogue_test.dart |
| TS-SAVINGS-07 | CHK064 | negative | Current 2,500.00; withdraw 500.00 then 3,000.00 | 2,000.00; second rejected (WithdrawalExceedsBalance) | test/features/savings/domain/catalogue/savings_catalogue_test.dart |
| TS-SAVINGS-08 | CHK065 | boundary | Contributions total 12,500.00 on 12,000.00 target | "تحقّق الهدف!" / "Goal reached!"; ≥100%; remaining 0.00; no estimate | test/features/savings/domain/catalogue/savings_catalogue_test.dart |
| TS-SAVINGS-09 | CHK066 | regression | Rate USD 48.50; contribute 100.00 USD; rate to 50.00 | Current +4,850.00; unchanged after the rate change (rate fixed when saved; the checklist wording "contribution date" is imprecise, see audit NF-02) | test/features/savings/domain/catalogue/savings_catalogue_test.dart |
| TS-SAVINGS-10 | CHK067 | negative | What-if monthly amount 0 or less | Validation message; no result | test/features/savings/domain/catalogue/savings_catalogue_test.dart |
| TS-OCCASION-01 | CHK068 | happy | Wedding: received 500 (Ahmed), 300 (Mona); gave 200 (Karim) | Received 800.00; given 200.00; "استلمت 600.00 أكثر مما دفعت" / "600.00 more received than given"; 3 participants | test/features/occasions/domain/catalogue/occasion_totals_catalogue_test.dart |
| TS-OCCASION-02 | CHK069 | consistency | Edit Ahmed 500.00 → 450.00 from either screen | Both screens 450.00; wedding received 750.00; one row in Ahmed history | test/features/occasions/domain/catalogue/occasion_totals_catalogue_test.dart |
| TS-OCCASION-03 | CHK070 | regression | After CHK068 | Ahmed "You owe Ahmed 500.00 EGP" (counts by default). ⏸ Q1 | test/features/occasions/domain/catalogue/occasion_totals_catalogue_test.dart |
| TS-OCCASION-04 | CHK071 | regression | Condolence occasion; 1,000.00 received from Sara | Occasion received 1,000.00; Sara balance unchanged | test/features/occasions/domain/catalogue/occasion_totals_catalogue_test.dart |
| TS-OCCASION-05 | CHK072 | regression | Change type Wedding → Condolence | No person balance changes | test/features/occasions/domain/catalogue/occasion_totals_catalogue_test.dart |
| TS-OCCASION-06 | CHK073 | regression | Delete an occasion with contributions | Confirmation mentions removal and balance change; each balance = value without those rows | test/features/occasions/domain/catalogue/occasion_totals_catalogue_test.dart |
| TS-OCCASION-07 | CHK074 | happy | Occasion with 0 participants | "لا يوجد مشاركون بعد" / "No participants yet", not Settled | test/features/occasions/presentation/cubit/occasion_detail_cubit_test.dart (partial) |
| TS-OCCASION-08 | SC-004 | boundary | Wedding: received 0.01 EGP from Ahmed only | Received 0.01 EGP; given 0.00 EGP; «استلمت 0.01 EGP أكثر مما دفعت» / "0.01 EGP more received than given" | test/features/occasions/domain/catalogue/occasion_totals_catalogue_test.dart |
| TS-OCCASION-09 | SC-004 | boundary | Wedding: received 999,999,999,999.99 EGP and gave 999,999,999,999.99 EGP | Net 0.00 EGP; «تمت التسوية» / "Settled" | test/features/occasions/domain/catalogue/occasion_totals_catalogue_test.dart |
| TS-FIN-11 | CHK075 | consistency | October Food 1,200.00; Transport 300.00 | Food 80%; Transport 20%; parts add to 1,500.00 | test/features/finance/domain/catalogue/finance_summary_catalogue_test.dart |
| TS-FIN-12 | CHK076 | consistency | Entries in Aug, Sep, Oct | Each trend month equals that month summary | test/features/finance/domain/usecases/get_spending_trend_test.dart |
| TS-FIN-13 | CHK077 | consistency | Switch period Oct → Sep | Every figure changes together | test/features/finance/presentation/cubit/reports_cubit_test.dart (partial: period kept on resubscribe) |
| TS-FIN-14 | SC-004 | boundary | October income 0.01 EGP; expense 999,999,999,999.99 EGP | Net −999,999,999,999.98 EGP; no overflow | test/features/finance/domain/catalogue/finance_summary_catalogue_test.dart |
| TS-EXPORT-01 | CHK078 | happy | Run export | CSV has every active and archived person and non-deleted transaction with amount and currency; no deleted rows | test/features/data_privacy/domain/usecases/export_user_data_test.dart |
| TS-EXPORT-02 | CHK079 | regression | Run export | CSV also has occasions, budgets, savings, rates, history. v1.0.1: ⚠ D1/RF-03 | test/features/data_privacy/export_sections_test.dart (the ten new sections in order, filled with the T003 data) |
| TS-EXPORT-03 | CHK080 | happy | Export with network monitoring | 0 requests; shared only on tap | test/features/data_privacy/export_no_network_test.dart |
| TS-RECON-01 | CHK081 | consistency | 3 people incl. one with occasion rows | History rows (gave − received, non-counting excluded) = balance shown | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart (CHK015 for one person); multi-person run with occasions: gap |
| TS-OVERVIEW-06 | CHK082 | consistency | Listed people vs totals (archived included) | Groups add up exactly to the two totals | test/features/transactions/domain/catalogue/overview_catalogue_test.dart |
| TS-OVERVIEW-07 | SC-004 | boundary | Only Ahmed, owing 0.01 EGP | «إجمالي المستحق لك» / "Total owed to you" 0.01 EGP; settled count 0 | test/features/transactions/domain/catalogue/overview_catalogue_test.dart |
| TS-RECON-02 | CHK083 | consistency | Occasion rows by direction | Occasion totals = sum of rows | test/features/occasions/domain/catalogue/occasion_totals_catalogue_test.dart |
| TS-RECON-03 | CHK084 | consistency | Budget line vs finance history filter | Line actual = Σ category expenses in month | test/features/budgets/domain/catalogue/budget_catalogue_test.dart |
| TS-HISTORY-01 | CHK085 | happy | Person history rows | Row shows direction, kind, amount+currency, date, note, "معدَّل"/"Edited", scan badge; sorted by date | test/widget/transaction_list_tile_test.dart (partial) |
| TS-HISTORY-02 | CHK086 | consistency | Finance history: Expense, Food, 2026-10-01..31 | Total = sum of listed rows | test/features/finance/presentation/cubit/finance_history_cubit_test.dart (partial) |
| TS-HISTORY-03 | CHK087 | regression | Open an edited transaction | Change history visible with timestamps. v1.0.1: ⚠ C3/PF-05 | test/features/transactions/presentation/widgets/transaction_list_tile_history_test.dart (marker opens the sheet; EN and AR; error state); audit rows: test/features/transactions/data/repositories/transactions_repository_impl_test.dart |
| TS-HISTORY-04 | CHK088 | regression | Open an edited savings contribution | History viewable. v1.0.1: ⚠ C3 | test/features/savings/presentation/widgets/contribution_list_tile_history_test.dart (marker opens the sheet; EN and AR); audit rows: test/features/savings/domain/usecases/edit_delete_contribution_test.dart |
| TS-EDIT-01 | CHK089 | happy | "I gave" 1,000.00 edited to 800.00 | Ahmed owes 800.00; "Edited"; audit holds 1,000.00 | test/features/transactions/domain/usecases/edit_transaction_test.dart (partial: update); test/features/transactions/data/repositories/transactions_repository_impl_test.dart (audit) |
| TS-EDIT-02 | CHK090 | happy | Edit direction of a normal "I gave" 1,000.00 to "I received" | "You owe Ahmed 1,000.00 EGP" (swing 2,000.00); allowed | test/features/transactions/domain/usecases/edit_transaction_test.dart (partial) |
| TS-EDIT-03 | CHK091 | regression | Owed 1,000.00; repayment 400.00 (balance 600.00); edit repayment | Direction cannot change; balance 600.00. v1.0.1: ⚠ A1 (1,400.00) | test/features/transactions/domain/catalogue/repayment_catalogue_test.dart |
| TS-EDIT-04 | CHK092 | regression | Edit "I gave" 1,000.00 EGP; currency to USD | Confirmation warns of 1,000.00 USD without conversion. v1.0.1: ⚠ E3/RF-01 | test/features/transactions/presentation/pages/transaction_form_dialogs_test.dart (E3 group, EN and AR: the confirmation names the amount and both currencies; cancel keeps the original; amount 1,500.00 EGP to USD) |
| TS-EDIT-05 | CHK093 | happy | Edit a transaction | Person read-only | gap (code: edit form shows person read-only; unverified by test) |
| TS-EDIT-06 | CHK094 | regression | October expense 300.00 → 450.00 | Summary, budget line and report show 450.00; previous value kept. v1.0.1: ⚠ D2 | test/features/finance/domain/usecases/edit_finance_entry_test.dart (partial: update only); history: test/features/finance/data/repositories/finance_repository_impl_test.dart (edit 300 -> 450 appends one `edited` row holding the previous value 30000); summary, budget and report figures after the edit: gap |
| TS-EDIT-07 | CHK095 | negative | Edit form with changes; leave without saving | Record unchanged; no "Edited" | gap |
| TS-DELETE-01 | CHK096 | happy | Delete "I gave" 1,000.00 (Ahmed owes 1,000.00) | Confirmation "can't be undone"; confirm: row gone, Settled, audit "deleted"; cancel: nothing | test/features/transactions/domain/usecases/delete_transaction_test.dart; test/features/transactions/data/repositories/transactions_repository_impl_test.dart |
| TS-DELETE-02 | CHK097 | happy | Delete expense 300.00 then Undo | Same entry returns; totals return | test/features/finance/domain/usecases/delete_finance_entry_test.dart |
| TS-DELETE-03 | CHK098 | happy | Savings goal 3,000.00; delete 1,000.00 contribution | Current 2,000.00 | test/features/savings/domain/usecases/edit_delete_contribution_test.dart |
| TS-DELETE-04 | CHK099 | consistency | A deleted row anywhere | Appears in no total | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart; test/features/finance/domain/catalogue/finance_summary_catalogue_test.dart (partial); full cross-screen sweep: gap |
| TS-DUP-01 | CHK100 | negative | Tap Save 5 times quickly on any money form | Exactly 1 row | test/features/transactions/data/repositories/transactions_repository_impl_test.dart (retried key); test/features/transactions/data/repositories/transactions_repository_watch_test.dart:61; UI single-flight on forms: gap |
| TS-DUP-02 | CHK101 | offline | Airplane mode; save; toggle network 3 times | 1 row on device and 1 on server | test/core/sync/sync_engine_push_test.dart (partial: retry); server side: gap (needs dev project) |
| TS-DUP-03 | CHK102 | negative | Force-close right after Save; reopen | 0 or 1 rows, never 2 | gap |
| TS-DUP-04 | CHK103 | regression | "I gave" 100.00 to Ahmed twice, same date | Both saved; "looks like a duplicate" warning before the second. v1.0.1: ⚠ C4 (no warning) | test/features/transactions/presentation/pages/transaction_form_dialogs_test.dart (C4 group: duplicate asks first, cancel saves nothing, confirm saves one row); detection: test/features/transactions/data/repositories/transactions_repository_impl_test.dart (C4 findPossibleDuplicate) |
| TS-OFFLINE-01 | CHK104 | offline | Airplane mode; each local money action | Succeeds; totals update at once | test/features/finance/reports_offline_test.dart (partial: reports); other actions: gap |
| TS-OFFLINE-02 | CHK105 | offline | Airplane mode; local actions; open sync settings | No error; pending count shown | test/features/cloud_sync/presentation/sync_settings_page_test.dart (partial) |
| TS-OFFLINE-03 | CHK106 | offline | Airplane mode; ask the AI assistant | Clear "needs internet" message; no crash; no money change | gap |
| TS-SYNC-01 | CHK107 | sync | A adds 3 transactions offline; goes online | B shows the same 3 rows and balances within one cycle | test/core/sync/sync_engine_push_test.dart; test/core/sync/sync_engine_pull_test.dart (fake remote) |
| TS-SYNC-02 | CHK108 | sync | Same transaction edited on A (800.00) and B (900.00) | Conflict listed; keep mine/theirs converge; discarded version kept | test/core/sync/sync_engine_conflict_test.dart; test/core/sync/local/conflict_resolver_test.dart; test/features/cloud_sync/data/cloud_sync_repository_conflict_test.dart |
| TS-SYNC-03 | CHK109 | sync | As CHK108 for an income/expense entry | Same as CHK108 | test/core/sync/local/sync_local_store_conflict_test.dart (partial: the only conflict test that mentions finance entries) |
| TS-SYNC-04 | CHK110 | sync | As CHK108 for a savings contribution | Conflict listed. v1.0.1: ⚠ A3 (last write silently wins) | test/core/sync/sync_engine_savings_conflict_test.dart; test/features/cloud_sync/data/cloud_sync_repository_savings_conflict_test.dart |
| TS-SYNC-05 | CHK111 | sync | A (UTC+3) records 2026-10-01; B at UTC+2 | B shows 2026-10-01; counts in October. v1.0.1: ⚠ B1 (shows 2026-09-30) | test/features/transactions/data/sync/money_transaction_sync_mapper_test.dart (B1: the date is built from occurred_on, with tz_offset_minutes 180, in any device zone); test/core/sync/sync_b1_repull_test.dart (the re-pull shows the server day 2026-10-01) |
| TS-SYNC-06 | CHK112 | sync | Delete on A; sync | Gone on B; totals match | test/core/sync/sync_engine_pull_test.dart (partial) |
| TS-SYNC-07 | CHK113 | sync | Network drops mid-upload of 50 changes | All 50 arrive once; 0 duplicates; 0 lost | test/core/sync/sync_engine_push_test.dart; test/core/sync/fakes/fake_sync_remote_test.dart (partial) |
| TS-SYNC-08 | CHK114 | sync | Turn sync off | No data requests; local data usable | test/core/sync/sync_scheduler_test.dart (partial) |
| TS-I18N-01 | CHK115 | localization | Arabic: every screen of sections 1-20 | No English text except currency codes and user data | gap |
| TS-AMOUNT-01 | CHK116 | boundary | Type "١٥٠٠٫٥٠" | Saved 1,500.50 (150050) | test/core/money/amount_input_catalogue_test.dart |
| TS-AMOUNT-02 | CHK117 | regression | Type "١٬٥٠٠" | Saved 1,500.00. v1.0.1: ⚠ RF-07 (rejected) | test/core/money/amount_input_catalogue_test.dart (CHK116 group, active; RF-07 is fixed) |
| TS-I18N-02 | CHK118 | localization | Status sentences with name, amount, plurals 1, 2, 3-10, 11+ | Natural Arabic e.g. "أحمد مديون لك بمبلغ 1,500.00 EGP"; correct plural forms | gap (ICU plurals exist in app_ar.arb; no test asserts them) |
| TS-I18N-03 | CHK119 | localization | English: every screen | No Arabic except user data | gap |
| TS-I18N-04 | CHK120 | localization | Amount formatting | "1,234,567.89 EGP": grouping, currency decimals, ISO suffix | test/core/money/currency_formatter_test.dart; test/core/money/egp_formatter_regression_test.dart |
| TS-RTL-01 | CHK121 | RTL | Arabic layout (the sub-checks in the checklist) | Layout mirrors; no overflow | test/features/occasions/presentation/widgets/occasions_rtl_theme_test.dart; test/widget/savings_rtl_theme_glass_test.dart; test/widget/app_lock_rtl_theme_test.dart; people/person/transaction screens: gap |
| TS-RTL-02 | CHK122 | RTL | "1,500.00 EGP" inside an Arabic sentence | Stays one piece, digits unreversed, "EGP" after the number | gap (device check) |
| TS-RTL-03 | CHK123 | RTL | "Ahmed مديون لك…" | Correct word order; no stray punctuation | gap (device check) |
| TS-RTL-04 | CHK124 | RTL | Charts in Arabic | Time order consistent with labels; no mirrored text | test/widget/budget_trend_chart_test.dart (partial); test/widget/reports_page_test.dart (partial) |
| TS-RTL-05 | CHK125 | RTL | Switch Arabic → English | No icon/layout left mirrored | gap |
| TS-I18N-05 | CHK126 | localization | Switch language on an open person page | Labels update without restart; numbers/status same | gap |
| TS-A11Y-02 | CHK127 | accessibility | Both themes; owes / owe / over-budget states | Contrast ≥4.5:1; states distinguishable without color | test/widget/balance_status_badge_test.dart (icon plus label checked); contrast: gap |
| TS-UX-01 | CHK128 | regression | Switch theme with a half-filled form | Typed values kept | test/widget/theme_switch_preserves_form_state_test.dart |
| TS-UX-02 | CHK129 | performance | Every data screen, up to 10,000 transactions | Loading turns into content, empty or error within 10 s | gap |
| TS-UX-03 | CHK130 | happy | Save in progress | Button shows progress and is disabled until done | gap |
| TS-UX-04 | CHK131 | happy | Empty states for 9 screens | Each says what is missing and offers a next step | test/widget/home_page_test.dart; test/widget/reports_page_test.dart (partial: two of nine) |
| TS-UX-05 | CHK132 | negative | Filter matches nothing | "No results" distinct from true empty | test/features/occasions/presentation/cubit/occasions_list_cubit_test.dart ; test/widget/people_list_page_test.dart (partial: occasions and people only) |
| TS-UX-06 | CHK133 | negative | Any error in Arabic mode | No exception text; translated message | gap (no test references FailureMessage) |
| TS-UX-07 | CHK134 | negative | Total blocked by a missing rate | Rate-needed message names the currency; offers set rate | test/features/currency/cross_feature_blocking_consistency_test.dart; test/features/transactions/domain/catalogue/overview_catalogue_test.dart |
| TS-UX-08 | CHK135 | negative | Simulated storage error on save | No partial row; form keeps input; retry possible | gap |
| TS-AMOUNT-03 | CHK136 | negative | Amount 0, -5, empty | "أدخل مبلغًا أكبر من صفر، بحد أقصى 12 رقمًا" / "Enter an amount greater than zero, up to 12 digits" | test/core/money/amount_input_catalogue_test.dart |
| TS-AMOUNT-04 | CHK137 | boundary | 0.01 and 0.001 EGP | 0.01 accepted; 0.001 rejected | test/core/money/amount_input_catalogue_test.dart |
| TS-AMOUNT-05 | CHK138 | boundary | 999,999,999,999.99 and 1,000,000,000,000 EGP | First accepted; second rejected | test/core/money/amount_input_catalogue_test.dart |
| TS-AMOUNT-06 | CHK139 | boundary | "1,500" and "1 500" | Both 1,500.00 | test/core/money/amount_input_catalogue_test.dart |
| TS-AMOUNT-07 | CHK140 | consistency | CHK136-139 on every amount form | Same result on every form | test/core/money/amount_input_forms_test.dart (CHK136, CHK137 across forms) |
| TS-UX-09 | CHK141 | negative | Exchange rate 0 or below | Rejected with explanation | test/features/currency/domain/usecases/set_exchange_rate_test.dart; test/features/currency/presentation/cubit/exchange_rate_form_cubit_test.dart |
| TS-BUDGET-13 | CHK142 | boundary | Budget allocation 0.00 | Accepted | test/features/budgets/domain/usecases/add_budget_category_allocation_test.dart |
| TS-BUDGET-14 | SC-004 | boundary | Food planned 999,999,999,999.99 EGP; spent 0.01 EGP; then that expense deleted | «ضمن الخطة» / "On track", remaining 999,999,999,999.98 EGP; after the delete spent 0.00 EGP | test/features/budgets/domain/catalogue/budget_catalogue_test.dart |
| TS-SAVINGS-11 | CHK143 | negative | Goal with target date in the past | Rejected | test/features/savings/presentation/cubit/goal_form_cubit_test.dart |
| TS-SAVINGS-12 | SC-004 | boundary | Target 999,999,999,999.99 EGP; contribution 0.01 EGP; then that contribution deleted | Current 0.01 EGP, remaining 999,999,999,999.98 EGP; after the delete current 0.00 EGP | test/features/savings/domain/catalogue/savings_catalogue_test.dart |
| TS-SEC-01 | CHK144 | happy | App lock on; background beyond timeout | PIN/biometric asked; switcher preview hides money | test/features/app_lock/ (domain and presentation tests); app-switcher preview: gap |
| TS-SEC-02 | CHK145 | regression | Capture device log over sections 1-20 | No names, amounts, notes, codes, tokens, keys | test/core/sync/sync_log_scrub_test.dart (sync logs only); full device log: gap |
| TS-SEC-03 | CHK146 | happy | AI key and requests | Key only in secure storage; not in export or logs; requests carry only tool results | test/features/ai_assistant/security/ (partial); export/log absence: gap |
| TS-SEC-04 | CHK147 | regression | "Delete all data" with typed confirmation | Every table, file, key and (optionally) cloud copy removed | test/core/database/data_wipe_test.dart; test/features/data_privacy/domain/usecases/delete_all_user_data_test.dart |
| TS-SEC-05 | CHK148 | negative | Two accounts; direct table queries | A cannot read or write B rows | gap (needs dev project; SQL checks in quickstart) |
| TS-SEC-06 | CHK149 | happy | Export file location | App-private temp folder until shared | gap (share_plus_service_test.dart does not assert the folder) |
| TS-A11Y-03 | CHK150 | accessibility | TalkBack on person balance | Full sentence: "Ahmed owes you 1,500 Egyptian pounds" or the Arabic equivalent | gap |
| TS-A11Y-04 | CHK151 | accessibility | Every money action | Touch target ≥48x48 dp | gap |
| TS-A11Y-05 | CHK152 | accessibility | 200% font size on person page, overview, budget lines, savings cards | No clipped amounts or status text | test/widget/hardening_layout_test.dart (person and transaction rows, en and ar); other screens: gap |
| TS-A11Y-06 | CHK153 | accessibility | Statuses (owes, owed, over, achieved, conflict) | Never color alone | test/widget/balance_status_badge_test.dart; test/widget/over_budget_warning_badge_test.dart |
| TS-PERF-01 | CHK154 | performance | 500 people, 10,000 transactions | Overview totals <2 s | test/performance/overview_scale_test.dart |
| TS-PERF-02 | CHK155 | performance | Scroll 10,000-row history | No frame >32 ms | gap |
| TS-PERF-03 | CHK156 | performance | After Save | New row and totals within 1 s | gap |
| TS-PERF-04 | CHK157 | performance | Run the two named suites | Both pass | test/performance/sync_upload_perf_test.dart; test/performance/people_list_scale_test.dart |
| TS-REG-01 | CHK158 | regression | fvm flutter test / analyze / format | 0 failures, ≥3,699 tests; 0 analyzer issues; format exit 0 | gap (a command, not a test; baseline recorded in quickstart.md) |
| TS-REG-02 | CHK159 | regression | Catalogue suites before and after each wave | Green; only Known-fail cases may turn green | test/features/transactions/domain/catalogue/person_balance_catalogue_test.dart; test/features/transactions/domain/catalogue/overview_catalogue_test.dart; test/features/transactions/domain/catalogue/repayment_catalogue_test.dart; test/features/occasions/domain/catalogue/occasion_totals_catalogue_test.dart; test/features/finance/domain/catalogue/finance_summary_catalogue_test.dart; test/features/budgets/domain/catalogue/budget_catalogue_test.dart; test/features/savings/domain/catalogue/savings_catalogue_test.dart; test/core/money/amount_input_catalogue_test.dart |
| TS-REG-03 | CHK160 | regression | Each fixed defect | A test that failed before the fix | test/features/transactions/domain/catalogue/repayment_catalogue_test.dart (A1, B2 cases); test/core/money/amount_input_catalogue_test.dart (RF-07); A3, B1, S0 tests: gap until written |
| TS-REG-04 | CHK161 | regression | RTL/theme comparisons | Differ only where text changed on purpose (E1) | gap (the repo has no image goldens: its "RTL/theme" tests assert layout, not pixels) |
| TS-REG-05 | CHK162 | regression | Upgrade a v1.0.1 database | Every balance, total, budget actual, savings figure equals the pre-upgrade snapshot to 0.01 | test/core/database/upgrade_financial_snapshot_test.dart |
| TS-SYNC-09 | CHK163 | sync | After 025/026: v1.0.1 and updated app on one account | 0 errors; 0 stuck; v1.0.1 savings edits stay last-write-wins; no finance_entry_audit rows to it | gap (needs migrations 025/026 and two devices) |
| TS-SYNC-10 | CHK164 | sync | App 1.1.0; pull page with an unknown type | Other rows applied; cursor advances; no error; log has no row data | test/core/sync/remote/sync_remote_data_source_test.dart (partial: unknown-type parsing; SQL side untested) |
| TS-SYNC-11 | CHK165 | sync | Phone that downloaded 2026-10-01 as 2026-09-30; upgrade and sync | Shows 2026-10-01; unsynced local edit left alone | test/core/sync/sync_b1_repull_test.dart |
| TS-SYNC-12 | CHK166 | sync | A (UTC+3) savings contribution 2026-10-01; B UTC+2 | Same day on B. Known gap G3 | gap |
| TS-DELETE-05 | CHK167 | regression | Gave 1,000.00 + later repayment 400.00; delete the 1,000.00 row | Confirmation says 1 later payback; result "You owe Ahmed 400.00". v1.0.1: ⚠ E6 | test/features/transactions/presentation/widgets/delete_transaction_confirm_dialog_test.dart (1 later repayment and "You owe Ahmed 400.00"); count: test/features/transactions/data/repositories/transactions_repository_impl_test.dart (E6 countLaterRepayments) |
| TS-REPAY-11 | CHK168 | boundary | Owed 10,000.00 EGP; USD = 48.50; repay 100.00 USD; then 50.00 GBP with no GBP rate | "Remaining 5,150.00 EGP"; GBP: no number, still savable. v1.0.1: ⚠ A2 | test/features/transactions/presentation/pages/repayment_form_page_test.dart |
| TS-REPAY-12 | SC-004 | boundary | Ahmed owes 999,999,999,999.99 EGP; repay the same amount | «تمت التسوية» / "Settled" | test/features/transactions/domain/catalogue/repayment_catalogue_test.dart |

### 17.2 Gap count

Classification: `gap` = the automated column starts with "gap" (no automated test at all); `partial` = the column says "partial"; everything else is counted as covered. Nine rows counted as covered carry a sub-note about an untested aspect (for example "label text: gap" or "contrast: gap"): TS-BAL-01, TS-FIN-04, TS-RECON-01, TS-DUP-01, TS-RTL-01, TS-A11Y-02, TS-A11Y-05, TS-SEC-01, TS-SEC-02. Under a strict reading they are partial, which gives about 112 covered / 37 partial / 27 gap.

| Class | Scenarios |
| --- | --- |
| Covered by a test (existing or catalogue) | 121 |
| Partly covered (`partial`) | 28 |
| **`gap` (no test)** | **27** |
| Total | 176 |

| Calculation group | Scenarios | `gap` rows |
| --- | --- | --- |
| PEOPLE | 6 | 0 |
| OVERVIEW | 7 | 0 |
| BAL | 12 | 0 |
| A11Y | 6 | 3 |
| REPAY | 12 | 0 |
| SETTLE | 2 | 1 |
| FIN | 14 | 0 |
| BUDGET | 14 | 0 |
| SAVINGS | 12 | 0 |
| OCCASION | 9 | 0 |
| EXPORT | 3 | 0 |
| RECON | 3 | 0 |
| HISTORY | 4 | 0 |
| EDIT | 7 | 2 |
| DELETE | 5 | 0 |
| DUP | 4 | 1 |
| OFFLINE | 3 | 1 |
| SYNC | 12 | 2 |
| I18N | 5 | 4 |
| AMOUNT | 7 | 0 |
| RTL | 5 | 3 |
| UX | 9 | 4 |
| SEC | 6 | 2 |
| PERF | 4 | 2 |
| REG | 5 | 2 |
| **Total** | **176** | **27** |

Gaps cluster in on-device behaviour (accessibility, RTL, performance, TalkBack, loading states) and in server-side checks that need a development project (CHK101 server side, CHK148, CHK163; the SQL tests for migrations 025 and 026 passed locally on 2026-10-06 with `supabase test db`, 316 of 316, and T067 is ticked, but neither migration is deployed to production yet). The defects that were open when the table was first written are now fixed and mapped to their test files: CHK092 (E3), CHK103 (C4), CHK079 (D1), CHK087 and CHK088 (C3), CHK111 (B1), CHK117 (RF-07) and CHK167 (E6) (convergence T095, 2026-10-06; each file was opened and holds a relevant test). CHK094 (D2) keeps a `partial` row: the history row is tested, the summary, budget and report figures after the edit are not. Still `gap` in the rows above: TS-EDIT (two rows), TS-DUP-03, and the device, RTL, performance and security rows. CHK020 (rate change on a foreign-currency balance, TS-BAL-11) and CHK027 (repayment kind cannot change, TS-REPAY-05) are now covered by the catalogue (convergence T091; the CHK020 test pins today's behaviour and is marked ⏸ Q2, because the valuation policy is the owner's decision). CHK035 (the two "settled" labels, SETTLE) is still a gap. The eight SC-004 boundary scenarios (TS-BAL-12, TS-OVERVIEW-07, TS-REPAY-12, TS-OCCASION-08 and 09, TS-FIN-14, TS-BUDGET-14, TS-SAVINGS-12) are covered by the catalogue tests. The counts above were recomputed from the table on 2026-10-06 (the earlier "101 / 38" split for covered and partial no longer matched the rows).

Correction found while mapping: CHK066 says the savings rate is "fixed on the contribution date". The code fixes it when the entry is saved or edited (audit NF-02); the catalogue test asserts the behaviour, not the wording.

_Pending T020 (device run)_ — results table for running `checklists/acceptance.md` against v1.0.1.


## 18. Accountant Requirements

Written for an accountant (محاسب). Daftary is a **single-entry** notebook for one person's own money: there is no double-entry ledger, no chart of accounts and no trial balance, and this audit does not recommend adding them. Reconciliation is per person, per occasion and per budget month (section 12). "Test" means an automated test of the logic; a phone run of the checklist (T020) is still pending.

| # | What an accountant needs | Status | Backlog |
| --- | --- | --- | --- |
| 1 | Rebuild any person's balance from the rows behind it | **Met** (every row listed; the 50-row and three-repayment cases are tested) | none |
| 2 | See, for every row: amount, currency, date, note, direction and kind | **Met** | none |
| 3 | One fixed sign rule: gave minus received | **Met** (tested) | none |
| 4 | Tell a repayment from a new loan | **Partly met**: it is labelled, but its direction could be edited into a new debt. Fixed on the branch, Opus-reviewed | A1 |
| 5 | See what is outstanding before recording a repayment | **Partly met**: fixed on the branch, Opus-reviewed | A2 |
| 6 | See who changed what and when, for people transactions and savings | **Partly met**: recorded, not shown | C3 |
| 7 | The same for income and expense | **Missing** | D2 |
| 8 | Deleted records kept and recoverable | **Partly met**: kept; income and expense can be undone briefly; no deleted-items view | C3 |
| 9 | The currency of each record kept; the rate used at the time kept | **Partly met**: currency kept; the rate is kept only for savings entries | C2 |
| 10 | Totals never netted across "owed to you" and "you owe" | **Met** (tested) | none |
| 11 | No total shown from partial data when a rate is missing | **Met**, with one disclosed exception (the savings total, section 14.1) | none |
| 12 | A date filter and a currency filter | **Partly met**: date filter for income and expense and occasions only; no currency filter; none on a person's history | D3 |
| 13 | A statement per person with a running balance | **Missing** | D3 |
| 14 | An export complete enough to reconcile outside the app | **Partly met** | D1 |
| 15 | Month cut-off correct (31 October versus 1 November) | **Met** on one device (tested); **Partly met** across time zones | B1 |
| 16 | Exact rounding; no loss of a minor unit | **Met** for one currency (integer minor units; 0.01 EGP cases tested). With a foreign currency two screens can differ by 0.01 because they round at different steps (section 14.1, NF-05) | C2 |
| 17 | No duplicate entries from a double tap or a retry | **Met**; a "looks like a duplicate" warning is **missing** | C4 |
| 18 | An opening balance and a way to forgive a debt | **Missing**, workarounds exist; not needed now | H3, H2 |
| 19 | Understand the app's words | **Partly met**: some labels are accounting jargon and one label means two things | E1 |


## 19. Chief Accountant Requirements

Written for a chief accountant (رئيس حسابات): controls, consistency and policy. As in section 18, this is a single-entry personal notebook; four-eyes approval, a trial balance and period-close procedures do not apply and are not recommended.

| # | Control or policy need | Status | Backlog |
| --- | --- | --- | --- |
| 1 | Financial records are never silently changed; every change is traceable | **Partly met**: people and savings yes (not shown); income and expense no; a repayment's direction could be edited (fixed on the branch) | C3, D2, A1 |
| 2 | One documented valuation policy for foreign currency | **Partly met**: two policies coexist (section 3.3) | C2 (Q2) |
| 3 | Loans and gifts are not mixed in one figure | **Missing** (decision needed) | C1 (Q1) |
| 4 | Totals equal the sum of the records behind them | **Met** in tests (people lists to totals, occasion rows, budget line to history); a phone run is pending | none |
| 5 | Income and expense are separate from loans and savings | **Met** (tested) | none |
| 6 | Sync never overwrites a money figure silently, never applies a change twice | **Partly met**: true for transactions and income and expense; savings entries can be overwritten | A3, S0 |
| 7 | An upgrade never changes a balance | **Partly met**: the upgrade snapshot test exists, but it only protects from the first schema change after v1.0.1 (schema 12, D2), which has not shipped | F2 |
| 8 | A regression control for the calculations | **Met** (the calculation catalogue, on the branch) | F2 |
| 9 | Backups and export are complete | **Partly met** | D1, E8 |
| 10 | A clear rule for a repayment larger than the debt | **Partly met**: allowed, now previewed and confirmed on the branch; the policy itself is Q3 | A2 (Q3) |
| 11 | Access and privacy controls | **Met** for a local PIN, screenshot protection, row-level security on the server and a complete data wipe; the database is not encrypted at rest (accepted); one Android backup setting is unverified | none |
| 12 | The AI assistant is never the source of a figure | **Met** (every figure comes from a deterministic tool); the model could still add numbers in prose, which nothing checks | H6 |
| 13 | Month and period cut-off holds across devices | **Partly met** | B1 |
| 14 | The change of a type (income to expense) is a controlled change | **Missing** (decision needed) | E9 (Q4) |

### 19.1 Proposed accounting concepts: user-visible or internal, and why (US3 scenario 3)

A concept is proposed only if it solves a concrete correctness or trust problem. Concepts without one are left out.

| Concept | Visible to the user, or internal? | Problem it solves | Backlog |
| --- | --- | --- | --- |
| A repayment's direction is fixed | Internal rule; the user sees a short note | Stops a repayment being edited into a new debt | A1 |
| "Remaining" and a result preview on the repayment form | **User-visible** | Stops a typing slip reversing who owes whom | A2 |
| A warning before deleting a debt that later repayments depend on | **User-visible** | Stops an unexplained "you owe them" | E6 |
| Social money ("مجاملات") shown apart from loans | **User-visible** (if Q1 = separate) | Stops gifts being read as debts | C1 |
| The rate of the day stored on income and expense | Internal field; the user sees a label such as "بسعر يوم التسجيل" | Stops last month's totals changing when a rate changes | C2 |
| A change-history view | **User-visible** | Lets anyone explain a changed balance | C3 |
| A history record for income and expense edits | Internal | Makes those edits traceable | D2 |
| A confirmation when a currency or an income/expense type changes on edit | **User-visible** | Stops a mis-tap reinterpreting an amount | E3, E9 |
| A statement with a running balance | **User-visible** | The minimum an accountant needs to reconcile | D3 |
| Possible-duplicate warning | **User-visible** | Stops double entry | C4 |
| Opening balance, write-off, debt link | Left out for now (optional later) | A workaround exists and no wrong figure results | H3, H2, H1 |
| Double-entry ledger, chart of accounts, trial balance | **Rejected** | No correctness or trust problem; would make the product an ERP | none |


## 20. Prioritized Backlog

36 items. Every field of FR-016 is a column. **priority** is the wave in plan.md (Wave 0 safety net, Wave 1 stop wrong balances, Wave 2 stop silent overwrites, Wave 3 prevent entry mistakes, Wave 4 explainability, Later). **status** is the state of the branch when this was written. Every finding of P2 or higher maps to at least one item here (14 and 16 give the finding IDs), and every item traces back to a finding, except the optional H items. New items E7, E8, E9 and F4 cover RF-09, RF-10/RF-11, RF-08 and RTL-09.

| id | title | type | severity | current | expected | business reason | technical reason | acceptance criteria | dependencies | priority (wave) | status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S0 | Older apps survive new sync data | Bug (latent) | P0 | Installed v1.0.1 apps fail a whole download page on an unknown record type and park a conflict nobody can see (AN-C1, AN-C2) | The server gates new behaviour by app version; new apps skip unknown types and keep syncing | Installed apps are not patchable; one wrong deploy order would stop sync for every user on the account | Client: `_parseChange` returns null for an unknown `entity_type`, logs `unknownEntitySkipped`, cursor advances. Server: migration 025 (version-gated policy) and 026 (`sync_pull_v2`) | CHK163, CHK164; quickstart SQL checks (old app stays last-write-wins; old pull never sees `finance_entry_audit`) | none (precedes A3, D2) | Wave 1; deploy migrations 025 then 026 (user runs db push), then release app 1.1.0 | implemented on branch, reviewed (Opus approve) |
| A1 | Lock a repayment's direction | Bug | P0 | The direction of a repayment can be edited and flips the debt (PF-02) | Direction is read-only for a repayment; the repository rejects a change | A wrong balance reached through normal use, with no trace | `editTransaction` returns `ValidationFailure` when kind is repayment and direction differs; form shows read-only text; cubit ignores `directionChanged` | CHK027, CHK091; repayment catalogue case A1 active | F2 | Wave 1 | implemented on branch, reviewed (Opus approve) |
| A2 | Show what is owed before repaying; confirm a reversal | Missing requirement | P1 | The repayment form shows no outstanding amount or result; an over-payment reverses the balance silently (PF-01) | Form shows "Remaining: X", a preview (converted with the balance's rates), and a confirmation when the amount exceeds what is owed | A typing slip creates a large false debt | Pure `RepaymentPreview`; cubit watches the person balance; blocked preview when a rate is missing; saving stays possible | CHK026, CHK028, CHK168 | Q3 only for the blocking variant | Wave 3 | implemented on branch, reviewed (Opus approve); blocking variant not built (Q3) |
| A3 | Savings contribution conflicts are shown, not overwritten | Bug | P0 (sync rule) | `savings_contribution` is last-write-wins; a losing edit is recorded nowhere (PF-11) | Two devices editing one contribution produce a conflict the user resolves, like transactions | Silent change to a money figure | Migration 025 sets the financial policy for app versions at or above 1.1.0 (and filters `conflict_resolutions` from `sync_pull` for v1.0.1); conflict list and sheet render a savings entry | CHK110; fake-remote test (stale base gives a conflict; keep mine/theirs both keep the other side) | S0 | Wave 2; migration 025 before release app 1.1.0 | implemented on branch, reviewed (Opus approve): client and migration 025 written; SQL tests passed locally (`supabase test db`, 316/316, 2026-10-06); production deploy pending (you run `supabase db push`) |
| B1 | A date never shifts across time zones | Bug | P2 | Pull rebuilds the date from the instant, so a day can move and cross a month (PF-08) | Pull uses the calendar day already on the wire; rows already shifted are repaired once | Wrong budget and report month after travel or a second device | `SyncWire.parseLocalDay(occurred_on)` with fallback; one-time download-cursor reset behind `b1_repull_done` | CHK111, CHK165; mapper tests run under `TZ=UTC` | none | Wave 1 | implemented on branch, reviewed (Opus approve), with the one-time repair |
| B2 | Repayment in a rare blocked-currency case | Bug | P3 | With opposite-direction currencies and no rate, the direction defaults to "given" (RF-04) | The user is asked to set the rate first | Avoids an arbitrary direction | `_repaymentDirection` returns `Either`; `RatesMissingFailure` | Repayment catalogue case B2 active | F2 | Wave 1 | implemented on branch, reviewed (Opus approve) |
| C1 | Show social money (نقطة) apart from loans | Missing requirement | P1 | Occasion gifts sit inside "total you owe" (PF-03) | Depends on Q1; recommended: a separate "مجاملات" line, status badges stay loan-only | Stops gifts being read as debts | Derived `socialNet`; no new column | Full catalogue green before and after; new split tests | F2, Q1 | Later (after Q1) | blocked on owner decision Q1 |
| C2 | One exchange-rate policy | Missing requirement | P1 | Today's rate everywhere except savings entries (PF-04) | Depends on Q2; recommended: income, expense and budget actuals at the entry-date rate, amounts owed at today's rate, labelled | Last month's totals stop moving without an edit | `rate_micros_at_entry` on finance entries, backfilled and flagged; sync field; its own feature | Catalogue green; snapshot test; new rate tests | F2, Q2, H4 (only if full history) | Later (after Q2) | blocked on owner decision Q2 |
| C3 | Show a record's change history | Missing requirement | P2 | Edit history is stored and synced but no screen shows it (PF-05) | Tapping "معدَّل / Edited" opens earlier values with timestamps | Lets anyone explain a changed balance | `watchAuditHistory`; one generic `ChangeHistoryCubit` and sheet for transactions, savings and (later) finance entries | CHK087, CHK088 | F2 | Wave 4 | implemented on branch, reviewed (Opus approve) |
| C4 | Warn about a possible duplicate amount | Improvement | P3 | No warning for the same person, amount, direction and date (RF-05) | A warning with a continue option, using the same idempotency key | Fewer accidental double entries | `findPossibleDuplicate`; reuse the duplicate sheet pattern | CHK103 | none | Wave 3 | implemented on branch, reviewed (Opus approve) |
| D1 | Complete data export | Missing requirement | P2 | Export omits occasions, budgets, savings, rates and all history (RF-03) | One section per area, same CSV format and safe write | Needed to reconcile outside the app | Extend `ExportUserData` with the existing repository reads | CHK079; export tests extended | C3, D2 | Wave 4 | implemented on branch, reviewed (Opus approve) |
| D2 | Keep a history of income and expense edits | Missing requirement | P1 (constitution) | Edits to income and expense keep nothing (RF-02); type can be switched (RF-08) | An append-only history written with each create, edit, delete and restore; shown by the C3 sheet | Constitution: every financial mutation traceable | New `finance_entry_audits` table; sync type `finance_entry_audit` (migration 026); served only by `sync_pull_v2` | CHK094; migration test; sync test | C3, S0 | Wave 4; migration 026 before release app 1.1.0 (single release) | implemented on branch, reviewed (Opus approve): migration 026 written; SQL tests passed locally (`supabase test db`, 316/316, 2026-10-06); production deploy pending (you run `supabase db push`) |
| D3 | Statement of account (كشف حساب) per person | Improvement | P3 | No chronological list with a running balance; no date filter on a person's history | Shareable list: opening 0, each row, closing equals the shown balance; optional period | The minimum an accountant asks for | Pure running-sum helper over the existing history | Closing balance equals the person balance (CHK081) | A1, C1 | Later | open |
| E1 | Plain wording (terminology) | Improvement | P2 | Formal wording and one label for two meanings (PF-06, PF-07) | The approved §8 table is applied; the person and occasion labels differ | Users record money correctly when words are clear | ARB files only; goldens regenerated | CHK035, CHK118; reworded screens differ in RTL/theme tests | Owner decision E1, A2 | Wave 3 | blocked on owner wording sign-off (T023) |
| E2 | Over-repayment preview | Missing requirement | P1 | As A2 | Delivered by A2 | As A2 | As A2 | As A2 | A2 | Wave 3 | implemented on branch, reviewed (Opus approve), with A2 |
| E3 | Confirm a currency change on edit | Improvement | P2 | Currency changes on edit with the digits kept, for people transactions and income/expense (RF-01) | A confirmation that no conversion happens | Stops "1,000 EGP" becoming "1,000 USD" by a mis-tap | Both form cubits and pages | CHK092 | none | Wave 3 | implemented on branch, reviewed (Opus approve) |
| E4 | Mark a repayment read-only in edit | Improvement | P0 | As A1 | Delivered by A1 | As A1 | As A1 | As A1 | A1 | Wave 1 | implemented on branch, reviewed (Opus approve), with A1 |
| E5 | Accept the Arabic thousands separator | Bug | P3 | "١٬٥٠٠" is rejected (RF-07) | Saved as 1,500.00 on every amount form | Arabic-digit users are not blocked | `NumeralParser` maps U+066C | CHK117; catalogue skip removed | none | Wave 3 | implemented on branch, reviewed (Opus approve) |
| E6 | Warn before deleting a debt that later repayments depend on | Improvement | P2 | Deleting the debt flips the balance with no warning (CHK032) | The confirmation says how many later repayments exist and the resulting balance; delete is never blocked | Avoids an unexplained "you owe them" | `countLaterRepayments`; delete dialog | CHK032, CHK167 | none | Wave 3 | implemented on branch, reviewed (Opus approve) |
| E7 | A distinct "nothing matches" state on the people list | Improvement | P3 | A search or filter with no result shows the "add a person" empty state (RF-09) | A "no results for this filter" message (as finance and occasions already have) | Avoids suggesting there are no people | People list page and ARB keys | CHK132 for People | none | Wave 3 | implemented on branch (convergence T097; no-match state with a clear action, EN and AR widget tests) |
| E8 | Make export and delete-all wording accurate | Bug (copy) | P2 | Export says "a complete copy of your data" yet omits several areas (RF-10); the delete warning omits savings goals and rates (RF-11) | Strings list exactly what is exported or deleted; "complete" returns after D1 | Stated promises must be true | ARB keys `exportDescription`, `deleteDataWarningMessage` | Reviewer reads both strings against the export and wipe contents | D1 (final wording) | Wave 3 | blocked on owner wording sign-off (T023) |
| E9 | Decide how income/expense type may change on edit | Improvement | P2 (P1 while D2 is open) | An entry can be switched between income and expense on edit, moving the net by twice the amount with no trace (RF-08) | Per owner decision Q4: confirmation plus history, or locked like `kind` | The same reinterpretation risk as A1 | Form cubit and repository guard | Edit test per chosen option | Q4, D2 | Wave 3 (after Q4) | blocked on owner decision Q4 |
| F1 | A regression test for every fix | Improvement (QA) | P1 | Defects A and B had no test | Each fix has a test that failed first | Prevents silent return | Per item | CHK160 | F2 | Every wave | ongoing; done for the implemented items |
| F2 | Calculation catalogue | Improvement (QA) | P1 | No test pinned the figures | Table-driven tests with exact inputs and outputs for every critical calculation, plus an upgrade snapshot | Safety net for C1, C2 and any rate change | Files under the catalogue folders; `upgrade_financial_snapshot_test.dart` | CHK158, CHK159 | none | Wave 0 | implemented on branch, reviewed (Opus approve) |
| F3 | Cross-device sync scenarios | Improvement (QA) | P2 | No test uses two time zones or a savings conflict | Fake-remote scenarios for both | Closes the sync test gap (section 9.2) | Extend `test/core/sync/fakes` | CHK110, CHK111 | A3, B1 | Wave 2 | implemented on branch, reviewed (Opus approve): fake-remote cross-device tests |
| F4 | Arabic cases for the most-read money screens | Improvement (QA) | P2 | The person detail, people list, status badge, transaction row and repayment form tests have no Arabic or RTL case (RTL-09) | Each renders in Arabic with the status sentence, amount and direction asserted | Most users read these screens in Arabic | Add Arabic-locale cases to the listed widget tests | Each file has at least one Arabic case asserting «مديون لك» / «أنت مدين لـ» / «تمت التسوية» and an amount with EGP | none | Wave 3 | implemented on branch (convergence T092; Arabic cases in the five listed widget test files) |
| G1 | Update PRODUCT.md | Improvement (docs) | P2 | Says no backend, sync or account (PF-10) | States the shipped reality | The source of truth must be true | Docs only | Reviewer reads it against sections 2 and 11 | none | Wave 0 | implemented on branch, reviewed (Opus approve) |
| G2 | Amend 001 spec FR-015 | Improvement (docs) | P3 | The spec still allows editing a repayment's direction | An exception recorded in 001 Clarifications | Spec and product agree | Docs only | Spec text updated | A1 | Wave 0 | implemented on branch, reviewed (Opus approve) |
| G3 | Savings contributions carry a calendar day on the wire | Bug | P3 | Only an instant is sent (PF-08, CHK166) | `occurred_on` and `tz_offset_minutes` on savings entries | Same date fix as B1 for savings | Migration plus mapper | CHK166 | B1 | Later | open |
| G4 | Edit a transaction by id (deep link) | Improvement (tech debt) | P3 | Editing depends on in-memory route arguments; a deep link shows "not found" | `getTransactionById` | Robust navigation | Repository read | Deep link opens the editor | none | Later | open |
| H1 | Link a repayment to a debt; debt ageing | Optional future feature | P3 | One running net per person (PF-09) | "Owes 500.00 EGP from 3 months ago" | Debt ageing | New link column | A repayment can name the debt it pays; open debts show their age; the person's net is unchanged (catalogue green) | C1 | Not scheduled | not scheduled |
| H2 | Forgive a debt (write-off) | Optional future feature | P3 | The user fakes a repayment | An explicit kind | Cleaner history | New kind | A write-off closes the balance to 0.00 EGP and is listed as a write-off, not a repayment | A1 | Not scheduled | not scheduled |
| H3 | Opening balance | Optional future feature | P3 | Workaround: a dated entry with a note | An explicit start balance | One fewer step | New kind | An opening-balance row sets the starting net and is listed first | none | Not scheduled | not scheduled |
| H4 | Exchange-rate history with effective dates | Optional future feature | P3 | One current rate per pair | Dated rates | Only needed if Q2 = full history | New table | After a rate change, a figure dated before it keeps the earlier rate | Q2 | Not scheduled | not scheduled |
| H5 | PDF statement for accountants; multi-period reports | Optional future feature | P3 | CSV only | A printable statement | Hand-off to an accountant | Report layer | PDF statement: opening, every row, closing equals the shown balance | D3 | Not scheduled | not scheduled |
| H6 | Check the AI's prose arithmetic against tool results | Optional future feature | P3 | Prompt-only guard (RF-06) | A post-check flags numbers not in tool output | Defence in depth | Assistant layer | A reply containing a number not in any tool result is flagged | none | Not scheduled | not scheduled |


# DECISIONS REQUIRED FROM ME

Six items, of which one is answered. Each open decision is one the evidence cannot settle.

### S1 · Audit only, or include the fixes? · **Answered 2026-10-05**
- **Recommended:** none needed (answered; recorded for completeness).
Include the fixes whose behaviour is already settled (waves 0 to 4). Fixes that depend on Q1, Q2 and Q3 were held; the policy-neutral part of Q3 (preview and confirmation) is already built.

### E1 · Do you approve the wording table in section 8? · **Pending** (needs a native Egyptian-speaker review, task T023)
- **Options:** (a) approve all 35 row changes and the two word families; (b) approve with amendments row by row in the `Decision` column; (c) keep today's words.
- **Recommended:** (b) after a native-speaker review. The two "settled" labels must be separated either way (PF-06).
- **Impact:** (a) and (b) change the Arabic and English strings in one pass and regenerate the layout tests; the checklist items that quote the text (CHK008, CHK014, CHK035, CHK118) follow. (c) leaves the clash and the accounting words in place.

### Q1 · Does social money (نقطة) belong in the same balance as loans?
- **Options:** (A) yes, keep today's behaviour and only explain it in words; (B) show it separately as "مجاملات" and keep status badges for loans only; (C) change the default for new occasion rows to "does not count", history unchanged.
- **Recommended:** B.
- **Impact:** A costs nothing and leaves "you owe" overstated by gifts. B changes the most-read screens (person, overview) and needs the full catalogue green before and after; no data migration. C changes only new rows, so old and new weddings behave differently.

### Q2 · Foreign amounts: today's rate or the rate of the day?
- **Options:** (A) everything at today's rate (savings entries would follow too); (B) income, expense and budget actuals at the rate of the entry date; amounts owed (people balances, including the occasion rows that are part of them) at today's rate; savings unchanged; each figure labelled with its rule; (C) everything at the transaction-date rate.
- **Recommended:** B. Restating an amount still owed at today's rate is normal; restating last month's spending is not.
- **Impact:** A is wording only but leaves last month's totals moving. B adds a stored rate on income and expense (a new column, a backfill labelled as such, a sync field): its own feature, high risk, done after the catalogue. C also needs a dated rate history (H4) and the largest change.

### Q3 · What may a repayment do when it is larger than what is owed?
- **Options:** (A) allow it, with a preview and a confirmation; (B) block it and ask the user to record a new loan instead; (C) allow it silently (v1.0.1).
- **Recommended:** A (already built on the branch, Opus-reviewed).
- **Impact:** A keeps 001 FR-012 and adds a step only when the amount exceeds what is owed. B needs a rule for rates and currencies and changes FR-012. C leaves the typing-slip risk.

### Q4 · May an income or expense entry change between income and expense on edit?
- **Options:** (A) allow it, but ask for confirmation, and record it in the history once D2 exists; (B) lock the type like the kind of a transaction (delete and re-enter to change it); (C) leave as is.
- **Recommended:** A. It is cheap for the user, and D2 makes it traceable; until D2 ships, the confirmation is the only control.
- **Impact:** A adds one confirmation step. B removes the risk entirely at the cost of re-entering a record (with a few seconds of undo). C leaves a change that moves the net by twice the amount with no trace (RF-08).

---

Contract check: pass (T025, Opus review, 2026-10-05). The only remaining placeholder is the device-run results table in §17 (T020).
