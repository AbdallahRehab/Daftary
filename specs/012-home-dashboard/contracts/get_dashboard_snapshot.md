# Contract: GetDashboardSnapshot

This feature has no external/network API (local-only, matching the rest of the app). The equivalent contract boundary is this **Domain use case**, which `DashboardCubit` (Presentation) depends on via DI, per constitution Principle XIV. It depends only on other use cases — `GetOverview` (from `transactions/domain/usecases/`) and `GetFinanceSummary`/`GetFinanceHistory` (from `finance/domain/usecases/`, feature 007) — never on a repository directly (research.md Decision 1).

```dart
/// Coordinates the two independent aggregates a Home screen needs
/// (FR-001/FR-002), run in parallel (`Future.wait`), and determines the
/// single combined first-run empty-state signal (FR-005, research.md
/// Decision 3). Never throws — each side's Either is returned as-is so the
/// caller (DashboardCubit) can treat them fully independently (FR-003).
@injectable
class GetDashboardSnapshot {
  const GetDashboardSnapshot(
    this._getOverview,
    this._getFinanceSummary,
    this._getFinanceHistory,
  );

  final GetOverview _getOverview;
  final GetFinanceSummary _getFinanceSummary;
  final GetFinanceHistory _getFinanceHistory;

  /// [period] is "this month" (research.md 007 Decision 6's period-range
  /// math, reused unchanged) unless the caller supplies a different one —
  /// Home always calls this with "this month."
  Future<DashboardSnapshot> call({required DateRange period}) async {
    final results = await Future.wait([
      _getOverview(),
      _getFinanceSummary(period),
      // limit: 1, no filter — existence check only, never rendered
      // directly (research.md Decision 3); errors here are treated as
      // "unknown, assume not empty" so a transient failure of this cheap
      // check never blocks or misrepresents the two real aggregates above.
      _getFinanceHistory(limit: 1, offset: 0),
    ]);
    // ... unpack into DashboardSnapshot(overview, finance, hasAnyFinanceEntry)
  }
}
```

**Behavioral guarantees**:
- The three calls run concurrently (`Future.wait`), never sequentially — this is the "genuine parallel coordination" that justifies this use case's existence under constitution Principle V, and is what keeps SC-001's 1-second load target achievable (two round-trips in parallel, not stacked).
- A failure in `_getOverview()` never prevents `_getFinanceSummary()`'s result (or vice versa) from being returned — both `Either`s are always present in the result, regardless of which succeeded.
- A failure in the `_getFinanceHistory(limit: 1)` existence check does not fail the whole call — it degrades to "assume not empty" (never incorrectly shows the combined first-run empty state to a returning user due to a transient error on the cheap check).
- Calling this again (e.g. on pull-to-refresh, or `DashboardCubit.retryOverview()`/`retryFinance()`) is always safe and side-effect-free — this is a pure read coordinator, never a mutation.

## Contract: DashboardCubit's retry surface

Not a repository/use-case contract in the traditional sense, but the Presentation-layer contract `HomePage` depends on for FR-003's independent-retry requirement:

```dart
abstract class DashboardCubit {
  /// Initial load — both aggregates, in parallel, via GetDashboardSnapshot.
  Future<void> load();

  /// Pull-to-refresh (FR-012) — identical to load(), re-fetches both.
  Future<void> refresh();

  /// Re-fetches ONLY the overview aggregate (FR-003); financeStatus/
  /// financeSummary/financeError are untouched by this call.
  Future<void> retryOverview();

  /// Re-fetches ONLY the finance aggregate (FR-003); overviewStatus/
  /// overviewSummary/overviewError are untouched by this call.
  Future<void> retryFinance();
}
```
