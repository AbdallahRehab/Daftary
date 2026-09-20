---

description: "Task list for Arabic/English Localization + Language Switch"
---

# Tasks: Arabic/English Localization + Language Switch

**Input**: Design documents from `/specs/002-localization-language-switch/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/settings_repository.md, quickstart.md

**Tests**: Test tasks are included — the plan's Testing section and constitution Principle XVI require unit/widget/integration coverage for this feature; they are not optional here.

**Organization**: Tasks are grouped by user story (spec.md priorities P1/P2/P3) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths are given for every task

## Path Conventions

Single Flutter app (feature-first clean architecture), matching feature 001:

- `lib/core/` — cross-feature infrastructure (database, DI, l10n, money, date, design system, routing)
- `lib/features/settings/{data,domain,presentation}/` — this feature's new module
- `test/` mirrors `lib/`; `integration_test/` holds end-to-end flows

---

## Phase 1: Setup

**Purpose**: Create the new feature's directory skeleton. No new package dependencies are needed (plan.md Technical Context confirms `flutter_bloc`, `go_router`, `drift`, `get_it`/`injectable`, `intl` are all already present).

- [ ] T001 Create the `settings` feature skeleton directories: `lib/features/settings/data/datasources/`, `lib/features/settings/data/repositories/`, `lib/features/settings/domain/entities/`, `lib/features/settings/domain/repositories/`, `lib/features/settings/domain/usecases/`, `lib/features/settings/presentation/cubit/`, `lib/features/settings/presentation/pages/`
- [ ] T002 [P] Create the mirrored test skeleton directories: `test/features/settings/data/repositories/`, `test/features/settings/domain/usecases/`, `test/features/settings/presentation/cubit/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The persistence layer and platform abstractions that both User Story 1 (live switch, which persists on every change per research.md Decision 2/3) and User Story 2 (restart persistence) depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T003 In `lib/core/database/app_database.dart`, add a new `AppSettings` Drift table per data-model.md: `id` (`TextColumn`, primary key, the app always writes the fixed constant `'singleton'` — "there is never more than one row"), `languageCode` (`TextColumn`, only `'en'` or `'ar'` is ever written), `updatedAt` (`IntColumn`, epoch millis, "set on every write"). Add `AppSettings` to the `@DriftDatabase(tables: [...])` list, bump `schemaVersion` from `1` to `2`, and add the app's first `MigrationStrategy` override (`onCreate: (m) => m.createAll()`, `onUpgrade: (m, from, to) async { if (from < 2) await m.createTable(appSettings); }`) per data-model.md's Migration section
- [ ] T004 [P] Create the `AppLanguage` domain enum (`english`, `arabic`, Flutter-free per Principle I) with a `code` getter (`'en'`/`'ar'`) in `lib/features/settings/domain/entities/app_language.dart`
- [ ] T005 [P] Create `DeviceLocaleProvider` (abstract, one method `Locale currentLocale()`) and its `@LazySingleton(as: DeviceLocaleProvider)` implementation backed by `WidgetsBinding.instance.platformDispatcher.locale`, in `lib/core/device/device_locale_provider.dart`, per contracts/settings_repository.md
- [ ] T006 Create `SettingsDao` (`@injectable`, constructor-injected `AppDatabase`, mirroring `lib/features/people/data/datasources/people_dao.dart`'s shape) with `getPreference()` (returns the single row or `null` if absent) and `upsertPreference(String languageCode, int updatedAt)` (single-row upsert keyed on the fixed `'singleton'` id) in `lib/features/settings/data/datasources/settings_dao.dart` (depends on T003)
- [ ] T007 [P] Create the `SettingsRepository` abstract interface exactly as specified in contracts/settings_repository.md — `Future<Either<Failure, AppLanguage?>> getLanguagePreference()` and `Future<Either<Failure, Unit>> setLanguagePreference(AppLanguage language)` — in `lib/features/settings/domain/repositories/settings_repository.dart` (depends on T004)
- [ ] T008 Create `SettingsRepositoryImpl` (`@LazySingleton(as: SettingsRepository)`, constructor-injected `SettingsDao`) in `lib/features/settings/data/repositories/settings_repository_impl.dart`: maps `SettingsDao` rows to/from `AppLanguage`, wraps DB I/O errors as `CacheFailure` (reuse the existing type in `lib/core/error/failure.dart` — do not create a new failure type), and treats an unrecognized `languageCode` value as "no valid preference" (returns `null`, per data-model.md's Validation rules) rather than throwing (depends on T006, T007)
- [ ] T009 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `lib/core/database/app_database.g.dart` (new `AppSettings` table) and `lib/core/di/injection.config.dart` (new `DeviceLocaleProvider`, `SettingsDao`, `SettingsRepositoryImpl` registrations) (depends on T003, T005, T006, T008)

**Checkpoint**: Persistence layer and device-locale abstraction exist and compile — user story implementation can now begin.

---

## Phase 3: User Story 1 - Switch the app's language from Settings (Priority: P1) 🎯 MVP

**Goal**: A user can open a new Settings tab (reachable app-wide via a new bottom navigation bar) and switch between Arabic and English, with the entire visible UI — including the bottom nav itself — re-rendering in the new language and direction immediately, with no app restart.

**Independent Test**: From any screen, tap the Settings tab, select the other language, and confirm the visible screen (Settings itself, then the previously active tab) re-renders fully in the new language/direction without a restart (spec Acceptance Scenarios 1-3).

### Implementation for User Story 1

- [ ] T010 [US1] Create `SettingsState` (`Equatable`, fields `AppLanguage language` and `bool isPersistFailing`, updated via `copyWith()`, mirroring `lib/features/people/presentation/cubit/person_list_state.dart`'s shape) in `lib/features/settings/presentation/cubit/settings_state.dart`
- [ ] T011 [US1] Create `SettingsCubit` (`flutter_bloc` `Cubit<SettingsState>`, `@lazySingleton` since it is root-scoped rather than per-screen — note this means a second `build_runner` pass is needed after this task) with an initial hardcoded `AppLanguage.english` state and a `changeLanguage(AppLanguage language)` method that emits the new state immediately and calls `SettingsRepository.setLanguagePreference` (fire-and-forget at this stage — the FR-008 retry/failure-flagging policy is added in User Story 2, T023) in `lib/features/settings/presentation/cubit/settings_cubit.dart` (depends on T007/T008, T010)
- [ ] T012 [US1] Restructure `lib/core/routing/app_router.dart` from its current flat list of 10 `GoRoute`s into a `StatefulShellRoute.indexedStack` with 3 branches, per research.md Decision 1 — no route paths removed: **People branch** (`/`, `/people`, `/people/new`, `/people/archived`, `/people/:id/edit`, `/people/:id`, `/people/:id/repayment`, `/transactions/new`, `/transactions/:id/edit`), **Overview branch** (`/overview`), **Settings branch** (new `/settings`, added in T015)
- [ ] T013 [US1] Create `MainShell` (a `StatefulNavigationShell`-driven `Scaffold` using Material's `NavigationBar`/`NavigationDestination` for the People/Overview/Settings tabs — per research.md Decision 6, no custom mirroring logic needed since `NavigationBar` already respects ambient `Directionality`) in `lib/core/routing/main_shell.dart` (depends on T012)
- [ ] T014 [US1] Create `SettingsPage` (a language picker — e.g. two selectable rows/radio options for Arabic and English — calling `context.read<SettingsCubit>().changeLanguage(...)` on selection; structure the page so future settings entries can be appended below the language switch without rework, per spec Assumptions) in `lib/features/settings/presentation/pages/settings_page.dart` (depends on T011)
- [ ] T015 [US1] Wire the `/settings` route to `SettingsPage` inside `MainShell`'s Settings branch in `lib/core/routing/app_router.dart` (depends on T012, T013, T014)
- [ ] T016 [US1] In `lib/main.dart`, wrap `DaftaryApp`'s subtree in `BlocProvider<SettingsCubit>` (root-scoped, above `MaterialApp.router`) and bind `MaterialApp.router`'s `locale:` parameter to `BlocBuilder<SettingsCubit, SettingsState>`'s `state.language` mapped to `Locale('ar')`/`Locale('en')`, per research.md Decision 2 (depends on T011)
- [ ] T017 [US1] Add the ARB keys needed by `SettingsPage`/`MainShell` (Settings tab label, People tab label, Overview tab label, Settings page title, "English"/"Arabic" option labels — check `lib/core/l10n/app_en.arb`/`app_ar.arb` first for any of these that already exist under different names before adding new ones) to `lib/core/l10n/app_en.arb` and `lib/core/l10n/app_ar.arb`, then run `flutter gen-l10n` to regenerate `lib/core/l10n/app_localizations_en.dart`/`app_localizations_ar.dart` (depends on T013, T014)
- [ ] T018 [P] [US1] Widget test asserting `MainShell` renders its 3 destinations in People/Overview/Settings order (with correct icons) under `Directionality.ltr`, and in mirrored order under `Directionality.rtl`, in `test/widget/main_shell_test.dart`
- [ ] T019 [P] [US1] Widget test asserting selecting a language on `SettingsPage` invokes `SettingsCubit.changeLanguage` with the expected `AppLanguage` (using a mocked/faked Cubit) in `test/widget/settings_page_test.dart`
- [ ] T020 [P] [US1] `bloc_test` unit test asserting `SettingsCubit.changeLanguage` synchronously emits a `SettingsState` with the new `language` value, given a faked `SettingsRepository`, in `test/features/settings/presentation/cubit/settings_cubit_test.dart`

**Checkpoint**: User Story 1 is fully functional and independently testable (quickstart.md scenario 1) — live language switching works app-wide via the new Settings tab, including bottom-nav mirroring.

---

## Phase 4: User Story 2 - Language choice persists across app restarts (Priority: P2)

**Goal**: The app remembers the user's language choice across restarts and resolves a sensible first-launch default when no choice has ever been made.

**Independent Test**: Set the language to Arabic, fully close and reopen the app, and confirm it launches directly in Arabic/RTL (spec Acceptance Scenarios 1-3).

### Implementation for User Story 2

- [ ] T021 [P] [US2] Create the `GetLanguagePreference` use case (calls `SettingsRepository.getLanguagePreference()`, a thin domain action per plan.md's Constitution Check — not a bare passthrough since callers combine its `null` result with device-locale fallback) in `lib/features/settings/domain/usecases/get_language_preference.dart`
- [ ] T022 [P] [US2] Create the `ChangeLanguage` use case owning the FR-008 policy from research.md Decision 7: calls `SettingsRepository.setLanguagePreference`; on failure, retries exactly once, synchronously (no `Timer`/`Future.delayed`); returns whether persistence ultimately succeeded so the caller can decide whether to surface a notice, in `lib/features/settings/domain/usecases/change_language.dart`
- [ ] T023 [US2] Update `SettingsCubit` (`lib/features/settings/presentation/cubit/settings_cubit.dart`): resolve the **initial** state by calling `GetLanguagePreference`, and when it returns `null` (no persisted row), resolve the first-launch default via `DeviceLocaleProvider.currentLocale()` per FR-009 ("prefer the device's system language when it is Arabic or English, otherwise English"); change `changeLanguage()` to call `ChangeLanguage` instead of the repository directly, setting `SettingsState.isPersistFailing = true` only when `ChangeLanguage` reports the retried write also failed (depends on T021, T022, T011)
- [ ] T024 [US2] Surface `SettingsState.isPersistFailing` as a small non-blocking banner/`SnackBar` on `SettingsPage` (`lib/features/settings/presentation/pages/settings_page.dart`) — the user must never be blocked from using the app in their chosen language because of this (depends on T023, T014)
- [ ] T025 [US2] Ensure the app's very first frame reflects the persisted/first-launch-default language rather than the `T011` hardcoded default — resolve `SettingsCubit`'s initial state (T023) before `runApp`/before `MaterialApp.router` first builds, in `lib/main.dart` (depends on T023, T016)
- [ ] T026 [P] [US2] Unit test `SettingsRepositoryImpl`/`SettingsDao` against Drift's in-memory `NativeDatabase.memory()`: persist-then-read-back a language preference, and confirm `getLanguagePreference()` returns `null` (via `Right(null)`) when no row exists yet, in `test/features/settings/data/repositories/settings_repository_impl_test.dart`
- [ ] T027 [P] [US2] Unit tests for `GetLanguagePreference` (faked `SettingsRepository`) and `ChangeLanguage` (including its retry-once-then-report-failure path) in `test/features/settings/domain/usecases/get_language_preference_test.dart` and `test/features/settings/domain/usecases/change_language_test.dart`
- [ ] T028 [US2] Extend the `bloc_test` suite in `test/features/settings/presentation/cubit/settings_cubit_test.dart` to cover: first-launch default resolution from a faked `DeviceLocaleProvider` (Arabic device locale → `AppLanguage.arabic`; a non-Arabic/English device locale, e.g. French → `AppLanguage.english`), and `isPersistFailing` becoming `true` only after `ChangeLanguage` reports the retried write failed (depends on T023)
- [ ] T029 [US2] `integration_test` covering the restart-persistence flow: set the language to Arabic, tear down and rebuild the widget tree against the same underlying `AppDatabase` (simulating a restart), confirm the app opens in Arabic/RTL; repeat for English, in `integration_test/language_switch_flow_test.dart`

**Checkpoint**: User Stories 1 AND 2 both work independently (quickstart.md scenarios 1-2) — live switching and restart persistence are both correct.

---

## Phase 5: User Story 3 - Every part of the app is correct in both languages and directions (Priority: P3)

**Goal**: Every existing screen is fully translated, correctly mirrored under RTL, and formats dates/currency correctly (Western digits always) in both languages, including mixed Arabic/English content.

**Independent Test**: With Arabic active, visit every major screen/surface and confirm correct mirroring, full translation, correct locale formatting, and no leftover English strings; repeat for English/LTR (spec Acceptance Scenarios 1-4).

### Implementation for User Story 3

- [ ] T030 [P] [US3] Create `AppDateFormatter` (mirrors `lib/core/money/egp_formatter.dart`'s shape: locale-in constructor, per-locale cached `intl.DateFormat`, Western digits forced under Arabic) in `lib/core/date/app_date_formatter.dart`, per research.md Decision 8
- [ ] T031 [P] [US3] Create a single shared helper that resolves the effective `intl` locale string for a given app locale — appending the `_u_nu_latn` Unicode extension when the language code is `'ar'` so digits stay Western (0-9) per FR-011/research.md Decision 5 — in `lib/core/l10n/numeral_locale.dart`, so this rule lives in exactly one place as the plan requires
- [ ] T032 [US3] Update `EgpFormatter` (`lib/core/money/egp_formatter.dart`) to resolve its `NumberFormat` through the T031 helper instead of the raw locale string it receives today (depends on T031)
- [ ] T033 [US3] Update the 4 `EgpFormatter()` call sites that currently default to the implicit `'en'` locale to instead pass the active app locale (e.g. `Localizations.localeOf(context).languageCode`): `lib/features/transactions/presentation/pages/person_detail_page.dart:102`, `lib/features/transactions/presentation/pages/overview_page.dart:125`, `lib/features/transactions/presentation/widgets/overview_summary_card.dart:23`, `lib/features/transactions/presentation/widgets/transaction_list_tile.dart:30` (depends on T032)
- [ ] T034 [US3] Replace the 3 hand-rolled `'${date.year.toString()...}-${date.month...}-${date.day...}'` strings with `AppDateFormatter` calls passing the active app locale: `lib/features/transactions/presentation/pages/transaction_form_page.dart:227`, `lib/features/transactions/presentation/pages/repayment_form_page.dart:121`, `lib/features/transactions/presentation/widgets/transaction_list_tile.dart:33` (depends on T030)
- [ ] T035 [US3] Fix the manually-built back button in `lib/features/transactions/presentation/pages/person_detail_page.dart:58` — `Icon(Icons.arrow_back)` does not auto-mirror under RTL the way the default `BackButton()` widget does — replace with `BackButtonIcon()` (which does mirror) or an explicit `Icon(Icons.arrow_back, textDirection: Directionality.of(context))`
- [ ] T036 [US3] Audit every existing screen/widget for hardcoded user-facing strings not yet sourced from `AppLocalizations`, and add any missing keys to both `lib/core/l10n/app_en.arb` and `lib/core/l10n/app_ar.arb` (regenerate via `flutter gen-l10n`) — covers: `people_list_page.dart`, `person_form_page.dart`, `person_edit_page.dart`, `archived_people_page.dart`, `person_list_tile.dart`, `relationship_tag_chip.dart`, `overview_page.dart`, `person_detail_page.dart`, `transaction_form_page.dart`, `transaction_edit_page.dart`, `repayment_form_page.dart`, `balance_status_badge.dart`, `delete_transaction_confirm_dialog.dart`, `duplicate_warning_sheet.dart`, `overview_summary_card.dart`, `person_picker_field.dart` (all under `lib/features/people/presentation/` and `lib/features/transactions/presentation/`)
- [ ] T037 [US3] Verify mixed Arabic/English content (e.g. a Latin-script person name inside an Arabic-RTL row, or a currency code) renders legibly without overlap, reversed characters, or corrupted spacing on `lib/features/people/presentation/widgets/person_list_tile.dart`, `lib/features/transactions/presentation/pages/person_detail_page.dart`, and `lib/features/transactions/presentation/widgets/person_picker_field.dart`; add a targeted `Directionality`/`TextField.textDirection` override only where a genuine bidi rendering issue is found
- [ ] T038 [P] [US3] Unit test `AppDateFormatter` for both `en` and `ar` locales, asserting output always uses Western digits (0-9), never Arabic-Indic glyphs (٠-٩), in `test/core/date/app_date_formatter_test.dart`
- [ ] T039 [P] [US3] Extend `EgpFormatter`'s existing test suite (`test/core/money/money_test.dart`, or a new `test/core/money/egp_formatter_test.dart`) to cover the `'ar'` locale producing Western digits with correctly-placed grouping/decimal separators
- [ ] T040 [US3] Manually run quickstart.md's scenario 3 across all in-scope screens for both languages/directions and fix any remaining overlap, clipping, or untranslated string found (SC-002, SC-004)

**Checkpoint**: All three user stories are independently functional; SC-001 through SC-006 are verifiable end-to-end.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final gates spanning all three user stories.

- [ ] T041 [P] Run `flutter analyze` and resolve any warnings/errors introduced by this feature (constitution: static analysis must be clean)
- [ ] T042 [P] Add a `bloc_test`/widget test that toggles `SettingsCubit`'s language back and forth 10 times in quick succession and asserts no crash, no duplicated state emissions, and the final state is consistent (SC-006), in `test/features/settings/presentation/cubit/settings_cubit_test.dart`
- [ ] T043 Run `flutter test` and `flutter test integration_test` in full and fix any regressions surfaced across the whole suite (not just this feature's new tests)
- [ ] T044 Manually run quickstart.md's full validation scenarios 1-4 end-to-end as a final smoke test before considering the feature done

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories (persistence layer and `DeviceLocaleProvider` are shared by US1 and US2)
- **User Story 1 (Phase 3)**: Depends on Foundational only
- **User Story 2 (Phase 4)**: Depends on Foundational; also modifies `SettingsCubit`/`SettingsPage`/`main.dart` created in US1 (T011, T014, T016) — cannot start implementation until those files exist, though it adds no new user-facing surface of its own
- **User Story 3 (Phase 5)**: Depends on Foundational; independent of US1/US2's files (touches `EgpFormatter`, new `AppDateFormatter`, and the pre-existing `people`/`transactions` screens) — could technically be built in parallel with US1/US2 by a different developer, though verifying "no app restart" behavior (T040) is easiest once US1 exists
- **Polish (Phase 6)**: Depends on US1, US2, and US3 all being complete

### Within Each User Story

- US1: State/Cubit (T010-T011) → routing/shell (T012-T013) → page (T014) → wiring (T015-T017) → tests (T018-T020)
- US2: Use cases (T021-T022) → Cubit update (T023) → UI/startup wiring (T024-T025) → tests (T026-T029)
- US3: New formatters/helper (T030-T031) → call-site fixes (T032-T035) → string/RTL audit (T036-T037) → tests (T038-T039) → manual pass (T040)

### Parallel Opportunities

- T001/T002 in parallel
- Within Foundational: T004 and T005 in parallel (different files); T007 in parallel with T005 once T004 lands
- Within US1: T018, T019, T020 in parallel (different test files) once their respective implementation tasks land
- Within US2: T021 and T022 in parallel; T026 and T027 in parallel
- Within US3: T030 and T031 in parallel; T038 and T039 in parallel
- US3's implementation (T030-T037) can proceed in parallel with US1/US2 by a different developer, since it touches a disjoint set of files

---

## Parallel Example: Foundational Phase

```bash
# Launch independent Foundational tasks together:
Task: "Create the AppLanguage domain enum in lib/features/settings/domain/entities/app_language.dart"
Task: "Create DeviceLocaleProvider in lib/core/device/device_locale_provider.dart"
```

## Parallel Example: User Story 1 Tests

```bash
# Launch all US1 test tasks together once their implementation tasks are done:
Task: "Widget test for MainShell tab order/mirroring in test/widget/main_shell_test.dart"
Task: "Widget test for SettingsPage language selection in test/widget/settings_page_test.dart"
Task: "bloc_test for SettingsCubit.changeLanguage in test/features/settings/presentation/cubit/settings_cubit_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Run quickstart.md scenario 1 — live language switching from the new Settings tab, no restart
5. Demo if ready — note the language will not yet survive a restart (that's User Story 2)

### Incremental Delivery

1. Setup + Foundational → persistence/device-locale foundation ready
2. Add User Story 1 → validate independently → demo (MVP: live switch works)
3. Add User Story 2 → validate independently → demo (adds restart persistence + first-launch default)
4. Add User Story 3 → validate independently → demo (completes full-app translation/RTL/formatting correctness)
5. Polish → final full-suite run and manual smoke test

### Parallel Team Strategy

With two developers after Foundational is done:

1. Developer A: User Story 1 → User Story 2 (sequential — US2 builds directly on US1's `SettingsCubit`/`SettingsPage`)
2. Developer B: User Story 3 (touches a disjoint file set — `EgpFormatter`, new `AppDateFormatter`, existing `people`/`transactions` screens)
3. Both converge for Phase 6 Polish once all three stories are done
