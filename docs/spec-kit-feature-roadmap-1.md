# Feature Roadmap — Localization, Theme, State Refresh, Onboarding

This roadmap splits the requested work into independent Spec Kit features. Each feature should have its own `specify → plan → tasks → implement → converge` cycle. This matches the Spec Kit approach for decomposing larger work into smaller, independently specified features.

## Global Rules

- Read the project constitution before implementation.
- Inspect the existing code before changing architecture.
- Do not guess the current BLoC/Cubit/state flow.
- Reuse existing architecture and shared components.
- Do not introduce a second state-management approach.
- Preserve existing behavior.
- Every feature must include loading/success/failure handling where applicable.
- Verify Arabic/English and RTL/LTR where relevant.
- Run `flutter format`, `flutter analyze`, and relevant tests.
- Run `/speckit-converge` after implementation.
- If convergence finds gaps, implement the generated follow-up tasks and converge again.

---

## R1 — Arabic / English Localization + Language Switch

### Goal

Make Arabic and English first-class application languages and allow the user to switch between them from the app.

### Requirements

1. Support:
   - Arabic
   - English

2. Add a language switch in Settings.

3. Language switching should update the UI without an app restart when technically possible.

4. Switching language must also switch:
   - RTL/LTR
   - alignment
   - navigation direction where applicable
   - directional icons/animations where applicable

5. Arabic must be designed as a real RTL UX, not merely translated English.

6. Persist the selected language across app restarts.

7. No user-facing strings should remain hardcoded in affected UI.

8. Reuse the existing localization architecture if one already exists.

9. Verify:
   - navigation
   - app bars
   - buttons
   - forms
   - dialogs
   - bottom sheets
   - cards
   - lists
   - charts
   - icons
   - spacing
   - mixed Arabic/English text
   - dates
   - numbers
   - currency

### Investigation

Inspect before coding:

- existing localization files
- locale configuration
- `MaterialApp`/`CupertinoApp`
- persisted settings
- current theme/settings state
- routing
- localization helpers

Do not replace the current architecture without evidence.

### Acceptance Criteria

- [ ] Arabic ↔ English switch works.
- [ ] UI updates immediately or through the smallest justified refresh.
- [ ] RTL/LTR changes correctly.
- [ ] Language persists after restart.
- [ ] No obvious hardcoded user-facing strings remain.
- [ ] Arabic screens are visually reviewed.
- [ ] English screens are visually reviewed.
- [ ] Localization tests are added/updated.
- [ ] Existing navigation and state are not broken.

---

## R2 — Dark Mode / Theme Switching

### Goal

Add production-quality Dark Mode and allow the user to switch between Light and Dark themes.

### Requirements

1. Support:
   - Light
   - Dark
   - System Default if it fits the existing architecture without unnecessary complexity

2. Add theme selection to Settings.

3. Persist the theme preference.

4. Theme switching should happen without restart when possible.

5. Use centralized semantic theme tokens instead of hardcoded widget colors.

6. Define semantic colors for:
   - background
   - surface
   - elevated surface
   - primary
   - secondary
   - text
   - secondary text
   - border
   - divider
   - success
   - warning
   - error
   - disabled
   - inputs
   - cards
   - charts
   - navigation
   - dialogs
   - bottom sheets

7. Verify readability and contrast in both themes.

8. Financial values must remain clearly readable in both themes.

### Investigation

Inspect:

- existing `ThemeData`
- `ColorScheme`
- color constants
- design-system files
- custom widgets
- charts
- loading/error/success components
- settings persistence

### Acceptance Criteria

- [ ] Light/Dark switching works.
- [ ] Preference persists.
- [ ] Existing screens render correctly in Dark Mode.
- [ ] Light Mode has no regression.
- [ ] No important meaning relies only on color.
- [ ] Inputs, dialogs, sheets, cards, lists, charts, and navigation are reviewed.
- [ ] Hardcoded colors are removed/replaced where appropriate.
- [ ] Relevant tests exist.

---

## R3 — Fix Stale State After Adding Money / Transactions

### Problem

On a person's details page, after adding a new money transaction such as money received or money given, the newly created transaction sometimes does not appear immediately.

The user currently has to reload/reopen the app before the new transaction becomes visible.

### Goal

After a successful transaction creation, Person Details must immediately reflect the new transaction and all affected totals.

### Required Investigation

Trace the real flow:

```text
Person Details UI
    ↓
BLoC/Cubit
    ↓
Add Transaction Use Case
    ↓
Repository
    ↓
Data Source
    ↓
Persistence/API
    ↓
Result
    ↓
State update
    ↓
Person Details UI
```

Inspect:

- Person Details BLoC/Cubit
- transaction creation BLoC/Cubit
- repository
- local cache/database
- remote response
- state ownership
- event sequencing
- emitted states
- mutable lists
- missing `copyWith`
- stale references
- duplicate BLoC/Cubit instances
- `BlocProvider` scope
- `BlocListener` / `BlocConsumer`
- navigation results
- cache invalidation
- synchronization

### Required Behavior

After successful creation:

1. Persist the transaction.
2. Return a reliable success result.
3. Update or refresh Person Details state.
4. Update:
   - transaction list
   - total received
   - total given
   - net balance
   - settlement-related values if affected
5. Show the transaction immediately.
6. Do not require app restart or manual reload.
7. Do not create duplicate transactions.
8. Handle failure without corrupting state.

### Allowed Implementation Strategies

After inspecting the architecture, choose the smallest correct approach:

#### Option A — Targeted Immutable State Update

If the create operation returns the complete domain transaction, update the current state using immutable data and `copyWith()`.

#### Option B — Targeted Refresh

After success, invoke the Person Details refresh/use case.

#### Option C — Shared State Coordination

Only if multiple screens genuinely require coordinated transaction state, introduce a clean shared-state/invalidation mechanism.

Do not introduce unnecessary global state.

### Acceptance Criteria

- [ ] Adding money received updates Person Details immediately.
- [ ] Adding money given updates Person Details immediately.
- [ ] Transaction list updates.
- [ ] Totals update.
- [ ] Net balance updates.
- [ ] No reload/restart is required.
- [ ] No duplicate transaction appears.
- [ ] Failure does not create a phantom transaction.
- [ ] State remains immutable.
- [ ] `copyWith()` is used where appropriate.
- [ ] Regression tests reproduce and prevent the original bug.

### Regression Tests

- Existing person → add received → verify transaction and balance.
- Existing person → add given → verify transaction and balance.
- Failed creation → verify no phantom transaction.
- Repeated add → verify no duplicate state entry.
- Navigate away/back → verify correct state.

---

## R4 — Fix Archive / Unarchive Stale State

### Problem

On the initial people/list screen, when a person is archived and then removed from the archive/unarchived, the person does not immediately appear in the active list.

The user has to reload or reopen the app.

### Goal

Archive/unarchive must immediately update the visible people state.

### Required Investigation

Trace:

```text
People List UI
    ↓
People BLoC/Cubit
    ↓
Archive/Unarchive Use Case
    ↓
Repository
    ↓
Local/Remote Data Source
    ↓
Result
    ↓
People List State
```

Inspect:

- archived flag/status
- active/archived filtering
- cache
- repository invalidation
- BLoC/Cubit events
- state emissions
- `copyWith`
- mutable collections
- multiple BLoC instances
- screen lifecycle
- navigation
- local DB queries
- synchronization
- optimistic updates

### Required Behavior

After successful unarchive:

1. Persist the new archive state.
2. Update People state immediately.
3. Remove the person from the archived-only list.
4. Add the person to the active list when the current filter should display them.
5. Preserve sorting/search/filter rules.
6. Do not require reload/restart.
7. Do not create duplicates.
8. Handle failures consistently.

### Acceptance Criteria

- [ ] Unarchiving immediately makes the person visible in the correct active list.
- [ ] Archived list updates immediately.
- [ ] No reload/restart is required.
- [ ] Search/filter state remains correct.
- [ ] No duplicate person appears.
- [ ] Failed unarchive leaves state consistent.
- [ ] State is immutable.
- [ ] Regression tests cover archive/unarchive.

### Regression Tests

- Archive active person → active list updates.
- Unarchive archived person → active list updates immediately.
- Unarchive → archived list removes person immediately.
- Search/filter remains correct.
- Failed unarchive → state remains consistent.
- Reopen screen → state remains correct.

---

## R5 — Onboarding / Intro Screens

### Goal

Create a short, premium onboarding experience that explains the application before the user enters the main product.

The onboarding should make the product understandable to a normal user and should not feel like accounting software.

### Core Message

The product helps users organize:

- money
- people
- social occasions
- expenses
- budgets
- savings
- scanned records
- financial insights

### Suggested Screens

#### Screen 1 — Know Your Money

Explain that the app helps users understand income, expenses, savings, and financial activity.

#### Screen 2 — Remember Money Between People

Explain that users can record who gave them money, who they gave money to, and what remains unsettled.

#### Screen 3 — Remember Social Occasions

Explain that weddings, birthdays, engagements, newborn occasions, gifts, and similar events can be recorded and remembered.

#### Screen 4 — Scan and Organize

Explain that users can scan paper records and review extracted names/amounts before saving.

#### Screen 5 — Understand Your Finances

Explain that the AI assistant can answer questions using the user's actual application data.

Do not make unsupported financial promises.

### UX Requirements

- Short and easy to understand.
- Clear progress indicator.
- Next/back controls.
- Skip option if supported by the final UX decision.
- Final CTA to enter the application.
- Arabic and English.
- RTL/LTR.
- Light/Dark support.
- Smooth but subtle animations.
- Accessible text and touch targets.
- No unnecessary technical terminology.

### Persistence

```text
App launch
 → check onboarding completion
 → show onboarding only when required
 → completion/skip persisted
 → next launch goes to normal entry flow
```

### Acceptance Criteria

- [ ] New user sees onboarding.
- [ ] User can navigate all onboarding screens.
- [ ] User can skip if the final UX includes skip.
- [ ] Completion is persisted.
- [ ] Onboarding does not unnecessarily reappear.
- [ ] Arabic and English work.
- [ ] RTL/LTR work.
- [ ] Light/Dark work.
- [ ] Animations are smooth and non-blocking.
- [ ] Accessibility is considered.

---

## Recommended Execution Order

### R1 — Localization

```text
/speckit-specify
/speckit-clarify
/speckit-plan
/speckit-checklist
/speckit-tasks
/speckit-analyze
/speckit-implement
/speckit-converge
```

### R2 — Dark Mode

Run the same cycle after R1 is stable.

### R3 — Transaction State Refresh

Treat this as an independently testable bug. Diagnose the root cause before changing code.

### R4 — Archive State Refresh

Treat this as another independent bug. If it shares the exact root cause with R3, document that finding and use the smallest shared architectural fix.

### R5 — Onboarding

Implement after localization/theme foundations are available.

---

## Priority

| ID | Feature | Priority | Dependency |
| --- | --- | --- | --- |
| R1 | Arabic/English + language switch | P0 | Existing app foundation |
| R2 | Dark Mode | P0 | R1 recommended |
| R3 | Transaction state refresh | P0 | Existing transaction architecture |
| R4 | Archive/unarchive state refresh | P0 | Existing people architecture |
| R5 | Onboarding | P1 | R1 + R2 recommended |

## Final Verification

Verify:

- Arabic ↔ English
- RTL ↔ LTR
- Light ↔ Dark
- transaction creation state refresh
- archive/unarchive state refresh
- onboarding persistence
- no duplicate state entries
- no forced app reload
- BLoC/Cubit immutability
- `copyWith()` correctness
- tests
- `flutter analyze`
- `flutter test`
- performance
- accessibility
