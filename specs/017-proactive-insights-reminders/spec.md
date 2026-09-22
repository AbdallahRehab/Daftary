# Feature Specification: Proactive Insights & Reminders/Notifications

**Feature Branch**: `017-proactive-insights-reminders`

**Created**: 2026-09-22

**Status**: Draft

**Input**: User description: "Roadmap V3.3 — Proactive Insights & Reminders/Notifications. Local push notifications (flutter_local_notifications, no backend) for budget-limit warnings (sourced from Budgets, spec 010) and savings-goal check-ins (sourced from Savings Goals, spec 011). Every notification MUST be a real, deterministically-computed observation from the user's actual stored data — never fabricated, generic, or AI-hallucinated (constitution Principle VIII). Conceptually depends on the AI Assistant (spec 014) for natural-language phrasing, but must define and ship a fully viable non-AI deterministic-template phrasing path that does not block on 014 existing. Covers user control (per-category enable/disable, quiet hours, contextual permission request), a scheduling/recomputation trigger, a re-notification/cooldown policy to avoid spam, deep-linking from a notification to its source screen, and full Arabic/English + RTL/LTR + light/dark support."

## Clarifications

*No outstanding [NEEDS CLARIFICATION] markers — ambiguities below were resolved with reasonable, documented defaults in Assumptions, following the pattern established in prior specs (e.g. 011-savings-goals).*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Receive a Budget-Limit Warning (Priority: P1)

A user who has set a monthly budget for a category (e.g. Groceries) wants to be proactively told, without having to remember to open the app and check, when their real spending is approaching or has exceeded that limit.

**Why this priority**: This is the feature's most immediately actionable, highest-value notification type — a budget warning that arrives after the money is already spent is far less useful than a preemptive nudge while the user can still change behavior, and this is the scenario the product brief's own example ("you are close to exceeding your shopping budget") is built around.

**Independent Test**: Can be fully tested by creating a budget for a category, adding expense entries that push actual spend past a warning threshold, triggering the feature's recomputation, and confirming a notification is generated with the correct real percentage/amount and that tapping it opens that budget's category detail.

**Acceptance Scenarios**:

1. **Given** a budgeted category (010) reaches 80% of its planned amount for the current month (actual spend computed from real 007 expense entries), **When** the recomputation next runs, **Then** a notification is generated stating the real category name and the real percentage used, sourced entirely from the existing budget-overview computation — never a second, independent spend calculation.
2. **Given** a budgeted category's actual spend exceeds 100% of its planned amount, **When** the recomputation next runs, **Then** a distinct "exceeded" notification is generated (not merely a higher-percentage version of the near-limit warning), reflecting the real overspend amount.
3. **Given** the user taps a budget-limit warning notification, **When** the app opens, **Then** it navigates directly to that specific budgeted category's detail view, not merely to the app's home screen.
4. **Given** a category's spend was already above 80% at the last notification and has not materially changed since, **When** the next scheduled recomputation runs, **Then** the system does NOT send a duplicate notification for the same unchanged condition (see Edge Cases/Assumptions for the exact re-notification policy).
5. **Given** the user has disabled budget-limit notifications specifically (while leaving savings-goal notifications on), **When** a category crosses a warning threshold, **Then** no notification is generated for it, while savings-goal notifications continue to function normally.
6. **Given** no budget exists for the current month for a given category, **When** the recomputation runs, **Then** no notification is generated for that category — there is nothing real to compare against.

---

### User Story 2 - Receive a Savings-Goal Check-In (Priority: P1)

A user with an active savings goal (011) wants an occasional, honest check-in on whether their real contribution pace is on track, ahead, or behind schedule relative to their goal's own plan — without having to open the app and mentally recompute it themselves.

**Why this priority**: This is the feature's second core notification type and directly serves the product brief's own example ("you can reach your savings goal 2 months earlier if you save an additional 750 EGP/month") — equally central to the feature's value as budget warnings, hence also P1.

**Independent Test**: Can be fully tested by creating a savings goal with a monthly contribution plan, letting time/contributions diverge from that plan, triggering recomputation, and confirming a check-in notification reflects the real computed pace using the same deterministic projection logic the goal's own detail screen uses.

**Acceptance Scenarios**:

1. **Given** an active savings goal (011) with a monthly contribution plan and a computed estimated completion, **When** the recomputation runs and the goal's real logged contribution pace is behind what the plan implies for the elapsed time, **Then** a check-in notification is generated stating this in terms of the real numbers (e.g. how far behind, using the goal's own deterministic projection calculation — never a separate estimate).
2. **Given** the same setup but the user's real pace is ahead of plan, **When** the recomputation runs, **Then** a distinct, positively-framed check-in notification is generated reflecting the real ahead-of-schedule amount.
3. **Given** a savings goal has already been marked achieved (011), **When** the recomputation runs, **Then** no further behind/ahead-of-pace check-in is generated for that goal (an achieved goal has nothing left to be "on pace" toward); a one-time achievement notification MAY be generated instead, exactly once per goal reaching achieved status.
4. **Given** the user taps a savings-goal check-in notification, **When** the app opens, **Then** it navigates directly to that specific goal's detail view.
5. **Given** a savings goal has no monthly contribution and no target date set (011's own "no estimate available yet" state), **When** the recomputation runs, **Then** no pace-based check-in is generated for that goal, since there is no real plan to compare actual pace against.
6. **Given** the user has disabled savings-goal notifications specifically (while leaving budget notifications on), **When** a goal's pace changes, **Then** no notification is generated for it, while budget notifications continue to function normally.

---

### User Story 3 - Control Notification Settings (Priority: P2)

A user wants control over whether and when they receive these notifications — turning the feature on or off entirely, toggling each category independently, and defining quiet hours during which no notification is delivered regardless of what's been computed.

**Why this priority**: Meaningful, expected control over any notification feature — but the feature already delivers its core value via User Stories 1-2 with sensible defaults even before a user visits settings, so this is P2 rather than P1.

**Independent Test**: Can be fully tested by opening notification settings, disabling one category, setting quiet hours, and confirming behavior matches exactly (no notification during quiet hours even if a real condition is met; a disabled category never notifies).

**Acceptance Scenarios**:

1. **Given** the user opens notification settings for the first time, **When** the screen loads, **Then** they see this feature described as off by default (Assumptions) with a clear action to enable it, and once enabled, independent toggles for "Budget warnings" and "Savings goal check-ins."
2. **Given** the user enables this feature for the first time, **When** the OS notification permission has not yet been granted, **Then** the system requests it at that exact moment (contextually, not at app startup), with a clear explanation of why, per constitution Principle XII.
3. **Given** the user denies the OS notification permission, **When** they return to notification settings, **Then** the system clearly explains that notifications cannot be delivered without OS permission and offers a link to the device's app-permission settings, without pretending the feature is on when it cannot actually deliver anything.
4. **Given** the user sets quiet hours (e.g. 10 PM–8 AM), **When** a real notification-worthy condition is computed during that window, **Then** the notification is deferred and delivered at the next moment outside quiet hours rather than silently dropped or delivered during quiet hours.
5. **Given** the user disables the entire feature, **When** they do, **Then** all future scheduled recomputation/notification delivery stops immediately, though this feature's disabling has no effect on the underlying Budget/Savings Goal data or calculations themselves.
6. **Given** the user re-enables the feature after having disabled it, **When** they do, **Then** the next recomputation evaluates current real data fresh (not a backlog of everything that would have fired while disabled).

---

### Edge Cases

- What happens when the same budgeted category oscillates around the warning threshold across multiple days (e.g. 79%, 81%, 79%, 82%)? The re-notification/cooldown policy (Assumptions) governs this — the system does not re-notify for every small fluctuation within the same threshold band, only for a materially new condition (crossing into "exceeded" from "near limit," or a new calendar month starting fresh).
- What happens at the start of a new budget month? Every budgeted category's notification state resets, since a new month is a genuinely new condition — a category that was "exceeded" last month starts the new month able to warn again once it independently crosses a threshold in the new month.
- What happens if the device is off or the app is force-quit when a scheduled recomputation would have run? The next time the app is opened (or the next scheduled trigger fires, whichever comes first — see Assumptions on the scheduling mechanism), the recomputation runs against current real data; no attempt is made to "catch up" on missed historical notifications, since only the current real state matters.
- What happens if the AI Assistant (spec 014) is not present in a given build? Every notification is still generated in full, using the deterministic localized message-template path (Assumptions) — this is not a degraded/partial mode, it is this feature's fully complete, independently shippable default behavior.
- What happens if a budget or savings goal is deleted after a notification about it was already delivered but not yet tapped? Tapping the (now-stale) notification navigates to the app's relevant list view (Budgets or Savings Goals) with a graceful "this item no longer exists" state, rather than crashing or showing an error.
- What happens when the user has zero budgets and zero savings goals? The feature's settings remain fully accessible and toggleable, but recomputation simply produces no notifications, since there is nothing real to observe — never a fabricated placeholder notification.
- What happens if the app's language or theme changes while notification settings are open? Layout remains correct, fully legible, and fully localized in RTL/LTR and both themes with no truncation; already-delivered OS notification text is not retroactively translated (it was generated once, in the language active at generation time), but all future notifications and the settings UI itself always reflect the currently active language.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST periodically evaluate the user's real Budget (010) and Savings Goal (011) data and generate at most one notification per budgeted category per distinct condition-change, and at most one pace check-in per savings goal per distinct condition-change, per the re-notification policy (Assumptions).
- **FR-002**: Every notification's content MUST be derived entirely from a deterministic computation over the user's actual stored data at generation time (real budget planned/actual amounts via 010's existing aggregation; real savings goal progress/pace via 011's existing deterministic projection) — the system MUST NEVER generate a notification containing a fabricated, generic, placeholder, or otherwise not-actually-computed number or claim.
- **FR-003**: The system MUST generate a "near limit" budget notification when a budgeted category's percentage-used crosses into the same near-full warning threshold already established by 010 (FR-008 of that spec), and a distinct "exceeded" notification when actual spend surpasses the planned amount — both sourced from 010's existing `GetBudgetOverview`-equivalent aggregation, never a second, independently implemented spend calculation.
- **FR-004**: The system MUST generate a savings-goal "behind pace" or "ahead of pace" check-in notification derived from comparing the goal's actual logged contribution history to its own stored monthly-contribution/target-date plan, using 011's existing deterministic projection calculation (`ProjectSavingsCompletion`-equivalent) — never a second, independently implemented projection.
- **FR-005**: The system MUST NOT generate a pace-based savings-goal notification for a goal that has no monthly contribution and no target date set (011's "no estimate available" state), since no real plan exists to compare against.
- **FR-006**: The system MUST NOT generate a further pace-based check-in for a goal already marked achieved (011); the system MAY generate a one-time achievement notification, delivered at most once per goal per time it newly reaches achieved status.
- **FR-007**: Every notification generated by this feature, when it lacks a natural-language phrasing provided by an available AI Assistant (spec 014), MUST be composed from a deterministic, fully localized (Arabic/English) message template populated with the real computed values (e.g. category name, percentage, amount, goal name, months ahead/behind) — this deterministic-template path MUST be fully functional and independently shippable with zero dependency on spec 014 existing or being enabled.
- **FR-008**: If an AI Assistant (spec 014) is present, enabled, and available at generation time, the system MAY use it only to rephrase a notification's wording around the same already-deterministically-computed values — the AI MUST NEVER be the source of the underlying number, comparison, or claim itself (constitution Principle VIII/IX), and any AI-phrasing failure or unavailability MUST fall back to the deterministic template path (FR-007) without failing to deliver the notification.
- **FR-009**: The system MUST allow the user to enable or disable this feature entirely, and independently enable or disable each of its two notification categories (budget warnings, savings-goal check-ins).
- **FR-010**: The system MUST default this feature to fully disabled (no notifications, no OS permission request) until the user explicitly enables it, consistent with the app's existing opt-in pattern for sensitive/permission-gated features.
- **FR-011**: The system MUST request OS-level notification permission only at the moment the user first enables this feature (contextually), never at app startup, and MUST show a clear rationale at that moment, per constitution Principle XII.
- **FR-012**: When OS notification permission is denied or later revoked, the system MUST clearly reflect this in the feature's settings UI (rather than silently appearing enabled while unable to deliver anything) and MUST offer a direct path to the device's app-permission settings.
- **FR-013**: Users MUST be able to configure a quiet-hours window during which no notification is delivered; a notification whose real underlying condition is computed during quiet hours MUST be deferred and delivered at the next moment outside the quiet-hours window, never silently dropped and never delivered inside the window.
- **FR-014**: Tapping a budget-limit notification MUST navigate the user directly to that specific budgeted category's detail view; tapping a savings-goal notification MUST navigate directly to that specific goal's detail view; tapping a notification whose underlying Budget/Savings Goal record no longer exists MUST navigate to the relevant feature's list view with a graceful "no longer exists" state, never a crash or raw error.
- **FR-015**: The system MUST NOT re-notify for a condition that has not materially changed since the last notification for that same category/goal (the specific re-notification/cooldown policy is documented in Assumptions) — this MUST prevent daily repeat notifications for an unchanged 85%-of-budget state.
- **FR-016**: A new calendar month MUST reset each budgeted category's notification state, allowing a category that previously triggered "exceeded" in a prior month to independently warn again in the new month based on that new month's own real data.
- **FR-017**: The system MUST perform its recomputation entirely on-device, on a schedule/trigger defined in Assumptions, with no backend, no push-notification service, and no network call of any kind involved anywhere in this feature.
- **FR-018**: Disabling this feature (FR-009) MUST immediately stop all future scheduled recomputation and notification delivery, and MUST have zero effect on any underlying Budget (010) or Savings Goal (011) data, record, or calculation.
- **FR-019**: Re-enabling this feature after being disabled MUST evaluate only the current real state of the user's data going forward — it MUST NOT attempt to retroactively deliver notifications for conditions that would have fired while disabled.
- **FR-020**: The system MUST present all screens and OS notification content introduced by this feature fully localized in Arabic and English, with correct RTL/LTR layout for the settings screen, and correctly themed in both light and dark mode for the settings screen.
- **FR-021**: The system MUST NOT alter, migrate, or affect any existing Budget (010), Savings Goal (011), or any other feature's data or calculations as part of this feature — this feature only reads existing aggregation/projection results and schedules local notifications; it introduces no new financial data of its own beyond its own notification-history/settings bookkeeping.

### Key Entities *(include if feature involves data)*

- **Notification Preference**: The user's configuration for this feature — whether it is enabled overall, whether each of the two categories (budget warnings, savings-goal check-ins) is independently enabled, and the configured quiet-hours window (start/end time). A single record per device, not a list.
- **Notification History Entry**: A record of a specific notification already delivered for a specific source (a budgeted category in a specific month, or a savings goal), storing enough state (e.g. the threshold band last notified, the month it applies to) to support the re-notification/cooldown policy (FR-015) without re-delivering for an unchanged condition. Exists purely as this feature's own internal bookkeeping — never a second source of truth for any budget/savings figure, which always remain freshly computed from 010/011 at generation time.
- **Scheduled Recomputation Trigger** *(not a persisted entity — a scheduling concept)*: The mechanism (Assumptions) by which this feature periodically re-evaluates real data; conceptually distinct from any notification content itself.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of notifications generated by this feature, across a test suite of at least 20 varied budget/savings-goal scenarios, contain a number/claim that exactly matches what the corresponding Budget (010) or Savings Goal (011) detail screen would independently show for the same data at the same moment — zero discrepancies.
- **SC-002**: A user can enable this feature, grant OS permission, and have a real, already-existing over-budget condition generate a correctly-worded notification within one recomputation cycle (Assumptions define the cycle), with zero manual refresh required.
- **SC-003**: Across a 30-day simulated test period with an unchanged 85%-of-budget condition held constant, the user receives exactly one notification for that condition (at the point it was first crossed), not 30 — verifying the re-notification/cooldown policy (FR-015).
- **SC-004**: Tapping any of at least 10 varied test notifications (mixing budget-warning, budget-exceeded, savings-behind, savings-ahead, and savings-achievement types) navigates to the exact correct source screen 100% of the time.
- **SC-005**: A user can fully disable this feature and confirm zero notifications are delivered over a subsequent test period with multiple real trigger-worthy conditions present, with zero effect on the underlying Budget/Savings Goal data (spot-checked before/after).
- **SC-006**: Setting a quiet-hours window results in zero notifications delivered during that window across a test period with multiple real trigger-worthy conditions occurring inside it, with each deferred notification still delivered once the window ends.
- **SC-007**: Switching the app language between Arabic and English, or switching between light and dark mode, produces zero layout, alignment, or truncation defects on the notification settings screen.

## Assumptions

- **Feature ships fully functional without the AI Assistant (spec 014)**: Per this task's explicit instruction and ROADMAP-PLAN.md's own framing (AI Assistant is a "benefits from" dependency, not a blocking one), this spec defines a complete, deterministic, localized message-template phrasing path (FR-007) as the feature's actual default — not a fallback bolted on later. If/when spec 014 exists and is enabled, it may optionally rephrase the same deterministically-computed values (FR-008), but this spec's own acceptance criteria and test plan are written entirely against the template path, since that is what can be verified today.
- **Recomputation trigger/schedule**: Recomputation runs (a) once per calendar day at a fixed local time (e.g. a time near typical morning app-check habits, exact time a product-copy/UX decision at implementation time), and (b) opportunistically whenever the app is foregrounded and more than a minimum interval (e.g. 6 hours) has passed since the last recomputation — combining a guaranteed daily check with a "catch up if you open the app" check, without requiring the app to run persistently in the background, consistent with the app's offline-first, non-backend-dependent architecture and `flutter_local_notifications`' local-scheduling model.
- **Re-notification/cooldown policy**: A given budgeted category or savings goal only generates a new notification when its **threshold band** changes (e.g. below-warning → near-limit → exceeded for budgets; on-pace → behind-pace / ahead-of-pace / achieved for savings goals), not on every recomputation while it remains in the same band — this directly satisfies FR-015/SC-003 and mirrors common, well-understood mobile-notification UX conventions (state-change-triggered, not polling-frequency-triggered). A new calendar month always resets a budgeted category's band to "not yet notified" (FR-016), since a new month is definitionally a new, real condition.
- **Quiet hours default**: Off by default (no quiet hours configured) until the user sets one, consistent with this feature's overall default-disabled posture (FR-010) — once the user has already opted in to notifications at all, the quiet-hours field on the notification-settings screen is pre-filled with a suggested **22:00–08:00 device-local time** starting point (resolved 2026-09-22, `/speckit-analyze`; previously left as an unresolved "MAY... refinable at implementation time" range). This is a suggested, fully user-editable default value stored in `Notification Preference` — never a hardcoded behavioral constant (constitution Principle XV) — the user can change either boundary or turn quiet hours back off entirely at any time. Applies only to this feature's two non-urgent notification categories (budget warnings, savings check-ins); the app has no time-critical/urgent notification category as of this spec.
- **Notification History Entry storage**: A small new local table (e.g. `NotificationHistory`), additive to `AppDatabase` per the existing migration convention — this is the only new persisted data this feature introduces; it stores no financial figures of its own (no duplicated amounts/percentages), only enough state (source id, last-notified band, applicable month/period) to implement the cooldown policy, so it can never become a second, driftable source of truth for any actual budget/savings number.
- **Two notification categories, not more**: Scoped exactly to budget-limit warnings and savings-goal check-ins per the roadmap's own explicit scope (ROADMAP-PLAN.md §V3.3) — no bill-due-date reminders, no generic "check in on your finances" nudges, and no other insight category are introduced by this spec; a future spec may add further categories to this same underlying scheduling/preference infrastructure without requiring architectural rework, since `Notification Preference` is already modeled as per-category toggles.
- **Currency/financial data**: This feature computes no financial figures of its own — every number in every notification is read from 010's/011's own already-computed, already-tested aggregation and projection results, reinforcing FR-002/FR-003/FR-004's "never a second computation path" requirement.
- **Navigation placement**: A "Notifications" section reachable from Settings, alongside the existing Language/Theme/Security (015) sections — exact placement is a navigation/IA decision made at planning time, not a behavioral requirement of this spec.
- **Dependency posture**: This feature is specified now, alongside Budgets (010) and Savings Goals (011), both of which are already spec'd (though not necessarily yet implemented) in this repository — consistent with this session's broader instruction to specify V3 features ahead of V2 implementation. This feature's own `/speckit-plan` and `/speckit-tasks` should note that meaningful end-to-end testing requires 010/011 to be implemented first, but the spec itself is written against their already-completed spec.md contracts (`GetBudgetOverview`-equivalent, `GetSavingsGoalDetail`/`ProjectSavingsCompletion`-equivalent), not against speculative behavior.
