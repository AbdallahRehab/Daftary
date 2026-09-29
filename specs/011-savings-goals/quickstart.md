# Quickstart: Validate Savings Goals

This is a run/validation guide, not an implementation reference — see `data-model.md` and `contracts/` for structure, and `tasks.md` (Phase 2) for build steps.

## Prerequisites

- Flutter 3.47.0 / Dart 3.10 SDK via `fvm` (`fvm flutter --version` to confirm).
- Dependencies installed and code regenerated once the migration/new DI registrations land:
  ```bash
  fvm flutter pub get
  fvm dart run build_runner build --delete-conflicting-outputs   # drift + injectable codegen
  ```
- An Android emulator/device or iOS simulator/device attached (`fvm flutter devices`).
- Scenarios 1-5 need no other data. Scenario 6 needs at least one exchange rate configured (018 Settings → Currency). Scenario 7 needs two devices/simulators signed in to the same account (021) and the Supabase migration `023_savings_goals_sync` applied.

## Run the app

```bash
fvm flutter run
```

On first launch after this feature ships, the local migration (schema v10 → v11) creates `SavingsGoals`/`SavingsContributions`/`SavingsContributionAudits` automatically; it touches no existing table. The feature works fully offline; sync starts once the user is signed in.

## Automated verification

```bash
fvm flutter analyze                # static analysis gate (constitution: must be clean)
fvm flutter test                   # unit + Cubit + widget tests, especially SavingsCalculator's
                                    # exhaustive pure-function suite
fvm flutter test integration_test  # end-to-end flows (requires a running device/emulator)
```

## Manual validation scenarios

Each scenario maps directly to a spec acceptance scenario; use as a scripted smoke test after implementation.

### 1. Create a goal (User Story 1)
1. Create "Emergency Fund," target 100,000 EGP, monthly contribution 5,000 EGP.
   - **Expect**: remaining 100,000 EGP, estimated completion 20 months.
2. Create it again but with a starting amount of 35,000 EGP.
   - **Expect**: remaining recalculates to 65,000 EGP, estimated completion to 13 months (matches the product brief's own worked example).
3. Try a target amount of 0.
   - **Expect**: blocked with a clear message.
4. Create a goal with a target date instead of a monthly contribution (e.g. 10 months from now).
   - **Expect**: required monthly contribution is computed and shown.
5. Create a goal with neither a monthly contribution nor a target date.
   - **Expect**: saved successfully; a prompt explains that setting one unlocks a completion estimate.

### 2. Log contributions and track progress (User Story 2)
1. On the Emergency Fund goal (current 35,000), log a 5,000 EGP contribution.
   - **Expect**: current becomes 40,000; remaining and estimated completion both update.
2. Log a one-off 10,000 EGP contribution (e.g. a bonus).
   - **Expect**: accepted, reflected immediately, visible in history alongside regular entries.
3. Log a 3,000 EGP withdrawal.
   - **Expect**: current decreases by 3,000; shown distinctly as a withdrawal in history.
4. Attempt to withdraw more than the current balance.
   - **Expect**: blocked with a clear explanation.
5. Push contributions until current reaches/exceeds target.
   - **Expect**: goal shown as achieved, with a celebratory (not warning-style) visual treatment.
6. Edit an earlier contribution's amount, then delete a different one.
   - **Expect**: current/remaining/estimated completion recalculate immediately both times.

### 3. What-if scenarios (User Story 3)
1. On a goal with remaining 65,000 EGP and monthly contribution 5,000 EGP (13 months), open what-if and ask "what if I save 1,000 EGP more per month."
   - **Expect**: shows 6,000 EGP/month, 11 months — goal's real stored contribution is unchanged (re-open the goal to confirm).
2. Ask "what contribution do I need to finish in 10 months."
   - **Expect**: shows 6,500 EGP/month.
3. Apply one of the above scenarios.
   - **Expect**: the goal's actual monthly contribution/target date updates to match; this is the only action that changed it.
4. Try a hypothetical monthly contribution of 0, and a hypothetical target date in the past.
   - **Expect**: both rejected with clear explanations.
5. Open the what-if calculator on an already-achieved goal.
   - **Expect**: a clear "nothing left to plan for" message, no misleading recalculation offered.

### 4. Multiple goals (User Story 4)
1. Create 3 goals with different targets/progress; open the goals overview.
   - **Expect**: each listed with progress, plus a correct combined total currently saved.
2. Archive one goal.
   - **Expect**: disappears from the active list, still viewable/editable/restorable under archived goals, history intact.
3. Attempt to permanently delete a goal with logged contributions.
   - **Expect**: blocked, offered to archive instead.
4. Delete a goal with zero contributions.
   - **Expect**: permanently removed, no confirmation-bypass issue.
5. On a fresh install with zero goals, open the goals section.
   - **Expect**: friendly empty state with a direct "create your first goal" action.

### 5. Localization and theming (FR-025)
1. Switch the app language to Arabic and reopen an achieved goal and the what-if calculator.
   - **Expect**: correct RTL layout, numeral/date formatting, no truncation in the celebratory state or calculator.
2. Switch between light and dark mode.
   - **Expect**: progress indicators and the achieved badge remain legible and correctly themed.

### 6. Currency (FR-019, FR-027, FR-028)
1. With EGP primary and a USD rate set, create a USD goal and log 100 USD into an EGP goal.
   - **Expect**: the EGP goal's history row shows 100 USD and the converted EGP amount; progress counts the EGP amount.
2. Remove the USD rate, then try to log another USD contribution.
   - **Expect**: blocked, message names USD; nothing recorded.
3. Open the overview.
   - **Expect**: the USD goal is listed with its own progress; the EGP total excludes it and is marked incomplete, naming USD.
4. Edit the goal and look for a currency field.
   - **Expect**: none — currency is fixed at creation.

### 7. Sync and audit (FR-024, FR-030)
1. On device A, create a goal and log two contributions; on device B, pull.
   - **Expect**: the goal and both entries appear with identical figures.
2. On device A, edit one entry and delete the other; sync.
   - **Expect**: device B reflects both changes; two audit rows exist (inspect `savings_contribution_audits`) with the prior values.
3. Use Settings → Delete all my data.
   - **Expect**: savings goals, contributions and audits are gone locally and in the cloud.

### 8. Integrations (FR-031)
1. Enable savings check-ins in notification settings with an active goal behind pace.
   - **Expect**: a savings check-in fires and tapping it opens `/savings/:goalId`.
2. Ask the AI assistant "how much do I need to save monthly to reach my goal?"
   - **Expect**: the figure matches the goal detail screen exactly.
3. Open Home.
   - **Expect**: a Savings card opens the goals overview; the Upcoming section lists goals with target dates instead of the placeholder.
4. Turn Liquid Glass on and walk every savings screen.
   - **Expect**: app bars and sheets use glass like the rest of the app.
