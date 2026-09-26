# Research: Branded Splash Screen (019)

All Technical Context unknowns are resolved below. Each decision cites the code it was checked against.

## Decision 1 — Startup work moves behind the splash; DI registration stays before `runApp`

- **Decision**: `main()` keeps `await configureDependencies()` before `runApp` and moves the two I/O steps it currently awaits, `SettingsCubit.initialize()` and `OnboardingCubit.initialize()`, into a new `AppStartupCubit` that runs while the splash is on screen.
- **Rationale**: `configureDependencies()` is `getIt.init()`. All registrations are lazy (`@lazySingleton`, no `@preResolve`), and `AppDatabase` opens lazily, so it does no I/O and costs microseconds. The widget tree needs it anyway (`DaftaryApp` reads `getIt<SettingsCubit>()`). The awaited cubit initializations are what hit SQLite; they are why the first frame waits today and why a failure currently leaves a blank screen (spec FR-011, FR-016).
- **Alternatives rejected**:
  - *Keep everything awaited before `runApp` and show a decorative splash afterwards*: this adds the animation on top of the existing wait, which breaks SC-002, and still can't show an error.
  - *Move DI behind the splash too*: nothing to gain, and it would force the splash to exist outside `DaftaryApp`'s providers.

## Decision 2 — The splash is a gate in `MaterialApp.router(builder:)`, not a route

- **Decision**: `DaftaryApp` passes `builder: (context, router) => AppStartupGate(child: router!)`. Until hand-off, the gate renders only the splash and does **not** mount `router`. At hand-off it mounts `router` underneath and fades the splash out, then removes it.
- **Rationale**:
  - `WidgetsApp` builds the `Router` widget and hands it to `builder` as `child`. Not mounting it means GoRouter parses nothing and runs no `redirect` until startup is `ready`. So the existing redirect in `lib/core/routing/app_router.dart`, which reads `OnboardingCubit.state` synchronously, still only runs against a settled state, exactly as its comment requires. No routing logic changes and the destination is chosen in one place (FR-013, no duplicated navigation).
  - Navigation happens once, when the `Router` first mounts, and the gate's one-way `_handedOff` latch guarantees that mount happens once (FR-014).
  - The splash never enters any navigator's history, so Back can't return to it (FR-010).
  - `builder` output sits below `MaterialApp`'s `Localizations`, `Directionality`, `MediaQuery`, `AnimatedTheme` and `ScaffoldMessenger`, so the splash gets the real theme and l10n for free.
- **Alternatives rejected**:
  - *`/splash` GoRoute plus `redirect` and `refreshListenable`*: this changes the router's settled-state contract, puts the splash into history, and needs extra code to remember a notification's cold-start target.
  - *Two separate `MaterialApp`s swapped by an `AnimatedSwitcher`*: this duplicates theme and l10n wiring and throws away the `ScaffoldMessenger`.

## Decision 3 — `AppStartupCubit` coordinates the existing initializers (presentation-only feature)

- **Decision**: Add a new feature, `lib/features/startup/`, with presentation code only. `AppStartupCubit` (`@lazySingleton`) depends on `SettingsCubit` and `OnboardingCubit` and calls their existing `initialize()` methods in order. It has a 10 s budget and per-step memoization, so retry re-runs only the unfinished steps and joins a step that is still in flight instead of starting a duplicate.
- **Rationale**: Constitution III requires BLoC/Cubit for presentation state. There is no new business rule, repository or persistence, so a Domain or Data layer would be empty ceremony (Principle V forbids trivial wrapper use cases). The work is purely orchestration of two presentation-level initializers that already own their use cases.
- **Alternatives rejected**:
  - *A domain `InitializeApp` use case*: Domain can't depend on the presentation cubits it would need to settle.
  - *Logic inside the gate widget*: this puts side effects in widgets, is not unit-testable, and violates Principle III.

## Decision 4 — Post-ready services start from `main.dart`, after readiness

- **Decision**: `NotificationRecomputeTrigger.start()` and `NotificationTapRouter.start(appRouter)` stay in `main.dart`, chained on `AppStartupCubit.whenReady`. They are no longer called unconditionally before `runApp`.
- **Rationale**:
  - This keeps today's order: they already ran after both initializers had completed.
  - It avoids competing for the database while startup is still resolving.
  - It keeps the cubit free of routing and notification dependencies, and it keeps the integration tests' `bootApp()` helpers, which never started these services, behaving as before.
  - If the tap router calls `router.go(target)` before the `Router` is mounted, it only updates GoRouter's `routeInformationProvider`. The `Router` parses that value when it mounts, so a notification cold-start still lands on its target (FR-013).
  - A "no longer exists" snackbar queued while the splash is up appears on the first `Scaffold` after hand-off, because the splash uses `Material`, not `Scaffold`.
- **Alternative rejected**: *Inject both services into the cubit*: this couples startup to notifications and `appRouter`, and adds no testability.

## Decision 5 — Hand-off timing

- **Decision**: Hand off when `intro finished AND state.status == ready`, whichever happens last. With reduced motion, the intro counts as finished on the first frame. There is no fixed minimum hold. Once `failed`, the gate stays on the splash in its error layout until a retry succeeds.
- **Rationale**: This meets FR-012 and SC-002. When startup finishes first, the full (≤ 900 ms) story plays once. When the intro finishes first, the mark rests in its settled state without looping.

## Decision 6 — Mark drawn in Dart (`CustomPainter`), not as an image or animation file

- **Decision**:
  - Re-draw the launcher-icon mark with two painters. `SplashNotebookPainter` draws the static page stack, page, spine, binding holes, faint ledger lines and bookmark ribbon. It sits in its own `RepaintBoundary` and never repaints. `SplashMotionPainter` draws what moves: the person glyph, the connection path, the written ledger line and the coin.
  - Geometry lives in one constants class that mirrors the SVG in `assets/icon/build_icon.py`.
  - The "د" coin glyph is drawn with a `TextPainter` using the platform Arabic font, as the icon does.
- **Rationale**:
  - A painter is ready on the **first frame**. An image asset has to be decoded asynchronously, which would leave a blank frame and break launch-screen continuity (FR-005, SC-001).
  - It adds zero bundle size, stays crisp at every density, and lets individual parts of the mark animate.
  - It needs no new dependency (the constitution prohibits unjustified packages).
- **Alternatives rejected**:
  - *Lottie or Rive*: a new dependency, a runtime-parsed asset, and a first-frame delay.
  - *Layered PNGs*: decode latency and several MB across densities.
  - *`flutter_native_splash`*: not needed; the native changes are a handful of XML and storyboard edits (below).

## Decision 7 — Native launch screens show the first Flutter frame exactly

- **Decision**: The first frame is the brand field plus the notebook, with ledger lines faint and no coin, person or text. The native launch screens draw exactly that:
  - **Colors**: `splash_field` = `#1F6F5C` (`AppColors.primary`) in light and `#0E3D32` (the icon gradient's deep stop) in dark. Android defines it in `values/colors.xml` and `values-night/colors.xml`; iOS uses the `LaunchBackground` named color with light and dark appearances.
  - **Image**: `splash_mark` is rendered by `build_icon.py --splash` on a transparent canvas of **288 dp/pt**, rendered at 1152 px and only ever downscaled, with the notebook inside the central 192 dp circle. The `--splash` flag keeps the launcher-icon sources from being re-rendered. The geometry uses one pinned transform shared with the Dart painter: raw `MARK` → `translate(512,512) scale(0.9) translate(-517,-515)`.
    - Android: `drawable-{m,h,xh,xxh,xxxh}dpi/splash_mark.png` at 288/432/576/864/1152 px.
    - iOS: `LaunchImage.imageset` at 288/576/864 px.
  - **Android 12+ (API 31+)** always shows the system SplashScreen, whose icon must fit a 192 dp circle on a 288 dp canvas. `values-v31/styles.xml` and `values-night-v31/styles.xml` set `windowSplashScreenBackground=@color/splash_field` and `windowSplashScreenAnimatedIcon=@drawable/splash_mark`. A `-night-v31` file is needed because the `night` qualifier outranks the API-level qualifier.
  - **Android 7–11**: LaunchTheme also sets `windowDrawsSystemBarBackgrounds=true`, because the pre-Holo parent themes leave it off and the transparent status bar would otherwise be ignored.
  - **Android 7–11 background**: `drawable-v21/launch_background.xml` and `drawable/launch_background.xml` become a `splash_field` color layer plus a centered `splash_mark` bitmap at its intrinsic 288 dp. The white layer is removed.
  - **iOS**: `LaunchScreen.storyboard` declares the `Named colors` capability and its background becomes the `LaunchBackground` named color. The image view stays centered at the image's intrinsic 288 pt.
  - **Flutter**: draws the same 288-logical-px canvas centered on the full screen, not the safe area, because the native screens center on the full window.
- **Rationale**: The same canvas, scale and centering in all three layers means the hand-off shows no jump (FR-005). The launch screens can only follow the device's light/dark setting. Flutter's first frame also follows the device, because settings are still unresolved and `ThemeMode.system` is the default, so they match. An in-app theme override then shows up as a 200 ms field-color crossfade (spec Edge Cases).
- **System bars**:
  - The `LaunchTheme`s set transparent status and navigation bars with light icons (`windowLightStatusBar=false`, `windowLightNavigationBar=false`, allowed at minSdk 24/27). `windowLightNavigationBar` needs API 27, so it goes in `values-v27` or is skipped; the task checks the lint.
  - iOS adds `UIStatusBarStyle = UIStatusBarStyleLightContent`. With view-controller-based appearance (the default, since the key is absent), this only affects the launch screen.
  - In Flutter, the splash wraps itself in `AnnotatedRegion<SystemUiOverlayStyle>` (light icons, transparent bars). After it's removed, the app's own `AppBar`s set the overlay again as they do today.
- **Alternative rejected**: *Put the coin in the native image*: the coin is what moves, so frame 0 would not match.

## Decision 8 — Motion design (Flutter-native, one `AnimationController`)

- **Decision**: One `AnimationController` of **900 ms**, driven by `Interval`-based `CurvedAnimation`s. The exit is a separate 280 ms `FadeTransition`. All values below are fractions of the controller:

| Beat | Interval | Curve | What it says |
|---|---|---|---|
| Hold | 0.00–0.08 | — | Absorbs the native → Flutter hand-off; frame 0 = launch image |
| Person appears (reading-start side) | 0.08–0.30 | easeOutCubic (opacity 0→1, scale 0.8→1) | "someone in your life" |
| Connection path draws (person → ledger corner) | 0.12–0.45 | easeInOutCubic (path trim 0→1) | "a relationship" |
| Coin travels along the path | 0.30–0.72 | easeInOutCubic (position), scale 0.7→1 | "money given or received" |
| Coin settles on the corner | 0.72–0.84 | easeOutBack, scale 1.06→1 | "it landed" |
| Top ledger line is written, in reading direction | 0.60–0.86 | easeOutCubic (trim 0→1, faint → brand) | "recorded, balance kept" |
| Person and path fade | 0.78–1.00 | easeOut | leaves the logo, which matches the launcher icon |
| Name and tagline rise in | 0.55–1.00 | easeOutCubic (opacity 0→1, translateY 8→0 dp) | identity |

  - **RTL**: the person starts on the right (reading start) and the ledger line is written right-to-left. The notebook and coin landing corner are not mirrored (they're the logo).
  - **Reduced motion**: when `MediaQuery.disableAnimationsOf(context)` is true, the controller is set to `1.0` with no ticking, the field-color crossfade and exit fade use `Duration.zero`, and the gate hands off on the first frame after `ready`.
  - **Error**: `controller.value = 1.0`, so motion stops in the settled state (FR-016).
- **Rationale**: 900 ms stays under the spec's 1 s cap (FR-007). Every beat maps to part of the product idea (person → relationship → money → ledger record). The final frame matches the launcher icon (notebook plus coin), so the splash reads as the same brand. Only transforms, opacity and path trims are used; there are no blurs per frame. Shadows are drawn once in the static layer, and the coin's shadow is a cheap offset circle.
- **Alternatives rejected**:
  - *Looping or pulsing motion while waiting*: this reads as a spinner; the spec requires motion not to repeat.
  - *Hero into the first screen*: there's no shared element in the first screen.

## Decision 9 — Colors: extend `tokens.dart` with the icon palette; no new theme system

- **Decision**: Add `AppBrandColors` to `lib/core/design_system/tokens.dart`, holding the launcher-icon palette that is already canonical in `build_icon.py`:
  - `field` = `AppColors.primary`, `fieldDeep` `#0E3D32`
  - `page` `#FFFDF6`, `pageShade` `#F6EDD8`, `pageEdge` `#E3D5B4`
  - `spine` `#0F4538`, `spineLight` `#1A6452`
  - `coinLight` `#FFD66B`, `coin` `#F2B233`, `coinDeep` `#D38E12`, `coinRim` `#FFF1C2`, `coinInk` `#8A5500`
  - `ribbon` `#F0735C`, `ribbonDeep` `#D24E3B`
  - `shadow` `#062A22` and `coinShadow` `#3A2600` (the SVG drop-shadow flood colours; the Dart notebook shadow uses the SVG's `dy 22` / `stdDeviation 26` scaled by the shared transform, so frame 0 matches the native PNG)
  - `onField` = `page`
  - Each value is commented "keep in sync with build_icon.py and native `splash_field`".
- **Rationale**:
  - The logo's colors are brand constants that are the same in both themes, so a `ThemeExtension` would be pointless.
  - Only the field varies with the theme. It's picked by `Theme.of(context).brightness` and crossfaded with `AnimatedContainer`.
  - Everything stays in the one design-system file (Principle XV), and the existing `ColorScheme` and `AppFinanceColors` are untouched.
  - The ledger line uses `field` (the brand primary), as in the icon.
- **Contrast** (verified by a new test): `onField` on `field` ≈ 5.9:1, and on `fieldDeep` ≈ 11.8:1. Both are at least 4.5:1 (FR-021).

## Decision 10 — Typography, text and localization

- **Decision**:
  - The name uses `textTheme.headlineSmall` (= `AppTypography.headline`, 24/700). The tagline uses `textTheme.bodyMedium` (= `AppTypography.bodyMuted`, 14/400). Both are colored `AppBrandColors.onField` and centered.
  - New ARB keys:

| Key | English | Arabic |
|---|---|---|
| `splashTagline` | "Every give and take, in one ledger" | "كل أخذ وعطاء في دفتر واحد" |
| `splashErrorMessage` | "Daftary couldn't finish opening. Please try again." | "تعذّر إكمال فتح دفتري. حاول مرة أخرى." |

  - The name reuses the existing `appTitle` (Daftary / دفتري) and the retry button reuses the existing `commonRetry` ("Try again").
- **Language before settings resolve**: `DaftaryApp` passes `locale: null` until `AppStartupState.appearanceResolved` is true. A `localeResolutionCallback` then picks Arabic when the device's first language is Arabic and English otherwise, which is the same rule as `SettingsCubit`'s first-launch default. The name and tagline only fade in once appearance is resolved, so the language never visibly flips. If the settings step itself fails, the error text still follows the device language (spec Edge Case).
- **Alternative rejected**: *No text at all*: the name is part of the brand, and the tagline is what makes the concept readable (SC-009).

## Decision 11 — Error handling and logging

- **Decision**:
  - Step exceptions and the 10 s `TimeoutException` are caught in `AppStartupCubit` and logged with `dart:developer` `log(name: 'daftary.startup', error:, stackTrace:)`, which is the project's existing convention (see `resolve_onboarding_status.dart`).
  - They're mapped to `StartupFailure.error` or `StartupFailure.timeout`. The user sees one message for both, with no technical detail.
  - A failed step's memoized future is cleared so retry re-runs it. A timed-out step that is still pending is **kept**, so retry awaits it rather than running it twice (FR-015, FR-016).
- **Testability**: the budget is a constructor parameter with `@ignoreParam` (supported by `injectable` 3.0.0; `injectable_annotations.dart:332`), defaulting to 10 s, so cubit tests use a short budget.

## Decision 12 — Test bootstrapping

- **Decision**: The nine `integration_test/*` `bootApp()` helpers currently initialize the two cubits and then pump `DaftaryApp`. They will instead call `await getIt<AppStartupCubit>().start()`, keeping their existing `changeLanguage` and other follow-ups, and then pump.
- **Rationale**: Their existing `pumpAndSettle()` then runs through the ≤ 1.2 s splash and hand-off. The tests exercise the real startup path, and no production test-only switch is added.
