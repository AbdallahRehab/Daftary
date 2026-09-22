# Feature Specification: App Lock (Biometric/PIN) & Screenshot Protection

**Feature Branch**: `015-app-lock-security`

**Created**: 2026-09-22

**Status**: Draft

**Input**: User description: "Roadmap V3.1 — App Lock (Biometric/PIN) & Screenshot Protection. Ground this in docs/project.txt section 15 (SECURITY) and the constitution's Principle XII (Security and Secrets Management). This is purely additive security hardening layered over the entire existing app (People, Transactions, and every future finance feature) — it has no dependency on any other unbuilt feature. The user can enable an app lock that gates access to the entire app on launch and on resume-from-background after a configurable inactivity timeout, with two selectable unlock methods (device biometric via local_auth, and a numeric PIN stored only as a salted hash in OS secure storage), a lockout/rate-limiting policy, a destructive-only 'forgot PIN' recovery path (no backend exists to email a reset code), always-on screenshot/screen-recording protection while foregrounded (FLAG_SECURE-equivalent on Android, a privacy overlay on iOS), and a new Security section in Settings. Opt-in, off by default; introduces flutter_secure_storage since the app has none today."

## Clarifications

*No outstanding [NEEDS CLARIFICATION] markers — ambiguities below were resolved with reasonable, documented defaults in Assumptions, following the pattern established in prior specs (e.g. 011-savings-goals).*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enable App Lock and Set a PIN (Priority: P1)

A user handling sensitive financial data (person debts, income/expense, savings) wants to require authentication before anyone — including someone who picks up their unlocked phone — can open Daftary and see their money data.

**Why this priority**: Without a way to turn the feature on and set a working unlock method, nothing else in this feature has any effect. This is the entire foundation.

**Independent Test**: Can be fully tested by opening Security settings, enabling App Lock, setting a PIN (entered twice, matching), backgrounding and reopening the app, and confirming the lock screen appears and the correct PIN unlocks it.

**Acceptance Scenarios**:

1. **Given** App Lock has never been configured, **When** the user opens Settings, **Then** a "Security" section is visible with App Lock shown as off, and the rest of the app behaves exactly as it does today (no lock screen appears anywhere).
2. **Given** the user turns App Lock on for the first time, **When** they are prompted to set a PIN, **Then** they must enter a PIN of the required length twice with both entries matching before App Lock activates.
3. **Given** the user enters two different PINs during setup (first entry vs. confirmation), **When** they attempt to confirm, **Then** the system rejects the mismatch, explains it, and lets them re-enter without losing the first digit they typed correctly.
4. **Given** App Lock is enabled with a PIN, **When** the user backgrounds the app and reopens it, **Then** a lock screen requiring the PIN (or biometric, if also enabled) is shown before any app content (People, Transactions, balances) becomes visible or readable.
5. **Given** the user is on the lock screen, **When** they enter the correct PIN, **Then** the app unlocks and returns them to exactly the screen they were on before backgrounding.
6. **Given** the user is on the lock screen, **When** they enter an incorrect PIN, **Then** the system rejects it, shows a clear error, and does not unlock.

---

### User Story 2 - Unlock with Biometrics, with PIN Fallback (Priority: P1)

A user with a fingerprint sensor or Face ID wants to unlock Daftary instantly without typing a PIN each time, while still having a reliable fallback when biometrics can't be used.

**Why this priority**: Biometric unlock is the fastest, most frequently used path in daily use once App Lock is on — without a dependable fallback, any biometric hiccup (smudged sensor, poor lighting, forgotten enrollment) would lock the user out of their own financial data entirely, which is unacceptable for a P1 feature.

**Independent Test**: Can be fully tested by enabling biometric unlock on a device with biometrics enrolled, confirming the lock screen offers biometric prompt automatically, then simulating a biometric failure/unavailability and confirming PIN entry is always reachable as a fallback.

**Acceptance Scenarios**:

1. **Given** the device has biometrics enrolled and the user enables biometric unlock in Security settings, **When** they next reach the lock screen, **Then** the biometric prompt is offered automatically (not requiring an extra tap) alongside a visible option to enter the PIN instead.
2. **Given** biometric unlock is enabled, **When** the user successfully authenticates with their fingerprint/face, **Then** the app unlocks immediately without requiring PIN entry.
3. **Given** biometric unlock is enabled, **When** biometric authentication fails (wrong finger, poor read) or is cancelled by the user, **Then** the system allows retrying the biometric prompt or switching to PIN entry, and does not count a biometric failure toward the PIN lockout counter (User Story 3).
4. **Given** the user enables biometric unlock, **When** the device has no biometrics enrolled or no biometric hardware at all, **Then** the system disables the biometric toggle with a clear explanation and requires a PIN as the unlock method instead.
5. **Given** biometric unlock was previously enabled, **When** the device's enrolled biometrics change (e.g. all fingerprints removed) or the OS reports biometrics are no longer available, **Then** the lock screen falls back to PIN entry automatically and informs the user biometric unlock needs to be re-confirmed in Security settings.
6. **Given** the user has both biometric and PIN unlock enabled, **When** they reach the lock screen, **Then** they can always manually switch to PIN entry even if the biometric prompt is showing.

---

### User Story 3 - Lockout After Repeated Wrong PIN Attempts (Priority: P2)

A user (or someone else attempting to guess it) enters the wrong PIN multiple times; the app needs to slow down further attempts so a PIN can't be brute-forced, without permanently locking the legitimate owner out.

**Why this priority**: This is a safety mechanism that matters once PIN unlock already works (User Story 1) — it hardens the feature but the app is still meaningfully protected without it for a first pass, so it's P2 rather than P1.

**Independent Test**: Can be fully tested by deliberately entering the wrong PIN the configured number of times in a row and confirming an escalating cooldown is enforced, then confirming the correct PIN works again once the cooldown expires.

**Acceptance Scenarios**:

1. **Given** the user enters the wrong PIN repeatedly, **When** they reach the configured failed-attempt threshold, **Then** PIN entry is temporarily disabled for a cooldown period, clearly displayed with a countdown or clear end condition.
2. **Given** the user is in a lockout cooldown, **When** the cooldown expires, **Then** PIN entry becomes available again automatically, with no other action required.
3. **Given** the user continues to fail after a cooldown expires, **When** they exceed a further threshold, **Then** the cooldown escalates (longer than the previous one) rather than repeating the same short cooldown indefinitely.
4. **Given** the user is in a PIN lockout cooldown and biometric unlock is also enabled and available, **When** they attempt biometric unlock, **Then** biometric authentication remains available as an independent unlock path (a PIN lockout does not block biometric attempts, since a wrong PIN guess is not evidence the legitimate biometric owner is doing anything wrong).
5. **Given** a failed PIN attempt occurs, **When** the system records it for the lockout counter, **Then** the attempted PIN value itself is never logged, stored in plaintext, or included in any diagnostic output — only a count and timestamp are retained.

---

### User Story 4 - Recover Access After Forgetting the PIN (Priority: P2)

A user who set a PIN, enabled App Lock, and later forgot the PIN (and has no biometric enrolled, or biometric also fails) needs an honest way to regain access to the app, understanding clearly that — because Daftary has no backend or account system — the only available recovery is resetting the app's local data.

**Why this priority**: This is a necessary safety valve for a purely local security feature — without it, a forgotten PIN would permanently and irrecoverably strand a user out of their own financial data, which is a severe enough consequence to warrant its own story, though it is secondary to the core lock/unlock mechanics.

**Independent Test**: Can be fully tested by triggering "Forgot PIN" from the lock screen, confirming biometric re-authentication is offered first when available, and confirming the only non-biometric path is a clearly explained, strongly confirmed, irreversible local data wipe that returns the app to a fresh-install state.

**Acceptance Scenarios**:

1. **Given** the user is on the PIN lock screen and taps "Forgot PIN," **When** biometric unlock is enabled and available on the device, **Then** the system offers biometric authentication as a way to regain access and, on success, lets the user set a new PIN without losing any app data.
2. **Given** the user taps "Forgot PIN" and biometric unlock is unavailable or not enabled, **When** they proceed, **Then** the system clearly explains that no other recovery exists besides erasing all local app data, and does not offer or imply any other recovery mechanism (no fake "email reset code," no support-ticket flow).
3. **Given** the user proceeds with the local-data-wipe recovery path, **When** they confirm, **Then** the system requires an explicit, strong, typed or double-tap confirmation (consistent with the constitution's Financial Domain Override for the app's most destructive actions) before erasing anything.
4. **Given** the user confirms the wipe, **When** it executes, **Then** all local app data (People, Transactions, every other feature's data, and the App Lock configuration itself) is erased atomically, and the app returns to its first-launch/Onboarding state exactly as if freshly installed.
5. **Given** the user cancels at any point in the "Forgot PIN" flow before final confirmation, **When** they back out, **Then** no data is altered and they are returned to the normal lock screen.

---

### User Story 5 - Screenshot and Screen-Recording Protection (Priority: P2)

A user wants confidence that a screenshot, screen recording, or an app-switcher/recents-list thumbnail can never casually expose their financial data — for example, someone glancing at their phone's recent-apps view, or a screen-recording app running for an unrelated reason.

**Why this priority**: This protects against a different, real threat (passive visual exposure of live financial data) than App Lock does (device access while backgrounded); it's independently valuable and ships even for users who never turn on App Lock at all, but is P2 because it's a hardening layer rather than the feature's primary access-control mechanism.

**Independent Test**: Can be fully tested by putting the app in the foreground, attempting a screenshot/screen recording (or, on Android, checking the app-switcher thumbnail), and confirming financial content is blocked or obscured, independent of whether App Lock itself is enabled.

**Acceptance Scenarios**:

1. **Given** the user is anywhere in the app with content visible, **When** they attempt to take a screenshot or start a screen recording, **Then** the captured/recorded output does not contain the app's financial content (blocked entirely on platforms that support it, obscured on platforms that don't).
2. **Given** the user switches to the OS app-switcher/recents view, **When** Daftary's thumbnail is shown, **Then** it displays a neutral, branded placeholder rather than the last visible financial screen.
3. **Given** screenshot protection is active, **When** the user uses the app's own legitimate export/share features (e.g. a future Reports/Data Export flow), **Then** those flows are unaffected — screenshot protection only blocks OS-level screen capture, never the app's own intentional data-sharing mechanisms.
4. **Given** the user has App Lock turned off entirely, **When** they use the app normally, **Then** screenshot/recording protection still applies, since it is independent of App Lock (Assumptions).

---

### User Story 6 - Manage Security Settings (Priority: P3)

A user wants to review and adjust their security configuration over time — change their PIN, switch which unlock methods are active, adjust how quickly the app locks after backgrounding, or turn App Lock off entirely.

**Why this priority**: This is ongoing configuration convenience once the feature already works end-to-end (User Stories 1-5) — valuable but not required for the feature to deliver its core protection on day one.

**Independent Test**: Can be fully tested by opening Security settings with App Lock already enabled, changing the PIN, changing the inactivity timeout, disabling biometric unlock, and confirming each change takes effect immediately and correctly on the next lock/unlock cycle.

**Acceptance Scenarios**:

1. **Given** App Lock is enabled, **When** the user chooses "Change PIN" in Security settings, **Then** they must first authenticate (PIN or biometric) before being allowed to set a new PIN (entered twice, matching).
2. **Given** App Lock is enabled with a chosen inactivity timeout, **When** the user changes it to a different duration, **Then** the new duration takes effect on the very next time the app is backgrounded.
3. **Given** both biometric and PIN unlock are enabled, **When** the user disables biometric unlock, **Then** subsequent lock screens only offer PIN entry, and any previously stored biometric-preference state is cleared.
4. **Given** the user disables App Lock entirely, **When** they confirm, **Then** the app immediately stops presenting a lock screen on launch/resume, though screenshot protection (User Story 5) remains active regardless.
5. **Given** the user disables App Lock, **When** they later re-enable it, **Then** they must go through PIN setup again (User Story 1) — no PIN is silently remembered or reused from a prior configuration for security hygiene.

---

### Edge Cases

- What happens when the app is backgrounded briefly for a system interruption (an incoming call, a permission dialog, switching to the share sheet to save an export, a keyboard-related app switch) rather than a genuine backgrounding? The system MUST distinguish a brief, expected interruption from real backgrounding and MUST NOT trigger a lock screen for the former; only backgrounding that persists past the configured inactivity timeout triggers a lock.
- What happens if the user force-quits and relaunches the app while App Lock is enabled? The lock screen MUST always appear on a fresh launch, regardless of the inactivity timeout setting (a full relaunch is always treated as requiring authentication).
- What happens when the device itself has no lock screen / passcode set at the OS level? App Lock and its PIN are independent of the OS-level device lock; Daftary's own PIN still applies regardless of whether the device has its own lock configured.
- What happens if the user changes the OS language or app theme while the lock screen or PIN pad is visible? Both must remain fully legible, correctly laid out, and fully localized in RTL/LTR and both themes with no layout break.
- What happens when the "Forgot PIN" data-wipe path is used but App Lock's own settings row is what triggered it (not the lock screen itself)? The same honest, no-backend-recovery explanation and confirmation flow applies regardless of entry point.
- What happens if the user is mid-lockout-cooldown (User Story 3) and force-quits and relaunches the app? The cooldown MUST persist across relaunch (state stored, not merely in-memory), since otherwise the lockout could be trivially bypassed by restarting the app.
- What happens to screenshot protection during the "Forgot PIN" data-wipe confirmation itself? It remains active — the destructive confirmation screen is exactly as sensitive as any other financial screen and must not be exempted.
- What happens on a platform where blocking screen recording outright isn't possible (iOS has no API to prevent screen recording the way Android's `FLAG_SECURE` does)? The system falls back to detecting an active recording and immediately applying the same obscuring overlay used for the app-switcher thumbnail for as long as the recording is active, rather than silently doing nothing.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a "Security" section in Settings where the user can enable or disable App Lock; App Lock MUST be off by default for both new installs and existing users upgrading to a version that includes this feature (no silent opt-in).
- **FR-002**: When the user enables App Lock for the first time, the system MUST require setting a PIN (entered twice, both entries matching) before App Lock becomes active; App Lock MUST NOT activate with zero configured unlock methods.
- **FR-003**: The system MUST enforce a minimum PIN length of 4 digits and MUST accept PIN lengths up to 6 digits; the PIN MUST consist of numeric digits only.
- **FR-004**: The system MUST store the PIN only as a salted cryptographic hash in OS-provided secure storage (Keychain on iOS, Keystore-backed secure storage on Android); the raw PIN value MUST NEVER be persisted, logged, cached in plaintext, or transmitted anywhere (this feature makes no network calls at all).
- **FR-005**: The system MUST allow the user to additionally enable biometric unlock (fingerprint/face, via the device's native biometric APIs) whenever the device reports biometric hardware present and at least one biometric enrolled; biometric unlock MUST always be offered as an addition to, never a replacement for, a configured PIN.
- **FR-006**: When biometric unlock is enabled and available, the system MUST present the biometric prompt automatically upon reaching the lock screen, while always keeping a visible, immediately usable option to enter the PIN instead.
- **FR-007**: The system MUST gracefully handle biometric unavailability (no hardware, nothing enrolled, OS-level biometric lockout, or enrollment changing after being enabled) by falling back to PIN entry and informing the user, never leaving them stranded on a non-functional biometric-only screen.
- **FR-008**: A failed biometric attempt MUST NOT count toward the PIN failed-attempt lockout counter (User Story 3), since the two are independent authentication factors.
- **FR-009**: Once App Lock is enabled, the system MUST require successful authentication (PIN or biometric) before revealing any app content: on every full app launch, and on every resume from background where the app was backgrounded longer than the configured inactivity timeout.
- **FR-010**: The system MUST distinguish a genuine backgrounding event from a brief, expected system interruption (e.g. an OS permission dialog, an incoming call overlay, the OS share sheet launched by the app's own export/share feature) and MUST NOT trigger a lock screen for the latter.
- **FR-011**: The system MUST offer a configurable inactivity timeout with the choices: Immediately, After 30 seconds, After 1 minute, After 5 minutes; the default for a newly enabled App Lock MUST be "After 1 minute."
- **FR-012**: The system MUST reject an incorrect PIN attempt with a clear, non-technical error message and MUST NOT unlock the app.
- **FR-013**: The system MUST track consecutive failed PIN attempts and, upon reaching 5 consecutive failures, MUST enforce a temporary cooldown during which PIN entry is disabled; the cooldown MUST escalate on continued failures (30 seconds after the 5th failure, 2 minutes after the 8th, 5 minutes after every 3 additional failures beyond that) rather than repeating a fixed short cooldown indefinitely.
- **FR-014**: A successful PIN or biometric unlock MUST reset the consecutive-failed-attempt counter to zero.
- **FR-015**: The failed-attempt lockout state (attempt count, cooldown end time) MUST persist across an app relaunch or force-quit — it MUST NOT be resettable simply by restarting the app.
- **FR-016**: The system MUST NEVER log, store in plaintext, or include in any diagnostic/crash output the value of any PIN entry attempt, whether correct or incorrect — only a non-reversible attempt count and timestamp may be retained for the lockout mechanism.
- **FR-017**: The system MUST provide a "Forgot PIN" path reachable from the lock screen; if biometric unlock is enabled and available, this path MUST first offer biometric re-authentication as a way to set a new PIN without any data loss.
- **FR-018**: When biometric re-authentication is unavailable or not enabled, the "Forgot PIN" path's only recovery option MUST be an explicit, clearly explained, strongly confirmed erasure of all local app data (returning the app to a fresh-install state); the system MUST NOT present or imply any other recovery mechanism (no email/SMS reset code, no support-ticket flow, no backdoor), since no backend or account system exists to support one.
- **FR-019**: The local-data-wipe recovery action MUST require an explicit strong confirmation step (e.g. typed confirmation phrase or equivalent deliberate double-confirmation) before executing, consistent with the constitution's Financial Domain Override for the app's most destructive actions, and MUST be atomic (either the entire wipe succeeds, or no data is altered).
- **FR-020**: The system MUST apply screen-capture protection while the app is in the foreground, at all times, independent of whether App Lock itself is enabled: preventing or blacking out screenshots and screen recordings where the platform provides a mechanism to do so, and substituting a neutral branded placeholder for the app's thumbnail in the OS app-switcher/recents view.
- **FR-021**: On a platform where outright screen-recording prevention is not available, the system MUST detect an active recording session and apply an obscuring overlay over the app's content for the duration of the recording, rather than leaving financial content exposed with no mitigation.
- **FR-022**: Screen-capture protection MUST NOT interfere with the app's own legitimate data-export/share flows (e.g. a future OS share-sheet-based export) — it blocks only unsanctioned OS-level screen capture, never the app's intentional data-output mechanisms.
- **FR-023**: The user MUST be able to change their PIN, and doing so MUST require successful authentication (current PIN or biometric) first, followed by entering and confirming a new PIN.
- **FR-024**: The user MUST be able to enable/disable biometric unlock independently of the PIN, at any time, from Security settings, without needing to reset or re-enter the existing PIN.
- **FR-025**: The user MUST be able to change the inactivity timeout at any time; the new value MUST take effect starting with the next time the app is backgrounded.
- **FR-026**: The user MUST be able to disable App Lock entirely from Security settings (after authenticating); doing so MUST immediately stop lock-screen presentation on subsequent launches/resumes, while leaving screenshot protection (FR-020) unaffected since it is independent of App Lock.
- **FR-027**: If a user disables and later re-enables App Lock, the system MUST require setting a new PIN from scratch (FR-002) rather than silently restoring or reusing any previously configured PIN, as a security hygiene measure.
- **FR-028**: The system MUST keep all App Lock and screenshot-protection functionality fully operational with no network connection, consistent with the app's existing offline-first architecture; this feature MUST NOT introduce any network call.
- **FR-029**: The system MUST present all new screens introduced by this feature (lock screen, PIN pad, PIN setup/change, Security settings section, Forgot-PIN flow, data-wipe confirmation) fully localized in Arabic and English, with correct RTL/LTR layout, and correctly themed in both light and dark mode.
- **FR-030**: The system MUST NOT alter, migrate, or affect any existing People, Transactions, or other feature's data or calculations as part of enabling, configuring, or using App Lock — the only data this feature introduces is its own security configuration (PIN hash, salt, enabled unlock methods, timeout setting, lockout counters).

### Key Entities *(include if feature involves data)*

- **App Lock Configuration**: The user's security setup — whether App Lock is enabled, which unlock methods are active (PIN, biometric, or both), the configured inactivity timeout, and whether screenshot protection is user-configurable (per Assumptions, it is always-on and not a toggle in this spec). Lives entirely in OS secure storage, never in the app's regular SQLite database, since it governs access to that database's contents.
- **PIN Credential**: The user's chosen PIN, represented only as a salted cryptographic hash plus its salt — never the raw digits. Includes the timestamp it was last changed, for potential future auditing, but never a plaintext or reversibly-encrypted form.
- **Lockout State**: The consecutive failed-PIN-attempt count and the current cooldown's end timestamp, if any. Persisted (not merely in-memory) so a relaunch cannot bypass an active cooldown; reset to zero on any successful unlock.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can enable App Lock and set a working PIN in under 60 seconds on first setup.
- **SC-002**: 100% of app launches and out-of-timeout resumes, once App Lock is enabled, require successful authentication before any financial content (person balances, transaction amounts, any screen) becomes visible — verified with zero exceptions across at least 20 varied launch/resume/interruption scenarios (including the brief-interruption edge cases).
- **SC-003**: A user who forgets their PIN and has biometric unlock available can regain full access, without any data loss, in under 30 seconds.
- **SC-004**: A user who forgets their PIN with no biometric available is never given a false impression that any non-destructive recovery exists; 100% of the "Forgot PIN" copy accurately reflects that the wipe is the only option in that case.
- **SC-005**: Across at least 15 attempts of trying to capture app content via screenshot, screen recording, or the app-switcher thumbnail while the app is foregrounded, zero attempts expose actual financial data — verified regardless of whether App Lock is separately enabled.
- **SC-006**: An attacker attempting to brute-force a 4-digit PIN is slowed to no more than roughly 1 guess per 30+ seconds of sustained real-time effort once the escalating lockout engages, verified by simulating repeated failures and measuring enforced cooldown durations against FR-013.
- **SC-007**: Switching the app language between Arabic and English, or switching between light and dark mode, produces zero layout, alignment, or truncation defects on the lock screen, PIN pad, Security settings, or any Forgot-PIN/data-wipe screen.
- **SC-008**: Zero instances of a PIN value (correct or incorrect attempt) appearing in application logs, crash reports, or any diagnostic output, verified by code review and log-output inspection across the full PIN entry/verification code path.

## Assumptions

- **Screenshot protection is always-on, not a user toggle**: Unlike App Lock, this spec makes foreground screen-capture protection (FR-020/FR-021) unconditional and not exposed as a settings toggle. Rationale: the product brief (`docs/project.txt` §15) lists "screenshot protection where appropriate" as a security baseline, not an optional convenience, and there is no legitimate identified user need in this app for taking a screenshot of live person-balance/transaction data that would justify a toggle that could be silently left on by mistake. If a genuine "for my own records" use case emerges later, a toggle can be added without any data-model change — this is a UI-only refinement.
- **PIN length**: 4-6 numeric digits, with a required confirm-entry step on setup and change. This mirrors the most common mobile app-lock convention (matching typical OS-level PIN/passcode UX) and keeps entry fast on a numeric pad, which matters since this screen is hit on every app open once enabled.
- **Inactivity timeout choices and default**: Immediately / 30s / 1min / 5min, defaulting to 1 minute. This balances security (not leaving the app unlocked indefinitely in the background) against convenience (not re-prompting for every brief app-switch), matching common patterns from other security-conscious mobile apps (e.g. banking apps typically default in this range).
- **Lockout thresholds**: 5 consecutive failures trigger the first 30-second cooldown; 8 consecutive trigger a 2-minute cooldown; every 3 additional failures beyond that add a further 5-minute cooldown. No maximum-attempts hard lockout is imposed (no permanent lockout), since this app has no backend/support channel that could ever unlock a permanently-locked account — the escalating cooldown alone provides the brute-force deterrent while the "Forgot PIN" data-wipe path remains the ultimate recovery valve.
- **No backend means recovery is inherently destructive**: Because Daftary is (and remains, per this feature's own scope) a fully local, offline-only, no-account application, there is no mechanism (email, SMS, support desk) through which a "forgot my PIN" request could be verified against a real identity. The only honest recovery path that doesn't secretly weaken the PIN's protection is therefore a full local data wipe — this is a deliberate security/UX trade-off, not an oversight, and is called out explicitly in the user-facing copy so it never feels like a bait-and-switch.
- **Biometric availability check uses the device's native capability query**: Whether biometric hardware exists and has at least one enrollment is queried live at the point the user tries to enable it (and again each time the lock screen is shown), rather than cached indefinitely, since enrollment can change at any time (e.g. the user removes all fingerprints from their device settings) and the app must react to that rather than continuing to assume biometrics work.
- **Currency/financial data**: Not applicable to this feature's own entities, but the entire reason for its existence is protecting the app's existing financial data (People, Transactions, and every V1.5/V2 finance feature) — this spec adds no new financial calculation of its own.
- **Secure storage dependency**: This is the first feature in the codebase to introduce `flutter_secure_storage` (or an architecturally equivalent OS-secure-storage abstraction) as a new dependency — justified because no existing capability in the app can store a secret (a PIN hash/salt) outside of the regular, less-protected SQLite database. Sequenced independently of the AI Assistant feature (specs/014), which was expected to be the first to need this; either feature introduces the same dependency once, not twice — if 014 lands the dependency first, this feature reuses it rather than adding a second one.
- **Navigation placement**: A new "Security" section is added inside the existing Settings screen; the lock screen itself is a full-screen, non-dismissible overlay shown above all app navigation (not a route within `go_router`'s normal stack), consistent with how a lock screen must pre-empt every other screen. Exact widget-level placement is a decision for this feature's own `/speckit-plan`, not a behavioral requirement of this spec.
