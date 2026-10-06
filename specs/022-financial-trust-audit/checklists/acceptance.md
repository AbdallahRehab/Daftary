# QA & Acceptance Checklist: Daftary Financial Logic

**Purpose**: Objective pass/fail acceptance checks for the 022 Financial Trust Audit and its remediation waves
**Created**: 2026-10-05
**Feature**: [spec.md](../spec.md) · [plan.md](../plan.md) · [research.md](../research.md)
**Source of truth**: the shipped business rules (specs 001–021 and the code on `main` at v1.0.1), plus the decisions in the spec's Clarifications.

> **Ownership.** This list belongs to the reviewer or QA. `[x]` means *the check was run and passed on the build under test*. Nobody ticks a box without running it. `/speckit-implement` reads these markers but never changes them.

## How to read this checklist

- **Format**: each item is *Given (starting data) → When (action) → Then (expected result)*. An item **passes only if every part of "Then" is true**.
- **Default setup**: a fresh install, primary currency **EGP**, no exchange rates, today = **2026-10-05**, app in **English** unless the item says otherwise. People are called *Ahmed*, *Mona*, *Karim*, *Sara*.
- **Sign rule (001 FR-008)**: a person's net = **total I gave − total I received**, over non-deleted rows.
  - Positive → "*{name}* owes you X" / "*{name}* مديون لك بمبلغ X".
  - Negative → "You owe *{name}* X" / "أنت مدين لـ *{name}* بمبلغ X".
  - Zero → "Settled" / "تمت التسوية".
  - A balance is never shown with a minus sign; the words carry the direction.
- **Tags**:
  - `⚠ Known fail <ID>`: the check is *expected to fail on v1.0.1* because of a confirmed defect (see research.md). It must pass once that plan item ships.
  - `⏸ <Q>`: the expected result depends on an open owner decision (plan.md). Run it to record what the app does today; the pass condition is final once the decision is made.
  - `[ref]`: the rule the check comes from.
- **Who reads what**: QA and developers use every item. Product managers can read the Then clauses alone. Accountants and chief accountants should start with sections 4–7, 11–15 and the reconciliation items (CHK081–CHK084).

> **Correction to the example in the request:** "received 2,000 and given 500 → 1,500 owed to the user" is the *wrong way round* under Daftary's rule. Given 500 − received 2,000 = −1,500, so **the user owes the person 1,500 EGP**. The checklist uses the correct direction (CHK014). If you meant the opposite convention, that would change the product's core rule. Please say so.

---

## 1. People

- [ ] CHK001 Given no people, when the user adds "Ahmed" with no transactions, then Ahmed appears in the People list **without a manual refresh**, with the status "Settled" and no amount. [001 FR-001; 004]
- [ ] CHK002 Given "Ahmed" exists, when the user adds "ahmed" or " Ahmed " (different case or extra spaces), then a possible-duplicate warning lists the existing Ahmed. Choosing the existing person creates **0** new people; choosing "create anyway" creates exactly **1**. [001 FR-003]
- [ ] CHK003 Given the add-person form, when the name is empty or only spaces, then the person can't be saved and the people count is unchanged. [constitution, Form Validation]
- [ ] CHK004 Given Ahmed owes you 1,500.00 EGP, when Ahmed is archived, then Ahmed leaves the active list and appears in Archived. The home overview "Total owed to you" **still includes 1,500.00 EGP**, and Ahmed's row there carries an archived marker. [001 Clarifications; research PF-12]
- [ ] CHK005 Given archived Ahmed (from CHK004), when Ahmed is restored, then Ahmed is back in the active list with balance 1,500.00 EGP and the same number of history rows as before archiving (no duplicates, none missing). [005]
- [ ] CHK006 Given Ahmed has at least 1 transaction, when the user tries to delete Ahmed, then deleting is refused with a message that suggests archiving instead, and Ahmed and every transaction remain. Given Karim has 0 transactions, deleting Karim succeeds. [001; server `person_has_transactions`]
- [ ] CHK007 Given Ahmed owes you 1,500.00 EGP, when the name is edited to "Ahmed Ali", then the new name shows in the People list, person detail, overview and every occasion participant row, and the balance is still 1,500.00 EGP.

## 2. Money received

- [ ] CHK008 Given Ahmed with no transactions, when the user records "I received" 2,000.00 EGP, then:
  - the history shows one row "I received 2,000.00 EGP";
  - the balance reads "You owe Ahmed 2,000.00 EGP" / "أنت مدين لـ Ahmed بمبلغ 2,000.00 EGP";
  - "Total you owe" grows by exactly 2,000.00 EGP. [001 FR-004, FR-008]
- [ ] CHK009 Given the record-transaction form, when it opens, then the date is today (2026-10-05). When 2026-09-15 is picked and saved, the row shows 2026-09-15 and is sorted by that date. [001 FR-004]
- [ ] CHK010 Given the form, when the note "سلفة للعربية" is entered, then it is saved and shown exactly as typed. An empty note is accepted.
- [ ] CHK011 Given the rate 1 USD = 48.50 EGP, when the user records "I received" 100.00 USD from Ahmed, then the row shows **100.00 USD** (its original currency) and the balance reads "You owe Ahmed 4,850.00 EGP". [018 FR-004, FR-008]

## 3. Money given

- [ ] CHK012 Given Mona with no transactions, when the user records "I gave" 500.00 EGP, then the balance reads "Mona owes you 500.00 EGP" and "Total owed to you" grows by exactly 500.00 EGP.
- [ ] CHK013 Given Mona with "I gave" 2,000.00 and "I received" 500.00, then the balance reads "**Mona owes you 1,500.00 EGP**". [001 FR-008]
- [ ] CHK014 Given Ahmed with "I received" 2,000.00 and "I gave" 500.00, then the balance reads "**You owe Ahmed 1,500.00 EGP**", *not* "Ahmed owes you". [001 FR-008]

## 4. Balances

- [ ] CHK015 Given Ahmed with 50 mixed transactions (a fixed data set kept by QA), then the balance shown equals Σgiven − Σreceived from the data set **exactly, to 0.01 EGP**. [001 SC-002]
- [ ] CHK016 Given Karim with "I gave" 750.00 and "I received" 750.00, then the status reads "Settled" / "تمت التسوية", with no amount and no minus sign.
- [ ] CHK017 Given Karim with "I gave" 750.00 and "I received" 749.99, then the status reads "Karim owes you 0.01 EGP", **not** "Settled".
- [ ] CHK018 Given Ahmed owes you 1,500.00, you owe Mona 700.00 and Karim is settled, then:
  - "Total owed to you" = **1,500.00 EGP**;
  - "Total you owe" = **700.00 EGP**;
  - Karim is counted as settled.
  
  The two totals are **never netted into 800.00**. [001 FR-013]
- [ ] CHK019 Given no USD rate, when the user records "I gave" 100.00 USD to Sara, then Sara's balance shows a rate-needed notice with "100.00 USD", and the overview total it belongs in is shown as blocked. No total converts USD at 1:1, and none quietly leaves it out. [018 FR-009]
- [ ] CHK020 Given Sara gave 100.00 USD and the rate is set to 48.50, then Sara owes you 4,850.00 EGP. When the rate is changed to 50.00, then Sara owes you **5,000.00 EGP** (today's behavior: what is owed is valued at today's rate). ⏸ Q2 [research PF-04]
- [ ] CHK021 Given no USD rate, and Sara with "I gave" 100.00 USD and "I received" 1,000.00 EGP, then Sara appears in neither "They owe you" nor "You owe them". She is listed as "rate needed", with no status badge. [018; `PersonBalance.status`]
- [ ] CHK022 Given any person, when the balance is read aloud by TalkBack, then the full sentence including the direction is spoken (see CHK150).

## 5. Repayments

- [ ] CHK023 Given Ahmed owes you 1,000.00 EGP, when "Record repayment" 1,000.00 is saved, then the new row is automatically "I received", labelled "Repayment" / "سداد", and the status is "Settled". [001 FR-011]
- [ ] CHK024 Given you owe Mona 700.00 EGP, when a repayment of 700.00 is saved, then the row is automatically "I gave" and the status is "Settled". [001 FR-011]
- [ ] CHK025 Given Karim is settled, then the "Record repayment" action is **not shown** on Karim's page. [`person_detail_page.dart`]
- [ ] CHK026 Given Ahmed owes you 1,000.00, when a repayment of 1,500.00 is entered, then a confirmation states the result ("You will owe Ahmed 500.00 EGP"). On confirm the balance reads "You owe Ahmed 500.00 EGP"; on cancel, nothing is saved. ⚠ Known fail A2 (today it saves silently) · ⏸ Q3 [001 FR-012]
- [ ] CHK027 Given a repayment row, when it is edited, then its kind cannot be changed and stays "Repayment". [001 Clarifications]
- [ ] CHK028 Given the repayment form, then it shows the current outstanding amount (for example "Remaining: 1,000.00 EGP") before the user types. ⚠ Known fail A2

## 6. Partial repayments

- [ ] CHK029 Given Ahmed owes you 1,000.00, when repayments of 400.00, then 250.00, then 350.00 are saved, then the balance after each one is **600.00 → 350.00 → Settled**. The history shows 4 rows in date order.
- [ ] CHK030 Given Ahmed owes you 1,000.00, when three repayments of 333.33 are saved, then the balance reads "Ahmed owes you **0.01 EGP**", not "Settled". (Money is exact, with no rounding.) [constitution VIII]
- [ ] CHK031 Given Ahmed owes you 1,000.00, when a repayment of 0.01 is saved, then Ahmed owes you 999.99 EGP.
- [ ] CHK032 Given "I gave" 1,000.00 and then a repayment of 400.00 (received), when the original 1,000.00 row is deleted, then the balance reads "You owe Ahmed 400.00 EGP", because the repayment stays as it is. This is the documented current behavior; the audit records it as a trust risk. [research PF-09]

## 7. Settlements

- [ ] CHK033 Given a person whose net is exactly 0.00, then the status is "Settled" in both languages. Under the "Settled" filter they are listed, with their full history still visible.
- [ ] CHK034 Given a person settles, then the overview's settled count goes up by exactly 1, and their amount leaves both totals.
- [ ] CHK035 Given an occasion with equal money received and given, and a person with net 0, then the two screens use **different** labels, each equal to the value the owner approved in audit §8 (proposed: person "All square" / "خالصين"; occasion "Money in = money out" / "الداخل = الخارج"). ⚠ Known fail PF-06 / E1 (today both say "تمت التسوية"; blocked until the owner signs off §8)

## 8. Income

- [ ] CHK036 Given no finance entries, when Income 10,000.00 "Salary" dated 2026-10-01 is added, then October shows Income 10,000.00, Expense 0.00, Net 10,000.00. **No person's balance changes.** [007]
- [ ] CHK037 Given CHK036, when Income 5,000.00 dated 2026-11-01 is added, then October's income is still 10,000.00 and November's is 5,000.00.
- [ ] CHK038 Given a budget for October, when income is added, then no budget line's actual changes. [010; spec Clarifications]

## 9. Expenses

- [ ] CHK039 Given Income 10,000.00, plus Expenses 1,200.00 "Food" and 300.00 "Transport" in October, then October shows Income **10,000.00**, Expense **1,500.00**, Net **8,500.00**.
- [ ] CHK040 Given Income 1,000.00 and Expense 1,500.00 in October, then the screen shows that spending was more than income by **500.00** in words or with an unambiguous label, never a bare unexplained number. [007 FR-014]
- [ ] CHK041 Given October Expense 1,500.00, when the user records "I gave" 1,000.00 to Ahmed (a loan), then October Expense **stays 1,500.00**. [spec Clarifications]
- [ ] CHK042 Given October Expense 1,500.00, when a savings contribution of 2,000.00 is logged, then October Expense **stays 1,500.00**. [spec Clarifications]

## 10. Categories

- [ ] CHK043 Given a fresh install, then each default category exists exactly once, and still exactly once after restarting the app and after a sync from a second device. [007; `seed_default_categories`]
- [ ] CHK044 Given "Gym" exists, when "gym" or " Gym" is created, then it is rejected as a duplicate and the category count is unchanged.
- [ ] CHK045 Given "Gym" has 0 entries, when it is removed, then it is deleted. Given "Food" has at least 1 entry, when it is removed, then it is **archived**:
  - existing entries still show "Food";
  - "Food" no longer appears in the picker for new entries;
  - October's totals, reports and budget actuals are unchanged. [007; 010 FR-021]
- [ ] CHK046 Given "Food" totals 1,200.00, when it is renamed "Groceries", then every past entry shows "Groceries" and the total is still 1,200.00.

## 11. Budgets

Setup for CHK047–CHK053: October budget, Food planned **2,000.00 EGP**.

- [ ] CHK047 Food spent 1,000.00 → used **50%**, remaining **1,000.00**, status "On track". [010]
- [ ] CHK048 Food spent 1,800.00 → used **90%**, remaining 200.00, status "**Near full**" (the threshold is ≥ 90%). [`budgetStatusFor`]
- [ ] CHK049 Food spent 1,799.99 → status "**On track**". (The comparison uses whole numbers, so 89.9995% is never rounded up to 90.) [`budgetStatusFor`]
- [ ] CHK050 Food spent 2,000.00 → used 100%, remaining 0.00, status "Near full" (**not** over budget: over budget requires spending *above* the plan).
- [ ] CHK051 Food spent 2,000.01 → status "**Over budget**", shown as over by 0.01 EGP.
- [ ] CHK052 Food planned 0.00 and spent 1.00 → status "Over budget", percentage "n/a" (no division by zero).
- [ ] CHK053 An expense of 250.00 in "Gifts" (no allocation in this budget) → shown under "Unbudgeted spending" with 250.00, and in **no** budget line.
- [ ] CHK054 An expense dated 2026-10-31 counts in October; one dated 2026-11-01 counts in November.
- [ ] CHK055 Given the October budget, when it is copied to November, then November has the same planned lines, November's actuals come only from November entries, and October is unchanged. [010]
- [ ] CHK056 Given Food spent 1,000.00, when that expense is edited to 1,900.00, then the Food line shows 1,900.00 and "Near full" **without leaving the screen**.
- [ ] CHK057 Given lines Food 1,000.00 and Transport 300.00 spent, plus unbudgeted 250.00, then the overall budget card shows spent **1,300.00** (budgeted lines only, by design: `BudgetSummary` totals are taken from the category lines), and "Unbudgeted spending" shows **250.00** as its own separate total. Any other value **fails**. [010 FR-005, FR-007]

## 12. Savings

Setup for CHK058–CHK064: goal "Car", target **12,000.00 EGP**, as of 2026-10-05.

- [ ] CHK058 No contributions → current 0.00, remaining 12,000.00, progress 0%.
- [ ] CHK059 Contributions 2,000.00 + 1,000.00 → current **3,000.00**, remaining **9,000.00**, progress **25%**.
- [ ] CHK060 Current 3,000.00 and a planned 1,000.00 a month → about **9 months** left, estimated date **2027-07-05**. [011 FR-010]
- [ ] CHK061 Current 3,000.00, planned 1,000.00 a month, target date 2027-04-05 (6 whole months away) → needed per month **1,500.00**, and a shortfall of **3 months** is shown. [011 FR-011, FR-012]
- [ ] CHK062 Remaining 1,000.00 with a target date of 2027-01-05 (3 months away) → needed per month **333.34** (always rounded *up*, never 333.33). [011 Assumptions]
- [ ] CHK063 Target date 2026-10-20 (inside this month) with remaining 9,000.00 → needed **9,000.00** this month (never "infinite" or a division error). [`SavingsCalculator`]
- [ ] CHK064 Current 2,500.00, when a withdrawal of 500.00 is logged, then current is 2,000.00. When a withdrawal of 3,000.00 is tried, then it is **rejected** and current is still 2,000.00. [`WithdrawalExceedsBalanceFailure`]
- [ ] CHK065 Contributions totalling 12,500.00 → the goal shows "Achieved", progress at least 100%, remaining **0.00** (never negative), and no estimate.
- [ ] CHK066 With the rate USD = 48.50, when 100.00 USD is contributed to an EGP goal, then current grows by **4,850.00**. When the rate later changes to 50.00, current **does not change** (the rate is fixed on the contribution date). [011 FR-028]
- [ ] CHK067 In the what-if calculator, a hypothetical monthly amount of 0 or less → a validation message, and no result is shown. [011 FR-016]

## 13. Occasions

Setup: a "Wedding" occasion.

- [ ] CHK068 Received 500.00 from Ahmed and 300.00 from Mona, gave 200.00 to Karim → Total received **800.00**, total given **200.00**, the summary reads "**600.00 more received than given**" / "استلمت 600.00 أكثر مما دفعت", and there are **3** participants. [008 FR-007, FR-008]
- [ ] CHK069 Ahmed's 500.00 contribution appears **once** in Ahmed's own history. When it is edited to 450.00 from either the occasion screen or Ahmed's page, both screens show 450.00 and the wedding total received becomes 750.00. [008 FR-010]
- [ ] CHK070 With CHK068 done, Ahmed's balance reads "You owe Ahmed 500.00 EGP" (wedding money counts toward the balance by default). ⏸ Q1 [research PF-03]
- [ ] CHK071 A "Condolence" occasion with 1,000.00 received from Sara (default setting) → the occasion's total received is 1,000.00, and **Sara's balance is unchanged**. [008 FR-018]
- [ ] CHK072 Given contributions already recorded, when the occasion type is changed from Wedding to Condolence, then **no** existing person balance changes. [008 research Decision 3]
- [ ] CHK073 Given an occasion with contributions, when the user deletes it, then the confirmation says that its contributions will be removed and that people's balances will change. After confirming, every contribution of that occasion is gone from each person's history, and each balance equals its value *without* those rows (for example, CHK070's Ahmed goes from "You owe Ahmed 500.00" back to his balance without the wedding). Cancel changes nothing. [008; `occasions_repository_impl.dart` `deleteOccasion` soft-deletes every contribution]
- [ ] CHK074 An occasion with 0 participants → shows the "no participants yet" empty state, **not** "Settled". [008 FR-020]

## 14. Reports

- [ ] CHK075 Given October expenses Food 1,200.00 and Transport 300.00, then the category breakdown shows Food 1,200.00 (80%) and Transport 300.00 (20%), and the parts add up to exactly 1,500.00.
- [ ] CHK076 Given entries in August, September and October, then each month on the trend chart equals that month's summary exactly.
- [ ] CHK077 When the period is switched from October to September, then every figure on the screen changes to September together, and nothing still shows October.
- [ ] CHK078 Given Data export, when it runs, then the CSV contains every active and archived person and every non-deleted transaction, each with amount and currency, and **no** deleted rows. [013]
- [ ] CHK079 Given Data export, then the CSV also contains occasions, budgets and allocations, savings goals and contributions, exchange rates, and change history. ⚠ Known fail D1 / RF-03
- [ ] CHK080 Given Data export runs with network monitoring on, then **0** network requests are made, and the file is shared only when the user taps share. [013 FR-012]

**Reconciliation (for accountants)**

- [ ] CHK081 For any person, adding up the rows in their history (gave − received, ignoring rows marked as not counting) gives exactly the balance shown. Run this for 3 people, including one with occasion contributions.
- [ ] CHK082 The people listed under "They owe you" add up exactly to "Total owed to you", and the same holds for "You owe them" and "Total you owe" (archived people included).
- [ ] CHK083 An occasion's totals equal the sum of its participant rows by direction.
- [ ] CHK084 A budget line's actual equals the sum of that category's expense entries dated in that month, using the finance history filter (category plus date range).

## 15. Transaction history

- [ ] CHK085 Each row in a person's history shows: direction, kind (normal / repayment / occasion), amount with currency, date, note, an "Edited" marker when edited, and a scan badge when it came from a scan. The rows are sorted by date. [001 FR-010; 009]
- [ ] CHK086 With finance history filtered by type = Expense, category = Food and dates 2026-10-01 to 2026-10-31, then the total shown equals the sum of the listed rows.
- [ ] CHK087 Given an edited transaction, when the user opens it, then they can see its change history: the old and new amount, direction, date and note, with timestamps. ⚠ Known fail C3 / PF-05
- [ ] CHK088 Given an edited savings contribution, then its change history can be viewed. ⚠ Known fail C3

## 16. Editing

- [ ] CHK089 Given "I gave" 1,000.00 to Ahmed, when it is edited to 800.00, then Ahmed owes you 800.00, the row shows "Edited", and a stored audit entry holds the previous 1,000.00. [001 FR-015, SC-007]
- [ ] CHK090 Given "I gave" 1,000.00 (a normal transaction), when the direction is edited to "I received", then the balance reads "You owe Ahmed 1,000.00 EGP" (a swing of 2,000.00). This is allowed. [001 FR-015]
- [ ] CHK091 Given Ahmed owes you 1,000.00 and a repayment of 400.00 (balance 600.00), when that repayment is edited, then the direction **can't be changed** and the balance stays **600.00**. ⚠ Known fail A1 (today the direction can be flipped and the balance becomes **1,400.00**, still labelled "Repayment") [research PF-02]
- [ ] CHK092 Given "I gave" 1,000.00 EGP, when the currency is changed to USD while editing, then a confirmation warns that the amount will be recorded as 1,000.00 USD **without conversion**. Cancel keeps EGP. ⚠ Known fail E3 / RF-01
- [ ] CHK093 When a transaction is edited, then the person it belongs to is shown read-only and can't be changed.
- [ ] CHK094 Given an October expense of 300.00, when it is edited to 450.00, then the October summary, the budget line and the report all show 450.00 straight away. Its previous value is kept. ⚠ Known fail D2 (no history today)
- [ ] CHK095 Given an open edit form with changes made, when the user leaves without saving, then the record is unchanged and gains no "Edited" marker.

## 17. Deleting

- [ ] CHK096 Given "I gave" 1,000.00 to Ahmed (Ahmed owes you 1,000.00), when delete is tapped, then a confirmation says it can't be undone. On confirm, the row leaves the history, Ahmed is "Settled", and an audit entry of type *deleted* keeps the previous values. On cancel, nothing changes. [001 FR-016]
- [ ] CHK097 Given an expense of 300.00, when it is deleted and then Undo / Restore is used, then the same entry (amount, category, date, note) comes back and the totals return to their earlier values. [007 `restore_finance_entry`]
- [ ] CHK098 Given a savings goal at 3,000.00, when a 1,000.00 contribution is deleted, then current is 2,000.00.
- [ ] CHK099 A deleted row appears in **no** total, anywhere:
  - person balance, overview, occasion totals;
  - finance summary, budget actual, reports;
  - AI assistant answers, export.

## 18. Duplicate prevention

- [ ] CHK100 When Save on any money form is tapped 5 times quickly, then exactly **1** row is created. [001 FR-020, SC-006]
- [ ] CHK101 Given airplane mode, when a transaction is saved and the connection is then toggled off and on 3 times (forcing sync retries), then exactly **1** row exists on the device and **1** on the server.
- [ ] CHK102 When the app is force-closed right after tapping Save and reopened, then **0 or 1** rows exist, never 2.
- [ ] CHK103 When "I gave" 100.00 to Ahmed on the same date is recorded twice on purpose, then both rows are saved (never blocked). A "looks like a duplicate" warning appears before the second one is saved. ⚠ Known fail C4 (Improvement; no warning today)

## 19. Offline mode

- [ ] CHK104 In airplane mode, each of these succeeds and the totals update straight away:
  - add, edit and delete a transaction; record a repayment;
  - add an income or expense; create a budget; log a savings contribution; add an occasion contribution;
  - scan paper with OCR (on the device). [spec Clarifications; 009]
- [ ] CHK105 In airplane mode, no local money action shows an error. Sync settings show the number of changes waiting to sync.
- [ ] CHK106 In airplane mode, the AI assistant shows a clear "needs internet" message, the app doesn't crash, and no money data changes.

## 20. Synchronization

Setup: devices A and B signed in to the same account with sync on.

- [ ] CHK107 When A adds 3 transactions offline and goes online, then within 1 sync cycle B shows the same 3 rows and identical balances.
- [ ] CHK108 When the same transaction is edited offline on A (to 800.00) and on B (to 900.00), and both sync, then a conflict is listed. After "keep mine" or "keep theirs", both devices show the same amount, and the discarded version is kept in the conflict record. [021]
- [ ] CHK109 Same as CHK108, for an income or expense entry. [021]
- [ ] CHK110 Same as CHK108, for a **savings contribution**. ⚠ Known fail A3 (today the last write silently wins) [research PF-11]
- [ ] CHK111 When A (UTC+3) records a transaction dated 2026-10-01 and B is set to UTC+2, then after sync B shows **2026-10-01**, and the row counts in **October** budgets and reports. ⚠ Known fail B1 (today it shows 2026-09-30) [research PF-08]
- [ ] CHK112 When a row is deleted on A and synced, then it disappears on B and the totals on both devices match.
- [ ] CHK113 When the network drops part-way through uploading 50 changes, then after reconnecting all 50 arrive exactly once, and there are 0 duplicates and 0 lost rows.
- [ ] CHK114 When sync is turned off, then no further network requests are made for data, and all local data stays usable.

## 21. Arabic

- [ ] CHK115 In Arabic, every screen in sections 1–20 shows no English text apart from currency codes and user-entered data.
- [ ] CHK116 When "١٥٠٠٫٥٠" (Arabic digits with an Arabic decimal point) is typed in an amount field, then it is saved as **1,500.50**. [`NumeralParser`]
- [ ] CHK117 When "١٬٥٠٠" (with the Arabic thousands separator ٬) is typed, then it is saved as **1,500.00**. ⚠ Known fail RF-07 (today `NumeralParser` doesn't convert ٬, so the amount is rejected)
- [ ] CHK118 Status sentences read naturally with the name and amount inserted ("أحمد مديون لك بمبلغ 1,500.00 EGP"), and Arabic plural forms are correct for 1, 2, 3–10 and 11+ people or items.

## 22. English

- [ ] CHK119 In English, no screen shows Arabic text apart from user-entered data.
- [ ] CHK120 Amounts show as `1,234,567.89 EGP`: thousands grouping, the currency's own number of decimals, and the ISO code after the number.

## 23. RTL

- [ ] CHK121 In Arabic:
  - the back arrow points right, and the list's leading content sits on the right;
  - progress bars (budgets, savings) fill from right to left;
  - forward chevrons are mirrored.
- [ ] CHK122 Inside an Arabic sentence, "1,500.00 EGP" stays in one piece and in order: the digits aren't reversed and "EGP" doesn't jump in front of the number.
- [ ] CHK123 An English name inside an Arabic sentence ("Ahmed مديون لك…") keeps the right word order with no stray punctuation.
- [ ] CHK124 Charts in Arabic keep their time order consistent with the labels, and no label text is mirror-flipped.

## 24. LTR

- [ ] CHK125 In English, no icon or layout is still mirrored from Arabic after switching language.
- [ ] CHK126 When the language is switched while a person's page is open, then every label updates without a restart, and every number and status stays the same.

## 25. Dark mode

- [ ] CHK127 In both themes, body text and amounts have a contrast ratio of at least 4.5:1, and the "owes you", "you owe" and over-budget states can be told apart **without color** (words or icons). [constitution, Accessibility]
- [ ] CHK128 Switching the theme while a form is half filled keeps every typed value.

## 26. Loading states

- [ ] CHK129 Every screen that reads data shows a loading state that turns into content, an empty state or an error within 10 s, even with 10,000 transactions. A spinner never runs forever. [constitution, Complete UI States]
- [ ] CHK130 While saving, the Save button shows progress and is disabled until the save finishes or fails.

## 27. Empty states

- [ ] CHK131 Each of these has an empty state that says what is missing and offers the next step: People, a person's history, Occasions, an occasion's participants, Finance history, a month with no budget, Savings, Reports and Sync conflicts.
- [ ] CHK132 A filter that matches nothing shows a "no results for this filter" message, which is **different** from the screen's true empty state.

## 28. Error states

- [ ] CHK133 No error shows a technical exception, stack trace, SQL, or English text in Arabic mode. Every error shown maps to a translated message. [`FailureMessage.messageFor`]
- [ ] CHK134 A total blocked by a missing exchange rate shows the rate-needed message, naming the currency and giving a way to set the rate.
- [ ] CHK135 When saving fails (a simulated storage error), then no partial row exists, the form keeps what was typed, and a retry is possible.

## 29. Validation

- [ ] CHK136 Amounts of 0, −5, or an empty field are rejected with "Enter an amount greater than zero, up to 12 digits" / "أدخل مبلغًا أكبر من صفر، بحد أقصى 12 رقمًا".
- [ ] CHK137 0.01 EGP is accepted; 0.001 EGP is rejected (too many decimal places).
- [ ] CHK138 999,999,999,999.99 EGP is accepted; 1,000,000,000,000 EGP is rejected. [`CurrencyFormatter.maxWholeDigits`]
- [ ] CHK139 "1,500" and "1 500" are both saved as 1,500.00.
- [ ] CHK140 CHK136–CHK139 give **the same result** on every amount form:
  - transaction, repayment, occasion contribution;
  - income or expense, budget allocation;
  - savings target, contribution and withdrawal.
  
  Any difference between forms fails. [spec Clarifications, Validation]
- [ ] CHK141 An exchange rate of 0 or below is rejected with an explanation. [018 FR-006]
- [ ] CHK142 A budget allocation of 0.00 is accepted ("0 is allowed").
- [ ] CHK143 Creating a savings goal with a target date in the past is rejected.

## 30. Security & privacy

- [ ] CHK144 With app lock on, after the app is in the background longer than the timeout, then the app asks for the PIN or biometric, and the app-switcher preview doesn't show money data. [015]
- [ ] CHK145 A device log captured during sections 1–20 contains **no** person names, amounts, notes, email codes, tokens or API keys. [constitution XII]
- [ ] CHK146 The AI API key is kept in secure storage, never appears in the export or the logs, and AI requests carry only the tool results needed for the question. [014; constitution IX]
- [ ] CHK147 After "Delete all data" with the typed confirmation, then:
  - the local database has 0 rows of user data and secure storage is empty;
  - if sync was on, the cloud copy is erased;
  - the app returns to onboarding. [013]
- [ ] CHK148 Using the server with two accounts, user A can't read or write any of user B's rows. Check this with direct table queries. [021 RLS]
- [ ] CHK149 The export file is written to the app's private temporary folder and can't be reached by other apps until the user shares it.

## 31. Accessibility

- [ ] CHK150 With TalkBack on, a person's balance is read as a full sentence ("Ahmed owes you 1,500 Egyptian pounds" or the Arabic equivalent), never as a bare number.
- [ ] CHK151 Every money action (save, repayment, edit, delete, add) has a touch target of at least 48×48 dp.
- [ ] CHK152 At 200% font size, the person page, overview, budget lines and savings cards show no clipped amounts or cut-off status text.
- [ ] CHK153 No status (owes, owed, over budget, achieved, conflict) is shown by color alone.

## 32. Performance

- [ ] CHK154 With 500 people and 10,000 transactions, the overview totals take **under 2 s** to compute (`test/performance/overview_scale_test.dart`). [001 SC-005]
- [ ] CHK155 Scrolling a history of 10,000 rows has **no frame over 32 ms**. [001 US1]
- [ ] CHK156 After Save, the new row and the updated totals appear **within 1 s**, with no manual refresh. [004]
- [ ] CHK157 `test/performance/sync_upload_perf_test.dart` and `people_list_scale_test.dart` pass on the build under test.

## 33. Regression testing

- [ ] CHK158 `fvm flutter test` passes with 0 failures and at least **3,699** tests (the baseline on 2026-10-05). `fvm flutter analyze` reports 0 issues. `dart format --set-exit-if-changed .` exits 0.
- [ ] CHK159 The calculation catalogue tests (plan F2) are green before **and** after every remediation wave. The only changes allowed are cases marked `⚠ Known fail` turning green.
- [ ] CHK160 Every fixed defect (A1, A2, A3, B1, B2, RF-07, …) has a test that **failed before the fix** and passes after it.
- [ ] CHK161 The RTL and theme screenshot comparisons differ only on screens whose text was changed on purpose (E1).
- [ ] CHK162 Given a v1.0.1 database with real data, when the app is upgraded to the build under test, then every person balance, overview total, budget actual and savings figure matches a snapshot taken before the upgrade, to 0.01.
- [ ] CHK163 After migrations 025 and 026 are deployed, a v1.0.1 app on the same account as an updated app keeps syncing with **0** errors and **0** stuck items. Its savings-contribution edits still apply as last-write-wins (it can't show that conflict). It never receives `finance_entry_audit` rows. On an updated app (R1+), the same savings conflict appears in the conflicts list. [plan S0; contracts A3+S0]
- [ ] CHK164 Given an R1+ app, when a download page contains a record of a type the app doesn't know, then the other rows on that page are applied, the download moves past it, and sync shows no error. The log line contains no row data. [plan S0]
- [ ] CHK165 Given a phone that downloaded a transaction dated 2026-10-01 as 2026-09-30 (before the B1 fix), when it is upgraded and syncs once, then the transaction shows **2026-10-01**. A record with an unsynced local edit is left as it is until that edit syncs. [plan B1 repair]
- [ ] CHK166 Given A (UTC+3) records a savings contribution dated 2026-10-01 and B is UTC+2, then after sync B shows the same day. ⚠ Known gap G3 (savings send no calendar day; not scheduled)
- [ ] CHK167 Given Ahmed with "I gave" 1,000.00 and a later repayment of 400.00, when the 1,000.00 row is deleted, then the confirmation says 1 later payback exists and the balance will become "You owe Ahmed 400.00". Confirming deletes; cancel changes nothing. ⚠ Known fail E6
- [ ] CHK168 Given Ahmed owes you 10,000.00 EGP and USD = 48.50, when a repayment of 100.00 USD is entered, then the preview reads "Remaining 5,150.00 EGP". With no GBP rate, a 50.00 GBP repayment shows no preview number and can still be saved. ⚠ Known fail A2

---

## Notes

- **Known-fail items (expected to fail today)**: CHK026, CHK028, CHK035, CHK079, CHK087, CHK088, CHK091, CHK092, CHK094, CHK103, CHK110, CHK111, CHK117, CHK164, CHK165, CHK167, CHK168. CHK166 is a known gap with nothing scheduled. Each maps to a plan item; it moves to pass when that item ships.
- **Decision-dependent items**: CHK020 (Q2), CHK026 (Q3), CHK070 (Q1). Update the expected results once the owner decides.
- **Updated after /speckit-analyze (2026-10-05)**: CHK035 now follows the approved §8 values. CHK057 states the real budget rule. CHK073 states what really happens when an occasion is deleted. CHK163 covers older apps. CHK164–CHK168 were added.
- **New finding while building this checklist**: RF-07. The Arabic thousands separator `٬` isn't converted by `NumeralParser`, so "١٬٥٠٠" is rejected as an invalid amount. Severity P3. Add it to `research.md` and to plan wave 3 (with E1).
- **Not covered here on purpose**: financial education content and calculators (016), notification wording (017) and splash or visual styling (019/020). They don't produce ledger figures. Their regression is covered by CHK158.
