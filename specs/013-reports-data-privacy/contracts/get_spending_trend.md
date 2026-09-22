# Contract: GetSpendingTrend

Local-only Domain use case (no external API), depending only on 007's existing `FinanceRepository` — no cross-feature coordination needed (unlike Home Dashboard's `GetDashboardSnapshot`), since Reports is entirely finance-owned data.

```dart
/// Coordinates FinanceRepository.getSummary(period) once per calendar
/// month across [monthsBack] recent months (FR-001), run concurrently
/// (Future.wait) — never sequentially, to keep SC-001's 2-second ceiling
/// achievable as history grows. Never introduces new SQL: every point in
/// the returned trend is exactly what GetSummary already computes for
/// that month.
@injectable
class GetSpendingTrend {
  const GetSpendingTrend(this._financeRepository);

  final FinanceRepository _financeRepository;

  /// [monthsBack] defaults to a reasonable rolling window (research.md
  /// Decision — presentation-layer default per spec Assumptions, e.g. 6
  /// months) ending at the current month, inclusive.
  Future<Either<Failure, List<SpendingTrendPoint>>> call({
    int monthsBack = 6,
  }) async {
    final periods = _lastNCalendarMonths(monthsBack); // pure date math
    final results = await Future.wait(
      periods.map((period) => _financeRepository.getSummary(period)),
    );
    // A single month's failure fails the whole trend (FR-005 surfaces one
    // combined error+retry for the trend as a unit — unlike Home
    // Dashboard's two-independent-aggregates design, a trend with a gap
    // in the middle is not a meaningful partial result to render).
    // ... fold results into Either<Failure, List<SpendingTrendPoint>>
  }
}
```

**Behavioral guarantees**:
- All `monthsBack` calls run concurrently, never sequentially.
- Never mutates any data — pure read composition.
- A failure on any single month's `getSummary` call fails the entire trend result (surfaced as one error+retry state, FR-005) rather than silently omitting that month, which would misrepresent the trend.

## Contract: `GetCategoryBreakdown` reuse (Reports' breakdown half)

No new use case — `ReportsCubit` calls 007's existing `FinanceRepository.getCategoryBreakdown(period)` directly for the currently-selected period (FR-002), exactly as `FinanceHistoryCubit` (007) already does. Documented here only to make explicit that Reports adds zero new aggregation logic for the breakdown half, matching FR-003.
