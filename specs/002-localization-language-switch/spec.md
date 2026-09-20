# Feature Specification: Arabic/English Localization + Language Switch

**Feature Branch**: `002-localization-language-switch`

**Created**: 2026-09-20

**Status**: Draft

**Input**: User description: "Make Arabic and English first-class application languages and allow the user to switch between them from the app. Add a language switch in Settings. Switching must update the UI without restart when possible, must switch RTL/LTR (alignment, navigation direction, directional icons/animations), Arabic must be a real RTL UX (not translated English), the choice must persist across restarts, and no user-facing strings may remain hardcoded. Verify navigation, app bars, buttons, forms, dialogs, bottom sheets, cards, lists, charts, icons, spacing, mixed Arabic/English text, dates, numbers, and currency."

## Clarifications

### Session 2026-09-20

- Q: Where should users find the entry point to open Settings (and the language switch) from? → A: A new bottom navigation bar / tab added app-wide, with Settings as one of the tabs.
- Q: What digit script should the app use for numbers and currency amounts when Arabic is active? → A: Western Arabic numerals (0-9), even though surrounding text is in Arabic.
- Q: If saving the language preference fails (e.g., a local storage write error), what should the app do? → A: Apply the switch for the current session immediately regardless of persistence outcome; retry the save silently in the background and surface a non-blocking notice only if it keeps failing.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Switch the app's language from Settings (Priority: P1)

A user opens the app's Settings, chooses their preferred language (Arabic or English), and sees the entire app update to that language and reading direction immediately, without needing to restart the app.

**Why this priority**: This is the core capability the feature exists to deliver. Without it, nothing else in this feature matters. It is also the smallest slice that is independently demonstrable and valuable on its own.

**Independent Test**: From any screen, tap the Settings tab in the app's bottom navigation, select the other language than the one currently active, and confirm the visible screen (Settings itself, then the previously active tab) re-renders fully in the new language and direction without a restart.

**Acceptance Scenarios**:

1. **Given** the app is running in English, **When** the user opens the Settings tab and selects Arabic, **Then** all visible text switches to Arabic, the layout mirrors to right-to-left (RTL), and the bottom navigation bar itself (tab order and icons) mirrors for RTL — all without the app restarting.
2. **Given** the app is running in Arabic, **When** the user opens the Settings tab and selects English, **Then** all visible text switches to English and the layout (including the bottom navigation bar) switches to left-to-right (LTR) without the app restarting.
3. **Given** the user just switched language from the Settings tab, **When** they switch to another tab, **Then** that tab is fully localized in the new language and the user's navigation position/state within that tab is preserved (they are not signed out of in-progress context).

---

### User Story 2 - Language choice persists across app restarts (Priority: P2)

A user who has selected a language does not have to re-select it every time they open the app; the app remembers their choice.

**Why this priority**: Persistence is what makes the language switch a real preference rather than a session-only toggle. It is testable independently of live-switching (User Story 1) and delivers value on its own even if live switching required a restart.

**Independent Test**: Set the language to Arabic, fully close the app, reopen it, and confirm it launches directly in Arabic with RTL layout, without the user having to reselect anything.

**Acceptance Scenarios**:

1. **Given** the user selected Arabic, **When** they fully close and reopen the app, **Then** the app launches in Arabic with RTL layout.
2. **Given** the user selected English, **When** they fully close and reopen the app, **Then** the app launches in English with LTR layout.
3. **Given** a user has never chosen a language, **When** they launch the app for the first time, **Then** the app picks a sensible starting language (matching the device's system language when it is Arabic or English, otherwise English) and that choice becomes the persisted default going forward.

---

### User Story 3 - Every part of the app is correct in both languages and directions (Priority: P3)

A user browsing any part of the app — lists of people, transaction forms, dialogs, charts, dates, and monetary amounts — experiences a coherent, correctly mirrored, fully translated interface in both Arabic and English, including screens that mix Arabic and English content (e.g., a name typed in English inside an otherwise Arabic sentence).

**Why this priority**: This is what separates "the app technically supports two languages" from "the app is genuinely usable in Arabic." It builds on Stories 1 and 2 and is verified last because it requires the switch and persistence to exist first, but it is independently testable screen-by-screen.

**Independent Test**: With Arabic active, visit every major screen and UI surface (navigation, app bars, forms, dialogs, bottom sheets, cards, lists, charts, icons) and confirm each renders correctly mirrored, fully translated, with correctly localized dates/numbers/currency, and with no leftover English strings; repeat for English/LTR.

**Acceptance Scenarios**:

1. **Given** Arabic is active, **When** the user views any screen with navigation, app bars, buttons, forms, dialogs, bottom sheets, cards, lists, or charts, **Then** those elements are mirrored for RTL, fully translated, and directional icons/animations point/flow in the RTL-appropriate direction.
2. **Given** Arabic is active, **When** the user views a screen showing dates, numbers, or currency amounts, **Then** those values are formatted per Arabic locale conventions while remaining unambiguous.
3. **Given** Arabic is active, **When** a screen displays content that mixes Arabic and English (e.g., a person's name entered in English, or a currency code), **Then** the mixed content renders legibly without overlapping, reversed digits, or corrupted layout.
4. **Given** either language is active, **When** the user inspects any in-scope screen, **Then** no untranslated/hardcoded user-facing string is visible.

---

### Edge Cases

- What happens if the user switches language while a dialog or bottom sheet is open? It should close cleanly or re-render correctly in the new language/direction, not show mixed-language content or crash.
- What happens if the user rapidly toggles the language back and forth several times? The app must not crash, freeze, duplicate UI, or end up in a state where language and direction disagree with each other.
- What happens if the device's system language changes while the app is installed but the user already made an explicit in-app choice? The app's own persisted choice takes precedence over the device's system language.
- What happens the very first time the app is launched, before any language has ever been chosen? The app must start in a well-defined language (see User Story 2, Scenario 3) rather than showing a blank or mixed-language screen.
- What happens when translated text is significantly longer/shorter than the source text (e.g., Arabic strings that don't fit where the English string fit)? Layout must adapt (wrap, truncate with full text accessible, or resize) without overlapping or clipping critical information, especially financial amounts.
- What happens to a screen with an in-progress, unsaved form if the user switches language elsewhere and returns to it? The screen must re-render in the new language without silently discarding the user's unsaved input.
- What happens if the app fails to save the selected language to persistent storage (e.g., a storage write error)? The language switch still applies for the current session; the app retries the save in the background and shows a non-blocking notice only if saving keeps failing (the user is never blocked from using the app in their chosen language because of a save error).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a language selection control in Settings offering Arabic and English.
- **FR-002**: System MUST provide a persistent, app-wide bottom navigation bar with a Settings destination/tab, reachable from anywhere in the app, through which the language switch is accessed.
- **FR-003**: The bottom navigation bar itself MUST mirror correctly (tab order and directional icons) when the active language's direction changes.
- **FR-004**: System MUST apply a language change to all currently visible and subsequently visited screens without requiring the user to restart the app.
- **FR-005**: System MUST switch the entire UI's reading direction to right-to-left (RTL) when Arabic is active, and to left-to-right (LTR) when English is active, including text alignment, layout mirroring, navigation direction, and the direction of directional icons and animations.
- **FR-006**: System MUST render Arabic as a genuine RTL experience (mirrored layouts, RTL-appropriate iconography/flow) rather than a left-to-right layout with translated text substituted in.
- **FR-007**: System MUST persist the user's selected language across app restarts, and MUST restore it automatically on every subsequent launch without requiring reselection.
- **FR-008**: If persisting the selected language fails, System MUST still apply the switch immediately for the current session, retry the save in the background, and surface a non-blocking notice to the user only if the save continues to fail — the user MUST NOT be blocked from using the app in their chosen language because of a persistence error.
- **FR-009**: System MUST determine the initial language on first-ever launch (before any explicit user choice exists) by preferring the device's system language when it is Arabic or English, and defaulting to English otherwise.
- **FR-010**: System MUST NOT contain hardcoded user-facing strings anywhere in the app; every user-facing string MUST be sourced through the app's localization system in both Arabic and English.
- **FR-011**: System MUST correctly format dates, numbers, and currency amounts according to the active language's locale conventions (grouping/thousands separators, decimal marks, currency symbol/code placement), while always rendering digits using Western Arabic numerals (0-9) in both English and Arabic — Arabic-Indic digit glyphs (٠-٩) MUST NOT be used.
- **FR-012**: System MUST render mixed Arabic/English content (e.g., a Latin-script name inside an Arabic sentence, or a currency code) legibly and without corrupted layout, in either direction.
- **FR-013**: System MUST correctly localize and mirror (as applicable) all of: navigation, app bars, buttons, forms, dialogs, bottom sheets, cards, lists, charts, and icons.
- **FR-014**: Changing the language MUST NOT discard the user's current navigation position or force a return to the home screen beyond what is needed to re-render text and direction.
- **FR-015**: System MUST remain stable (no crash, freeze, duplicated UI, or language/direction mismatch) when the language is switched repeatedly in quick succession.
- **FR-016**: System MUST reuse the app's existing localization infrastructure (translation resource files and generated accessors) rather than introducing a second, parallel localization mechanism.

### Key Entities

- **Language Preference**: The user's currently selected app display language (Arabic or English). Single value scoped to the app installation on the device; persists across app restarts until explicitly changed; drives both the active translation set and the layout direction (RTL/LTR) app-wide.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can change the app's display language and see the change fully applied in under 2 seconds, without restarting the app.
- **SC-002**: 100% of screens reachable in the app render with no overlapping, clipped, or misaligned text or controls in both Arabic (RTL) and English (LTR).
- **SC-003**: The selected language is correctly restored on 100% of app relaunches following a language change, until the user changes it again.
- **SC-004**: A review of all in-scope screens finds zero user-facing strings that remain untranslated (hardcoded) in either language.
- **SC-005**: A review of screens containing dates, numbers, and currency amounts finds zero instances of incorrect or ambiguous locale formatting in either language.
- **SC-006**: Toggling the language back and forth 10 times in a row produces zero crashes, freezes, or visual/state corruption.

## Assumptions

- The project's existing localization architecture (generated localization resources with Arabic and English translation files, as already present in the codebase) is reused and extended, not replaced.
- The app currently has no Settings screen and no bottom navigation bar (existing screens use a single Scaffold/AppBar pattern with icon-based navigation). This feature includes introducing an app-wide bottom navigation bar with a Settings tab (see Clarifications), and a minimal Settings screen whose first entry is the language switch, structured so future settings (e.g., a theme switch) can be added to it later without rework. The existing top-level destinations (People List/home, Overview) become tabs alongside Settings; deep navigation within a tab (e.g., a person's detail page) continues to work as it does today.
- The app is single-user/local-first with no per-account profile system, so the language preference is scoped to the app installation on the device, not to a user account.
- "Without an app restart when technically possible" is interpreted as: the running app's UI reflects the new language and direction immediately upon selection, with no more than a brief, expected re-render — not a full process restart.
- Only Arabic and English are in scope; no "follow system language" option is required (unlike the separately planned theme feature, which does consider a system-default mode).
- Existing screens (people list, person details, transaction forms, archived people, overview, dialogs, bottom sheets, charts) are all in scope for translation coverage and RTL correctness, since they are all currently reachable in the app.
