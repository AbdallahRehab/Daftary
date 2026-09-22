# Implementation Plan: AI Financial Assistant

**Branch**: `014-ai-financial-assistant` | **Date**: 2026-09-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/014-ai-financial-assistant/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Let the app's single local user ask natural-language financial questions (Arabic or English) and get answers grounded entirely in values the app has already computed deterministically — never a raw database dump, never model-invented arithmetic. Implemented as one new Flutter clean-architecture feature (`ai_assistant`) with two new local tables (`AIConversations`, `AIMessages`) plus a single-row `AISettings` table, using BLoC/Cubit for state, `flutter_secure_storage` for the user's own bring-your-own AI provider API key (this app's first secret ever stored, and its first network-capable feature), and a minimal HTTP client to call the user's chosen provider directly from the device — there is no Daftary-hosted backend or proxy. The model never receives raw data or database access: every answerable question is exposed to it as one of a small set of structured tools, each a thin, non-computing wrapper around an **existing** deterministic use case (`GetFinanceSummary`/`GetCategoryBreakdown` from 007, `GetPersonBalance`/`GetOverview` from 001, `GetOccasionDetail`/`GetOccasionsList` from 008, `GetBudgetForMonth`/`GetBudgetTrend` from 010, `GetGoalDetail`/`GetSavingsOverview`/`CalculateWhatIfMonthlyContribution` from 011). The assistant is strictly read-only (no tool ever writes), off by default, requires an explicit API key + consent to enable, and disabling it immediately and verifiably halts all outbound calls. This feature does not read, write, or alter any table owned by another feature — it only calls those features' own existing, already-audited Domain use cases.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.47.0 (pinned via `fvm`, `.fvmrc`)

**Primary Dependencies**: `flutter_bloc` (state management, Principle III), `get_it` + `injectable` for DI, `drift` + `sqlite3_flutter_libs` + `path_provider` for the local relational database (same `AppDatabase`, new tables), `fpdart` for `Either<Failure, Success>` result flow, `equatable`, `uuid`, `intl`/`gen_l10n` for Arabic/English localization, `go_router` for navigation. **Two new dependencies, both justified below**: `flutter_secure_storage` (OS Keychain/Keystore — this feature's API key is the first secret this app has ever needed to store; no existing capability covers it) and a minimal HTTP client package (`http` — this feature is the app's first-ever network call; a lighter package is preferred over a full interceptor/retry framework like `dio` since this feature needs exactly one outbound call shape — a JSON chat/tool-call request to one user-chosen endpoint — and nothing resembling the complex multi-endpoint client `dio` is built for).

**Storage**: Local SQLite via `drift`, same single on-device `daftary.sqlite`/`AppDatabase` used by every other feature; three new tables (`AIConversations`, `AIMessages`, `AISettings`) added via an additive `drift` schema migration. The API key itself is **never** stored in `drift`/SQLite — it lives exclusively in the OS secure credential store via `flutter_secure_storage`, referenced from `AISettings` only by an opaque, non-secret key identifier.

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail` (Cubit tests with a faked `AIAssistantRepository`), `integration_test` (enable/consent flow, ask-and-get-grounded-answer flow using a fake `AIService` — **no test ever makes a real network call to a real provider**, consistent with the app's existing fully-deterministic, non-flaky test suite).

**Target Platform**: Android and iOS mobile apps (existing app scope).

**Project Type**: mobile-app (Flutter, feature-first clean architecture).

**Performance Goals**: Every tool call (the local, deterministic side — calling an existing use case) completes in the same sub-second budget already established by the use case it wraps (e.g. `GetFinanceSummary` <1s per 007's own goal); the assistant's own UI never blocks on provider latency (a visible "thinking"/typing state, never a frozen UI, while awaiting the provider's HTTP response, which is outside this app's control and excluded from any latency SLA here).

**Constraints**: This is the **only** feature in the entire app with a network dependency — every other feature MUST remain fully functional offline regardless of this feature's connectivity or enabled state (FR-015/FR-022). The assistant MUST NEVER perform financial arithmetic itself or have direct database access (constitution Principle VIII) — every number it states MUST be traceable to an existing use case's return value (FR-006/FR-007, AIMessage's grounding reference in data-model.md). The API key MUST NEVER appear in logs, crash reports, exported data, or anywhere outside secure storage and the outbound HTTPS request to the user's own chosen provider (constitution Principle XII). The assistant MUST NEVER create/edit/delete any record (constitution Principle IX, FR-010) — every tool exposed to the model is read-only by construction (its Dart signature has no mutating path).

**Scale/Scope**: Single user per device; one continuous, unbounded-storage conversation (not multi-thread, per spec Assumptions); 1 new feature (`ai_assistant`); ~4 screens (AI Assistant setup/settings — provider + key + consent, `ChatPage`, a clear-conversation confirmation, and typed in-chat error/offline states — some of these are dialogs/sheets rather than full pages, decided at task-breakdown time).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Clean Architecture Layering | `ai_assistant` splits into `data/domain/presentation`; `ChatPage`/`AISettingsPage` never touch `drift`, `flutter_secure_storage`, or the HTTP client directly — only through Domain use cases and the `AIAssistantRepository` interface | PASS |
| II. Feature-First Modularity | Code lives under `lib/features/ai_assistant/`; no new global catch-all folder. `SecureCredentialStore` (wrapping `flutter_secure_storage`) starts feature-scoped in `ai_assistant/data/` — it is not promoted to `core/` yet since no second feature needs it today; the roadmap's own V3.1 App Lock item is the first candidate to justify that promotion later, not this feature | PASS |
| III. BLoC/Cubit Mandate | `AISettingsCubit` (setup/provider/key/consent/clear), `ChatCubit` (message list, send, retry, typed failure states) — no alternate state layer | PASS |
| IV. Immutable State | Both Cubits' states are `Equatable` value classes updated via `copyWith()`; the message list inside `ChatState` is never mutated in place — every append/update produces a new list | PASS |
| V. Domain-Driven Business Logic | Use cases: `EnableAIAssistant` (validates key format, persists consent + secure key), `DisableAIAssistant`, `UpdateProviderCredentials`, `AskFinancialQuestion` (orchestrates one conversation turn: builds minimal context, calls `AIService`, dispatches any tool calls, persists both messages), `ClearConversation`, `GetConversation` — each a meaningful business action, several coordinating two repositories/services | PASS |
| VI. Repository Pattern | Domain defines `AIAssistantRepository` (conversation + settings persistence) and the `AIService` interface (the swappable provider client) as abstractions; Data provides `AIAssistantRepositoryImpl` and a concrete `AIService` implementation. Presentation/Domain depend only on the interfaces, resolved via DI | PASS |
| VII. Explicit Error Handling | Every repository/use-case/service call returns `Either<Failure, T>`; new typed failures (`InvalidApiKeyFailure`, `RateLimitFailure`, `AINetworkFailure`, `AIProviderFailure`, `UnrecognizedAIResponseFailure`) added alongside the existing `core/error/failure.dart` hierarchy — never an empty catch, never a raw exception/HTTP error surfaced to the UI | PASS |
| VIII. Deterministic Financial Calculations | **Central to this feature.** No financial figure is ever computed by the model or by any code in `ai_assistant` — every tool the model can call is a direct, unmodified pass-through to an existing use case (`GetFinanceSummary`, `GetCategoryBreakdown`, `GetPersonBalance`, `GetOverview`, `GetOccasionDetail`, `GetBudgetForMonth`, `GetGoalDetail`, `CalculateWhatIfMonthlyContribution`, etc.); the model only narrates the returned value. See `contracts/financial_query_tools.md` | PASS |
| IX. AI Isolation | **This feature is the direct implementation of this principle.** All AI/LLM access sits behind `AIAssistantRepository`/`AIService`; `ChatPage`/`ChatCubit` never call an LLM directly; the API key is never embedded in the client (it is user-entered, stored in secure storage, never a build-time constant); every tool call's inputs/outputs are minimal and structured (`contracts/financial_query_tools.md`); every model response is parsed into a typed structure and validated before display — an unparseable response becomes `UnrecognizedAIResponseFailure`, never raw text rendered blindly | PASS |
| X. OCR Human-in-the-Loop | Not applicable — no OCR in this feature | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | This feature is the one exception to "offline-first" by nature (it needs a live connection to the provider), but it still fully respects the principle's spirit: the app detects offline state and gives a clear, distinct message (FR-017/FR-022) rather than assuming connectivity; a duplicate rapid "send" is prevented (FR-019) since a provider call is not free and must not be double-fired; nothing about this feature affects the idempotency guarantees of any other feature's mutations, because this feature performs no mutations of its own | PASS |
| XII. Security & Secrets | The API key is this app's first-ever secret; it is stored exclusively via `flutter_secure_storage` (Keychain/Keystore), never logged, never in crash reports, never in the exported-data flow (only the non-secret `AISettings` metadata and conversation history are exportable, per FR-013) | PASS |
| XIII. Localization & RTL/LTR | `gen_l10n` ARB additions for `ar`/`en` (setup/consent copy, chat UI, every typed failure message); message-bubble alignment follows reading direction, never hardcoded left/right (FR-021) | PASS |
| XIV. Dependency Injection | `get_it`/`injectable` wires the DAO, `SecureCredentialStore`, `AIService` implementation, repositories, use cases, and both Cubits; nothing self-instantiated, including the HTTP client instance | PASS |
| XV. Design System | Reuses existing `core/design_system` components (`AppButton`, `AppTextField`, `AppCard`, `AppConfirmDialog`, `AppEmptyView`); a chat bubble and a typing/loading indicator are the only genuinely new visual components, built inside `features/ai_assistant/presentation/widgets/` first (not prematurely promoted to `core/`) | PASS |
| XVI. Testability by Design | Use cases/repositories/mappers/tool-dispatch logic unit-tested with a faked `AIService` and faked existing-feature use cases; both Cubits tested with `bloc_test`/`mocktail`; widget tests for setup/consent and chat send/retry/error states; `integration_test` exercises enable→ask→grounded-answer and enable→disable→no-further-calls end-to-end against a fake `AIService`, never a real provider | PASS |

No violations requiring justification — **Complexity Tracking is not needed.** The two new dependencies (`flutter_secure_storage`, a minimal HTTP client) are the direct, minimal, already-anticipated cost of this being the app's first feature needing a secret and a network call at all (roadmap ROADMAP-PLAN.md §V2.5, §1 "Architecturally significant gap") — not scope creep.

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): The tool-calling boundary (`contracts/financial_query_tools.md`) was designed so that adding a new tool in the future never requires touching `AIService`, `ChatCubit`, or any existing feature's use case — only a new thin wrapper function in `ai_assistant/domain/tools/`. No new dependency, layering, or state-management deviation was introduced beyond what Phase 0 already justified. All gates above remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/014-ai-financial-assistant/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/                        # UNCHANGED by this feature (no new cross-cutting code promoted yet)
│   ├── database/                 # AppDatabase gains AIConversations + AIMessages + AISettings
│   │                              # tables, additive migration only (exact schemaVersion bump
│   │                              # determined at implementation time — see research.md)
│   ├── design_system/            # reused as-is
│   ├── di/                       # gains ai_assistant feature registrations (generated via injectable)
│   ├── error/                    # reused; gains InvalidApiKeyFailure/RateLimitFailure/
│   │                              # AINetworkFailure/AIProviderFailure/UnrecognizedAIResponseFailure
│   ├── l10n/                     # app_en.arb / app_ar.arb gain ai_assistant-feature keys
│   └── routing/                  # app_router.dart gains the ai_assistant entry route(s)
│
├── features/
│   ├── people/                   # UNCHANGED — this feature only calls its existing use cases
│   ├── transactions/              # UNCHANGED — same
│   ├── finance/                   # UNCHANGED (007) — same
│   ├── settings/                  # UNCHANGED — AI setup lives in its own feature, not bolted onto Settings
│   ├── onboarding/                # UNCHANGED
│   └── ai_assistant/               # NEW
│       ├── data/
│       │   ├── datasources/       # AIConversationDao (drift): conversation + messages + settings;
│       │   │                       # SecureCredentialStore (flutter_secure_storage wrapper)
│       │   ├── models/            # AIMessageEntity/AISettingsEntity <-> domain mappers; provider
│       │   │                       # request/response DTOs
│       │   ├── services/          # AIServiceImpl (HTTP client, one concrete provider protocol
│       │   │                       # adapter per supported provider preset, selected by AISettings)
│       │   └── repositories/      # AIAssistantRepositoryImpl
│       ├── domain/
│       │   ├── entities/          # AIConversation, AIMessage, AIAssistantSettings
│       │   ├── repositories/      # AIAssistantRepository (abstract)
│       │   ├── services/          # AIService (abstract) — the swappable provider boundary
│       │   ├── tools/             # one thin function per financial_query_tools.md tool,
│       │   │                       # each wrapping exactly one existing use case, read-only
│       │   └── usecases/          # EnableAIAssistant, DisableAIAssistant,
│       │   │                       # UpdateProviderCredentials, AskFinancialQuestion,
│       │   │                       # ClearConversation, GetConversation
│       └── presentation/
│           ├── cubit/             # AISettingsCubit, ChatCubit
│           ├── pages/              # AISettingsPage (provider/key/consent/clear),
│           │                       # ChatPage
│           └── widgets/            # ChatBubble, TypingIndicator, ConsentDisclosureSheet,
│                                    # AIFailureBanner (one visual per typed failure)
│
└── main.dart                       # UNCHANGED (Cubits resolved per-screen via DI, matching
                                     # every other feature — no app-level bootstrap change)

test/
├── features/
│   └── ai_assistant/
│       ├── domain/usecases/       # unit tests, faked repository + faked AIService
│       ├── domain/tools/          # unit tests: each tool passes through its wrapped use case's
│       │                           # return value unchanged and performs zero arithmetic of its own
│       ├── data/repositories/     # AIAssistantRepositoryImpl tests against an in-memory drift DB
│       └── presentation/cubit/    # bloc_test + mocktail (both Cubits, all typed-failure paths)
└── widget/                         # AISettingsPage, ChatPage widget tests (RTL/LTR bubble alignment)

integration_test/
└── ai_assistant_flows_test.dart    # enable (key+consent) -> ask -> grounded answer; honest-decline
                                     # path; disable -> zero further calls; clear conversation
                                     # (US1-US6), all against a fake AIService — never a live provider
```

**Structure Decision**: Standard single Flutter app (Option 1 shape), one new feature-first module `lib/features/ai_assistant/` added alongside the existing five features, per constitution Principle II. `ai_assistant` is deliberately the only feature module in this app with a `data/services/` folder for an outbound network client and a secure-credential datasource — both isolated behind Domain interfaces (`AIService`, and secure storage accessed only through the repository), so no other layer is aware a network call or a secret is even involved. No `backend/`/`api/` split exists or is introduced — the HTTP call targets the user's own chosen third-party provider directly from the device; Daftary has no server component in this feature or anywhere else in the app.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally omitted.
