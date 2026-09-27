# Contract: Adaptive glass components (UI)

**Location**: `lib/core/design_system/glass/`. This is the **only** directory that imports `package:liquid_glass_widgets`.

## Invariants (apply to every component)

1. **OFF identity**: When `AppGlassScope.maybeOf(context)` is `null` or has `enabled == false`, the component returns the Material widget it replaces, built from exactly the arguments the caller passed, with no additions. No package widget is constructed (FR-013, SC-003).
2. **ON additions only**: When glass is ON, the component may set the replaced widget's background, surface tint and elevation to transparent or 0, and place **one** `AppGlassSurface` behind it. It MUST NOT change the widget's:
   - callbacks
   - semantics, tooltips or keys
   - child, title or actions
   - sizes or touch targets
   - text styles
3. **No nesting**: An `AppGlassSurface` is never placed inside another `AppGlassSurface` (FR-012). A debug assertion checks this through an inherited marker.
4. **Scoped rebuilds**: Only components (and the Settings preview) call `AppGlassScope.of`/`maybeOf`. Screens never read the glass state (FR-014, FR-022).
5. **Theme and direction**: The tint comes from `Theme.of(context).colorScheme.surface`. All layout uses directional APIs, so it mirrors in RTL (FR-017, FR-018).

## Components

### `AppGlassScope` (InheritedWidget)

- `AppGlassScope({required AppGlassStyle style, required Widget child})`.
- `static AppGlassStyle? maybeOf(BuildContext)` and `static AppGlassStyle of(BuildContext)`. `of` returns `AppGlassStyle.off` when no scope is present.
- `updateShouldNotify` returns `old.style != style`.
- Inserted once, in `main.dart`'s `MaterialApp.builder`, above `AppStartupGate`, fed by a `BlocSelector` on `SettingsState.glassAppearance`.

### `AppGlassSurface` (primitive, used internally and by the Settings preview)

- Props: `child`, `borderRadius` (default 0), `padding`.
- It builds the following, with the tint alpha picked by `Theme.of(context).brightness`:

  ```dart
  GlassContainer(
    shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
    quality: GlassQuality.standard,
    settings: LiquidGlassSettings(
      glassColor: surface.withValues(alpha: tintAlpha),
      blur: style.blur,
      thickness: 10,
      bodyMode: GlassBodyMode.clear,
    ),
    child: child,
  )
  ```

### `AppTopBar implements PreferredSizeWidget`

- Accepts the subset of `AppBar` parameters used across the 17 pages (finalized by the task audit): `title`, `actions`, `leading`, `automaticallyImplyLeading`, `bottom`, `centerTitle`, and the rest.
- `preferredSize` is identical to the equivalent `AppBar`.
- OFF: `AppBar(...)`.
- ON: `AppBar(..., backgroundColor: transparent, surfaceTintColor: transparent, scrolledUnderElevation: 0, elevation: 0, flexibleSpace: AppGlassSurface())`.

### `AppScaffold`

- Forwards the `Scaffold` parameters used by the migrated pages.
- ON: `extendBodyBehindAppBar: appBar != null`, and `extendBody: bottomNavigationBar != null`.
- OFF: both use the caller's value, which defaults to `false`.

### `AppNavigationBar`

- Same parameters as the `NavigationBar` usage in `main_shell.dart`.
- ON: a `Stack` with an `AppGlassSurface` filling the bar's bounds, including the bottom safe area, under a `NavigationBar(backgroundColor: transparent, surfaceTintColor: transparent, elevation: 0)`.
- Used only in the compact (< 600dp) layout. The `NavigationRail` is unchanged.

### `AppFab` (`AppFab`, `AppFab.small`, `AppFab.extended`)

- Same parameters as the corresponding `FloatingActionButton` constructors used in the app: `onPressed`, `tooltip`, `child`/`icon`/`label`, `heroTag`.
- ON: an `AppGlassSurface` shaped to the FAB's own shape (the theme's `floatingActionButtonTheme` shape, or its default radius) behind a `FloatingActionButton` with transparent background, elevation 0, and foreground `colorScheme.primary`.

### `showAppModalSheet<T>`

- Same parameters as the single existing `showModalBottomSheet` call: `context`, `builder`, `isScrollControlled`.
- OFF: `showModalBottomSheet<T>(...)` with the identical arguments.
- ON: `showModalBottomSheet<T>(..., backgroundColor: transparent, elevation: 0, builder: (c) => AppGlassSurface(borderRadius: AppRadius.lg /* top only via clip */, child: builder(c)))`.

### `AppGlassInsets`

- `static EdgeInsets of(BuildContext context)` returns `MediaQuery.paddingOf(context)` when ON, and `EdgeInsets.zero` when OFF.
- Scrollables that set an explicit `padding:` inside an `AppScaffold` body add it, for example `padding: base + AppGlassInsets.of(context)`.

## Test obligations (per component)

| Check | OFF | ON |
| --- | --- | --- |
| `find.byType(GlassContainer)` | finds nothing | finds one |
| Same callbacks fire on tap | ✓ | ✓ |
| Tooltip and semantics label present | ✓ | ✓ |
| Text scale 2.0: no overflow | ✓ | ✓ |
| `Directionality.rtl`: leading and trailing mirrored | ✓ | ✓ |
