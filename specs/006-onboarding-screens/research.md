# Phase 0 Research: Onboarding / Intro Screens

## Decision 1: Router-level onboarding gate via a global `GoRouter.redirect`, resolved before `runApp`

**Decision**: Add one new top-level `GoRoute('/onboarding')` to the existing `appRouter` (a sibling of the current `StatefulShellRoute.indexedStack`, not nested inside it — onboarding has no bottom nav), and add a global `redirect:` callback on the `GoRouter` constructor that consults `OnboardingCubit`'s already-resolved state:

```dart
redirect: (context, state) {
  final onboarding = context.read<OnboardingCubit>().state;
  final onOnboardingRoute = state.matchedLocation == '/onboarding';
  if (onboarding.status == OnboardingLoadStatus.showOnboarding && !onOnboardingRoute) {
    return '/onboarding';
  }
  if (onboarding.status == OnboardingLoadStatus.mainApp && onOnboardingRoute) {
    return '/';
  }
  return null; // no redirect
}
```

`OnboardingCubit.initialize()` (which calls the `ResolveOnboardingStatus` use case) is awaited in `main.dart` **before** `runApp`, exactly the pattern `SettingsCubit.initialize()` already establishes for the first-launch language default (`main.dart` T025). Because both cubits are fully resolved before the first frame, the redirect callback above never needs to be `async` and never needs `refreshListenable` — it reads an already-settled `Cubit` state synchronously, the same way `MaterialApp.router`'s `locale:` already reads `SettingsState` synchronously today. This keeps the onboarding gate a pure extension of an existing, already-idiomatic startup pattern rather than inventing a new one.

**Rationale**: `go_router`'s documented pattern for a protected/gated route is exactly a top-level `redirect` — this is also what the constitution's Navigation standard calls for ("Authenticated routes MUST be protected... deep links, unknown routes, authentication redirects... MUST all be handled explicitly"). Treating onboarding as a guarded route is structurally identical to an auth gate, so no new navigation pattern is introduced.

**Alternatives considered**:
- *A splash/loading screen widget that decides where to go*: rejected — adds an extra screen and a state machine the router's own `redirect` already handles for free, and risks a visible flash/flicker the current codebase doesn't have today.
- *Async `redirect` with a `Future`*: rejected — unnecessary since the state is already resolved pre-`runApp`; an async redirect would only be needed if the check had to happen lazily/on first navigation, which would reintroduce a flash.
- *Deciding `initialLocation` dynamically instead of a `redirect`*: rejected — `initialLocation` alone doesn't protect deep links or a later in-session reset of onboarding state; `redirect` covers both the first frame and any future navigation attempt back into `/onboarding` or away from it.

## Decision 2: FR-010a existing-data check as a dedicated `ResolveOnboardingStatus` use case, not a repository method

**Decision**: `OnboardingRepository` stays scoped to only its own table (`isOnboardingComplete()` / `completeOnboarding()`), matching every other repository in this codebase (Principle VI: a repository owns its own bounded data). The FR-010a coordination logic — "if no completion flag exists yet, but at least one `Person` or `MoneyTransaction` record already exists, treat as already onboarded" — lives in a new Domain use case, `ResolveOnboardingStatus`, injected with `OnboardingRepository`, `PeopleRepository`, and `TransactionsRepository`. Its logic:

1. Read `OnboardingRepository.isOnboardingComplete()`. If `true` → return `mainApp`.
2. Otherwise, call `PeopleRepository.hasAnyPerson()` and `TransactionsRepository.hasAnyTransaction()`. If either is `true` → call `OnboardingRepository.completeOnboarding()` (auto-mark complete, so this check never has to run again) → return `mainApp`.
3. Otherwise → return `showOnboarding` (and persist nothing yet — see Decision 5 / Edge Cases).

**Rationale**: This is genuine multi-repository coordination expressing a real business rule (constitution Principle V explicitly allows/expects a use case here, and explicitly warns against a *trivial* wrapper — this is not one, since it branches, coordinates three repositories, and has a side effect). Putting this logic on `OnboardingRepository` itself would force it to depend on `people`'s and `transactions`' tables directly, violating Principle VI's "a repository owns its own bounded data" and Principle II's feature boundary.

**Alternatives considered**:
- *Method directly on `OnboardingRepository` that reaches into `People`/`MoneyTransactions` tables*: rejected — breaks the Data-layer feature boundary (`OnboardingDao` would need to know `people`'s and `transactions`' schema, which those features already own via their own Daos).
- *Check performed ad-hoc inside `OnboardingCubit`*: rejected — puts multi-repository business logic in Presentation, violating Principle I (screens/Cubits must not embed business rules) and making it untestable without Flutter.

**New repository methods required** (both new, both cheap `LIMIT 1`/`EXISTS`-style queries against each feature's own existing Dao, not a full list fetch):
- `PeopleRepository.hasAnyPerson()` → `Future<Either<Failure, bool>>`. Counts **both active and archived** people (unlike `searchActivePeople`, which excludes archived) — an archived-only install still proves prior real use.
- `TransactionsRepository.hasAnyTransaction()` → `Future<Either<Failure, bool>>`. Counts **including soft-deleted** rows (`deletedAt IS NOT NULL`) — a since-deleted transaction is still proof the app was previously used, matching the existing precedent in `PeopleDao.countTransactionsForPerson`, which already counts soft-deleted rows for its own precondition check.

## Decision 3: Reduced motion via `MediaQuery.of(context).disableAnimations`

**Decision**: Read Flutter's built-in `MediaQuery.of(context).disableAnimations` (which reflects iOS "Reduce Motion" and Android "Remove animations" at the platform level — no plugin needed) at the point each onboarding transition/animation would run. When `true`:
- Screen transitions use `pageController.jumpToPage(i)` instead of `pageController.animateToPage(i, duration: ..., curve: ...)`.
- Any decorative per-screen illustration animation (e.g. an `AnimatedSwitcher`/implicit animation on the icon/illustration) uses `Duration.zero` or is skipped entirely in favor of a static frame.

**Rationale**: This is the standard, dependency-free Flutter mechanism for reduced motion (explicitly required by FR-013 and the constitution's Accessibility standard), consistent with the Engineering & Quality Standards' general instruction to "prefer implicit animations... respect accessibility/reduced-motion settings."

**Alternatives considered**: A custom app-level "motion preference" setting — rejected as out of scope; the spec ties this to "the device's reduced-motion accessibility setting," i.e. the OS-level signal, not a new in-app preference.

## Decision 4: `PageView`/`PageController` is sufficient — no new dependency

**Decision**: Use Flutter's built-in `PageView.builder` + `PageController` for the 5 onboarding screens. `PageController` gives forward/back navigation (`nextPage()`/`previousPage()`/programmatic `animateToPage`/`jumpToPage`), `onPageChanged` for keeping a locally-held step index in sync (for `OnboardingProgressIndicator`), and free swipe gestures at no extra cost. Skip is a plain router navigation call (`context.go('/')` after `OnboardingCubit.completeOnboarding()`), not a `PageView` concern.

**Rationale**: `pubspec.yaml` has no animation/carousel package today (no Lottie/Rive/`smooth_page_indicator`, etc.), and 5 static content screens with a step indicator is exactly what `PageView` is designed for — matches the plan's constraint to prefer no new dependency unless clearly justified, and none is: nothing here needs anything `PageView` can't already do.

**Alternatives considered**:
- *A third-party onboarding/carousel package* (e.g. `introduction_screen`, `smooth_page_indicator`): rejected — adds a dependency for functionality `PageView` + a small custom progress-indicator widget already covers, and would sit awkwardly against the constitution's centralized design-system requirement (a third-party package's own styling vs. `core/design_system` tokens).
- *Custom `AnimatedSwitcher`-only paging (no `PageView`)*: rejected — loses free swipe-to-navigate and `onPageChanged` bookkeeping `PageView` already provides.

## Decision 5: In-flow step index is local widget state, not Cubit state

**Decision**: The currently-visible onboarding screen index is held as local state in `OnboardingPage` (via `PageController`/a `ValueNotifier<int>` driving `OnboardingProgressIndicator`), not promoted into `OnboardingCubit`'s state.

**Rationale**: This mirrors an existing precedent already in the codebase — `MainShell`'s bottom-nav tab index lives in `StatefulNavigationShell.currentIndex` (framework-managed), not in a Cubit — because it is ephemeral UI/navigation state with no business meaning and nothing outside the widget needs to observe it. `OnboardingCubit` is reserved for the two things that *are* business actions: resolving the startup gate (`ResolveOnboardingStatus`) and marking onboarding complete/skipped (`OnboardingRepository.completeOnboarding()`). This also directly satisfies the Edge Case that an interrupted onboarding must restart from screen 1 — since the step index is never persisted anywhere, there is nothing to accidentally resume from.

**Alternatives considered**: Modeling the step index as `OnboardingCubit` state — rejected as unnecessary Cubit surface area for a value with no business meaning, and would make `OnboardingState`'s "gate" semantics (`resolving`/`showOnboarding`/`mainApp`) awkwardly conflated with in-flow paging semantics.

## Decision 6: Language/theme switch mid-onboarding preserves screen and progress "for free"

**Decision**: No special handling is required. `OnboardingPage` and its `PageController` are ordinary widget state; a language change (`SettingsCubit` emitting new state → `MaterialApp.router`'s `locale` changing) or a theme change (feature 003's mechanism) triggers a rebuild of the subtree, not a remount — Flutter preserves `State` objects (including `PageController` position) across such rebuilds as long as the widget's type/position in the tree and any `Key` are unchanged, which they are here (no route change occurs on a language/theme switch).

**Rationale**: This is the same behavior feature 002 already relies on for `StatefulNavigationShell` preserving each tab's navigation stack across a language switch (FR-014 in that feature) — the same guarantee extends to `OnboardingPage`'s own `PageController`, requiring no new code, just correct verification in `quickstart.md`/the integration test.

**Alternatives considered**: Persisting the current step index so it could be explicitly "restored" across a rebuild — rejected as solving a problem that doesn't exist here (no remount occurs) and would conflict with Decision 5.

## Decision 7: Fail-open to the main app if `ResolveOnboardingStatus` itself fails

**Decision**: If `ResolveOnboardingStatus` returns a `Failure` (e.g. a `CacheFailure` reading the local DB), `OnboardingCubit.initialize()` treats this the same as `mainApp` — logging the failure but not blocking startup behind an unresolvable gate.

**Rationale**: A broken onboarding-status read must never be able to lock a user (including an existing user with real financial data) out of the app they already have data in. This mirrors feature 002's FR-008 philosophy ("the switch MUST apply... even if persisting it fails") of never letting a local-storage hiccup block the user from the app itself, applied to a gate rather than a preference write. This does mean onboarding could theoretically reappear on a subsequent successful read if the first read failed transiently — an accepted, low-probability trade-off favoring never blocking access to the user's own financial data (constitution's Financial Domain Override: correctness/access to their data over convenience of the onboarding polish).

**Alternatives considered**: Fail closed to `showOnboarding` on any read error — rejected, since for a *returning* user with existing data this would be strictly worse (re-showing onboarding to someone already mid-use of a financial app) than the chosen fail-open behavior, which only ever risks onboarding showing once more than intended, never blocking access to real data.
