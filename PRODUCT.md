# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

[Confirmed: single unified Material 3 design language for both Android and iOS — no Cupertino-specific adaptation. Recorded as `android` because Material is the one design language actually implemented; iOS builds render the same Material UI rather than adapting per-OS. Do not introduce Cupertino affordances (back-swipe gestures, iOS-style pickers/switches) unless the user changes this decision.]

## Stack

Flutter (Dart SDK ^3.10.0), Material 3, `flutter_bloc`/Cubit for state, `go_router` for navigation, `drift` (SQLite) for local persistence, `get_it` + `injectable` for DI, `flutter_localizations`/`intl` for i18n. Existing codebase — not a stack decision for this task.

## Users

Individual Egyptian users (Arabic-first, English-supported) who exchange money informally with people in their life — friends, family, colleagues — and need to remember who owes them and who they owe. The target user has no accounting or bookkeeping background; the product must feel like "someone who remembers my money for me," not a ledger app for professionals. [Inferred from docs/project.txt master brief and the app's actual terminology (people, money given/received, balances, EGP currency); confirmed by the app being local-first with no auth/backend, i.e., built for a single individual's own device.]

## Product Purpose

Daftary ("my notebook/ledger" in Arabic) lets a user create a person and record money given to or received from them over time, so the running balance ("they owe you" / "you owe them" / "settled") is always clear without mental math or a paper notebook. Success is a user trusting the app's numbers enough to stop tracking debts in their head or on paper, and being able to answer "does X still owe me money, and how much?" in one glance.

## Positioning

Unlike a generic expense tracker or a general ledger app, Daftary is built specifically around *money relationships between people* — not categorized spending. The atomic unit is a person and a two-directional running balance with them (given vs. received, including partial repayments), not a transaction category. [From docs/project.txt: "Your Personal Financial Memory" / "complete money relationship" positioning — recorded as the product's direction, not a finalized slogan.]

## Operating Context

- Local-first: all data lives on-device in a Drift/SQLite database; there is currently no backend, sync, or authentication layer.
- Bilingual: Arabic and English are both first-class, with full RTL support required for Arabic (not a translated LTR layout).
- Currency: Egyptian Pounds (EGP) is the only currency currently modeled.
- Core workflows already implemented: add/edit/archive/restore a person; record a transaction (money given or received) against a person; record a (partial) repayment; view a person's balance and full history; view an overview/dashboard of all balances; onboarding for first-time users; settings for language and theme (light/dark).
- Not yet implemented (out of scope for this audit per user decision, but the design system should stay extensible toward them): occasions/social events, receipt/paper OCR capture, an AI financial assistant, budgets, savings goals, income/expense categorization, multi-currency, sync/backup.
- Duplicate-person detection exists as a safeguard when adding a person (`find_possible_duplicate_person` usecase, `duplicate_warning_sheet` widget).
- In-progress side work exists in `.kilo/worktrees/` (other tool's worktrees) — not part of this task's scope; do not edit those paths.

## Capabilities and Constraints

- Business logic, repository behavior, data models, DB schema, and navigation structure must not change as part of this UI/UX work unless a UX improvement genuinely requires it — and any such case must be flagged before making the change.
- No authentication or multi-user concept exists yet; do not design screens that assume one.
- Design system decisions made now (tokens, components, patterns) should be written generically enough to extend to future modules (occasions, budgets, savings) without rework, even though those modules are not being built in this pass.
- Platform: unified Material 3 across Android and iOS (see `## Platform`); do not fork the visual language per OS.

## Brand Commitments

- App name: "Daftary" (Arabic: my notebook/ledger). Keep as the product identity.
- Voice from existing copy (see `lib/core/l10n/app_en.arb`/`app_ar.arb`): plain, calm, non-technical language — e.g. "No people yet", "Add a person to start tracking money you give or receive with them", "This person has recorded transactions. Archive them instead to keep their history." Avoid accounting jargon in any new copy.
- Brand personality target (from docs/project.txt): simple, friendly, trustworthy, private, intelligent, fast — explicitly *not* accounting-software-feeling.

## Evidence on Hand

- Existing design system: `lib/core/design_system/` (`AppButton`, `AppCard`, `AppConfirmDialog`, `AppEmptyView`, `AppTextField`) and `lib/core/design_system/tokens.dart` (semantic `ColorScheme` + `AppFinanceColors` theme extension for positive/negative/neutral/warning finance colors, light and dark, `AppSpacing`, `AppRadius`, `AppTypography`). This is a real, working system — improve it, do not replace it with a second one.
- Localization: `lib/core/l10n/app_en.arb` and `app_ar.arb` (107 keys) — real, shipped copy for both languages.
- Specs already written and (per git history) implemented: `specs/001-money-relationships-tracking`, `specs/002-localization-language-switch`, `specs/003-dark-mode-theme`, `specs/004-transaction-state-refresh`, `specs/005-archive-state-refresh`, `specs/006-onboarding-screens`. These document intended behavior for the corresponding features — treat as authoritative context, not something to redesign from scratch.
- No visual mockups, brand assets, logo, or marketing materials exist. No user research, testimonials, or usage data exist — do not fabricate any of these.

## Product Principles

1. Feel like a notebook a trusted person keeps for you, not an accounting tool — plain language, minimal financial jargon, calm visuals.
2. A person's balance status (owed / owing / settled) must be understandable at a glance, in both languages and both themes, without reading numbers carefully.
3. Arabic is a first-class experience, not a mirrored translation — RTL layout, alignment, icon direction, and copy tone are each verified independently, not assumed from the LTR version.
4. One consistent design language across the whole app: one spacing system, one component set, one interaction pattern per action type (destructive, confirm, form, etc.).
5. Local-first and private by default — the UI should never suggest cloud sync, accounts, or data leaving the device, since none of that exists yet.

## Accessibility & Inclusion

No formal accessibility standard has been mandated by the user. Given the target user (non-technical, general Egyptian public, mixed age range for a personal-finance-adjacent app), treat WCAG AA-equivalent contrast and minimum 44x48dp touch targets as a working bar during this audit. [Inferred, not confirmed by the user — flag any accessibility fix that would meaningfully change visual style before applying it broadly.]
