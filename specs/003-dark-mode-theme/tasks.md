---

description: "Task list for Dark Mode / Theme Switching"
---

# Tasks: Dark Mode / Theme Switching

**Input**: Design documents from `/Users/abdallahrehab/projects/Daftary/specs/003-dark-mode-theme/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: This repo's established convention (`002-localization-language-switch`'s `test/features/settings/**` and `test/widget/*` files, plus this feature's own plan.md Project Structure, which names every new/extended test file explicitly) is to write unit, BLoC, widget, and integration tests per feature. Test tasks are therefore included below, not omitted.

**Organization**: Tasks are grouped by user story (spec.md priorities P1, P1, P2) to enable independent implementation and testing of each story. Because this feature deliberately extends one existing, tightly-coupled `SettingsCubit`/`SettingsState`/`main.dart` (per plan.md, reusing `002`'s architecture rather than introducing a parallel one), the shared plumbing every story needs to even compile (DB column, repository methods, use cases, `SettingsState` fields, the `SettingsCubit` method, the token system, and the `MaterialApp.router` wiring) lives in Phase 2 (Foundational); each user-story phase then adds that story's own story-specific tests and story-specific UI/audit work on top of it.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Single Flutter app (Option 1, per plan.md Structure Decision): `lib/`, `test/`, `integration_test/` at repository root. This feature adds no new top-level `lib/features/` folder — it extends `lib/features/settings/` and `lib/core/design_system/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Localized strings every user-story phase's UI work depends on.

- [ ] T001 [P] Add theme ARB keys to `lib/core/l10n/app_en.arb`: `themeSectionTitle` ("Theme"), `themeLight` ("Light"), `themeDark` ("Dark"), `themeSystemDefault` ("System Default"), `themeSaveFailed` ("Couldn't save your theme choice. It's still active for this session — we'll keep trying."), mirroring the existing `languageSectionTitle`/`languageEnglish`/`languageArabic`/`settingsSaveFailed` keys
- [ ] T002 [P] Add the matching Arabic translations for the same five keys to `lib/core/l10n/app_ar.arb`
- [ ] T003 Regenerate `lib/core/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_ar.dart` via `flutter gen-l10n` (depends on T001, T002)

**Checkpoint**: Localized theme strings available to any UI work below.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The shared persistence, domain, state, token, and app-wiring layer every user story needs to exist before it can be implemented or tested at all (per spec Assumptions: reuse `002`'s single `SettingsCubit`/`SettingsState`/`AppSettings` row and retry-once-then-notify policy, not a parallel mechanism).

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### Domain entity

- [ ] T004 [P] Create `enum AppThemeMode { light('light'), dark('dark'), system('system'); const AppThemeMode(this.value); final String value; }` (Flutter-free, no `package:flutter` import — constitution Principle I) in `lib/features/settings/domain/entities/app_theme_mode.dart`, mirroring `AppLanguage`'s `code` pattern (data-model.md Entity 1)

### Persistence (schema, DAO, repository)

- [ ] T005 In `lib/core/database/app_database.dart`, add `TextColumn get themeMode => text().nullable()();` to the `AppSettings` table, bump `schemaVersion` from `2` to `3`, and extend `MigrationStrategy.onUpgrade` with `if (from < 3) { await m.addColumn(appSettings, appSettings.themeMode); }` (data-model.md: "themeMode is NULL for: (a) a brand-new install with no AppSettings row at all, and (b) a row that predates this feature")
- [ ] T006 Regenerate `lib/core/database/app_database.g.dart` via `dart run build_runner build --delete-conflicting-outputs` (depends on T005)
- [ ] T007 Rewrite `SettingsDao.upsertPreference` in `lib/features/settings/data/datasources/settings_dao.dart` from `upsertPreference(String languageCode, int updatedAt)` to `Future<void> upsertPreference({String? languageCode, String? themeMode, required int updatedAt})`: read the existing row via `getPreference()` first, then upsert with `languageCode: languageCode ?? existing?.languageCode ?? AppLanguage.english.code` and `themeMode: Value(themeMode ?? existing?.themeMode)`, so a theme-only write never clobbers `languageCode` and vice versa (research.md Decision 3) (depends on T006)
- [ ] T008 Update the call site in `SettingsRepositoryImpl.setLanguagePreference` (`lib/features/settings/data/repositories/settings_repository_impl.dart`) from the old positional `upsertPreference(language.code, ...)` call to the new named-parameter form `upsertPreference(languageCode: language.code, updatedAt: ...)` (depends on T007)
- [ ] T009 Add `Future<Either<Failure, AppThemeMode?>> getThemeModePreference();` and `Future<Either<Failure, Unit>> setThemeModePreference(AppThemeMode mode);` to the abstract `SettingsRepository` in `lib/features/settings/domain/repositories/settings_repository.dart` (contracts/settings_repository.md) (depends on T004)
- [ ] T010 Implement both new methods on `SettingsRepositoryImpl` in `lib/features/settings/data/repositories/settings_repository_impl.dart`: `getThemeModePreference()` returns `Right(null)` when there is no row or `row.themeMode` is `NULL`, otherwise parses the stored string against `AppThemeMode.values` via a private `_parseThemeMode` (an unrecognized string returns `null`, never throws — mirrors `_parse` for `AppLanguage`, data-model.md Validation rules); `setThemeModePreference(mode)` calls `_dao.upsertPreference(themeMode: mode.value, updatedAt: DateTime.now().millisecondsSinceEpoch)`; both wrap DB errors as `Left(CacheFailure(...))` (depends on T007, T009)
- [ ] T011 [P] Create `GetThemeModePreference` use case in `lib/features/settings/domain/usecases/get_theme_mode_preference.dart`: `@injectable` class whose `call()` returns `_repository.getThemeModePreference()`, mirroring `GetLanguagePreference` (contracts/settings_repository.md) (depends on T009)
- [ ] T012 [P] Create `ChangeThemeMode` use case in `lib/features/settings/domain/usecases/change_theme_mode.dart`: `@injectable` class whose `call(AppThemeMode mode)` calls `setThemeModePreference(mode)`, and on failure retries exactly once (no `Timer`/`Future.delayed`), returning whether it ultimately succeeded — mirrors `ChangeLanguage`'s retry-once-then-report policy (contracts/settings_repository.md, research.md Decision 9) (depends on T009)

### Theme tokens

- [ ] T013 [P] In `lib/core/design_system/tokens.dart`, replace `ThemeData buildAppTheme()` with `ThemeData buildLightTheme()` and `ThemeData buildDarkTheme()`, each built from `ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light|dark, error: AppColors.error)` plus component themes (`InputDecorationTheme`, `CardThemeData`, `DialogThemeData`, `BottomSheetThemeData`, `NavigationBarThemeData`) derived from that scheme, covering FR-006's inputs/cards/dialogs/bottom-sheets/navigation roles (data-model.md Entity 2 Part A, contracts/theme_tokens.md)
- [ ] T014 In `lib/core/design_system/tokens.dart`, add `class AppFinanceColors extends ThemeExtension<AppFinanceColors>` with fields `positive`/`positiveSurface`, `negative`/`negativeSurface`, `neutral`/`neutralSurface`, `success`/`successSurface`, `warning`/`warningSurface`, `chartPositive`/`chartNegative`/`chartNeutral` plus `copyWith`/`lerp` overrides; define `static const light = AppFinanceColors(positive: #1F8A56, positiveSurface: #E4F5EC, negative: #C24B3F, negativeSurface: #FBEAE7, neutral: #6B6B6B, neutralSurface: #EDEDEA, success: #1F8A56 (aliases positive), successSurface: #E4F5EC, warning: #B3730C, warningSurface: #FCEFDB, chartPositive/chartNegative/chartNeutral aliasing positive/negative/neutral)` and `static const dark = AppFinanceColors(positive: #4ADE93, positiveSurface: #1C3B2C, negative: #FF6B57, negativeSurface: #40201C, neutral: #B0B0AE, neutralSurface: #2A2A28, success: #4ADE93, successSurface: #1C3B2C, warning: #F2B84B, warningSurface: #3B2E13, chart* aliasing positive/negative/neutral)` exactly per data-model.md Entity 2 Part B's table; register `ThemeData(extensions: [AppFinanceColors.light])` / `[AppFinanceColors.dark])` in `buildLightTheme()`/`buildDarkTheme()` (depends on T013)
- [ ] T015 In `lib/core/design_system/tokens.dart`, add `extension AppThemeContext on BuildContext { AppFinanceColors get financeColors => Theme.of(this).extension<AppFinanceColors>()!; }` so call sites never call `Theme.of(context).extension<...>()` directly (contracts/theme_tokens.md) (depends on T014)
- [ ] T016 In `lib/core/design_system/tokens.dart`, drop the hardcoded `color: AppColors.onSurfaceMuted` field from `AppTypography.bodyMuted` (keep only its `fontSize: 13`/`height: 1.4`), since a `static const TextStyle` color cannot vary by theme (research.md Decision 8) (depends on T013)

### State and Cubit

- [ ] T017 [P] Extend `SettingsState` in `lib/features/settings/presentation/cubit/settings_state.dart` with `AppThemeMode themeMode = AppThemeMode.system` and `bool isThemeModePersistFailing = false`, updating the constructor defaults, `copyWith()`, and `props` accordingly (data-model.md `SettingsState` shape table) (depends on T004)
- [ ] T018 Extend `SettingsCubit` in `lib/features/settings/presentation/cubit/settings_cubit.dart`: inject `GetThemeModePreference`/`ChangeThemeMode`; `initialize()` also resolves `state.themeMode` (the persisted value if present, else `AppThemeMode.system` per FR-011 with no device I/O — research.md Decision 5); add `Future<void> changeThemeMode(AppThemeMode mode)` that emits `state.copyWith(themeMode: mode, isThemeModePersistFailing: false)` immediately (FR-004: live, no restart), then persists via `ChangeThemeMode`, setting `isThemeModePersistFailing: true` only if the retried write also fails (contracts/settings_repository.md) (depends on T011, T012, T017)
- [ ] T019 Regenerate `lib/core/di/injection.config.dart` via `dart run build_runner build --delete-conflicting-outputs` to register `GetThemeModePreference`/`ChangeThemeMode` (depends on T011, T012, T018)

### App wiring

- [ ] T020 In `lib/main.dart`'s `MaterialApp.router`, replace `theme: buildAppTheme()` with `theme: buildLightTheme()`, add `darkTheme: buildDarkTheme()`, and add `themeMode: switch (state.themeMode) { AppThemeMode.light => ThemeMode.light, AppThemeMode.dark => ThemeMode.dark, AppThemeMode.system => ThemeMode.system }` (contracts/theme_tokens.md "Caller contract") (depends on T013, T018)

**Checkpoint**: Foundation ready — `SettingsCubit` compiles and resolves/persists a theme mode, `buildLightTheme()`/`buildDarkTheme()`/`context.financeColors` exist, and `main.dart` re-themes on state change. User story implementation can now begin.

---

## Phase 3: User Story 1 - Switch Between Light and Dark Theme (Priority: P1) 🎯 MVP

**Goal**: A user picks Light or Dark in Settings and every currently visible screen updates live, with financial values remaining legible and no color-alone meaning.

**Independent Test**: From Settings, select "Dark," verify every screen the user can currently reach (people list, person details, add transaction, overview, settings) renders in dark colors with no unstyled/white flashes; select "Light" again and verify the app returns to the original appearance with no regression.

### Tests for User Story 1 ⚠️

> Write these tests first; they should fail until the Implementation tasks below land.

- [ ] T021 [P] [US1] Add `test/widget/app_card_test.dart` rendering `AppCard` under both `buildLightTheme()` and `buildDarkTheme()`, asserting its fill/border resolve from `Theme.of(context).colorScheme` (no leftover `AppColors` reference)
- [ ] T022 [P] [US1] Add `test/widget/balance_status_badge_test.dart` rendering `BalanceStatusBadge` under both themes for all three `RelationshipStatus` values, asserting the icon (`arrow_downward`/`arrow_upward`/`check_circle_outline`) and label are always present alongside the color (FR-009)
- [ ] T023 [P] [US1] Add `test/widget/transaction_list_tile_test.dart` rendering `TransactionListTile` under both themes, asserting the direction icon is always present alongside the amount color regardless of theme (FR-009)
- [ ] T024 [P] [US1] Extend `test/widget/settings_page_test.dart` asserting selecting "Light"/"Dark" in the new Theme section calls `SettingsCubit.changeThemeMode` with the expected `AppThemeMode`

### Implementation for User Story 1

- [ ] T025 [P] [US1] In `lib/core/design_system/app_card.dart`, replace `AppColors.surface`/`AppColors.divider` with `Theme.of(context).colorScheme.surface`/`Theme.of(context).colorScheme.outlineVariant`
- [ ] T026 [P] [US1] In `lib/core/design_system/app_text_field.dart`, replace the `fillColor: AppColors.surface` and the two `BorderSide(color: AppColors.divider)` uses with `Theme.of(context).colorScheme` equivalents, preferring `InputDecorationTheme` values where possible (contracts/theme_tokens.md)
- [ ] T027 [P] [US1] In `lib/core/design_system/app_empty_view.dart`, replace `Icon(icon, size: 48, color: AppColors.onSurfaceMuted)` with `Theme.of(context).colorScheme.onSurfaceVariant`, and update its `AppTypography.bodyMuted` usage to add `.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)` (research.md Decision 8, depends on T016)
- [ ] T028 [P] [US1] In `lib/features/transactions/presentation/pages/overview_page.dart`, replace `AppColors.positive`/`AppColors.negative` with `context.financeColors.positive`/`context.financeColors.negative`
- [ ] T029 [P] [US1] In `lib/features/transactions/presentation/widgets/balance_status_badge.dart`, replace `AppColors.positiveSurface`/`AppColors.positive`/`AppColors.negativeSurface`/`AppColors.negative`/`AppColors.neutralSurface`/`AppColors.neutral` across all three `RelationshipStatus` switch branches with the matching `context.financeColors.*` roles
- [ ] T030 [P] [US1] In `lib/features/transactions/presentation/widgets/transaction_list_tile.dart`, replace `AppColors.negative`/`AppColors.positive`/`AppColors.neutralSurface` with `context.financeColors.*`, and update its `AppTypography.bodyMuted` usage to add `.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)` (research.md Decision 8, depends on T016)
- [ ] T031 [P] [US1] In `lib/features/transactions/presentation/widgets/overview_summary_card.dart`, replace `AppColors.positive`/`AppColors.negative` with `context.financeColors.positive`/`context.financeColors.negative`, replace the divider `Container(width: 1, height: 40, color: AppColors.divider)` with `Theme.of(context).colorScheme.outlineVariant`, and update its `AppTypography.bodyMuted` usage to add `.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)` (research.md Decision 8, depends on T016)
- [ ] T032 [P] [US1] In `lib/features/people/presentation/widgets/relationship_tag_chip.dart`, replace `AppColors.neutralSurface` with `context.financeColors.neutralSurface`
- [ ] T033 [P] [US1] In `lib/features/transactions/presentation/widgets/duplicate_warning_sheet.dart`, update its `AppTypography.bodyMuted` usage to add `.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)` (research.md Decision 8, depends on T016)
- [ ] T034 [P] [US1] In `lib/features/people/presentation/pages/person_form_page.dart`, update its `AppTypography.bodyMuted` usage to add `.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)` (research.md Decision 8, depends on T016)
- [ ] T035 [P] [US1] In `lib/features/settings/presentation/pages/settings_page.dart`, add a "Theme" section below the existing Language section: a `label`-styled title (`l10n.themeSectionTitle`) followed by a `RadioGroup<AppThemeMode>` with `RadioListTile`s for `l10n.themeLight`/`l10n.themeDark` (System Default added in US3), `groupValue: state.themeMode`, `onChanged` calling `context.read<SettingsCubit>().changeThemeMode(mode)` — mirroring the existing Language `RadioGroup` structure; extend the page's `BlocConsumer.listenWhen`/`listener` to also show `l10n.themeSaveFailed` when `isThemeModePersistFailing` newly becomes `true`
- [ ] T036 [US1] Create `integration_test/theme_switch_flow_test.dart` with the User Story 1 scenario: launch, select Dark from Settings, verify the people list/person detail/transaction form/overview/settings screens all render Dark with no restart, select Light again, verify no regression (quickstart.md "Validate User Story 1", SC-001) (depends on T025-T035)

**Checkpoint**: User Story 1 is fully functional and independently testable — live Light/Dark switching works across every reachable screen with no color-alone meaning.

---

## Phase 4: User Story 2 - Theme Preference Persists Across Restarts (Priority: P1)

**Goal**: The user's Light/Dark/System Default choice survives a full app close and reopen.

**Independent Test**: Set theme to Dark, fully close the app, reopen it, and verify it launches directly in Dark theme (and equivalently for Light, and for System Default if supported).

### Tests for User Story 2 ⚠️

> These validate the persistence layer built in Phase 2 (Foundational); they are the concrete proof of SC-003.

- [ ] T037 [P] [US2] Add `test/core/database/app_database_migration_test.dart` asserting an upgrade from `schemaVersion` 2 leaves the new `themeMode` column `NULL` on existing rows, and a fresh install starts directly at `schemaVersion` 3 with the column present (data-model.md Validation rules)
- [ ] T038 [P] [US2] Add `test/features/settings/data/datasources/settings_dao_test.dart` asserting `upsertPreference`'s merge-then-upsert correctness: a theme-only write does not clobber an existing `languageCode`, and a language-only write does not clobber an existing `themeMode` (research.md Decision 3)
- [ ] T039 [P] [US2] Extend `test/features/settings/data/repositories/settings_repository_impl_test.dart` with `getThemeModePreference`/`setThemeModePreference` cases: no row → `Right(null)`, `NULL` `themeMode` column → `Right(null)`, a valid stored string → the parsed `AppThemeMode`, an unrecognized string → `Right(null)` (never thrown), a DB error → `Left(CacheFailure)`
- [ ] T040 [P] [US2] Add `test/features/settings/domain/usecases/get_theme_mode_preference_test.dart` (faked `SettingsRepository`) asserting the use case passes through the repository's result unchanged
- [ ] T041 [P] [US2] Add `test/features/settings/domain/usecases/change_theme_mode_test.dart` asserting the retry-once-then-report policy: succeeds on the first attempt → `true`; fails first, succeeds on retry → `true` (repository called twice); fails both attempts → `false` (repository called twice)
- [ ] T042 [P] [US2] Extend `test/features/settings/presentation/cubit/settings_cubit_test.dart` with an `initialize` group covering theme resolution (persisted `AppThemeMode.dark`/`.light` is restored exactly; `NULL`/no-row resolves to `AppThemeMode.system` per FR-011) and a `changeThemeMode` group covering `isThemeModePersistFailing` (stays `false` on success; becomes `true` only after the retried write also fails; does not become `true` when the retry succeeds), mirroring the existing `changeLanguage`/`initialize` test groups

### Implementation for User Story 2

- [ ] T043 [US2] Extend `integration_test/theme_switch_flow_test.dart` with the User Story 2 scenario: set theme to Dark, tear down and recreate the app/`SettingsCubit` against the same on-disk database (simulated restart), verify it launches directly in Dark with no flash of Light; repeat for Light (quickstart.md "Validate User Story 2", SC-003) (depends on T036, T037-T042)

**Checkpoint**: User Stories 1 AND 2 both work independently — switching is live and the choice survives a full restart.

---

## Phase 5: User Story 3 - Follow System Theme Automatically (Priority: P2)

**Goal**: A user can pick "System Default" so the app always matches the device's current Light/Dark setting, live, without a manual choice.

**Independent Test**: Select "System Default" in Settings, change the device's system theme (e.g. via OS quick settings), and return to the app to verify it follows the device setting; verify the choice persists as "System Default" (not a frozen Light/Dark snapshot) across restarts.

### Tests for User Story 3 ⚠️

- [ ] T044 [P] [US3] Extend `test/widget/settings_page_test.dart` asserting selecting "System Default" in the Theme section calls `SettingsCubit.changeThemeMode(AppThemeMode.system)`

### Implementation for User Story 3

- [ ] T045 [US3] In `lib/features/settings/presentation/pages/settings_page.dart`'s Theme `RadioGroup<AppThemeMode>` (added in T035), add a third `RadioListTile` for `l10n.themeSystemDefault` with `value: AppThemeMode.system` (depends on T035, T044)
- [ ] T046 [US3] Extend `integration_test/theme_switch_flow_test.dart` with the User Story 3 scenario: select "System Default," change the simulated platform brightness while the app is open, verify the app updates live with no restart (research.md Decision 6 — Flutter's own `themeMode: ThemeMode.system`); fully close/reopen with the device on a given system brightness and verify the app reflects that *current* system theme rather than a frozen snapshot (quickstart.md "Validate User Story 3") (depends on T043, T045)

**Checkpoint**: All three user stories are independently functional — Light/Dark/System Default all switch live and all persist correctly (System Default persists as "system," not a resolved snapshot).

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Sweep for regressions and verify the feature's Definition of Done across the whole app, not just the audited files.

- [ ] T047 [P] Sweep the entire `lib/` tree for any remaining hardcoded color reference — `grep -rn "AppColors\." lib` (expect zero hits outside `lib/core/design_system/tokens.dart`) and `grep -rn "Color(0x" lib` (expect zero hits outside `tokens.dart`) — fixing any newly-found site the same way as the Phase 3 audit (FR-007, Edge Cases: "a future screen or component added without using the shared theme tokens... must be treated as a defect")
- [ ] T048 [P] Manually re-verify the WCAG 2.1 AA contrast pairs in `data-model.md`'s contrast table (`onSurface`/`onSurfaceVariant` on `background`; `positive`/`negative` financial text on `background` and on their surfaces) against the final rendered Dark theme, confirming all pass 4.5:1 for normal/financial text and 3:1 for large text/UI components (FR-008, SC-004)
- [ ] T049 Run the full `quickstart.md` manual walkthrough end-to-end: User Stories 1-3, plus all four Edge Cases (mid-transition form/dialog state preserved across a theme switch per FR-012; first-install default is System Default per FR-011; loading/empty/error states legible in Dark per FR-010; `BalanceStatusBadge`/`TransactionListTile` never rely on color alone per FR-009)
- [ ] T050 Run `flutter analyze`, `flutter test`, and `flutter test integration_test/theme_switch_flow_test.dart`; fix any warnings or failures rather than suppressing them (constitution Code Quality Gates)
- [ ] T051 [P] Grep the repo for any remaining reference to the removed `buildAppTheme()` name (docs, comments, other tests) and update to `buildLightTheme()`/`buildDarkTheme()`
- [ ] T052 [P] Add `test/widget/theme_switch_preserves_form_state_test.dart`: pump `TransactionFormPage` (or another in-progress form) under `buildLightTheme()`, enter text into a field, switch the ambient `ThemeMode` to Dark via a `MaterialApp` rebuild (no navigation/dispose in between), and assert the entered text and widget state are still present after the switch — an automated regression guard for FR-012, supplementing the manual T049 walkthrough
- [ ] T053 [P] Add `test/core/design_system/contrast_ratio_test.dart`: a pure-Dart unit test computing the WCAG 2.1 contrast ratio (relative-luminance formula, no widget pump required) for each color pair listed in `data-model.md`'s contrast table (`onSurface`/`onSurfaceVariant` on `background`; `positive`/`negative` on `background` and on their surfaces, both themes) directly from the `AppFinanceColors.light`/`AppFinanceColors.dark`/`ColorScheme` token values, asserting each meets 4.5:1 (normal/financial text) or 3:1 (large text/UI components) — an automated regression guard for FR-008/SC-004, supplementing the manual T048 re-verification

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup (T003's ARB strings are consumed by Foundational-adjacent UI later, but Foundational's own tasks T004-T020 have no hard Setup dependency and may start in parallel with Phase 1) — BLOCKS all user stories.
- **User Stories (Phase 3-5)**: All depend on Foundational (Phase 2) completion.
  - User Story 1 (P1) can start immediately after Foundational.
  - User Story 2 (P1) can start immediately after Foundational (its tests exercise Foundational code directly) but its integration-test task (T043) extends the file User Story 1 creates (T036), so T043 follows T036.
  - User Story 3 (P2) extends both the Settings UI (T035, from US1) and the integration test (T043, from US2), so it follows both.
- **Polish (Phase 6)**: Depends on all three user stories being complete.

### User Story Dependencies

- **User Story 1 (P1)**: No dependency on US2/US3 beyond shared Foundational work — independently testable per its own Independent Test.
- **User Story 2 (P1)**: No dependency on US1's specific widgets, but its integration-test task (T043) is written as an extension of US1's integration-test file (T036) rather than a duplicate file.
- **User Story 3 (P2)**: Extends US1's Settings UI (adds the third radio option to the `RadioGroup` T035 created) and US2's integration test (T046 extends T043) — genuinely additive, does not modify US1/US2 behavior.

### Within Each User Story

- Tests are written before their corresponding implementation tasks (TDD) for User Story 1 and 3's new UI/widget behavior.
- User Story 2's tests validate already-built Foundational persistence code (that code must exist first — it is shared by every story via the Cubit constructor).
- Each story's own integration-test task comes last, after that story's other tasks.

### Parallel Opportunities

- T001, T002 (Setup) in parallel.
- T004, T011, T012, T013, T017 (Foundational, different files) in parallel once their own listed dependencies are satisfied.
- T021-T024 (US1 tests, four different files) in parallel.
- T025-T035 (US1 implementation, eleven different files, all independent of each other) in parallel once Foundational is done.
- T037-T042 (US2 tests, six different files) in parallel.
- Different user stories cannot usefully run in parallel by different people here, because US2/US3 both extend files US1 creates (`settings_page.dart`, `theme_switch_flow_test.dart`) — sequence US1 → US2 → US3 for those two files specifically, even though most other files are independent.

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Add test/widget/app_card_test.dart rendering AppCard under both themes"
Task: "Add test/widget/balance_status_badge_test.dart rendering under both themes, all 3 statuses"
Task: "Add test/widget/transaction_list_tile_test.dart rendering under both themes"
Task: "Extend test/widget/settings_page_test.dart for Light/Dark selection"

# Launch the 9-file (+2 bodyMuted-only) color audit together:
Task: "app_card.dart: AppColors.surface/divider -> colorScheme"
Task: "app_text_field.dart: AppColors.surface/divider -> colorScheme"
Task: "app_empty_view.dart: AppColors.onSurfaceMuted -> colorScheme.onSurfaceVariant"
Task: "overview_page.dart: AppColors.positive/negative -> financeColors"
Task: "balance_status_badge.dart: AppColors.* -> financeColors (3 statuses)"
Task: "transaction_list_tile.dart: AppColors.* -> financeColors"
Task: "overview_summary_card.dart: AppColors.* -> financeColors/colorScheme"
Task: "relationship_tag_chip.dart: AppColors.neutralSurface -> financeColors"
Task: "duplicate_warning_sheet.dart: bodyMuted call site color fix"
Task: "person_form_page.dart: bodyMuted call site color fix"
Task: "settings_page.dart: add Theme section (Light/Dark)"
```

## Parallel Example: User Story 2

```bash
Task: "test/core/database/app_database_migration_test.dart"
Task: "test/features/settings/data/datasources/settings_dao_test.dart"
Task: "Extend test/features/settings/data/repositories/settings_repository_impl_test.dart"
Task: "test/features/settings/domain/usecases/get_theme_mode_preference_test.dart"
Task: "test/features/settings/domain/usecases/change_theme_mode_test.dart"
Task: "Extend test/features/settings/presentation/cubit/settings_cubit_test.dart"
```

## Parallel Example: User Story 3

```bash
# Only one net-new file-independent task in this story; the other two are
# sequential extensions of files US1/US2 already created.
Task: "Extend test/widget/settings_page_test.dart for System Default selection"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories; this is most of the actual plumbing, per plan.md's tight coupling to the existing `SettingsCubit`).
3. Complete Phase 3: User Story 1.
4. **STOP and VALIDATE**: run `integration_test/theme_switch_flow_test.dart`'s User Story 1 scenario (T036) and the quickstart.md User Story 1 walkthrough independently.
5. Ship: live Light/Dark switching across the whole app is already a complete, demoable dark-mode feature at this point (persistence and System Default are additive on top).

### Incremental Delivery

1. Setup + Foundational → foundation ready (DB column, repository, use cases, tokens, cubit, app wiring all exist).
2. Add User Story 1 → validate independently → this is the MVP.
3. Add User Story 2 → validate independently (restart persistence) → theme choice now survives a real-world app close.
4. Add User Story 3 → validate independently (system-follow) → full spec scope delivered.
5. Polish → sweep for any missed hardcoded color, re-confirm contrast, run the full quickstart and quality gates.

### Parallel Team Strategy

With multiple developers, after Foundational is done:
- Developer A: User Story 1's widget-level color audit (T025-T034, all independent files).
- Developer B: User Story 1's Settings UI + tests (T021, T024, T035) in parallel with A, then hands off T036 once both land.
- Developer C: User Story 2's persistence tests (T037-T042) in parallel with A/B, since they only depend on Foundational, not on US1's UI work.
- User Story 3 is small enough (3 tasks) to pick up by whoever finishes first, once US1's T035 and US2's T043 have landed.

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks.
- [Story] label maps task to specific user story for traceability.
- The Phase 3 color-token audit's file list (11 files, 8 via direct `AppColors.*` reference + 2 via `AppTypography.bodyMuted`-only, `app_empty_view.dart`/`transaction_list_tile.dart`/`overview_summary_card.dart` needing both) was verified exhaustive via `grep -rn "AppColors\." lib` and `grep -rn "AppTypography.bodyMuted" lib` — no other hardcoded-color call sites exist in `lib/` outside `tokens.dart` itself.
- Commit after each task or logical group; stop at any checkpoint to validate a story independently.
- Avoid: vague tasks, same-file conflicts marked `[P]`, cross-story dependencies that would break a story's independent testability beyond the two explicitly-noted sequential file extensions (`settings_page.dart`, `theme_switch_flow_test.dart`).
