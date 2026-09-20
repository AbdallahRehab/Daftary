# Implementation Plan: Arabic/English Localization + Language Switch

**Branch**: `002-localization-language-switch` | **Date**: 2026-09-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-localization-language-switch/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Let the user pick Arabic or English from a new Settings tab and have the entire app switch language and reading direction (RTL/LTR) live, with the choice persisted on-device and restored on every launch. Implemented as a new `settings` Flutter clean-architecture feature (persisted via a new Drift table) whose language preference is broadcast app-wide through a root-scoped `SettingsCubit` driving `MaterialApp.router`'s `locale`; navigation is restructured from flat `go_router` routes into a `StatefulShellRoute.indexedStack` with three branches (People/home, Overview, Settings) behind a new bottom navigation bar, which is the new Settings entry point (spec Clarifications). Alongside the switch itself, this feature completes the app's localization coverage (audits every existing screen for hardcoded strings) and fixes the two currently locale-blind formatting paths — `EgpFormatter` (always constructed with `locale: 'en'` today) and three hand-rolled `date.year-month-day` strings — so currency and dates render correctly, with Western Arabic numerals (0-9) even under Arabic (spec Clarifications).

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.38 stable

**Primary Dependencies**: `flutter_bloc` (state management, Principle III) for the new `SettingsCubit`; `go_router`'s `StatefulShellRoute.indexedStack` for the new bottom-navigation shell (preserves each tab's own navigator stack — satisfies FR-014 without custom state-preservation code); `drift` for the new `AppSettings` table (schema v1→v2 migration) via the existing `AppDatabase`; `get_it` + `injectable` for DI; `fpdart` for `Either<Failure, Success>`; `intl` (`flutter_localizations`/`gen_l10n`) for the ARB-driven localization already in place, extended with the `_u_nu_latn` Unicode locale extension to force Western digits under Arabic (spec Clarifications: numeral script) for both `NumberFormat` (currency) and `DateFormat` (dates). No new package dependencies.

**Storage**: Local SQLite via the existing `drift` `AppDatabase` — a new single-row `AppSettings` table (`schemaVersion` 1→2, with an explicit `MigrationStrategy.onUpgrade` added since none exists yet); no remote backend (feature is fully local, per spec Assumptions: single-user/local-first, no per-account profile)

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail` (`SettingsCubit` unit tests with a faked `SettingsRepository`/`DeviceLocaleProvider`), Drift's in-memory `NativeDatabase.memory()` for `SettingsRepositoryImpl`/`SettingsDao` tests, `integration_test` (language switch + persistence + RTL mirroring end-to-end), a golden/widget check of the bottom navigation bar mirrored under `Directionality.rtl`

**Target Platform**: Android and iOS mobile apps (existing `android/`/`ios/` platform folders; desktop/web scaffolding out of scope, matching feature 001)

**Project Type**: mobile-app (Flutter, feature-first clean architecture) — adds one new feature (`settings`) to the existing `people`/`transactions` features

**Performance Goals**: Language switch visibly and fully applied in under 2 seconds with no full-screen flash (SC-001); repeated switching (10x back-to-back) produces zero crashes/freezes/visual corruption (SC-006)

**Constraints**: No app restart for a language change (spec FR-004); the switch MUST apply for the current session even if persisting it fails, with a silent background retry and only a non-blocking notice if that also fails (spec FR-008, Clarifications); Arabic MUST be a genuine mirrored RTL experience, not translated English (FR-006); every user-facing string MUST come from the existing `gen_l10n` ARB files — no hardcoded strings anywhere in-scope (FR-010); digits MUST always render as Western Arabic numerals (0-9) even in Arabic (FR-011, Clarifications); the bottom navigation bar itself must mirror correctly under RTL (FR-003)

**Scale/Scope**: 1 new feature (`settings`); a router restructure touching all 11 existing routes (regrouped into 3 `StatefulShellRoute` branches, no route paths removed); a full-app string/RTL/date/currency audit across ~20 existing screens/widgets (people list, person detail/edit/form, archived people, overview, transaction form/edit, repayment form, plus shared dialogs/bottom sheets/cards); 2 currently locale-blind formatting utilities to fix (`EgpFormatter`, ad-hoc date strings)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Clean Architecture Layering | New `settings` feature split into `data/domain/presentation`; `SettingsCubit` never touches `drift` directly, only `SettingsRepository`; `MainShell` (bottom nav) is a pure Presentation/routing widget with no business logic | PASS |
| II. Feature-First Modularity | New code lives under `lib/features/settings/`; the bottom-nav shell and locale-aware formatter changes live in `lib/core/routing/` and `lib/core/money/`/`lib/core/date/` respectively — genuinely cross-feature concerns, not a new catch-all folder | PASS |
| III. BLoC/Cubit Mandate | `SettingsCubit` is a `flutter_bloc` `Cubit`, same as every other Cubit in the app — no second state-management paradigm. It is root-scoped (provided once above `MaterialApp.router`) rather than per-screen, which is a lifetime choice, not a different pattern; documented in research.md | PASS |
| IV. Immutable State | `SettingsState` is an `Equatable` value class updated via `copyWith()`, mirroring `PersonListState`'s shape | PASS |
| V. Domain-Driven Business Logic | Use cases `GetLanguagePreference` and `ChangeLanguage` represent the two real business actions (resolve current/default language; explicitly change and persist it) — not bare repository passthroughs, since `ChangeLanguage` also owns the retry-once-then-flag-non-blocking-failure policy (FR-008) | PASS |
| VI. Repository Pattern | Domain defines `SettingsRepository`; Data provides `SettingsRepositoryImpl` backed by a new `SettingsDao`; Presentation/Domain depend only on the interface via DI, exactly like `PeopleRepository`/`TransactionsRepository` | PASS |
| VII. Explicit Error Handling | `SettingsRepository` methods return `Either<Failure, T>`; a persistence failure becomes a typed `CacheFailure`, never a raw exception — `ChangeLanguage`/`SettingsCubit` handle it explicitly per FR-008 rather than swallowing it | PASS |
| VIII. Deterministic Financial Calculations | Not applicable — no financial calculation in this feature (only formatting of amounts already computed by feature 001) | PASS (N/A) |
| IX. AI Isolation | Not applicable — no AI integration | PASS (N/A) |
| X. OCR Human-in-the-Loop | Not applicable — no OCR | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Fully local, no network; "offline" is the permanent default. The persistence-failure retry-then-notify policy (FR-008) is this feature's equivalent of graceful degradation — a local storage write failure never blocks the user from using their chosen language | PASS |
| XII. Security & Secrets | No secrets/credentials/sensitive data involved — a language preference is not sensitive; no new logging of sensitive values | PASS (N/A) |
| XIII. Localization & RTL/LTR | This feature directly implements Principle XIII for the whole app: completes ARB coverage, verifies RTL mirroring app-wide, fixes locale-blind currency/date formatting, and forces Western numerals under Arabic per the spec's Clarifications | PASS |
| XIV. Dependency Injection | `SettingsRepository`, `SettingsDao`, both use cases, and `SettingsCubit` are all wired through the existing `get_it`/`injectable` setup; `DeviceLocaleProvider` (new small platform abstraction for first-launch default resolution) is injected too, not read directly from `PlatformDispatcher` inside the Cubit | PASS |
| XV. Design System | `MainShell`'s bottom navigation and the new `SettingsPage` reuse `core/design_system` tokens and existing shared widgets (`AppCard`, etc.); no new hardcoded colors/spacing | PASS |
| XVI. Testability by Design | Unit tests for `SettingsRepositoryImpl`/`SettingsDao` (in-memory Drift), `ChangeLanguage`/`GetLanguagePreference` use cases, `SettingsCubit` (`bloc_test` + `mocktail`, covering the FR-008 retry/notify path), widget tests for `SettingsPage` and RTL mirroring of `MainShell`, and an `integration_test` end-to-end language-switch flow | PASS |

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): The single-row `AppSettings` table and the `DeviceLocaleProvider` platform abstraction added during design are the minimal implementation of FR-005/FR-009 (persistence + first-launch default) — not speculative scope; `DeviceLocaleProvider` exists specifically so Domain/`SettingsCubit` logic stays testable and Flutter-framework-free at the Domain layer (Principle I), with the one unavoidable `PlatformDispatcher` read isolated in `core/`. No new dependency, layering, or state-management deviation was introduced beyond what the Constitution Check above already accounted for; all gates remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/002-localization-language-switch/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── database/
│   │   └── app_database.dart        # +AppSettings table, schemaVersion 1→2, MigrationStrategy.onUpgrade
│   ├── date/
│   │   └── app_date_formatter.dart  # NEW — centralized locale-aware date formatting (replaces 3 ad-hoc
│   │                                  # `'${date.year}-${date.month}-${date.day}'` strings), Western digits under 'ar'
│   ├── device/
│   │   └── device_locale_provider.dart  # NEW — thin abstraction over PlatformDispatcher.locale, injected
│   │                                      # so first-launch default resolution stays testable
│   ├── di/                          # regenerated injection.config.dart (settings + new core deps registered)
│   ├── l10n/                        # app_en.arb / app_ar.arb — extended with every missing key found in audit
│   ├── money/
│   │   └── egp_formatter.dart       # locale param now actually threaded through from the active app locale;
│   │                                  # forces `_u_nu_latn` under 'ar' (Western digits, spec Clarifications)
│   └── routing/
│       ├── app_router.dart          # restructured: StatefulShellRoute.indexedStack, 3 branches
│       └── main_shell.dart          # NEW — bottom navigation Scaffold (People / Overview / Settings)
│
├── features/
│   ├── settings/                    # NEW feature
│   │   ├── data/
│   │   │   ├── datasources/         # SettingsDao (drift, single-row AppSettings table)
│   │   │   └── repositories/        # SettingsRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/            # AppLanguage (enum: english, arabic — Flutter-free)
│   │   │   ├── repositories/        # SettingsRepository (abstract)
│   │   │   └── usecases/            # GetLanguagePreference, ChangeLanguage
│   │   └── presentation/
│   │       ├── cubit/               # SettingsCubit (root-scoped), SettingsState
│   │       └── pages/                # SettingsPage (language picker; extensible for future settings)
│   │
│   ├── people/                       # existing — string/date/currency audit only, no structural change
│   └── transactions/                 # existing — string/date/currency audit only (EgpFormatter/date call
│                                       # sites updated to pass the active locale), no structural change
│
└── main.dart                         # DaftaryApp wrapped in BlocProvider<SettingsCubit>; MaterialApp.router's
                                        # `locale` now driven by SettingsState instead of being device-implicit

test/
├── core/
│   ├── date/                         # AppDateFormatter unit tests (en/ar, Western digits)
│   └── money/                        # EgpFormatter locale-aware formatting tests (extends existing suite)
├── features/
│   └── settings/
│       ├── domain/usecases/          # GetLanguagePreference, ChangeLanguage — faked SettingsRepository
│       ├── data/repositories/        # SettingsRepositoryImpl against an in-memory drift DB
│       └── presentation/cubit/       # SettingsCubit — bloc_test + mocktail, covers FR-008 retry/notify path
└── widget/
    ├── main_shell_test.dart          # NEW — bottom nav renders/mirrors correctly under LTR and RTL
    └── settings_page_test.dart       # NEW — language selection triggers the expected Cubit calls

integration_test/
└── language_switch_flow_test.dart    # NEW — switch language live, verify RTL/persistence across a
                                        # simulated restart, per spec User Stories 1-2
```

**Structure Decision**: Same single Flutter app shape as feature 001 (Option 1), extended with one new feature-first module (`lib/features/settings/`) following the identical `data/domain/presentation` layering as `people`/`transactions`. The bottom-navigation shell and the two now-locale-aware formatting utilities are cross-feature concerns and correctly live in `lib/core/` (Principle II) rather than inside `settings` — `people`/`transactions` screens call them but don't own them. No `backend/`/`api/` split; this feature adds no network layer. Tests continue to mirror `lib/` under `test/`, plus `integration_test/` for the end-to-end language-switch flow.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally omitted.
