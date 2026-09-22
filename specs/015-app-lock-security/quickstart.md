# Quickstart: Validate App Lock (Biometric/PIN) & Screenshot Protection

This is a run/validation guide, not an implementation reference — see `data-model.md` and `contracts/` for structure, and `tasks.md` (Phase 2) for build steps.

## Prerequisites

- Flutter 3.47.0 / Dart 3.10 SDK via `fvm` (`fvm flutter --version` to confirm).
- Dependencies installed and code regenerated once `local_auth`/`flutter_secure_storage`/`crypto` and new DI registrations land:
  ```bash
  fvm flutter pub get
  fvm dart run build_runner build --delete-conflicting-outputs   # injectable codegen
  ```
- A **physical** Android device or iOS device/simulator with biometrics enrolled is required to validate User Story 2 end-to-end (`local_auth` biometric prompts do not work meaningfully on most emulators without simulated fingerprint enrollment — Android emulators support `adb -e emu finger touch <id>` to simulate a fingerprint; iOS Simulator's Face ID/Touch ID can be enrolled and triggered via the Simulator's own Features menu). PIN-only flows validate fine on any emulator.
- No dependency on any other feature's data — this feature can be validated on a fresh install with zero prior People/Transactions data, though testing that it doesn't interfere with real screens is more convincing with some existing data present.

## Run the app

```bash
fvm flutter run
```

App Lock is off by default on both a fresh install and an upgrade — confirm the app behaves exactly as before this feature until Security settings are opened and App Lock is explicitly enabled (FR-001).

## Automated verification

```bash
fvm flutter analyze                # static analysis gate (constitution: must be clean)
fvm flutter test                   # unit + Cubit + widget tests, especially PinHasher's and
                                    # LockoutPolicy's exhaustive pure-function suites
fvm flutter test integration_test  # end-to-end flows (requires a running device/emulator;
                                    # biometric steps use a BiometricService test double, not
                                    # real OS biometric prompts, per plan.md Project Structure)
```

## Manual validation scenarios

Each scenario maps directly to a spec acceptance scenario; use as a scripted smoke test after implementation.

### 1. Enable App Lock and set a PIN (User Story 1)
1. Open Settings → Security. Confirm App Lock shows off and no lock screen has ever appeared.
2. Enable App Lock; set PIN `1234` then confirm with `1234`.
   - **Expect**: App Lock activates immediately.
3. Enable App Lock again from scratch (after disabling); enter `1234` then confirm with `5678`.
   - **Expect**: mismatch rejected with a clear message; first entry is not silently discarded — user can retry the confirmation step.
4. Background the app (home button) and reopen it.
   - **Expect**: lock screen appears before any People/Transactions content is visible.
5. Enter the correct PIN.
   - **Expect**: unlocks to exactly the screen last shown before backgrounding.
6. Enter an incorrect PIN.
   - **Expect**: rejected with a clear error; app stays locked.

### 2. Biometric unlock with PIN fallback (User Story 2)
1. With App Lock enabled and biometrics enrolled on the device, enable biometric unlock in Security settings.
   - **Expect**: toggle succeeds; if no biometrics are enrolled, the toggle is disabled with an explanation instead.
2. Background and reopen the app.
   - **Expect**: biometric prompt appears automatically, with a visible "Use PIN instead" option alongside it.
3. Authenticate successfully with biometrics.
   - **Expect**: unlocks immediately, no PIN entry required.
4. Cancel or fail the biometric prompt.
   - **Expect**: offered retry or PIN entry; this failure does NOT count toward the PIN lockout counter (verify by then entering 4 wrong PINs afterward and confirming no lockout yet at attempt 5, not 4 — i.e. the biometric failure didn't pre-consume a slot).
5. Disable biometric enrollment at the OS level (device Settings → remove all fingerprints/Face ID), then reopen the app.
   - **Expect**: lock screen falls back to PIN entry automatically with a message that biometric needs to be re-confirmed.

### 3. Lockout after repeated wrong PINs (User Story 3)
1. Enter the wrong PIN 5 times in a row.
   - **Expect**: a 30-second cooldown engages with a visible countdown; PIN entry disabled during it.
2. Wait for the cooldown to expire.
   - **Expect**: PIN entry re-enabled automatically with no extra action.
3. Fail 3 more times (reaching 8 total).
   - **Expect**: a 2-minute cooldown engages (longer than the first).
4. During an active cooldown, attempt biometric unlock (if enabled/available).
   - **Expect**: biometric remains usable — not blocked by the PIN lockout.
5. Force-quit the app mid-cooldown and relaunch.
   - **Expect**: the cooldown is still in effect (not reset by the relaunch).

### 4. Forgot PIN recovery (User Story 4)
1. On the lock screen, tap "Forgot PIN" with biometric enabled and available.
   - **Expect**: offered biometric re-authentication first; on success, allowed to set a new PIN with zero data loss (spot-check that existing People/Transactions data is untouched afterward).
2. Repeat with biometric disabled/unavailable.
   - **Expect**: clearly explained that the only recovery is a full local data wipe — no other option is offered or implied.
3. Proceed to the wipe confirmation screen and cancel before confirming.
   - **Expect**: returns to the normal lock screen with zero data altered.
4. Proceed and complete the strong confirmation.
   - **Expect**: all local data (People, Transactions, App Lock's own configuration) is erased; app returns to the first-launch/Onboarding state.

### 5. Screenshot and screen-recording protection (User Story 5)
1. With App Lock **off**, open any screen with financial content and attempt a screenshot.
   - **Expect**: blocked or blacked out on Android; obscured/blocked per the iOS approach — confirms protection is independent of App Lock.
2. Switch to the OS app-switcher/recents view.
   - **Expect**: Daftary's thumbnail shows a neutral branded placeholder, not the last visible screen.
3. Start a screen recording (iOS Control Center) while using the app.
   - **Expect**: an obscuring overlay appears for the duration of the recording.
4. Trigger a legitimate OS share-sheet flow from within the app (if available from another shipped feature).
   - **Expect**: completely unaffected by screenshot protection.

### 6. Manage security settings (User Story 6)
1. With App Lock enabled, choose "Change PIN."
   - **Expect**: requires authenticating first (PIN or biometric), then a normal set-twice PIN flow.
2. Change the inactivity timeout from 1 minute to Immediately.
   - **Expect**: the very next backgrounding triggers an immediate lock on return, regardless of duration backgrounded.
3. Disable biometric unlock while both methods are active.
   - **Expect**: subsequent lock screens show PIN entry only.
4. Disable App Lock entirely.
   - **Expect**: no more lock screens on launch/resume; screenshot protection (Scenario 5) still applies.
5. Re-enable App Lock.
   - **Expect**: fresh PIN setup is required — the old PIN is not silently reused.

### 7. Localization and theming (FR-029)
1. Switch the app language to Arabic while the lock screen, PIN pad, and lockout countdown are visible.
   - **Expect**: correct RTL layout, numeral/date/duration formatting, no truncation.
2. Switch between light and dark mode on the Security settings and Forgot-PIN/wipe-confirmation screens.
   - **Expect**: all remain legible and correctly themed.
