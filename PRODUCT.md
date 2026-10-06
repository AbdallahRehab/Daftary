# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

[Confirmed: single unified Material 3 design language for both Android and iOS — no Cupertino-specific adaptation. Recorded as `android` because Material is the one design language actually implemented; iOS builds render the same Material UI rather than adapting per-OS. Do not introduce Cupertino affordances (back-swipe gestures, iOS-style pickers/switches) unless the user changes this decision.]

## Stack

Flutter (Dart SDK ^3.10.0, pinned to Flutter 3.47.0 via fvm), Material 3, `flutter_bloc`/Cubit for state, `go_router` for navigation (`StatefulShellRoute`), `drift` (SQLite) for local persistence, `get_it` + `injectable` for DI, `flutter_localizations`/`intl` for i18n, `flutter_local_notifications` for on-device reminders. Existing codebase — not a stack decision for design work.

## Users

Individual Egyptian users (Arabic-first, English-supported) who exchange money informally with people in their life — friends, family, colleagues — and need to remember who owes them and who they owe, and who increasingly want a simple picture of their own money too (income, spending, plans). The target user has no accounting or bookkeeping background; the product must feel like "someone who remembers my money for me," not a ledger app for professionals. [Inferred from docs/project.txt master brief and the app's terminology; confirmed by the app being local-first and fully usable offline without an account, with only an optional email-linked cloud sync (021), i.e., built for a single individual's own data.]

## Product Purpose

Daftary ("my notebook/ledger" in Arabic) lets a user create a person and record money given to or received from them over time, so the running balance ("they owe you" / "you owe them" / "settled") is always clear without mental math or a paper notebook. Around that core it offers personal finance tools — income/expense tracking, general financial education, and honest reminders — so the same trusted notebook covers the user's own money. Success is a user trusting the app's numbers enough to stop tracking debts and spending in their head or on paper, and being able to answer "does X still owe me money, and how much?" in one glance.

## Positioning

People-first, broader finance. Unlike a generic expense tracker or ledger app, Daftary is built around *money relationships between people*: the atomic unit is a person and a two-directional running balance with them (given vs. received, including partial repayments), not a transaction category. This remains the core and the differentiator. Personal-finance modules (income/expense, education, insights, and planned budgets/savings) orbit that core and must never demote it — people and balances stay the first thing the app is about. [Confirmed by the user 2026-09-25.]

## Operating Context

- Local-first: all data lives on-device in a Drift/SQLite database and every money feature works fully offline. **Optional cloud sync (021)** exists: the user can link an email account (one-time code) and sync their own data to Supabase through an outbox with revision-based push/pull, manual conflict resolution for money records, and append-only change history. Sync is off unless the user turns it on. Family/shared finances remain out of scope (one user, one account).
- Bilingual: Arabic and English are both first-class, with full RTL support required for Arabic (not a translated LTR layout).
- Navigation: bottom navigation shell with People, Overview, and Settings as top-level destinations; other modules are entered from these.
- Implemented modules:
  - **People & transactions** (001): add/edit/archive/restore a person; record money given or received; record partial repayments; view a person's balance and full history; duplicate-person warning on add.
  - **Overview**: totals of owed-to-me / owed-by-me across all people, plus entry to finance.
  - **Income & expense** (007): personal finance entries with customizable categories, history, and totals, kept separate from person-to-person transactions.
  - **Financial education** (016): a curated, bundled content library and deterministic calculators (e.g. compound growth). General education only, never personalized investment advice; a disclaimer is visible at every entry point.
  - **Insights & reminders** (017): local notifications computed deterministically from the user's real stored data, with per-category controls, quiet hours, cooldowns, and deep links. Never fabricated or generic.
  - **Multi-currency** (018): every amount carries an ISO 4217 currency (EGP by default and always present). The user sets a primary currency and enters exchange rates by hand; there are no live rates. Aggregates convert to the primary currency, individual records keep their original currency, and a missing rate blocks a total with a clear message instead of guessing.
  - **Settings**: language, theme (light/dark), currency, notifications. **Onboarding**: a first-launch intro.
  - **Occasions / social money** (008), **on-device OCR paper entry** (009, review-and-confirm before saving), **household budgets** (010), **savings goals** (011), **Home Dashboard** (012), **reports, data export and delete-all-data** (013), **AI financial assistant** (014, bring-your-own key, figures come only from deterministic tools), **app lock** (015), **splash** (019), **liquid-glass UI** (020) and **optional cloud sync** (021) are all built.
- Audit and remediation of financial correctness: `specs/022-financial-trust-audit/` (audit.md, backlog, owner decisions). See `specs/` and `specs/ROADMAP-PLAN.md`.
- In-progress side work may exist in `.kilo/worktrees/` (another tool's worktrees) — never edit those paths.

## Capabilities and Constraints

- Design and UI work does not change business logic, repository behavior, data models, DB schema, or navigation structure. If a UX improvement genuinely requires one of those, flag it before making the change.
- One user per account: the optional sync account exists only to back up and sync the user's own data. There is no multi-user or shared-ledger concept; never design screens that assume one.
- Design system decisions (tokens, components, patterns) are written generically enough to serve every module — current and planned — without a per-module visual language.
- Honesty over filler: insights, reminders, dashboard sections, and any AI output show only real, deterministically computed observations or an honest empty state — never fake, static, or placeholder "insights."
- AI assistant: bring-your-own API key stored in on-device secure storage, no Daftary backend. AI output is non-authoritative and never presented as fact about the user's money.
- OCR: on-device recognition only (ML Kit / Vision), never cloud.
- Financial education never gives personalized investment recommendations and never reads the user's data to personalize advice.
- Money is stored as integer minor units with an explicit currency; Arabic-Indic digits are accepted on input.
- Platform: unified Material 3 across Android and iOS (see `## Platform`); do not fork the visual language per OS.

## Brand Commitments

- App name: "Daftary" (Arabic: my notebook/ledger). Keep as the product identity.
- Voice from existing copy (see `lib/core/l10n/app_en.arb`/`app_ar.arb`): plain, calm, non-technical language — e.g. "No people yet", "Add a person to start tracking money you give or receive with them", "This person has recorded transactions. Archive them instead to keep their history." Avoid accounting and investment jargon in any new copy.
- Brand personality target (from docs/project.txt): simple, friendly, trustworthy, private, intelligent, fast — explicitly *not* accounting-software-feeling.

## Evidence on Hand

- Existing design system: `lib/core/design_system/` (`AppButton`, `AppCard`, `AppConfirmDialog`, `AppDateField`, `AppEmptyView`, `AppIconBadge`, `AppTextField`, `CurrencyIndicatorChip`, `CurrencyPicker`) and `lib/core/design_system/tokens.dart` (semantic `ColorScheme` + `AppFinanceColors` theme extension for positive/negative/neutral/warning, light and dark; `AppSpacing`, `AppRadius`, `AppTypography`). This is a real, working system — improve it, do not replace it with a second one.
- Localization: `lib/core/l10n/app_en.arb` and `app_ar.arb` (~300 keys) — real, shipped copy for both languages.
- Specs `specs/001`–`018` plus `specs/ROADMAP-PLAN.md` document intended behavior; 001–007 and 016–018 are implemented. Treat them as authoritative product context, not something to redesign from scratch.
- Product brief: `docs/project.txt`.
- No visual mockups, brand assets, logo, or marketing materials exist. No user research, testimonials, or usage data exist — do not fabricate any of these.

## Product Principles

1. Feel like a notebook a trusted person keeps for you, not an accounting tool — plain language, minimal financial jargon, calm visuals.
2. People come first. A person's balance status (owed / owing / settled) must be understandable at a glance, in both languages, both themes, and any currency, without reading numbers carefully. Finance modules support this core and never crowd it out.
3. Arabic is a first-class experience, not a mirrored translation — RTL layout, alignment, icon direction, numerals, and copy tone are each verified independently, not assumed from the LTR version.
4. One consistent design language across every module: one spacing system, one component set, one interaction pattern per action type (destructive, confirm, form, etc.).
5. Private and honest by default — data stays on the device unless the user opts in to the optional email-linked cloud sync or to the bring-your-own-key AI assistant, the app is fully usable offline without an account and never pressures the user to create one, and every number, insight, or reminder is real or clearly absent.

## Accessibility & Inclusion

No formal accessibility standard has been mandated by the user. Given the target user (non-technical, general Egyptian public, mixed age range for a personal-finance-adjacent app), treat WCAG AA-equivalent contrast and minimum 48×48dp touch targets as a working bar, and verify layouts at larger system font scales. [Inferred, not confirmed by the user — flag any accessibility fix that would meaningfully change visual style before applying it broadly.]
