# Implementation Plan: Branded Splash Screen

**Branch**: `019-splash-screen` | **Date**: 2026-09-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/019-splash-screen/spec.md`

## Summary

Today, Daftary awaits its I/O startup (`SettingsCubit.initialize()`, `OnboardingCubit.initialize()`) before `runApp`, behind a blank white native launch screen that has no failure path. This feature:

1. Moves that startup behind a Flutter splash, driven by a new presentation-only `AppStartupCubit` with a 10 s budget and retry.
2. Adds `AppStartupGate` in `MaterialApp.router(builder:)`. It shows the splash and mounts the existing GoRouter only once startup is ready and the intro has finished, so the existing onboarding `redirect` picks the destination exactly once.
3. Draws the launcher-icon mark in Dart with a 900 ms story: person → connection → coin → ledger line written. The motion mirrors in RTL and respects reduced motion.
4. Makes the Android (legacy and API 31+ SplashScreen) and iOS launch screens pixel-match the splash's first frame, in light and dark.

No new dependencies, no router or business-logic changes.

## Technical Context

**Language/Version**: Dart ^3.10, Flutter 3.47.0 (stable)

**Primary Dependencies**: all existing:

- `flutter_bloc`, `equatable`
- `get_it` + `injectable` (DI)
- `go_router` 18
- `flutter_localizations` + gen_l10n (ARB in `lib/core/l10n`)
- dev: `bloc_test`, `mocktail`, `integration_test`
- Asset tooling: `assets/icon/build_icon.py` (Chrome + `sips`), already used for the launcher icon

**Storage**: N/A. Nothing new is persisted; existing Drift/SQLite reads happen through the existing cubits.

**Testing**: `flutter_test` (widget), `bloc_test` + `mocktail` (cubit), `integration_test` (device flows)

**Target Platform**: Android minSdk 24 (Flutter default; edge-to-edge at the current targetSdk), iOS 15.0+

**Project Type**: Mobile app (single Flutter project, feature-first Clean Architecture)

**Performance Goals**:

- First Flutter frame no later than today's (the startup I/O no longer blocks it)
- 60 fps intro with no jank
- Splash adds ≤ 1 s when startup is fast and 0 s when startup is slower than the intro

**Constraints**:

- Intro ≤ 900 ms, exit fade 280 ms, hard budget 10 s
- Zero new packages and zero new Flutter bundle assets
- Native PNGs roughly < 60 KB per density

**Scale/Scope**:

- 1 new feature folder (4 source files)
- 2 modified Dart files (`main.dart`, `tokens.dart`) plus 2 ARB files and a comment-only router touch
- About 10 native launch files
- 9 integration-test helper updates
- 3 new test files

## Constitution Check

*GATE: must pass before Phase 0 research, and is re-checked after Phase 1 design.*

| Principle | Status | How |
|---|---|---|
| I Clean Architecture | ✅ | Presentation only. The splash never touches the DB or repositories; it only calls the existing cubits' `initialize()`. |
| II Feature-first | ✅ | `lib/features/startup/`. Nothing added to `core/` except brand color tokens in the existing `tokens.dart`. |
| III BLoC/Cubit | ✅ | `AppStartupCubit` owns the lifecycle (idle, preparing, ready, failed), dedupes starts, ignores obsolete retries, and is testable without UI. |
| IV Immutable state | ✅ | `AppStartupState` is `Equatable` with `copyWith`, and emits only on real change. |
| V Domain logic / no trivial use cases | ✅ (justified) | No domain rule exists, so no Domain or Data layer is created (Complexity Tracking). |
| VI Repository | ✅ N/A | No data access. |
| VII Error handling | ✅ | Exceptions and timeouts are caught, logged (`dart:developer`), and mapped to the typed `StartupFailure`. The UI shows a localized message only. No empty catch. |
| VIII Financial determinism | ✅ N/A | |
| XI Offline | ✅ | Local-only startup; zero network. |
| XII Security | ✅ | No data in logs beyond the exception type and stack. No new permissions. |
| XIII Localization/RTL | ✅ | ARB keys for all text; reading-direction-aware motion; Arabic shaping via the platform font. |
| XIV DI | ✅ | Cubit registered with `@lazySingleton`; `@ignoreParam` for the test budget. |
| XV Design system | ✅ | Logo palette centralized as `AppBrandColors` in `tokens.dart`; spacing, type and breakpoints from existing tokens. |
| XVI Testability | ✅ | Cubit unit tests (G1–G8), gate and view widget tests, and an integration flow. |
| Standards: build discipline, reduced motion, navigation centralized, complete UI states, duplicate-action protection | ✅ | No work in `build`. `MediaQuery.disableAnimationsOf`. The router is the only destination decider. The error state has retry. Retry is guarded. |

**Post-design re-check (after Phase 1)**: still passes. The `builder:` gate adds no routing logic, and `AppBrandColors` holds constants that previously lived only in `build_icon.py`, so there's no duplicate theme system.

## Project Structure

### Documentation (this feature)

```text
specs/019-splash-screen/
├── spec.md
├── plan.md                 # this file
├── research.md             # Decisions 1–12
├── data-model.md           # AppStartupState, gate latch
├── quickstart.md           # validation guide (M1–M13)
├── contracts/
│   ├── app_startup_cubit.md
│   └── splash_ui.md
├── checklists/requirements.md
└── tasks.md                # /speckit-tasks
```

### Source code

```text
lib/
├── main.dart                                    # MODIFY
├── core/
│   ├── design_system/tokens.dart                # MODIFY: + AppBrandColors
│   ├── l10n/app_en.arb, app_ar.arb              # MODIFY: + splashTagline, splashErrorMessage
│   ├── l10n/app_localizations*.dart             # REGENERATED (flutter gen-l10n)
│   ├── di/injection.config.dart                 # REGENERATED (build_runner)
│   └── routing/app_router.dart                  # COMMENT ONLY (redirect precondition wording)
└── features/startup/presentation/               # NEW
    ├── cubit/app_startup_cubit.dart
    ├── cubit/app_startup_state.dart
    └── widgets/
        ├── app_startup_gate.dart
        ├── splash_view.dart                     # SplashView, SplashWordmark, error block
        └── splash_mark.dart                     # SplashMark, SplashGeometry, 2 painters

assets/icon/build_icon.py                        # MODIFY: + SPLASH render (--splash flag, 1152 px source) and per-density resize

android/app/src/main/kotlin/com/daftary/daftary/MainActivity.kt  # MODIFY: API 31+ instant splash exit (research Decision 13)

android/app/src/main/res/
├── values/colors.xml                            # NEW  splash_field #1F6F5C
├── values-night/colors.xml                      # NEW  splash_field #0E3D32
├── values/styles.xml, values-night/styles.xml   # MODIFY LaunchTheme bars (NormalTheme untouched)
├── values-v31/styles.xml                        # NEW  LaunchTheme + windowSplashScreen*
├── values-night-v31/styles.xml                  # NEW  same, night
├── drawable/launch_background.xml               # MODIFY color + bitmap
├── drawable-v21/launch_background.xml           # MODIFY color + bitmap
└── drawable-{mdpi…xxxhdpi}/splash_mark.png      # NEW (generated)

ios/Runner/
├── Base.lproj/LaunchScreen.storyboard           # MODIFY background → named color
├── Assets.xcassets/LaunchBackground.colorset/   # NEW light/dark color
├── Assets.xcassets/LaunchImage.imageset/*.png   # REPLACE (generated, 288pt)
└── Info.plist                                   # MODIFY + UIStatusBarStyle LightContent

test/
├── features/startup/presentation/cubit/app_startup_cubit_test.dart # NEW  G1–G8
├── widget/app_startup_gate_test.dart            # NEW  hand-off, reduced motion, error, once-only
├── widget/splash_view_test.dart                 # NEW  en/ar, rtl/ltr, light/dark, sizes, text scale, semantics
└── core/design_system/contrast_test.dart        # MODIFY + onField pairs

integration_test/
├── splash_startup_flow_test.dart                # NEW  fresh → onboarding; returning → People; resume/theme/lang no replay
└── *_test.dart (9 files)                        # MODIFY bootApp(): startup.start() replaces the two initialize() calls
```

**Structure decision**: The feature lives in `lib/features/startup/presentation`, following the feature-first rule. Only brand color constants join the existing design-system file.

## Design detail by area

### Architecture and startup flow

```text
main(): ensureInitialized → await configureDependencies()   (registration only)
        → unawaited(startup.start())                        (settings → onboarding, 10 s budget)
        → startup.whenReady.then(trigger.start + tapRouter.start(appRouter))
        → runApp(DaftaryApp)
DaftaryApp: MultiBlocProvider(+AppStartupCubit) → BlocBuilder<Settings> → BlocBuilder<AppStartup>(buildWhen: appearanceResolved changed)
        → MaterialApp.router(locale: resolved ? Locale(lang) : null, localeResolutionCallback, builder: AppStartupGate)
AppStartupGate: splash only → [ready ∧ introDone] → mount Router under fading splash → Router only
```

- **Destination**: GoRouter's existing redirect (onboarding vs. `/`), plus any `go()` the tap router issued earlier. Nothing new decides routes.
- **Exactly once**: the `_handedOff` latch plus a single Router mount.
- **Errors**: `failed` keeps the gate on the splash in error mode, and `retry()` resumes.
- **Resume, rotation, language or theme**: the gate state persists and the latch is already set, so there's no replay. A process restart gets a new gate.

### UI and UX

Layout, typography and spacing are defined in [contracts/splash_ui.md](contracts/splash_ui.md):

- Mark: fixed 288 logical px, full-screen centered.
- Text block: at `center + contentBottom + AppSpacing.xl`, within the safe area, `FittedBox.scaleDown` for tiny or landscape screens.
- Error layout: a scrollable centered column, capped at `AppBreakpoints.maxReadingWidth`.

### Animation

This is Decision 8 in [research.md](research.md): one 900 ms controller, `Interval` beats, a 280 ms exit fade, reduced motion jumps to the end, and failure jumps to the end. The static notebook sits in a `RepaintBoundary`; only the motion painter repaints.

### Theme

- `AppBrandColors` (logo palette, same in both themes).
- The field color comes from `Theme.of(context).brightness` and is crossfaded by `AnimatedContainer`.
- Text styles come from `Theme.of(context).textTheme` (already merged with `AppTypography`).
- `ColorScheme` and `AppFinanceColors` are unchanged.

### Localization

- Two new ARB keys; `appTitle` and `commonRetry` are reused.
- `locale: null` plus a device-rule callback until settings resolve.
- The text is hidden until resolved, so it never flips.
- Motion direction comes from `Directionality`.

### Platform

The native launch screen equals Flutter frame 0 (Decision 7):

- Android 7–11 uses `launch_background` (color + bitmap).
- Android 12+ uses `windowSplashScreenBackground` + `windowSplashScreenAnimatedIcon`, with separate night-v31 styles.
- iOS uses the storyboard named color + LaunchImage at 288 pt.
- `NormalTheme` is untouched, so the window background behind the running app stays as today.
- Edge-to-edge: the field draws behind the bars, `AnnotatedRegion` sets light icons, and text uses `SafeArea`.

### Performance

- Startup I/O is no longer on the critical path to the first frame.
- The splash builds a handful of widgets with no image decode, no fonts beyond the system ones, and no new assets in the Flutter bundle.
- The gate rebuilds only on `AppStartupState` changes (`buildWhen`). The painters repaint only via their `Listenable`.
- Post-ready services start after readiness, as today.
- Profile check in quickstart M13.

### Testing

| Layer | File | Covers |
|---|---|---|
| Cubit | `test/features/startup/presentation/cubit/app_startup_cubit_test.dart` | G1–G8 (order, idempotency, error, timeout, targeted retry, joined in-flight step, guarded retry, `whenReady`) using mocked `SettingsCubit`/`OnboardingCubit` and a 50 ms budget |
| Widget | `test/widget/app_startup_gate_test.dart` | child not mounted before ready; not mounted before intro end even if ready; mounted exactly once (build counter) whichever finishes last; reduced motion → hand-off on first frame after ready; failure → error block, Try again calls `retry()`, button disabled while retrying; no replay on lifecycle `paused`→`resumed` and on theme/locale rebuild |
| Widget | `test/widget/splash_view_test.dart` | en/ar text; `TextDirection.rtl`/`ltr` renders without exceptions; field color per brightness; 320×480, landscape 740×360, 1024×1366 and `textScaler` 2.0 with no overflow; semantics: one header "Daftary", mark excluded, error live region |
| Unit | `test/core/design_system/contrast_test.dart` | `onField` on `field`/`fieldDeep` ≥ 4.5 |
| Integration | `integration_test/splash_startup_flow_test.dart` | fresh install → Onboarding; returning → People; background/resume and theme/language switches never show `SplashView` again |
| Regression | all existing `test/` and `integration_test/` | pass with `bootApp()` using `start()` |

## Files: create and modify (with boundaries)

### Create

| File | Layer | Responsibility |
|---|---|---|
| `lib/features/startup/presentation/cubit/app_startup_state.dart` | Presentation | Immutable startup state and enums ([data-model.md](data-model.md)) |
| `lib/features/startup/presentation/cubit/app_startup_cubit.dart` | Presentation | Ordered, memoized, time-boxed startup; retry; `whenReady` |
| `lib/features/startup/presentation/widgets/app_startup_gate.dart` | Presentation | Controllers, hand-off latch, exit fade, mounting the Router |
| `lib/features/startup/presentation/widgets/splash_view.dart` | Presentation | Field, wordmark, error block, system-bar style, safe-area layout |
| `lib/features/startup/presentation/widgets/splash_mark.dart` | Presentation | Geometry constants and the two painters (static notebook, motion) |
| Android `values*/colors.xml`, `values-v31`/`values-night-v31/styles.xml`, `splash_mark.png` ×5 | Platform | Native launch continuity |
| iOS `LaunchBackground.colorset` | Platform | Light/dark launch field |
| 3 test files + 1 integration test | Test | See Testing |

### Modify

| File | Change | Must remain untouched |
|---|---|---|
| `lib/main.dart` | Remove the two awaited `initialize()` calls; start `AppStartupCubit`; chain post-ready services on `whenReady`; provide the cubit; `builder:`, `locale`, `localeResolutionCallback` | Theme and themeMode mapping, delegates, `scaffoldMessengerKey`, `routerConfig` |
| `lib/core/design_system/tokens.dart` | Add `AppBrandColors` | Everything else (themes, `AppColors`, `AppFinanceColors`, typography) |
| `lib/core/l10n/app_en.arb`, `app_ar.arb` | Add 2 keys | Existing keys |
| `lib/core/routing/app_router.dart` | Update the redirect comment ("awaited in main.dart" → "settled before AppStartupGate mounts the Router") | All routes and redirect logic |
| `assets/icon/build_icon.py` | Add the `SPLASH` markup (notebook, faint lines, no coin, scale 0.9, recentered, 288-unit canvas mapping) and resizing into Android and iOS folders | Existing icon renders |
| Android `drawable*/launch_background.xml`, `values*/styles.xml` | Field + mark; bar colors in LaunchTheme | `NormalTheme`, manifest |
| iOS `LaunchScreen.storyboard`, `LaunchImage` PNGs, `Info.plist` | Named background color; new image; `UIStatusBarStyle` | Other plist keys, constraints |
| `test/core/design_system/contrast_test.dart` | Add pairs | Existing pairs |
| 9 × `integration_test/*_test.dart` | `bootApp()` startup call | Test bodies |

### Dependencies

- **Reused**: `flutter_bloc`, `equatable`, `get_it`/`injectable` (`@ignoreParam`), `go_router`, gen_l10n, `bloc_test`, `mocktail`, `integration_test`.
- **New**: **none**. Lottie, Rive and `flutter_native_splash` were considered and rejected (research Decisions 6–7).

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Splash stuck | 10 s budget → error and retry; `ready` is terminal; hand-off depends only on `ready ∧ introDone`, and `introDone` is forced true under reduced motion and on failure |
| Navigation race / double navigation | Router mounted once behind a latch; no `go()` from the splash; tap-router `go()` before mount is absorbed by the route information provider |
| Duplicate initialization | Memoized steps; idempotent `start()`; retry joins in-flight steps; post-ready services are already idempotent |
| Settings unresolved on the first frames (wrong language or theme) | `locale: null` with the device rule; text hidden until resolved; theme defaults to system, which equals the native screen, then crossfades |
| Onboarding redirect running on unsettled state | Router not mounted before `ready`; redirect code unchanged |
| Background → foreground, rotation, language or theme change replaying the splash | The gate lives above the Router and is unkeyed; latch persists; no lifecycle observer in the gate |
| App restart (process death) | A new process gets a new gate, so the splash is shown once (spec US4 AS3) |
| Authentication state changes | No sign-in exists; the onboarding gate is the only session state, handled by the unchanged redirect. A future app lock (015) plugs in after the gate. |
| Android 12+ ignoring `launch_background` | Separate v31 and night-v31 styles with the SplashScreen attributes |
| Launch screen vs. in-app theme mismatch | 200 ms field crossfade (spec Edge Case) |
| iOS launch screen caching hides changes | Documented in quickstart |
| Painter mark drifting from native PNG | Single geometry source mirrored in `build_icon.py`; frame-0 invariant; manual M1/M10 screen-recording check |
| Arabic "د" glyph differs slightly between platform fonts | Accepted: the coin isn't on frame 0 (it arrives with motion), so no continuity break |
| Asset loading failure | No Flutter assets are loaded by the splash; native images are compiled resources |
| Large text or tiny screens | `FittedBox.scaleDown` for the wordmark; the error layout scrolls; widget tests at 320×480, landscape and 2.0 text scale |
| Existing integration tests breaking | `bootApp()` switched to `start()`; `pumpAndSettle` runs through the ≤ 1.2 s splash |

## Complexity Tracking

| Deviation | Why needed | Simpler alternative rejected because |
|---|---|---|
| The `startup` feature has no Domain or Data layer | It only orchestrates two existing presentation-level initializers; there is no business rule or data | Empty layers or a wrapper use case would violate Principle V (no trivial use cases), and Domain can't depend on presentation cubits |
| `AppStartupCubit` depends on two other cubits | Their `initialize()` methods are the existing, tested startup contracts; re-implementing them via their use cases would duplicate logic | Duplicating the settings and onboarding resolution logic would risk drift |
