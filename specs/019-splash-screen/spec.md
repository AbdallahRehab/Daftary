# Feature Specification: Branded Splash Screen

**Feature Branch**: `019-splash-screen`

**Created**: 2026-09-26

**Status**: Draft

**Input**: User description: "Professional Splash Screen — a production-ready, branded splash that expresses Daftary's core idea (money given to and received from people, balances, financial relationships) using the existing brand identity, colors, typography and design language; subtle, fast, intentional animation that respects reduced-motion; Light/Dark, Arabic/English, RTL/LTR; starts immediately, never gets stuck, hands off safely to the correct next screen (onboarding or main app) without duplicate initialization or navigation races; no change to unrelated screens or business logic."

## Context: What Exists Today

- On launch, the operating system shows its launch screen (plain white on Android and iOS; the dark variant on Android is the system's default dark background) while the app silently prepares its data store, language/theme preference, and first-launch (onboarding) decision. Nothing branded is shown during this window, and if that preparation fails the user is left on a blank screen with no explanation and no way forward.
- The app's identity is already defined: the name **Daftary / دفتري** ("my ledger"), an emerald brand color, finance colors that mean "they owe you" (green) and "you owe them" (coral), and a launcher icon showing a cream ledger notebook with a gold "د" coin on an emerald field.
- After preparation, the app opens either the onboarding sequence (first launch) or the People home screen (returning user). A notification tapped while the app was closed can also open a specific screen.
- There is no sign-in; the only startup "gate" is whether onboarding has been completed.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A Branded, Seamless Launch (Priority: P1)

When a user opens Daftary from a closed state, they immediately see Daftary's own identity — the ledger-and-coin mark and the app name in their language, on the brand's color field — instead of a blank white screen. The system launch screen and the splash look like one continuous image: no white flash, no jump in the mark's size or position, and no color change between them.

**Why this priority**: This is the first thing every user sees on every cold launch. Replacing an unbranded blank screen with a coherent branded moment is the core value of the feature, and it is viable on its own even without animation.

**Independent Test**: Force-close the app, launch it in Light and in Dark mode, in Arabic and in English, and observe (slow-motion screen recording where possible) that the launch screen → splash → first screen sequence shows no white flash, no mark jump, and the correct localized name.

**Acceptance Scenarios**:

1. **Given** the app is fully closed and the device is in Light mode, **When** the user opens the app, **Then** the first visible frame is the brand color field with the Daftary mark centered, and the splash continues from exactly that image.
2. **Given** the device is in Dark mode (or the user chose Dark in the app's settings), **When** the user opens the app, **Then** the splash uses the dark variant of the brand field and the mark remains clearly visible, with no bright flash at any point.
3. **Given** the app language is Arabic, **When** the splash is shown, **Then** the name reads "دفتري", laid out right-to-left and correctly shaped; **Given** English, **Then** it reads "Daftary".
4. **Given** any supported phone or tablet size, in portrait or landscape, **When** the splash is shown, **Then** the mark and name are centered, fully visible, clear of notches, the camera cutout, rounded corners and system bars, and are never cropped or stretched.

---

### User Story 2 - The Mark Tells the Story in Under a Second (Priority: P1)

As the app finishes getting ready, a short, calm animation expresses what Daftary does: a coin passes between two sides — you and another person — and comes to rest on the ledger, whose lines settle into place as the balance is recorded. The motion then gives way to the first screen with a soft transition.

**Why this priority**: The animation is what makes the splash specific to Daftary rather than a generic logo screen, and it is the feature's main differentiator. It builds directly on Story 1.

**Independent Test**: Launch the app with animations enabled and verify the sequence plays once, completes within the time limit, communicates the give/receive → recorded idea, and transitions smoothly; then enable the system's reduce-motion / remove-animations setting and verify no movement plays.

**Acceptance Scenarios**:

1. **Given** animations are enabled, **When** the splash appears, **Then** a single, non-repeating sequence plays: the coin travels from one side toward the ledger, the ledger lines settle, and the name fades in — completing within 1 second.
2. **Given** the app is in Arabic (right-to-left), **When** the sequence plays, **Then** its left/right movement is mirrored so that it follows the reading direction, exactly as it does in English left-to-right.
3. **Given** the user has turned on the system's reduce-motion, remove-animations, or equivalent accessibility setting, **When** the splash appears, **Then** the final, settled composition is shown immediately with no movement, and the app proceeds as soon as it is ready.
4. **Given** the animation has finished, **When** the app is ready, **Then** the splash hands off to the first screen with a brief fade (no slide, bounce or zoom), and the user cannot navigate "back" to the splash.

---

### User Story 3 - Always Reaches the Right Place, Never Stuck (Priority: P1)

After the splash, the user lands on exactly the screen they would have reached without it: the onboarding sequence on first launch, the People home screen for a returning user, or the screen a tapped notification points to. If the app cannot finish getting ready, the splash turns into a clear, localized message with a way to try again instead of freezing.

**Why this priority**: A splash that delays, misroutes, or hangs is worse than no splash. Correct and safe hand-off is a release blocker, not polish.

**Independent Test**: Launch as (a) a brand-new install, (b) a user who has completed onboarding, (c) via a notification tap while closed, and (d) with preparation made to fail; verify the destination in (a)–(c) matches current behavior and (d) shows the retry message, and that retry recovers when the cause is gone.

**Acceptance Scenarios**:

1. **Given** onboarding has never been completed, **When** the splash finishes, **Then** the onboarding sequence opens.
2. **Given** onboarding has been completed or skipped, **When** the splash finishes, **Then** the People home screen opens.
3. **Given** the app was closed and the user tapped one of Daftary's notifications, **When** the splash finishes, **Then** the screen that notification targets opens — exactly as it does today.
4. **Given** preparation fails (for example the local data store cannot be opened), **When** that failure occurs, **Then** the splash stops animating and shows a short, localized message and a "Try again" action; choosing it retries preparation once more, and on success the app proceeds normally.
5. **Given** preparation has not finished within 10 seconds, **When** that limit passes, **Then** the same message and "Try again" action are shown rather than an indefinite wait.
6. **Given** the splash is handing off, **When** any combination of animation completion and readiness occurs (in either order, or at the same moment), **Then** navigation happens exactly once.

---

### User Story 4 - Only on a Real Launch (Priority: P2)

The splash appears only when the app is started from a closed state. Switching away and back, locking and unlocking the phone, rotating, changing the language or theme in Settings, or finishing onboarding never replays it.

**Why this priority**: Replaying a splash on every return is a common annoyance and wastes the user's time; it matters to everyday use but is secondary to the first-launch experience itself.

**Independent Test**: With the app open on any screen, send it to the background and bring it back, rotate the device, and change language and theme in Settings; verify the splash never reappears and the user stays on the same screen.

**Acceptance Scenarios**:

1. **Given** the app is open on any screen, **When** the user leaves the app and returns while it is still running, **Then** they return to the same screen with no splash.
2. **Given** the user changes language or theme in Settings, **When** the change applies, **Then** no splash is shown and the current screen is preserved (existing behavior).
3. **Given** the operating system ended the app in the background, **When** the user reopens it, **Then** it is treated as a fresh launch and the splash is shown once.

### Edge Cases

- **Preparation finishes before the first frame / before the animation ends**: the user sees the full (short) animation, then proceeds; the splash never waits beyond the animation's end once the app is ready.
- **Preparation takes longer than the animation**: the mark rests in its final, settled state (no looping, no spinner-style motion) until ready, then proceeds.
- **Preparation fails before the language preference is known**: the error message uses the device's language if it is Arabic or English, otherwise English, and follows that language's reading direction.
- **Repeated "Try again" failures**: each attempt shows the same message again; the app never crashes, duplicates work already done, or navigates anywhere.
- **User taps or presses Back during the splash**: taps are ignored; Android Back behaves as it does on any root screen (leaves the app), and it does not skip to or break the next screen.
- **Very small screens, split-screen and very large text settings**: the composition scales down to fit; the name may wrap but never overflows or gets cut off.
- **Landscape phones, tablets and foldables**: the mark keeps a comfortable, capped size and stays centered; it does not balloon on large displays.
- **Theme preference differs from the device setting** (e.g. device Light, app set to Dark): the system launch screen can only follow the device setting, so the splash follows the app's chosen theme and the change between them is a quick, smooth crossfade rather than an abrupt switch.
- **Notification tapped while the app is closed**, and the targeted item no longer exists: behavior is unchanged from today's handling of that case; the splash only delays it by the animation.
- **Screen reader active**: the name "Daftary / دفتري" is announced once; the decorative mark and motion are not announced; the error message and "Try again" action are reachable and announced if shown.

## Requirements *(mandatory)*

### Functional Requirements

#### Presentation & identity

- **FR-001**: The app MUST show a branded splash on every launch from a closed state, before any other app screen.
- **FR-002**: The splash MUST display the existing Daftary mark (ledger notebook and "د" coin, as in the launcher icon) centered on the brand color field, plus the localized app name. It MAY include one short, localized line that describes the app's purpose; it MUST NOT include any other text, buttons, or loading indicators during normal operation.
- **FR-003**: The splash MUST use only the app's existing brand colors, finance colors, and type scale; it MUST NOT introduce a new palette, typeface, or visual style.
- **FR-004**: The splash MUST provide a Light and a Dark variant and MUST follow the theme the user chose in the app (Light, Dark, or System).
- **FR-005**: The system launch screen on Android and iOS MUST show the same background color and the same mark at the same size and position as the splash's first frame, in both Light and Dark device modes, so the hand-off is visually seamless. The white launch background MUST be removed.
- **FR-006**: The composition MUST stay centered, uncropped, undistorted, and clear of system bars, notches, and screen cutouts across all supported phone, tablet, and foldable sizes in both orientations, with the mark's size capped on large screens.

#### Motion

- **FR-007**: When animations are allowed, the splash MUST play one non-repeating sequence of at most 1 second that conveys money moving between two sides and being recorded in the ledger (give/receive → balance), then rest in its final state.
- **FR-008**: The sequence's horizontal direction MUST mirror between right-to-left and left-to-right languages: the side the money comes from is the reading-start side, and the ledger entry is written in the reading direction. The mark itself is a logo and is never mirrored (it must also match the system launch screen, which cannot know the app's language).
- **FR-009**: When the device's reduce-motion / disable-animations accessibility setting is on, the splash MUST show its final, settled composition immediately with no movement.
- **FR-010**: The hand-off from the splash to the first screen MUST be a short fade, and the splash MUST NOT remain in back-navigation history.

#### Startup hand-off

- **FR-011**: The splash MUST appear without waiting for the app's startup preparation (data store, saved language/theme, onboarding decision); that preparation MUST run while the splash is visible.
- **FR-012**: The splash MUST hand off at the later of (a) the end of its animation (or immediately, under reduced motion) and (b) completion of startup preparation — never later — and MUST NOT add any fixed extra wait.
- **FR-013**: After the splash, the user MUST land on the same destination the app chooses today: onboarding on first launch, the People home screen for returning users, or the target of a notification tapped while the app was closed.
- **FR-014**: Navigation away from the splash MUST happen exactly once per launch, regardless of the order or timing in which animation and preparation finish.
- **FR-015**: Each startup preparation step MUST run exactly once per successful launch; the splash MUST NOT trigger additional loading, network access, or data work of its own.
- **FR-016**: If startup preparation fails, or has not completed within 10 seconds, the splash MUST stop any motion and show a short, localized, non-technical message and a "Try again" action. "Try again" MUST re-run only the preparation that has not yet succeeded and, on success, proceed per FR-012/FR-013.
- **FR-017**: The splash MUST NOT be shown when the app returns from the background, on rotation, on language or theme changes, or at any time other than a launch from a closed state.

#### Localization & accessibility

- **FR-018**: Every piece of text on the splash (name, optional tagline, error message, "Try again") MUST come from the app's existing Arabic and English translations; no text may be hardcoded.
- **FR-019**: The splash MUST lay out correctly in right-to-left (Arabic) and left-to-right (English), including correct Arabic letter shaping for the name.
- **FR-020**: Screen readers MUST announce the app name once and MUST NOT announce decorative elements; when the error state is shown, its message and "Try again" action MUST be announced and operable, with a touch target of at least 48×48 points.
- **FR-021**: All text on the splash MUST meet at least 4.5:1 contrast against its background in both Light and Dark variants, and MUST remain readable and unclipped at the largest system text size.

#### Scope protection

- **FR-022**: The feature MUST NOT change onboarding logic, the People home screen, notification handling, settings behavior, or any other existing screen or business rule beyond what is needed to show the splash first and hand off from it.

### Key Entities

- **Startup readiness**: the outcome of the app's startup preparation — *preparing*, *ready* (with the chosen destination: onboarding or main app), or *failed* (with a user-safe reason). It is transient, exists only during a launch, and is never stored.
- **Splash appearance**: the Light or Dark variant, the reading direction, and whether motion is allowed — all derived from existing app/device settings; nothing new is persisted.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of cold launches tested (Light/Dark × Arabic/English × Android/iOS), the user sees no white or off-brand flash and no visible jump of the mark between the system launch screen and the splash.
- **SC-002**: The splash adds at most 1 second to the time between opening the app and reaching the first usable screen, compared with the same device before this feature; when preparation takes longer than 1 second, the splash adds no measurable time at all.
- **SC-003**: The splash animation plays with no dropped or stuttering frames noticeable to a viewer on a mid-range device, and the splash causes no startup errors or warnings.
- **SC-004**: 100% of launches leave the splash within 10 seconds — either to the correct screen or to the "Try again" message; no launch path remains on the splash indefinitely.
- **SC-005**: In 100% of tested launch scenarios (first launch, returning user, notification cold-start), the destination after the splash matches the destination reached before this feature, and navigation occurs exactly once.
- **SC-006**: With reduce-motion enabled, 0 moving elements are shown.
- **SC-007**: The splash never appears on return from background, rotation, or language/theme change across a scripted session of at least 20 such transitions.
- **SC-008**: All existing automated app tests continue to pass unchanged, other than tests that start the app and must now pass through the splash.
- **SC-009**: In an informal review, people shown the splash can say the app is about money between people (lending, borrowing, owing) or about a personal ledger, rather than describing it as a generic logo screen.

## Assumptions

- "Launch from a closed state" means the app process starting (cold start, or after the operating system ended it). Returning to a still-running app is never a launch.
- Since the app has no sign-in, the "authentication state" referred to in the request is the existing onboarding gate (first launch vs. returning user). If the planned app lock (feature 015) ships later, it will sit after the splash; designing for it is out of scope here.
- The existing launcher icon artwork is the source of the splash mark; it may be simplified or re-drawn for crispness and motion, but not redesigned.
- The brand color field reuses the launcher icon's emerald gradient in Light mode and a deep emerald built from the same brand color in Dark mode, so both variants stay within the current identity.
- The optional tagline, if used, reuses the app's existing plain-language voice (as in onboarding copy) and is added to the existing Arabic and English translations.
- The 10-second limit is a safety net: normal preparation is local-only and is expected to finish well within 1 second.
- The system launch screen follows the device's Light/Dark setting only; a mismatch with an in-app theme override is handled by the crossfade described in Edge Cases.
- No new third-party packages or downloadable animation files are expected; the motion is built with the app's existing capabilities.
- Out of scope: redesigning the launcher icon, onboarding, or home screens; adding sign-in or app lock; showing the splash on resume.
