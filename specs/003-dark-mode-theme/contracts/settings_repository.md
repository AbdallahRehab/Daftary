# Contract: `SettingsRepository` (extended)

This feature has no external/network API (local-only, same as `002`). The contract
boundary remains the **Domain repository interface**, which Presentation (via use cases)
and Data (`SettingsRepositoryImpl`) both depend on, per constitution Principle VI. This is
the same interface `002-localization-language-switch` introduced
(`lib/features/settings/domain/repositories/settings_repository.dart`) — this feature
*extends* it with two new methods; it does not introduce a second repository, per spec
Assumptions ("reuses the existing state-management and settings-persistence architecture").

```dart
abstract class SettingsRepository {
  // --- existing (002), unchanged ---
  Future<Either<Failure, AppLanguage?>> getLanguagePreference();
  Future<Either<Failure, Unit>> setLanguagePreference(AppLanguage language);

  // --- NEW (003) ---

  /// The persisted theme mode choice, or `null` if the user has never
  /// explicitly chosen one yet (data-model.md: no row, or a row that
  /// predates this feature's `themeMode` column). The caller
  /// (`SettingsCubit`) treats `null` as `AppThemeMode.system`, per FR-011.
  Future<Either<Failure, AppThemeMode?>> getThemeModePreference();

  /// Persists [mode] as the user's explicit choice. The caller
  /// (`ChangeThemeMode`) owns the retry-once-then-flag-non-blocking-failure
  /// policy (mirroring `002`'s FR-008 approach for language, research.md
  /// Decision 9) — this method itself simply reports success/failure of a
  /// single write attempt.
  Future<Either<Failure, Unit>> setThemeModePreference(AppThemeMode mode);
}
```

**Failure modes**: `CacheFailure` (local DB I/O error), `UnknownFailure` — unchanged from
`002`, no new failure types introduced.

---

## Contract: `GetThemeModePreference` (use case)

```dart
@injectable
class GetThemeModePreference {
  const GetThemeModePreference(this._repository);
  final SettingsRepository _repository;

  Future<Either<Failure, AppThemeMode?>> call() =>
      _repository.getThemeModePreference();
}
```

Not a bare passthrough in isolation, but — like `GetLanguagePreference` — exists so the
caller (`SettingsCubit.initialize()`) combines it with the FR-011 first-launch default
resolution rather than every call site re-deriving that policy.

## Contract: `ChangeThemeMode` (use case)

```dart
@injectable
class ChangeThemeMode {
  const ChangeThemeMode(this._repository);
  final SettingsRepository _repository;

  /// Returns whether persistence ultimately succeeded (after the retry, if
  /// the first attempt failed), so the caller can decide whether to
  /// surface a notice. Mirrors `ChangeLanguage` exactly (research.md
  /// Decision 9).
  Future<bool> call(AppThemeMode mode) async {
    final first = await _repository.setThemeModePreference(mode);
    if (first.isRight()) return true;
    final retry = await _repository.setThemeModePreference(mode);
    return retry.isRight();
  }
}
```

---

## Contract: `SettingsCubit` (extended)

Root-scoped, unchanged lifetime/provisioning from `002` (provided once above
`MaterialApp.router` in `main.dart`). New public surface:

```dart
class SettingsCubit extends Cubit<SettingsState> {
  // --- existing (002), unchanged ---
  Future<void> initialize();               // now also resolves themeMode (see below)
  Future<void> changeLanguage(AppLanguage language);

  // --- NEW (003) ---
  Future<void> changeThemeMode(AppThemeMode mode);
}
```

`initialize()`'s contract is extended (not replaced): it must complete before the app's
first frame (same as `002`'s T025 constraint in `main.dart`), and now resolves *both*
`state.language` and `state.themeMode` before returning — `main.dart` calls it exactly
once, unchanged.

`changeThemeMode(mode)`:
1. Emits `state.copyWith(themeMode: mode, isThemeModePersistFailing: false)` immediately
   (FR-004: live update, no restart, no waiting on persistence).
2. Persists via `ChangeThemeMode` (retry-once policy).
3. On ultimate failure, emits `state.copyWith(isThemeModePersistFailing: true)` — the
   session's theme choice is never rolled back or blocked by a persistence failure.

## Contract: theme tokens (design-system boundary)

See `contracts/theme_tokens.md` for the `ThemeData`/`AppFinanceColors` contract every
screen and shared component in the app depends on.
