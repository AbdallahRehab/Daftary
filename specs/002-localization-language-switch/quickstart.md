# Quickstart: Validate Arabic/English Localization + Language Switch

This is a run/validation guide, not an implementation reference — see `data-model.md` and `contracts/` for structure, and `tasks.md` (Phase 2) for build steps.

## Prerequisites

- Flutter 3.38 stable / Dart 3.10 SDK installed (`flutter --version` to confirm).
- Dependencies installed and code regenerated once the tasks phase has added the `AppSettings` table/DI registrations:
  ```bash
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs   # drift + injectable codegen
  ```
- An Android emulator/device or iOS simulator/device attached (`flutter devices`), ideally one whose OS language can be switched (for the first-launch-default scenario below).

## Run the app

```bash
flutter run
```

On first launch (or after this feature's DB migration runs against an existing v1 database), the app resolves its starting language per FR-009 — no manual setup needed.

## Automated verification

```bash
flutter analyze                # static analysis gate (constitution: must be clean)
flutter test                   # unit + Cubit + widget tests
flutter test integration_test  # end-to-end language-switch-and-persist flow
```

## Manual validation scenarios

Each scenario maps directly to a spec acceptance scenario; use them as a scripted smoke test after implementation.

### 1. Switch language live (User Story 1, spec Acceptance Scenarios 1-3)

1. Launch the app in English. Tap the **Settings** tab in the bottom navigation.
2. Select **Arabic**.
   - **Expect**: within ~1-2 seconds, all visible text switches to Arabic, the layout mirrors to RTL, and the bottom navigation bar itself reorders/mirrors — no app restart, no full-screen flash.
3. Tap the **People** tab (now on the mirrored side).
   - **Expect**: the People list is fully in Arabic/RTL, and if you had previously pushed a screen on that tab (e.g. a person's detail page) before switching, it's still there when you navigate back into it — not reset to the list root.
4. Repeat in reverse: switch back to English from the Settings tab and confirm LTR returns everywhere, including the bottom nav.

### 2. Persistence across restart (User Story 2, spec Acceptance Scenarios 1-3)

1. Set the language to Arabic. Fully close the app (not just background it) and relaunch.
   - **Expect**: the app opens directly in Arabic/RTL — no reselection needed.
2. Repeat, setting English instead.
3. Uninstall and reinstall the app (or clear its data) to simulate a genuine first launch, with the device's OS language set to Arabic.
   - **Expect**: the app opens in Arabic on that very first launch (FR-009), and that becomes the persisted choice from then on. Repeat with the device OS language set to something other than Arabic or English (e.g. French) — expect the app to open in English.

### 3. Full-app correctness in both directions (User Story 3, spec Acceptance Scenarios 1-4)

1. With Arabic active, walk through every screen: People list, a person's detail/history, add/edit a transaction, record a repayment, archived people, Overview, and any dialog/bottom sheet/confirm-delete flow.
   - **Expect**: every visible string is Arabic (no leftover English), layout/icons/navigation are correctly mirrored, and no text overlaps, clips, or is cut off.
2. On a screen showing money amounts and dates (Overview, a person's transaction list), inspect the digits closely.
   - **Expect**: amounts and dates use Western digits (0-9) — never ٠١٢٣٤٥٦٧٨٩ — even though the surrounding text is Arabic (spec Clarifications).
3. Create or view a person whose name was typed in English while the app is in Arabic.
   - **Expect**: the Latin-script name renders legibly inline within the Arabic-RTL layout, with no reversed characters or corrupted spacing.
4. Repeat step 1 in English/LTR as a regression check — nothing that worked before this feature should now be broken.

### 4. Persistence-failure resilience (Edge Cases, FR-008)

This scenario needs a way to force the local DB write to fail (e.g. a debug-only fault injection point on `SettingsRepositoryImpl`, or exercising the unit-level `SettingsCubit` test directly — see `test/features/settings/presentation/cubit/`). Not expected to be reproducible by hand on a normal device; treat the automated Cubit test covering this path (research.md Decision 7) as the primary verification, and use this only if a manual repro path exists in your build:

1. Force the next settings write to fail, then select a different language in Settings.
   - **Expect**: the UI still switches immediately to the new language (never blocked on the failed write), and only after the single silent retry also fails does a small non-blocking notice appear — the app remains fully usable in the newly selected language throughout.
