# Phase 1 Data Model: Dark Mode / Theme Switching

Two Key Entities from spec.md are modeled here: **Theme Preference** and **Semantic
Theme Token Set**. Both extend the existing `002-localization-language-switch`
persistence/state shapes (research.md Decisions 1-4) rather than introducing parallel
ones.

## Entity 1: Theme Preference

### Domain representation

`lib/features/settings/domain/entities/app_theme_mode.dart` (NEW, Flutter-free):

```dart
/// The user's chosen theme mode (Domain, Flutter-free per constitution
/// Principle I). Mapped to Flutter's own `ThemeMode` only at the
/// Presentation boundary (main.dart) — mirrors how `AppLanguage` maps to
/// `Locale` only at that same boundary.
enum AppThemeMode {
  light('light'),
  dark('dark'),
  system('system');

  const AppThemeMode(this.value);

  /// The wire value persisted in `AppSettings.themeMode`.
  final String value;
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `value` | `String` | `'light'` \| `'dark'` \| `'system'` — persisted verbatim |

### Persistence representation

`lib/core/database/app_database.dart` — `AppSettings` table gains one column
(`schemaVersion` 2 → 3):

```dart
class AppSettings extends Table {
  TextColumn get id => text()();
  TextColumn get languageCode => text()();
  TextColumn get themeMode => text().nullable()();   // NEW
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
```

Migration (`AppDatabase.migration`):

```dart
onUpgrade: (m, from, to) async {
  if (from < 2) {
    await m.createTable(appSettings);
  }
  if (from < 3) {
    await m.addColumn(appSettings, appSettings.themeMode);   // NEW
  }
},
```

Same single row (`id = 'singleton'`) as `languageCode` — no new table, no new row
lifecycle (research.md Decision 2).

### Validation / state-resolution rules

- `themeMode` is `NULL` for: (a) a brand-new install with no `AppSettings` row at all,
  and (b) a row that predates this feature (upgraded from schemaVersion 2, where
  `themeMode` didn't exist). Both cases are treated identically by
  `SettingsRepositoryImpl.getThemeModePreference()`: return `Right(null)`.
- An unrecognized persisted string (only reachable via external DB tampering, never a
  normal app write) is treated as "no valid preference" (`null`), not thrown — mirrors
  `SettingsRepositoryImpl._parse` for `AppLanguage` exactly.
- `SettingsCubit.initialize()` resolves the *effective* theme mode: persisted value if
  present, else the FR-011 first-launch default `AppThemeMode.system` (research.md
  Decision 5 — no device I/O required, unlike language's first-launch resolution).
- Persisting a theme mode change never blocks the UI: `SettingsCubit.changeThemeMode`
  emits the new mode immediately, then persists via `ChangeThemeMode` (retry-once policy,
  research.md Decision 9); a fully-failed persist sets `isThemeModePersistFailing = true`,
  surfaced as a non-blocking `SnackBar` (new `themeSaveFailed` ARB string), matching
  `isPersistFailing`'s existing UX for language.

### State transitions

```
[no row / themeMode NULL] --(user picks Light/Dark/System in Settings)--> [themeMode = <choice>]
        ^                                                                        |
        |                                                                        v
        +---------------------- (user picks a different choice) -----------------+
```

There is no "unset" transition — once a user makes an explicit choice, `themeMode` always
holds a valid value going forward; only pre-choice states resolve through the FR-011
default.

### `SettingsState` shape (extended)

`lib/features/settings/presentation/cubit/settings_state.dart`:

| Field | Type | Default | Notes |
| --- | --- | --- | --- |
| `language` | `AppLanguage` | `AppLanguage.english` | existing (002), unchanged |
| `isPersistFailing` | `bool` | `false` | existing (002), unchanged — language-only |
| `themeMode` | `AppThemeMode` | `AppThemeMode.system` | NEW |
| `isThemeModePersistFailing` | `bool` | `false` | NEW |

---

## Entity 2: Semantic Theme Token Set

Two-part token model (research.md Decision 7): Material's own `ColorScheme` for
general-purpose roles, plus one custom `ThemeExtension` for finance-domain roles Material
has no equivalent for. Every FR-006-listed role maps to exactly one of these two parts —
no role is left undefined, and none is duplicated across both.

### Part A — `ColorScheme` roles (generated, not hand-authored)

`lib/core/design_system/tokens.dart`:

```dart
ColorScheme _lightScheme = ColorScheme.fromSeed(
  seedColor: AppColors.primary,
  brightness: Brightness.light,
  error: AppColors.error,
);
ColorScheme _darkScheme = ColorScheme.fromSeed(
  seedColor: AppColors.primary,
  brightness: Brightness.dark,
  error: AppColors.error,
);
```

| FR-006 role | `ColorScheme` field | Consumed via |
| --- | --- | --- |
| background | `surface` (M3 merges background into surface) | `Theme.of(context).colorScheme.surface` |
| surface | `surface` | same |
| elevated surface | `surfaceContainerHigh` | same |
| primary | `primary` / `onPrimary` | same (already how `AppButton`'s `FilledButton` resolves its color — no change needed there) |
| secondary | `secondary` / `onSecondary` | same |
| text | `onSurface` | same |
| secondary text | `onSurfaceVariant` | same (replaces `AppTypography.bodyMuted`'s hardcoded color — research.md Decision 8) |
| border | `outline` | same |
| divider | `outlineVariant` | same (replaces `AppColors.divider`) |
| error | `error` / `onError` | same (already used by `app_confirm_dialog.dart`) |
| disabled | `onSurface` at reduced opacity (Material convention, `.withValues(alpha: 0.38)`) | same |
| inputs | `InputDecorationTheme` built from the scheme, set on `ThemeData.inputDecorationTheme` | `AppTextField` no longer sets its own `fillColor`/`border` colors directly |
| cards | `CardThemeData` built from the scheme, set on `ThemeData.cardTheme` | `AppCard` still owns its own `Container` (custom radius/hairline-border look is a design decision, not a Material `Card`) but reads its border/fill from `Theme.of(context).colorScheme` instead of `AppColors` |
| navigation | `NavigationBarThemeData` (for `MainShell`'s bottom nav) built from the scheme | `MainShell` |
| dialogs | `DialogThemeData` built from the scheme | `showAppConfirmDialog` (already `Theme.of`-driven for its destructive-action color; unaffected) |
| bottom sheets | `BottomSheetThemeData` built from the scheme | any future bottom sheet |

### Part B — `AppFinanceColors` (custom `ThemeExtension`)

`lib/core/design_system/tokens.dart`:

```dart
class AppFinanceColors extends ThemeExtension<AppFinanceColors> {
  const AppFinanceColors({
    required this.positive, required this.positiveSurface,
    required this.negative, required this.negativeSurface,
    required this.neutral, required this.neutralSurface,
    required this.success, required this.successSurface,
    required this.warning, required this.warningSurface,
    required this.chartPositive, required this.chartNegative, required this.chartNeutral,
  });

  final Color positive, positiveSurface;
  final Color negative, negativeSurface;
  final Color neutral, neutralSurface;
  final Color success, successSurface;
  final Color warning, warningSurface;
  final Color chartPositive, chartNegative, chartNeutral;

  static const light = AppFinanceColors(/* current AppColors.* light values */);
  static const dark = AppFinanceColors(/* new dark values, see table below */);

  @override
  AppFinanceColors copyWith({...}) => ...;
  @override
  AppFinanceColors lerp(ThemeExtension<AppFinanceColors>? other, double t) => ...;
}

extension AppThemeContext on BuildContext {
  AppFinanceColors get financeColors =>
      Theme.of(this).extension<AppFinanceColors>()!;
}
```

| Role | Light value (existing `AppColors`) | Dark value (NEW) |
| --- | --- | --- |
| `positive` | `#1F8A56` | `#4ADE93` |
| `positiveSurface` | `#E4F5EC` | `#1C3B2C` |
| `negative` | `#C24B3F` | `#FF6B57` |
| `negativeSurface` | `#FBEAE7` | `#40201C` |
| `neutral` | `#6B6B6B` | `#B0B0AE` |
| `neutralSurface` | `#EDEDEA` | `#2A2A28` |
| `success` | `#1F8A56` (aliases `positive`) | `#4ADE93` |
| `successSurface` | `#E4F5EC` | `#1C3B2C` |
| `warning` | `#B3730C` (NEW — no current warning role exists) | `#F2B84B` |
| `warningSurface` | `#FCEFDB` | `#3B2E13` |
| `chartPositive`/`chartNegative`/`chartNeutral` | alias `positive`/`negative`/`neutral` | alias `positive`/`negative`/`neutral` |

Dark theme `background`/`surface` (via `ColorScheme.fromSeed(brightness: Brightness.dark)`)
resolve near `#121212`/`#1E1E1E` (Material's standard dark baseline); `onSurface`/
`onSurfaceVariant` resolve near `#F2F2F0`/`#B0B0AE`.

### WCAG 2.1 AA contrast verification (research.md Decision 10)

Computed with the standard WCAG relative-luminance formula, dark theme, against the
`#121212` background unless noted:

| Pair | Contrast ratio | Threshold required | Result |
| --- | --- | --- | --- |
| `onSurface` (`#F2F2F0`) text on `background` (`#121212`) | ~16.7:1 | 4.5:1 (normal text) | PASS |
| `onSurfaceVariant` (`#B0B0AE`) text on `background` | ~8.6:1 | 4.5:1 (normal text) | PASS |
| `positive` (`#4ADE93`) financial text on `background` | ~10.9:1 | 4.5:1 (financial text, treated as normal-text threshold per research.md Decision 10) | PASS |
| `positive` (`#4ADE93`) icon/text on `positiveSurface` (`#1C3B2C`) (badge context) | ~7.1:1 | 3:1 (large text/UI component) | PASS |
| `negative` (`#FF6B57`) financial text on `background` | ~6.7:1 | 4.5:1 | PASS |
| `negative` (`#FF6B57`) icon/text on `negativeSurface` (`#40201C`) (badge context) | ~5.2:1 | 3:1 | PASS |

Light theme pairs are unchanged from the app's current (already-shipping) values and are
not re-verified here; only the newly-introduced dark values needed checking.

### FR-009 cross-reference (no color-alone meaning)

`positive`/`negative` are never the sole signal: `BalanceStatusBadge` pairs color with an
icon (`arrow_downward`/`arrow_upward`/`check_circle_outline`) and a localized label;
`TransactionListTile`'s amount color is paired with a leading direction icon. This
pairing is preserved by the token-conversion audit (research.md Decision 7's file list),
not re-invented.
