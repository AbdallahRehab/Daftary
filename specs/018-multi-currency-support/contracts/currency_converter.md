# Contract: CurrencyConverter (pure Domain service — no `Either`, no I/O, no repository dependency, research.md Decision 6)

```dart
abstract class CurrencyConverter {
  /// Converts [amount] into [targetCurrency] using [rates] (already
  /// fetched by the caller — this service never queries CurrencyRepository
  /// itself). Returns a typed ConversionResult rather than throwing or
  /// silently defaulting to 1:1 (FR-009):
  ///  - If amount.currency == targetCurrency: always succeeds trivially
  ///    (no rate needed at all — same-currency amounts never block).
  ///  - If a direct ExchangeRate(amount.currency -> targetCurrency) exists
  ///    in [rates]: converts using it, rounding per research.md Decision 4
  ///    (round-half-up to targetCurrency's smallest unit, FR-013).
  ///  - Otherwise: returns ConversionResult.rateUnavailable(amount.currency)
  ///    — NEVER a 1:1 fallback, NEVER a silently-omitted/zeroed amount.
  ConversionResult convert({
    required Money amount,
    required Currency targetCurrency,
    required List<ExchangeRate> rates,
  });

  /// Convenience for the common aggregation case: converts and sums a list
  /// of amounts into targetCurrency. If ANY amount's currency has no
  /// available rate (per convert()'s rules), the ENTIRE sum is reported as
  /// blocked (SumResult.blocked, carrying the specific missing
  /// currencies) rather than silently summing only the convertible subset
  /// — this is what FR-009's "the total is incomplete/blocked" behavior
  /// means concretely: partial aggregation is never presented as if it
  /// were the complete total.
  SumResult sumToTargetCurrency({
    required List<Money> amounts,
    required Currency targetCurrency,
    required List<ExchangeRate> rates,
  });
}
```

## Value Object: ConversionResult *(ephemeral)*

```dart
sealed class ConversionResult {
  const factory ConversionResult.converted(Money value) = _Converted;
  const factory ConversionResult.rateUnavailable(Currency missingRateFor) = _RateUnavailable;
}
```

## Value Object: SumResult *(ephemeral)*

```dart
sealed class SumResult {
  const factory SumResult.total(Money value) = _Total;
  const factory SumResult.blocked(List<Currency> missingRatesFor) = _Blocked;
}
```

## Contract: CurrencyRepository

Local-only Domain/Data boundary over the `PrimaryCurrencySetting`/`ExchangeRates` `drift` tables and the bundled `Currency` catalog. All methods return `Either<Failure, T>`.

```dart
abstract class CurrencyRepository {
  /// The bundled starter catalog (research.md Decision 1) — static, never
  /// changes at runtime.
  Future<Either<Failure, List<Currency>>> getSupportedCurrencies();

  /// Current primary currency (FR-005). Defaults to EGP if never set.
  Future<Either<Failure, PrimaryCurrencySetting>> getPrimaryCurrency();

  /// Sets the primary currency. The USE CASE layer (SetPrimaryCurrency,
  /// not this repository method) enforces FR-012's forced-rate check
  /// before calling this — this method itself just persists the change.
  Future<Either<Failure, Unit>> setPrimaryCurrency(String currencyCode);

  /// All currently configured exchange rates (FR-006/FR-007).
  Future<Either<Failure, List<ExchangeRate>>> getExchangeRates();

  /// Upserts a rate for (currencyCode -> relativeToCurrencyCode). Rejects
  /// rate <= 0 (InvalidExchangeRateFailure, FR-006).
  Future<Either<Failure, ExchangeRate>> setExchangeRate({
    required String currencyCode,
    required String relativeToCurrencyCode,
    required double rate,
  });

  /// Removes a previously-set rate (spec Edge Cases: reverts any
  /// dependent total to the blocked state — the underlying records are
  /// never altered).
  Future<Either<Failure, Unit>> removeExchangeRate(String currencyCode);
}
```

## Contract: SetPrimaryCurrency (Domain use case — enforces FR-012)

```dart
abstract class SetPrimaryCurrency {
  /// FR-012. Before changing the primary currency, checks whether any
  /// existing record anywhere in the app is denominated in the CURRENT
  /// primary currency (a cross-feature read — the one place in this
  /// feature that queries beyond CurrencyRepository itself, via a small
  /// read-only "is this currency used anywhere" check composed from each
  /// of 001/007/008/010/011's own repositories). If so, and no
  /// ExchangeRate exists for (oldPrimaryCurrency -> newPrimaryCurrency),
  /// returns RateRequiredForSwitchFailure(oldPrimaryCurrency) instead of
  /// completing the switch — the caller (Cubit) then prompts the user to
  /// set that rate as part of completing the change.
  Future<Either<Failure, Unit>> call({
    required String newPrimaryCurrencyCode,
    double? rateForPreviousPrimary, // optional: set in the same call if
                                     // the user provides it at switch time
  });
}
```

**Failure modes**: `InvalidExchangeRateFailure` (zero/negative rate, FR-006), `RateRequiredForSwitchFailure` (FR-012), `CurrencyNotFoundFailure` (an unknown currency code), `CacheFailure`, `UnknownFailure`. `CurrencyConverter` never returns a `Failure` — see `ConversionResult`/`SumResult` above (mirrors 016's `CalculatorValidationResult<T>` pattern of keeping pure-service outcomes separate from repository-layer `Either<Failure, T>`).

**Idempotency note**: `setExchangeRate` upserts by `(currencyCode, relativeToCurrencyCode)` — a duplicate rapid-tap simply reapplies the same end state, no duplicate-row risk given the table's own `UNIQUE` constraint (data-model.md).

**Cross-feature note**: `CurrencyRepository`/`CurrencyConverter` call no other feature's repository. `SetPrimaryCurrency` is the one use case in this entire feature that reaches into 001/007/008/010/011's repositories, and does so read-only, solely to answer "is the currency I'm about to demote from primary actually in use anywhere" for FR-012's check — mirroring 017-proactive-insights-reminders' own single-narrow-exception pattern (`GetPrefillableSavingsGoalAmount`) for isolating the one unavoidable cross-feature read as its own explicit, documented use case rather than blending it into the repository layer.
