# Research: Configurable Liquid Glass UI

**Feature**: 020-liquid-glass-ui | **Date**: 2026-09-27

Every package claim below was checked against the published source of
`liquid_glass_widgets` 1.7.2 (pub.dev archive), not only its README. Every
repo claim was checked against the current `main` tree. Items marked
**Spike** are confirmed at runtime by the first implementation task
before any screen is migrated.

---

## Decision 1: Package version and constraint

- **Decision**: Add `liquid_glass_widgets: '>=1.7.2 <1.8.0'`.
- **Rationale**: The package needs Flutter ≥ 3.41 and Dart ≥ 3.5, and depends only on the Flutter SDK. The project runs Flutter 3.47 and Dart `^3.10`. The package ships a minor release every few days, and 1.x minors have changed rendering defaults (for example, the tab bar's default quality). Capping below 1.8 lets bug-fix patches in while keeping visual changes reviewable.
- **Alternatives considered**:
  - `^1.7.2`: this would admit silent visual changes on `pub upgrade`.
  - An exact pin: this would block patch fixes to a fast-moving renderer.

## Decision 2: Package bootstrap

- **Decision**:
  - In `main()`, call `unawaited(LiquidGlassWidgets.initialize())` next to the existing unawaited startup work.
  - Pass `LiquidGlassWidgets.wrap(child: const DaftaryApp(), brightnessResolver: Theme.maybeBrightnessOf)` to `runApp`. Pass no `theme:` and keep `respectSystemAccessibility: true` and `adaptiveQuality: false`, which are both defaults.
- **Rationale**:
  - `initialize()` is async disk-to-RAM shader loading with no GPU work. It runs while the splash (`AppStartupGate`) is up, so turning glass ON later never stalls on shader load.
  - Without `theme:`, `wrap()` only sets two globals (accessibility bridging and the Material brightness resolver) and returns `child` unchanged. That means **no extra widgets in the tree when glass is OFF**.
  - `adaptiveQuality` is marked experimental and would benchmark the device at startup.
- **Alternatives considered**:
  - Calling `initialize()` only when glass is ON: this would need the settings before `runApp`, and toggling ON would then hitch on first use.
  - Awaiting `initialize()`: this would add startup latency for no first-frame benefit, because the splash covers it.

## Decision 3: How user levels reach the renderer (bypassing `GlassTheme`)

- **Decision**: Don't use `GlassTheme`/`GlassThemeData` for the user's levels. The app provides its own `AppGlassScope` (an `InheritedWidget` in `core/design_system/glass/`) carrying an immutable `AppGlassStyle`. The single primitive `AppGlassSurface` builds an explicit `LiquidGlassSettings` from that style and the current `ColorScheme`, and passes it as `GlassContainer(settings:)`.
- **Rationale (verified in source)**:
  - Readability needs `LiquidGlassSettings.bodyMode = GlassBodyMode.clear`. The default `adaptive` mode "takes your color's hue but holds the background's perceived brightness", so a surface-coloured tint cannot make the bar lighter or darker than the content behind it, and text contrast would be uncontrolled. `bodyMode` and the light-mode legibility veil `whitenStrength` exist **only** on `LiquidGlassSettings`, not on `GlassThemeSettings`.
  - The tint must come from the app's `ColorScheme.surface` (FR-017), not from the package's default blue-white tint. A `ColorScheme` is only available below `MaterialApp`.
  - An app-owned inherited scope keeps the package out of every screen's imports. Only `core/design_system/glass/` imports `liquid_glass_widgets`.
- **Alternatives considered**:
  - `GlassThemeData.simple(blur:, thickness:)`: this lacks `bodyMode` and a tint that follows the theme.
  - `GlassTheme` placed under `MaterialApp.builder`: this is possible, but it still can't express `bodyMode`, so it adds nothing over the explicit settings.

## Decision 4: Surfaces keep their Material widgets, and glass is a platter behind them

- **Decision**: Each adaptive component renders the **existing Material widget** in both modes. When glass is ON, three things change:
  - its background becomes transparent (`backgroundColor`/`surfaceTintColor` transparent, elevation 0);
  - an `AppGlassSurface` sits behind it: via `flexibleSpace` for `AppBar`, a `Stack` for the navigation bar, a wrapper for the FAB, and the sheet body for modal sheets;
  - the scaffold lets content pass underneath (Decision 6).
- **Rationale (verified in source)**:
  - `GlassAppBar` is "a simple layout container with a transparent `backgroundColor`" where "glass effects are rendered by individual child widgets… not by the bar surface". Its default constructor adds **no automatic back button**, and its toolbar height is 44 compared with Material's 56. The `.pinned` variant takes data-only `GlassBarItem`s, not widgets. Switching to it would change back navigation, action widgets (the `PopupMenuButton` action), tooltips, semantics and height. That breaks US1-4 / FR-016 / FR-020.
  - `GlassTabBar.bottom` has its own fixed label size (`labelFontSize = 11`), a magnification and drag interaction, and a floating-pill layout. Parity with dynamic text and existing semantics would have to be re-proven.
  - There is **no glass FAB widget** in the package. `GlassIconButton` has no extended-label form.
  - Keeping the Material widget guarantees the same semantics, tooltips, focus, touch targets, text scaling and RTL mirroring in both modes. Glass then only changes the surface underneath.
- **Alternatives considered**:
  - `GlassAppBar`, `GlassTabBar.bottom`, `GlassIconButton` and `GlassSheet.show`: rejected for v1 for the parity reasons above. They can be adopted later behind the same adaptive components (SC-009) without touching screens.

## Decision 5: The glass primitive, `AppGlassSurface`

- **Decision**: `AppGlassSurface` wraps `GlassContainer` with:
  - `shape: LiquidRoundedSuperellipse(borderRadius: r)`, using `r = 0` for full-bleed bars and `AppRadius` tokens for the FAB and sheet;
  - `quality: GlassQuality.standard`;
  - `settings:` from Decision 3;
  - `useOwnLayer: false`.

  It is the **only** place that constructs package glass.
- **Rationale**: The README reserves `premium` for static, non-scrolling surfaces, says it is Impeller-only and may misrender inside scrollables, and notes it falls back on Skia. `standard` is the documented default for all paths, which gives one predictable look on iOS Metal, Android Vulkan and Android GLES. A single primitive makes FR-012 (no nesting) and FR-023 (quality) enforceable in one file.
- **Alternatives considered**:
  - `premium` for bars: its appearance differs by device class, and it adds a texture-capture cost.
  - `minimal`: shader-free, but only a plain BackdropFilter, so it isn't Liquid Glass.
- **Spike (S1)**: Confirm that `LiquidRoundedSuperellipse(borderRadius: 0)` renders a clean full-bleed rectangle.
- **Spike (S2)**: Confirm that `GlassContainer` at `standard` blurs the real content behind it without a `LiquidGlassScope`/`GlassBackgroundSource`. That pairing is documented as needed only for Skia/Web refraction of interactive indicators. Check on an iOS device, an Android Vulkan device, and an Android GLES (budget) device.

## Decision 6: Content passes beneath glass chrome only when glass is ON

- **Decision**:
  - Add a thin `AppScaffold`, which forwards every `Scaffold` parameter the app uses. When glass is ON it sets `extendBodyBehindAppBar: true`, and `extendBody: true` when it has a bottom bar. When glass is OFF both stay at their current values (`false`).
  - Scrollable bodies with an explicit `padding:` add `AppGlassInsets.of(context)`. This is `MediaQuery.paddingOf(context)` when glass is ON and `EdgeInsets.zero` when OFF.
  - The main shell's compact `Scaffold` becomes an `AppScaffold` with `extendBody` so tab pages scroll under the bottom bar.
- **Rationale**: Glass is only visible over moving content. The spec (US4-1) requires lists to scroll beneath the app bar and bottom bar. Returning `EdgeInsets.zero` when OFF keeps the OFF layout pixel-identical (SC-003). Adding `MediaQuery` padding unconditionally would shift OFF layouts on devices with a home indicator, in wide layouts and on pushed routes. The on/off branch lives inside core components, not screens (FR-014).
- **Alternatives considered**:
  - Leaving the layout unchanged: glass over a flat page surface is just a tinted bar, which fails US4-1 and makes Intensity invisible.
  - Per-screen `extendBodyBehindAppBar: glassOn`: this puts branching in 17 screens, which violates FR-014.
- **Cost (accepted)**: Every migrated screen whose scrollable sets its own `padding:` needs a one-line inset addition. Tasks audit each of the 17 app-bar screens plus the three shell tabs. Q1's scope default (all 17 app bars) sets the size of this audit.

## Decision 7: Level values (Transparency → tint alpha, Intensity → blur)

- **Decision**: Tint = `ColorScheme.surface` at the level's alpha, with `bodyMode: GlassBodyMode.clear`. "Higher Transparency" means **more see-through** (lower alpha). Starting token values, finalized by Spike S3:

  | Level | Transparency: tint alpha (light / dark) | Intensity: blur (logical px) |
  | --- | --- | --- |
  | Low | 0.86 / 0.84 | 4 |
  | Medium (default) | 0.74 / 0.70 | 8 |
  | High | 0.62 / 0.58 (floor) | 14 |

  Other `LiquidGlassSettings` fields stay at package defaults, except `thickness` (refraction depth), which is fixed at a subtle 10 so text on bars doesn't warp.
- **Rationale**:
  - The package's own defaults (tint alpha 0.12/0.08, blur 5/4) are tuned for decorative glass over wallpapers, not for text-bearing app chrome over dense financial lists.
  - The alpha **floor** at High is the Android readability guarantee (FR-008/FR-019). Android reports no high-contrast flag, so the package's automatic fallback never fires there.
  - Blur never drops below 4, so even the most transparent setting frosts busy content.
- **Spike (S3)**: Measure contrast of `onSurface` title text and icons on each bar over the busiest real screens (the People list and Finance history, in light and dark). Tune only the numbers until SC-005 passes at every level (4.5:1 text, 3:1 icons).
- **Alternatives considered**:
  - Continuous sliders: these need per-value validation and are harder to test.
  - Mapping Transparency to `thickness`: verified wrong. `thickness` is refraction depth.

## Decision 8: Persistence (extend `AppSettings`, schema 7 → 8)

- **Decision**:
  - Add three **nullable** columns to `AppSettings`: `glassEnabled` (bool), `glassTransparency` (text), `glassIntensity` (text). The migration step is `if (from < 8) { addColumn ×3 }`.
  - `SettingsDao.upsertPreference` gains three optional params with the same merge-don't-clobber behaviour.
  - `SettingsRepository` gains `getGlassAppearancePreference()` and `setGlassAppearancePreference(GlassAppearance)`.
- **Rationale**:
  - This reuses the single-row settings store that language and theme already use, as the spec requires. No new storage is introduced.
  - `NULL` means "never set" and maps to the default per field. That makes a fresh install, an upgrade and a corrupted value behave the same, with no data backfill.
  - Writing all three fields in one upsert makes each save an atomic snapshot. Rapid taps can't interleave partial writes, and the last emitted state is the last row written, because drift serializes writes on one connection.
- **Alternatives considered**:
  - A new `GlassPreferences` table: this duplicates infrastructure.
  - `shared_preferences`: this adds a second persistence mechanism, which the spec forbids.
  - Non-null columns with SQL defaults: these would need a backfill, and they hide the difference between "never set" and "set".

## Decision 9: State (extend `SettingsCubit`; isolate rebuilds)

- **Decision**:
  - `SettingsState` gains `glassAppearance` (default `GlassAppearance.defaults`) and `isGlassPersistFailing`.
  - `SettingsCubit.initialize()` also loads the glass preference.
  - New methods `setGlassEnabled(bool)`, `setGlassTransparency(GlassLevel)` and `setGlassIntensity(GlassLevel)` emit immediately, then persist through a `ChangeGlassAppearance` use case with the existing retry-once policy.
  - In `main.dart`:
    - The root `BlocBuilder<SettingsCubit, SettingsState>` gets `buildWhen: language or themeMode changed`.
    - `MaterialApp.builder` becomes `BlocSelector<SettingsCubit, SettingsState, GlassAppearance>` → `AppGlassScope(style: toAppGlassStyle(appearance), child: AppStartupGate(child: child!))`.
- **Rationale**:
  - The cubit is the existing root-scoped owner of appearance preferences and is already initialized behind the splash by `AppStartupCubit`. That's what makes FR-004 (correct from the first frame) hold with no new startup step.
  - Today the root builder rebuilds `MaterialApp.router` on **any** state change. Without `buildWhen`, each glass tap would rebuild the router, localization and theme, which violates FR-022.
  - The selector plus `InheritedWidget.updateShouldNotify` means that only widgets that called `AppGlassScope.of` rebuild.
- **Alternatives considered**:
  - A separate `GlassSettingsCubit`: this duplicates the load, retry and failure-notice plumbing, and adds a second startup dependency.
  - Reading the cubit directly inside core components: `core/` would then import `features/settings`, which violates Principle II's direction of dependency.

## Decision 10: Domain types

- **Decision**:
  - `GlassLevel` enum (`low`, `medium`, `high`), with wire values mirroring the `AppThemeMode.value` pattern.
  - `GlassAppearance` (Equatable: `enabled`, `transparency`, `intensity`, `copyWith`, `static const defaults = (true, medium, medium)`).
  - Both are Flutter-free, in `features/settings/domain/entities/`.
  - `GetGlassAppearancePreference` follows the `GetThemeModePreference` precedent.
  - `ChangeGlassAppearance` owns the retry-once policy.
- **Rationale**: Mirrors the existing settings feature exactly. Equatable equality is what makes the `BlocSelector` skip no-op rebuilds.
- **Note on Principle V**: `GetGlassAppearancePreference` is a thin read. It is kept for symmetry with the two existing `Get…Preference` use cases, since the cubit depends only on use cases. It is recorded in Complexity Tracking.

## Decision 11: Mapping domain to style lives in settings presentation

- **Decision**:
  - `core/design_system/glass/app_glass_tokens.dart` holds the numeric level table from Decision 7, as named constants for low, medium and high.
  - `features/settings/presentation/glass/glass_style_mapper.dart` maps `GlassAppearance` → `AppGlassStyle(enabled, tintAlpha(light/dark), blur)` by switching on `GlassLevel`.
- **Rationale**: Core cannot import a feature's domain enum. The feature can import core tokens. This matches how `AppThemeMode` is mapped to Flutter's `ThemeMode` only at the presentation boundary.

## Decision 12: Component set and naming

- **Decision** (in `lib/core/design_system/glass/`, `App` prefix):

  | Component | Replaces | OFF renders | ON adds |
  | --- | --- | --- | --- |
  | `AppTopBar` | `AppBar(...)` in 17 pages | the identical `AppBar` | transparent bar with an `AppGlassSurface` `flexibleSpace` |
  | `AppScaffold` | `Scaffold(...)` in the same pages and the compact shell | the identical `Scaffold` | `extendBodyBehindAppBar` / `extendBody` |
  | `AppNavigationBar` | the compact `NavigationBar` in `main_shell.dart` | the identical `NavigationBar` | transparent bar over an `AppGlassSurface` |
  | `AppFab` (`.new`, `.small`, `.extended`) | the FABs in 5 pages | the identical FAB | glass pill or circle behind a transparent FAB |
  | `showAppModalSheet` | the 1 `showModalBottomSheet` call | the identical call | transparent sheet background with a rounded-top `AppGlassSurface` behind the body |
  | `AppGlassInsets` | explicit scroll paddings | `EdgeInsets.zero` | `MediaQuery.paddingOf` |
  | `AppGlassSurface` | internal primitive | nothing (never built) | `GlassContainer` |

  `AppTopBar` is used instead of `AppAppBar` for readability. The prefix convention still holds.
- **Rationale**: The components replace the widgets one-for-one, so each screen change is mechanical and reviewable. Screens contain no branching (FR-014). When OFF the component returns the exact Material widget built from the same arguments, and no glass widget is constructed (FR-013, SC-003).
- **Out of scope (per spec, "MAY")**: menus (1 `PopupMenuButton`) and dialogs (2 `showDialog`). They stay as they are in v1.
- **Unchanged regardless of setting**: the `NavigationRail` (≥ 600dp), the splash, app lock and onboarding.

## Decision 13: Behaviour when no scope is present

- **Decision**: `AppGlassScope.maybeOf(context)` returning `null` is treated as **glass OFF**.
- **Rationale**: Every existing widget test pumps pages without the app root, so they keep rendering the exact pre-feature widgets and pass unchanged (SC-008). Production always has the scope, because `main.dart` inserts it.

## Decision 14: Settings UX

- **Decision**:
  - Settings gains an **Appearance** group directly below the Theme section, built with the existing `_SettingsSection` + `AppCard` pattern.
  - It contains a `SwitchListTile` for "Liquid Glass".
  - When ON, an `AnimatedSize` reveals two Material `SegmentedButton<GlassLevel>` rows ("Glass transparency", "Glass intensity": Low / Medium / High) and a **preview** tile.
  - The preview is a fixed-height `Stack`. Its backdrop comes from `colorScheme` (primary, tertiary and secondary shapes plus a line of sample text), and an `AppTopBar`-style `AppGlassSurface` strip carrying a localized sample title and icon sits on top.
  - Settings controls are Material, not `GlassSwitch`/`GlassSegmentedControl`.
- **Rationale**:
  - Material controls match every other Settings row and avoid putting interactive glass inside glass, which the package itself warns against.
  - The preview uses the same `AppGlassSurface` and scope, so it can't drift from the real bars (FR-015).
  - `SegmentedButton` gives three equally sized, labelled, accessible targets and mirrors in RTL.
  - Because the preview depends on `AppGlassScope`, it rebuilds on level changes and nothing else does.

## Decision 15: Accessibility

- **Decision**:
  - Keep `respectSystemAccessibility: true`. On iOS, "Increase Contrast" (`MediaQuery.highContrastOf`) makes the package swap glass for its plain frosted rendering, and reduce-motion (`MediaQuery.disableAnimationsOf`) stills glass motion.
  - The Decision 7 floors are the Android guarantee.
  - Material widgets keep semantics, tooltips, 48dp targets and text scaling.
  - The preview gets a `Semantics` label describing it as a sample, and is excluded from focus traversal.
- **Spike (S4)**: Verify that the frosted fallback under "Increase Contrast" still uses our explicit `settings` tint. If it doesn't, confirm that the fallback surface still meets SC-005.

## Decision 16: Testing strategy

- **Unit**:
  - `SettingsRepositoryImpl`: per-field defaults for `NULL` and unknown values.
  - `SettingsDao`: a glass write doesn't clobber language or theme, and vice versa.
  - Migration v7 → v8: columns added and existing rows preserved, following `app_database_migration_test.dart`.
  - `ChangeGlassAppearance`: the retry-once policy.
  - `glass_style_mapper`: every level maps to the right token.
- **Cubit** (`bloc_test`):
  - `initialize` with no row, a partial row, and a full row;
  - each `set…` emits immediately;
  - a persist failure raises `isGlassPersistFailing` without rolling back;
  - rapid changes end on the last value.
- **Widget**:
  - For each component, OFF produces the identical Material widget and properties, with `find.byType(GlassContainer)` finding nothing.
  - For each component, ON produces exactly one `GlassContainer` with semantics and tooltip intact.
  - Checks at text scale 2.0 and in RTL.
  - The Settings page shows and hides the controls and preview, and the preview updates on level change.
  - A root rebuild test: a glass change doesn't rebuild `MaterialApp`, and a scroll position on another tab survives.
- **Package in tests (verified)**: the package detects `FLUTTER_TEST` and adjusts its shader asset path. **Spike (S5)**: confirm that `GlassContainer` pumps without error in `flutter test`. If it doesn't, ON-mode widget tests stub `AppGlassSurface` through a scope flag.
- **Manual**: the Verification Matrix in `quickstart.md`, plus a `--profile` frame-timing run on a mid-range Android device and an iPhone (SC-006).
