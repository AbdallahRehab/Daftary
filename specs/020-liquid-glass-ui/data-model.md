# Data Model: Configurable Liquid Glass UI

**Feature**: 020-liquid-glass-ui | **Date**: 2026-09-27

## Domain (Flutter-free) — `lib/features/settings/domain/entities/`

### `GlassLevel` (enum)

| Value | Wire value (persisted) | Meaning for Transparency | Meaning for Intensity |
| --- | --- | --- | --- |
| `low` | `'low'` | least see-through | least blur |
| `medium` | `'medium'` | default | default |
| `high` | `'high'` | most see-through (floored for readability) | most blur |

Mirrors `AppThemeMode` (enum with a `value` wire string).

### `GlassAppearance` (Equatable value object)

| Field | Type | Default |
| --- | --- | --- |
| `enabled` | `bool` | `true` |
| `transparency` | `GlassLevel` | `GlassLevel.medium` |
| `intensity` | `GlassLevel` | `GlassLevel.medium` |

- `static const defaults = GlassAppearance()`.
- `copyWith(...)` is the only way to derive a changed value (Principle IV).
- Equality is by all three fields. `BlocSelector` relies on this to skip no-op rebuilds.

#### Validation rules

- A field that is unknown or `NULL` falls back to **that field's** default only. The others keep their stored values.
- No other values are representable. There is no numeric input path, which is how the readability floors are enforced (FR-008).

**State transitions**: none beyond value replacement. Disabling keeps `transparency` and `intensity` unchanged, so they're restored when the user re-enables.

## Persistence — `AppSettings` table (drift, `lib/core/database/app_database.dart`)

The schema version goes from **7 to 8**. The table is single-row (`id = 'singleton'`).

| Column | Type | Nullable | Existing? | Notes |
| --- | --- | --- | --- | --- |
| `id` | text PK | no | yes | always `'singleton'` |
| `languageCode` | text | no | yes | unchanged |
| `themeMode` | text | yes | yes | unchanged |
| `updatedAt` | int | no | yes | bumped on every write |
| `glassEnabled` | bool | **yes** | **new** | `NULL` means default (`true`) |
| `glassTransparency` | text | **yes** | **new** | a `GlassLevel.value`, or `NULL` for the default |
| `glassIntensity` | text | **yes** | **new** | a `GlassLevel.value`, or `NULL` for the default |

**Migration**: `if (from < 8)` adds the three columns with `addColumn`. It's additive only, with no backfill. Existing rows read as "never set", so existing users get the defaults, including glass **ON** (see spec Assumptions).

**Write semantics**: `SettingsDao.upsertPreference` merges. Parameters that aren't passed keep their existing column values, so a glass write never clobbers language or theme, and the reverse also holds. A glass save always writes all three glass columns together as one snapshot.

## Repository contract additions

See [contracts/settings_repository.md](contracts/settings_repository.md).

## Presentation state — `SettingsState` additions

| Field | Type | Default | Purpose |
| --- | --- | --- | --- |
| `glassAppearance` | `GlassAppearance` | `GlassAppearance.defaults` | Live preference; drives `AppGlassScope`. |
| `isGlassPersistFailing` | `bool` | `false` | Set only after the retried write fails. Shows a localized snackbar. Never rolls back the session value. |

Both are added to `copyWith` and `props`.

## Design-system values — `lib/core/design_system/glass/`

### `AppGlassStyle` (immutable, `==`/`hashCode`)

This is the resolved, renderer-facing configuration the scope carries. Core defines it, so it doesn't know about `GlassLevel`.

| Field | Type | Notes |
| --- | --- | --- |
| `enabled` | `bool` | `false` means every adaptive component renders its Material original |
| `tintAlphaLight` | `double` | alpha of `ColorScheme.surface` in light mode |
| `tintAlphaDark` | `double` | alpha in dark mode |
| `blur` | `double` | logical px |

`static const off = AppGlassStyle(enabled: false, …)` is used when no scope is present (research Decision 13).

### `AppGlassTokens` (constants)

These are the starting values from research Decision 7, finalized by Spike S3.

| Token | Low | Medium | High |
| --- | --- | --- | --- |
| `tintAlphaLight` | 0.86 | 0.74 | 0.62 |
| `tintAlphaDark` | 0.84 | 0.70 | 0.58 |
| `blur` | 4 | 8 | 14 |

Fixed values: `thickness = 10`, `bodyMode = GlassBodyMode.clear`, `quality = GlassQuality.standard`.

### Mapping

`features/settings/presentation/glass/glass_style_mapper.dart`: `GlassAppearance → AppGlassStyle`.

- `transparency` selects `tintAlphaLight` and `tintAlphaDark`.
- `intensity` selects `blur`.
- `enabled` is passed through unchanged.
