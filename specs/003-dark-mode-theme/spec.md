# Feature Specification: Dark Mode / Theme Switching

**Feature Branch**: `003-dark-mode-theme`

**Created**: 2026-09-20

**Status**: Draft

**Input**: User description: "R2 — Dark Mode / Theme Switching: Add production-quality Dark Mode and allow the user to switch between Light and Dark themes, with theme selection in Settings, persisted preference, centralized semantic theme tokens instead of hardcoded widget colors, and readability/contrast (including financial values) verified in both themes."

## Clarifications

### Session 2026-09-20

- Q: What contrast standard should "sufficient contrast" be measured against for text and financial values in both themes? → A: WCAG 2.1 AA (4.5:1 normal text, 3:1 large text/UI components)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Switch Between Light and Dark Theme (Priority: P1)

A user opens Settings and chooses their preferred visual theme (Light or Dark) so the entire app matches their preference and viewing conditions (e.g. low-light use at night).

**Why this priority**: This is the core value of the feature — without a working, immediate switch, there is no dark mode feature at all.

**Independent Test**: From Settings, select "Dark", verify every screen the user can currently reach (people list, person details, add transaction, overview, settings) renders in dark colors with no unstyled/white flashes; select "Light" again and verify the app returns to the original appearance with no regression.

**Acceptance Scenarios**:

1. **Given** the app is running in Light theme, **When** the user selects "Dark" in Settings, **Then** all visible screens update to the Dark theme without requiring an app restart.
2. **Given** the app is running in Dark theme, **When** the user selects "Light" in Settings, **Then** all visible screens return to the Light theme without requiring an app restart.
3. **Given** the user is on any screen with financial values (balances, totals, transaction amounts), **When** the theme is Dark, **Then** all financial text remains clearly readable with sufficient contrast against its background.

---

### User Story 2 - Theme Preference Persists Across Restarts (Priority: P1)

A user who picked Dark (or Light) theme expects the app to remember that choice the next time they open it, without having to reselect it.

**Why this priority**: Persistence is required for the preference to be genuinely usable; without it, every app relaunch resets user intent, which the roadmap explicitly calls out as unacceptable.

**Independent Test**: Set theme to Dark, fully close the app, reopen it, and verify it launches directly in Dark theme (and equivalently for Light, and for System Default if supported).

**Acceptance Scenarios**:

1. **Given** the user selected Dark theme, **When** the app is fully closed and reopened, **Then** the app launches in Dark theme.
2. **Given** the user selected Light theme, **When** the app is fully closed and reopened, **Then** the app launches in Light theme.

---

### User Story 3 - Follow System Theme Automatically (Priority: P2)

A user who wants the app to always match their device's system-wide Light/Dark setting can choose a "System Default" option instead of manually picking a theme.

**Why this priority**: Valuable convenience for users who already manage Light/Dark at the OS level, but the app is still a complete, usable dark-mode feature without it — hence P2, not P1.

**Independent Test**: Select "System Default" in Settings, change the device's system theme (e.g. via OS quick settings), and return to the app to verify it follows the device setting; verify the choice persists as "System Default" (not a frozen Light/Dark snapshot) across restarts.

**Acceptance Scenarios**:

1. **Given** the user selected "System Default", **When** the device's system theme changes while the app is open, **Then** the app updates to match without requiring an app restart.
2. **Given** the user selected "System Default" and later closes/reopens the app, **When** the app launches, **Then** it reflects the device's current system theme, not a previously cached Light/Dark value.

---

### Edge Cases

- What happens to charts, cards, and other visual elements that currently rely on color alone to convey meaning (e.g. positive vs. negative balances)? They must remain distinguishable through more than color in both themes (e.g. icon, sign, or label), per accessibility requirements.
- How does the app behave on a screen displayed mid-transition when the theme changes (e.g. a form with unsaved input, an open dialog or bottom sheet)? Unsaved input and open overlays must be preserved and must simply re-render with new theme colors, not close or reset.
- What happens if a future screen or component is added without using the shared theme tokens? It must be treated as a defect against this feature's Definition of Done, not an acceptable exception.
- How do loading, empty, and error state components look in Dark theme? They must remain legible and visually consistent with the rest of the Dark theme, not left in Light-only styling.
- What happens the very first time the app is installed, before the user has made any theme choice? The app must apply a sensible default (see Assumptions) rather than an undefined/unstyled appearance.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a Light theme and a Dark theme, both applied consistently across every screen, dialog, bottom sheet, and reusable component in the app.
- **FR-002**: The system MUST provide a "System Default" theme option that follows the device's current system-wide Light/Dark setting and updates live if that setting changes while the app is open.
- **FR-003**: Users MUST be able to select their theme preference (Light, Dark, or System Default) from Settings.
- **FR-004**: The system MUST apply a theme change to all currently visible screens without requiring an app restart.
- **FR-005**: The system MUST persist the user's theme preference across app restarts, including when the preference is "System Default".
- **FR-006**: The system MUST define and use a single centralized set of semantic color roles (background, surface, elevated surface, primary, secondary, text, secondary text, border, divider, success, warning, error, disabled, inputs, cards, charts, navigation, dialogs, bottom sheets) that both themes implement, rather than each screen/component defining its own colors.
- **FR-007**: Existing screens and shared components MUST be updated to source their colors from the semantic theme rather than hardcoded color values, wherever a hardcoded color is found during implementation.
- **FR-008**: The system MUST ensure all text — including financial values (balances, amounts, totals) — meets WCAG 2.1 AA contrast ratios (at least 4.5:1 for normal text, at least 3:1 for large text and UI components) against its background in both Light and Dark themes.
- **FR-009**: The system MUST NOT rely on color alone to convey important meaning (e.g. money owed vs. money received); an additional visual cue (icon, sign, label, or similar) MUST be present in both themes.
- **FR-010**: The system MUST render loading, success, empty, and error states correctly and legibly in both themes.
- **FR-011**: The system MUST apply a defined default theme on first launch, before the user has made an explicit choice (see Assumptions).
- **FR-012**: Switching themes MUST NOT alter, lose, or reset any in-progress user input (e.g. a form being filled out) or navigation state.

### Key Entities *(include if feature involves data)*

- **Theme Preference**: The user's chosen theme mode — Light, Dark, or System Default. Persisted per device/user and read at app startup and whenever changed in Settings.
- **Semantic Theme Token Set**: The named collection of color roles (background, surface, text, success, error, etc.) that Light and Dark each provide a concrete value for; screens and components reference token names, not raw colors.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can switch from Light to Dark (or back) and see every currently visible screen fully updated in under 1 second, with no restart.
- **SC-002**: 100% of screens reachable in the app today render correctly (no unstyled, missing, or low-contrast elements) in both Light and Dark theme during visual review.
- **SC-003**: The selected theme preference is correctly restored on 100% of app relaunches, including after a full app close.
- **SC-004**: All financial values meet WCAG 2.1 AA contrast ratios (4.5:1 normal text, 3:1 large text/UI components) in both themes, with zero instances of financial text being illegible or ambiguous due to color choice.
- **SC-005**: No user-reported or reviewer-found instance exists of meaning being conveyed by color alone after the feature ships.

## Assumptions

- The app currently has a single, hardcoded Light-only visual style with no existing dark variant; this feature introduces Dark theme and the semantic token layer needed to support it, rather than modifying an existing multi-theme system.
- On first install (before any explicit user choice), the app defaults to "System Default" so it immediately matches the device's current appearance; this is a reasonable, common default and does not block scope.
- "System Default" is included in scope as explicitly requested in the roadmap and is technically feasible without disproportionate complexity, since the app already reads platform settings for other purposes (e.g. locale).
- Theme preference is a single value shared by the whole app (not per-screen or per-feature).
- This feature reuses the existing state-management and settings-persistence architecture already established for language preference (see the localization/language-switch feature) rather than introducing a new mechanism.
- Charts and data visualizations are in scope for semantic theming but redesigning their underlying data representation is out of scope — only their color/theme presentation changes.
- "Reviewed"/"verified" acceptance criteria are primarily satisfied via manual visual review during implementation and testing; a lightweight automated contrast-ratio unit test (tasks.md T053) supplements this as a regression guard for FR-008/SC-004's specific numeric thresholds, but full accessibility review (screen readers, touch targets, etc.) remains manual.
