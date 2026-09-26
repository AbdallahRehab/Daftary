---

description: "Task list for 019 Branded Splash Screen"
---

# Tasks: Branded Splash Screen

**Input**: Design documents from `specs/019-splash-screen/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/app_startup_cubit.md](contracts/app_startup_cubit.md), [contracts/splash_ui.md](contracts/splash_ui.md), [quickstart.md](quickstart.md)

**Tests**: Included. The spec (SC-005–SC-008) and the request both require them. Test tasks come before the implementation they cover and should fail first.

**Organization**: Phases follow the spec's user stories (US1–US4) after Setup and Foundational. The "Requested-phase map" at the end shows where each of the eight requested areas (architecture, foundation, visual, animation, l10n/a11y, platform, testing, validation) lives.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel. It touches a different file from every other open task and depends on no incomplete task.
- **[Story]**: US1–US4 from spec.md.
- Paths are repository-relative.

## Scope protection (applies to every task)

- Touch **only** the files listed in plan.md → "Files: create and modify". Any other file change is a defect.
- Do **not** change: routes or redirect logic in `lib/core/routing/app_router.dart` (comment only, T017); `SettingsCubit`, `OnboardingCubit`, their use cases and repositories; `NotificationTapRouter`, `NotificationRecomputeTrigger`; `NormalTheme`; `AndroidManifest.xml`; any screen other than the splash; `pubspec.yaml` dependencies.
- If you find a problem unrelated to the splash, **do not fix it**. Append it to `specs/019-splash-screen/notes-out-of-scope.md` (created in T001) with the file, the symptom, and why it's out of scope.

---

## Phase 1: Setup (architecture preparation, read-only)

**Purpose**: Confirm the plan's assumptions against the real code before changing anything. These tasks produce notes only.

- [X] T001 Create `specs/019-splash-screen/notes-out-of-scope.md` with a heading and an empty list, used by the scope-protection rule above.
- [X] T002 [P] Re-verify the startup flow in `lib/main.dart`: `configureDependencies()` → `SettingsCubit.initialize()` → `OnboardingCubit.initialize()` → `NotificationRecomputeTrigger.start()` → `NotificationTapRouter.start(appRouter)` → `runApp`. Also confirm that `lib/core/di/injection.config.dart` has no `@preResolve` or awaited registrations (research Decision 1). Record any difference in `specs/019-splash-screen/notes-out-of-scope.md` and stop if Decision 1 no longer holds.
- [X] T003 [P] Re-verify that `lib/core/routing/app_router.dart` `redirect` reads `getIt<OnboardingCubit>().state` synchronously and that no `refreshListenable` exists. Also check that `lib/core/routing/notification_tap_router.dart` only calls `router.go(...)` or shows a snackbar through `appScaffoldMessengerKey` (research Decisions 2 and 4).
- [X] T004 [P] Re-verify the design tokens in `lib/core/design_system/tokens.dart`: `AppColors.primary == 0xFF1F6F5C`; `AppSpacing`, `AppBreakpoints.maxReadingWidth` and `AppTypography` exist, and `_textThemeFor` maps `headlineSmall`/`bodyMedium`/`bodyLarge`. Also re-check the icon palette hex values in `assets/icon/build_icon.py` `DEFS` against research Decision 9.
- [X] T005 [P] Re-verify localization: `l10n.yaml` (arb-dir `lib/core/l10n`, template `app_en.arb`), and that the existing keys `appTitle` and `commonRetry` are present in both `lib/core/l10n/app_en.arb` and `lib/core/l10n/app_ar.arb`.
- [X] T006 [P] Confirm no new dependency is needed: `pubspec.yaml` already has `flutter_bloc`, `equatable`, `get_it`, `injectable`, `go_router`, `bloc_test`, `mocktail`, `integration_test`, and `injectable` exports `ignoreParam` (`~/.pub-cache/hosted/pub.dev/injectable-3.0.0/lib/src/injectable_annotations.dart`). No `pubspec.yaml` edit is permitted.

**Acceptance (Phase 1)**: Every plan assumption is confirmed, or a difference is recorded and resolved before Phase 2.

---

## Phase 2: Foundational (startup state, gate, wiring)

**Purpose**: Startup runs behind a gate that mounts the router exactly once. This blocks every user story. At the end of this phase the app launches through a plain field-colored splash and reaches the correct screen.

**⚠️ CRITICAL**: No user-story work may start before the Phase 2 checkpoint.

### Tokens and strings

- [X] T007 [P] Add `class AppBrandColors` (private const constructor) to `lib/core/design_system/tokens.dart`, placed after `AppColors`. Constants:
  - `field = AppColors.primary`, `fieldDeep = Color(0xFF0E3D32)`
  - `page = Color(0xFFFFFDF6)`, `pageShade = Color(0xFFF6EDD8)`, `pageEdge = Color(0xFFE3D5B4)`
  - `spine = Color(0xFF0F4538)`, `spineLight = Color(0xFF1A6452)`
  - `coinLight = Color(0xFFFFD66B)`, `coin = Color(0xFFF2B233)`, `coinDeep = Color(0xFFD38E12)`, `coinRim = Color(0xFFFFF1C2)`, `coinInk = Color(0xFF8A5500)`
  - `ribbon = Color(0xFFF0735C)`, `ribbonDeep = Color(0xFFD24E3B)`
  - `shadow = Color(0xFF062A22)` (the notebook drop shadow, `#shadow` flood colour), `coinShadow = Color(0xFF3A2600)` (`#coinShadow` flood colour)
  - `onField = page`

  Add a doc comment saying these are the launcher-icon/splash palette, the same in both themes, and must stay in sync with `assets/icon/build_icon.py` and the native `splash_field` colors. Change nothing else in the file.
- [X] T008 [P] Add to `lib/core/l10n/app_en.arb`: `"splashTagline": "Every give and take, in one ledger"` and `"splashErrorMessage": "Daftary couldn't finish opening. Please try again."`, each with an `@key` `description`.
- [X] T009 [P] Add to `lib/core/l10n/app_ar.arb`: `"splashTagline": "كل أخذ وعطاء في دفتر واحد"` and `"splashErrorMessage": "تعذّر إكمال فتح دفتري. حاول مرة أخرى."`.
- [X] T010 Run `flutter gen-l10n` and confirm `lib/core/l10n/app_localizations.dart`, `app_localizations_en.dart` and `app_localizations_ar.dart` expose `splashTagline` and `splashErrorMessage`. Depends on T008 and T009.

### Startup state and cubit (tests first)

- [X] T011 [P] Create `lib/features/startup/presentation/cubit/app_startup_state.dart`:
  - `enum AppStartupStatus { idle, preparing, ready, failed }` and `enum StartupFailure { error, timeout }`.
  - An immutable `AppStartupState extends Equatable` with fields `status` (default `idle`), `appearanceResolved` (default `false`), `failure` (`StartupFailure?`, default `null`, "set only while status == failed") and `isRetry` (default `false`).
  - `copyWith`, where `failure` is cleared explicitly by a `clearFailure` flag.
  - Getters `isReady` and `isFailed`; `props`.
  - Follow [data-model.md](data-model.md) exactly.
- [X] T012 [P] Write `test/features/startup/presentation/cubit/app_startup_cubit_test.dart` (the repo's cubit-test convention, as in `test/features/onboarding/presentation/cubit/onboarding_cubit_test.dart`) (bloc_test + mocktail; mock `SettingsCubit` and `OnboardingCubit` with `class _MockX extends Mock implements X`; budget `Duration(milliseconds: 50)`). It covers guarantees G1–G8 from [contracts/app_startup_cubit.md](contracts/app_startup_cubit.md):
  - G1: emission order on success.
  - G2: `start()` twice (concurrently and sequentially) calls each `initialize()` once.
  - G3: settings throws → `failed(error)`, no exception escapes; onboarding throws → `failed(error)` with `appearanceResolved == true`.
  - G4: onboarding never completes → `failed(timeout)`.
  - G5: after G3 (onboarding threw once and then succeeds), `retry()` calls settings 0 more times and onboarding 1 more time → `ready`.
  - G6: after G4 with a `Completer`-backed onboarding, `retry()` then completing the completer → `ready`, with onboarding `initialize()` invoked exactly once in total.
  - G7: `retry()` in idle, preparing and ready emits nothing.
  - G8: `whenReady` completes after `ready`, and completes immediately when already ready. It also completes without error (never throws `StateError`) if the cubit is closed before reaching `ready`.

  Tests must fail (the cubit doesn't exist yet).
- [X] T013 Create `lib/features/startup/presentation/cubit/app_startup_cubit.dart` as `@lazySingleton class AppStartupCubit extends Cubit<AppStartupState>`, with constructor `(SettingsCubit, OnboardingCubit, {@ignoreParam Duration timeout = const Duration(seconds: 10)})`. Implementation:
  - `start()`: if `status != idle`, return the stored `_run` future; otherwise store it.
  - `_attempt()`: emit `preparing`, then run the steps inside `.timeout(timeout)`.
  - Memoized step futures `_settingsStep ??= _settings.initialize()` and `_onboardingStep ??= _onboarding.initialize()`. A step that errors resets its field to `null` (via `catchError` that rethrows); a pending step is kept.
  - Emit `appearanceResolved: true` after settings and `status: ready` after onboarding.
  - On `TimeoutException` → `failed(timeout)`; on any other error → `failed(error)`. Both are logged with `developer.log('startup failed', name: 'daftary.startup', error: e, stackTrace: s)` from `dart:developer`. No empty catch.
  - `retry()` acts only when `isFailed`: it emits `preparing(isRetry: true, clearFailure)` and runs `_attempt()` again.
  - `whenReady` returns `state.isReady ? Future.value() : stream.firstWhere((s) => s.isReady, orElse: () => state).then((_) {})`. The `orElse` means closing the cubit before `ready` completes the future instead of throwing `StateError` (contract G8: never completes with an error). Callers in `main.dart` still only start services when `state.isReady`, so they check the flag inside the `then`.
  - Add doc comments citing FR-011/012/015/016.

  T012 must pass. Depends on T011 and T012.
- [X] T014 Run `dart run build_runner build --delete-conflicting-outputs` and confirm `lib/core/di/injection.config.dart` registers `AppStartupCubit` as a lazy singleton, with `timeout` not resolved from DI. Depends on T013.

### Gate skeleton and app wiring

- [X] T015 Create `lib/features/startup/presentation/widgets/splash_view.dart` with a **minimal** `SplashView` for now: a `StatelessWidget` taking `{required Animation<double> intro}` that renders `ColoredBox` with `Theme.of(context).brightness == Brightness.dark ? AppBrandColors.fieldDeep : AppBrandColors.field` filling the screen. US1 and US3 fill it in. Depends on T007.
- [X] T016 Create `lib/features/startup/presentation/widgets/app_startup_gate.dart` per [contracts/splash_ui.md](contracts/splash_ui.md): `AppStartupGate({required Widget child})`, a `StatefulWidget` with `TickerProviderStateMixin`.
  - Controllers: `_intro` (900 ms) and `_exit` (280 ms).
  - Fields `_introDone`, `_handedOff` and `_splashRemoved`.
  - `initState` forwards `_intro`. On completion, `_introDone = true` and it calls `_maybeHandOff()`.
  - `BlocListener<AppStartupCubit, AppStartupState>` (`listenWhen: status changed`) → `_maybeHandOff()`.
  - `_maybeHandOff()`: only if `!_handedOff && _introDone && state.isReady`, set `_handedOff = true`, then `setState` and `_exit.forward()`. When `_exit` completes, set `_splashRemoved = true` and `setState`.
  - `build`:
    - `!_handedOff` → `SplashView(intro: _intro)` only (child **not** built).
    - `_handedOff && !_splashRemoved` → `Stack(fit: expand, [child, IgnorePointer(child: FadeTransition(opacity: ReverseAnimation(_exit), child: SplashView(...)))])`.
    - Otherwise → `child`.
  - Dispose both controllers. No `context.go`/`push`, no lifecycle observer, no keys.

  Depends on T013 and T015.
- [X] T017 Edit only the comments in `lib/core/routing/app_router.dart` that say `OnboardingCubit.initialize()` "is awaited in main.dart before runApp". Reword them to "is settled before `AppStartupGate` (019) mounts the Router". Routes and redirect code stay unchanged.
- [X] T018 Modify `lib/main.dart`:
  - Keep `WidgetsFlutterBinding.ensureInitialized()` and `await configureDependencies()`.
  - Remove the awaited `getIt<SettingsCubit>().initialize()` and `getIt<OnboardingCubit>().initialize()`. Replace them with `final startup = getIt<AppStartupCubit>(); unawaited(startup.start());`.
  - Replace the direct `NotificationRecomputeTrigger.start()` and `NotificationTapRouter.start(appRouter)` calls with `unawaited(startup.whenReady.then((_) { if (!startup.state.isReady) return; getIt<NotificationRecomputeTrigger>().start(); unawaited(getIt<NotificationTapRouter>().start(appRouter)); }));`. The `isReady` check covers `whenReady` completing because the cubit closed (T013).
  - Add `BlocProvider<AppStartupCubit>.value(value: getIt<AppStartupCubit>())` to the `MultiBlocProvider`.
  - Wrap `MaterialApp.router` in `BlocBuilder<AppStartupCubit, AppStartupState>(buildWhen: (a, b) => a.appearanceResolved != b.appearanceResolved)`.
  - Set `locale: startup.appearanceResolved ? Locale(state.language.code) : null` and `localeResolutionCallback: (locales, supported) => (locales?.firstOrNull?.languageCode == 'ar') ? const Locale('ar') : const Locale('en')`. The callback is a private top-level function with a doc comment citing research Decision 10.
  - Set `builder: (context, child) => AppStartupGate(child: child!)`.
  - Update the comments that referenced T025 and FR-001 ordering.
  - Theme, themeMode mapping, delegates, `routerConfig` and `scaffoldMessengerKey` stay unchanged.

  Depends on T014 and T016.
- [X] T019 [P] In `integration_test/onboarding_flow_test.dart` `bootApp()`, replace `await getIt<SettingsCubit>().initialize();` with `await getIt<AppStartupCubit>().start();`, placed before the existing `changeLanguage`, and delete the separate `await getIt<OnboardingCubit>().initialize();`. Keep `freshInstall` clearing **before** `start()`. Test bodies stay unchanged. Depends on T018.
- [X] T020 [P] Same `bootApp()` change in `integration_test/language_switch_flow_test.dart`. Depends on T018.
- [X] T021 [P] Same `bootApp()` change in `integration_test/theme_switch_flow_test.dart`. Depends on T018.
- [X] T022 [P] Same `bootApp()` change in `integration_test/money_relationships_flows_test.dart`. Depends on T018.
- [X] T023 [P] Same `bootApp()` change in `integration_test/archive_state_refresh_flow_test.dart`. Depends on T018.
- [X] T024 [P] Same `bootApp()` change in `integration_test/finance_flows_test.dart`. Depends on T018.
- [X] T025 [P] Same `bootApp()` change in `integration_test/currency_flows_test.dart`. Depends on T018.
- [X] T026 [P] Same `bootApp()` change in `integration_test/financial_education_flows_test.dart`. Depends on T018.
- [X] T027 [P] Same `bootApp()` change in `integration_test/insights_notifications_flows_test.dart`. If this file starts the recompute trigger or tap router itself, keep that call. Depends on T018.
- [X] T028 Run `flutter analyze` and `flutter test`; both must be green, with T012 passing. Depends on T010–T027.

**Checkpoint / Acceptance (Phase 2)**:

- The app cold-starts to a flat brand-colored screen and then reaches Onboarding or People, as before.
- Startup I/O no longer blocks `runApp`, and the Router mounts once.
- `flutter analyze` is clean and all unit and widget tests pass.

---

## Phase 3: User Story 1 — A branded, seamless launch (P1) 🎯 MVP

**Goal**: The settled Daftary mark and the localized name on the brand field, in Light and Dark, matching the native launch screen with no flash or jump (FR-001–FR-006, FR-018–FR-021).

**Independent test**: Cold-launch in Light and Dark, English and Arabic, on Android API 29 and API 34 and on iOS. Record the screen: no white flash, no mark jump, correct name (quickstart M1–M4, M10, M11).

### Tests for US1

- [X] T029 [P] [US1] Write `test/widget/splash_view_test.dart`. It pumps `SplashView` inside `MaterialApp` with `buildLightTheme()`/`buildDarkTheme()`, `AppLocalizations` delegates, locale `en`/`ar`, and `AlwaysStoppedAnimation(1.0)`. Assertions:
  1. The field color is `AppBrandColors.field` in light and `AppBrandColors.fieldDeep` in dark (find the `AnimatedContainer` and read its decoration color).
  2. The text `Daftary` + `splashTagline` in `en` and `دفتري` + the Arabic tagline in `ar`.
  3. Both `TextDirection.ltr` and `rtl` render with `tester.takeException()` null.
  4. `tester.view` sizes 320×480, 740×360 (landscape) and 1024×1366, and `MediaQuery textScaler: TextScaler.linear(2.0)`, with no overflow exception.
  5. Semantics: exactly one header node labeled with `appTitle`, and no semantics node from the mark.

  Must fail before T034.
- [X] T030 [P] [US1] Extend `test/core/design_system/contrast_test.dart` with a group `splash`: `AppBrandColors.onField` on `field` and on `fieldDeep` are each `>= 4.5`. Existing pairs stay untouched.

### Implementation for US1: mark and layout

- [X] T031 [US1] Create `lib/features/startup/presentation/widgets/splash_mark.dart` with `abstract final class SplashGeometry`:
  - `extent = 288.0` (logical px canvas, equal to the native 288 dp/pt) and `markScale = 0.9`.
  - One pinned transform, identical to `SPLASH_TRANSFORM` in `assets/icon/build_icon.py` (T037): raw `MARK` coordinates → `translate(512,512) scale(0.9) translate(-517,-515)` in the 1024-unit space, then `× extent / 1024` into canvas px. (517,515) is the centre of the notebook bounding box, x 300–734 and y 240–790, including the page-edge offset. Do **not** apply `MARK_CENTRED`'s translate(-24,-20). Expose it as `static Offset toCanvas(Offset raw)` and `static const double unit = markScale * extent / 1024` (≈ 0.253125 canvas px per raw unit). Check: the notebook's farthest corner is 315 scaled units from the centre, below the 341 that fits Android 12's 192 dp icon circle.
  - Constants copied from `assets/icon/build_icon.py` `MARK`: the page-edge rect (318,262,416,528, r44), page rect (300,240,416,528, r44), spine path, 4 binding holes (x346, y318/426/534/642, r9), ledger lines (y350: 448→640; y440: 448→656; y530: 448→600; stroke 26, round), ribbon path, coin centre (676,676), radius 124 and rim radius 98.
  - `contentBottom`: the lowest painted y relative to the canvas centre once the coin has landed, computed from the constants.
  - `personOrigin(TextDirection)`: `Offset(∓135, 20)` from centre (negative x for ltr).
  - `connectionControl(TextDirection)`: the mirrored control point `Offset(∓60, -110)`.
  - Named motion constants (logical px unless noted): `personHeadRadius = 7`, `personShoulders = Size(22, 11)`, `personHeadGap = 3`, `connectionStroke = 2`, `connectionAlpha = 0.45`, `coinShadowOffset = Offset(0, 3)`, `coinShadowAlpha = 0.25`, `coinStartScale = 0.7`, `coinSettleOvershoot = 0.06`, `coinGlyphScale = 1.42` (multiplied by the coin radius), `coinRimAlpha = 0.7`, `wordmarkRise = 8`, `holesAlpha = 0.55`, `faintLineAlpha = 0.28`.
  - Shadow constants derived from the SVG `DEFS` (`#shadow`: `dy 22`, `stdDeviation 26`, flood `#062A22` @0.45), in raw units multiplied by `unit`: `notebookShadowOffset = Offset(0, 22 * unit)`, `notebookShadowSigma = 26 * unit`, `notebookShadowAlpha = 0.45`.
  - A comment says every value mirrors `SPLASH` in `build_icon.py` (T037).
- [X] T032 [US1] In `lib/features/startup/presentation/widgets/splash_mark.dart`, add `class SplashNotebookPainter extends CustomPainter`. It paints, in this order, using only `AppBrandColors`:
  - one drop shadow under the page stack, matching the SVG `#shadow` filter: the page-stack shape offset by `SplashGeometry.notebookShadowOffset`, filled with `AppBrandColors.shadow` at `notebookShadowAlpha`, and `MaskFilter.blur(BlurStyle.normal, SplashGeometry.notebookShadowSigma)`. A Gaussian σ equals SVG `stdDeviation`, so no conversion is needed.
  - the page edge (`pageEdge`)
  - the page (vertical linear gradient `page` → `pageShade`)
  - the spine (horizontal gradient `spine` → `spineLight`)
  - binding holes (`page` at `holesAlpha`)
  - all three ledger lines in `field` at `faintLineAlpha` (the faint frame-0 state)
  - the ribbon (vertical gradient `ribbon` → `ribbonDeep`)

  `shouldRepaint` returns `false`. Depends on T031.
- [X] T033 [US1] In `lib/features/startup/presentation/widgets/splash_mark.dart`, add `class SplashMark extends StatelessWidget` (`{required Animation<double> intro}`): `ExcludeSemantics(SizedBox.square(dimension: SplashGeometry.extent, child: RepaintBoundary(child: CustomPaint(painter: const SplashNotebookPainter()))))`. Leave a clearly marked slot in a `Stack` for the motion painter added in T049. Depends on T032.
- [X] T034 [US1] Replace the minimal `SplashView` in `lib/features/startup/presentation/widgets/splash_view.dart` with the brand layout from [contracts/splash_ui.md](contracts/splash_ui.md):
  - Outer structure: `AnnotatedRegion<SystemUiOverlayStyle>` (`statusBarColor`/`systemNavigationBarColor` transparent, `statusBarIconBrightness`/`systemNavigationBarIconBrightness: Brightness.light`, `statusBarBrightness: Brightness.dark`) → `Material(type: MaterialType.transparency)` → `AnimatedContainer`.
  - `AnimatedContainer`: color `field`/`fieldDeep` by brightness; duration `Duration(milliseconds: 200)`, or `Duration.zero` when `MediaQuery.disableAnimationsOf(context)`.
  - Inside it, a `LayoutBuilder` → `Stack`:
    - `Center(child: SplashMark(intro: intro))`, centered on the **full** screen, not a SafeArea.
    - `Positioned(top: h / 2 + SplashGeometry.contentBottom + AppSpacing.xl, left: 0, right: 0, bottom: 0)` → `SafeArea(top: false)` → `Padding(horizontal: AppSpacing.lg)` → `Align(topCenter)` → `FittedBox(fit: BoxFit.scaleDown)` → `SplashWordmark`.
  - Add a `bool appearanceResolved` parameter (default `true`).

  Depends on T033 and T010.
- [X] T035 [US1] In `lib/features/startup/presentation/widgets/splash_view.dart`, add a private `_SplashWordmark` with a `Column(mainAxisSize: min)`:
  - `Semantics(header: true, child: Text(l10n.appTitle, style: textTheme.headlineSmall!.copyWith(color: AppBrandColors.onField), textAlign: center))`
  - `SizedBox(height: AppSpacing.xs)`
  - `Text(l10n.splashTagline, style: textTheme.bodyMedium!.copyWith(color: AppBrandColors.onField), textAlign: center)`

  Opacity is `0` when `!appearanceResolved` (the animated reveal is added in T050). There are no hardcoded strings, colors or sizes. Depends on T034.
- [X] T036 [US1] Pass `appearanceResolved: state.appearanceResolved` from `AppStartupGate`'s `BlocBuilder` into `SplashView` in `lib/features/startup/presentation/widgets/app_startup_gate.dart`. Depends on T035.

### Implementation for US1: shared asset generation

- [X] T037 [US1] Extend `assets/icon/build_icon.py`:
  - Add `SPLASH_MARK`: `MARK` without the `<!-- coin -->` group, with all three ledger lines at `stroke-opacity="0.28"` to match T032. Wrap it in `SPLASH_TRANSFORM = 'translate(512 512) scale(0.9) translate(-517 -515)'`, exactly the transform pinned in T031. Do not use `MARK_CENTRED`.
  - Give `render()` an optional `size=1024` parameter that sets `--window-size={size},{size}` and the root `<svg width/height>` (the viewBox stays `0 0 1024 1024`). Existing icon calls keep the default.
  - Render the splash **at 1152 px** (`render("splash", svg_splash, size=1152)`, the xxxhdpi size) so every density is a downscale, never an upscale. The canvas represents 288 dp/pt.
  - Add argument handling: `python3 assets/icon/build_icon.py` renders everything as today; `python3 assets/icon/build_icon.py --splash` renders **only** the splash and runs the resize step, so launcher sources are never re-rendered by this feature.
  - Add a `resize_splash()` step using macOS `sips -z <px> <px>` from the 1152 source that writes:
    - Android `android/app/src/main/res/drawable-mdpi/splash_mark.png` (288), `-hdpi` (432), `-xhdpi` (576), `-xxhdpi` (864), `-xxxhdpi` (1152)
    - iOS `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` (288), `@2x` (576), `@3x` (864)
  - Update the module docstring (outputs and the `--splash` flag). The existing icon markup and renders must stay unchanged. Depends on T031, whose geometry must match.
- [X] T038 [US1] Run `python3 assets/icon/build_icon.py --splash` (never without the flag in this feature), then verify the 8 PNGs exist at the expected pixel sizes (`sips -g pixelWidth`), each Android PNG is under 60 KB (use `pngcrush`/`sips` recompression only if that is exceeded), and `assets/icon/splash.png` renders the coin-less notebook. Launcher icon PNGs must be byte-identical afterwards (`git status --porcelain assets/icon/icon.png assets/icon/background.png assets/icon/foreground.png assets/icon/monochrome.png android/app/src/main/res/mipmap-* android/app/src/main/res/drawable-*/ic_launcher_* ios/Runner/Assets.xcassets/AppIcon.appiconset` prints nothing). Depends on T037.

### Implementation for US1: native launch continuity (Android)

- [X] T039 [P] [US1] Create `android/app/src/main/res/values/colors.xml` with `<color name="splash_field">#1F6F5C</color>` and `android/app/src/main/res/values-night/colors.xml` with `<color name="splash_field">#0E3D32</color>`. Each has a comment: "019: equals AppBrandColors.field / fieldDeep".
- [X] T040 [P] [US1] Rewrite `android/app/src/main/res/drawable-v21/launch_background.xml` and `android/app/src/main/res/drawable/launch_background.xml` as a `layer-list`: `<item android:drawable="@color/splash_field"/>` plus `<item><bitmap android:gravity="center" android:src="@drawable/splash_mark"/></item>`. Remove the white layer. Depends on T039 and T038.
- [X] T041 [P] [US1] In `android/app/src/main/res/values/styles.xml` and `values-night/styles.xml`, add to **LaunchTheme only**:
  - `<item name="android:statusBarColor">@android:color/transparent</item>`
  - `<item name="android:navigationBarColor">@android:color/transparent</item>`
  - `<item name="android:windowLightStatusBar">false</item>`
  - `<item name="android:windowDrawsSystemBarBackgrounds">true</item>`. The pre-Holo parents (`Theme.Light.NoTitleBar` / `Theme.Black.NoTitleBar`) don't set it, and without it `statusBarColor` is ignored on API 24–30.

  NormalTheme stays untouched. Then create `android/app/src/main/res/values-v31/styles.xml` and `android/app/src/main/res/values-night-v31/styles.xml`. Each defines both `LaunchTheme` (same parents as their non-v31 counterparts; the same four items plus `android:windowLightNavigationBar=false`, `android:windowSplashScreenBackground=@color/splash_field` and `android:windowSplashScreenAnimatedIcon=@drawable/splash_mark`) and an unchanged copy of `NormalTheme`, so the night qualifier can't shadow the SplashScreen attributes (research Decision 7). Depends on T039 and T038.

### Implementation for US1: native launch continuity (iOS)

- [X] T042 [P] [US1] Create `ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json` with a universal sRGB color `#1F6F5C`, plus a `"appearances": [{"appearance":"luminosity","value":"dark"}]` entry `#0E3D32`.
- [X] T043 [US1] Edit `ios/Runner/Base.lproj/LaunchScreen.storyboard`:
  - Add `<capability name="Named colors" minToolsVersion="9.0"/>` inside the existing `<dependencies>` block (it's absent today, and named colors fail to resolve or build without it).
  - Replace the view's `<color key="backgroundColor" red="1" green="1" blue="1" .../>` with `<color key="backgroundColor" name="LaunchBackground"/>`.
  - Add `<namedColor name="LaunchBackground"><color red="0.1216" green="0.4353" blue="0.3608" alpha="1" colorSpace="custom" customColorSpace="sRGB"/></namedColor>` to `<resources>`.
  - Update `<image name="LaunchImage" width="288" height="288"/>`.
  - Keep the centerX/centerY constraints unchanged.

  Depends on T042 and T038.
- [X] T044 [P] [US1] In `ios/Runner/Info.plist`, add `<key>UIStatusBarStyle</key><string>UIStatusBarStyleLightContent</string>`. Do not add `UIViewControllerBasedStatusBarAppearance`; its default must stay YES so the setting only affects the launch screen.

- [X] T045 [US1] Run `flutter test test/widget/splash_view_test.dart test/core/design_system/contrast_test.dart`; all pass. Depends on T029, T030 and T034–T036.

**Checkpoint / Acceptance (US1)**:

- Cold launch shows the emerald field plus the settled notebook from the native frame through to the Flutter splash, with no white flash or jump, in both Light and Dark.
- The localized name and tagline are shown and the text contrast is at least 4.5:1.
- The layout holds at 320×480, landscape, tablet and 2.0 text scale.

---

## Phase 4: User Story 2 — the mark tells the story in under a second (P1)

**Goal**: A 900 ms, non-repeating person → connection → coin → ledger-line story that mirrors with reading direction, with a 280 ms exit fade and a reduced-motion static state (FR-007–FR-010).

**Independent test**: Cold launch with animations enabled in English and Arabic, then with reduce motion on (quickstart M1, M3, M5, M13).

### Tests for US2

- [X] T046 [P] [US2] Create `test/widget/app_startup_gate_test.dart` with a harness. It pumps `MaterialApp(theme: buildLightTheme(), localizationsDelegates, home: BlocProvider<AppStartupCubit>.value(value: mockCubit, child: AppStartupGate(child: _ProbeChild())))`. `_ProbeChild` counts `build` calls and `initState` calls in static counters. The mock cubit (`MockCubit` from bloc_test via `whenListen`) exposes controllable states. Add the US2 cases:
  1. Ready from the start with animations on: at 450 ms the probe is not mounted; after `pump(900ms)` and then `pump(280ms)`, the probe is mounted and the `SplashView` is gone. The intro reaches its end without exceptions.
  2. `MediaQueryData(disableAnimations: true)` with ready from the start: after a single `pump()`, the probe is mounted and no `SplashView` remains (zero-duration exit).
  3. `Directionality` rtl renders the intro to completion without exceptions.

### Implementation for US2

- [X] T047 [US2] In `lib/features/startup/presentation/widgets/splash_mark.dart`, add `abstract final class SplashTimeline` with the `Interval`s from research Decision 8 as `static const` values:
  - `person = Interval(0.08, 0.30, curve: Curves.easeOutCubic)`
  - `connection = Interval(0.12, 0.45, curve: Curves.easeInOutCubic)`
  - `coinTravel = Interval(0.30, 0.72, curve: Curves.easeInOutCubic)`
  - `coinSettle = Interval(0.72, 0.84, curve: Curves.easeOutBack)`
  - `ledgerWrite = Interval(0.60, 0.86, curve: Curves.easeOutCubic)`
  - `connectionFade = Interval(0.78, 1.0, curve: Curves.easeOut)`
  - `wordmark = Interval(0.55, 1.0, curve: Curves.easeOutCubic)`

  Also add `introDuration = Duration(milliseconds: 900)` and `exitDuration = Duration(milliseconds: 280)`. Replace the literal durations in `app_startup_gate.dart` (T016) with these constants.
- [X] T048 [US2] In `lib/features/startup/presentation/widgets/splash_mark.dart`, add `class SplashMotionPainter extends CustomPainter`. Constructor `(Animation<double> t, TextDirection dir) : super(repaint: t)`. At `t == 0` it paints nothing, which preserves the frame-0 invariant. It paints:
  - **Person** at `SplashGeometry.personOrigin(dir)`: a head circle of radius `personHeadRadius`, and below it, after `personHeadGap`, a shoulder half-ellipse of size `personShoulders`, in `AppBrandColors.onField`. Opacity `person × (1 − connectionFade)`, scale 0.8→1.
  - **Connection**: a quadratic `Path` from the person to the coin centre via `connectionControl(dir)`. Stroke `connectionStroke` in `onField` at `connectionAlpha × (1 − connectionFade)` opacity, round caps. Trimmed with `PathMetric.extractPath(0, len × connection)`.
  - **Ledger line 1** (the y350 line), written in reading direction: from its start x to end x in ltr, from end to start in rtl. Stroke width as geometry, colour `AppBrandColors.field`, opacity 1, trimmed by `ledgerWrite`. It is drawn over the faint line.
  - **Coin** at `PathMetric.getTangentForOffset(len × coinTravel).position`. Scale `lerp(coinStartScale, 1.0, coinTravel)`, multiplied by the settle overshoot (`1 + coinSettleOvershoot × sin(π × coinSettle)`). Drawn as:
    - an offset shadow circle (`AppBrandColors.coinShadow` at `coinShadowAlpha`, offset `coinShadowOffset`)
    - a linear gradient fill `coinLight → coin → coinDeep`
    - a rim stroke `coinRim` at `coinRimAlpha`
    - "د" via a cached `TextPainter` (`fontWeight: w700`, `color: coinInk`, `fontSize: radius × coinGlyphScale`, `textDirection: rtl`) centred

    It is hidden while `coinTravel == 0`.

  `shouldRepaint` returns `dir != old.dir`. Only opacity, transforms and trimming change per frame; no per-frame blur or allocation of `Paint`s beyond fields. Depends on T047.
- [X] T049 [US2] In `SplashMark` (`lib/features/startup/presentation/widgets/splash_mark.dart`), add `CustomPaint(painter: SplashMotionPainter(intro, Directionality.of(context)))` above the static `RepaintBoundary` layer, wrapped in its own `RepaintBoundary`, in the slot from T033. Depends on T048.
- [X] T050 [US2] Animate `_SplashWordmark` in `lib/features/startup/presentation/widgets/splash_view.dart` with `FadeTransition` (`CurvedAnimation(parent: intro, curve: SplashTimeline.wordmark)`) and a `SlideTransition`-equivalent `AnimatedBuilder` translating y `SplashGeometry.wordmarkRise`→0 logical px. Combine it with the `appearanceResolved` gate: the opacity is `0` until resolved, then it follows the intro, or snaps to 1 if the intro is already complete. Depends on T047 and T035.
- [X] T051 [US2] Reduced motion in `lib/features/startup/presentation/widgets/app_startup_gate.dart`:
  - In `didChangeDependencies`, read `MediaQuery.disableAnimationsOf(context)`. If it's true and the intro hasn't been handed off: `_intro.value = 1.0` (no ticking) and `_introDone = true`. If `context.read<AppStartupCubit>().state.isReady`, also set `_handedOff = true` and `_splashRemoved = true` directly. **No `setState` and no `_exit.forward()` here**: `didChangeDependencies` runs inside the build phase, and `build` runs next anyway. If not yet ready, the `BlocListener` → `_maybeHandOff()` path completes it later. In `_maybeHandOff()`, when reduced motion is on, skip `_exit` and set `_splashRemoved = true` in the same `setState`.
  - Start `_intro.forward()` in the first `didChangeDependencies` rather than `initState`, so the flag is known before any tick.

  Depends on T047.
- [X] T052 [US2] Run `flutter test test/widget/app_startup_gate_test.dart test/widget/splash_view_test.dart`; all pass. Depends on T046 and T048–T051.

**Checkpoint / Acceptance (US2)**:

- The story plays once in ≤ 900 ms and ends in the launcher-icon composition.
- In Arabic, the person starts on the right and the line writes right-to-left; the notebook isn't mirrored.
- With reduce motion on, nothing moves and hand-off is immediate.
- The exit is a 280 ms fade with no Back entry to the splash.

---

## Phase 5: User Story 3 — always reaches the right place, never stuck (P1)

**Goal**: The correct destination exactly once, including notification cold-start. Failure or timeout shows a localized message with "Try again" (FR-012–FR-016, FR-020).

**Independent test**: Fresh install → Onboarding; returning → People; notification cold-start → its target; forced failure → error then recovery (quickstart M7–M9).

### Tests for US3

- [X] T053 [P] [US3] Add these cases to `test/widget/app_startup_gate_test.dart`:
  4. **Intro ends first**: states `preparing` for 1.5 s; the probe isn't mounted and the mark rests at its end state with no exceptions. Then emit `ready` → after `pump(280ms)` the probe is mounted, with `initState` count == 1.
  5. **Ready at exactly the intro end**: the probe's `initState` count is still 1.
  6. **Failed** (`failure: error`): no probe; `find.text(l10n.splashErrorMessage)` and a `FilledButton` with `l10n.commonRetry` are present. Tapping it calls `mockCubit.retry()` once. With `isRetry: true` in `preparing`, the button is disabled (`onPressed == null`) and a second tap does nothing.
  7. **Failed → retry → ready**: the probe is mounted once.
  8. **Error semantics**: the message node has `liveRegion`, and the button is ≥ 48×48.
  9. **Arabic error**: with locale `ar`, the Arabic message and "حاول مرة أخرى" are shown in RTL.
  13. **Back or tap during the splash** (spec Edge Case): while `preparing`, at 300 ms, `await tester.binding.handlePopRoute()` and `tester.tapAt(center)` → no exception and the probe isn't mounted. After `ready` and the intro end, the probe mounts once as normal.
- [X] T054 [P] [US3] Create `integration_test/splash_startup_flow_test.dart`, mirroring the existing `bootApp()` helper style from `integration_test/onboarding_flow_test.dart` (reset getIt → `configureDependencies()` → optional fresh-install clear → `pumpWidget(const DaftaryApp())` → `getIt<AppStartupCubit>().start()` → `pumpAndSettle()`). Cases:
  1. **Fresh install**: `find.byType(SplashView)` is present immediately after `pumpWidget`, then `OnboardingPage` after settle, and `SplashView` is absent.
  2. **Returning user** (onboarding completed): `PeopleListPage` after settle.
  3. The splash never re-appears after `pumpAndSettle()` (no `SplashView` found at any later point in the test).

### Implementation for US3

- [X] T055 [US3] Add `enum SplashMode { brand, error }` and parameters `{SplashMode mode = SplashMode.brand, VoidCallback? onRetry, bool retrying = false}` to `SplashView` in `lib/features/startup/presentation/widgets/splash_view.dart`. For `SplashMode.error`, build inside the same `AnnotatedRegion`/`Material`/`AnimatedContainer`:
  - `SafeArea` → `Center` → `SingleChildScrollView(padding: EdgeInsets.all(AppSpacing.lg))` → `ConstrainedBox(maxWidth: AppBreakpoints.maxReadingWidth)` → `Column(mainAxisSize: min)`, containing:
    - `SplashMark(intro: const AlwaysStoppedAnimation(1.0))`
    - `SizedBox(height: AppSpacing.lg)`
    - `Semantics(liveRegion: true, child: Text(l10n.splashErrorMessage, style: textTheme.bodyLarge!.copyWith(color: AppBrandColors.onField), textAlign: center))`
    - `SizedBox(height: AppSpacing.lg)`
    - `FilledButton(onPressed: retrying ? null : onRetry, style: FilledButton.styleFrom(backgroundColor: AppBrandColors.onField, foregroundColor: AppBrandColors.field, minimumSize: const Size(48, 48)), child: Text(l10n.commonRetry))`

  Depends on T034.
- [X] T056 [US3] Wire failure in `lib/features/startup/presentation/widgets/app_startup_gate.dart`:
  - In the `BlocListener`, when the state becomes `isFailed`, set `_intro.value = 1.0`, which stops motion (FR-016).
  - In `build` before hand-off, pass `mode: state.isFailed || (state.isRetry && !state.isReady) ? SplashMode.error : SplashMode.brand`, `onRetry: context.read<AppStartupCubit>().retry` and `retrying: state.status == AppStartupStatus.preparing`.
  - Hand-off after a successful retry still requires `_introDone`, which is already true.

  Depends on T055 and T016.
- [X] T057 [US3] Verify that `whenReady` chaining in `lib/main.dart` (T018) starts `NotificationRecomputeTrigger` and `NotificationTapRouter` exactly once, including after a failed → retried → ready sequence. `whenReady` resolves once, and both `start()` methods are already idempotent. Document the check in a code comment beside the chain. No behaviour change beyond T018.
- [ ] T058 [US3] Run `flutter test test/widget/app_startup_gate_test.dart` and `flutter test integration_test/splash_startup_flow_test.dart -d <simulator/emulator>`; all pass. Depends on T053–T057.

**Checkpoint / Acceptance (US3)**:

- Destinations match pre-feature behavior (Onboarding, People, notification target), and the Router mounts exactly once.
- Failure or timeout shows the localized message and an operable "Try again" that recovers.
- No launch path stays on the splash indefinitely.

---

## Phase 6: User Story 4 — only on a real launch (P2)

**Goal**: No replay on resume, rotation, or language or theme change (FR-017).

**Independent test**: Quickstart M6. The automated checks are below.

- [X] T059 [P] [US4] Add these cases to `test/widget/app_startup_gate_test.dart`:
  10. After hand-off, loop 20 times (SC-007): `tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused)`, `pump()`, `.resumed`, `pump()` → no `SplashView` at any iteration and the probe's `initState` count is still 1.
  11. After hand-off, rebuild the host `MaterialApp` with `buildDarkTheme()` and locale `ar` → no `SplashView`, and the probe's `initState` count is 1 (the gate's state is preserved).
  12. After hand-off, change `tester.view.physicalSize` to landscape → no `SplashView`.
- [X] T060 [P] [US4] Add a case to `integration_test/splash_startup_flow_test.dart`: after reaching People, switch the theme via `getIt<SettingsCubit>().changeThemeMode(AppThemeMode.dark)` and the language via `changeLanguage(AppLanguage.arabic)`, and simulate `paused` → `resumed`, with `pumpAndSettle` after each step. `SplashView` is never found and `PeopleListPage` remains.
- [ ] T061 [US4] Run `flutter test test/widget/app_startup_gate_test.dart` and the integration file from T060; all pass. If a replay occurs, fix it only inside `app_startup_gate.dart` (for example an accidental `Key` or a state reset), not in the router or `main.dart` theme code. Depends on T059 and T060.

**Checkpoint / Acceptance (US4)**: The splash appears only on process start.

---

## Phase 7: Polish, validation and platform verification

**Purpose**: Quality gates, scope audit, and device verification (quickstart M1–M13).

- [X] T062 Run `dart format lib test integration_test` and commit nothing unrelated. Only files from plan.md may show formatting changes.
- [X] T063 Run `flutter analyze` with zero issues. Fix issues the feature introduced; add no `// ignore` comments. Pre-existing unrelated warnings go to `notes-out-of-scope.md`.
- [X] T064 Run `flutter test` (all unit and widget tests) and record the pass count.
- [ ] T065 Run `flutter test integration_test -d <iOS simulator>` and `-d <Android emulator>` (the whole folder, including the 9 updated flows and `splash_startup_flow_test.dart`); all pass.
- [X] T066 [P] Dependency audit: `git diff main -- pubspec.yaml pubspec.lock` shows **no** changes.
- [X] T067 [P] Unused-code audit: no unused imports (the analyzer is clean), no unused `AppBrandColors` constants (grep each name under `lib/`), and no Flutter asset added to `pubspec.yaml`. `assets/icon/splash.png` is a generated source (like `icon.png`) and is committed alongside the others.
- [X] T068 [P] Scope audit: `git diff --stat main` lists only the files in plan.md's "Create"/"Modify" tables, plus the regenerated `app_localizations*.dart`, `injection.config.dart` and the generated PNGs. Anything else is reverted or explained in `notes-out-of-scope.md`.
- [ ] T069 Performance check (quickstart M13):
  - Run `flutter run --profile` on a physical or mid-range Android device and on iOS. Cold-launch 3 times with the DevTools timeline.
  - Confirm no UI or raster frame over 16 ms during the intro, and that the static notebook layer is not repainted after frame 1 (enable "Highlight repaints").
  - Confirm time-to-first-frame is not worse than on `main`.
  - Record the numbers in `specs/019-splash-screen/quickstart.md` under a "Results" heading.
- [ ] T070 Android verification on emulators API 29 and API 34+, Light/Dark × English/Arabic, plus a small phone, landscape and a tablet or foldable: quickstart M1–M8 and M10–M12. Screen-record M1 and M10 at 60 fps and confirm frame-0 equality and no white frame. Check the edge-to-edge field behind transparent bars with light icons.
- [ ] T071 iOS verification on iPhone SE, iPhone 16 Pro Max and iPad simulators (delete the app first to clear the launch-screen cache), Light/Dark × English/Arabic: quickstart M1–M8, M11 and M12, covering the safe area, Dynamic Island and the status-bar light content on the launch screen.
- [ ] T072 Mark every task complete in this file, update `specs/019-splash-screen/checklists/requirements.md` notes with the verification date, and list any residual limitations (for example the minor "د" glyph differences between platform fonts) in the final summary.

---

## Dependencies and execution order

### Phase dependencies

- **Setup (T001–T006)**: none; T002–T006 run in parallel.
- **Foundational (T007–T028)**: after Setup. **Blocks all user stories.**
- **US1 (T029–T045)**: after Foundational.
- **US2 (T046–T052)**: after US1 T033 and T035 (it extends `SplashMark` and the wordmark).
- **US3 (T053–T058)**: after Foundational and US1 T034. Can run in parallel with US2 because it touches different sections, but `splash_view.dart` and `app_startup_gate.dart` are shared, so run it **sequentially after US2** if there's a single developer.
- **US4 (T059–T061)**: after Foundational. Its tests are independent; the gate test file is shared, so append after US3's cases.
- **Polish (T062–T072)**: after all stories.

### Key task dependencies

- T010 ← T008, T009
- T013 ← T011, T012
- T014 ← T013
- T016 ← T013, T015
- T018 ← T014, T016
- T019–T027 ← T018
- T028 ← T010–T027
- T032 ← T031
- T033 ← T032
- T034 ← T033, T010
- T035 ← T034
- T036 ← T035
- T037 ← T031
- T038 ← T037
- T040, T041, T043 ← T038
- T048 ← T047
- T049 ← T048
- T050 ← T047, T035
- T051 ← T047
- T055 ← T034
- T056 ← T055, T016

### Parallel opportunities

- **Setup**: T002, T003, T004, T005 and T006 together.
- **Foundational**:
  - T007, T008, T009 and T011 together, and T012 alongside them.
  - Once T018 is done, T019–T027 (nine separate files) together.
- **US1**:
  - T029 and T030 (tests), plus T039, T042 and T044 (native files with no generated dependency), together.
  - After T038: T040, T041 and T043 together.
- **US3**: T053 and T054 together (different files).
- **US4**: T059 and T060 together.
- **Polish**: T066, T067 and T068 together.

### Parallel example (US1 kick-off)

```text
T029 splash_view_test.dart          | T030 contrast_test.dart
T039 android colors.xml (×2)         | T042 iOS LaunchBackground.colorset
T044 iOS Info.plist                 | T031 splash_mark.dart geometry (then T032→T033→T034…)
```

## Implementation strategy

1. **MVP = Setup + Foundational + US1**: a seamless, branded, static splash with safe startup. This is already shippable and removes the white screen.
2. **+ US2**: the signature motion story, reduced motion, and the exit fade.
3. **+ US3**: the error and retry UI and destination and once-only verification. The cubit-level safety already exists from Foundational.
4. **+ US4**: no-replay regression guards.
5. **Polish**: gates, audits and device verification.

## Requested-phase map

| Requested phase | Tasks |
|---|---|
| 1 Architecture preparation | T001–T006 |
| 2 Foundation (state, init, navigation, errors, exactly-once, lifecycle) | T011–T028, T056–T057 |
| 3 Visual design (field, mark, concept, typography, spacing, layout, responsive, light/dark) | T007, T015, T031–T036, T055 |
| 4 Animation (entry, motion, coin, ledger, exit, timing, curves, reduced motion, perf) | T016, T047–T051, T069 |
| 5 Localization and accessibility (en/ar, RTL/LTR, semantics, safe areas, sizes) | T008–T010, T018 (locale), T029, T035, T048 (direction), T053 (a11y), T055 |
| 6 Android and iOS | T039–T044, T037–T038, T070, T071 |
| 7 Testing | T012, T029, T030, T046, T052, T053, T054, T058–T061, T064, T065 |
| 8 Validation and quality | T062–T072 |

**Text decision**: the splash **does** show text (app name and tagline, plus the error message and button), all from ARB (research Decision 10). No user-facing string is hardcoded.

## Feature acceptance (all must hold)

- Visual identity matches the launcher icon and palette (US1).
- The story communicates people → money → ledger record (US2).
- Light, Dark, Arabic, English, RTL and LTR all verified (T029, T053, T070, T071).
- Reduced motion handled (T046 case 2, M5).
- Hand-off is reliable and happens exactly once, and the splash is never stuck (T012, T053, T054).
- Android and iOS verified (T070, T071).
- Existing flows are unaffected (T065).
- Tests and analysis pass (T063–T065).
- No new dependency (T066).
