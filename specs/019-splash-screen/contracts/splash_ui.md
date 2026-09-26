# Contract: Splash UI (gate, view, mark)

## `AppStartupGate` (`lib/features/startup/presentation/widgets/app_startup_gate.dart`)

`StatefulWidget` with `TickerProviderStateMixin`; `const AppStartupGate({required Widget child})`.

- **Where it's used**: `DaftaryApp` → `MaterialApp.router(builder: (context, child) => AppStartupGate(child: child!))`.
- **Reads**: `BlocBuilder<AppStartupCubit, AppStartupState>`, provided by `DaftaryApp`'s `MultiBlocProvider`.
- **Before hand-off**: renders only `SplashView`; `child` is **not** in the tree.
- **Hand-off**: happens when `_introDone && state.isReady`, reached from a `BlocListener` or the intro's status listener, whichever comes last.
  - It sets `_handedOff` once, then builds `Stack[child, IgnorePointer(FadeTransition(_exit, SplashView))]` and starts `_exit`.
  - When `_exit` completes, it builds just `child`.
  - **Reduced motion**: `_intro.value = 1` and `_exit` duration is `Duration.zero`.
- **Failure**: sets `_intro.value = 1` and passes `failed`/`isRetry` to `SplashView`, which shows the error block.
- **Never**: calls `context.go`/`push`, keys itself on locale or theme, or listens to app lifecycle.

## `SplashView` (`lib/features/startup/presentation/widgets/splash_view.dart`)

`StatelessWidget` with `{required Animation<double> intro, required SplashMode mode, VoidCallback? onRetry, bool retrying = false}`, where `enum SplashMode { brand, error }`.

The tree, top to bottom:

- `AnnotatedRegion<SystemUiOverlayStyle>`: light icons, transparent status and navigation bars.
  - `Material` (not `Scaffold`, so queued snackbars wait for the first real `Scaffold`), with a transparent type.
    - `AnimatedContainer`:
      - color: `field` or `fieldDeep` by `Theme.of(context).brightness`
      - duration: 200 ms, or zero with reduced motion
      - fills the whole screen, edge to edge
      - **Brand mode**: a `LayoutBuilder` with a `Stack`:
        - `Center` → `SplashMark(intro)`, 288×288 logical px, centered on the **full** screen (matches native).
        - `Positioned(top: h/2 + SplashGeometry.contentBottom + AppSpacing.xl, start: 0, end: 0, bottom: 0)`, inside `SafeArea(top: false)` and horizontal `AppSpacing.lg` padding. It holds an `Align(topCenter)` → `FittedBox(scaleDown)` → `SplashWordmark`.
        - `SplashWordmark` shows `appTitle` (`headlineSmall`, `onField`, `Semantics(header: true)`) and `splashTagline` (`bodyMedium`, `onField`), separated by `AppSpacing.xs`. Opacity and translateY come from the intro interval 0.55–1.0. It stays at opacity 0 until `appearanceResolved`, which is passed in.
      - **Error mode**: `SafeArea` → `Center` → `SingleChildScrollView` → `ConstrainedBox(maxWidth: AppBreakpoints.maxReadingWidth)` → `Column(min)`:
        - `SplashMark` (settled)
        - gap `AppSpacing.lg`
        - `Semantics(liveRegion: true)` → `Text(splashErrorMessage, bodyLarge, onField, center)`
        - gap `AppSpacing.lg`
        - `FilledButton` (`commonRetry`, `backgroundColor: onField`, `foregroundColor: field`, `minimumSize: Size(48, 48)`, disabled while `retrying`)

## `SplashMark` and painters (`lib/features/startup/presentation/widgets/splash_mark.dart`)

- `SplashMark({required Animation<double> intro})` is a 288×288 `Stack`:
  1. `RepaintBoundary(CustomPaint(painter: SplashNotebookPainter()))`: static, `shouldRepaint` returns false. It draws the page-edge stack, cream page gradient, spine gradient with binding holes, three ledger lines at 0.28 opacity, the ribbon, and a single soft drop shadow.
  2. `CustomPaint(painter: SplashMotionPainter(intro, textDirection))`: repaints from `intro` via `super(repaint: intro)`. It draws:
     - the person glyph (head circle and shoulder arc) at the reading-start side
     - the connection path (quadratic curve, `onField` at 0.45 opacity, trimmed)
     - the top ledger line written in reading direction (`field` color)
     - the coin (gradient, rim and "د" via `TextPainter`, plus an offset shadow circle) along the path
- The whole mark is `ExcludeSemantics`.
- **Geometry**: `SplashGeometry` (same file) holds every coordinate in the 1024-unit icon space, scaled by `extent / 1024`, with `splashMarkScale = 0.9` and the notebook re-centered. A comment says it must stay in sync with `SPLASH` in `assets/icon/build_icon.py`. It also defines `contentBottom`, the lowest painted point relative to center (about 76 logical px), which is used for the text offset.
- **Frame 0 invariant**: at `intro == 0`, the output is exactly the notebook layer (motion painter draws nothing), which equals `splash_mark.png`.

## Localization keys (`lib/core/l10n/app_en.arb`, `app_ar.arb`)

- New: `splashTagline`, `splashErrorMessage`, each with an `@` description.
- Reused: `appTitle`, `commonRetry`.
