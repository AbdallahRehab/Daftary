# Phase 1 Data Model: Reports & Data/Privacy Controls

This feature introduces **no new database table**. It reads across every existing table (`People`, `MoneyTransactions`, `TransactionAuditEntries` untouched; `FinanceEntries`/`FinanceCategories` from feature 007; `AppSettings`, `OnboardingStatus`) and, for deletion, wipes rows from all of them — but adds no column and no table of its own.

## Entity: SpendingTrendPoint (Domain, in-memory only)

One month's worth of the Reports trend (FR-001). Produced by `GetSpendingTrend`, never persisted.

| Field | Type | Notes |
|---|---|---|
| `period` | `DateRange` | One calendar month, reusing 007's existing period-range shape (research.md 007 Decision 6). |
| `totalIncomeMinorUnits` | `int` | From that month's `FinanceSummary.totalIncomeMinorUnits`, unchanged. |
| `totalExpenseMinorUnits` | `int` | From that month's `FinanceSummary.totalExpenseMinorUnits`, unchanged. |
| `netMinorUnits` | `int` | From that month's `FinanceSummary.netMinorUnits`, unchanged. |

**Note**: `SpendingTrendPoint` is a thin re-shaping of `FinanceSummary` (007) for a specific month, purely for the trend chart's convenience — it never recomputes anything `GetSummary` didn't already compute (FR-003).

## Entity: ExportResult (Domain, in-memory only)

The outcome of one `ExportUserData` call.

| Field | Type | Notes |
|---|---|---|
| `filePath` | `String` | Path to the generated `.csv` in the app's own sandboxed cache/temp directory (never uploaded by the app itself, FR-012). |
| `generatedAt` | `DateTime` | When the export was produced. |
| `sectionCounts` | `Map<String, int>` | Row count per section (`People`, `Transactions`, `FinanceEntries`, `Categories`, `Settings`) — used by tests (SC-003) and can optionally be surfaced to the user as a completeness summary. |

**Validation rules**: `filePath` MUST point to a file that exists and is non-empty (even an all-empty-sections export still has the section markers/headers, satisfying FR-008's "valid file, not an error" requirement — see Edge Cases).

## Entity: DeleteConfirmationInput (Presentation, in-memory only)

The typed-confirmation gate's own local state (research.md Decision 8) — never persisted, exists only for the duration of the confirmation screen.

| Field | Type | Notes |
|---|---|---|
| `typedPhrase` | `String` | What the user has typed so far. |
| `expectedPhrase` | `String` | The localized phrase the user must match exactly (e.g. the localized word for "DELETE"), sourced from `l10n`. |
| `isConfirmationEnabled` | `bool` | Derived: `typedPhrase.trim() == expectedPhrase` — never independently settable, always recomputed from the two fields above (constitution Principle IV — no redundant stored state). |

## New Domain capability: `DataWipeRepository`

Not an entity, but the one genuinely new repository interface this feature adds (research.md Decision 5) — documented here since it's the single new piece of the data model's *write* surface.

```dart
abstract class DataWipeRepository {
  /// Deletes every row from every existing table (People, MoneyTransactions,
  /// TransactionAuditEntries, FinanceEntries, FinanceCategories, AppSettings,
  /// OnboardingStatus) as one atomic operation (FR-018) — either every table
  /// ends up empty, or (on any failure) every table is left completely
  /// unchanged. Never a partial wipe.
  Future<Either<Failure, Unit>> deleteAllUserData();
}
```

## Relationship to existing entities

- **`OverviewSummary`/`PersonSummary`/`MoneyTransaction`** (owned by `transactions`): read-only for export, untouched otherwise.
- **`FinanceSummary`/`CategoryBreakdownItem`/`FinanceEntry`/`Category`** (owned by `finance`, feature 007): read-only for both Reports and export, untouched otherwise.
- **`AppLanguage`/`AppThemeMode`** (owned by `settings`): read-only for export.
- **`OnboardingStatus`** (owned by `onboarding`): read (indirectly, via `ResolveOnboardingStatus`) after a successful delete, per research.md Decision 6 — this feature never writes to it directly; `deleteAllUserData()` clears the row, and `onboarding`'s own existing logic takes it from there.
- **No new entity is added to `transactions`, `finance`, `people`, or `settings`.** This feature is a pure read/administer layer over all of them.
