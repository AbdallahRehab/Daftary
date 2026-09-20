# Quickstart: Validating Dark Mode / Theme Switching

## Prerequisites

- Flutter 3.38 stable / Dart SDK `^3.10.0` (matches `pubspec.yaml`) installed and on PATH.
- Repo dependencies installed: `flutter pub get`.
- Code generation run (Drift's `AppSettings.themeMode` column and the DI registrations
  for `GetThemeModePreference`/`ChangeThemeMode` are generated code):
  ```
  dart run build_runner build --delete-conflicting-outputs
  ```
- A connected device/emulator/simulator (Android or iOS — see plan.md Technical Context;
  desktop/web are out of scope).
- If upgrading an existing local install (schemaVersion 2 → 3, data-model.md), no manual
  step is needed — `AppDatabase.migration`'s `onUpgrade` runs automatically on first
  launch after the upgrade and leaves `themeMode` as `NULL` (resolved to "System Default"
  per FR-011).

## Run the app

```
flutter run
```

## Validate User Story 1 — Switch Between Light and Dark Theme (P1)

1. Launch the app; note current appearance (Light, by default under System Default on a
   light-mode device/simulator).
2. Navigate to the Settings tab (bottom navigation, per `002`'s `MainShell`).
3. Under the new "Theme" section (contracts/settings_repository.md — `SettingsPage`),
   select "Dark."
4. **Expected**: every currently visible screen — reachable via the People (home),
   Overview, and Settings tabs — updates to Dark theme immediately, with no app restart
   and no unstyled/white flash (SC-001: under 1 second). Navigate to the people list,
   a person's detail screen, the transaction/repayment forms, and Overview; confirm each
   renders fully in Dark (no leftover Light-only surfaces — this is the FR-007 audit
   scope: `AppCard`, `AppTextField`, `AppEmptyView`, `OverviewSummaryCard`,
   `BalanceStatusBadge`, `TransactionListTile`, `OverviewPage`'s inline colors, and
   `RelationshipTagChip` per research.md Decision 7).
5. Select "Light" again. **Expected**: the app returns to its original Light appearance,
   with no regression on any of the screens checked in step 4.
6. On a screen with financial values (Overview's totals, a person's transaction list),
   confirm all amount text remains clearly legible in Dark — cross-check against
   data-model.md's contrast table if in doubt.

## Validate User Story 2 — Theme Preference Persists Across Restarts (P1)

1. Set theme to Dark (per User Story 1, step 3).
2. Fully close the app (not just background it — force-stop/swipe away).
3. Reopen the app.
4. **Expected**: the app launches directly in Dark theme — no flash of Light theme before
   Dark applies, and no need to reselect it in Settings (SC-003).
5. Repeat steps 1-4 selecting "Light" instead. **Expected**: same result, launches in
   Light.

## Validate User Story 3 — Follow System Theme Automatically (P2)

1. In Settings, select "System Default."
2. Leaving the app open, change the device's system-wide Light/Dark setting via OS quick
   settings (e.g. iOS Control Center's Dark Mode toggle, Android's Quick Settings Dark
   theme tile).
3. Return to the app (or observe it live, if the OS toggle doesn't require leaving the
   app). **Expected**: the app's theme updates to match the new system setting without
   requiring an app restart (research.md Decision 6 — this is Flutter's built-in
   `themeMode: ThemeMode.system` behavior, not custom polling).
4. Fully close and reopen the app with the device still on, say, system Dark.
   **Expected**: the app launches in Dark, reflecting the device's *current* system theme
   — not a value cached from when "System Default" was first selected (data-model.md:
   the persisted value is literally `AppThemeMode.system`, re-resolved live on every
   launch, never a frozen snapshot).

## Validate Edge Cases

- **Mid-transition form/dialog state**: open the transaction form, type a partial amount
  and note, then switch theme from Settings (navigate back, switch, navigate forward —
  or, if a dialog/bottom sheet is open elsewhere, switch while it's open). **Expected**:
  the entered text and open dialog/bottom sheet are preserved and simply re-render in the
  new theme's colors — nothing is cleared or dismissed (FR-012).
- **First install, no explicit choice yet**: fresh install (or clear app data), before
  ever opening Settings. **Expected**: the app matches the device's current system
  appearance immediately (FR-011 default is `AppThemeMode.system`, not a hardcoded Light).
- **Loading/empty/error states in Dark**: trigger Overview's empty state ("All settled")
  and, if reachable, an error/retry state, while in Dark theme. **Expected**: both remain
  legible and visually consistent with the rest of Dark theme (FR-010).
- **No color-only meaning**: in Dark theme, confirm `BalanceStatusBadge` and
  `TransactionListTile` amounts each still carry their icon (arrow direction /
  check-circle) alongside color — not color alone (FR-009, data-model.md's FR-009
  cross-reference).

## Automated checks (for reference — not a substitute for the manual walkthrough above)

```
flutter analyze
flutter test
flutter test integration_test/theme_switch_flow_test.dart
```

See `data-model.md` for the exact `SettingsState`/`AppSettings` shapes these tests assert
against, and `contracts/settings_repository.md` / `contracts/theme_tokens.md` for the
exact interfaces they exercise.
