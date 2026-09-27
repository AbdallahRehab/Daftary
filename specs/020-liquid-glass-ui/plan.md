# Implementation Plan: Configurable Liquid Glass UI

**Branch**: `020-liquid-glass-ui` | **Date**: 2026-09-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/020-liquid-glass-ui/spec.md`

## Summary

Add `liquid_glass_widgets` (1.7.x) as an optional, user-controlled visual layer. The user's preference has three fields: on/off, Transparency (Low/Medium/High), and Intensity (Low/Medium/High). It lives in the existing drift `AppSettings` row and the existing root `SettingsCubit`. It reaches the UI through one app-owned `AppGlassScope`. A small set of adaptive design-system components (`AppTopBar`, `AppScaffold`, `AppNavigationBar`, `AppFab`, `showAppModalSheet`) replace their Material counterparts one-for-one:

- **Glass OFF**: each component returns the exact Material widget.
- **Glass ON**: each component keeps the Material widget, and so its semantics, back button, tooltips and text scaling. It makes the widget's background transparent and places a single `GlassContainer` platter behind it.

Transparency maps to the tint alpha of `ColorScheme.surface` (with `GlassBodyMode.clear`), and Intensity maps to `blur`. Both use fixed, readability-floored tokens. Research is in [research.md](research.md).

```text
Settings page (Material controls + preview)
      │  setGlassEnabled / setGlassTransparency / setGlassIntensity
      ▼
SettingsCubit ──ChangeGlassAppearance (retry-once)──► SettingsRepository ─► SettingsDao ─► AppSettings (schema 8)
      │  state.glassAppearance (Equatable)
      ▼
main.dart: BlocSelector ─► glass_style_mapper ─► AppGlassScope(AppGlassStyle)   [core/design_system/glass]
      │  (only dependents rebuild; MaterialApp does not: root buildWhen = language|themeMode)
      ▼
AppTopBar · AppScaffold · AppNavigationBar · AppFab · showAppModalSheet · Settings preview
      ├─ enabled  → Material widget (transparent) + AppGlassSurface (GlassContainer, standard quality)
      └─ disabled → identical pre-feature Material widget, no package widget built
```

## Technical Context

**Language/Version**: Dart `^3.10` / Flutter 3.47.0 stable.

**Primary Dependencies**:

- Existing: `flutter_bloc` 9, `injectable`/`get_it`, `drift` 2.22, `fpdart`, `equatable`, `go_router` 18, and `flutter_localizations` with `gen_l10n`.
- **New**: `liquid_glass_widgets >=1.7.2 <1.8.0`. It depends only on the Flutter SDK.

**Storage**: drift/SQLite, the `AppSettings` single row. Three nullable columns are added, and the schema goes from 7 to 8.

**Testing**: `flutter_test`, `bloc_test`, `mocktail`, drift in-memory databases, and the existing migration-test pattern.

**Target Platform**: Android (Impeller Vulkan, plus the GLES fallback) and iOS 15+. The package also supports desktop and web, which the app doesn't target.

**Project Type**: Mobile app with a feature-first Clean Architecture.

**Performance Goals**:

- 95% or more of frames within budget while scrolling the longest lists with glass ON at the highest intensity (SC-006).
- A glass setting change rebuilds only the glass components and the preview (FR-022).

**Constraints**:

- Pixel-identical UI when OFF (SC-003).
- No package widget built when OFF.
- The package is imported only in `core/design_system/glass/` and in `main.dart` for bootstrap.

**Scale/Scope**:

- 17 pages with an app bar, 5 pages with a FAB, 1 modal sheet, and the compact bottom bar.
- About 10 new core files, 8 settings-feature file edits, 1 migration, and about 10 new l10n keys.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | How |
| --- | --- | --- |
| I Clean Architecture | ✅ | `GlassLevel`/`GlassAppearance` are Flutter-free domain types. Data is in DAO and repository. Presentation holds the cubit, mapper and components. Screens get no logic. |
| II Feature-first | ✅ | The preference code stays in `features/settings`. The adaptive components go into `core/design_system/glass/` because they're used by 6 features (people, transactions, finance, currency, insights_notifications, financial_education) plus the shell. That's the "shared by 2+ features" bar. Core never imports a feature, because mapping happens in `features/settings/presentation`. |
| III BLoC/Cubit | ✅ | Reuses the root `SettingsCubit`. No new state paradigm. |
| IV Immutable state | ✅ | `copyWith` on `SettingsState` and `GlassAppearance`. `BlocSelector` plus Equatable prevent redundant emissions and rebuilds. The root `buildWhen` is added. |
| V Domain-driven use cases | ⚠️ justified | `ChangeGlassAppearance` owns the retry policy. `GetGlassAppearancePreference` is thin and kept for symmetry (Complexity Tracking). |
| VI Repository | ✅ | Two methods are added to the existing `SettingsRepository` contract. The implementation is in `SettingsRepositoryImpl`. |
| VII Error handling | ✅ | `Either<Failure, …>` with `CacheFailure`. Per-field fallback for unknown values, with no throws. A failed save leads to a localized non-blocking snackbar. |
| VIII–XI Financial / AI / OCR / sync | N/A | No financial data, AI, OCR or network involved. |
| XII Security | ✅ | Non-sensitive display preference. Nothing is logged. |
| XIII Localization/RTL | ✅ | About 10 new ARB keys in `en` and `ar`. Components use Material directional widgets. RTL is part of the widget tests and the manual matrix. |
| XIV DI | ✅ | New use cases are `@injectable`. The cubit constructor gains them through `injection.config.dart` regeneration. |
| XV Design system | ✅ | Level values in `AppGlassTokens`. Tint from `ColorScheme.surface`. No raw colours. The components use the `App` prefix. |
| XVI Testability | ✅ | Unit, cubit, migration and component contract tests, plus the Settings page widget test (research Decision 16). |
| New dependency ("unjustified new dependencies" prohibited) | ✅ justified | User-requested capability. Pure Dart/Flutter with no native code or permissions. Isolated behind core components, so removing it touches one directory plus the bootstrap. |

**Gate result**: PASS, with one documented Principle V deviation.

**Post-design re-check**: PASS. The Phase 1 artifacts (data model, contracts) introduce no new violations. The core → feature dependency direction was checked: the mapper lives in the feature.

## Project Structure

### Documentation (this feature)

```text
specs/020-liquid-glass-ui/
├── plan.md                         # this file
├── research.md                     # Phase 0 — 16 decisions, spikes S1–S5
├── data-model.md                   # Phase 1
├── quickstart.md                   # Phase 1 — validation guide
├── contracts/
│   ├── settings_repository.md      # repo / use case / cubit additions
│   └── adaptive_glass_components.md# UI component contract + OFF-identity invariant
├── checklists/requirements.md
└── tasks.md                        # Phase 2 (/speckit-tasks, not yet created)
```

### Source Code (repository root)

```text
pubspec.yaml                                   # + liquid_glass_widgets >=1.7.2 <1.8.0
lib/main.dart                                  # initialize() + wrap(); root buildWhen; BlocSelector → AppGlassScope in builder

lib/core/database/app_database.dart            # AppSettings + glassEnabled/glassTransparency/glassIntensity; schemaVersion 8; from<8 migration
lib/core/design_system/glass/                  # NEW — only place importing the package
├── app_glass_style.dart                       # AppGlassStyle (+ .off)
├── app_glass_tokens.dart                      # level → tint alpha / blur table
├── app_glass_scope.dart                       # InheritedWidget, of / maybeOf
├── app_glass_surface.dart                     # GlassContainer primitive (+ no-nesting assert)
├── app_glass_insets.dart                      # padding delta, zero when OFF
├── app_top_bar.dart                           # AppBar adaptive
├── app_scaffold.dart                          # Scaffold adaptive (extendBody*)
├── app_navigation_bar.dart                    # NavigationBar adaptive
├── app_fab.dart                               # FloatingActionButton adaptive (.small/.extended)
└── app_modal_sheet.dart                       # showAppModalSheet
lib/core/l10n/app_en.arb, app_ar.arb           # + appearance/glass keys
lib/core/routing/main_shell.dart               # compact Scaffold/NavigationBar → AppScaffold/AppNavigationBar

lib/features/settings/
├── domain/entities/glass_level.dart           # NEW
├── domain/entities/glass_appearance.dart      # NEW
├── domain/repositories/settings_repository.dart          # + 2 methods
├── domain/usecases/get_glass_appearance_preference.dart  # NEW
├── domain/usecases/change_glass_appearance.dart          # NEW (retry-once)
├── data/datasources/settings_dao.dart          # upsertPreference + 3 optional params
├── data/repositories/settings_repository_impl.dart       # + 2 methods, per-field parse
├── presentation/cubit/settings_state.dart      # + glassAppearance, isGlassPersistFailing
├── presentation/cubit/settings_cubit.dart      # initialize + 3 setters
├── presentation/glass/glass_style_mapper.dart  # NEW GlassAppearance → AppGlassStyle
├── presentation/pages/settings_page.dart       # Appearance section, snackbar listener
└── presentation/widgets/glass_preview.dart     # NEW preview built on AppGlassSurface

# Mechanical one-line swaps (AppBar→AppTopBar, Scaffold→AppScaffold, FAB→AppFab, + AppGlassInsets on explicit scroll padding)
lib/features/{people,transactions,finance,currency,insights_notifications,financial_education,settings}/presentation/**  # 17 pages
lib/features/transactions/presentation/widgets/duplicate_warning_sheet.dart          # showModalBottomSheet → showAppModalSheet

test/core/database/app_database_migration_test.dart   # + v7→v8 case
test/core/design_system/glass/                        # NEW — one contract test per component + surface
test/features/settings/{data,domain,presentation}/    # extended: DAO, repo, use cases, cubit, settings page
```

**Structure Decision**: Follow the existing feature-first layout. The preference is owned by `features/settings` in the same shape as language and theme mode (entity → repo → DAO → cubit). The rendering capability is a design-system concern in `core/design_system/glass/`, which is the single seam to the third-party package. Screens only swap widget names.

## Delivery phases (input to `/speckit-tasks`)

1. **Spikes S1–S5** (research.md). These are throwaway. They confirm the rendering, token contrast, the accessibility fallback and test-harness behaviour on real devices before any screen is touched. **Exit**: the token table is finalized, or the plan is revised.
2. **Preference slice** (US1 data path): domain types → DAO/migration → repository → use cases → cubit → tests. There is no UI change yet, and the app behaves identically.
3. **Glass core**: style, tokens, scope, surface, insets → `AppTopBar`, `AppScaffold`, `AppNavigationBar`, `AppFab`, `showAppModalSheet`, each with an OFF-identity and ON contract test. Then wire up `main.dart` (bootstrap, `buildWhen`, selector → scope).
4. **Settings UX** (US1 toggle, US2 levels, US3 preview), plus l10n (en/ar) and the snackbar.
5. **Surface migration** (US4): the shell bottom bar, then the 17 app-bar pages with their scroll-padding audit, the 5 FAB pages, and the 1 sheet. One feature folder per commit, and the full test suite is run after each.
6. **Verification**: the quickstart matrix, the profile-mode performance run, and the `grep` isolation check.

## Risks

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| `GlassContainer` doesn't blur live content without `LiquidGlassScope` on some path | Medium | Spike S2 runs first. Fallback: wrap the shell and page bodies in `LiquidGlassScope` + `GlassBackgroundSource` inside `AppScaffold`, which stays contained in core. |
| Token contrast fails on the busiest screens | Medium | Spike S3. Only the token numbers change, and the spec already fixes three levels. |
| Scroll-padding audit misses a screen, so content hides under the bar when ON | Medium | A per-screen checklist in tasks, and scenario 1 of the quickstart walks every screen. OFF is unaffected because the insets are zero. |
| Package minor releases change the look | Medium | Version capped below 1.8. The package is imported in one directory. |
| Default ON surprises upgraded users | Low / product | Spec Assumption. Reversible with one toggle. Revisit in `/speckit-clarify` if needed. |
| App-bar scope (Q1) was defaulted, not confirmed | Product | All 17 pages is the recommended default. Phase 5 is split per feature, so narrowing the scope only drops tasks. |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| `GetGlassAppearancePreference` is a thin pass-through use case (Principle V) | The cubit depends only on use cases, matching the existing `GetLanguagePreference`/`GetThemeModePreference` | Injecting the repository into the cubit for this one read would mix two patterns inside the same cubit. |
| `AppScaffold` wraps `Scaffold` | `extendBodyBehindAppBar`/`extendBody` must follow the glass state without branching in 17 screens (FR-014) | Per-screen flags put glass logic in screens. Leaving the layout unchanged makes glass invisible (research Decision 6). |
| `AppGlassInsets` padding delta | Keeps the OFF layout pixel-identical while letting content clear the glass chrome when ON | Adding `MediaQuery` padding unconditionally shifts OFF layouts on notched, tablet and pushed routes. |
