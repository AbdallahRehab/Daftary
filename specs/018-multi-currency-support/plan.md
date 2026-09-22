# Implementation Plan: Multi-Currency Support

**Branch**: `018-multi-currency-support` | **Date**: 2026-09-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/018-multi-currency-support/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Evolve `core/money/Money` from an implicit-EGP-only integer-minor-units type into a currency-aware `CurrencyAmount` (amount + ISO 4217 `Currency`), and thread that currency dimension through every existing amount-bearing entity (`MoneyTransaction` 001, `FinanceEntry` 007, an Occasion contribution 008, `Budget` planned/actual 010, `SavingsGoal`/`SavingsContribution` 011) via five independently-migrated, individually-tested additive schema changes. Add a new small `currency` feature module owning the `Currency` catalog, the `PrimaryCurrencySetting`, and user-maintained `ExchangeRate` records, plus a pure `CurrencyConverter` Domain service every existing feature's aggregation query composes with (never duplicates). No network call anywhere (FR-014) — rates are entirely manual. This is explicitly the most cross-cutting spec in this V3 batch: unlike 015/016/017 (purely additive new modules), this plan's Project Structure enumerates a per-existing-feature migration checklist rather than a single new module, and its Constitution Check treats each of the five affected features' migrations as independently gated.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.47.0 (pinned via `fvm`, `.fvmrc`)

**Primary Dependencies**: `flutter_bloc`, `get_it` + `injectable`, `drift`, `fpdart`, `equatable`, `go_router`, `intl` (all existing, reused as-is). No new external package dependency is required — currency conversion is pure Dart arithmetic (like `SavingsCalculator`/011, `CompoundGrowthCalculator`/016), and the `Currency` catalog is bundled static data (like 016's educational content, research.md Decision 1) rather than a fetched ISO-4217 reference dataset.

**Storage**: `core/money/Money` (existing) is extended to `CurrencyAmount` (or `Money` gains a `currency` companion field — exact type-design decision in research.md Decision 2) — every existing table with a `*MinorUnits` column gains a paired `*Currency` column via an additive migration (one migration step per affected feature's existing table, not one giant undifferentiated migration — research.md Decision 3). Two new small tables: `PrimaryCurrencySetting` (single record) and `ExchangeRates` (one row per non-primary currency in use). `AppDatabase.schemaVersion` increments by 1 covering all of these changes together in one coordinated release, since they are interdependent (a currency column with no `Currency`/`ExchangeRate` catalog to reference would be meaningless) — see research.md Decision 3 for why this is one migration, not five separate ones, despite touching five features' tables.

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail`, `integration_test` per affected feature (extending, not replacing, each of 001/007/008/010/011's own existing/future integration test suites with currency-mixed scenarios) plus a new `currency_flows_test.dart` for the currency-settings/exchange-rate screens themselves. `CurrencyConverter`'s rounding/conversion arithmetic gets the same exhaustive pure-function test rigor as 011's `SavingsCalculator`/016's three calculators.

**Target Platform**: Android and iOS mobile apps (existing app scope). Pure Dart/Flutter, no native platform code required.

**Project Type**: mobile-app (Flutter, feature-first clean architecture)

**Performance Goals**: A single record's currency conversion (for individual display, which per FR-010 never actually needs to happen — records always show their own original currency) is not on any hot path; an aggregate total spanning up to ~500 records across up to 5 currencies converts and sums in under 200ms (well within existing 007/010/011 aggregation performance envelopes, since `CurrencyConverter`'s per-item work is a single multiplication+rounding, negligible next to the existing DB query cost it's composed with).

**Constraints**: Zero network calls anywhere in this feature (FR-014) — the single highest-priority architectural constraint, verified by a dedicated test mirroring 016's/017's own zero-network-activity assertion pattern. Every individual-record display MUST show that record's own original currency/amount unconverted (FR-010) — enforced by never overwriting a record's stored `CurrencyAmount` during aggregation, only computing a separate, ephemeral converted figure at the aggregation call site. A missing exchange rate MUST block (not silently default) the specific total that needs it (FR-009) — `CurrencyConverter.convert()` returns a typed "rate unavailable" result rather than falling back to any implicit 1:1 assumption. All five affected features' existing balance/total FORMULAS remain unchanged (FR-017) — this plan only inserts a conversion step ahead of a sum that was already correct for a single currency, never alters what is being summed or how.

**Scale/Scope**: Single user per device; `ExchangeRates` scales with the number of non-primary currencies actually in use (small, typically 1-5). Five existing features (001/007/008/010/011) each require: one additive migration (currency column(s) on their existing table(s)), one repository-layer read/write update to carry `CurrencyAmount` instead of bare minor-units, and one aggregation-query update to compose with `CurrencyConverter` — no new screens in those five features beyond adding the currency selector to their existing amount-entry forms and a currency indicator to their existing amount displays. One new feature module (`currency`) with ~3 screens (Primary Currency setting, Exchange Rate list, Exchange Rate add/edit).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Clean Architecture Layering | New `currency` feature splits into `data/domain/presentation`; `CurrencyConverter` is a pure Domain service, never called from a widget directly; each of 001/007/008/010/011's own aggregation use cases (already Domain-layer, per their own specs) is the only place that composes with it | PASS |
| II. Feature-First Modularity | New code lives under `lib/features/currency/`; the five existing features gain currency-awareness to their own existing entities/repositories rather than a "multi_currency" feature reaching into their internals — each feature still owns its own data, now simply currency-aware data (constitution: "feature-first structure keeps ownership boundaries clear") | PASS |
| III. BLoC/Cubit Mandate | `PrimaryCurrencyCubit`, `ExchangeRateListCubit`, `ExchangeRateFormCubit` for the new screens; each of the five existing features' own existing Cubits gain a currency field to their existing form/display state rather than a new parallel state-management path | PASS |
| IV. Immutable State | All new/extended Cubit states remain `Equatable` value classes updated via `copyWith()` — a currency field added to an existing state class is exactly the "explicit state fields over proliferating state subclasses" pattern the constitution already prefers | PASS |
| V. Domain-Driven Business Logic | New use cases: `SetPrimaryCurrency`, `SetExchangeRate`, `GetExchangeRates`, `ConvertToPrimaryCurrency` (thin wrapper around `CurrencyConverter` plus the FR-012 forced-rate-on-switch check) — plus `CurrencyConverter` itself (pure Domain service, not a use case, since it has no side effects and no repository dependency, exactly mirroring 011's `SavingsCalculator`/016's calculators) | PASS |
| VI. Repository Pattern | `CurrencyRepository` (Domain interface, owns `PrimaryCurrencySetting`/`ExchangeRates`) defined in the new `currency` feature; each of 001/007/008/010/011's own existing repository interfaces gain currency-aware method signatures (e.g. `createTransaction` now accepts a `CurrencyAmount` instead of a bare `int minorUnits`) — a signature change to an existing, already-published interface, not a new parallel repository | PASS |
| VII. Explicit Error Handling | `CurrencyConverter.convert()` returns a typed `ConversionResult` (success or `ExchangeRateMissingFailure`) rather than throwing or silently defaulting (FR-009); all `CurrencyRepository` calls return `Either<Failure, T>`; new `InvalidExchangeRateFailure` for FR-006's zero/negative rejection | PASS |
| VIII. Deterministic Financial Calculations | The entire point of `CurrencyConverter`: pure, deterministic, integer-minor-units-preserving arithmetic with one documented rounding rule (FR-013, research.md Decision 4) — never floating point, never AI-estimated; every existing feature's own balance/total FORMULA is untouched, only the amounts feeding it become currency-normalized first | PASS |
| IX. AI Isolation | Not applicable — no AI integration in this feature | PASS (N/A) |
| X. OCR Human-in-the-Loop | Not applicable — no OCR in this feature, though a future OCR feature (009) would need to also pass a `CurrencyAmount` when calling `AddTransaction` post-this-feature — noted as a downstream coordination point, not a gate violation here | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Feature is fully local; `SetExchangeRate`/`SetPrimaryCurrency` are naturally idempotent (upsert-by-currency-code, never appending duplicate rate rows for the same currency) | PASS |
| XII. Security & Secrets | No secrets, no new data classification; exchange rates are ordinary (non-sensitive) user preference data | PASS |
| XIII. Localization & RTL/LTR | Currency codes/symbols follow the same RTL/LTR-correct placement convention already established for EGP formatting in `core/money` (constitution: "currency formatting must respect locale... never simple string concatenation"); `gen_l10n` ARB additions for the new currency-settings screens and "rate needed" messaging across every affected feature's existing screens | PASS |
| XIV. Dependency Injection | `get_it`/`injectable` wires `CurrencyRepository`, `CurrencyConverter`, the new use cases, and Cubits; each of 001/007/008/010/011's existing DI registrations are updated for their now-currency-aware repository signatures, not re-architected | PASS |
| XV. Design System | Reuses existing `core/design_system`; a currency-code picker/dropdown and a small currency-indicator chip (shown next to every amount display app-wide) are the two genuinely new visual components, built once in `core/design_system` directly (not feature-scoped first) since they are needed by five existing features simultaneously from day one — a documented, justified exception to the usual "promote only after a second feature needs it" sequencing (constitution Principle XV), because this feature's very nature requires all five to gain the same component in the same release | PASS |
| XVI. Testability by Design | `CurrencyConverter`'s conversion/rounding logic is unit-tested exhaustively as pure functions (no DB/Flutter dependency), mirroring 011/016's calculator rigor; each of 001/007/008/010/011's own aggregation use cases gets an EXTENDED test (not a new file) covering a multi-currency scenario alongside their existing single-currency tests; `CurrencyRepository`/DAOs tested against an in-memory drift DB; new Cubits tested with `bloc_test`/`mocktail`; a dedicated migration test per affected feature confirms every pre-existing row is explicitly labeled EGP post-migration (FR-002/SC-005) | PASS |

No violations requiring justification beyond the one explicitly documented, reasoned exception noted under Principle XV above (a day-one shared component, not a premature abstraction — justified by this feature's simultaneous five-feature scope) — **Complexity Tracking documents this one exception below, nothing else.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): Treating this feature's migration as five independently-gated, individually-tested per-feature steps (research.md Decision 3) rather than one undifferentiated "add currency everywhere" change is the direct, minimal implementation of spec.md's own Assumptions note about this being qualitatively different from 015/016/017 — it is not scope creep, it is the only way to keep the constitution's Financial Domain Override ("financial records MUST NEVER be silently modified... every financial mutation MUST be traceable") satisfiable when the mutation in question is a schema migration touching five separate balance-calculation-critical tables simultaneously. Keeping `CurrencyConverter` a pure, repository-free Domain service (mirroring 011/016's precedent) is what makes FR-013's determinism and FR-009's missing-rate-blocks-not-defaults guarantee independently, exhaustively unit-testable rather than something each of the five features' own aggregation code could each get subtly wrong in a different way. All gates above remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/018-multi-currency-support/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md         # Phase 1 output (/speckit-plan command)
├── contracts/            # Phase 1 output (/speckit-plan command)
└── tasks.md              # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── money/
│   │   ├── money.dart                # EXTENDED: Money gains a currency-aware companion —
│   │   │                              # exact shape (Money itself gains a `currency` field vs.
│   │   │                              # a new wrapping CurrencyAmount(amount: Money, currency:
│   │   │                              # Currency)) decided in research.md Decision 2. Every
│   │   │                              # existing call site across 001/007/008/010/011 that
│   │   │                              # constructs/consumes a bare Money is touched — this is
│   │   │                              # the single highest-blast-radius file change in this
│   │   │                              # entire roadmap run.
│   │   ├── egp_formatter.dart         # EXTENDED or SUPERSEDED by a currency-aware formatter
│   │   │                              # (research.md Decision 5) that still defaults to
│   │   │                              # EGP-identical output for EGP amounts (FR-015/SC-008)
│   │   └── currency.dart              # NEW: the Currency value object (code/symbol/name) and
│   │                                   # the bundled starter-currency catalog (research.md
│   │                                   # Decision 1, mirroring 016's bundled-content pattern)
│   ├── database/                      # AppDatabase: additive currency column(s) on
│   │                                   # MoneyTransactions (001), FinanceEntries (007), the
│   │                                   # occasion-contribution table (008), Budgets (010),
│   │                                   # SavingsGoals + SavingsContributions (011), PLUS two
│   │                                   # new tables PrimaryCurrencySetting + ExchangeRates —
│   │                                   # ONE coordinated schemaVersion +1 (research.md
│   │                                   # Decision 3), each table's change independently tested
│   │   └── migrations/
│   │       └── vNN_currency_support.dart   # explicit, reviewable migration step covering all
│   │                                        # six table changes, each documented individually
│   ├── design_system/                 # gains CurrencyPicker + CurrencyIndicatorChip (built
│   │                                   # here directly per the documented Principle XV
│   │                                   # exception above, not feature-scoped first)
│   ├── di/                            # gains currency feature registrations; updates existing
│   │                                   # registrations for 001/007/008/010/011's now-currency-
│   │                                   # aware repository implementations
│   ├── error/                         # gains InvalidExchangeRateFailure, ExchangeRateMissing
│   │                                   # Failure (used by CurrencyConverter's typed result, not
│   │                                   # thrown — see contracts/currency_converter.md)
│   ├── l10n/                          # app_en.arb / app_ar.arb gain currency-settings screen
│   │                                   # keys + "rate needed" messaging keys reused across all
│   │                                   # five affected features
│   └── routing/                       # app_router.dart gains the 3 new currency-settings routes
│
├── features/
│   ├── people/                        # (001) MoneyTransaction gains currency; PersonRepository/
│   │                                   # balance-aggregation query composes CurrencyConverter;
│   │                                   # transaction form gains CurrencyPicker; history list
│   │                                   # gains CurrencyIndicatorChip per row
│   ├── finance/                       # (007) FinanceEntry gains currency; FinanceRepository's
│   │                                   # summary/breakdown queries compose CurrencyConverter;
│   │                                   # entry form + breakdown screens updated accordingly
│   ├── occasions/                     # (008) occasion-contribution amount gains currency;
│   │                                   # occasion-totals computation composes CurrencyConverter
│   ├── budgets/                       # (010) Budget planned/actual gain currency;
│   │                                   # GetBudgetOverview-equivalent composes CurrencyConverter
│   ├── savings/                       # (011) SavingsGoal target + SavingsContribution gain
│   │                                   # currency (one currency per goal, spec Assumptions);
│   │                                   # GetSavingsOverview's combined total composes
│   │                                   # CurrencyConverter; ProjectSavingsCompletion/what-if
│   │                                   # calculator explicitly stays single-currency internally
│   │                                   # (FR-011) — no CurrencyConverter call inside it at all
│   ├── settings/                      # UNCHANGED except a "Currency" nav entry point
│   └── currency/                      # NEW
│       ├── data/
│       │   ├── content/                # bundled starter-currency catalog (JSON, mirrors 016's
│       │   │                          # bundled-content pattern, research.md Decision 1)
│       │   ├── datasources/            # CurrencySettingsDao, ExchangeRateDao (drift)
│       │   └── repositories/           # CurrencyRepositoryImpl
│       ├── domain/
│       │   ├── entities/               # Currency, PrimaryCurrencySetting, ExchangeRate,
│       │   │                          # ConversionResult
│       │   ├── repositories/            # CurrencyRepository (abstract)
│       │   ├── services/                # CurrencyConverter (pure, no repository dependency —
│       │   │                          # research.md Decision 6, mirrors 011/016's calculators)
│       │   └── usecases/                # SetPrimaryCurrency (includes the FR-012 forced-rate
│       │                              # check), SetExchangeRate, GetExchangeRates,
│       │                              # GetSupportedCurrencies
│       └── presentation/
│           ├── cubit/                   # PrimaryCurrencyCubit, ExchangeRateListCubit,
│           │                          # ExchangeRateFormCubit
│           ├── pages/                    # CurrencySettingsPage, ExchangeRateListPage,
│           │                          # ExchangeRateFormPage
│           └── widgets/                  # RateNeededBanner (the shared "blocked total"
│                                       # indicator reused across 001/007/008/010/011)
│
└── main.dart                            # UNCHANGED

test/
├── core/money/                         # Money/currency-formatter unit tests — EGP-only output
│                                        # byte-identical to pre-feature behavior (FR-015/SC-008)
├── features/
│   ├── people/ 007/finance/ occasions/ budgets/ savings/
│   │                                    # EACH gains an EXTENDED (not new-file) multi-currency
│   │                                    # test alongside its existing aggregation tests —
│   │                                    # mirrors this plan's own "extend, don't duplicate"
│   │                                    # philosophy for the five affected features
│   └── currency/
│       ├── domain/services/            # CurrencyConverter exhaustive pure-function suite —
│       │                                # the most exhaustively tested file in this feature
│       ├── domain/usecases/            # unit tests, faked CurrencyRepository
│       ├── data/repositories/          # CurrencyRepositoryImpl tests against an in-memory
│       │                                # drift DB
│       └── presentation/cubit/         # bloc_test + mocktail
└── widget/                              # CurrencyPicker / CurrencyIndicatorChip / RateNeeded
                                          # Banner widget tests (core/design_system additions)

integration_test/
├── currency_flows_test.dart             # set primary currency, add/edit exchange rate, forced-
│                                        # rate-on-switch (FR-012), rate deletion re-blocks a
│                                        # total, zero-network-activity assertion
└── (extends, per feature) people_flows_test.dart / finance_flows_test.dart /
    occasions_flows_test.dart / budgets_flows_test.dart / savings_flows_test.dart
                                        # each gains a multi-currency aggregation scenario
```

**Structure Decision**: One new, small `lib/features/currency/` module owning the `Currency` catalog, primary-currency setting, and exchange rates, PLUS a coordinated, individually-tested currency-awareness change to `core/money/Money` and to each of the five existing features' own tables/repositories/forms/displays. This is explicitly not a single self-contained module the way 015/016/017 are — per spec.md's own Assumptions, this plan treats each of 001/007/008/010/011's migrations as an independently gated step (research.md Decision 3), never one undifferentiated sweep.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| `CurrencyPicker`/`CurrencyIndicatorChip` built directly in `core/design_system` on day one, rather than first built inside one feature and promoted later (constitution Principle XV's normal sequencing) | This feature's entire premise requires all five existing features (001/007/008/010/011) to gain the same currency-selection and currency-display UI in the same coordinated release — there is no meaningful "first feature" to build it inside first, since none of the five is more entitled to be that first feature than another | Building it inside, say, `features/people/` first and promoting it once a second feature needs it — rejected, would mean 007/008/010/011 ship with either a duplicated ad hoc picker or a hard, artificial dependency on `features/people/`'s internals, both worse than the direct `core/` placement given this feature's genuinely simultaneous five-feature scope |
