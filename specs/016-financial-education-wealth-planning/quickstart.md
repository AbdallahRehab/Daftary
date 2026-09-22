# Quickstart: Validate Financial Education & Wealth Planning

This is a run/validation guide, not an implementation reference — see `data-model.md` and `contracts/` for structure, and `tasks.md` (Phase 2) for build steps.

## Prerequisites

- Flutter 3.47.0 / Dart 3.10 SDK via `fvm` (`fvm flutter --version` to confirm).
- Dependencies installed and code regenerated once new DI registrations land:
  ```bash
  fvm flutter pub get
  fvm dart run build_runner build --delete-conflicting-outputs   # injectable codegen
  ```
- No dependency on any other feature's data — this feature can be validated on a fresh install with zero prior app usage. To also validate the optional pre-fill (FR-014), have at least one Savings Goal (011) with a non-zero current amount created first.

## Run the app

```bash
fvm flutter run
```

Content is bundled with the app — no first-launch download, no remote configuration, works identically in airplane mode from the very first run.

## Automated verification

```bash
fvm flutter analyze                # static analysis gate (constitution: must be clean)
fvm flutter test                   # unit + Cubit + widget tests, especially the three
                                    # calculators' exhaustive pure-function suites
fvm flutter test integration_test  # end-to-end flows (requires a running device/emulator)
```

## Manual validation scenarios

Each scenario maps directly to a spec acceptance scenario; use as a scripted smoke test after implementation.

### 1. Browse the content library (User Story 1)
1. Enable airplane mode on the test device/emulator (or otherwise disable all connectivity).
2. Open the Financial Education section from its navigation entry point.
   - **Expect**: category list renders instantly with the disclaimer visible; zero connectivity errors.
3. Open a category, then an article.
   - **Expect**: article list shows titles/descriptions; article body renders legibly with headings/paragraphs; disclaimer still visible/reachable.
4. Switch app language to Arabic and reopen the same article.
   - **Expect**: fully translated, correctly RTL-mirrored, no truncation.
5. Read an investment-concept article (e.g. diversification).
   - **Expect**: explained in general terms only — no specific product/asset named, no "you should" phrasing.

### 2. Compound-growth calculator (User Story 2)
1. Open the compound-growth calculator; enter monthly 1,000 EGP, rate 10%, duration 10 years.
   - **Expect**: a projected total appears, with a contributed-vs-growth breakdown and the "hypothetical illustration" note.
2. Change the rate to 15%.
   - **Expect**: result recalculates immediately; re-entering the exact same inputs again always reproduces the exact same result (determinism check).
3. Enter 0 for monthly contribution, then a negative rate, then 0 years.
   - **Expect**: each rejected individually with a clear explanation.
4. Enter an annual rate of 40% (above the sanity-check threshold).
   - **Expect**: computed and shown, PLUS an additional "unusually high, purely illustrative" note.
5. With a Savings Goal already created (current amount > 0), open the calculator's optional pre-fill.
   - **Expect**: starting amount pre-fills from the goal, remains freely editable, and no part of the UI frames this as a recommendation.
6. With zero Savings Goals, open the calculator.
   - **Expect**: the pre-fill option is simply absent/hidden; manual entry still works fully.

### 3. Doubling-time and savings-rate calculators (User Story 3)
1. Open the doubling-time calculator; enter 8%.
   - **Expect**: an approximate doubling time (72÷8 = 9 years) appears, labeled as an approximation.
2. Enter 0, then a negative rate.
   - **Expect**: both rejected with clear explanations.
3. Open the savings-rate calculator; enter income 20,000 EGP and savings 5,000 EGP.
   - **Expect**: 25% savings rate shown.
4. Enter savings of 25,000 EGP against the same 20,000 EGP income.
   - **Expect**: accepted, shows a rate over 100%, not rejected or clamped.
5. Confirm neither calculator offers to read real Income/Expense (007) data even if 007 is implemented in this build.
   - **Expect**: both remain fully manual-entry only.

### 4. Persistent disclaimer and non-personalization boundary (User Story 4)
1. Visit every screen this feature introduces (library home, a category, an article, all three calculators) at least twice each, in two separate app sessions.
   - **Expect**: the disclaimer is visible or immediately reachable via a permanent element on every single visit, both times — never suppressed after a first viewing.
2. Search every screen in this feature for any input requesting risk tolerance, income profiling used to tailor content, or net worth.
   - **Expect**: none exist — the only "personal" numeric inputs anywhere are the calculators' own manually-entered, non-persisted, non-profiling figures.
3. Perform a full content-and-copy audit (all articles + all calculator result copy).
   - **Expect**: zero instances of naming a specific investment product/asset/platform, and zero instances of directive ("you should...") phrasing — this is the release-blocking check for SC-004.

### 5. Localization, theming, and offline verification (FR-017/FR-018)
1. Switch the app language between Arabic and English on every screen in this feature.
   - **Expect**: zero layout, alignment, or truncation defects (SC-006), including on the disclaimer banner and calculator result breakdown cards.
2. Switch between light and dark mode on every screen.
   - **Expect**: all remain legible and correctly themed.
3. With the device fully offline (airplane mode) for the entire session, exercise every screen and calculator in this feature.
   - **Expect**: 100% functional with zero connectivity-related error states (SC-007).
