# Phase 0 Research: Multi-Currency Support

## 1. Bundled static currency catalog, not a fetched ISO 4217 dataset

**Decision**: The `Currency` catalog (code, symbol, display name, minor-unit precision) is bundled as a small static Dart/JSON data file under `lib/core/money/` (or `lib/features/currency/data/content/`), shipped with the app, covering the starter set (EGP + USD/EUR/SAR/AED/GBP per spec.md Assumptions) — never fetched from any external ISO-4217 reference API.

**Rationale**: This directly mirrors 016-financial-education-wealth-planning's research.md Decision 1 (bundled static content over a remote fetch) for the same underlying reason: this feature's entire premise (FR-014, "no network call anywhere") would be immediately contradicted by fetching even a static reference dataset from the network at runtime. A hardcoded, version-controlled, code-reviewed list of ~6 currencies is trivial to maintain and requires no infrastructure.

**Alternatives considered**: Fetching a currency-code reference list from a public API at first run — rejected outright, violates FR-014; letting the user type an arbitrary free-text currency code — rejected per spec.md Assumptions ("not assumed here... low-risk future extension"), since an unvalidated free-text code would make the bundled catalog's symbol/precision metadata inapplicable and complicate the exchange-rate UI for no clear near-term benefit.

## 2. `Money` gains a `currency` field directly, rather than a separate wrapping type

**Decision**: `core/money/Money` itself gains a `currency` field (`Money({required int minorUnits, required Currency currency})`), rather than introducing a new `CurrencyAmount(Money amount, Currency currency)` wrapper type alongside the existing currency-less `Money`.

**Rationale**: A wrapping type would leave two parallel money representations in the codebase (`Money` for "not yet migrated" call sites and `CurrencyAmount` for migrated ones) throughout this feature's necessarily incremental five-feature rollout, inviting exactly the kind of silent-EGP-assumption bug this feature exists to eliminate — a `Money` used somewhere that should have been a `CurrencyAmount` would compile fine and silently keep behaving as EGP-only. Extending `Money` itself means every existing call site that constructs a `Money` is a compile error until it supplies a currency, forcing an exhaustive, compiler-verified migration across 001/007/008/010/011 rather than relying on code review alone to catch every missed call site.

**Alternatives considered**: The wrapping-type approach — rejected for the silent-gap risk above, despite it being a smaller, more isolated initial diff; making `currency` optional/nullable on `Money` with an EGP default — rejected, this is exactly the "ambiguous, ever-implicit EGP" pattern FR-002/FR-015 exist to eliminate for anything other than the one-time migration itself, and would let new code accidentally omit currency by relying on the default.

## 3. One coordinated migration covering all five features' tables, not five separate ones

**Decision**: A single `AppDatabase.schemaVersion` increment and a single `onUpgrade` migration step (`vNN_currency_support.dart`) adds the currency column(s) to `MoneyTransactions` (001), `FinanceEntries` (007), the occasion-contribution table (008), `Budgets` (010), and `SavingsGoals`/`SavingsContributions` (011) together, plus creates `PrimaryCurrencySetting`/`ExchangeRates` — but each table's change is implemented, reviewed, and unit-tested as an independently identifiable step within that one migration file (spec.md's own Assumptions: "never a single undifferentiated 'add currency everywhere' change").

**Rationale**: These six changes are interdependent in a way 015/016/017's purely additive tables are not — a currency column on `MoneyTransactions` with no `Currency`/`ExchangeRate` catalog yet existing to reference would be meaningless, and shipping them as five separate app releases would mean the app spends time in an inconsistent state (some features currency-aware, others not) that this feature's own FR-008 ("no aggregate screen in the app is exempt from this feature's rules") explicitly forbids. Bundling them into one migration is the only way to satisfy FR-008 atomically. Treating each table's change as independently tested (not independently *shipped*) is what satisfies the constitution's Financial Domain Override without requiring five separate releases.

**Alternatives considered**: Five separate schema-version bumps, one per feature, released incrementally — rejected, would leave the app in a self-contradictory state (e.g. Budgets currency-aware while Savings Goals isn't) for however long the incremental rollout takes, violating FR-008's "no exemptions" requirement; a single undifferentiated migration function with no per-table test isolation — rejected per spec.md's own explicit Assumption against exactly this.

## 4. Rounding rule: round-half-up to the target currency's smallest unit

**Decision**: `CurrencyConverter.convert()` computes `targetMinorUnits = round(sourceMinorUnits × rate × (targetMinorUnitsPerMajor / sourceMinorUnitsPerMajor))` using round-half-up (never round-half-even/banker's rounding, never truncation), consistent with spec.md's own Assumptions.

**Rationale**: Round-half-up is the most broadly understood, least-surprising rounding convention for a general audience-facing financial figure (as opposed to round-half-even, which is a more specialized convention typically reserved for repeated-aggregate statistical contexts) — and, critically, applying exactly one documented rule everywhere a conversion occurs (never a different rule on different screens) is what FR-013 requires as a hard, testable constraint, not merely a suggestion.

**Alternatives considered**: Truncation (round-down) — rejected, would make every converted total a slight underestimate, arguably a worse user-facing surprise than a consistent, well-understood rounding convention; round-half-even — rejected as less intuitive to a general user reading a single converted total (its benefit — reducing cumulative bias across *many* independent roundings — is not the primary concern here, since each conversion is independently, transparently computed and displayed, not silently accumulated across a long unseen chain).

## 5. Currency-aware formatter extends `EgpFormatter`'s existing pattern, never replaces its EGP output

**Decision**: A new `CurrencyFormatter` (parameterized by `Currency`, superseding direct use of `EgpFormatter` at new call sites) is added following `EgpFormatter`'s exact existing structure (locale-aware, cached `NumberFormat` per locale, Western-digit-guarantee post-processing) — `EgpFormatter` itself may be kept as a thin, byte-identical-output wrapper around `CurrencyFormatter(currency: egp)` for any call site not yet touched by this feature's migration, guaranteeing FR-015/SC-008's "byte-for-byte identical" requirement is structurally true, not just asserted.

**Rationale**: This is the direct implementation of spec.md's Assumptions ("reuses and extends the app's existing locale-aware number-formatting approach... rather than inventing a second formatting mechanism") and of FR-015/SC-008's explicit "zero behavior change for an EGP-only user" requirement — by making `EgpFormatter`'s own output byte-identical (a thin wrapper, not a reimplementation), there is no risk of the currency-aware formatter's shared code path subtly changing EGP's own number formatting (spacing, thousands separators, decimal digit count) as a side effect of adding currency-symbol support.

**Alternatives considered**: A wholly separate `CurrencyFormatter` implementation independent of `EgpFormatter`'s existing logic — rejected, risks exactly the kind of subtle formatting drift for existing EGP users that SC-008's regression requirement exists to catch; deleting `EgpFormatter` outright and replacing every call site in one sweep — rejected as unnecessarily coupling this feature's rollout to touching every single existing display call site in one atomic change, when a thin backward-compatible wrapper achieves the same guarantee with far less blast radius per individual feature migration step (research.md Decision 3's per-feature independence).

## 6. `CurrencyConverter` is a pure Domain service with zero repository dependency

**Decision**: `CurrencyConverter` takes the `ExchangeRate`(s) it needs as plain method parameters (already fetched by its caller), never queries `CurrencyRepository`/`AppDatabase` itself — mirroring 011-savings-goals' `SavingsCalculator` and 016-financial-education-wealth-planning's three calculator services (both already-established precedents in this codebase for "pure, deterministic, I/O-free Domain arithmetic service").

**Rationale**: Consistent with this codebase's now-repeated pattern (011, 016) for isolating deterministic financial arithmetic as exhaustively unit-testable pure functions — a converter that cannot itself reach into the database cannot silently develop an inconsistent read path from whatever each of the five aggregation call sites uses to fetch the current `ExchangeRate` set, and is trivially testable with fixture rate data with no DB setup at all.

**Alternatives considered**: `CurrencyConverter` as a full use case that fetches its own rates via `CurrencyRepository` — rejected, would mean five different call sites (001/007/008/010/011's own aggregation use cases) each separately depend on and mock `CurrencyRepository` just to test their own currency-conversion behavior, when a pure function parameterized by already-fetched rates is simpler to compose and test in isolation, exactly the reasoning 011/016 already established in this codebase.
