# Contract: Theme Tokens (`core/design_system`)

This is not a network or Domain-repository contract — it's the **design-system
boundary** every screen and shared component in the app depends on (constitution
Principle XV: "Colors... MUST be centralized in one design system and consumed via
theme/design tokens"). It replaces direct `AppColors.xxx` static-field access
(`lib/core/design_system/tokens.dart`, today) with a runtime, `BuildContext`-resolved
contract, since a `static const Color` cannot vary by the user's theme choice.

## `lib/core/design_system/tokens.dart` — public surface after this feature

```dart
/// The app's Light Material theme, built from AppColors + AppFinanceColors.light.
ThemeData buildLightTheme();

/// The app's Dark Material theme, built from AppColors + AppFinanceColors.dark.
ThemeData buildDarkTheme();

/// Finance-domain color roles Material's ColorScheme has no equivalent for
/// (data-model.md Entity 2, Part B). Registered on ThemeData.extensions.
class AppFinanceColors extends ThemeExtension<AppFinanceColors> { ... }
```

```dart
/// Ergonomic accessor so call sites never write
/// `Theme.of(context).extension<AppFinanceColors>()!` directly.
extension AppThemeContext on BuildContext {
  AppFinanceColors get financeColors;
}
```

`AppColors` (the existing `static const Color` class) is retained internally — it becomes
the single place the two themes' *seed* values are defined (`ColorScheme.fromSeed`'s
`seedColor`/`error`, and `AppFinanceColors.light`'s concrete values) — but it is no longer
imported or referenced directly by any file outside `lib/core/design_system/tokens.dart`.

## Caller contract: how `lib/main.dart` wires this in

```dart
MaterialApp.router(
  theme: buildLightTheme(),
  darkTheme: buildDarkTheme(),
  themeMode: switch (state.themeMode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  },
  // ...existing locale/router wiring, unchanged
)
```

The `AppThemeMode` (Domain) → `ThemeMode` (Flutter) mapping is inlined at this single call
site (research.md Decision 6) — it is presentation-boundary glue, not a reusable
abstraction yet.

## Caller contract: how a screen/widget reads a color

Every one of the 9 files identified in research.md Decision 7 (and any new
screen/component going forward, per FR-007/Edge Cases) MUST read colors through one of:

- `Theme.of(context).colorScheme.<role>` — general roles (see data-model.md Entity 2
  Part A table: background/surface/elevated-surface/primary/secondary/text/secondary-text/
  border/divider/error/disabled).
- `context.financeColors.<role>` — finance-domain roles (positive/negative/neutral/
  success/warning + their surfaces, chart aliases).

Never `AppColors.<field>` directly, and never a raw `Color(0x......)` literal. This is the
Definition of Done check for FR-007 going forward, not just a one-time migration.

## Backward-compatibility note

`AppButton`, `AppSecondaryButton`, and `showAppConfirmDialog` already resolve their colors
through `Theme.of(context)` (`FilledButton`/`OutlinedButton`/`AlertDialog` defaults, and
`Theme.of(dialogContext).colorScheme.error` for the destructive-action path) — they
require **no code changes** for dark mode to work correctly; they already satisfy this
contract today. Only the 9 files that reference `AppColors.*` directly need updating.
