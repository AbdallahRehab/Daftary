# Phase 0 Research: Arabic/English Localization + Language Switch

All Technical Context unknowns are resolved below — none were marked `NEEDS CLARIFICATION`. Every product-facing ambiguity (Settings entry point, numeral script, persistence-failure UX) was already resolved in the spec's own Clarifications session; this document resolves the remaining *technical* decisions needed to start Phase 1 design, building on the stack and conventions feature 001 already established.

## 1. Bottom navigation with preserved per-tab state: `StatefulShellRoute.indexedStack` vs. manual `IndexedStack` vs. separate `Navigator`s

**Decision**: `go_router`'s `StatefulShellRoute.indexedStack`, with three branches — People (home), Overview, Settings — replacing the current flat list of 11 `GoRoute`s (regrouped under branches, no paths removed).

**Rationale**: The spec's clarified entry point (a bottom nav tab) combined with FR-014 ("changing language MUST NOT discard the user's current navigation position") means switching tabs — and switching language while on a tab — must not reset that tab's own navigation stack (e.g. leaving a pushed `PersonDetailPage` and returning to Settings must not lose it). `StatefulShellRoute.indexedStack` is `go_router`'s first-party, constitution-compatible ("centralized, declarative routing strategy," Engineering & Quality Standards: Navigation) answer to exactly this: each branch keeps its own `Navigator`/state automatically, with zero custom state-preservation code.

**Alternatives considered**: A manual `IndexedStack` of three independently-built subtrees with `go_router` routing only inside the top-level shell (rejected — reinvents what `StatefulShellRoute` already does correctly, and risks subtly wrong back-button/deep-link behavior since it isn't router-aware); giving each tab its own top-level `Navigator` wired by hand outside `go_router` (rejected — a second, competing navigation mechanism alongside the existing centralized `go_router` setup, against the Navigation standard's "navigation decisions MUST NOT be duplicated").

## 2. Broadcasting the active language app-wide: root-scoped `SettingsCubit` vs. `InheritedWidget`/`Provider` vs. a `get_it`-exposed stream read directly in `main.dart`

**Decision**: A single `SettingsCubit` (still `flutter_bloc`, per Principle III), provided once via `BlocProvider` above `MaterialApp.router` in `main.dart`, with `MaterialApp.router`'s `locale:` parameter bound to `BlocBuilder<SettingsCubit, SettingsState>`'s `state.language`.

**Rationale**: Flutter's own `Localizations`/`Directionality` machinery already rebuilds the whole subtree — including RTL mirroring — whenever `MaterialApp`'s `locale` argument changes; no extra plumbing is needed to make the switch "live" (FR-004) beyond making that one argument reactive to state. Keeping it a `Cubit` (just root-scoped instead of per-screen, unlike every other Cubit in this app so far) satisfies Principle III without introducing a second state-management paradigm — it is the same tool used everywhere else, only with app-lifetime scope, which is a normal and well-precedented `flutter_bloc` pattern for cross-cutting app state (locale/theme).

**Alternatives considered**: A plain `InheritedWidget`/`ChangeNotifier`+`Provider` pair (rejected — `Provider` is not used anywhere in this codebase and would be a second state-management mechanism alongside BLoC, which Principle III prohibits without documented justification that doesn't exist here); reading a `get_it`-registered `Stream<AppLanguage>` directly with a `StreamBuilder` in `main.dart`, bypassing Cubit (rejected — throws away the state-lifecycle/testability guarantees (loading/failure, `bloc_test`) Principle III and XVI expect from presentation-layer state).

## 3. Persisting the language preference: new Drift table vs. `shared_preferences` vs. a file

**Decision**: A new single-row `AppSettings` table in the existing `AppDatabase` (Drift), bumping `schemaVersion` from 1 to 2 and adding the app's first explicit `MigrationStrategy` (none existed before — schema was create-only at v1).

**Rationale**: The app already has exactly one persistence technology (Drift/SQLite) and the constitution's "reuse existing architecture" expectation (also stated directly in the source roadmap's Global Rules) argues against introducing a second one (`shared_preferences`) purely to store one value. A single-row table with an upsert DAO is a well-understood Drift pattern, keeps `SettingsRepository` symmetric with `PeopleRepository`/`TransactionsRepository` (same Repository-over-DAO shape, Principle VI), and means this is also the point where the app's migration story has to start being real — a low-risk, low-scope place to add it for the first time.

**Alternatives considered**: `shared_preferences` (rejected — a new dependency and a second persistence mechanism for a single value the existing database can hold just as easily; would also mean two different places a future "export all my data" or "reset app" feature would need to look); writing a raw JSON/plist file to app storage (rejected — reinvents transactional writes and error handling Drift already provides, for no benefit).

## 4. First-launch default language: device locale via injected `DeviceLocaleProvider` vs. reading `PlatformDispatcher` directly in the Cubit vs. always defaulting to English

**Decision**: A small `DeviceLocaleProvider` abstraction in `core/device/`, backed by `WidgetsBinding.instance.platformDispatcher.locale`, injected into `SettingsCubit` via `get_it`/`injectable` — used only when no persisted preference exists yet (FR-009: prefer the device's system language when it's Arabic or English, else English).

**Rationale**: `PlatformDispatcher` is a Flutter-framework type. Principle I keeps Domain Flutter-free, and reading it directly inside a Cubit (Presentation) would still be fine architecturally, but would make `SettingsCubit`'s first-launch-default branch impossible to unit test without a real Flutter binding. Wrapping it behind a one-method interface and injecting it (Principle XIV: DI everywhere, "nothing self-instantiates a dependency") keeps that branch trivially fakeable in `bloc_test`, consistent with how every other platform-adjacent dependency in this app (the DB, the connectivity service pattern implied by Principle XI) is handled.

**Alternatives considered**: Reading `PlatformDispatcher.instance.locale` inline in `SettingsCubit` (rejected — works, but couples a unit test to `TestWidgetsFlutterBinding` for no real benefit over a one-line fake); always defaulting to English regardless of device locale (rejected — the spec's FR-009 explicitly requires preferring the device's Arabic/English system language when present, since that's the far better first-run experience for an Arabic-speaking user with an Arabic-language phone).

## 5. Forcing Western Arabic numerals (0-9) under the Arabic locale

**Decision**: Use ICU's `_u_nu_latn` Unicode locale extension — `NumberFormat.currency(locale: 'ar_u_nu_latn', ...)` / `NumberFormat.decimalPattern('ar_u_nu_latn')` / `DateFormat.yMd('ar_u_nu_latn')` — wherever a value is formatted under the Arabic locale, instead of plain `'ar'`. `EgpFormatter` and the new `AppDateFormatter` both resolve their effective `intl` locale string through one small helper so this rule lives in exactly one place.

**Rationale**: `intl`'s CLDR data formats numbers with Eastern Arabic-Indic digits (٠-٩) for the bare `'ar'` locale by default, which the spec's Clarifications session explicitly rejected in favor of Western digits (0-9) for this financial app, matching the roadmap's currency/number requirements. `nu-latn` (`_u_nu_latn` in `intl`'s locale-string form) is the standard, first-party ICU mechanism for "use this locale's other conventions (grouping, decimal marks, currency placement) but Western digits" — no manual digit-substitution or extra dependency needed.

**Alternatives considered**: Formatting with `'ar'` and then string-replacing Eastern digits back to Western ones after the fact (rejected — fragile, duplicates logic already solved correctly one layer down by ICU, and risks missing a code path); the existing `NumeralParser.toWesternDigits` utility (rejected for *output* formatting — it exists for normalizing *user-typed input* before parsing, Decision 9 in feature 001's research; reusing it here would mean formatting with Eastern digits first and immediately undoing it, strictly more work than not producing them in the first place).

## 6. RTL mirroring of the bottom navigation bar itself (FR-003)

**Decision**: Use Flutter Material's built-in `NavigationBar`/`NavigationDestination` widgets for the three tabs, inside the existing `Directionality` Flutter's `Localizations`/`MaterialApp` already establishes from the active `locale`. No custom mirroring logic.

**Rationale**: Material widgets, including `NavigationBar`, already lay themselves out according to the ambient `Directionality` — tab order and icon placement mirror automatically once the surrounding `Directionality` is RTL, the same mechanism that already mirrors every other Material widget in the app today. This is a "verify it behaves correctly," not a "build it," requirement.

**Alternatives considered**: A hand-built bottom bar with manually swapped `Row` children based on `Directionality.of(context)` (rejected — unnecessary custom code duplicating what `NavigationBar` already does correctly, and a maintenance burden if a 4th tab is ever added).

## 7. Persistence-failure retry policy (FR-008, Clarifications)

**Decision**: `ChangeLanguage`'s Cubit-level caller (`SettingsCubit.changeLanguage`) emits the new language immediately, then calls the repository; on failure it retries the repository call exactly once, synchronously (no timer/delay); if that second attempt also fails, it emits `SettingsState.isPersistFailing = true`, which `SettingsPage` surfaces as a small non-blocking banner/snackbar.

**Rationale**: The spec's Clarifications answer is "retry the save silently in the background and surface a non-blocking notice only if it keeps failing" — a single immediate retry satisfies "keeps failing" for a local SQLite write (transient failures here are essentially always either instantly-retryable or persistently broken, e.g. a full disk) without introducing `Timer`/`Future.delayed` machinery that would make `SettingsCubit` harder to unit test deterministically with `bloc_test`.

**Alternatives considered**: A delayed retry (e.g. `Future.delayed(2s)`) or a small retry-with-backoff loop (rejected — adds real-time dependencies to a Cubit test, and a local disk write is not the kind of transient failure that benefits from backoff the way a network call does); no retry at all, straight to the failure notice (rejected — doesn't match the spec's explicit "retry... silently" answer).

## 8. Centralizing date formatting (`AppDateFormatter`)

**Decision**: A new `core/date/app_date_formatter.dart`, mirroring `EgpFormatter`'s shape (locale-in, cached `intl.DateFormat`, Western-digit-forcing per Decision 5), replacing the three existing hand-rolled `'${date.year}-${date.month}-${date.day}'` strings in `transaction_form_page.dart`, `repayment_form_page.dart`, and `transaction_list_tile.dart`.

**Rationale**: These three call sites are currently locale-blind — they'd show the same digit-glue'd string in Arabic as in English, which fails FR-011 and the spec's User Story 3. Centralizing in `core/` (rather than fixing each site with its own inline `DateFormat`) matches how `EgpFormatter` already centralizes currency formatting and avoids three copies of the same Western-digit-forcing logic (Decision 5) drifting apart over time.

**Alternatives considered**: Fixing each of the three call sites independently with its own local `DateFormat` (rejected — duplicates the locale-resolution/Western-digit logic three times, the exact "centralized" formatting principle `EgpFormatter` already established for money).

## 9. Testing stack

**Decision**: Same as feature 001 — `flutter_test` (unit/widget), `bloc_test` + `mocktail` (`SettingsCubit` against faked `SettingsRepository`/`ChangeLanguage`/`GetLanguagePreference`/`DeviceLocaleProvider`), Drift's in-memory `NativeDatabase.memory()` for `SettingsRepositoryImpl`/`SettingsDao`, `integration_test` for the end-to-end language-switch-and-persist flow, plus a widget test asserting `MainShell`'s tab order/icons under both `Directionality.ltr` and `Directionality.rtl`.

**Rationale**: No new testing need this feature introduces that the existing stack doesn't already cover; reusing it keeps tooling minimal (Principle XVI) and consistent with the rest of the app.

**Alternatives considered**: A dedicated golden-image test package for the RTL mirroring check (rejected — deferred in feature 001's research for the same reason: not required by the spec/constitution yet, and a plain widget test asserting destination order/positions is sufficient to catch a real mirroring regression).
