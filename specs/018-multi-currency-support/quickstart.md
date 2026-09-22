# Quickstart: Validate Multi-Currency Support

This is a run/validation guide, not an implementation reference — see `data-model.md` and `contracts/` for structure, and `tasks.md` (Phase 2) for build steps.

## Prerequisites

- Flutter 3.47.0 / Dart 3.10 SDK via `fvm` (`fvm flutter --version` to confirm).
- Dependencies installed and code regenerated once the migration/new DI registrations land:
  ```bash
  fvm flutter pub get
  fvm dart run build_runner build --delete-conflicting-outputs   # drift + injectable codegen
  ```
- **Requires People (001), Income/Expense (007), Occasions (008), Budgets (010), and Savings Goals (011) implemented in code** for full end-to-end validation, since this feature's changes are additive migrations onto their existing tables. Unlike 015/016/017, this feature cannot be meaningfully validated as a standalone module — see plan.md's Project Structure.
- An existing installation with some pre-feature EGP-only data (to validate the migration, SC-005) is strongly recommended for the first manual pass, in addition to a fresh install.

## Run the app

```bash
fvm flutter run
```

On first launch after this feature ships (on an existing installation), the migration runs automatically, backfilling every existing record to explicit EGP (FR-002) — no manual step, no data loss, no prompt interrupting the user.

## Automated verification

```bash
fvm flutter analyze                # static analysis gate (constitution: must be clean)
fvm flutter test                   # unit + Cubit + widget tests, especially CurrencyConverter's
                                    # exhaustive pure-function suite and each of 001/007/008/
                                    # 010/011's EXTENDED multi-currency aggregation tests
fvm flutter test integration_test  # end-to-end flows (requires a running device/emulator and
                                    # 001/007/008/010/011 implemented)
```

## Manual validation scenarios

Each scenario maps directly to a spec acceptance scenario; use as a scripted smoke test after implementation.

### 1. Record an amount in a non-primary currency (User Story 1)
1. With primary currency EGP, record a new Person transaction (001) in USD, amount 100.
   - **Expect**: saved and displayed as "100 USD," never converted/relabeled to EGP.
2. Repeat for a new Income/Expense entry (007), Occasion contribution (008), Budget planned amount (010), and Savings Goal target (011).
   - **Expect**: each shows a currency selector defaulting to EGP, changeable, and each saves with the chosen currency preserved.
3. Without touching this feature at all, record a normal EGP transaction as before.
   - **Expect**: identical experience to pre-feature behavior, zero extra prompts.

### 2. Aggregated totals across currencies (User Story 2)
1. Give a person one 1,000 EGP transaction and one 100 USD transaction; set an exchange rate 1 USD = 48.50 EGP.
2. View that person's net balance.
   - **Expect**: balance correctly includes the converted USD amount (4,850 EGP-equivalent), while the transaction history still lists the original 100 USD unconverted.
3. Add a transaction in a third currency (e.g. EUR) with no rate configured yet.
   - **Expect**: the balance total now clearly shows a "rate needed for EUR" blocked state — not silently omitting the EUR transaction, not treating it as 1:1.
4. Set a EUR rate; revisit the balance.
   - **Expect**: now correctly included.
5. Repeat the same rate-needed-blocks-then-unblocks check on the Overview totals (001), Finance summary (007), a Budget's totals (010), and the Savings overview's combined total (011).
   - **Expect**: identical, consistent behavior on every one of these five screens.

### 3. Primary currency and exchange rate management (User Story 3)
1. Open Currency settings; confirm EGP shown as primary with an exchange-rate management view.
2. Add a rate "1 USD = 48.50 EGP"; confirm it saves with a last-updated timestamp.
3. Edit the rate to 49.00; confirm the timestamp updates and subsequent totals use the new rate.
4. Attempt to enter a zero or negative rate.
   - **Expect**: rejected with a clear explanation.
5. Confirm the exchange-rate screen clearly states rates are manual/not auto-fetched.
6. Change the primary currency to USD while EGP-denominated records exist and no USD→EGP-reverse rate exists yet.
   - **Expect**: prompted to set a rate for EGP (now the "foreign" currency) as part of completing the switch — never left in a silently-blocked state immediately after switching with no explanation.

### 4. Migration and regression verification
1. On an installation with pre-existing EGP-only data (at least a few records per feature), upgrade to this feature.
   - **Expect**: every pre-existing record now explicitly shows EGP; zero ambiguous/blank currency indicators anywhere (SC-005).
2. As a user who never touches this feature, perform a full regression pass across People/Transactions/007/008/010/011.
   - **Expect**: byte-for-byte identical totals/behavior to pre-feature (SC-008).
3. With the device in airplane mode throughout, exercise Scenarios 1-3 above.
   - **Expect**: fully functional, zero network requests observed (FR-014/SC-006).
4. Switch the app language between Arabic and English, and light/dark mode, on the Currency settings screen and on a "rate needed" blocked-total message.
   - **Expect**: zero layout, alignment, or truncation defects (SC-007), including currency codes/symbols in RTL.
