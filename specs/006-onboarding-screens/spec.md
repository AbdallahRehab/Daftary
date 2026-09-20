# Feature Specification: Onboarding / Intro Screens

**Feature Branch**: `006-onboarding-screens`

**Created**: 2026-09-20

**Status**: Draft

**Input**: User description: "R5 — Onboarding: create a short, premium onboarding experience explaining the app before the user enters the main product, covering knowing your money, remembering money between people, remembering social occasions, scanning and organizing records, and understanding finances via the AI assistant — shown to new users, persisted on completion/skip, with Arabic/English, RTL/LTR, and Light/Dark support."

## Clarifications

### Session 2026-09-20

- Q: How should the app decide whether a user who already has the app installed (before this feature ships) should see onboarding on their first launch after the update? → A: Existing data = already onboarded — at startup, if any domain data already exists (at least one Person or Transaction record), mark onboarding as complete automatically and never show it; otherwise treat as a new user and show onboarding.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-Time User Understands the App Before Entering It (Priority: P1)

A person opens the app for the very first time and is shown a short sequence of introductory screens that explain, in plain language, what the app helps them do — before they land on the main product.

**Why this priority**: This is the entire purpose of the feature; without a first-launch onboarding sequence being shown, nothing else in this feature has value.

**Independent Test**: Install/launch the app for the first time (no prior completion recorded) and verify the onboarding sequence is shown before any main-product screen is reachable.

**Acceptance Scenarios**:

1. **Given** a user is launching the app for the first time, **When** the app finishes starting up, **Then** the onboarding sequence is shown instead of the main product entry point.
2. **Given** the user is on the onboarding sequence, **When** they view each screen in order, **Then** each screen clearly communicates one core idea (knowing your money, remembering money between people, remembering social occasions, scanning and organizing records, understanding your finances) without accounting jargon.

---

### User Story 2 - User Navigates and Completes Onboarding (Priority: P1)

A user moves forward and backward through the onboarding screens at their own pace, sees a clear indication of progress, and finishes by reaching a final call-to-action that takes them into the app.

**Why this priority**: Without reliable, controllable navigation and a clear exit into the product, onboarding blocks rather than helps first-time users — this is as essential as showing the screens at all.

**Independent Test**: Step through every onboarding screen using next/back controls, verify the progress indicator updates correctly at each step, and verify the final screen's call-to-action takes the user into the main app.

**Acceptance Scenarios**:

1. **Given** the user is on any onboarding screen except the first, **When** they choose to go back, **Then** they return to the previous screen with correct progress shown.
2. **Given** the user is on any onboarding screen except the last, **When** they choose to go forward, **Then** they advance to the next screen with correct progress shown.
3. **Given** the user is on the final onboarding screen, **When** they select the final call-to-action, **Then** they are taken into the main application.

---

### User Story 3 - Completion Is Remembered So Onboarding Does Not Reappear (Priority: P1)

A user who has finished (or skipped) onboarding expects to go straight to the main app on every future launch, without seeing the intro screens again.

**Why this priority**: Onboarding that reappears on every launch is a functional defect that would actively annoy returning users — persistence is not optional polish, it's required correctness.

**Independent Test**: Complete onboarding, fully close the app, and reopen it; verify the app goes directly to the normal entry point with no onboarding shown. Repeat using the skip path if skip is available.

**Acceptance Scenarios**:

1. **Given** a user has completed onboarding, **When** they close and reopen the app, **Then** onboarding does not appear and the app opens to its normal entry point.
2. **Given** a user skipped onboarding, **When** they close and reopen the app, **Then** onboarding does not appear again.

---

### User Story 4 - User Can Skip Onboarding (Priority: P2)

A user who is already familiar with the app's concept, or simply wants to get started immediately, can skip the remaining onboarding screens and go straight into the app.

**Why this priority**: Improves experience for users who don't need the explanation, but the app remains fully functional and the core educational goal is still met without it — hence P2, not P1.

**Independent Test**: From any onboarding screen, choose skip and verify the user lands directly in the main app, and that this choice is remembered on the next launch (per User Story 3).

**Acceptance Scenarios**:

1. **Given** the user is on any onboarding screen, **When** they choose to skip, **Then** they are taken directly into the main application.
2. **Given** the user skipped onboarding, **When** the app is relaunched later, **Then** the app treats onboarding as complete (does not show it again).

---

### Edge Cases

- What happens if the app is closed/killed mid-onboarding, before completion or skip? On relaunch, the user must see onboarding again from the start (since it was not completed or skipped), not land in an undefined state.
- What happens for a returning user who already had the app installed before this feature shipped (no completion record exists, but they are not a brand-new user)? A reasonable default determines whether they see onboarding once or are treated as already onboarded (see Assumptions).
- What happens if the user switches app language (Arabic/English) or theme (Light/Dark) while on an onboarding screen? The current screen and progress must be preserved, re-rendering correctly in the new language/direction/theme.
- What happens on very small screens or with large accessibility text sizes? All onboarding content, controls, and progress indicators must remain fully visible and usable, wrapping or resizing as needed rather than being cut off.
- What happens if the device is set to reduced-motion? Onboarding animations must respect that setting and avoid motion that could cause discomfort.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST show an onboarding sequence to a user who has never completed or skipped it before, prior to reaching the main application entry point.
- **FR-002**: The onboarding sequence MUST include distinct screens communicating: (1) understanding income/expenses/savings/financial activity, (2) remembering money given/received between people and what remains unsettled, (3) remembering social occasions (weddings, birthdays, engagements, newborns, gifts, and similar events), (4) scanning paper records and reviewing extracted names/amounts before saving, and (5) getting financial understanding through an AI assistant that uses the user's own data.
- **FR-003**: The AI-assistant onboarding screen MUST describe its capability accurately and MUST NOT state or imply specific, unsupported financial guarantees or promises.
- **FR-004**: The system MUST provide a clear, always-visible indication of the user's progress through the onboarding sequence (e.g. which step they are on out of how many).
- **FR-005**: The system MUST let the user move forward and backward between onboarding screens.
- **FR-006**: The system MUST let the user skip the remaining onboarding screens and proceed directly into the app from any point in the sequence.
- **FR-007**: The final onboarding screen MUST present a clear call-to-action that takes the user into the main application.
- **FR-008**: The system MUST persist onboarding completion (whether finished normally or skipped) so it survives an app restart.
- **FR-009**: On every subsequent app launch after completion or skip is persisted, the system MUST go directly to the normal app entry point and MUST NOT show onboarding again.
- **FR-010**: If the app is closed before onboarding is completed or skipped, the system MUST show onboarding again from the beginning on the next launch.
- **FR-010a**: On the first startup after this feature is installed/updated, if any existing domain data is already present (at least one Person or Transaction record), the system MUST automatically mark onboarding as complete and MUST NOT show it, treating the installation as belonging to an existing user rather than a new one.
- **FR-011**: The onboarding sequence MUST render correctly in both Arabic (RTL) and English (LTR), including correct reading direction, alignment, and any directional icons/controls.
- **FR-012**: The onboarding sequence MUST render correctly in both Light and Dark theme.
- **FR-013**: Onboarding animations MUST be smooth, non-blocking (must not prevent or delay user interaction with controls), and MUST respect the device's reduced-motion accessibility setting where applicable.
- **FR-014**: Onboarding text and touch targets MUST meet the app's existing accessibility standards (readable text, adequately sized controls).

### Key Entities *(include if feature involves data)*

- **Onboarding Completion State**: A persisted flag/record indicating whether the current user has completed or skipped onboarding, checked at app startup to decide whether to show onboarding or go directly to the main entry point.
- **Onboarding Screen**: One step in the introductory sequence, with its own message/illustration content and position within the overall progress indicator.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of first-time app launches (no prior completion/skip recorded) show the onboarding sequence before the main app is reachable.
- **SC-002**: A new user can view all onboarding screens and reach the main app in under 60 seconds when moving directly through without skipping.
- **SC-003**: 100% of app launches after onboarding was completed or skipped go directly to the main app with zero unwanted reappearances of onboarding, across manual and automated regression testing.
- **SC-004**: Onboarding renders correctly (no cut-off text, no broken layout, correct direction) in both Arabic and English, and in both Light and Dark theme, verified through visual review of every onboarding screen.
- **SC-005**: Zero onboarding screens contain unsupported financial promises or imply that a not-yet-shipped app capability (e.g. OCR scanning, the AI assistant) is currently available, verified through content review.

## Assumptions

- "New user" is defined as a device/app install with no persisted onboarding completion/skip record; onboarding state is stored locally per install rather than tied to a user account, since the app does not require account sign-in to be used.
- Confirmed via clarification: existing users who already had the app installed before this feature ships are treated as already onboarded — no manual/retroactive backfill of a historical completion record is required, since the system automatically writes one at first qualifying launch (FR-010a) — so onboarding does not unexpectedly interrupt someone already familiar with the app, using presence of any Person or Transaction record as the existing-user signal.
- Skip is included in scope, consistent with the roadmap's suggested UX and the acceptance criterion "User can skip if the final UX includes skip" — skip is treated as an included, standard capability rather than an open question, since it is a common, low-risk pattern for onboarding flows and no reasonable default suggests omitting it.
- Onboarding is presented after localization (R1) and theme (R2) foundations exist, per the roadmap's recommended execution order, so this feature can directly reuse the existing language and theme switching mechanisms rather than building its own. **This is a hard prerequisite, not just a build-order preference**: FR-012 and SC-004's dark-theme rendering criteria depend on `003-dark-mode-theme` having already shipped a working `ThemeMode` mechanism — they cannot be verified until 003 lands, so 003-dark-mode-theme MUST be implemented (and its `AppDatabase.schemaVersion` 2→3 migration merged) before this feature's database migration (see data-model.md's Migration section, which targets 3→4 for exactly this reason).
- The number and order of onboarding screens follows the five topics from the roadmap; exact copy/illustration content is a content/design decision made during implementation, not specified here.
- No backend/network call is required to determine onboarding content or eligibility; onboarding content is bundled with the app and its completion state is purely local.
- Screens 4 (scanning) and 5 (AI assistant) introduce the product's intended feature set descriptively — they explain what the app is designed to help with, not assert that every described capability is already fully available in the current build. Copy for these screens MUST NOT claim a capability is available today if it has not shipped yet (see FR-003, SC-005).
