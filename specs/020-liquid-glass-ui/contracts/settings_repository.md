# Contract: `SettingsRepository` — glass additions

**Location**: `lib/features/settings/domain/repositories/settings_repository.dart`. The implementation is `SettingsRepositoryImpl` in `data/repositories/`.

Existing language and theme methods are **unchanged**.

```dart
/// The persisted glass preference with per-field defaults applied, or
/// `null` when no settings row exists at all.
Future<Either<Failure, GlassAppearance?>> getGlassAppearancePreference();

/// Persists all three glass fields as one snapshot. The caller
/// (`ChangeGlassAppearance`) owns the retry-once policy. This method
/// reports the outcome of a single write attempt.
Future<Either<Failure, Unit>> setGlassAppearancePreference(
  GlassAppearance appearance,
);
```

## Behaviour

| Stored row | `getGlassAppearancePreference()` returns |
| --- | --- |
| no row | `Right(null)`. The cubit uses `GlassAppearance.defaults`. |
| row, all glass columns `NULL` (upgraded install) | `Right(GlassAppearance.defaults)` |
| row, `glassTransparency = 'bogus'`, others valid | `Right(...)` with `transparency: medium`, and the other fields as stored |
| DAO throws | `Left(CacheFailure(...))`. The cubit falls back to the defaults. |

| Call | Effect on row |
| --- | --- |
| `setGlassAppearancePreference(a)` | Upserts `glassEnabled`, `glassTransparency` and `glassIntensity` from `a`, and bumps `updatedAt`. `languageCode` and `themeMode` are preserved. |
| DAO throws | `Left(CacheFailure(...))`. Nothing is partially written, because it's one upsert statement. |

## Use cases

| Use case | Signature | Policy |
| --- | --- | --- |
| `GetGlassAppearancePreference` | `Future<Either<Failure, GlassAppearance?>> call()` | Pass-through. Kept for symmetry with the existing `Get…Preference` use cases. |
| `ChangeGlassAppearance` | `Future<bool> call(GlassAppearance a)` | One immediate retry on failure. Returns whether the write ultimately succeeded. Identical to `ChangeThemeMode`. |

## `SettingsCubit` surface (additions)

| Method | Emits | Then |
| --- | --- | --- |
| `initialize()` (extended) | also sets `glassAppearance` (persisted value, or the defaults) | nothing |
| `setGlassEnabled(bool)` | `glassAppearance.copyWith(enabled:)`, `isGlassPersistFailing: false` | `ChangeGlassAppearance`. On `false`, emits `isGlassPersistFailing: true`. |
| `setGlassTransparency(GlassLevel)` | same pattern | same |
| `setGlassIntensity(GlassLevel)` | same pattern | same |

Emitting an identical `GlassAppearance` is a no-op: nothing is emitted and nothing is written.
