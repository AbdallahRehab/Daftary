# Phase 0 Research: Financial Education & Wealth Planning

## 1. Bundled static content format

**Decision**: Educational content is authored as structured JSON files (one per article, or one per category), bundled as Flutter assets under `lib/features/financial_education/data/content/{en,ar}/`, loaded via `rootBundle` at runtime through `BundledEducationContentDataSource`. Not a `drift` table, not a remote fetch, not markdown-rendered-from-network.

**Rationale**: This is the direct implementation of spec.md's own Assumption ("Content is bundled with the app, not remotely fetched") — treating content as versioned app assets means it ships, updates, and is code-reviewed exactly like any other part of the app, with zero new infrastructure (no CMS, no content API, no first-ever backend dependency for a feature explicitly chosen *because* it avoids exactly that kind of regulatory/operational risk). JSON (rather than a `drift` table) keeps content human-authorable/diffable in PRs and avoids inventing a migration story for content that never actually needs runtime querying beyond "get this category's articles" / "get this article by id."

**Alternatives considered**: A `drift` table seeded at first launch — rejected, adds migration/seeding complexity for data that never changes per-user and is more naturally reviewed as plain files; a remote CMS/backend — explicitly rejected by the spec itself (FR-002) and the product brief's own risk-avoidance reasoning; Markdown files parsed at runtime — considered but JSON keeps the schema (title, short description, body, optional structured examples) explicit and typed rather than relying on markdown-parsing edge cases for a security/compliance-sensitive feature where content structure matters (e.g. guaranteeing the disclaimer-adjacent framing isn't accidentally mangled by a parser quirk).

## 2. Initial content scope (for task-planning sizing, not a hard requirement)

**Decision**: Ship with 3 categories × 3-4 articles each at minimum: "Budgeting Basics" (e.g. "Why Track Your Spending," "The 50/30/20 Idea, Explained," "Building Your First Budget"), "Saving Strategies" (e.g. "Emergency Funds Explained," "Automating Your Savings," "Short-Term vs. Long-Term Goals"), "Understanding Investment Concepts" (e.g. "What Is Diversification?," "Risk and Return, Explained," "What Compounding Really Means," "A Plain-Language Glossary of Investment Terms"). Each article 300-800 words.

**Rationale**: Satisfies spec.md's Assumption that initial scope be "a meaningful, genuinely useful starting set... not a single placeholder page" while giving `/speckit-tasks` a concrete, sizeable content-authoring task list rather than an open-ended one. Category/article names above are illustrative content-authoring guidance, not binding requirements — refinable at content-writing time.

**Alternatives considered**: A single combined article — rejected, doesn't satisfy "browsable categories" (FR-001/FR-003) meaningfully; an exhaustive curriculum (dozens of articles) — rejected as out of scope per spec.md's own Assumption, and better delivered incrementally in a later content-only update once this feature's structure ships.

## 3. Calculator services take zero repository dependency

**Decision**: `CompoundGrowthCalculator`, `DoublingTimeCalculator`, and `SavingsRateCalculator` are pure Dart classes/functions with no constructor dependency on any repository, DAO, or database access at all — not `TransactionRepository`, not `FinanceRepository`, not even `SavingsRepository`. The single pre-fill exception (FR-014) is implemented as a separate use case (`GetPrefillableSavingsGoalAmount`) that returns a plain `int?` (minor units) to the Presentation Cubit, which then sets it as an editable starting value in the calculator's input form — the calculator services themselves never see or call anything related to it beyond receiving whatever number the user's input field currently holds.

**Rationale**: This is the structural enforcement of FR-004/FR-005/FR-013 discussed in plan.md's Constitution Check — a calculator service that has no import path to any feature's real financial data cannot regress into implicit personalization even via a careless future edit, which is a stronger guarantee than a code-review-only promise. It directly mirrors 011-savings-goals' `SavingsCalculator` pattern (also dependency-free) but goes one step further here because this feature's entire premise depends on that boundary being provably real, not just documented.

**Alternatives considered**: Letting the compound-growth calculator directly query `SavingsRepository` for the pre-fill inside its own calculation call — rejected, would blur the line between "user-provided input" and "app-read financial data" inside the one place (the calculator itself) that must stay provably input-only; keeping the pre-fill entirely out of scope — rejected, spec.md User Story 2 Scenario 6 explicitly calls for it as an optional convenience.

## 4. Compound-growth formula

**Decision**: `futureValue = monthlyContribution × (((1 + monthlyRate)^months − 1) / monthlyRate)`, where `monthlyRate = annualRatePercent / 100 / 12` and `months = years × 12`; `totalContributed = monthlyContribution × months`; `totalGrowth = futureValue − totalContributed`. When `monthlyRate == 0` (a 0% rate, which is valid — rejected only if negative per FR-008), the formula degenerates to `futureValue = monthlyContribution × months` (avoiding a division-by-zero), handled as an explicit branch.

**Rationale**: This is the standard "future value of an ordinary annuity" formula, textbook-verifiable and easily unit-tested against known reference values — exactly the kind of "simple, documented, deterministic arithmetic" the constitution's Principle VIII and this feature's entire premise require. Monthly compounding (rather than annual, daily, or continuous) was chosen as the single supported model since the calculator's own input is a *monthly* contribution — modeling multiple compounding-frequency options would add UI/input complexity without adding illustrative value for a general-education tool.

**Alternatives considered**: Annual-only compounding — rejected, doesn't match a monthly-contribution input naturally; letting the user choose a compounding frequency — rejected as unnecessary complexity for an illustrative, general-education calculator (research.md's own framing: this is not a precision investment-planning tool).

## 5. Navigation entry point

**Decision**: A new "Financial Education" (or "Learn") entry point added to the app's main navigation — most naturally as a card/link from Settings or Home's quick actions (mirroring how 011-savings-goals left exact placement to plan-time), reachable with zero prerequisite setup (FR-020).

**Rationale**: Consistent with spec.md's own Assumption ("exact placement is a navigation/IA decision made at planning time, not a behavioral requirement of this spec") and with ROADMAP-PLAN.md §9's general precedent of not adding a new bottom-nav tab for every feature — this is a secondary, non-daily-use feature well suited to a discoverable-but-not-primary placement (e.g. a Settings row or a Home card), not a 5th bottom-nav tab.

**Alternatives considered**: A dedicated bottom-nav tab — rejected as disproportionate for a feature with no daily-transactional use case, consistent with ROADMAP-PLAN.md §9's reasoning against tab-per-feature growth.
