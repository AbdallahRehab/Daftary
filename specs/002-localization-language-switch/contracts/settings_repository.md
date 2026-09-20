# Contract: SettingsRepository

This feature has no external/network API (local-only — see spec Assumptions). The equivalent contract boundary is the **Domain repository interface**, which Presentation (via the two use cases) and Data (via `SettingsRepositoryImpl`) both depend on, per constitution Principle VI. Both methods return `Either<Failure, T>` (Principle VII) — no method throws to the caller.

```dart
abstract class SettingsRepository {
  /// The persisted language choice, or `null` if the user has never
  /// explicitly chosen one yet (FR-009's "no row" case — first launch, or
  /// first launch after upgrading from a version that predates this table).
  Future<Either<Failure, AppLanguage?>> getLanguagePreference();

  /// Persists [language] as the user's explicit choice. The caller
  /// (`ChangeLanguage`) owns the FR-008 retry-once-then-flag-non-blocking-
  /// failure policy — this method itself simply reports success/failure
  /// of a single write attempt.
  Future<Either<Failure, Unit>> setLanguagePreference(AppLanguage language);
}
```

**Failure modes**: `CacheFailure` (local DB I/O error — the only realistic failure for a local single-row upsert), `UnknownFailure`.

---

# Contract: DeviceLocaleProvider

A thin, injectable, Flutter-framework-touching abstraction (lives in `core/device/`, not in `settings/domain/`) so `SettingsCubit`'s first-launch-default branch (FR-009) stays unit-testable without a real Flutter binding (research.md Decision 4).

```dart
abstract class DeviceLocaleProvider {
  /// The device/OS's current system locale (e.g. from
  /// `WidgetsBinding.instance.platformDispatcher.locale`).
  Locale currentLocale();
}
```

Not `Either`-wrapped — reading the platform locale is synchronous and cannot meaningfully fail; the caller (`SettingsCubit`) is responsible for deciding what to do if `currentLocale().languageCode` is neither `'ar'` nor `'en'` (falls back to `AppLanguage.english`, per FR-009).
