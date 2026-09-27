# Quickstart: validating Liquid Glass

**Feature**: 020-liquid-glass-ui

## Prerequisites

- Flutter 3.47 stable (`flutter --version`).
- Dependencies fetched: `flutter pub get`, then `dart run build_runner build --delete-conflicting-outputs`. This regenerates drift (schema 8) and injectable.
- Devices:
  - one iPhone (iOS 15+);
  - one Android device on Impeller Vulkan (a recent Pixel or Galaxy);
  - one budget Android device on the GLES fallback.

## Automated checks

```bash
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter test                                   # full suite: must pass unchanged (SC-008)
flutter test test/core/database                # includes the v7 → v8 migration
flutter test test/features/settings            # repo, DAO, use cases, cubit
flutter test test/core/design_system/glass     # component OFF-identity / ON contracts
```

Expected results:

- All tests pass.
- No `// ignore`.
- `liquid_glass_widgets` is imported only under `lib/core/design_system/glass/`:

  ```bash
  grep -rl liquid_glass_widgets lib | grep -v core/design_system/glass
  ```

  This prints nothing, except `lib/main.dart`, which holds the bootstrap only.

## Spikes (run before migrating screens; research.md S1–S5)

1. **S1/S2**: Temporarily render `AppGlassSurface` behind `AppTopBar` on the People list with glass ON.
   - Pass: the list visibly frosts under the bar on all three devices.
   - Pass: the bar is a clean full-bleed rectangle.
2. **S3**: For each Transparency × Intensity level, in light and dark, screenshot the People list and Finance history scrolled mid-way. Measure the title and icon contrast against the bar's rendered pixels.
   - Pass: ≥ 4.5:1 for text and ≥ 3:1 for icons at every level.
   - If it fails: adjust `AppGlassTokens` only.
3. **S4**: On iOS, turn on Settings → Accessibility → Display & Text Size → Increase Contrast.
   - Pass: glass becomes the plain frosted surface and is still readable.
4. **S5**: Pump `AppGlassSurface` in a widget test with `flutter test`.
   - Pass: no shader or asset errors.

## Manual scenarios

| # | Steps | Expected |
| --- | --- | --- |
| 1 | Fresh install, finish onboarding | Glass ON. The top bars, bottom bar and FABs are glass. Lists scroll beneath them. |
| 2 | Settings → Appearance → turn Liquid Glass OFF | Every surface is instantly back to the pre-feature look. The controls and preview hide. |
| 3 | Compare scenario 2 with the `main` build (screenshots of People, Overview, Settings, a person detail, Finance history, a form, the duplicate-warning sheet) | Pixel-identical (SC-003) |
| 4 | Turn ON, set Transparency High and Intensity Low, then kill and relaunch the app | The same values from the first frame after the splash. No flash of the other mode. |
| 5 | Change each level while watching the preview | The preview updates in the same frame. The rest of Settings doesn't flicker. |
| 6 | Scroll the People list halfway, go to the Settings tab, change the intensity, then return | The People scroll position is preserved (SC-007) |
| 7 | Switch Arabic ↔ English and Light ↔ Dark with glass ON | Bars mirror in RTL. The tint follows the theme. Labels are localized. |
| 8 | System text size at maximum, glass ON | No clipping on the bars, FAB or sheet. Touch targets are unchanged. |
| 9 | Trigger the duplicate-person warning with glass ON | The sheet is glass, its content is readable, and its actions work as before. |
| 10 | Tablet or landscape ≥ 600dp | The navigation rail is unchanged. The page top bars follow the setting. |
| 11 | Toggle glass rapidly 10 times, then relaunch | The final state on screen equals the state after relaunch. |
| 12 | Make the DB read-only (debug) and toggle | The toggle still applies. A localized "couldn't save" snackbar appears. |

## Performance (SC-006)

Run with `flutter run --profile` on the budget Android device and the iPhone, with glass ON at High Intensity. Fling the longest People list and Finance history for 10 seconds while watching the DevTools performance overlay.

Pass: at least 95% of frames are within budget, with no shader-compile jank on the first toggle ON. That second condition is what the `initialize()` preload is for.
