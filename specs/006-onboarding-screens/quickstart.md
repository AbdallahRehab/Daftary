# Quickstart: Validating Onboarding / Intro Screens

This is a runnable validation guide, not an implementation guide — it proves the feature works end-to-end against the acceptance scenarios in `spec.md`. See `data-model.md` for the `OnboardingStatus` table shape and `contracts/onboarding_repository.md` for the exact interfaces exercised below.

## Prerequisites

- Feature 002 (localization/settings) and feature 003 (dark mode) are implemented, since onboarding directly reuses their language and theme mechanisms (spec Assumptions).
- `flutter pub get` has been run after the schema/DI changes land (`app_database.dart` schemaVersion 4 — this feature's own migration, assuming `003-dark-mode-theme`'s 2→3 migration has already landed — regenerated `injection.config.dart`, `app_localizations.dart` regenerated from the ARB additions).

```sh
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs   # regenerates injection.config.dart, app_database.g.dart
flutter gen-l10n                                                  # regenerates app_localizations*.dart from the new ARB keys
```

## Automated validation

```sh
flutter analyze
flutter test test/features/onboarding
flutter test test/features/people    # includes the new hasAnyPerson cases
flutter test test/features/transactions   # includes the new hasAnyTransaction cases
flutter test test/widget/onboarding_page_test.dart
flutter test integration_test/onboarding_flow_test.dart
```

All of the above MUST pass before this feature is considered done (Definition of Done).

## Manual / scripted scenario validation

Each scenario below maps directly to a spec User Story or Edge Case. For a real device/simulator, "reinstall" means uninstall + reinstall (clears local SQLite); "restart" means fully close (swipe away, not just backgrounding) and relaunch.

### User Story 1 — First-time user sees onboarding before the main app (P1)

1. Fresh install (no prior `OnboardingStatus` row, no `Person`/`MoneyTransaction` rows) → launch the app.
2. **Expect**: the onboarding sequence appears first; no People/Overview/Settings screen is reachable before it. Verify via `integration_test`: assert the widget tree shows `OnboardingPage` and does not show `MainShell`/`NavigationBar` immediately after `pumpAndSettle()` on cold start.
3. Step through all 5 screens (`OnboardingTopic.values` order) and confirm each screen's title/description matches its topic (understanding money → money between people → social occasions → scanning records → AI assistant) and contains no accounting jargon (manual content review, SC-005 for the AI-assistant screen specifically — confirm no unsupported financial promise language).

### User Story 2 — Navigate and complete onboarding (P1)

1. From screen 1, tap Next repeatedly; verify `OnboardingProgressIndicator` updates ("step 2 of 5", etc.) at each step and the correct screen content renders.
2. From any screen after the first, tap Back; verify it returns to the previous screen with the indicator decremented correctly.
3. On screen 5 (last), verify the CTA button reads as a clear "finish"/"get started" action (not "Next") — tap it.
4. **Expect**: navigates directly into the main app's normal entry point (People list, per `app_router.dart`'s `'/'` route).
5. Time the walkthrough tapping straight through with no pauses: **Expect** under 60 seconds total (SC-002).

### User Story 3 — Completion is remembered (P1)

1. Complete onboarding (Scenario above), fully close the app, relaunch.
2. **Expect**: app opens directly to the main entry point; `OnboardingPage` never appears. Verify the `OnboardingStatus` row now has `isComplete = true` (query the dev DB, or assert via `OnboardingRepositoryImpl.isOnboardingComplete()` in a widget/integration test).
3. Repeat using the Skip path (Scenario below) instead of finishing — same expectation on relaunch.

### User Story 4 — Skip onboarding (P2)

1. From any onboarding screen (first, middle, or last), tap Skip.
2. **Expect**: navigates directly into the main app immediately (no confirmation dialog required by the spec).
3. Relaunch the app: **Expect** onboarding does not reappear (same persisted-flag check as User Story 3).

### FR-010a — Existing installs are treated as already onboarded

1. Simulate an "existing user upgrading" state: seed the local DB with at least one `Person` row (or one `MoneyTransaction` row) **and no `OnboardingStatus` row** — i.e. the pre-006 DB state.
2. Launch the app.
3. **Expect**: onboarding is never shown; the app opens directly to the main entry point on this very first post-upgrade launch, and `OnboardingStatus.isComplete` is now `true` (auto-written by `ResolveOnboardingStatus`, research.md Decision 2 / contracts). Verify with both a seeded `Person`-only case and a seeded `MoneyTransaction`-only case (including one where the only existing person is archived, and one where the only existing transaction is soft-deleted) — all four must resolve to "already onboarded."

### Edge Case — App killed mid-onboarding

1. Fresh install, launch, advance to screen 3 of 5, then force-kill the app (not just background it) before tapping Skip or the final CTA.
2. Relaunch.
3. **Expect**: onboarding shows again starting from screen 1 (not resumed at screen 3) — per data-model.md, no row was ever written for an incomplete flow.

### Edge Case — Language/theme switch mid-onboarding

1. Fresh install, launch, advance to screen 2 or 3.
2. Switch the app language (Arabic ↔ English) via whatever mechanism the settings feature exposes reachable from context, or trigger the same `SettingsCubit.changeLanguage` call directly in a widget test.
3. **Expect**: still on the same screen (index unchanged), now rendered in the new language/direction (RTL mirroring correct per FR-011), progress indicator still shows the same step.
4. Repeat for a Light ↔ Dark theme switch (feature 003's mechanism): **Expect** same screen/progress preserved, correct Light/Dark rendering (FR-012).

### Accessibility / reduced motion

1. Enable the OS-level "Reduce Motion" (iOS) or "Remove animations" (Android) accessibility setting.
2. Launch onboarding, step through screens.
3. **Expect**: transitions are instant (no animated slide/fade), Next/Back/Skip remain immediately tappable at every step (FR-013 — animations must never block interaction), and nothing else in the flow is broken.
4. Also verify with a large system text-size setting: **Expect** all onboarding text/controls remain fully visible, wrapping rather than being cut off (Edge Cases, FR-014).

## Definition of Done checklist (constitution)

- [ ] Architecture correct (Domain/Data/Presentation layering per `plan.md` Project Structure)
- [ ] UI implemented for all 5 screens + progress indicator + Skip + final CTA
- [ ] Loading/error/empty states: N/A for static content; startup gate fails open per research.md Decision 7 (no infinite spinner — `OnboardingCubit.initialize()` always resolves to a definite status)
- [ ] Localization (ARB keys) and RTL both verified
- [ ] `flutter analyze` / `flutter test` / `flutter format` pass
- [ ] No sensitive data logged (N/A — no sensitive data in this feature)
- [ ] `integration_test/onboarding_flow_test.dart` covers all 4 User Stories + FR-010a + the two Edge Cases above
