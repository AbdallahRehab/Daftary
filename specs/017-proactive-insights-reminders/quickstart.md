# Quickstart: Validate Proactive Insights & Reminders/Notifications

This is a run/validation guide, not an implementation reference — see `data-model.md` and `contracts/` for structure, and `tasks.md` (Phase 2) for build steps.

## Prerequisites

- Flutter 3.47.0 / Dart 3.10 SDK via `fvm` (`fvm flutter --version` to confirm).
- Dependencies installed and code regenerated once the migration/new DI registrations land:
  ```bash
  fvm flutter pub get
  fvm dart run build_runner build --delete-conflicting-outputs   # drift + injectable codegen
  ```
- **Requires Budgets (010) and Savings Goals (011) implemented in code**, not just spec'd, for meaningful end-to-end validation — this feature reads their real data. Unit/Cubit-level tests can run against fixtures regardless of 010/011's implementation status; `integration_test` scenarios below assume both exist.
- A physical device or emulator with notification permission promptable (most emulators support this fine, unlike 015's biometric requirement).

## Run the app

```bash
fvm flutter run
```

Notifications are off by default (FR-010) — confirm the app behaves exactly as before this feature until Notification Settings are opened and the feature is explicitly enabled.

## Automated verification

```bash
fvm flutter analyze                # static analysis gate (constitution: must be clean)
fvm flutter test                   # unit + Cubit + widget tests, especially
                                    # EvaluateBudgetNotifications/EvaluateSavingsGoalNotifications'
                                    # exhaustive pure-classification suites
fvm flutter test integration_test  # end-to-end flows (requires a running device/emulator and
                                    # 010/011 implemented; notification delivery uses a
                                    # NotificationScheduler test double, never real OS spam
                                    # during automated runs)
```

## Manual validation scenarios

Each scenario maps directly to a spec acceptance scenario; use as a scripted smoke test after implementation.

### 1. Budget-limit warning (User Story 1)
1. Create a budget for "Groceries," planned 2,000 EGP; add expense entries totaling 1,700 EGP (85%).
2. Trigger a recomputation (e.g. a debug-only "run now" action, or wait for the foreground trigger).
   - **Expect**: a "near limit" notification appears stating "Groceries" and 85%, matching the Budgets screen's own displayed percentage exactly.
3. Add another 500 EGP in expenses (now over 100%).
   - **Expect**: a distinct "exceeded" notification appears (not a repeat of the near-limit one).
4. Trigger recomputation again with no new expenses.
   - **Expect**: no duplicate notification (band unchanged).
5. Tap the exceeded notification.
   - **Expect**: app opens directly to the Groceries category's budget detail.
6. Disable "Budget warnings" only, then push another category over its limit.
   - **Expect**: no notification for that category; a savings-goal check-in (if independently triggered) still works.

### 2. Savings-goal check-in (User Story 2)
1. Create a savings goal "Emergency Fund," target 100,000 EGP, monthly contribution 5,000 EGP; log contributions well behind that pace for the elapsed time.
2. Trigger recomputation.
   - **Expect**: a "behind pace" notification appears with the real behind-by-months figure, matching what the goal's own detail screen's projection would show.
3. Log enough contributions to move ahead of pace instead; recompute.
   - **Expect**: a distinct "ahead of pace" notification appears.
4. Push contributions until the goal is achieved; recompute.
   - **Expect**: a one-time achievement notification appears; a further recompute with no change produces no further pace notification for this goal.
5. Tap any of the above notifications.
   - **Expect**: app opens directly to that goal's detail screen.

### 3. Notification settings and control (User Story 3)
1. Open Notification Settings for the first time.
   - **Expect**: feature shown off by default with a clear enable action.
2. Enable the feature.
   - **Expect**: OS permission prompt appears at this exact moment (not earlier), with a clear rationale.
3. Deny the OS permission, then return to settings.
   - **Expect**: a clear "notifications can't be delivered" state with a link to device settings.
4. Grant permission; set quiet hours 10 PM–8 AM; trigger a recomputation with a real over-budget condition during that window (simulate the clock or use a debug override).
   - **Expect**: notification is deferred, delivered once the window ends, never delivered during it.
5. Disable the feature entirely.
   - **Expect**: no further notifications regardless of real conditions; Budgets/Savings Goals data and calculations are unaffected (spot-check both screens still show correct figures).
6. Re-enable the feature.
   - **Expect**: only current real conditions evaluated going forward — no backlog delivery.

### 4. Cross-cutting: cooldown, month reset, and offline verification
1. Hold a budget category at a constant 85% across a simulated multi-day period (SC-003).
   - **Expect**: exactly one notification total, at the point it first crossed 85%.
2. Advance to a new budget month with the same category again crossing 85% independently.
   - **Expect**: a fresh notification fires for the new month (band reset, FR-016).
3. With the device in airplane mode throughout, repeat Scenarios 1-2.
   - **Expect**: fully functional — zero network requests observed at any point (FR-017).
4. Switch the app language between Arabic and English, and light/dark mode, on Notification Settings.
   - **Expect**: zero layout, alignment, or truncation defects (SC-007).
