# Phase 1 Data Model: Arabic/English Localization + Language Switch

Derived from the spec's Key Entities section, the Clarifications session, and the Phase 0 research decisions (Drift-backed persistence, injected device-locale default). This feature adds exactly one persisted entity.

## Entity: Language Preference (`AppSettings` table / `AppLanguage` domain enum)

The user's currently selected app display language. Single value scoped to the app installation on the device (spec Assumptions: no per-account profile system) — there is exactly one row, ever.

| Field | Type | Rules |
|---|---|---|
| `id` | `String` | Primary key, fixed constant value (e.g. `'singleton'`) — enforces the "single value" rule at the schema level; there is never more than one row |
| `languageCode` | `String` | `'en'` or `'ar'` only (stored as the domain `AppLanguage` enum's wire value) |
| `updatedAt` | `int` (epoch millis) | Set on every write — not user-facing, but useful for support/debugging ("when did the user last change this") |

**Domain representation**: `AppLanguage` (Domain, Flutter-free enum: `english`, `arabic`), with a `code` getter (`'en'`/`'ar'`) used at the Data-layer boundary only — Domain and Presentation code refer to `AppLanguage.english`/`AppLanguage.arabic`, never to raw strings.

**Validation rules**:
- Only `'en'`/`'ar'` are ever written; the Data-layer mapper is the single place a raw string is parsed into `AppLanguage`, and an unrecognized value there is treated as "no valid preference" (falls back to first-launch default resolution, Decision 4) rather than a crash — this can only happen from external DB tampering, never from normal app writes, but the constitution's "no raw exceptions to the UI" rule still applies to it.
- No app code ever leaves the row `null`/absent to mean "English" or "Arabic" implicitly — **absence of the row** is the only representation of "no explicit choice yet" (drives FR-009's first-launch default), and once the user changes the language even once, the row always exists from then on.

**Lifecycle**: `absent (no row, first launch)` → `set to 'en' or 'ar' (first explicit choice, or an auto-persisted first-launch default per FR-009)` → `[changed any number of times]`. There is no "delete"/"reset to unset" operation exposed anywhere in this feature's scope.

**Derived (not stored)**: The active `TextDirection`/`Locale` used by `MaterialApp.router` is derived from `AppLanguage` at the Presentation boundary (`SettingsCubit`/`main.dart`), never persisted separately — this is exactly how the spec's Key Entities section describes it ("drives both the active translation set and the layout direction... app-wide"), and keeps a single source of truth (no risk of language and direction ever disagreeing, per Edge Cases).

## Migration

`AppDatabase.schemaVersion` moves from `1` to `2`. This is the first explicit `MigrationStrategy` the app has needed (schema was create-only at v1):

- `onCreate`: create all tables as usual (fresh installs land directly on the v2 schema, `AppSettings` included).
- `onUpgrade` (from 1 to 2): `m.createTable(appSettings)` only — no data migration needed since the table is new and starts empty (first launch after upgrade resolves the FR-009 default exactly like a fresh install).
