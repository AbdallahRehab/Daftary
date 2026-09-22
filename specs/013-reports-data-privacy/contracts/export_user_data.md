# Contract: ExportUserData

Local-only Domain use case, depending only on already-existing repository interfaces (research.md Decision 2) — introduces zero new abstract methods on `PeopleRepository`, `TransactionsRepository`, `FinanceRepository`, `CategoryRepository`, or `SettingsRepository`.

```dart
@injectable
class ExportUserData {
  const ExportUserData(
    this._peopleRepository,
    this._transactionsRepository,
    this._financeRepository,
    this._categoryRepository,
    this._settingsRepository,
  );

  final PeopleRepository _peopleRepository;
  final TransactionsRepository _transactionsRepository;
  final FinanceRepository _financeRepository;
  final CategoryRepository _categoryRepository;
  final SettingsRepository _settingsRepository;

  /// Composes every existing read method (research.md Decision 2) into one
  /// section-delimited CSV file (research.md Decision 4), written to the
  /// app's own sandboxed cache directory. Never transmits data anywhere
  /// (FR-012) — this call only produces a local file; sharing it is a
  /// separate, explicit user action (ShareService, below).
  Future<Either<Failure, ExportResult>> call() async {
    // 1. People: searchActivePeople() + searchArchivedPeople(), concatenated
    // 2. Transactions: getPersonHistory(personId) for each person above, flattened
    // 3. FinanceEntries: getHistory(filter: null, limit: 500, offset: N) paged to completion
    // 4. Categories: getCategories(type: income/expense, includeArchived: true)
    // 5. Settings: getLanguagePreference() + getThemeModePreference()
    // ... serialize each section to its own CSV block, write one file, return ExportResult
  }
}
```

**Behavioral guarantees**:
- Read-only — never mutates any table.
- Produces a structurally valid file even when every section is empty (FR-008) — section markers and header rows are always written, only the data rows are absent.
- A failure partway through composition (e.g., one repository call fails) surfaces as a single `Either.left(Failure)` — no partially-written file is left in the app's cache in a state that could be mistaken for a complete export (FR-011); the use case writes to a temporary path and only finalizes/renames it to the returned `ExportResult.filePath` on full success.

## Contract: ShareService

The Domain-facing interface isolating the `share_plus` platform call (constitution Principle VI — a swappable platform capability behind an abstraction), per plan.md's Project Structure.

```dart
abstract class ShareService {
  /// Hands [filePath] to the OS's native share/save sheet (FR-010). Returns
  /// success once the OS sheet has been presented — NOT once the user has
  /// necessarily completed a share (dismissing the sheet is a normal,
  /// non-error outcome, per spec Edge Cases).
  Future<Either<Failure, Unit>> shareFile({
    required String filePath,
    String? subject,
  });
}
```

`SharePlusService` (Data) is the only file in the codebase that imports `package:share_plus/share_plus.dart`, calling `Share.shareXFiles([XFile(filePath)], subject: subject)` and mapping any platform exception to a typed `Failure`.
