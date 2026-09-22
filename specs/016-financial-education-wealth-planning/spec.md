# Feature Specification: Financial Education & Wealth Planning

**Feature Branch**: `016-financial-education-wealth-planning`

**Created**: 2026-09-22

**Status**: Draft

**Input**: User description: "Roadmap V3.2 — Financial Education & Wealth Planning. This is the project's own explicitly-chosen safer MVP alternative to a personalized-investment-advice feature (docs/project.txt §9: the app may provide financial education, saving strategies, investment concepts, risk explanations, general information, calculators, and scenario simulations, but must NOT blindly provide personalized investment recommendations — if investment functionality introduces regulatory/legal risk, the safer MVP alternative is exactly this feature). A curated, static (bundled, not AI/CMS-generated) educational content library plus deterministic scenario/compound-growth calculators reusing the same rigor as 011-savings-goals' ProjectSavingsCompletion — pure arithmetic, never AI-estimated. Calculators are general-purpose manual-input tools that never read the user's actual transaction/income/expense/savings data to auto-personalize a recommendation (may optionally pre-fill a Savings Goal amount as a pure convenience, never as advice). A persistent, always-visible disclaimer at every entry point that this is general education/illustrative calculation only, not personalized advice. No network calls, fully local. No dependency on any other unbuilt feature."

## Clarifications

*No outstanding [NEEDS CLARIFICATION] markers — ambiguities below were resolved with reasonable, documented defaults in Assumptions, following the pattern established in prior specs (e.g. 011-savings-goals).*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse and Read Educational Content (Priority: P1)

A user who wants to understand personal-finance basics, saving strategies, or general investment concepts — but has no reliable, unbiased place to learn them in Arabic or English relevant to their own context — wants to browse a trustworthy, curated library inside the app they already use for their money.

**Why this priority**: This is the feature's core deliverable and the entire reason it exists as the safer alternative to personalized advice — without a real content library, there is nothing to browse and the feature has no value at all.

**Independent Test**: Can be fully tested by opening the Financial Education section, browsing its categories, opening an article, and confirming the content renders correctly with the persistent disclaimer visible, with zero network activity.

**Acceptance Scenarios**:

1. **Given** the user opens the Financial Education section for the first time, **When** the screen loads, **Then** they see a browsable set of categories (e.g. Budgeting Basics, Saving Strategies, Understanding Investment Concepts, Risk & Diversification Explained) each containing one or more articles, and a clearly visible disclaimer banner.
2. **Given** the user selects a category, **When** it opens, **Then** they see a list of that category's articles with a title and short description each.
3. **Given** the user opens an article, **When** it renders, **Then** the full article content displays legibly, formatted for readability (headings, paragraphs, and where relevant simple illustrative examples), with the disclaimer still visible or immediately re-referenceable on that screen.
4. **Given** the user is offline (which, for this app, is the normal state), **When** they browse any part of this feature, **Then** everything loads instantly with zero network requests and zero loading spinners waiting on connectivity.
5. **Given** the user switches the app language between Arabic and English, **When** they reopen the content library, **Then** every category and article is available and fully readable in the selected language, correctly mirrored for RTL when Arabic is active.
6. **Given** an article discusses an investment concept (e.g. diversification, risk/return tradeoff, compound growth), **When** the user reads it, **Then** the content is written in general, educational terms about how the concept works — never as a suggestion to take a specific action with the user's own money, and never referencing the user's own financial data.

---

### User Story 2 - Run a Compound-Growth "What If" Calculator (Priority: P1)

A user curious about the mechanics of saving or investing over time wants to explore a hypothetical scenario — "if I put aside a certain amount every month at a certain rate of return for a certain number of years, what would the total be" — as a general illustration of how compounding works, using numbers they choose themselves.

**Why this priority**: This is the feature's second core deliverable (alongside content) and directly answers the product brief's explicit call for "calculators" and "scenario simulations" as part of the safer MVP — without it, the feature is read-only content with no interactive tool.

**Independent Test**: Can be fully tested by opening the compound-growth calculator, entering a monthly amount, an annual rate, and a duration, and confirming the projected total is computed correctly via deterministic arithmetic with the illustrative disclaimer shown alongside the result.

**Acceptance Scenarios**:

1. **Given** the user opens the compound-growth calculator, **When** they enter a monthly contribution of 1,000 EGP, an annual rate of 10%, and a duration of 10 years, **Then** the system computes and displays a projected total using standard compound-interest arithmetic, clearly labeled as a hypothetical illustration based on the rate the user entered.
2. **Given** the user changes any input (monthly amount, rate, or duration), **When** they update it, **Then** the projected total recalculates immediately and deterministically — the exact same inputs always produce the exact same result.
3. **Given** the user enters a zero or negative monthly amount, a negative rate, or a zero/negative duration, **When** they submit, **Then** the system rejects the invalid input with a clear explanation rather than silently computing a nonsensical or infinite result.
4. **Given** the user enters an unusually high annual rate (e.g. above a generous sanity-check ceiling), **When** they submit, **Then** the system still computes it accurately but shows an additional, clearly worded note that this is a purely hypothetical rate for illustration and not a realistic expectation.
5. **Given** the result is displayed, **When** the user views it, **Then** it is shown alongside a breakdown (total contributed vs. total growth) and the persistent disclaimer, never as a bare number that could be mistaken for a promise or a forecast.
6. **Given** the user has an existing Savings Goal (spec 011) with a starting amount already saved, **When** they open the calculator, **Then** they may optionally choose to pre-fill the starting amount from that goal purely as a numeric convenience — freely overwritable — and the system never uses this pre-fill to suggest or imply any specific action.

---

### User Story 3 - Run a Simple Effective-Savings-Rate / Rule-of-Thumb Calculator (Priority: P2)

A user wants a quick, generic way to see how a savings rate or a doubling-time rule of thumb works in the abstract, without needing to model month-by-month compounding.

**Why this priority**: This is a secondary, simpler calculator that rounds out the "calculators" requirement from the product brief with a lighter-weight tool; valuable but the feature is already useful with just the compound-growth calculator (User Story 2), so this is P2.

**Independent Test**: Can be fully tested by entering a principal amount and an annual rate into the rule-of-thumb calculator and confirming the estimated doubling time (or effective savings rate, depending on the chosen tool) is computed correctly via simple deterministic arithmetic.

**Acceptance Scenarios**:

1. **Given** the user opens the doubling-time calculator, **When** they enter an annual rate of 8%, **Then** the system computes and displays an approximate doubling time using the standard "rule of 72" arithmetic (72 ÷ rate), clearly labeled as a rough approximation, not an exact projection.
2. **Given** the user enters a rate of 0 or a negative rate, **When** they submit, **Then** the system rejects it with a clear explanation, since a doubling time cannot be computed for a non-positive rate.
3. **Given** the user opens the effective-savings-rate calculator and enters a monthly income figure and a monthly savings amount, **When** they submit, **Then** the system computes and displays the resulting savings rate as a percentage, using simple deterministic division.
4. **Given** the user enters a savings amount exceeding the income figure, **When** they submit, **Then** the system accepts it (a savings rate over 100% is mathematically valid, e.g. saving from existing reserves) but does not reject or clamp the value — this calculator does not read or infer the figures from the user's actual Income/Expense data (007) even when that feature exists, since these are manually entered illustrative inputs only.

---

### User Story 4 - Understand the Feature's Boundaries via the Persistent Disclaimer (Priority: P2)

A user engaging with this feature — especially the investment-concept content and calculators — needs to always be able to see, at a glance, that nothing here is personalized advice, so they never mistake a general illustration for a recommendation about their own money.

**Why this priority**: This is the feature's core safety/compliance mechanism (docs/project.txt §9's explicit risk-avoidance instruction) — without a persistent, unavoidable disclaimer, User Stories 1-3 alone could be misread by a user as implicit advice, which is exactly the outcome this entire feature exists to prevent. It is P2 rather than P1 only because the disclaimer's presence is woven into every screen delivered by US1-US3 rather than being a separately reachable destination of its own.

**Independent Test**: Can be fully tested by navigating to every screen this feature introduces and confirming a clearly visible, non-dismissible-permanently disclaimer is present on each one, and that no screen anywhere in this feature asks for or uses personal risk-tolerance, income, net worth, or actual transaction history to tailor its content or a calculator result.

**Acceptance Scenarios**:

1. **Given** the user opens any screen in this feature (content library home, a category, an article, either calculator), **When** the screen renders, **Then** a disclaimer stating this is general education/illustrative calculation only, not personalized financial or investment advice, and recommending consultation with a licensed professional for individual advice, is visible or immediately reachable via a persistent, always-present element on that screen (e.g. a banner or a permanently accessible info affordance) — never a one-time modal the user dismisses once and never sees again.
2. **Given** the user has seen the disclaimer many times before, **When** they return to any screen in this feature, **Then** it is still shown — it is never suppressed after a first viewing, since its purpose is standing protection, not onboarding.
3. **Given** the user interacts with any part of this feature, **When** they do, **Then** the system at no point asks the user to input or select their personal risk tolerance, income level, net worth, or investment goals in a way that would tailor content shown or a recommendation given — this feature never builds or stores a personal financial-risk profile.
4. **Given** an article or calculator result could be read as suggesting a specific action, **When** the content/copy is written, **Then** it is phrased in general, illustrative, or educational terms (e.g. "a diversified portfolio spreads risk across asset types" rather than "you should diversify into X") — verified by content review as part of this feature's definition of done, not just at spec time.

---

### Edge Cases

- What happens if the user's device language is set to a language other than Arabic or English? The app's existing language-fallback behavior applies (defaulting to the app's currently configured language, per the existing localization system) — this feature introduces no new language-fallback mechanism.
- What happens when the compound-growth calculator's duration is very long (e.g. 50 years) combined with a high rate? The system still computes and displays the result accurately using standard arithmetic (no artificial cap on duration/rate beyond the sanity-check note in User Story 2 Scenario 4), since refusing to compute a valid (if extreme) input would be less honest than showing it with context.
- What happens when the user tries to link or infer a calculator result to a specific Savings Goal beyond the optional starting-amount pre-fill (User Story 2 Scenario 6)? Not supported — the calculator's result is never written back to, or otherwise associated with, any Savings Goal or any other persisted entity; it exists only for the duration of the calculation.
- What happens if a future AI Assistant (spec 014) is asked a question that touches on investment concepts? Out of scope for this spec — any interaction between a future AI Assistant and this feature's content (e.g. the assistant referencing an article) is a decision for that feature's own spec, not this one; this spec makes no assumption about it either way.
- What happens when the app's theme or language changes while a calculator's result or the disclaimer banner is visible? Both must remain correctly laid out, fully legible, and fully localized in RTL/LTR and both themes with no truncation.
- What happens if the user has zero Savings Goals when opening the compound-growth calculator's optional pre-fill (User Story 2 Scenario 6)? The pre-fill option is simply unavailable/hidden in that case, and the calculator still functions fully with manual entry.
- What happens if new educational content needs to be added or corrected after the app is released? Content updates ship as part of a normal app version update (bundled content, per Assumptions) — this feature does not include any in-app content-editing or remote-content-update mechanism.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a browsable library of educational content organized into categories, each containing one or more articles, covering at minimum: personal-finance/budgeting basics, saving strategies, and general investment concepts and risk explanations.
- **FR-002**: All educational content MUST be static and bundled with the application (or otherwise locally sourced) — never fetched from a remote CMS or backend, never AI-generated at runtime, and never user-editable.
- **FR-003**: Users MUST be able to navigate from the content library home to a category to an individual article, and back, with each level showing enough information (category name, article titles/short descriptions) to choose what to read next.
- **FR-004**: The system MUST NOT, anywhere in this feature's content or calculators, recommend a specific investment product, asset, security, platform, or a specific asset allocation to the user.
- **FR-005**: The system MUST NOT ask for, collect, infer, or use the user's personal risk tolerance, income level, net worth, investment goals, or actual transaction/income/expense/savings history to tailor, personalize, or filter which content is shown or how a calculator computes its result.
- **FR-006**: All investment-related educational content MUST be written in general, abstract, educational terms describing how a concept works (e.g. diversification, risk/return tradeoff, compounding) — never phrased as a suggestion or instruction for the user to take a specific action with their own money.
- **FR-007**: The system MUST provide a compound-growth "what if" calculator accepting a monthly contribution amount, an annual growth rate (percentage), and a duration (in years), and MUST compute a projected total using deterministic, documented compound-interest arithmetic — never an AI/LLM-estimated figure (constitution Principle VIII).
- **FR-008**: The compound-growth calculator MUST reject a monthly contribution that is zero or negative, an annual growth rate that is negative, and a duration that is zero or negative, each with a clear explanation.
- **FR-009**: The compound-growth calculator's result MUST be displayed alongside a breakdown distinguishing total amount contributed from total projected growth, and MUST be accompanied by a clearly worded statement that the figure is a hypothetical illustration based on a rate the user entered themselves, not a prediction, guarantee, or recommendation.
- **FR-010**: When the user enters an annual growth rate above a defined high-rate threshold, the compound-growth calculator MUST still compute and display the result accurately, and MUST additionally show a clear note that the entered rate is unusually high and the result is purely illustrative.
- **FR-011**: The system MUST provide a doubling-time calculator using the standard "rule of 72" approximation (72 ÷ annual rate), clearly labeled as an approximation, and MUST reject a zero or negative rate with a clear explanation.
- **FR-012**: The system MUST provide an effective-savings-rate calculator accepting a manually entered income figure and a manually entered savings amount, computing the savings rate as a simple percentage via deterministic division, and MUST accept a savings amount that exceeds the income figure without rejecting or clamping it.
- **FR-013**: Neither calculator in this feature (FR-007, FR-011, FR-012) MUST read, query, or auto-populate its inputs from the user's actual `MoneyTransaction`, `FinanceEntry`/`Category` (007), or `SavingsContribution` (011) data — all inputs are manually entered by the user for every calculation, with the single documented exception of FR-014.
- **FR-014**: The compound-growth calculator MAY offer the user an explicit, optional action to pre-fill its starting-amount input from an existing Savings Goal's current saved amount (spec 011), strictly as a numeric convenience; the pre-filled value MUST remain freely editable/overwritable by the user, and this pre-fill action MUST NOT be used, described, or framed anywhere as a recommendation.
- **FR-015**: The system MUST display a persistent disclaimer — stating that this feature provides general education and illustrative calculation only, is not personalized financial or investment advice, and recommends consulting a licensed professional for advice specific to the user's own situation — visible or immediately reachable via a permanently present element (not a one-time dismissible modal) on every screen this feature introduces: the content library home, category views, article views, and both calculators.
- **FR-016**: The disclaimer (FR-015) MUST continue to be shown on every subsequent visit to any screen in this feature — it MUST NOT be permanently suppressed or hidden after a first viewing.
- **FR-017**: The system MUST keep all content browsing and calculator functionality fully operational with no network connection; this feature MUST NOT make any network call, and MUST NOT transmit any user data to any third party as part of its own operation.
- **FR-018**: The system MUST present all screens introduced by this feature fully localized in Arabic and English, with correct RTL/LTR layout, number/percentage/currency formatting, and correctly themed in both light and dark mode.
- **FR-019**: The system MUST NOT alter, migrate, or affect any existing People, Transactions, Income/Expense (007), Occasions (008), Budgets (010), or Savings Goals (011) data or calculations as part of this feature; the only interaction with any other feature's data is the strictly read-only, user-initiated, optional pre-fill described in FR-014.
- **FR-020**: The system MUST allow the user to reach the Financial Education & Wealth Planning section from the app's main navigation without any prerequisite setup (no account, no enabled feature flag, no configuration step) — it is available by default to every user, consistent with its purely local, self-contained nature.

### Key Entities *(include if feature involves data)*

- **Education Category**: A grouping of related articles (e.g. "Saving Strategies," "Understanding Investment Concepts"). Attributes: name, short description, an ordered list of articles. Bundled/static, never user-created or user-edited.
- **Education Article**: A single piece of static educational content within a category. Attributes: title, short description (for list views), full body content (formatted for readability), and a stable identifier used only for navigation — no author-personalization, no user-specific variant.
- **Compound Growth Scenario** *(ephemeral, not persisted)*: A hypothetical calculation input (monthly contribution, annual rate, duration) and its deterministic result (projected total, total contributed, total growth). Exists only for the duration of the calculator interaction; never saved, never associated with any other entity beyond the one-time optional Savings Goal starting-amount pre-fill (FR-014), which itself does not persist a link back.
- **Doubling Time Scenario** *(ephemeral, not persisted)*: A hypothetical annual-rate input and its computed approximate doubling time (rule of 72). Never persisted.
- **Savings Rate Scenario** *(ephemeral, not persisted)*: A manually entered income and savings-amount pair and its computed savings-rate percentage. Never persisted, never sourced from the app's actual Income/Expense data.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can navigate from the content library home to a specific article and back in under 15 seconds, with zero network requests observed during the entire session.
- **SC-002**: For any valid input combination, the compound-growth calculator's projected total exactly matches the deterministic compound-interest formula defined in FR-007, verified across at least 20 varied monthly-amount/rate/duration combinations with zero discrepancies.
- **SC-003**: 100% of screens introduced by this feature display the persistent disclaimer (FR-015) on every visit, verified by navigating to each screen at least twice in a test pass and confirming its continued presence both times.
- **SC-004**: Zero instances, across a full content and calculator-copy review, of language recommending a specific investment product, asset, or allocation, or of any input field requesting personal risk-tolerance/income/net-worth profiling data used to tailor a result (FR-004/FR-005) — verified by manual content audit as part of this feature's definition of done.
- **SC-005**: A user can complete a doubling-time or effective-savings-rate calculation, from opening the calculator to seeing a result, in under 20 seconds.
- **SC-006**: Switching the app language between Arabic and English, or switching between light and dark mode, produces zero layout, alignment, or truncation defects on the content library, any article, or either calculator, including the disclaimer element itself.
- **SC-007**: 100% of this feature's screens remain fully functional (content renders, calculators compute) when tested with the device in airplane mode, with zero error states referencing connectivity.

## Assumptions

- **Content is bundled with the app, not remotely fetched**: Consistent with the product brief's own framing of this feature as a *safer, static* MVP alternative to personalized advice, and with the app's fully offline-first architecture — educational content ships as app assets (e.g. structured local files) versioned with the app itself, updated only via a normal app release. This avoids introducing this app's first-ever content backend/CMS dependency for a feature explicitly chosen *because* it avoids the regulatory/legal risk of anything more dynamic or personalized.
- **Compound-growth formula**: Standard monthly-compounding formula over the ordinary annuity of monthly contributions (future value = monthly contribution × [((1 + monthly rate)^months − 1) / monthly rate], where monthly rate = annual rate ÷ 12), applied consistently and documented at implementation time — chosen as the most common, easily-verified, textbook formulation for this kind of illustrative calculator, deliberately simple rather than modeling compounding-frequency options the user would have no way to reason about.
- **High-rate sanity-check threshold**: A generous but finite annual-rate threshold (e.g. 30%) above which the extra cautionary note (FR-010) appears — chosen because a plausible, non-egregious rate shouldn't be second-guessed, but a rate far outside realistic long-run market returns deserves an explicit "this is hypothetical" reminder given this feature's regulatory sensitivity; the exact number is a product-copy decision refinable at implementation time without changing this requirement's intent.
- **No user-authored notes or saved scenarios**: Unlike Savings Goals (011), calculator scenarios in this feature are explicitly ephemeral and never saved — this keeps the feature simple and reinforces that these are illustrative, one-off explorations rather than a tracked financial plan (which is what Savings Goals already exists for).
- **No dependency on AI Assistant (014) or any other unbuilt feature**: This feature's content and calculators are fully self-contained and functional with zero other V2/V3 feature present; the single optional integration point (FR-014, pre-filling from an existing Savings Goal) degrades gracefully to "unavailable" when Savings Goals doesn't exist or has no goals, per Edge Cases.
- **Currency**: Amounts entered into calculators are treated as plain numeric figures for illustrative arithmetic; where a currency symbol/format is shown for readability, it reuses the app's existing `core/money`/EGP formatting for consistency, without implying the calculator is reading real EGP account data.
- **Navigation placement**: Reachable from the app's main navigation (e.g. a Settings or a dedicated "Learn"/"Education" entry point) with no prerequisite setup (FR-020); exact placement is a navigation/IA decision made at planning time, not a behavioral requirement of this spec.
- **Content depth for V3 scope**: A "curated library" for this spec's initial scope means a meaningful, genuinely useful starting set of categories/articles (not a single placeholder page) but is not required to be an exhaustive financial-education curriculum — exact article count/depth is a content-authoring decision for implementation/task planning, not a architecturally-defining one.
