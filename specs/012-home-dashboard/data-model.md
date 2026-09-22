# Phase 1 Data Model: Home Dashboard

This feature introduces **no new database table, column, or persisted field** (spec Key Entities, FR-016). Everything below is an in-memory Domain/Presentation value object, never written to `AppDatabase`.

## Entity: DashboardSnapshot (Domain, in-memory only)

The result of `GetDashboardSnapshot`, composing the two existing aggregates plus the derived combined-empty signal. Never persisted; recomputed on every load/refresh/retry.

| Field | Type | Notes |
|---|---|---|
| `overview` | `Either<Failure, OverviewSummary>` | The existing `transactions` aggregate, untouched (data-model owned by spec 001). |
| `finance` | `Either<Failure, FinanceSummary>` | The existing `finance` aggregate for "this month" (data-model owned by spec 007). |
| `hasAnyFinanceEntry` | `bool` | From `FinanceRepository.getHistory(limit: 1)` — used only for the combined-empty determination (research.md Decision 3), never displayed directly. |

**Note**: `DashboardSnapshot` is intentionally *not* an `Equatable` entity with a single flattened shape — it is returned once by `GetDashboardSnapshot.call()` and immediately unpacked into `DashboardState`'s own fields (below), which is the actual value object the UI observes. Keeping the two `Either`s separate at this boundary (rather than collapsing into one combined failure) is what makes FR-003's independent-retry requirement possible downstream.

## Entity: DashboardState (Presentation, in-memory only)

The `DashboardCubit`'s immutable state (`Equatable`, `copyWith()`), per constitution Principle IV and research.md Decision 2.

| Field | Type | Notes |
|---|---|---|
| `overviewStatus` | `LoadStatus` (`loading` \| `success` \| `failure`) | Independent of `financeStatus`. |
| `overviewSummary` | `OverviewSummary?` | Populated once `overviewStatus == success`. |
| `overviewError` | `String?` | Populated once `overviewStatus == failure`; a localized, user-friendly message (constitution Principle VII — never a raw exception string). |
| `financeStatus` | `LoadStatus` (`loading` \| `success` \| `failure`) | Independent of `overviewStatus`. |
| `financeSummary` | `FinanceSummary?` | Populated once `financeStatus == success`. |
| `financeError` | `String?` | Populated once `financeStatus == failure`. |
| `isCombinedEmpty` | `bool` | Set once, on first successful load of *both* aggregates, from `GetDashboardSnapshot`'s zero-people/zero-finance-entries determination (research.md Decision 3). Never recomputed mid-partial-error (a partial-error state is not an empty state — it is its own distinct rendering, per FR-003). |

**Derived getters** (never separately stored, per constitution Principle IV — "avoid redundant state"):
- `isFullyLoading` = `overviewStatus == loading && financeStatus == loading` (FR-002's initial loading gate).
- `isFullFailure` = `overviewStatus == failure && financeStatus == failure` (FR-004's full-screen error state).
- `isAnyPartialError` = exactly one of the two statuses is `failure` while the other is `success` (FR-003's independent inline-error-per-card state).

**State transitions**: `loading → {success, failure} independently per side → [retryOverview()/retryFinance() → loading (that side only) → {success, failure}]*`. There is no "both must succeed together" gate — each side's lifecycle is fully independent, matching the two-source-of-truth nature of the underlying data (research.md Decision 2).

## Relationship to existing entities

- **`OverviewSummary`/`PersonSummary`** (owned by `transactions`, spec 001): read-only, unchanged. `DashboardSnapshot`/`DashboardState` hold a reference to the same instance `GetOverview` already returns — never a copy, never a re-derived value.
- **`FinanceSummary`** (owned by `finance`, spec 007): read-only, unchanged. Same relationship as above.
- **No new entity is added to either `transactions` or `finance`.** This feature is a pure read-side composition layer over both.

## Value object: `LoadStatus` (shared within `dashboard`)

```dart
enum LoadStatus { loading, success, failure }
```

Deliberately not reused from `OverviewStatus` (the pre-existing `transactions/presentation/cubit/overview_state.dart` enum being replaced by this feature) — `OverviewStatus` is removed as part of this feature's relocation (research.md Decision 1), and `LoadStatus` is its direct successor, now used twice (once per aggregate) within the same `DashboardState` rather than once for the whole screen.
