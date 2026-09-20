# Implementation Plan: Dark Mode / Theme Switching

**Branch**: `003-dark-mode-theme` | **Date**: 2026-09-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-dark-mode-theme/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Let the user pick Light, Dark, or System Default from the existing Settings screen and
have the entire app re-theme live, with the choice persisted on-device and restored (or,
for System Default, freshly re-resolved) on every launch. Implemented entirely by
extending the `002-localization-language-switch` `settings` feature — the same
root-scoped `SettingsCubit`, the same single-row `AppSettings` Drift table (a new
nullable `themeMode` column, schemaVersion 2→3), and the same retry-once-then-notify
persistence-failure policy `002` established for language — rather than a parallel
mechanism, per spec Assumptions. The harder half of this feature is FR-006/FR-007: the
app's colors today (`lib/core/design_system/tokens.dart`'s `AppColors`) are
`static const Color` fields referenced directly from 9 files, which cannot vary by theme;
this plan replaces them with a two-part runtime token system — Material's own
`ColorScheme.fromSeed(brightness:)` for general roles (background/surface/text/border/
divider/inputs/cards/navigation/dialogs/bottom sheets), plus one small custom
`AppFinanceColors` `ThemeExtension` for the finance-specific roles Material has no
equivalent for (positive/negative/neutral/success/warning + their surfaces) — and updates
every one of those 9 files to read colors through `BuildContext` instead of the static
class. `MaterialApp.router`'s `themeMode: ThemeMode.system` branch (Flutter's own
platform-brightness-change listening) satisfies FR-002/User Story 3's live
system-following requirement with no custom polling code.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.38 stable

**Primary Dependencies**: `flutter_bloc` (Principle III) — extends the existing
`SettingsCubit`/`SettingsState`, no new Cubit; `drift` for the `AppSettings.themeMode`
column (schema v2→v3 migration) via the existing `AppDatabase`; `get_it` + `injectable`
for DI (two new use cases registered the same way `GetLanguagePreference`/
`ChangeLanguage` are today); `fpdart` for `Either<Failure, Success>`; Flutter's own
`ThemeData`/`ColorScheme`/`ThemeExtension`/`ThemeMode` (framework-native, no package
dependency) for the theme/token layer. No new package dependencies.

**Storage**: Local SQLite via the existing `drift` `AppDatabase` — the existing
single-row `AppSettings` table gains one nullable `themeMode TEXT` column
(`schemaVersion` 2→3, extending the `MigrationStrategy.onUpgrade` `002` already added);
no remote backend (fully local, matching `001`/`002`).

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail` (`SettingsCubit`
theme-mode transitions and `isThemeModePersistFailing`, faked `SettingsRepository`),
Drift's in-memory `NativeDatabase.memory()` for `SettingsRepositoryImpl`/`SettingsDao`
theme-column tests, widget tests re-rendering each of the 9 audited widgets under both
`buildLightTheme()`/`buildDarkTheme()` to catch a missed hardcoded color, `integration_test`
(live switch + persistence across a simulated restart + system-default re-resolution,
per spec User Stories 1-3). WCAG 2.1 AA contrast is verified manually (values computed and
recorded in `data-model.md`) and additionally guarded by a lightweight automated
contrast-ratio unit test (`test/core/design_system/contrast_ratio_test.dart`, tasks.md
T053) computed directly from the token values — no third-party contrast-checking tooling
is introduced, per spec Assumptions.

**Target Platform**: Android and iOS mobile apps (existing `android/`/`ios/` platform
folders; desktop/web scaffolding out of scope, matching `001`/`002`)

**Project Type**: mobile-app (Flutter, feature-first clean architecture) — extends the
existing `settings` feature and `core/design_system`; adds no new top-level feature

**Performance Goals**: Theme switch visibly and fully applied to every currently visible
screen in under 1 second, no restart (SC-001); switching repeatedly produces no visual
corruption or dropped frames (implied by SC-001/SC-002 holding on every check)

**Constraints**: No app restart for a theme change (FR-004); System Default MUST follow
live OS changes while the app is open, not just at next launch (FR-002, User Story 3);
switching theme MUST NOT lose in-progress form input or dismiss an open dialog/bottom
sheet (FR-012); every screen/dialog/bottom sheet/shared component MUST source colors from
the centralized semantic tokens, not hardcoded values, including anything added after this
feature ships (FR-006/FR-007, Edge Cases); all text — especially financial values — MUST
meet WCAG 2.1 AA (4.5:1 normal text / 3:1 large text/UI components) in both themes
(FR-008); status/meaning MUST NOT be conveyed by color alone in either theme (FR-009).

**Scale/Scope**: 0 new top-level features (extends `settings`); 1 Drift schema migration
(v2→v3, one nullable column); 2 new Domain use cases (`GetThemeModePreference`,
`ChangeThemeMode`) plus 2 new `SettingsRepository` methods; a bounded 11-file color-token
audit — 9 files via direct `AppColors.*` reference
(`lib/core/design_system/{tokens,app_card,app_text_field,app_empty_view}.dart`,
`lib/features/transactions/presentation/{widgets/overview_summary_card.dart,widgets/balance_status_badge.dart,widgets/transaction_list_tile.dart,pages/overview_page.dart}`,
`lib/features/people/presentation/widgets/relationship_tag_chip.dart`), plus 2 more files
via `AppTypography.bodyMuted`-only usage
(`lib/features/transactions/presentation/widgets/duplicate_warning_sheet.dart`,
`lib/features/people/presentation/pages/person_form_page.dart`) — verified exhaustive
via `grep -rn "AppColors\."`/`grep -rn "Color(0x"`/`grep -rn "AppTypography.bodyMuted"` across
`lib/`, no other hardcoded-color call sites exist; 1 new ARB key group (theme section title
+ 3 mode labels + 1 save-failed message, in both `app_en.arb`/`app_ar.arb`) plus regenerated
`app_localizations*.dart`; `main.dart`'s `MaterialApp.router` gains `darkTheme`/`themeMode`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
| --- | --- | --- |
| I. Clean Architecture Layering | `AppThemeMode` (Domain) stays Flutter-free — no `package:flutter` import; the `AppThemeMode → ThemeMode` mapping lives only at the Presentation boundary (`main.dart`, inlined per research.md Decision 6), exactly mirroring how `AppLanguage → Locale` is handled today. `SettingsCubit`/use cases never touch `drift` or `ThemeData` directly | PASS |
| II. Feature-First Modularity | No new top-level feature folder — theme preference extends the existing `lib/features/settings/` `data/domain/presentation` layers; the token/theme rewrite lives in `lib/core/design_system/`, a genuinely cross-feature design-system concern already established by `001`/`002`, not a new catch-all | PASS |
| III. BLoC/Cubit Mandate | Reuses the existing root-scoped `SettingsCubit` — no second Cubit, no second state-management paradigm. `ThemeExtension`/`ColorScheme` are Flutter's own theming mechanism (the same mechanism the app's single `ThemeData` already used pre-feature), not an alternative to BLoC — the actual *selected mode* state lives in `SettingsState`, nowhere else (research.md Decision 7) | PASS |
| IV. Immutable State | `SettingsState` extended via `copyWith()` with two new fields (`themeMode`, `isThemeModePersistFailing`), same `Equatable` value-class pattern as the existing `language`/`isPersistFailing` fields — no mutation | PASS |
| V. Domain-Driven Business Logic | `GetThemeModePreference`/`ChangeThemeMode` mirror `GetLanguagePreference`/`ChangeLanguage` — `ChangeThemeMode` owns the retry-once-then-flag policy (research.md Decision 9), a real (if small) business rule, not a bare repository passthrough | PASS |
| VI. Repository Pattern | `SettingsRepository` (existing interface) is *extended* with two methods, not replaced or duplicated; `SettingsRepositoryImpl`/`SettingsDao` remain the only Data-layer implementation, resolved via DI exactly like every other repository | PASS |
| VII. Explicit Error Handling | New repository methods return `Either<Failure, T>`; a theme-mode persistence failure becomes the existing `CacheFailure`, no new failure type, never a raw exception reaching `SettingsCubit`/UI | PASS |
| VIII. Deterministic Financial Calculations | Not applicable — no financial calculation touched; this feature only changes how already-computed amounts are *colored/rendered*, addressed instead by FR-008/FR-009 (contrast, no color-alone meaning) and Principle XV below | PASS (N/A) |
| IX. AI Isolation | Not applicable — no AI integration | PASS (N/A) |
| X. OCR Human-in-the-Loop | Not applicable — no OCR | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Fully local, no network, same as `002`. `ChangeThemeMode`'s retry-once-then-notify policy is this feature's instance of `002`'s established graceful-degradation pattern: a local write failure never blocks the user from using their chosen theme for the current session | PASS |
| XII. Security & Secrets | No secrets/credentials/sensitive data involved — a theme preference is not sensitive; no new logging of sensitive values | PASS (N/A) |
| XIII. Localization & RTL/LTR | New user-facing strings (theme section title, "Light"/"Dark"/"System Default" labels, a save-failed notice) are added to both `app_en.arb`/`app_ar.arb` and consumed via `AppLocalizations`, never hardcoded — no `Text("Dark")` literals. RTL mirroring is unaffected (orthogonal to color theming) and re-verified per the quickstart's User Story 1 walkthrough in Dark theme | PASS |
| XIV. Dependency Injection | `GetThemeModePreference`/`ChangeThemeMode` are `@injectable`, registered through the existing `get_it`/`injectable` codegen (`injection.config.dart` regenerated), exactly like every other use case — no manual instantiation introduced | PASS |
| XV. Design System | This feature is the direct, concrete fulfillment of Principle XV's "consumed via theme/design tokens" requirement for color — today's `AppColors` `static const` fields are, by construction, incapable of varying by theme; converting them to `Theme.of(context).colorScheme`/`context.financeColors` (research.md Decision 7) is this principle's central deliverable here, and the 9-file audit is scoped exhaustively (verified via repo-wide `grep`, not sampled) | PASS |
| XVI. Testability by Design | Unit tests for `SettingsRepositoryImpl`'s new theme methods and `SettingsDao`'s merge-then-upsert logic (in-memory Drift), `GetThemeModePreference`/`ChangeThemeMode` use cases (faked repository), `SettingsCubit` theme-mode transitions and the `isThemeModePersistFailing` path (`bloc_test`+`mocktail`), widget tests re-rendering the 9 audited widgets under both themes, and an `integration_test` covering all three user stories end-to-end | PASS |

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`):
The two-part token design (`ColorScheme.fromSeed(brightness:)` + one custom
`AppFinanceColors` `ThemeExtension`, data-model.md Entity 2) is the minimal implementation
of FR-006 — it reuses Material's built-in contrast-aware role generation for every role
that maps onto it, and hand-authors only the finance-specific roles Material has no
equivalent for, rather than duplicating ~20 roles across a single bespoke token class.
The `SettingsDao.upsertPreference` merge-then-upsert rewrite (research.md Decision 3,
required once a second nullable preference shares the same singleton row) was the one
design detail not obvious from `002`'s original single-preference shape; it was worked
out during Phase 0 and adds no new dependency, layering, or state-management deviation.
All gates above remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/003-dark-mode-theme/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md         # Phase 1 output (/speckit-plan command)
├── contracts/            # Phase 1 output (/speckit-plan command)
│   ├── settings_repository.md
│   └── theme_tokens.md
└── tasks.md              # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── database/
│   │   └── app_database.dart        # +AppSettings.themeMode (nullable), schemaVersion 2→3,
│   │                                   # migration onUpgrade gains `if (from < 3) addColumn(...)`
│   ├── design_system/
│   │   ├── tokens.dart               # REWRITTEN: buildLightTheme()/buildDarkTheme() replace
│   │   │                               # buildAppTheme(); AppFinanceColors ThemeExtension (light/dark);
│   │   │                               # AppThemeContext BuildContext extension (.financeColors);
│   │   │                               # AppColors retained internally as the two themes' seed values only
│   │   ├── app_card.dart             # AppColors.surface/divider → Theme.of(context).colorScheme.*
│   │   ├── app_text_field.dart       # AppColors.surface/divider → Theme.of(context).colorScheme.*
│   │   │                               # (fillColor/border now come from InputDecorationTheme where possible)
│   │   └── app_empty_view.dart       # AppColors.onSurfaceMuted → Theme.of(context).colorScheme.onSurfaceVariant
│   ├── di/                           # regenerated injection.config.dart (+GetThemeModePreference,
│   │                                   # +ChangeThemeMode registrations)
│   └── l10n/                         # app_en.arb / app_ar.arb — +themeSectionTitle, +themeLight,
│                                       # +themeDark, +themeSystemDefault, +themeSaveFailed
│                                       # (app_localizations*.dart regenerated via gen_l10n)
│
├── features/
│   ├── settings/                     # EXTENDED (not new)
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── settings_dao.dart          # upsertPreference(String,int) → upsertPreference({
│   │   │   │                                    # String? languageCode, String? themeMode, required int
│   │   │   │                                    # updatedAt}) — merge-then-upsert (research.md Decision 3)
│   │   │   └── repositories/
│   │   │       └── settings_repository_impl.dart  # +getThemeModePreference/setThemeModePreference
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── app_theme_mode.dart        # NEW — enum: light, dark, system (Flutter-free)
│   │   │   ├── repositories/
│   │   │   │   └── settings_repository.dart   # +2 methods (abstract)
│   │   │   └── usecases/
│   │   │       ├── get_theme_mode_preference.dart  # NEW
│   │   │       └── change_theme_mode.dart          # NEW
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   ├── settings_cubit.dart        # initialize() also resolves themeMode;
│   │       │   │                                # +changeThemeMode(AppThemeMode)
│   │       │   └── settings_state.dart        # +themeMode, +isThemeModePersistFailing
│   │       └── pages/
│   │           └── settings_page.dart         # +Theme section (Light/Dark/System RadioGroup,
│   │                                            # mirroring the existing Language RadioGroup)
│   │
│   ├── transactions/
│   │   └── presentation/
│   │       ├── widgets/
│   │       │   ├── overview_summary_card.dart      # AppColors.positive/negative/divider →
│   │       │   │                                      # context.financeColors.*/colorScheme.outlineVariant
│   │       │   ├── balance_status_badge.dart        # AppColors.positive/negative/neutral(+Surface) →
│   │       │   │                                      # context.financeColors.*
│   │       │   ├── transaction_list_tile.dart        # AppColors.negative/positive/neutralSurface →
│   │       │   │                                       # context.financeColors.*
│   │       │   └── duplicate_warning_sheet.dart      # AppTypography.bodyMuted-only: add explicit
│   │       │                                           # onSurfaceVariant color (research.md Decision 8)
│   │       └── pages/
│   │           └── overview_page.dart                # AppColors.positive/negative → context.financeColors.*
│   │
│   └── people/
│       └── presentation/
│           ├── widgets/
│           │   └── relationship_tag_chip.dart         # AppColors.neutralSurface → context.financeColors.neutralSurface
│           └── pages/
│               └── person_form_page.dart              # AppTypography.bodyMuted-only: add explicit
│                                                        # onSurfaceVariant color (research.md Decision 8)
│
└── main.dart                          # MaterialApp.router gains darkTheme: buildDarkTheme(),
                                         # themeMode: <mapped from state.themeMode>; theme: buildLightTheme()
                                         # (renamed from buildAppTheme())

test/
├── core/
│   └── database/                      # NEW — AppDatabase migration test (v2→v3 leaves themeMode NULL
│                                        # on existing rows, fresh installs get schemaVersion 3 directly)
├── features/
│   └── settings/
│       ├── domain/usecases/           # +get_theme_mode_preference_test.dart, +change_theme_mode_test.dart
│       ├── data/
│       │   ├── datasources/           # +settings_dao_test.dart (merge-then-upsert correctness:
│       │   │                            # a theme-only write doesn't clobber languageCode and vice versa)
│       │   └── repositories/          # settings_repository_impl_test.dart extended with theme cases
│       └── presentation/cubit/        # settings_cubit_test.dart extended: changeThemeMode transitions,
│                                        # isThemeModePersistFailing retry-then-fail path
└── widget/
    ├── settings_page_test.dart        # extended: theme selection triggers the expected Cubit calls
    ├── app_card_test.dart             # NEW — renders correctly under buildLightTheme()/buildDarkTheme()
    ├── balance_status_badge_test.dart # NEW — same, both themes; icon+label still present regardless of theme
    └── transaction_list_tile_test.dart # NEW — same, both themes

integration_test/
└── theme_switch_flow_test.dart        # NEW — switch theme live, verify persistence across a simulated
                                         # restart, and System Default re-resolving live, per User Stories 1-3
```

**Structure Decision**: Same single Flutter app shape as `001`/`002` (Option 1). This
feature adds **no new top-level feature** — it extends the existing `settings` feature
(Principle II: theme preference is genuinely the same kind of concern as language
preference, already co-located on the Settings screen) and rewrites
`lib/core/design_system/tokens.dart` plus its handful of direct consumers (a legitimate
`core/` responsibility — design tokens are cross-feature by definition, same justification
`001` used for `core/design_system/` originally). No `backend/`/`api/` split; no network
layer. Tests continue to mirror `lib/` under `test/`, plus `integration_test/` for the
end-to-end theme-switch flow, matching `002`'s precedent exactly.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally omitted.
