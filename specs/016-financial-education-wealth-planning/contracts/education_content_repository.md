# Contract: EducationContentRepository

Local-only Domain/Data boundary over bundled static assets (research.md Decision 1) — not a network API contract (see 011's `savings_repository.md` for why this codebase replaces network contracts with a local one). All methods return `Either<Failure, T>` despite reading static bundled assets, since a missing/malformed bundled asset is still a real (if rare) failure mode worth surfacing typed, per constitution Principle VII.

```dart
abstract class EducationContentRepository {
  /// All categories for the currently active app language (FR-001/FR-003),
  /// in their authored display order.
  Future<Either<Failure, List<EducationCategory>>> getCategories();

  /// One category by id, including its ordered article summaries
  /// (id/title/shortDescription — not full bodies, keeping the category
  /// list view lightweight). Returns ContentNotFoundFailure for an unknown
  /// id (should not occur in practice since ids are internal navigation
  /// constants, not user input, but handled per constitution Principle VII).
  Future<Either<Failure, EducationCategory>> getCategory(String categoryId);

  /// One full article by id, including its bodySections (FR-003).
  Future<Either<Failure, EducationArticle>> getArticle(String articleId);
}
```

## Contract: CompoundGrowthCalculator (pure Domain service — no `Either`, no I/O, no repository dependency at all per research.md Decision 3)

```dart
abstract class CompoundGrowthCalculator {
  /// FR-007/FR-008/FR-009/FR-010. Computes futureValue/totalContributed/
  /// totalGrowth per research.md Decision 4's formula. Returns a
  /// CalculatorValidationResult<CompoundGrowthResult> (see below) rather
  /// than throwing — the caller (Cubit) maps a failed validation to a
  /// clear, localized inline error (FR-008), never a thrown exception
  /// reaching the UI (constitution Principle VII, applied consistently
  /// even for a pure, non-I/O service).
  CalculatorValidationResult<CompoundGrowthResult> calculate({
    required int monthlyContributionMinorUnits,
    required double annualRatePercent,
    required int years,
  });
}
```

## Contract: DoublingTimeCalculator (pure Domain service)

```dart
abstract class DoublingTimeCalculator {
  /// FR-011. Rejects annualRatePercent <= 0.
  CalculatorValidationResult<DoublingTimeResult> calculate({
    required double annualRatePercent,
  });
}
```

## Contract: SavingsRateCalculator (pure Domain service)

```dart
abstract class SavingsRateCalculator {
  /// FR-012. Rejects incomeMinorUnits <= 0. Accepts (never clamps)
  /// savingsAmountMinorUnits > incomeMinorUnits.
  CalculatorValidationResult<SavingsRateResult> calculate({
    required int incomeMinorUnits,
    required int savingsAmountMinorUnits,
  });
}
```

## Shared Value Object: CalculatorValidationResult<T>

```dart
/// Either a computed T on success, or a typed validation problem —
/// deliberately NOT an Either<Failure, T> from core/error, since these are
/// pure, side-effect-free input-validation outcomes local to this feature's
/// calculators, not repository/I/O failures.
class CalculatorValidationResult<T> {
  const CalculatorValidationResult.success(this.value) : problem = null;
  const CalculatorValidationResult.invalid(this.problem) : value = null;

  final T? value;
  final CalculatorInputProblem? problem; // e.g. nonPositiveAmount,
                                          // negativeRate, nonPositiveDuration,
                                          // nonPositiveIncome
}
```

## Contract: GetPrefillableSavingsGoalAmount (Domain use case — the ONE call site touching another feature's repository)

```dart
/// FR-014. Read-only. Returns null (not a Failure) when SavingsRepository
/// (011) is unavailable in this build, or the user has zero active goals —
/// both are ordinary "nothing to pre-fill" states, not errors. Returns the
/// single most-recently-created active goal's current saved amount
/// (research.md/spec.md: "purely as a numeric convenience"), NEVER passed
/// into CompoundGrowthCalculator directly — the Presentation Cubit copies
/// this value into the calculator FORM's starting text field, which the
/// user may freely overwrite before the calculation itself runs.
abstract class GetPrefillableSavingsGoalAmount {
  Future<int?> call();
}
```

**Failure modes**: `ContentNotFoundFailure` (unknown category/article id — should not occur given ids are internal constants), `ContentAssetLoadFailure` (a bundled JSON asset failed to parse — a build-time content-authoring bug, not a runtime user-facing scenario in practice, but handled per Principle VII), `CacheFailure`, `UnknownFailure`. Calculator services never return a `Failure` — see `CalculatorValidationResult<T>` above.

**Idempotency note**: Not applicable — this feature has zero mutation methods anywhere (no create/edit/delete use case exists at all, per plan.md Constitution Check XI: N/A).

**Cross-feature note**: `EducationContentRepository` and all three calculator services call no other feature's repository — the entire content/calculator core of this feature has zero cross-feature dependencies, matching 011-savings-goals' own "cleanest boundary" precedent. `GetPrefillableSavingsGoalAmount` is the single, deliberately narrow, explicitly read-only exception, isolated in its own use case rather than blended into any calculator (research.md Decision 3).
