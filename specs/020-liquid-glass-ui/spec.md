# Feature Specification: Configurable Liquid Glass UI

**Feature Branch**: `020-liquid-glass-ui`

**Created**: 2026-09-27

**Status**: Draft

**Input**: User description: "Integrate the Flutter package `liquid_glass_widgets` into the application as an optional, user-configurable visual experience. Users can enable or disable Liquid Glass from Settings and, where officially supported by the package, customize transparency and glass intensity, with a live preview. Glass is applied selectively to navigation and control chrome through reusable adaptive components; when disabled, the existing UI is restored unchanged. Must preserve architecture, business logic, navigation, localization (Arabic/English, RTL/LTR), Light/Dark themes, accessibility, and performance on Android and iOS." (full description retained in the `/speckit-specify` invocation)

## Clarifications

### Session 2026-09-27

- Q: Which screens' top app bars should switch to glass when Liquid Glass is ON? → A: **Default adopted (not user-confirmed)**: all 17 screens that have an app bar, through one shared adaptive app bar (Option B). The user moved on to `/speckit-plan` without answering, so the recommended option was taken. Revisit before implementation if a narrower scope is wanted.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Turn Liquid Glass on or off (Priority: P1)

A user opens Settings, finds a **Liquid Glass** switch in the Appearance section, and turns it on or off. With it on, the app's navigation and control chrome (app bars, bottom navigation, floating action buttons, modal sheets) takes on the frosted Liquid Glass look. With it off, every screen looks and behaves exactly as it does today. The choice is remembered across navigation and app restarts.

**Why this priority**: The on/off switch is the core of the feature and its safety valve. Without it nothing else is reachable, and it guarantees users who dislike the effect, or whose devices struggle with it, can return to today's UI.

**Independent Test**: Toggle the switch, visit the home shell, a list screen, and a screen with a modal sheet, then restart the app. Glass chrome appears only when ON and survives the restart. When OFF, the screens match the pre-feature app.

**Acceptance Scenarios**:

1. **Given** Liquid Glass is OFF, **When** the user turns it ON in Settings, **Then** the in-scope surfaces (see FR-010) switch to the glass look immediately, without leaving Settings or restarting.
2. **Given** Liquid Glass is ON, **When** the user turns it OFF, **Then** every in-scope surface returns to its existing appearance and no glass rendering remains anywhere in the app.
3. **Given** the user set Liquid Glass to a value, **When** they navigate to other screens and back, or fully close and relaunch the app, **Then** the same value is in effect from the first rendered frame after launch.
4. **Given** Liquid Glass is ON or OFF, **When** the user performs any existing action (add a transaction, switch tabs, open a sheet, change language), **Then** the outcome is identical to today. Only appearance differs.
5. **Given** saving the preference fails, **When** the user changes the switch, **Then** the change still takes effect for the current session and a small non-blocking notice tells the user it could not be saved, matching how language/theme save failures are handled today.

---

### User Story 2 - Adjust how strong the glass looks (Priority: P2)

With Liquid Glass ON, the user sees two extra controls: **Glass Transparency** (how see-through the glass surfaces are) and **Glass Intensity** (how strongly the glass blurs what is behind it). Each offers a small set of safe levels (Low / Medium / High). The chosen levels apply to every glass surface in the app and are remembered across restarts.

**Why this priority**: Customization adds comfort and personal choice, but the feature is already valuable with the defaults alone.

**Independent Test**: With glass ON, change each control to each level. Glass surfaces across the app reflect the new level. After a restart the levels are unchanged. With glass OFF, the controls are hidden.

**Acceptance Scenarios**:

1. **Given** Liquid Glass is ON, **When** the user opens Settings, **Then** Glass Transparency and Glass Intensity controls are visible, each showing its current level.
2. **Given** Liquid Glass is OFF, **When** the user opens Settings, **Then** the two customization controls are hidden, and their last values are retained for when glass is turned back on.
3. **Given** the user picks any available level, **When** they view glass surfaces over busy content (e.g. a scrolled transaction list behind the app bar), **Then** titles, icons and labels on the glass remain clearly readable. No selectable level produces an unreadable state.
4. **Given** a stored level is missing, corrupted, or unrecognized (e.g. after an upgrade), **When** the app starts, **Then** that setting falls back to its default (Medium) without error.

---

### User Story 3 - Live preview in Settings (Priority: P3)

Directly beneath the Liquid Glass controls, the user sees a small preview: a glass sample placed over a colorful, theme-derived backdrop. The preview updates instantly as they change transparency or intensity, and follows the current Light/Dark mode and language direction.

**Why this priority**: The preview makes abstract levels understandable before leaving Settings. It is a convenience layered on User Story 2.

**Independent Test**: In Settings with glass ON, change each level and switch Light/Dark and Arabic/English. The preview changes appearance immediately each time and remains legible.

**Acceptance Scenarios**:

1. **Given** Liquid Glass is ON, **When** the user changes Transparency or Intensity, **Then** the preview reflects the new value within the same interaction, with no perceptible delay.
2. **Given** the app is in Dark mode (or Light mode), **When** the preview is shown, **Then** its backdrop and glass follow that mode's colors.
3. **Given** the app is in Arabic, **When** the preview is shown, **Then** its content is laid out right-to-left with localized text.
4. **Given** Liquid Glass is OFF, **When** the user views Settings, **Then** the preview is hidden.
5. The preview is built from the same glass building blocks the rest of the app uses, so what the user sees matches the real surfaces.

---

### User Story 4 - Glass used only where it helps (Priority: P2)

A user browsing the app with glass ON sees it on floating chrome (the top app bar, the bottom navigation bar, floating action buttons, and modal bottom sheets) while the content itself (lists of people and transactions, cards, forms, text sections, page backgrounds) stays opaque and easy to read.

**Why this priority**: Selective application protects readability and performance, which are the main risks of the feature. It is delivered together with User Story 1, since the switch has to affect something.

**Independent Test**: With glass ON, walk through Home, People, a person detail, Finance history, Settings, and a modal sheet flow. Confirm glass appears only on the intended surfaces and that list items, form fields, and page backgrounds are unchanged.

**Acceptance Scenarios**:

1. **Given** glass is ON, **When** the user scrolls a long list, **Then** content scrolls beneath the glass app bar/bottom bar, and no individual list item is rendered as glass.
2. **Given** glass is ON, **When** the user opens a form (e.g. add transaction), **Then** input fields keep their existing appearance.
3. **Given** glass is ON, **When** a surface that normally shows glass is displayed on top of another glass surface (e.g. a sheet over the glass bottom bar), **Then** glass layers are not stacked inside one another in a way that degrades legibility.

---

### User Story 5 - Consistent with themes, languages, platforms and accessibility (Priority: P2)

A user in Arabic dark mode on Android, or English light mode on iPhone, gets a glass experience that matches their theme colors and reading direction. If the user has enabled system accessibility options such as increased contrast, reduced transparency or reduced motion, the app honors them.

**Why this priority**: These are cross-cutting guarantees that apply to every surface touched by User Stories 1–4. Breaking any of them is a regression.

**Independent Test**: Run the Verification Matrix below (glass ON/OFF × Light/Dark × Arabic/English × Android/iOS), plus one pass with the OS high-contrast / reduce-transparency setting on.

**Acceptance Scenarios**:

1. **Given** any combination of Light/Dark and Arabic/English, **When** glass is ON, **Then** glass surfaces use the app's existing theme colors and typography, and layout direction is mirrored correctly in RTL.
2. **Given** the OS "increase contrast" or "reduce transparency" setting is on, **When** glass is ON, **Then** glass surfaces fall back to a more opaque, higher-contrast presentation that stays readable.
3. **Given** the user uses the largest system text size, **When** glass is ON, **Then** text on glass surfaces scales exactly as it does with glass OFF, without clipping, and touch targets keep at least their existing size.
4. **Given** a supported Android or iOS device, **When** glass is toggled ON or OFF, **Then** the app keeps working on both platforms. Glass is not restricted to one platform.

---

### Edge Cases

- **First launch / upgrade**: No stored glass preference exists, so the defaults apply (Liquid Glass ON, Transparency Medium, Intensity Medium). This includes existing users upgrading, who will see glass chrome after the update and can turn it off in Settings.
- **Corrupted or unknown stored value**: Any unreadable stored value for a single glass setting falls back to that setting's default. The other settings are unaffected.
- **Save failure**: The change applies in-session and a non-blocking localized notice appears. The app never blocks or crashes.
- **Toggling rapidly**: Repeated quick taps on the switch or levels settle on the last selection, both on screen and in storage.
- **Toggling while a sheet or dialog is open**: Not reachable from Settings itself. Any surface opened after the change uses the new mode.
- **Device lacks the advanced rendering path** (e.g. older Android GPU or renderer fallback): the package's own fallback applies. The app still shows a legible, frosted-style surface and never a blank or broken one.
- **Very bright or very dark content behind glass**: Titles and icons on glass remain readable at every selectable level.
- **Wide layouts** (the shell's navigation-rail mode at ≥ 600dp): The rail keeps its current appearance unless explicitly in scope. Only the compact bottom-bar layout is required to adopt glass.
- **Splash / app lock / onboarding**: These full-screen, brand-controlled flows are unchanged regardless of the glass setting.

## Requirements *(mandatory)*

### Functional Requirements

#### Settings & persistence

- **FR-001**: The Settings screen MUST contain an Appearance area (alongside the existing Theme section) with a **Liquid Glass** ON/OFF switch.
- **FR-002**: Changing the switch MUST take effect app-wide immediately, without restart and without leaving Settings.
- **FR-003**: The Liquid Glass on/off state, Glass Transparency level, and Glass Intensity level MUST persist across navigation and app restarts. They MUST be stored in the app's existing settings storage alongside the language and theme preferences, not in a new parallel storage mechanism.
- **FR-004**: The persisted values MUST be applied from the first rendered frame after launch, so users never see a flash of the wrong mode.
- **FR-005**: Defaults when no value is stored, or when a stored value is unrecognized: Liquid Glass **ON**, Glass Transparency **Medium**, Glass Intensity **Medium**.
- **FR-006**: If saving a glass preference fails, the app MUST keep the new value for the current session and show a localized, non-blocking notice, consistent with the existing language/theme save-failure behavior.

#### Customization

- **FR-007**: When Liquid Glass is ON, Settings MUST offer **Glass Transparency** and **Glass Intensity** controls, each with exactly three levels: Low, Medium, High. When Liquid Glass is OFF these controls and the preview MUST be hidden, and their stored values MUST be retained.
- **FR-008**: Each level MUST correspond to a fixed, pre-validated appearance value chosen so that every level keeps text and icons on glass readable in both Light and Dark modes. Users MUST NOT be able to select a value outside these levels.
- **FR-009**: Only customization dimensions the package officially supports MAY be exposed to users. Transparency and Intensity are the only user-facing dimensions for this feature. Rendering quality, highlight sharpness, tint and other package options MUST NOT be user-facing, and MAY be set internally per surface as the package recommends.

#### Where glass appears

- **FR-010**: When Liquid Glass is ON, glass MUST be applied to these surfaces, and to no others unless the plan justifies it explicitly:
  - the top app bar of every screen that has one (17 screens today), through one shared adaptive app bar
  - the compact-layout bottom navigation bar of the main shell
  - floating action buttons
  - modal bottom sheets

  Menus and important floating controls MAY be included if the plan identifies clear value and no readability cost.
- **FR-011**: Glass MUST NOT be applied to individual list items, general containers/cards in scrolling content, text sections, form input fields, large scrolling content areas, or full-screen backgrounds.
- **FR-012**: Glass surfaces MUST NOT be nested inside other glass surfaces.
- **FR-013**: When Liquid Glass is OFF, each in-scope surface MUST render exactly its pre-feature implementation, and no glass rendering work MUST occur anywhere in the app.

#### Reusable components

- **FR-014**: Each in-scope surface MUST be provided through a single reusable adaptive component. The component chooses the glass or the existing implementation from the current setting, so no screen is duplicated and no screen contains its own on/off branching logic. Names MUST follow the existing design-system convention (`App…` prefix).
- **FR-015**: The Settings preview MUST be built from these same adaptive components.
- **FR-016**: Adopting glass MUST NOT change any repository, use case, domain entity, or business rule outside the settings feature, nor any navigation route or interaction behavior.

#### Theme, localization, accessibility, platform

- **FR-017**: Glass surfaces MUST derive colors and typography from the existing theme and design tokens. They MUST follow the active Light/Dark mode, including "System default", and MUST update when the mode changes.
- **FR-018**: All new user-facing text MUST be localized in Arabic and English, and all new UI MUST mirror correctly in RTL.
- **FR-019**: The app MUST keep the package's automatic accessibility bridging on, so the OS reduce-motion setting and iOS "Increase Contrast" swap glass for its plain frosted, non-animated presentation. Because Android exposes no equivalent flag, the level floors in FR-008 are the readability guarantee on Android.
- **FR-020**: Glass surfaces MUST preserve existing semantics labels, touch target sizes, dynamic text scaling, and interaction behavior.
- **FR-021**: The feature MUST be available on both Android and iOS, with no platform-specific restriction beyond the package's own documented fallbacks.

#### Performance

- **FR-022**: Changing a glass setting MUST rebuild only UI that depends on it. The app-level router, localization and theme MUST NOT be rebuilt by a glass-only change, and unrelated screens' state (scroll positions, form input, open cubits) MUST be preserved. The same holds in reverse: a language or theme change MUST NOT require any glass-specific rebuild beyond what the theme change already causes.
- **FR-023**: Glass effects MUST NOT be applied inside scrolling lists. Any higher-cost rendering option MUST be limited to static, non-scrolling surfaces, as the package recommends.

### Key Entities

- **Glass Appearance Preference**: The user's Liquid Glass configuration. It has an enabled flag (on/off), a Transparency level (Low/Medium/High), and an Intensity level (Low/Medium/High). It is stored with, and is part of, the existing app-wide user preferences (language, theme mode). Each field falls back independently to its default.
- **Glass Level**: A named, bounded step (Low/Medium/High) that maps to one fixed, readability-validated appearance value. It is the only form in which users influence glass appearance.

## Package Capability Findings *(discovery requirement)*

Verified against the published source of `liquid_glass_widgets` **1.7.2** (pub.dev archive, September 2026), not only its README. Its pubspec declares Flutter `>=3.41.0`, Dart `>=3.5.0 <4.0.0`, and no dependencies besides Flutter.

| Topic | Verified finding | Impact on this spec |
| --- | --- | --- |
| Versions | Needs Flutter ≥ 3.41 and Dart ≥ 3.5. The project is on Flutter 3.47 with Dart SDK `^3.10`. | Compatible. |
| Platforms | iOS, Android, macOS, Web, Windows, Linux. Rendering paths: iOS on Impeller/Metal and Android on Impeller/Vulkan get the full pipeline; Android on Impeller/GLES gets a reduced 8-shape pipeline; Skia/Web get a lightweight 2D shader. Devices without shader-filter support fall back automatically. | Android and iOS are both supported, with no platform gating (FR-021). |
| Initialization | `LiquidGlassWidgets.initialize()` (async shader preload) and `LiquidGlassWidgets.wrap(child:, theme:, respectSystemAccessibility:, adaptiveQuality:, brightnessResolver:)`. `wrap` does only two things: it sets globals, and inserts a `GlassTheme` when a theme is passed. | Setup at startup. `brightnessResolver: Theme.maybeBrightnessOf` bridges the app's Light/Dark/System mode (FR-017). |
| Runtime theming | `GlassTheme` is an `InheritedWidget` taking `GlassThemeData(light:, dark:)`, where each side is a `GlassThemeVariant(settings:, quality:, borderRadius:, glowColors:)`. It can be placed and updated anywhere in the tree, and only widgets that depend on it rebuild. | User levels can be applied live without rebuilding the app (FR-002, FR-022). |
| **Transparency** | Controlled by the **alpha of `glassColor`** ("opacity defines the intensity of the tint"). Defaults are `RGBO(210,220,240,0.12)` in light and `RGBO(255,255,255,0.08)` in dark. `thickness` is **not** opacity: it is refraction depth (defaults 12 light / 10 dark). | Glass Transparency sets the tint alpha. Lower alpha means more see-through. |
| **Intensity** | `blur` is the frost radius, default 5 light / 4 dark. `blur: 0` is clear optical glass, not a flat fill. | Glass Intensity sets the blur radius. |
| Other properties (exist in the API) | `thickness`, `lightIntensity`, `lightAngle`, `ambientStrength`, `refractiveIndex`, `saturation`, `chromaticAberration` (marked "WIP"), `fresnelStrength`, `edgeAbsorption`, `specularSharpness`, and a theme-level `borderRadius`. Shadow-related fields `shadowElevation`, `shadow` and `whitenStrength` exist only on per-widget `LiquidGlassSettings`, not on the theme. | Supported, but none is user-facing (FR-009). The plan may tune them internally per level. |
| Quality | `GlassQuality.standard`, `premium` (Impeller only; "may not render correctly inside ListView/CustomScrollView"), and `minimal` (shader-free BackdropFilter). `GlassTabBar.bottom` defaults to premium, and `GlassScaffold` promotes app bars and bottom bars to premium. | Set internally per surface: premium only on static chrome, standard or minimal elsewhere (FR-023). |
| Widgets | `GlassAppBar` (an iOS-style `ObstructingPreferredSizeWidget`), `GlassTabBar` (`.bottom`), `GlassNavigationShell`, `GlassScaffold`, `GlassButton`, `GlassIconButton`, `GlassSheet`, `GlassModalSheet`, `GlassMenu`, `GlassDialog`, `GlassSwitch`, `GlassSlider`, `GlassSegmentedControl`, `GlassCard`, `GlassContainer`, and about 40 more. There is **no dedicated floating-action-button widget**. | A glass FAB is built from `GlassButton`/`GlassIconButton` placed in the existing FAB slot. |
| Backdrop | Glass is only visible when content sits behind it. `GlassScaffold` handles backdrop isolation and edge fading. On Skia/Web, refraction needs a `LiquidGlassScope` + `GlassBackgroundSource`. | Glass chrome over a plain surface reads as a lightly tinted bar. See Clarifications for the layout decision. |
| Accessibility | `GlassAccessibilityScope(reduceMotion:, reduceTransparency:)` reads `MediaQuery.disableAnimationsOf` and **`MediaQuery.highContrastOf`** by default (`respectSystemAccessibility: true`). With reduce-transparency active, glass is replaced by a plain frosted surface. | This works automatically on iOS ("Increase Contrast"). Android reports no high-contrast flag through Flutter, so readability there depends on the level floors (FR-008). |
| RTL | README: "Full RTL support — layouts, drag directions, tab ordering, and physics auto-reverse". `GlassAppBar` resolves text direction. | Compatible with Arabic (FR-018). Still verified in the matrix. |
| Recommended usage | Glass is for navigation and control chrome only. Content stays opaque. "Glass is a platter, not a wrapper": no interactive glass inside `GlassCard`/`GlassContainer`. | Matches FR-010 to FR-012. |

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can find and toggle Liquid Glass from the Settings screen in under 15 seconds, and the visible change appears in under 0.5 seconds without a restart.
- **SC-002**: In 100% of restart tests, the Liquid Glass on/off state and both levels come back exactly as the user left them, from the first frame.
- **SC-003**: With Liquid Glass OFF, screenshots of every in-scope screen match the pre-feature app in both themes and both languages: zero visual differences.
- **SC-004**: With Liquid Glass ON, every in-scope screen in the Verification Matrix (Light/Dark × Arabic/English × Android/iOS) renders glass only on the surfaces listed in FR-010, with zero glass list items, form fields, or page backgrounds.
- **SC-005**: At every selectable Transparency/Intensity level, primary text and icons on glass surfaces meet a contrast ratio of at least 4.5:1 for text and 3:1 for icons over representative light and dark content.
- **SC-006**: Scrolling the longest list screen with glass ON on a mid-range Android device and a recent iPhone produces no visible jank. Frame build and raster times stay within the device's frame budget for at least 95% of frames.
- **SC-007**: Changing any glass setting preserves scroll position and in-progress input on other screens in the navigation stack.
- **SC-008**: The full existing automated test suite passes unchanged with Liquid Glass both ON and OFF, confirming no change to business behavior.
- **SC-009**: A new glass-enabled surface can be added by reusing the shared adaptive components and configuration, with no new settings, storage, or state logic.

### Verification Matrix

| Mode | Theme | Language/Direction | Platform | Check |
| --- | --- | --- | --- | --- |
| ON | Light, Dark | English (LTR), Arabic (RTL) | Android, iOS | Glass only on intended surfaces. Levels apply. Settings persist. Preview updates. Readable. |
| OFF | Light, Dark | English (LTR), Arabic (RTL) | Android, iOS | Identical to the pre-feature UI. No glass rendering. Business flows unchanged. |
| ON + OS Increase Contrast | Light, Dark | Either | iOS | Glass falls back to a plain frosted, readable presentation. |
| ON, High transparency, busiest backdrop | Light, Dark | Either | Android | Chrome text and icons still meet SC-005 without any OS flag. |

## Assumptions

- **Default ON applies to upgrades too**: The user specified Liquid Glass defaults to ON (FR-04). Existing users who upgrade will therefore see glass chrome immediately after the update. "UI unchanged" (User Story 10 of the input) is guaranteed whenever the switch is OFF, not for an upgraded install on default settings.
- **Three discrete levels** (Low/Medium/High) are used for both customization controls instead of free sliders. This enforces safe limits (FR-008), keeps Settings simple, and is easy to test. The exact package values behind each level are decided and validated in planning.
- **"Transparency" maps to the alpha of the package's `glassColor` tint, and "Intensity" maps to its `blur` radius** (verified in source; `thickness` is refraction depth, not opacity). Each level is a fixed light/dark pair of those two values, applied through the glass theme.
- **Existing architecture (verified in repo)**: Settings state lives in the root-scoped `SettingsCubit`, provided above `MaterialApp.router` in `main.dart`, which already owns the language and theme mode and their retry-once save policy. Persistence is the drift `AppSettings` single-row table (`id = 'singleton'`) behind `SettingsRepository`/`SettingsDao`. Adding the glass fields raises the schema from version 7 to 8. Saved settings load behind `AppStartupGate` (the splash), which is what makes FR-004's "first frame" guarantee achievable. Today the root `BlocBuilder<SettingsCubit>` rebuilds the whole `MaterialApp` on any state change, so FR-022 requires the glass fields to be read through a selector (or `buildWhen`) instead of that builder.
- **Component home**: The adaptive components live in `lib/core/design_system/` with the existing `App…` prefix (alongside `AppCard`, `AppButton`). This is justified by constitution Principle XV, since they are used across several features. Each component reads the glass state itself, so screens contain no on/off branching.
- **Current surface inventory (verified)**:
  - 17 pages build a raw Material `AppBar`. There is no shared app-bar component yet.
  - 5 pages use a `FloatingActionButton`.
  - There is 1 `showModalBottomSheet` call site (the duplicate-warning sheet).
  - There is 1 `PopupMenuButton` and 2 `showDialog` call sites.
  - The main shell (`main_shell.dart`) shows a `NavigationBar` below 600dp and a `NavigationRail` from 600dp up.
- **Settings location**: The existing Settings screen already has a Theme section. The Liquid Glass controls join it in an Appearance grouping rather than moving to a new screen.
- **Storage**: The existing single-row app-settings store (currently holding language and theme mode) is extended with the three glass fields. This requires a schema migration under the existing database migration process.
- **State**: The existing root-level settings state holder (already providing language and theme mode above the app) owns the glass preference. No new state-management approach is introduced.
- **Scope of surfaces**: Only the compact bottom navigation bar is in scope. The wide-layout navigation rail, the splash screen, app-lock screen, and onboarding flow keep their current appearance.
- **Package risk**: The package is young and fast-moving, at 1.x with frequent releases. The version is pinned to a compatible minor release and re-verified during planning. If a documented capability turns out not to exist, the corresponding control is dropped rather than imitated with custom rendering.

## Out of Scope

- A redesign of the app, or replacement of the design system, navigation, state management, or persistence.
- Applying glass to every screen or surface automatically, or to content areas, lists, forms, or backgrounds.
- User-facing controls for tint, saturation, brightness, quality, shadow, corner radius, refraction, highlight sharpness, or style variants.
- Custom glass rendering to imitate capabilities the package does not officially provide.
- Changes to business logic, repositories, use cases, or domain models outside the settings feature.
