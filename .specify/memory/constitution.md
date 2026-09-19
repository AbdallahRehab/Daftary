<!--
Sync Impact Report
Version change: [TEMPLATE] → 1.0.0 (initial ratification)
Modified principles: N/A (first concrete adoption of the constitution template)
Added sections:
  - Core Principles: I–XVI (Clean Architecture Layering, Feature-First Modularity,
    BLoC/Cubit Mandate, Immutable State, Domain-Driven Business Logic, Repository
    Pattern, Explicit Error Handling, Deterministic Financial Calculations,
    AI Isolation, OCR Human-in-the-Loop, Offline Resilience & Idempotent Sync,
    Security & Secrets Management, Localization & RTL/LTR, Dependency Injection,
    Design System, Testability by Design)
  - Engineering & Quality Standards (performance, accessibility, widget/build
    discipline, logging, navigation, dates/files/permissions/lifecycle/config,
    duplicate-action protection, form validation, UI state completeness)
  - Development Workflow & Quality Gates (CI/CD, code quality, documentation,
    naming, refactoring discipline, code review mode, Definition of Done,
    prohibited patterns, architectural decision rule)
  - Governance (amendment procedure, versioning policy, compliance review,
    financial-domain override rule, pre-implementation checklist)
Removed sections: none (template placeholders only)
Follow-up TODOs:
  - TODO(RATIFICATION_DATE): Confirmed as the date this constitution was first
    adopted by the team (2026-09-19). Update only if an earlier informal
    ratification date is later documented.
-->

# Daftary Constitution

## Core Principles

### I. Clean Architecture Layering
Every feature MUST be structured into three layers — Presentation, Domain, and
Data — with dependencies flowing in exactly one direction:
Presentation → Domain → Data. Presentation MUST NEVER depend on Data directly.
Domain MUST NEVER depend on Presentation, and MUST remain free of Flutter
framework types, Dio, Firebase, SQLite, or API DTOs. Domain describes WHAT the
application does; Data and Presentation describe HOW. Screens and widgets MUST
NOT call APIs, access Dio, access a database, perform business calculations,
implement repository logic, parse API responses, or embed business rules.

**Rationale**: Enforcing a single dependency direction keeps business rules
independently testable and insulated from UI or infrastructure churn, which is
essential for a financial application that must remain correct as the UI and
backend evolve independently.

### II. Feature-First Modularity
The codebase MUST be organized primarily by feature
(`lib/features/<feature>/{data,domain,presentation}`), not by technical layer
at the global level. Global catch-all folders such as `widgets/`, `services/`,
`repositories/`, or `models/` containing unrelated feature code are
PROHIBITED. Code MUST only move into `lib/core/` when it is genuinely shared
across two or more features, has stable behavior, and represents a real
cross-cutting concern or design-system element.

**Rationale**: Feature-first structure keeps ownership boundaries clear,
limits blast radius of changes, and prevents `core/` from becoming an
unmanaged dumping ground.

### III. BLoC/Cubit as the Mandatory State Management Solution
`flutter_bloc` (BLoC/Cubit) MUST be used for all presentation-layer state
unless a documented, reviewed exception exists. A BLoC/Cubit MUST coordinate
use cases and hold presentation state; it MUST NOT contain repository
implementations, direct API calls, or large business algorithms. Every
BLoC/Cubit MUST define a clear state lifecycle (e.g. initial, loading,
success, failure), handle loading/success/error explicitly, avoid duplicate
in-flight requests, avoid or resolve race conditions, cancel/ignore obsolete
operations where relevant, and remain testable without Flutter UI (mocked
use cases/repositories, exact state-transition assertions). Introducing a
second state-management paradigm alongside BLoC is PROHIBITED without
documented justification.

**Rationale**: A single, disciplined state-management approach keeps behavior
predictable across a large, feature-rich app and keeps state changes
testable in isolation from widgets.

### IV. Immutable State
All BLoC/Cubit states MUST be immutable value objects updated exclusively via
`copyWith()`. Mutating existing state instances, or mutating lists/maps held
inside state, is PROHIBITED — use defensive copies or immutable collections.
New state MUST only be emitted when UI-relevant data actually changes; use
`BlocSelector`, `buildWhen`, and `listenWhen` to prevent redundant emissions
and rebuilds. Prefer explicit state fields over proliferating state
subclasses for complex screens.

**Rationale**: Immutability makes state transitions predictable, debuggable,
and safe to test; unnecessary emissions and rebuilds harm performance and UX
smoothness (see Principle on Performance & UX).

### V. Domain-Driven Business Logic
The Domain layer owns entities, repository contracts, use cases, business
rules, and domain-specific failures/value objects. A use case MUST represent
a meaningful business action (e.g. `AddTransaction`, `SettleTransaction`,
`CalculateSavingPlan`) and MUST NOT be created as a trivial wrapper around a
single repository call unless it provides real architectural value —
business logic, multi-repository coordination, reuse, or isolated
testability justify its existence.

**Rationale**: Concentrating business rules in the Domain layer, expressed as
named use cases, keeps intent explicit and makes financial logic reviewable
and testable independent of UI or infrastructure.

### VI. Repository Pattern as the Data Abstraction Boundary
Domain MUST define repository contracts as abstract interfaces; Data MUST
provide concrete implementations (e.g. `PeopleRepository` in Domain,
`PeopleRepositoryImpl` in Data). Presentation and Domain MUST depend only on
the abstraction, resolved through dependency injection — never on a concrete
`*RepositoryImpl`. Repositories are the source of truth for application data
and MUST own remote/local data coordination, caching, synchronization,
retry, mapping, and error conversion within the Data layer.

**Rationale**: This boundary lets remote/local data sources, caching, and
sync strategy evolve without touching business logic or UI, and enables
straightforward test doubles for Domain/Presentation tests.

### VII. Explicit Error Handling and Result Flow
Empty catch blocks (`catch (_) {}`) and silently swallowed errors are
PROHIBITED. Raw exceptions MUST NEVER be exposed directly to the UI.
Infrastructure exceptions MUST be converted into a predictable typed
`Failure` model (e.g. `ServerFailure`, `NetworkFailure`, `TimeoutFailure`,
`UnauthorizedFailure`, `ForbiddenFailure`, `NotFoundFailure`,
`ValidationFailure`, `CacheFailure`, `ParsingFailure`, `UnknownFailure`).
Expected failure paths MUST be represented explicitly through a typed
result/error mechanism (e.g. `Either<Failure, Success>` or an equivalent),
not through exceptions used as normal control flow. Exceptions are reserved
for truly exceptional, unexpected conditions.

**Rationale**: In a financial app, silent or ambiguous failures can hide data
loss or incorrect state. Typed failures make every error path reviewable and
let the UI present accurate, localized, user-friendly feedback.

### VIII. Deterministic Financial Calculations
All financial calculations — person balances, debts, remaining amounts,
monthly budgets, savings targets, transaction totals — MUST be computed by
deterministic application/domain logic. AI/LLMs MUST NEVER be the source of
truth for a financial calculation; AI may explain a result already computed
deterministically, but must not compute it. Money MUST NOT be handled with
careless floating-point arithmetic — use integer minor units or an
equivalently precise money representation.

**Rationale**: Financial correctness is non-negotiable; non-deterministic or
imprecise computation directly risks incorrect money records and user trust.

### IX. AI Integration Is Isolated and Non-Authoritative
All AI/LLM integration MUST sit behind explicit interfaces (e.g.
`FinancialAssistantRepository`, `AIService`, `AIDataProvider`). Screens MUST
NEVER call an LLM directly. API keys MUST NEVER be embedded in the Flutter
client. AI MUST receive only the minimum data required for the task,
structured outputs/function calling SHOULD be used where appropriate, and
every AI-generated output MUST be validated before use — AI responses are
never blindly trusted (see Principle VIII for the financial-calculation
boundary).

**Rationale**: Isolating AI behind interfaces bounds its blast radius, keeps
secrets out of the client, and lets the app evolve or swap AI providers
without touching business logic.

### X. OCR Is an Uncertain Input Source Requiring Confirmation
OCR-derived data MUST flow through: Image → Preprocessing → OCR → Parsing →
Validation → User Review → Confirmation → Persistence. The application MUST
NEVER auto-create financial transactions directly from OCR output without
explicit user confirmation. Extracted values MUST be shown clearly and MUST
be correctable before saving.

**Rationale**: OCR is inherently error-prone; treating it as a proposal that
a human confirms — rather than a fact — protects financial data integrity.

### XI. Offline Resilience and Idempotent Synchronization
The app MUST detect online/offline/restored-connection states and MUST NEVER
assume connectivity is always available. Offline, the UI MUST give meaningful
feedback, preserve locally supported actions, avoid unnecessary API calls,
and queue operations where appropriate. On reconnect, the app MUST
synchronize pending operations, prevent duplicate transactions, and handle
conflicts. Financial mutations MUST be protected against duplicate
submission, retry duplication, race conditions, and partial sync using
unique transaction IDs, idempotency keys where applicable, sync status,
pending queues, retry strategy, and a defined conflict-resolution strategy.
Financial mutations MUST NEVER be blindly retried without accounting for
idempotency.

**Rationale**: A financial ledger that can silently double-apply a mutation
under retry or reconnect is a correctness failure, not just a UX one.

### XII. Security and Secrets Management
Authentication tokens, user information, financial data, OCR documents, AI
context, the local database, and API communication MUST all be protected.
Sensitive credentials MUST use secure storage; sensitive local data MUST be
encrypted when required. Secrets MUST NEVER be hardcoded or committed;
configuration MUST be managed per environment (development/staging/
production). Logging MUST NEVER include passwords, tokens, financial
secrets, personal sensitive information, or API keys, and MUST distinguish
debug/warning/error levels with verbose logs disabled in production.
Permissions (camera, photos, notifications, biometrics) MUST be requested
contextually, not all at once at startup, with a reason shown when
appropriate.

**Rationale**: This app handles personal financial data; a single leaked
secret or logged token is a direct security incident, not a bug.

### XIII. Localization and RTL/LTR Are First-Class, Not Retrofitted
The app MUST fully support Arabic (RTL) and English (LTR) from generated
localization resources (`flutter_localizations`/`gen_l10n`) — Arabic MUST be
designed for, not treated as a translated English UI. User-facing strings
MUST NEVER be hardcoded (`Text("Add Transaction")` is PROHIBITED; use
`context.l10n.addTransaction` or equivalent). Directionality, alignment,
icons, navigation, padding, text alignment, charts, numbers, dates, and
currency MUST all behave correctly in both directions, including mixed
Arabic/English content. Currency formatting MUST respect locale (EGP and
others), decimal handling, thousands separators, and currency placement —
never simple string concatenation.

**Rationale**: RTL/LTR and localization are core product requirements for
this user base, not cosmetic extras; retrofitting them later is far more
expensive than designing for them from the start.

### XIV. Dependency Injection Everywhere
All non-trivial dependencies — repositories, use cases, data sources, API
clients, the database, analytics, storage, OCR, AI services, and the
connectivity service — MUST be injected, not instantiated directly inside
widgets or BLoCs/Cubits. A single, consistent DI approach MUST be used
throughout the project.

**Rationale**: Constructor/DI-based wiring is what makes Principles I, III,
and VI testable in practice — swapping a real dependency for a fake is only
possible if nothing self-instantiates it.

### XV. Centralized Design System, No Hardcoded Design Values
Colors, typography, spacing, border radius, shadows, icons, motion,
component styles, breakpoints, and theme MUST be centralized in one design
system and consumed via theme/design tokens. Repeated raw values (e.g.
`Color(0xFF123456)`) scattered across the app are PROHIBITED. Shared UI
components (e.g. `AppButton`, `AppTextField`, `AppCard`, `AppDialog`,
`AppEmptyView`, `AppTransactionCard`) MUST be promoted to `core/` only once
they are used by multiple features and have stable behavior — do not
prematurely extract a shared component used by only one feature.

**Rationale**: A centralized design system keeps the app visually and
behaviorally consistent and makes theme-wide changes (including RTL/LTR and
accessibility adjustments) tractable.

### XVI. Testability by Design
Every important business rule MUST be testable. At minimum: unit tests for
use cases, repositories, mappers, financial calculations, and validators;
BLoC tests covering initial/loading/success/failure states, transitions, and
edge cases with mocked/faked dependencies; widget tests for user
interactions and important UI/error/empty states; integration tests for
critical end-to-end flows. A feature is not done merely because it compiles
(see Definition of Done).

**Rationale**: Tests are how the other principles are actually verified over
time — architecture and immutability rules without tests will erode under
deadline pressure.

## Engineering & Quality Standards

**Performance & Animation**: Startup time, build cost, rebuild frequency,
memory, image size, network usage, database queries, large lists, and JSON
parsing are treated as requirements, not afterthoughts. Use `const`
constructors, `ListView.builder`, slivers, pagination, lazy loading, image
caching, selective BLoC rebuilds, and justified memoization; measure before
optimizing complex bottlenecks; avoid premature optimization. Animations
must be intentional (communicate state, aid navigation, give feedback),
prefer implicit animations/`AnimatedSwitcher`/`AnimatedSize`/`Hero`, respect
accessibility/reduced-motion settings, and must never be sacrificed-for nor
sacrifice performance.

**Accessibility**: Support screen readers, semantic labels, large text,
sufficient contrast, adequate touch target sizes, reduced motion where
applicable, and sensible keyboard/focus behavior. Important information
MUST NEVER be conveyed through color alone.

**Widget, Build, and Side-Effect Discipline**: Widgets MUST be small,
focused, reusable, and `Stateless` where possible; split any widget that
becomes hard to understand. `build()` MUST remain lightweight — no API
requests, database queries, expensive calculations, complex transformations,
or side effects inside it. Side effects (navigation, snackbars, dialogs,
analytics, notifications) MUST be triggered through `BlocListener`/
`BlocConsumer` or equivalent mechanisms, never simply because a widget
rebuilt. Lists of transactions/people/expenses MUST use lazy rendering,
pagination where required, stable keys, efficient item widgets, and
selectors/`buildWhen` to avoid rebuilding the whole list.

**Navigation**: Use a centralized, declarative routing strategy (e.g.
`go_router`); navigation decisions MUST NOT be duplicated across widgets.
Authenticated routes MUST be protected. Deep links, unknown routes,
authentication redirects, back navigation, and unsaved-changes prompts MUST
all be handled explicitly.

**Dates, Files, Permissions, Lifecycle, Configuration**: Date/time handling
MUST be centralized (locale, timezone, relative dates, server/client
timezone differences) rather than scattered across screens. OCR/attachment
handling MUST compress images appropriately, validate file types, limit file
sizes, and handle permissions, cancellation, upload failures, and progress.
Permissions MUST be requested contextually, never all at startup. The app
MUST handle background/foreground/termination, network restoration,
authentication expiration, and pending synchronization without assuming it
stays alive indefinitely. Environments (development/staging/production) MUST
be separated and configuration centralized — never hardcode
environment-specific values.

**Duplicate Action Protection**: Double taps, duplicate submissions,
duplicate API requests, and duplicate financial transactions MUST be
prevented, especially for money-related operations (see also Principle XI).

**Form Validation**: Forms MUST validate locally, show clear localized
errors, prevent invalid financial values, reflect loading state, prevent
duplicate submissions, and disable submit controls when appropriate.

**Complete UI States**: Every network/data-driven screen MUST implement
loading, success, empty, and error states — infinite spinners with no
resolution are PROHIBITED, and error states should offer retry where useful.
Error messages MUST be user-friendly and localized; technical exceptions
MUST NEVER be shown to users. Empty states MUST explain what is empty, why
it matters, and what action the user can take.

## Development Workflow & Quality Gates

**Code Quality Gates**: Before any feature is considered complete, run
`flutter analyze`, `flutter test`, and `flutter format`, and fix warnings
rather than suppressing them. `// ignore` comments, `dynamic`, unnecessary
casts, force unwraps, huge methods, and duplicated code are PROHIBITED
unless a documented reason exists. CI/CD MUST fail a PR when formatting,
static analysis, or required tests fail; the pipeline should progress
toward covering formatting, analysis, tests, build, security checks,
versioning, and release artifacts.

**Naming**: Classes use `PascalCase`; variables/functions use `camelCase`;
files use `snake_case.dart`. Names must communicate intent — prefer specific
names (`CurrencyFormatter`, `TransactionMapper`,
`NetworkConnectivityService`) over vague ones (`Utils`, `Helper`, `Manager`)
unless the responsibility named is genuinely and narrowly clear.

**Refactoring Discipline**: When modifying existing code: understand current
behavior, preserve required functionality, identify architectural
violations, refactor incrementally, avoid unrelated changes, run tests and
the analyzer, and verify UI behavior. Do not rewrite entire modules
unnecessarily. When existing code conflicts with this constitution, improve
it incrementally rather than leaving the bad pattern in place or performing
an unscoped rewrite.

**Code Review Mode**: Before finalizing code, review it as a senior Flutter
engineer would: Is responsibility in the correct layer? Is it reusable,
testable, performant, secure? Is state immutable and `copyWith()` used
correctly? Is error handling, localization, and RTL support complete? Is
offline behavior handled? Does it duplicate existing code? Is there a
simpler solution? Will it scale?

**Definition of Done**: A feature is complete only when architecture is
correct; UI is implemented; loading/error/empty states exist; localization
and RTL both work; validation exists; accessibility was considered; network
behavior is handled; appropriate tests exist; the analyzer and formatter
pass; there is no obvious performance regression; there is no sensitive
data leakage; and the code is reusable and maintainable. Compiling is not
sufficient.

**Prohibited Patterns**: API calls, business logic, or database access in
widgets; repository implementations in Domain; unnecessary Flutter-specific
code in Domain; mutated state or mutated collections inside state;
hardcoded user-facing strings, colors, or dimensions; ignored or swallowed
errors; raw exceptions exposed to UI; API keys in source code; AI performing
critical financial calculations; auto-saved OCR financial data without
confirmation; duplicated shared components; giant BLoCs or screens;
unjustified abstractions; unjustified new dependencies; a second
state-management solution; and randomly mixed architectural patterns.

**Architectural Decision Rule**: When choosing between two approaches,
prefer the option with the best overall balance of simplicity,
maintainability, testability, performance, scalability, security, and
developer experience — never choose a technology merely because it is
popular. Explain non-obvious architectural decisions where they are made
(PR description, ADR, or code comment on WHY).

## Governance

This constitution supersedes all other engineering practices, style guides,
and prior informal conventions for this project. All PRs and code reviews
MUST verify compliance with it, using the Code Review Mode and Definition of
Done checklists above as the baseline review criteria. Any complexity that
deviates from a principle here (e.g. bypassing BLoC, skipping a use case,
adding a hardcoded value) MUST be explicitly documented and justified in the
PR/commit description; undocumented deviations MUST be treated as defects to
be fixed, not precedents to be followed.

**Financial Domain Override**: Because this is a financial application,
correctness MUST always be prioritized over convenience. Financial records
MUST NEVER be silently modified. Every financial mutation MUST be traceable
via IDs, timestamps, audit metadata, and transaction history, and MUST go
through explicit user confirmation and deterministic calculation (Principles
VIII, X, XI). Where this override and any other guidance in this document
appear to conflict, the Financial Domain Override controls.

**Pre-Implementation Checklist**: Before implementing any feature, the
owning engineer (human or AI) MUST determine: which feature owns it; which
layer owns the responsibility; the Domain entity involved; the required
UseCase(s); the required Repository and DataSource; the BLoC/Cubit state
shape needed; which shared components can be reused; what errors can occur;
offline behavior; Arabic/RTL behavior; behavior on slow devices; required
tests; security concerns; and whether the design can be simplified. Only
after answering these should implementation begin.

**Amendment Procedure**: Amendments are made by editing this file directly
(or via the project's constitution-update workflow), and MUST include an
updated Sync Impact Report describing what changed. Any principle removal or
redefinition that narrows or reverses an existing MUST/NEVER rule requires
explicit sign-off from the project owner before merge.

**Versioning Policy**: This constitution follows semantic versioning:
- MAJOR — backward-incompatible governance changes, or removal/redefinition
  of an existing principle.
- MINOR — a new principle or materially expanded section is added.
- PATCH — clarifications, wording fixes, or non-semantic refinements.

**Compliance Review**: Every PR review and every AI-assisted implementation
session MUST check the change against the Core Principles, the Engineering &
Quality Standards, and the Definition of Done before the work is considered
finished. Deviations found after merge MUST be filed as follow-up work, not
silently left in place.

**Version**: 1.0.0 | **Ratified**: 2026-09-19 | **Last Amended**: 2026-09-19
