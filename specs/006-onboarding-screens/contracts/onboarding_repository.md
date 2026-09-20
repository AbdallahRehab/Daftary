# Contract: OnboardingRepository

This feature has no external/network API (local-only — see spec Assumptions). The equivalent contract boundary is the **Domain repository interface**, which Presentation (via `OnboardingCubit`) and Data (via `OnboardingRepositoryImpl`) both depend on, per constitution Principle VI. Both methods return `Either<Failure, T>` (Principle VII) — no method throws to the caller.

```dart
abstract class OnboardingRepository {
  /// Whether onboarding has already been completed or skipped on this
  /// install. `Right(false)` covers both "no row exists yet" and an
  /// explicit `isComplete = false` row (data-model.md: the latter is never
  /// actually written by this feature, but the repository still reports it
  /// correctly if one is ever present).
  Future<Either<Failure, bool>> isOnboardingComplete();

  /// Marks onboarding complete (finished normally, explicitly skipped, or
  /// auto-detected via FR-010a — the repository does not distinguish the
  /// reason, per data-model.md's deliberately minimal flag). Idempotent:
  /// calling it again after it is already `true` is a no-op success.
  Future<Either<Failure, Unit>> completeOnboarding();
}
```

**Failure modes**: `CacheFailure` (local DB I/O error — the only realistic failure for a local single-row read/upsert), `UnknownFailure`.

**Callers**:
- `ResolveOnboardingStatus` (use case, below) calls `isOnboardingComplete()` and, on its FR-010a auto-detect branch, `completeOnboarding()`.
- `OnboardingCubit` calls `completeOnboarding()` directly (no wrapper use case) when the user finishes the last screen or taps Skip — see plan.md's Constitution Check (Principle V) for why this is not a use case, matching existing precedent (`TransactionFormCubit`/`ArchivedPeopleCubit` also call a repository directly alongside use cases).

---

## Contract: ResolveOnboardingStatus (use case)

Coordinates three repositories to answer one question at startup: should this launch show onboarding, or go straight to the main app? This is the answer to "should FR-010a's existing-data check be a method on `OnboardingRepository` itself, or a separate use case coordinating both repositories?" — see research.md Decision 2 for the full rationale: it is a dedicated use case, because `OnboardingRepository` must not reach into `people`'s/`transactions`' own tables.

Note: this `OnboardingGateStatus` is a domain-layer type with only two values — it never represents a "still loading" state, since `call()` always resolves synchronously against already-awaited repository calls. It is distinct from the presentation-layer `OnboardingLoadStatus` enum (`resolving` / `showOnboarding` / `mainApp`) that `OnboardingCubit`'s `OnboardingState` uses — the extra `resolving` value there covers the brief startup window before `call()` returns, which has no equivalent at the domain layer. Do not conflate the two enums.

```dart
enum OnboardingGateStatus { showOnboarding, mainApp }

@injectable
class ResolveOnboardingStatus {
  ResolveOnboardingStatus(
    this._onboardingRepository,
    this._peopleRepository,
    this._transactionsRepository,
  );

  final OnboardingRepository _onboardingRepository;
  final PeopleRepository _peopleRepository;
  final TransactionsRepository _transactionsRepository;

  /// FR-001/FR-009/FR-010a decision logic:
  /// 1. If onboarding is already marked complete → mainApp.
  /// 2. Else, if any Person or MoneyTransaction record already exists
  ///    (FR-010a — active or archived people; including soft-deleted
  ///    transactions) → auto-complete onboarding, then → mainApp.
  /// 3. Else → showOnboarding (nothing is persisted yet; see data-model.md
  ///    State Transitions — the row is only ever written at the moment of
  ///    actual completion).
  ///
  /// On any Failure from step 1 or 2, fails open to mainApp rather than
  /// blocking startup (research.md Decision 7) — never returns a Failure
  /// itself; the caller (OnboardingCubit) always gets a definite status.
  Future<OnboardingGateStatus> call();
}
```

**Not `Either`-wrapped on return**: unlike every other use case/repository method in this codebase, `call()` deliberately never surfaces a `Failure` to its caller — research.md Decision 7 requires failing open to `mainApp` on any internal error, so the use case itself absorbs and logs the failure rather than pushing the fail-open policy decision up into `OnboardingCubit`. This keeps the "never block the user behind an unresolvable gate" rule enforced in exactly one place.

**Callers**: `OnboardingCubit.initialize()`, awaited in `main.dart` before `runApp` (alongside the existing `SettingsCubit.initialize()` await).

---

## Contract additions to existing repositories

Two new methods, one on each existing repository, both feeding step 2 of `ResolveOnboardingStatus` above. Each is implemented against that feature's own existing Dao (no new Dao) with a cheap `LIMIT 1`-style existence query — never a full list fetch.

```dart
// lib/features/people/domain/repositories/people_repository.dart (addition)
abstract class PeopleRepository {
  // ...existing methods unchanged...

  /// FR-010a: whether at least one Person record exists at all — active
  /// OR archived (unlike searchActivePeople, which excludes archived).
  /// An archived-only install still proves prior real use.
  Future<Either<Failure, bool>> hasAnyPerson();
}
```

```dart
// lib/features/transactions/domain/repositories/transactions_repository.dart (addition)
abstract class TransactionsRepository {
  // ...existing methods unchanged...

  /// FR-010a: whether at least one MoneyTransaction record exists at all —
  /// including soft-deleted rows (deletedAt IS NOT NULL). A since-deleted
  /// transaction still proves the app was previously used, matching the
  /// existing precedent in PeopleDao.countTransactionsForPerson.
  Future<Either<Failure, bool>> hasAnyTransaction();
}
```

**Failure modes for both**: `CacheFailure`, `UnknownFailure` — same as every other method on these repositories.

**Why additions to existing repositories rather than a new cross-feature query**: keeps each feature the sole owner of its own table (Principle VI/II); `ResolveOnboardingStatus` composes the two booleans rather than either repository knowing about the other's schema.
