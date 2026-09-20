# Phase 0 Research: Dark Mode / Theme Switching

Every unknown below was resolved by reading the actual codebase (`lib/features/settings/`,
`lib/core/design_system/tokens.dart`, `lib/core/database/app_database.dart`,
`lib/main.dart`) rather than assumed; nothing here is `NEEDS CLARIFICATION`.

## Decision 1: Reuse the existing `settings` feature and `SettingsCubit`, don't create a new feature

**Decision**: Theme mode preference is added as new fields/methods on the existing
`settings` feature (`SettingsRepository`, `SettingsDao`, `SettingsCubit`/`SettingsState`)
from `002-localization-language-switch`, exactly as spec Assumptions require ("reuses the
existing state-management and settings-persistence architecture already established for
language preference... rather than introducing a new mechanism").

**Rationale**: `SettingsCubit` is already root-scoped above `MaterialApp.router`
(`lib/main.dart`) and already resolves one persisted preference before the first frame
(`getIt<SettingsCubit>().initialize()`). Theme mode is the same shape of problem
(persisted, app-wide, read-at-startup, changed-from-Settings) — a second Cubit or a
second Drift table would duplicate this machinery for no benefit and would violate
Principle III (no second state-management paradigm) in spirit even if technically still
`flutter_bloc`.

**Alternatives considered**:
- A dedicated `ThemeCubit`/`theme` feature — rejected: duplicates `SettingsCubit`'s
  root-scoping, initialization-ordering, and retry/persistence-failure plumbing for a
  preference that belongs conceptually next to language on the same Settings screen.
- `InheritedWidget`/`ValueNotifier` outside BLoC — rejected outright by Principle III.

## Decision 2: Extend the `AppSettings` table (schemaVersion 2→3) rather than a new table

**Decision**: Add one nullable column, `themeMode TEXT`, to the existing single-row
`AppSettings` table (`lib/core/database/app_database.dart`), bump `schemaVersion` from 2
to 3, and add an `onUpgrade` branch: `if (from < 3) { await m.addColumn(appSettings,
appSettings.themeMode); }`.

**Rationale**: `AppSettings` is already the single-row "preferences" table
(`id = 'singleton'`); a `themeMode` column follows the exact precedent `languageCode` set
in schemaVersion 1→2. Nullable (no default) so upgrading users get `NULL` automatically —
which the repository maps to "no explicit choice yet," the same semantics as a missing
row (Decision 3).

**Alternatives considered**: a separate `AppThemePreference` table — rejected, needless
join complexity for one column on what is already a singleton settings row.

## Decision 3: `upsertPreference` becomes one merge-then-upsert method with named optional params

**Decision**: `SettingsDao.upsertPreference` changes from
`upsertPreference(String languageCode, int updatedAt)` to:

```dart
Future<void> upsertPreference({String? languageCode, String? themeMode, required int updatedAt}) async {
  final existing = await getPreference();
  await _db.into(_db.appSettings).insertOnConflictUpdate(
    AppSettingsCompanion.insert(
      id: _singletonId,
      languageCode: languageCode ?? existing?.languageCode ?? AppLanguage.english.code,
      themeMode: Value(themeMode ?? existing?.themeMode),
      updatedAt: updatedAt,
    ),
  );
}
```

`SettingsRepositoryImpl.setLanguagePreference` calls it with `languageCode:` only;
`setThemeModePreference` calls it with `themeMode:` only.

**Rationale**: `AppSettingsCompanion.insert()`'s `languageCode` is a required,
non-nullable, no-default column — a bare `insertOnConflictUpdate` upsert for a
theme-only write on a row that doesn't exist yet (e.g. the user changes theme before ever
touching language) would be forced to fabricate a language value at the SQL layer with no
visibility into what's "correct." Reading the existing row first and merging is the
simplest correct fix: it preserves whichever field the caller didn't intend to touch,
requires no SQL-level `DEFAULT` clause (which would only cover fresh-row INSERTs, not
protect existing rows from being clobbered), and costs one extra read on a single-row
table (negligible). A single merged method also avoids near-duplicate
`upsertLanguage`/`upsertThemeMode` methods that would both need this same read-merge
logic — one method, one code path (Architectural Decision Rule: simplest option that's
still correct).

**Alternatives considered**:
- Two separate DAO methods (`upsertLanguage`, `upsertThemeMode`) — rejected: duplicates
  the read-then-merge logic twice for no benefit.
- Give `languageCode` a SQL-level default via `.withDefault(const Constant('en'))` and
  skip the read — rejected: only protects the fresh-row INSERT path, still requires
  reasoning about whether an *existing* row's `languageCode` would be silently
  overwritten by an upsert Companion that omits it (it would not, under Drift's
  `insertOnConflictUpdate`, but this is a subtler invariant to rely on than "read, then
  write what changed").

## Decision 4: `AppThemeMode` — a new Domain enum, `null` from the repository means "no explicit choice yet"

**Decision**: New Flutter-free Domain entity, mirroring `AppLanguage`'s shape exactly:

```dart
enum AppThemeMode {
  light('light'),
  dark('dark'),
  system('system');
  const AppThemeMode(this.value);
  final String value;
}
```

`SettingsRepository.getThemeModePreference()` returns `Either<Failure, AppThemeMode?>` —
`null` covers both "no row yet" and "row exists but `themeMode` column is still `NULL`"
(a user who upgraded from schemaVersion 2). `SettingsCubit.initialize()` treats `null` as
`AppThemeMode.system`, per FR-011 and spec Assumptions ("on first install... defaults to
System Default").

**Rationale**: Keeps Domain layer Flutter-free (Principle I) — `AppThemeMode` never
imports `package:flutter`. The Presentation-layer mapping to Flutter's own `ThemeMode`
enum happens at the single point that needs it.

**Alternatives considered**: reuse Flutter's `ThemeMode` enum directly as the Domain/DB
value — rejected: it lives in `package:flutter/material.dart`, which Principle I
explicitly forbids importing into Domain (`SettingsRepository`, `SettingsDao`'s row
mapping) and would leak into `settings_dao.dart`/`settings_repository.dart` files.

## Decision 5: No device-introspection abstraction needed for theme's first-launch default (unlike language)

**Decision**: Theme mode's first-launch default is the constant `AppThemeMode.system`,
resolved with no I/O and no injected provider.

**Rationale**: Language's first-launch default (`DeviceLocaleProvider`) had to resolve a
*concrete* answer (`en` or `ar`) from the device locale, because "system default" isn't a
valid persisted `AppLanguage` value. Theme's default, by contrast, literally *is* one of
the three valid `AppThemeMode` values (`system`) — Flutter's own `MaterialApp.router`
resolves what "system" currently means, live, via `themeMode: ThemeMode.system` (Decision
6). No new `core/device/` abstraction is needed for this feature.

## Decision 6: `MaterialApp.router`'s built-in `themeMode: ThemeMode.system` handles FR-002's live system-follow requirement — no manual `PlatformDispatcher` listening

**Decision**: `main.dart` passes `theme: buildLightTheme()`, `darkTheme: buildDarkTheme()`,
and `themeMode:` mapped from `SettingsState.themeMode` (a 3-arm `switch` inlined at the
call site, mirroring how `Locale(state.language.code)` is already constructed inline
today — not promoted to a separate mapper file until a second call site needs it).

**Rationale**: `WidgetsBinding` already listens for `didChangePlatformBrightness` and
triggers a rebuild of anything under `MaterialApp` when the OS brightness setting changes
while the app is open; `MaterialApp`'s own `themeMode: ThemeMode.system` branch already
resolves current platform brightness via `MediaQuery`/`PlatformDispatcher` on every
build. This satisfies FR-002 ("updates live if that setting changes while the app is
open") and User Story 3's acceptance scenarios with zero custom code — reinventing this
with a manual `PlatformDispatcher.instance.onPlatformBrightnessChanged` callback would
duplicate framework behavior for no gain (Architectural Decision Rule).

**Alternatives considered**: manually read `PlatformDispatcher.platformBrightness` inside
`SettingsCubit` and store a resolved `Brightness` — rejected: reintroduces exactly the
staleness bug FR-002/User Story 3 Acceptance Scenario 2 calls out ("not a frozen
Light/Dark snapshot"), since a Cubit-held value wouldn't automatically refresh when the OS
setting changes without the same platform-dispatcher listening Flutter already does for
free.

## Decision 7: Semantic theme tokens = Material `ColorScheme.fromSeed(brightness:)` + one small custom `ThemeExtension` for finance-specific roles

**Decision**: Two-part token architecture in `lib/core/design_system/tokens.dart`:

1. **`ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light|dark, error: AppColors.error)`**
   generates the standard Material roles — `primary`/`onPrimary`, `secondary`/
   `onSecondary`, `surface`/`onSurface`, `surfaceContainer`/`surfaceContainerHigh`
   (elevated surface), `outline` (border), `outlineVariant` (divider), `onSurfaceVariant`
   (secondary text), `error`/`onError`. `ThemeData`'s component themes (`InputDecorationTheme`,
   `CardThemeData`, `DialogThemeData`, `BottomSheetThemeData`, `NavigationBarThemeData`) are
   built from this scheme in `buildLightTheme()`/`buildDarkTheme()`, covering FR-006's
   "inputs, cards, navigation, dialogs, bottom sheets" roles through Flutter's own
   component-theming mechanism.
2. **`AppFinanceColors extends ThemeExtension<AppFinanceColors>`** — a small custom
   token set for the roles Material has no equivalent for: `positive`/`positiveSurface`
   ("they owe you"), `negative`/`negativeSurface` ("you owe them"), `neutral`/
   `neutralSurface` (settled/tags), `success`/`successSurface`, `warning`/
   `warningSurface` (generic, forward-looking non-finance feedback), and
   `chartPositive`/`chartNegative`/`chartNeutral` (FR-006's "charts" role — aliased to
   the finance roles today since the app has no chart widgets yet; this satisfies "defined
   and used" without inventing a speculative separate chart palette per spec Assumptions
   "redesigning their underlying data representation is out of scope"). Registered via
   `ThemeData(extensions: [AppFinanceColors.light])` /
   `ThemeData(extensions: [AppFinanceColors.dark])`. Accessed via a `BuildContext`
   extension getter (`context.financeColors`) wrapping
   `Theme.of(this).extension<AppFinanceColors>()!`, so call sites never call
   `Theme.of(context).extension<...>()` directly.

**Rationale**: `ThemeExtension` is the Flutter-native mechanism for exactly this problem
(custom design tokens that must vary by theme and animate/rebuild with `Theme.of`,
`ThemeData.lerp`-compatible). Splitting roles this way avoids inventing ~20 duplicate
custom tokens for things `ColorScheme` + component themes already provide, which is both
less code and less to keep in sync across two themes (Architectural Decision Rule:
simplest option with the best maintainability). It also directly resolves the concrete
problem found during investigation: **`AppColors` today is a class of `static const
Color` fields** (`lib/core/design_system/tokens.dart`), referenced directly (not through
`Theme.of(context)`) from 9 files — `app_card.dart`, `app_text_field.dart`,
`app_empty_view.dart`, `overview_summary_card.dart`, `balance_status_badge.dart`,
`transaction_list_tile.dart`, `overview_page.dart`, `relationship_tag_chip.dart`, and
`tokens.dart` itself. A compile-time `static const` cannot vary at runtime by theme, so
every one of these 9 files must change from `AppColors.xxx` to
`Theme.of(context).colorScheme.xxx` or `context.financeColors.xxx` — this is the concrete
scope of FR-007's audit (verified via `grep -rn "AppColors\."` and `grep -rn "Color(0x"`
across `lib/`: no other hardcoded color literals exist outside `tokens.dart`, so the
audit is fully bounded to these 9 files plus `tokens.dart`'s own rewrite).

**Alternatives considered**:
- A single giant hand-authored token class covering every FR-006-listed role
  (background/surface/text/secondary-text/border/divider/primary/secondary/disabled/...)
  duplicated alongside `ColorScheme` — rejected: duplicates roles Material's own
  `ColorScheme` already generates correctly (including built-in contrast-aware tonal
  relationships from `ColorScheme.fromSeed`), doubling the values to keep in sync across
  two themes for no benefit.
- A custom `InheritedWidget` instead of `ThemeExtension` — rejected: reinvents
  `Theme.of(context)` propagation and `ThemeData.lerp` animation support that
  `ThemeExtension` already provides.
- Provider/Riverpod-based token resolution — rejected outright by Principle III/XIV (a
  second DI/state paradigm).

## Decision 8: `AppTypography`'s one hardcoded color (`bodyMuted`) is dropped from the constant; color applied at call sites, like `.amount`/`.body` already are

**Decision**: `AppTypography.bodyMuted` keeps its `fontSize`/`height` but drops its
`color: AppColors.onSurfaceMuted` field. Its ~5 call sites (which today do
`Text(x, style: AppTypography.bodyMuted)` with no override) add
`.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)`.

**Rationale**: `AppTypography.amount` and `AppTypography.body` are already applied via
`.copyWith(color: ...)` at their call sites (`overview_summary_card.dart`,
`transaction_list_tile.dart`) — `bodyMuted` is the one outlier baking a color directly
into a `static const TextStyle`, which (like `AppColors`) cannot vary by theme. This is
the smallest possible fix consistent with the existing call-site pattern, not a redesign
of `AppTypography`.

**Alternatives considered**: move all typography into `ThemeData.textTheme` and have call
sites read `Theme.of(context).textTheme.bodyMedium` instead of `AppTypography.*` — out of
scope: a much larger refactor of every screen's text styling with no requirement driving
it (FR-006 only lists *color* roles, not typography roles), and would touch far more than
the 9-file color audit this feature is scoped to.

## Decision 9: `ChangeThemeMode` mirrors `ChangeLanguage`'s retry-once-then-flag policy; `SettingsState` gets a separate `isThemeModePersistFailing` field

**Decision**: New `ChangeThemeMode` use case retries a failed
`setThemeModePreference` write exactly once (synchronously, no `Timer`/`Future.delayed`),
identical in shape to `ChangeLanguage`. `SettingsState` gets a new
`isThemeModePersistFailing` field (default `false`) alongside the existing
`isPersistFailing` (kept as-is, scoped to language) rather than renaming/generalizing the
existing field.

**Rationale**: The spec's Assumptions require reusing "the existing state-management and
settings-persistence architecture already established for language preference" — that
architecture *is* the retry-once-then-notify policy (`002`'s FR-008), not just the Cubit
shape, so `ChangeThemeMode` reuses it for consistency even though `003`'s own FRs don't
restate a persistence-failure policy explicitly. Adding a second, separately-named boolean
(rather than renaming `isPersistFailing` to something generic like
`isLanguagePersistFailing`) avoids an unrelated ripple through already-merged `002` code
(`SettingsPage`'s existing `listenWhen`/`listener`, `settings_cubit_test.dart`) that isn't
required by this feature (Refactoring Discipline: avoid unrelated changes) — and keeps it
unambiguous in `SettingsPage` which specific preference's save failed, so the right
localized message (`settingsSaveFailed` vs. a new `themeSaveFailed`) can be shown.

## Decision 10: WCAG 2.1 AA contrast verified manually via the WCAG relative-luminance formula, documented in `data-model.md`

**Decision**: Per spec Assumptions ("Automated/scripted contrast and accessibility checks
are out of scope for this feature"), FR-008 compliance is verified by computing contrast
ratios by hand (standard WCAG 2.1 relative-luminance formula) for the concrete dark-theme
color values chosen, and recording the resulting ratios in `data-model.md` next to each
token pair, so implementation has a checked-in reference rather than "looks fine" as the
only bar. All financial-value token pairs were computed to clear **4.5:1** (the stricter
normal-text threshold), not just the 3:1 large-text/UI-component threshold, since
`transaction_list_tile.dart`'s amount text uses `FontWeight.w600` (semibold), which is
below WCAG's bold-weight threshold for the "large text" 3:1 exemption — targeting 4.5:1
uniformly for financial text removes any ambiguity about which threshold applies.

**Rationale**: Matches the spec's own scoping decision; computing real numbers during
planning (rather than deferring entirely to "review during implementation") catches an
unreadable color pairing before any widget code is written.

**Alternatives considered**: pull in a contrast-checking package (e.g. as a dev-dependency
used in a script) — explicitly out of scope per spec Assumptions; not pursued.

## Decision 11: No new color-only-meaning regressions — existing icon/label pairing already satisfies FR-009, must be re-verified per-theme, not redesigned

**Decision**: `BalanceStatusBadge` (icon + label + color) and `TransactionListTile`
(`arrow_upward`/`arrow_downward` icon + color) already pair every status/direction color
with a non-color cue. No redesign is needed for FR-009 — the token-conversion audit (files
listed in Decision 7) must simply preserve these existing icon/label pairings while
swapping the color source, and manual review during implementation re-confirms the pairing
still reads correctly in Dark theme.

**Rationale**: Investigation of `balance_status_badge.dart` and `transaction_list_tile.dart`
confirms the icon+color+label pattern already exists; this feature's job is to make the
*color* theme-aware without breaking that existing pairing, not to invent a new
accessibility affordance.
