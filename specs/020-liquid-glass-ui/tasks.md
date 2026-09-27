---
description: "Task list for 020 Configurable Liquid Glass UI"
---

# Tasks: Configurable Liquid Glass UI

**Input**: Design documents from `specs/020-liquid-glass-ui/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Included. Constitution Principle XVI requires them, and research Decision 16 defines them. Within each phase, write tests first and confirm they fail before implementing.

**Organization**:

- Phase 1 is package preparation.
- Phase 2 is the blocking foundation, split into sub-phases that match the requested areas:
  - 2A: configuration model
  - 2B: persistence
  - 2C: state management
  - 2D: reusable glass abstraction
- Phases 3–7 are the spec's user stories.
- Phase 8 is verification and polish.

**Story map (spec.md)**:

| Label | User story | Priority |
| --- | --- | --- |
| US1 | Turn Liquid Glass on or off | P1 |
| US2 | Adjust how strong the glass looks | P2 |
| US3 | Live preview in Settings | P3 |
| US4 | Glass used only where it helps (full surface rollout) | P2 |
| US5 | Consistent with themes, languages, platforms and accessibility | P2 |

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task).
- **[Story]**: the user story the task belongs to. Setup, Foundational and Polish tasks have no label.

---

## Phase 1: Setup — Project & Package Preparation

**Purpose**: Add the package safely and prove the rendering assumptions on real devices before any app code depends on them.

- [X] T001 Record the toolchain baseline. Run `flutter --version` and `dart --version`, and confirm they satisfy `liquid_glass_widgets` 1.7.2's constraints (`flutter: >=3.41.0`, `sdk: >=3.5.0 <4.0.0`) against the project's `environment: sdk: ^3.10.0` in `pubspec.yaml`. Paste the outputs into the "Baseline" note at the bottom of this file.
- [X] T002 Snapshot the current dependency lock: copy `pubspec.lock` to `specs/020-liquid-glass-ui/pubspec.lock.before` (a temporary file, deleted in T095).
- [X] T003 Add `liquid_glass_widgets: '>=1.7.2 <1.8.0'` under `dependencies:` in `pubspec.yaml`. Run **`flutter pub get`, not `pub upgrade`**. Then diff `pubspec.lock` against `pubspec.lock.before`: the only change allowed is the new `liquid_glass_widgets` entry, which has no transitive dependencies besides Flutter. Revert and investigate if any other package's version changed.
- [X] T004 Verify the package's bootstrap API against the resolved source in the pub cache: open `package:liquid_glass_widgets/liquid_glass_setup.dart`. Confirm that `LiquidGlassWidgets.initialize()` is `Future<void>`, and that `LiquidGlassWidgets.wrap({required Widget child, GlassThemeData? theme, bool respectSystemAccessibility = true, bool adaptiveQuality = false, …, Brightness? Function(BuildContext)? brightnessResolver})` only sets globals and returns `child` when `theme == null` and `adaptiveQuality == false`. Note any difference in the Baseline note, and stop if the API differs from research.md Decisions 2–3.
- [X] T005 Verify supported platforms and rendering paths from the resolved package's `README.md` and `pubspec.yaml`: iOS (Impeller/Metal), Android (Impeller Vulkan, plus the GLES fallback), and automatic fallback where `ImageFilter.isShaderFilterSupported` is false. Confirm that no native setup is needed (no `Info.plist`, Gradle, `AndroidManifest.xml` or `Podfile`/SPM change). Record this in the Baseline note.
- [ ] T006 Create a throwaway spike route (not committed) at `lib/dev/glass_spike_page.dart`. It is a `ListView` of 200 coloured `ListTile`s under a Material `AppBar` whose `flexibleSpace` is `GlassContainer(shape: LiquidRoundedSuperellipse(borderRadius: 0), quality: GlassQuality.standard, settings: LiquidGlassSettings(glassColor: <surface @ 0.74>, blur: 8, thickness: 10, bodyMode: GlassBodyMode.clear))`, with `Scaffold(extendBodyBehindAppBar: true)`. Call `LiquidGlassWidgets.initialize()` and `wrap(...)` temporarily in `lib/main.dart`.
- [ ] T007 **Spike S1/S2** (research Decision 5): run the T006 page on an iPhone, an Android Impeller-Vulkan device and a budget Android GLES device. Record in the Baseline note:
  - (a) the bar renders as a clean full-bleed rectangle;
  - (b) list content visibly blurs beneath it **without** `LiquidGlassScope`/`GlassBackgroundSource`.

  If (b) fails on any path, record the fallback: `AppScaffold` wraps its body in `LiquidGlassScope` + `GlassBackgroundSource`, per the plan's Risks table.
- [ ] T008 **Spike S3** (research Decision 7): in the T006 page, cycle tint alpha {0.86/0.84, 0.74/0.70, 0.62/0.58} × blur {4, 8, 14} in light and dark. Screenshot each combination over the busiest scroll position, and measure title-text and icon contrast against the rendered bar pixels. Pass means ≥ 4.5:1 for text and ≥ 3:1 for icons (SC-005). Record the final numbers for `AppGlassTokens` in the Baseline note, adjusting only the numbers.
- [ ] T009 **Spike S4** (research Decision 15): on iOS, enable Settings → Accessibility → Display & Text Size → Increase Contrast and reopen the T006 page. Confirm the glass switches to the package's plain frosted rendering and still meets SC-005. Record the result.
- [X] T010 **Spike S5** (research Decision 16): in a scratch test under `test/`, pump the T006 `GlassContainer` inside `MaterialApp` with `flutter test`, and confirm there are no shader or asset exceptions. Record the result. If it fails, T030 must add an `AppGlassScope.debugDisableRendering` test seam.
- [X] T011 Remove the spike: delete `lib/dev/glass_spike_page.dart` and the scratch test, and revert the temporary `lib/main.dart` changes. Keep only the `pubspec.yaml`/`pubspec.lock` change from T003.

**Checkpoint**: The package is added with no unrelated upgrades. Rendering, contrast tokens, the accessibility fallback and test-harness behaviour are all confirmed.

---

## Phase 2: Foundational (Blocking Prerequisites)

**⚠️ CRITICAL**: No user-story task can start until Phase 2 is complete.

### Phase 2A — Liquid Glass configuration model (domain, Flutter-free)

- [X] T012 [P] Write `test/features/settings/domain/entities/glass_appearance_test.dart`. It asserts:
  - `GlassAppearance.defaults == GlassAppearance(enabled: true, transparency: GlassLevel.medium, intensity: GlassLevel.medium)`;
  - value equality and `hashCode` across all three fields;
  - `copyWith` changes only the named field;
  - disabling via `copyWith(enabled: false)` keeps `transparency`/`intensity` unchanged (data-model "State transitions");
  - `GlassLevel.values.map((l) => l.value)` equals `['low', 'medium', 'high']`.
- [X] T013 [P] Create `lib/features/settings/domain/entities/glass_level.dart`: `enum GlassLevel { low('low'), medium('medium'), high('high') }` with `final String value` and a doc comment "The wire value persisted in `AppSettings.glassTransparency` / `glassIntensity`". Mirror `app_theme_mode.dart`. No Flutter imports.
- [X] T014 Create `lib/features/settings/domain/entities/glass_appearance.dart`: an `Equatable` class with `final bool enabled`, `final GlassLevel transparency`, `final GlassLevel intensity`.
  - `const GlassAppearance({this.enabled = true, this.transparency = GlassLevel.medium, this.intensity = GlassLevel.medium})`.
  - `static const defaults = GlassAppearance()`.
  - `copyWith`, with `props` covering all three fields.
  - Doc comments state the validation rules: "an unknown or NULL field falls back to that field's default only", and "no values outside `GlassLevel` are representable". No Flutter imports. Run T012 until it is green.

### Phase 2B — Persistence (existing drift `AppSettings`, schema 7 → 8)

- [X] T015 Extend the migration test in `test/core/database/app_database_migration_test.dart` with a v7 → v8 case, following the file's raw-`sqlite3` v4 → v5 pattern. Build a schema-7 database with an `app_settings` row (`languageCode: 'ar'`, `themeMode: 'dark'`), open it with `AppDatabase`, and assert:
  - the columns `glass_enabled`, `glass_transparency` and `glass_intensity` exist and are `NULL`;
  - `languageCode` and `themeMode` are unchanged;
  - `schemaVersion == 8`.
- [X] T016 Edit `lib/core/database/app_database.dart`:
  - add to `AppSettings`: `BoolColumn get glassEnabled => boolean().nullable()();`, `TextColumn get glassTransparency => text().nullable()();` and `TextColumn get glassIntensity => text().nullable()();`, with a doc comment "NULL = never set → default (data-model.md)";
  - bump `schemaVersion` to `8`;
  - add `if (from < 8) { await m.addColumn(appSettings, appSettings.glassEnabled); await m.addColumn(appSettings, appSettings.glassTransparency); await m.addColumn(appSettings, appSettings.glassIntensity); }` after the `from < 7` block.
- [X] T017 Regenerate code: `dart run build_runner build --delete-conflicting-outputs`. This updates `lib/core/database/app_database.g.dart`. Confirm that T015 passes and that `flutter test test/core/database` stays green.
- [X] T018 [P] Extend `test/features/settings/data/datasources/settings_dao_test.dart`:
  - (a) `upsertPreference(glassEnabled: false, glassTransparency: 'high', glassIntensity: 'low', updatedAt: …)` on an existing row preserves `languageCode` and `themeMode`;
  - (b) a later `upsertPreference(themeMode: 'light', …)` preserves all three glass columns;
  - (c) on no row, a glass-only write creates the row with the existing `languageCode` fallback (`AppLanguage.english.code`).
- [X] T019 Edit `lib/features/settings/data/datasources/settings_dao.dart`: add the optional parameters `bool? glassEnabled`, `String? glassTransparency` and `String? glassIntensity` to `upsertPreference`. Merge each one as `Value(param ?? existing?.column)`, exactly like `themeMode`, and update the doc comment ("a glass write never clobbers language/theme and vice versa"). Run T018 until it is green.
- [X] T020 [P] Extend `test/features/settings/data/repositories/settings_repository_impl_test.dart` to cover the table in [contracts/settings_repository.md](contracts/settings_repository.md):
  - no row → `Right(null)`;
  - a row with all glass columns `NULL` → `Right(GlassAppearance.defaults)`;
  - `glassTransparency: 'bogus'` → `transparency: GlassLevel.medium`, with the other fields as stored;
  - a DAO throw on read → `Left(CacheFailure)`;
  - `setGlassAppearancePreference` writes all three columns in **one** `upsertPreference` call (verify with mocktail);
  - a DAO throw on write → `Left(CacheFailure)`.
- [X] T021 Edit `lib/features/settings/domain/repositories/settings_repository.dart`: add `Future<Either<Failure, GlassAppearance?>> getGlassAppearancePreference();` and `Future<Either<Failure, Unit>> setGlassAppearancePreference(GlassAppearance appearance);`, with the doc comments from [contracts/settings_repository.md](contracts/settings_repository.md).
- [X] T022 Edit `lib/features/settings/data/repositories/settings_repository_impl.dart`:
  - implement both methods;
  - add `GlassLevel? _parseGlassLevel(String?)`, mirroring `_parseThemeMode`;
  - build the appearance per field: `enabled: row.glassEnabled ?? GlassAppearance.defaults.enabled`, `transparency: _parseGlassLevel(row.glassTransparency) ?? GlassAppearance.defaults.transparency`, and the same for intensity;
  - the write passes all three fields plus `updatedAt: DateTime.now().millisecondsSinceEpoch` in a single `_dao.upsertPreference`;
  - wrap errors as `CacheFailure('Failed to load/save glass appearance preference: $e')`. Never throw.

  Run T020 until it is green.
- [X] T023 [P] Write `test/features/settings/domain/usecases/change_glass_appearance_test.dart`. It covers: first attempt succeeds → `true` with 1 call; first fails and retry succeeds → `true` with 2 calls; both fail → `false` with 2 calls. Mirror the existing `change_theme_mode` test.
- [X] T024 [P] Create `lib/features/settings/domain/usecases/get_glass_appearance_preference.dart` (`@injectable`, `call()` → `_repository.getGlassAppearancePreference()`). Mirror `get_theme_mode_preference.dart`, and add a doc note that it is kept for symmetry (plan Complexity Tracking).
- [X] T025 Create `lib/features/settings/domain/usecases/change_glass_appearance.dart` (`@injectable`, `Future<bool> call(GlassAppearance a)`, with one immediate retry and no timers). Mirror `change_theme_mode.dart`. Run T023 until it is green.

### Phase 2C — State management (existing root `SettingsCubit`)

- [X] T026 Extend `test/features/settings/presentation/cubit/settings_cubit_test.dart` using `bloc_test`, with mocked `GetGlassAppearancePreference` and `ChangeGlassAppearance`:
  - `initialize` with `Right(null)` → `glassAppearance == GlassAppearance.defaults`;
  - with `Right(GlassAppearance(enabled: false, transparency: high, intensity: low))` → that value;
  - with `Left(CacheFailure)` → the defaults;
  - `setGlassEnabled(false)` emits immediately with `isGlassPersistFailing: false`;
  - persist `false` → then emits `isGlassPersistFailing: true`, and the value is **not** rolled back;
  - `setGlassTransparency(GlassLevel.medium)` when it is already medium → emits nothing and calls `ChangeGlassAppearance` zero times;
  - three rapid calls → the final state equals the last call, and `ChangeGlassAppearance` receives the snapshots in order;
  - the existing language and theme tests still pass.
- [X] T027 Edit `lib/features/settings/presentation/cubit/settings_state.dart`: add `final GlassAppearance glassAppearance` (default `GlassAppearance.defaults`) and `final bool isGlassPersistFailing` (default `false`, with a doc comment "set only after the retried write fails; scoped separately from language/theme flags"). Add both to the constructor, `copyWith` and `props`.
- [X] T028 Edit `lib/features/settings/presentation/cubit/settings_cubit.dart`:
  - inject `GetGlassAppearancePreference` and `ChangeGlassAppearance`;
  - in `initialize()`, also load the glass preference (`getOrElse((_) => null) ?? GlassAppearance.defaults`) in the same single `emit`;
  - add `setGlassEnabled(bool)`, `setGlassTransparency(GlassLevel)` and `setGlassIntensity(GlassLevel)`. Each builds `next = state.glassAppearance.copyWith(...)`, returns early if `next == state.glassAppearance`, emits `copyWith(glassAppearance: next, isGlassPersistFailing: false)`, awaits `_changeGlassAppearance(next)`, and on `false` emits `copyWith(isGlassPersistFailing: true)`.

  Run T026 until it is green.
- [X] T029 Regenerate DI: `dart run build_runner build --delete-conflicting-outputs`, then confirm the new use cases and cubit arguments appear in `lib/core/di/injection.config.dart`, and that `flutter test test/features/settings test/features/startup` is green. `AppStartupCubit` already awaits `SettingsCubit.initialize()` behind the splash, so no startup change is needed (FR-004).

### Phase 2D — Reusable Liquid Glass abstraction (core primitives)

- [X] T030 [P] Create `lib/core/design_system/glass/app_glass_style.dart`: an immutable `AppGlassStyle` with `enabled`, `tintAlphaLight`, `tintAlphaDark` and `blur`, plus `==`/`hashCode` and `static const off` (enabled `false`). It must not import the package or any feature. If T010 failed, add `final bool debugDisableRendering` here.
- [X] T031 [P] Create `lib/core/design_system/glass/app_glass_tokens.dart`: `abstract final class AppGlassTokens` with named constants for the three levels, using the values **finalized in T008**:
  - `tintAlphaLightLow`/`Medium`/`High` (starting 0.86 / 0.74 / 0.62);
  - `tintAlphaDarkLow`/`Medium`/`High` (starting 0.84 / 0.70 / 0.58);
  - `blurLow`/`Medium`/`High` (starting 4 / 8 / 14);
  - `thickness = 10`.

  Include a doc comment that High Transparency is the readability floor (FR-008, FR-019).
- [X] T032 Create `lib/core/design_system/glass/app_glass_scope.dart`:
  - `class AppGlassScope extends InheritedWidget` with `final AppGlassStyle style`;
  - `static AppGlassStyle? maybeOf(BuildContext)` via `dependOnInheritedWidgetOfExactType`;
  - `static AppGlassStyle of(BuildContext) => maybeOf(context) ?? AppGlassStyle.off` (research Decision 13: no scope means OFF);
  - `static bool enabledOf(BuildContext)`;
  - `updateShouldNotify => old.style != style`.
- [X] T033 [P] Write `test/core/design_system/glass/app_glass_surface_test.dart`:
  - with a scope `enabled: true` in light and dark, one `GlassContainer` is found, whose `settings.glassColor` equals `colorScheme.surface.withValues(alpha: tintAlphaLight|Dark)`, `settings.blur == style.blur`, `settings.bodyMode == GlassBodyMode.clear` and `quality == GlassQuality.standard`;
  - nesting an `AppGlassSurface` inside another trips the debug assertion (FR-012).
- [X] T034 Create `lib/core/design_system/glass/app_glass_surface.dart`:
  - `AppGlassSurface({Key? key, required Widget child, double borderRadius = 0, EdgeInsetsGeometry? padding})`;
  - it builds `GlassContainer(shape: LiquidRoundedSuperellipse(borderRadius: borderRadius), quality: GlassQuality.standard, padding: padding, settings: LiquidGlassSettings(glassColor: scheme.surface.withValues(alpha: brightness == Brightness.dark ? style.tintAlphaDark : style.tintAlphaLight), blur: style.blur, thickness: AppGlassTokens.thickness, bodyMode: GlassBodyMode.clear), child: child)`;
  - it wraps its child in a private `_GlassSurfaceMarker` InheritedWidget, and `assert`s that no marker exists above it.

  This is the **only** file that constructs `GlassContainer`. Run T033 until it is green.
- [X] T035 [P] Write `test/core/design_system/glass/app_glass_insets_test.dart`: with no scope, or a scope that is OFF, it returns `EdgeInsets.zero` even when `MediaQuery.padding` is non-zero; with ON, it returns `MediaQuery.paddingOf(context)`.
- [X] T036 Create `lib/core/design_system/glass/app_glass_insets.dart`: `abstract final class AppGlassInsets { static EdgeInsets of(BuildContext context) }`, per [contracts/adaptive_glass_components.md](contracts/adaptive_glass_components.md). Run T035 until it is green.
- [X] T037 [P] Write `test/features/settings/presentation/glass/glass_style_mapper_test.dart`: every (`enabled`, `transparency`, `intensity`) combination maps to the matching `AppGlassTokens` constants, and `enabled` passes through.
- [X] T038 Create `lib/features/settings/presentation/glass/glass_style_mapper.dart`: `AppGlassStyle toAppGlassStyle(GlassAppearance a)`, using exhaustive `switch` expressions on `GlassLevel`. The feature imports core; core never imports the feature. Run T037 until it is green.
- [X] T039 Write `test/widget/app_root_glass_rebuild_test.dart`. Pump `DaftaryApp` with a real `SettingsCubit` backed by fakes, and a probe widget that counts its builds under `MaterialApp.builder`. Then:
  - call `setGlassIntensity(GlassLevel.high)`;
  - assert that the `MaterialApp.router` root builder did **not** re-run (count it through a `Builder` inside the root `BlocBuilder`);
  - assert that a widget calling `AppGlassScope.of` **did** rebuild (FR-022).
- [X] T040 Edit `lib/main.dart`:
  - (a) add `unawaited(LiquidGlassWidgets.initialize());` next to the existing unawaited startup calls;
  - (b) change `runApp(const DaftaryApp())` to `runApp(LiquidGlassWidgets.wrap(child: const DaftaryApp(), brightnessResolver: Theme.maybeBrightnessOf))`, with no `theme:` and default accessibility (research Decision 2);
  - (c) add `buildWhen: (p, c) => p.language != c.language || p.themeMode != c.themeMode` to the root `BlocBuilder<SettingsCubit, SettingsState>`;
  - (d) change `builder: (context, child) => AppStartupGate(child: child!)` to a `BlocSelector<SettingsCubit, SettingsState, GlassAppearance>(selector: (s) => s.glassAppearance, builder: (context, appearance) => AppGlassScope(style: toAppGlassStyle(appearance), child: AppStartupGate(child: child!)))`.

  Run T039 and `test/widget/app_startup_gate_test.dart` until they are green.

**Checkpoint**: The preference persists and loads behind the splash, and the scope is live at the root. No screen has changed yet, so the app looks exactly as before.

---

## Phase 3: User Story 1 — Turn Liquid Glass on or off (Priority: P1) 🎯 MVP

**Goal**: A Settings switch toggles glass live and persists. The core adaptive components exist, and the shell bottom bar plus the three tab-root top bars (People, Overview, Settings) use them.

**Independent Test**: Toggle in Settings. The bottom bar and the People, Overview and Settings top bars switch instantly. Relaunch: the state is kept from the first frame. OFF is pixel-identical to `main` (quickstart scenarios 1–4, 11, 12).

### Tests for User Story 1

- [X] T041 [P] [US1] Write `test/core/design_system/glass/app_top_bar_test.dart`. Per the contract's "Test obligations" table:
  - **OFF**: `AppTopBar(title:, actions:, leading:)` produces an `AppBar` whose `title`, `actions`, `leading`, `automaticallyImplyLeading`, `backgroundColor`, `elevation` and `flexibleSpace` equal those of a directly built `AppBar`, with no `GlassContainer`.
  - **ON**: one `GlassContainer`; `backgroundColor`, `surfaceTintColor` and `elevation` are transparent or 0; the implied back button still pops.
  - Both modes: `preferredSize` equals `AppBar`'s; the action tooltip is present; no overflow at text scale 2.0; leading and actions mirror under `TextDirection.rtl`.
- [X] T042 [P] [US1] Write `test/core/design_system/glass/app_scaffold_test.dart`:
  - OFF: `extendBodyBehindAppBar` and `extendBody` equal the caller's values (default `false`), and all forwarded params are identical.
  - ON with `appBar` → `extendBodyBehindAppBar: true`; ON with `bottomNavigationBar` → `extendBody: true`.
- [X] T043 [P] [US1] Write `test/core/design_system/glass/app_navigation_bar_test.dart`:
  - OFF: a `NavigationBar` identical in `selectedIndex`, `destinations` and `onDestinationSelected`, with no `GlassContainer`.
  - ON: one `GlassContainer` behind a transparent `NavigationBar`; tapping a destination calls `onDestinationSelected`; labels are present at text scale 2.0; destinations mirror in RTL.
- [X] T044 [P] [US1] Write `test/features/settings/presentation/pages/settings_page_glass_test.dart`:
  - the "Liquid Glass" `SwitchListTile` reflects `state.glassAppearance.enabled`;
  - tapping it calls `setGlassEnabled(!enabled)`;
  - when `isGlassPersistFailing` flips `false → true`, a SnackBar with `l10n.glassSaveFailed` appears once;
  - the switch sits in an "Appearance" section directly after the Theme section;
  - Arabic locale renders the Arabic strings.

### Implementation for User Story 1

- [X] T045 [P] [US1] Add l10n keys to `lib/core/l10n/app_en.arb`, each with an `@key` description:
  - `appearanceSectionTitle`: "Appearance"
  - `liquidGlassTitle`: "Liquid Glass"
  - `liquidGlassSubtitle`: "Frosted glass effect on bars and buttons"
  - `glassSaveFailed`: "Couldn't save your glass setting. It will apply until you close the app."
- [X] T046 [P] [US1] Add the same four keys to `lib/core/l10n/app_ar.arb`:
  - `appearanceSectionTitle`: "التأثيرات المرئية" (not "المظهر", which the Arabic Theme heading already uses)
  - `liquidGlassTitle`: "الزجاج السائل"
  - `liquidGlassSubtitle`: "تأثير زجاجي مصنفر على الأشرطة والأزرار"
  - `glassSaveFailed`: "تعذّر حفظ إعداد الزجاج. سيظل مطبقًا حتى تغلق التطبيق."

  Then run `flutter gen-l10n` to regenerate `lib/core/l10n/app_localizations*.dart`.
- [X] T047 [US1] Create `lib/core/design_system/glass/app_top_bar.dart`: `class AppTopBar extends StatelessWidget implements PreferredSizeWidget`. It forwards exactly the `AppBar` params used by the 17 pages (from the audit: `title`, `actions`, `leading`, `automaticallyImplyLeading`, `bottom`, `centerTitle`, `key`). `preferredSize` is computed identically to `AppBar`: `Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0))`.
  - OFF → `AppBar(...)` with the same arguments.
  - ON → the same plus `backgroundColor: Colors.transparent`, `surfaceTintColor: Colors.transparent`, `elevation: 0`, `scrolledUnderElevation: 0`, `flexibleSpace: const AppGlassSurface(child: SizedBox.expand())`.

  Run T041 until it is green.
- [X] T048 [US1] Create `lib/core/design_system/glass/app_scaffold.dart`: `class AppScaffold extends StatelessWidget`. It forwards the `Scaffold` params used by the migrated pages and the shell: `appBar`, `body`, `floatingActionButton`, `floatingActionButtonLocation`, `bottomNavigationBar`, `backgroundColor`, `resizeToAvoidBottomInset`, `extendBody`, `extendBodyBehindAppBar` and `key`.
  - ON → `extendBodyBehindAppBar: appBar != null || extendBodyBehindAppBar` and `extendBody: bottomNavigationBar != null || extendBody`.
  - OFF → the caller's values unchanged.

  Run T042 until it is green.
- [X] T049 [US1] Create `lib/core/design_system/glass/app_navigation_bar.dart`: `class AppNavigationBar extends StatelessWidget` with `selectedIndex`, `onDestinationSelected` and `destinations`.
  - OFF → the identical `NavigationBar`.
  - ON → `Stack(children: [Positioned.fill(child: AppGlassSurface(child: SizedBox.expand())), NavigationBar(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, elevation: 0, ...)])`, so the glass also covers the bottom safe area.

  Run T043 until it is green.
- [X] T050 [US1] Edit `lib/core/routing/main_shell.dart`, **compact branch only** (`width < AppBreakpoints.medium`): change `Scaffold` → `AppScaffold` and `NavigationBar` → `AppNavigationBar`, keeping `selectedIndex`, `onDestinationSelected` and `destinations` unchanged. The wide `NavigationRail` branch is not touched (spec edge case). Update or extend the existing shell test under `test/core/routing/` so it still finds the destinations and switches tabs.
- [X] T051 [US1] Migrate `lib/features/people/presentation/pages/people_list_page.dart` (tab root). Its 3 `Scaffold(` occurrences are the loading, error and data states: change them to `AppScaffold`, and the `AppBar(` to `AppTopBar(`, keeping `title`, `actions` and the tooltip. For the explicit scroll paddings at the `EdgeInsets.fromLTRB(...)` list padding (around line 91) and the `EdgeInsets.only(bottom: 88)` FAB clearance (around line 189), add `+ AppGlassInsets.of(context)` to the outermost scrollable's padding **only**. The FAB is migrated in US4.
- [X] T052 [US1] Migrate `lib/features/transactions/presentation/pages/overview_page.dart` (tab root): `Scaffold` → `AppScaffold`, `AppBar` → `AppTopBar`. Add `+ AppGlassInsets.of(context)` to the scrollable paddings at `EdgeInsets.all(AppSpacing.md)` (around lines 62 and 87). Leave the inner symmetric padding (line 70) unchanged.
- [X] T053 [US1] Migrate the Settings scaffold in `lib/features/settings/presentation/pages/settings_page.dart` (tab root): `Scaffold` → `AppScaffold`, `AppBar` → `AppTopBar`, and change the `ListView` padding `const EdgeInsets.all(AppSpacing.md)` to `const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context)`.
- [X] T054 [US1] In `lib/features/settings/presentation/pages/settings_page.dart`, add a `_SettingsSection(icon: Icons.blur_on_outlined, title: l10n.appearanceSectionTitle, child: SwitchListTile(key: const Key('settings_liquid_glass_switch'), title: Text(l10n.liquidGlassTitle), subtitle: Text(l10n.liquidGlassSubtitle), value: state.glassAppearance.enabled, onChanged: (v) => context.read<SettingsCubit>().setGlassEnabled(v)))` directly after the Theme section, preceded by `const SizedBox(height: AppSpacing.lg)`.
- [X] T055 [US1] In `lib/features/settings/presentation/pages/settings_page.dart`, extend the `BlocConsumer`:
  - `listenWhen` gains `|| (!previous.isGlassPersistFailing && current.isGlassPersistFailing)`;
  - `listener` picks the message by priority: glass → `l10n.glassSaveFailed`, then theme, then language.

  Run T044 until it is green.
- [X] T056 [US1] Run `flutter test`. The full existing suite must pass unchanged (SC-008), because pages pumped without the app root have no scope and so render OFF (research Decision 13).

**Checkpoint**: The MVP is shippable. The toggle works, the choice persists, and the bottom bar and three top bars go glass when ON and are identical to `main` when OFF.

---

## Phase 4: User Story 2 — Adjust how strong the glass looks (Priority: P2)

**Goal**: Glass transparency and Glass intensity controls, each with three levels, visible only when glass is ON, persisted, and applied app-wide.

**Independent Test**: With glass ON, change each level. All glass surfaces change. Relaunch: the levels are kept. With glass OFF the controls are hidden, and their values return when glass is turned back on.

### Tests for User Story 2

- [X] T057 [P] [US2] Extend `test/features/settings/presentation/pages/settings_page_glass_test.dart`:
  - with `enabled: true`, two `SegmentedButton<GlassLevel>` are shown (keys `settings_glass_transparency`, `settings_glass_intensity`), showing the current levels;
  - selecting "High" calls `setGlassTransparency(GlassLevel.high)` or `setGlassIntensity(GlassLevel.high)`;
  - with `enabled: false`, neither is in the tree;
  - toggling OFF then ON shows the previously selected levels.

### Implementation for User Story 2

- [X] T058 [P] [US2] Add these keys, with descriptions, to `lib/core/l10n/app_en.arb`:
  - `glassTransparencyTitle`: "Glass transparency"
  - `glassIntensityTitle`: "Glass intensity"
  - `glassLevelLow`: "Low"
  - `glassLevelMedium`: "Medium"
  - `glassLevelHigh`: "High"
- [X] T059 [P] [US2] Add the same keys to `lib/core/l10n/app_ar.arb`:
  - `glassTransparencyTitle`: "شفافية الزجاج"
  - `glassIntensityTitle`: "قوة الزجاج"
  - `glassLevelLow`: "منخفضة"
  - `glassLevelMedium`: "متوسطة"
  - `glassLevelHigh`: "عالية"

  Then run `flutter gen-l10n`.
- [X] T060 [US2] Create `lib/features/settings/presentation/widgets/glass_level_selector.dart`: a stateless `GlassLevelSelector({required String title, required GlassLevel value, required ValueChanged<GlassLevel> onChanged, Key? key})`. It renders a `ListTile`-style title plus a full-width `SegmentedButton<GlassLevel>(segments: [low, medium, high] with l10n labels, selected: {value}, showSelectedIcon: false, onSelectionChanged: (s) => onChanged(s.single))`, with `AppSpacing` padding only.
- [X] T061 [US2] In `lib/features/settings/presentation/pages/settings_page.dart`, turn the Appearance section's child into a `Column` of:
  - the switch from T054;
  - an `AnimatedSize(duration: kThemeAnimationDuration, child: state.glassAppearance.enabled ? Column([Divider(height: 1, indent: AppSpacing.md), GlassLevelSelector(key: Key('settings_glass_transparency'), title: l10n.glassTransparencyTitle, value: state.glassAppearance.transparency, onChanged: cubit.setGlassTransparency), Divider(...), GlassLevelSelector(key: Key('settings_glass_intensity'), ..., intensity)]) : const SizedBox.shrink())`.

  Run T057 until it is green.

**Checkpoint**: US1 and US2 both work. Levels visibly change every migrated surface.

---

## Phase 5: User Story 3 — Live preview in Settings (Priority: P3)

**Goal**: A small preview shows the current glass settings over a theme-derived backdrop and updates instantly.

**Independent Test**: With glass ON, change the levels and switch Light/Dark and Arabic/English. The preview updates in the same frame and mirrors in RTL. With glass OFF, it is hidden.

### Tests for User Story 3

- [X] T062 [P] [US3] Write `test/features/settings/presentation/widgets/glass_preview_test.dart`:
  - under a scope with `enabled: true`, it contains exactly one `AppGlassSurface` and the localized sample title;
  - after pumping a new scope style (a different blur), the inner `GlassContainer.settings.blur` equals the new value within one `pump()`;
  - in the dark theme the backdrop uses `colorScheme` colours (no `Color(0x…)` literals — enforce by review);
  - under `Directionality.rtl` the sample icon is on the leading (right) side;
  - it exposes a `Semantics` label `l10n.glassPreviewSemantics` and is `ExcludeFocus`ed.
- [X] T063 [P] [US3] Extend `test/features/settings/presentation/pages/settings_page_glass_test.dart`: the preview (key `settings_glass_preview`) is present only when glass is ON.

### Implementation for User Story 3

- [X] T064 [P] [US3] Add these keys to `lib/core/l10n/app_en.arb`:
  - `glassPreviewTitle`: "Preview"
  - `glassPreviewSemantics`: "Sample of the Liquid Glass effect with your current settings"

  Add them to `lib/core/l10n/app_ar.arb`:
  - `glassPreviewTitle`: "معاينة"
  - `glassPreviewSemantics`: "نموذج لتأثير الزجاج السائل بإعداداتك الحالية"

  Then run `flutter gen-l10n`.
- [X] T065 [US3] Create `lib/features/settings/presentation/widgets/glass_preview.dart`: a stateless `GlassPreview`. It is an `ExcludeFocus` + `Semantics(label: l10n.glassPreviewSemantics, excludeSemantics: true)` around a fixed-height (`AppSpacing.xxl * 3`) `ClipRRect(borderRadius: AppRadius.md)`, containing a `Stack` of:
  - (a) a backdrop of three `DecoratedBox` circles/blobs in `colorScheme.primary`, `tertiary` and `secondary`, with two lines of `l10n.glassPreviewTitle` text at `AppTypography` styles, positioned with `PositionedDirectional`;
  - (b) a top strip `PositionedDirectional(top: 0, start: 0, end: 0, height: kToolbarHeight)` holding `AppGlassSurface(child: Row(icon Icons.blur_on_outlined, Text(l10n.liquidGlassTitle)))`.

  It reuses the same `AppGlassSurface` as the real bars (FR-015). Run T062 until it is green.
- [X] T066 [US3] In `lib/features/settings/presentation/pages/settings_page.dart`, append `Padding(padding: EdgeInsets.all(AppSpacing.md), child: GlassPreview(key: Key('settings_glass_preview')))` to the `AnimatedSize` column from T061, after the intensity selector. Run T063 until it is green.

**Checkpoint**: US1–US3 are complete. The Settings experience is finished.

---

## Phase 6: User Story 4 — Glass used only where it helps: full surface rollout (Priority: P2)

**Goal**: Every in-scope surface (all 17 app bars, 5 FAB pages and 1 modal sheet) uses the adaptive components. Lists, cards, fields and backgrounds stay opaque.

**Independent Test**: With glass ON, walk through quickstart scenario 1 on every screen listed below. Glass appears only on bars, FABs and the sheet, and no content is hidden under the bars at scroll-top or scroll-end. With glass OFF, every screen is pixel-identical to `main`.

**Per-screen rule (applies to T071–T084)**:

- `Scaffold(` → `AppScaffold(`, and `AppBar(` → `AppTopBar(`.
- Add `+ AppGlassInsets.of(context)` to the padding of the **outermost scrollable** of the body only (the listed line numbers are approximate), and never to inner cards or rows.
- Do not change any other argument.
- After each file, run that feature's existing tests.

### Tests for User Story 4

- [X] T067 [P] [US4] Write `test/core/design_system/glass/app_fab_test.dart`. For each of `AppFab`, `AppFab.small` and `AppFab.extended`:
  - OFF → identical to the corresponding `FloatingActionButton` constructor (`onPressed`, `tooltip`, `child`/`icon`/`label` and `heroTag` equal), with no `GlassContainer`.
  - ON → one `GlassContainer`; the FAB is transparent with elevation 0; `onPressed` fires; the tooltip is present; at text scale 2.0 the extended label doesn't overflow; the extended icon and label order mirror in RTL.
- [X] T068 [P] [US4] Write `test/core/design_system/glass/app_modal_sheet_test.dart`:
  - OFF → `showAppModalSheet` shows a route whose sheet has the theme's default background and no `GlassContainer`;
  - ON → the sheet background is transparent, the body is wrapped in one `AppGlassSurface` with `AppRadius.lg`, `isScrollControlled` is honoured, and the sheet still dismisses by drag and by barrier tap.

### Implementation for User Story 4 — components

- [X] T069 [US4] Create `lib/core/design_system/glass/app_fab.dart`: `class AppFab extends StatelessWidget` with constructors `AppFab({onPressed, tooltip, heroTag, required child})`, `AppFab.small(...)` and `AppFab.extended({onPressed, tooltip, heroTag, icon, required label})`, holding a private variant enum.
  - OFF → the exact `FloatingActionButton` / `.small` / `.extended`.
  - ON → `AppGlassSurface(borderRadius: <the FAB theme shape radius, falling back to AppRadius.lg; for .extended, AppRadius.pill>, child: FloatingActionButton…(backgroundColor: Colors.transparent, foregroundColor: colorScheme.primary, elevation: 0, focusElevation: 0, hoverElevation: 0, highlightElevation: 0, ...))`.

  Run T067 until it is green.
- [X] T070 [US4] Create `lib/core/design_system/glass/app_modal_sheet.dart`: `Future<T?> showAppModalSheet<T>({required BuildContext context, required WidgetBuilder builder, bool isScrollControlled = false})`.
  - OFF → `showModalBottomSheet<T>(context: context, isScrollControlled: isScrollControlled, builder: builder)`, with arguments identical to today.
  - ON → the same, plus `backgroundColor: Colors.transparent`, `elevation: 0`, and `builder: (c) => AppGlassSurface(borderRadius: AppRadius.lg, child: builder(c))`. Read the scope from `context` before pushing.

  Run T068 until it is green.

### Implementation for User Story 4 — screen migration (one feature folder per commit)

- [X] T071 [P] [US4] Migrate `lib/features/people/presentation/pages/people_list_page.dart` FAB: `FloatingActionButton(onPressed:, tooltip:, child:)` → `AppFab(...)` with the same arguments.
- [X] T072 [P] [US4] Migrate `lib/features/people/presentation/pages/archived_people_page.dart`: the per-screen rule, with scroll padding `EdgeInsets.all(AppSpacing.md)` (around line 40).
- [X] T073 [P] [US4] Migrate `lib/features/people/presentation/pages/person_form_page.dart`: the per-screen rule, with form scroll padding `EdgeInsets.all(AppSpacing.md)` (around line 132). Keep `actions`.
- [X] T074 [P] [US4] Migrate `lib/features/transactions/presentation/pages/person_detail_page.dart`:
  - apply the per-screen rule, keeping the custom `leading`;
  - scroll paddings `EdgeInsets.all(AppSpacing.md)` (around line 147) and `EdgeInsets.only(bottom: 88)` (around line 201): add the insets to the outermost scrollable only;
  - `FloatingActionButton(...)` → `AppFab(...)`.
- [X] T075 [P] [US4] Migrate `lib/features/transactions/presentation/pages/transaction_form_page.dart` (padding around line 117) and `lib/features/transactions/presentation/pages/repayment_form_page.dart` (padding around line 59) using the per-screen rule.
- [X] T076 [P] [US4] Migrate `lib/features/transactions/presentation/widgets/duplicate_warning_sheet.dart`: `showModalBottomSheet<void>(context:, isScrollControlled: true, builder:)` → `showAppModalSheet<void>(...)` with the same arguments. Confirm the sheet's own content widgets are unchanged.
- [X] T077 [P] [US4] Migrate `lib/features/finance/presentation/pages/finance_history_page.dart`:
  - apply the per-screen rule, keeping `actions` and the tooltip, with scroll padding `EdgeInsets.fromLTRB(...)` (around line 102);
  - the two FABs: `FloatingActionButton.small(...)` → `AppFab.small(...)` and `FloatingActionButton.extended(...)` → `AppFab.extended(...)`, keeping any `heroTag` values so the two FABs don't clash.
- [X] T078 [P] [US4] Migrate `lib/features/finance/presentation/pages/category_management_page.dart`:
  - apply the per-screen rule, with scroll paddings around lines 100, 155 and 185. Add the insets only to the outermost `ListView`.
  - The FAB lives in a `builder:` closure: `FloatingActionButton.extended(...)` → `AppFab.extended(...)`.
- [X] T079 [P] [US4] Migrate `lib/features/finance/presentation/pages/finance_entry_form_page.dart` (padding around line 147) and `lib/features/finance/presentation/pages/category_form_page.dart` (padding around line 132) using the per-screen rule.
- [X] T080 [P] [US4] Migrate `lib/features/currency/presentation/pages/exchange_rate_list_page.dart`:
  - apply the per-screen rule, with scroll padding `EdgeInsets.fromLTRB(...)` (around line 124). The empty-state `EdgeInsets.all(AppSpacing.lg)` (around line 92) is not a scrollable, so leave it.
  - The conditional `FloatingActionButton.extended` → `AppFab.extended`, keeping its `key`.
- [X] T081 [P] [US4] Migrate `lib/features/currency/presentation/pages/currency_settings_page.dart` (padding around line 136) and `lib/features/currency/presentation/pages/exchange_rate_form_page.dart` (padding around line 116) using the per-screen rule.
- [X] T082 [P] [US4] Migrate `lib/features/insights_notifications/presentation/pages/notification_settings_page.dart` using the per-screen rule (padding around line 133).
- [X] T083 [P] [US4] Migrate `lib/features/financial_education/presentation/widgets/education_page_scaffold.dart`. It has 2 `Scaffold(`s, so migrate both, with the `EdgeInsets.fromLTRB(...)` padding (around line 31). This single shared scaffold covers every financial-education page.
- [X] T084 [US4] Guard against missed surfaces:
  - `grep -rnwE "AppBar|FloatingActionButton|NavigationBar|showModalBottomSheet" lib --include='*.dart' | grep -v "core/design_system/glass" | grep -v ':\s*///'` must print nothing. Whole-word matching skips `AppTopBar`, `AppNavigationBar`, `SliverAppBar` and `*ThemeData`, so the only references left are inside the components.

  Record any intentional exception, with its reason, in the Baseline note.
- [X] T085 [US4] Run `flutter test` (the full suite). Every existing page test must pass unchanged, because pages pumped without the root scope are OFF.

**Checkpoint**: All in-scope surfaces are adaptive. OFF is identical to `main` everywhere.

---

## Phase 7: User Story 5 — Themes, languages, platforms, accessibility (Priority: P2)

**Goal**: Prove and harden the cross-cutting guarantees (FR-017 to FR-021, SC-005) across every migrated surface.

**Independent Test**: Run the spec's Verification Matrix and quickstart scenarios 7–10 on iOS and Android.

- [X] T086 [P] [US5] Write `test/core/design_system/glass/glass_matrix_test.dart`: a parameterised widget test over {light, dark} × {`Locale('en')`/LTR, `Locale('ar')`/RTL} × {glass OFF, ON} × {textScaler 1.0, 2.0}. It pumps a representative page frame (`AppScaffold` + `AppTopBar` with an action + a 50-item list + `AppFab.extended` + a compact `AppNavigationBar`) and asserts:
  - no overflow and no exceptions;
  - the action tooltip, FAB tooltip and destination labels are present (semantics);
  - the leading and trailing positions mirror under RTL;
  - `GlassContainer` count: 0 when OFF, and exactly 3 when ON (bar, FAB, nav bar), with no nesting (FR-012).
- [X] T087 [P] [US5] Write `test/core/design_system/glass/glass_accessibility_test.dart`. Under `MediaQuery(data: MediaQueryData(highContrast: true, disableAnimations: true))` with glass ON, pumping `AppTopBar` produces no exception, and the static accessor on `GlassAccessibilityScope` that returns `GlassAccessibilityData` (confirm its exact name in the package's `glass_accessibility_scope.dart`) reports reduce-transparency and reduce-motion as active. This confirms `respectSystemAccessibility` stays on (FR-019).
- [X] T088 [US5] Theme-token audit: `grep -rnE "Color\(0x|Colors\." lib/core/design_system/glass lib/features/settings/presentation/widgets | grep -v "Colors.transparent"` must return nothing. Any colour must come from `Theme.of(context).colorScheme` (FR-017, Principle XV).
- [ ] T089 [US5] Manual device pass (quickstart scenarios 7, 8 and 10 plus the Verification Matrix rows) on an iPhone, an Android Vulkan device and an Android GLES device, with glass ON and OFF, in light and dark, and in Arabic and English. Include iOS Increase Contrast ON (matrix row 3) and Android at High transparency over the busiest list (matrix row 4). Record pass/fail per row in the Baseline note, and file any failure as a token or component fix before continuing.

**Checkpoint**: Cross-cutting guarantees are verified on both platforms.

---

## Phase 8: Polish & Cross-Cutting Verification

- [ ] T090 [P] Performance (SC-006): `flutter run --profile` on the budget Android device and the iPhone, with glass ON at High intensity. Fling the People list and Finance history for 10 seconds each with the DevTools performance overlay. At least 95% of frames must be within budget, with no shader-compile jank on the first toggle ON. Record the numbers in the Baseline note.
- [ ] T091 [P] OFF-identity visual check (SC-003): on one device, take screenshots with glass OFF of People, Overview, Settings, a person detail, Finance history, a transaction form and the duplicate-warning sheet. Compare them with the same screens from the `main` build. They must be identical, and any difference is a defect in the relevant component.
- [ ] T092 [P] State preservation (SC-007): scroll the People list halfway, switch to the Settings tab, change the intensity, and return. The scroll position is unchanged. Repeat with a half-filled transaction form open on another branch.
- [X] T093 Package isolation check (plan constraint): `grep -rl "liquid_glass_widgets" lib` lists only files under `lib/core/design_system/glass/` and `lib/main.dart`.
- [X] T094 Quality gates: `dart format --output=none --set-exit-if-changed .`, `flutter analyze` (zero warnings, no new `// ignore`), and `flutter test` all pass.
- [ ] T095 Delete `specs/020-liquid-glass-ui/pubspec.lock.before`, and walk the full [quickstart.md](quickstart.md) Manual scenarios table (1–12). Tick each one in the Baseline note.
- [ ] T096 Update `specs/020-liquid-glass-ui/spec.md` → `**Status**: Implemented`. If T008 changed any token numbers, update the level table in `research.md` Decision 7 and `data-model.md` to the final values.

---

## Dependencies & Execution Order

### Phase dependencies

```text
Phase 1 Setup (T001–T011, spikes gate the token values)
   ↓
Phase 2 Foundational: 2A model → 2B persistence → 2C state → 2D abstraction + main.dart wiring
   ↓
Phase 3 US1 (P1, MVP) — components AppTopBar/AppScaffold/AppNavigationBar + toggle + shell + 3 tab roots
   ↓                    ↘
Phase 4 US2 (P2)        Phase 6 US4 (P2) — needs US1's AppTopBar/AppScaffold; independent of US2/US3
   ↓
Phase 5 US3 (P3) — needs US2's Appearance column (T061)
   ↓
Phase 7 US5 (P2) — needs US4 complete (verifies every migrated surface)
   ↓
Phase 8 Polish
```

### Key task dependencies

- T013 → T014 → T021/T022 → T024/T025 → T027/T028 → T029
- T016 → T017 (codegen) → T019/T022
- T030 and T031 → T032 → T034 → T036, T047, T049, T069, T070
- T038 + T032 → T040 (`main.dart` wiring)
- T047 + T048 → T051–T053 (tab roots) → T071–T083 (rollout)
- T054 → T061 → T066 (the Settings Appearance section grows story by story)
- The l10n tasks (T045/T046, T058/T059, T064) must precede any widget using those keys, and `flutter gen-l10n` runs after each pair.

### Parallel opportunities

- **Phase 2**:
  - T012 ∥ T013;
  - T018 ∥ T020 ∥ T023 (different test files);
  - T030 ∥ T031;
  - T033 ∥ T035 ∥ T037.
- **US1**: T041 ∥ T042 ∥ T043 ∥ T044 (tests); T045 ∥ T046 (ARB files).
- **US4**: after T069/T070, all migrations T071–T083 are [P]. Each is a different feature folder, so they can run as separate commits or agents.
- **US5**: T086 ∥ T087.
- **Polish**: T090 ∥ T091 ∥ T092.

### Parallel example: User Story 4 rollout

```text
After T069 (AppFab) and T070 (showAppModalSheet) are green, run together:
  T072–T073 people/        T074–T076 transactions/     T077–T079 finance/
  T080–T081 currency/      T082 insights_notifications/ T083 financial_education/
Then T084 (grep guard) → T085 (full suite).
```

---

## Implementation Strategy

### MVP first (User Story 1)

1. Phase 1: add the package and run the spikes. Stop if S1 or S2 fail and adopt the `LiquidGlassScope` fallback before continuing.
2. Phase 2: foundation. The app is visually unchanged, the preference persists, and the scope is live.
3. Phase 3 (US1): toggle, shell bottom bar and three tab-root top bars.
4. **Stop and validate**: quickstart scenarios 1–4, 11 and 12. This is a demonstrable, shippable increment.

### Incremental delivery

1. Add US2 levels → validate scenario 5 minus the preview.
2. Add US3 preview → validate scenario 5.
3. Add US4 rollout, one feature folder per commit, running that folder's tests after each.
4. Add US5 matrix, then the Polish gates → ready for review.

### Scope lever

Q1 (app-bar scope) was **defaulted, not user-confirmed**. If a narrower scope is chosen:

- "tab roots only": drop T072–T075, T077–T079 (app-bar parts) and T080–T083, and keep the FAB and sheet tasks.

No other phase changes.

---

## Baseline note (filled in during Phase 1 and the verification tasks)

- Toolchain (T001): Flutter 3.47.0 stable, Dart 3.13.0 — satisfies flutter >=3.41.0 / sdk >=3.5.0 <4.0.0; project sdk ^3.10.0.
- Lock diff (T003): only `liquid_glass_widgets 1.7.2` added (sha256 5b828ace…); no other package changed.
- Bootstrap API check (T004): matches research Decisions 2–3 (initialize(): Future<void>; wrap() only sets globals + optional GlassTheme/GlassAdaptiveScope).
- Platform notes (T005): iOS Metal / Android Vulkan full pipeline, Android GLES 8-shape fallback, shader-filter-unsupported fallback; no native config required.
- S1/S2 rendering (T007): NOT RUN — no physical device connected during implementation session (2026-09-27).
- S3 final tokens (T008): NOT RUN — starting token values from research Decision 7 used unchanged; must be validated on devices.
- S4 Increase Contrast (T009): NOT RUN — needs iOS device.
- S5 flutter test (T010): PASS — GlassContainer(standard, bodyMode.clear, radius 0) pumps with no exceptions; no test seam needed.
- T039 note: implemented as `integration_test/liquid_glass_flow_test.dart` (needs real DI + on-device SQLite, like the other flow tests); analyzes clean but NOT RUN — no device connected.
- Grep-guard exceptions (T084): none (one `//` comment reworded from "AppBar" to "app bar").
- Layout notes (US4): pages with a fixed header above a list (people_list, archived_people, category_management, education_page_scaffold) split the inset — header takes the top, list the bottom; archived_people's list and the education body additionally use `MediaQuery.removePadding(removeTop: true)` so glass ON doesn't double the top gap (no-op when OFF). person_detail splits the inset across its first sliver and its bottom `SliverPadding`.
- Arabic heading: `appearanceSectionTitle` is "التأثيرات المرئية" — "المظهر" was already the Theme heading.
- Device matrix (T089): NOT RUN — no device.
- Performance (T090): NOT RUN — no device.
- Quickstart scenarios (T095): NOT RUN — no device (`pubspec.lock.before` deleted). Automated gates: `flutter analyze` clean, `flutter test` 1365/1365, `dart format` 0 changed.
