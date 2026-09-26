# Quickstart: Validating the Branded Splash Screen (019)

## Prerequisites

- Flutter 3.47 (`flutter --version`), Xcode, and an Android SDK with an API 34+ emulator plus an API 29 or 30 emulator (for the pre-SplashScreen-API path).
- Native launch assets regenerated: `python3 assets/icon/build_icon.py --splash` (splash only; never re-renders launcher icons). This needs Google Chrome for the SVG render and macOS `sips` for resizing.
- **iOS caches launch screens.** After changing them, delete the app from the simulator or device, and restart the simulator if the old launch screen still appears.

## Automated gates

```bash
dart format lib test integration_test
flutter analyze
flutter test                                   # unit + widget, incl. test/features/startup/**
flutter test integration_test/splash_startup_flow_test.dart -d <device>
flutter test integration_test -d <device>      # all existing flows still pass through the splash
```

Expected: all green, and no new analyzer issues.

## Manual scenarios (each maps to spec acceptance scenarios)

| # | Setup | Action | Expected |
|---|---|---|---|
| M1 | Device Light, app language English | Force-stop and launch; record the screen at 60 fps | Emerald field and notebook from the very first frame; no white flash, no mark jump (SC-001). The person appears on the **left**, the coin arcs onto the bottom-right corner, the top line writes left→right, and "Daftary" plus the tagline rise in. Hand-off fades to People or Onboarding in ≤ ~1.2 s total. |
| M2 | Device Dark | Same as M1 | Deep emerald field, same continuity; the text is legible. |
| M3 | App language Arabic | Same as M1 | Person on the **right**, line writes right→left, "دفتري" and the Arabic tagline are correctly shaped and RTL. The notebook is not mirrored. |
| M4 | Device Light, app theme set to Dark in Settings | Cold launch | The native launch screen is light emerald; the Flutter field crossfades to deep emerald over about 200 ms. No abrupt switch. |
| M5 | Reduce Motion (iOS) / Remove animations (Android) on | Cold launch | Static settled logo; no movement; hands off as soon as ready (SC-006). |
| M6 | App open on any screen | Home out and back; lock and unlock; rotate; switch language and theme in Settings | The splash never reappears; the same screen is kept (SC-007). |
| M7 | Fresh install, or clear app data | Launch | Splash → Onboarding. Complete onboarding, relaunch → splash → People. |
| M8 | A scheduled 017 notification posted, app killed | Tap the notification | Splash → the same destination or snackbar as before this feature. |
| M9 | Debug build with the startup failure hook (see below) | Launch | Motion stops; the localized error message and "Try again" appear; Try again recovers. |
| M10 | Android 10 emulator (API 29) and API 34 | Cold launch in Light and Dark | Continuity holds on both the legacy `launch_background` path and the Android 12+ SplashScreen path. |
| M11 | iPhone SE (small), iPhone 16 Pro Max, iPad; Android small phone, landscape, foldable | Cold launch | Mark centered and uncropped; text clear of notch, Dynamic Island and system bars; no overflow at the largest font size. |
| M12 | TalkBack / VoiceOver on | Cold launch; then M9 | "Daftary" announced once; the mark isn't announced; in the error state the message and button are announced and the button can be activated. |
| M13 | `flutter run --profile` | Cold launch with DevTools timeline | No jank frames during the intro; the first Flutter frame isn't later than before this feature (SC-002, SC-003). |

### Forcing a startup failure (M9)

There is no production switch. For a manual check, temporarily throw inside `OnboardingCubit.initialize()` in a local debug build, or make the database file unreadable on an emulator. The automated equivalent is G3/G4 in [contracts/app_startup_cubit.md](contracts/app_startup_cubit.md) and the gate widget tests.

## References

- Behavior and states: [data-model.md](data-model.md)
- APIs: [contracts/app_startup_cubit.md](contracts/app_startup_cubit.md), [contracts/splash_ui.md](contracts/splash_ui.md)
- Rationale: [research.md](research.md)
