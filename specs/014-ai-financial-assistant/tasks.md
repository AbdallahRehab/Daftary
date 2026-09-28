---

description: "Task list for AI Financial Assistant (feature 014)"
---

# Tasks: AI Financial Assistant

**Input**: Design documents from `/specs/014-ai-financial-assistant/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present). **Hard dependency** (added 2026-09-22 per `/speckit-analyze` finding F6, matching 012/013's gating rigor): features 001 (People/Transactions), 007 (Income & Expense), 008 (Occasions), 010 (Budgets), and 011 (Savings) MUST all be implemented first — `GetOverview`/`GetPersonBalance` (001), `GetFinanceSummary`/`GetCategoryBreakdown` (007), `GetOccasionDetail`/`GetOccasionsList` (008), `GetBudgetForMonth` (010), and `GetGoalDetail`/`GetSavingsOverview`/`CalculateWhatIfMonthlyContribution` (011) must all exist and be registered in DI before Phase 2 (US2's tool implementations, T035) of this feature can begin. This is a hard gate, not the softer build-order note below — do not start T035 against a half-built dependency.

**Tests**: Included, consistent with 001/007/008/010/011's precedent (constitution Principle XVI). Each user story's tests are written before its implementation tasks (TDD ordering). The `domain/tools/` pass-through tests (US2) are the single most important test suite in this feature, per constitution Principle VIII/IX — they are the automated proof that no tool ever performs its own arithmetic.

**Organization**: Tasks are grouped by user story (spec.md priorities P1-P3) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no unmet dependencies)
- **[Story]**: Maps to spec.md user stories (US1-US7)
- File paths follow plan.md's Project Structure exactly

## Path Conventions

Single Flutter app, feature-first per constitution Principle II: `lib/core/`, `lib/features/ai_assistant/{data,domain,presentation}` — a fully independent new feature that only *calls into* the existing `transactions`, `finance`, `occasions`, `budgets`, `savings` features' own already-implemented Domain use cases, never their tables directly. `test/` mirrors `lib/`; `integration_test/` for end-to-end flows.

**Build-order note**: per ROADMAP-PLAN.md's own dependency graph, this feature is sequenced last in V2 — every existing use case referenced below (`GetFinanceSummary`, `GetPersonBalance`, `GetBudgetForMonth`, `GetGoalDetail`, `GetOccasionDetail`, etc.) is expected to already exist in the codebase by the time these tasks run. If any referenced use case is not yet implemented when a task below is picked up, that use case's own feature must land first — this tasks.md does not re-implement any of them.

---

## Phase 1: Setup

**Purpose**: Directory skeleton and the two new dependencies this feature (uniquely in the app) requires.

- [X] T001 Create the directory skeleton: `lib/features/ai_assistant/{data/{datasources,models,services,repositories},domain/{entities,repositories,services,tools,usecases},presentation/{cubit,pages,widgets}}/`, mirrored under `test/features/ai_assistant/{domain/{tools,usecases},data/{datasources,repositories,services},presentation/cubit}/`.
- [X] T002 [P] Add `flutter_secure_storage` and `http` to `pubspec.yaml` dependencies (research.md Decisions 2-3 — this app's first-ever secure-storage and network dependencies); run `flutter pub get`.

**Checkpoint**: Directories and dependencies exist.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Entities, failures, schema, and the interface boundaries (`AIAssistantRepository`, `AIService`, `SecureCredentialStore`) every user story depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 [P] Define the `AIConversation` entity (`id`, `createdAt`, `lastActivityAt`) in `lib/features/ai_assistant/domain/entities/ai_conversation.dart`, per data-model.md — exactly one row per installation, created lazily on first enable.
- [X] T004 [P] Define the `MessageSender` enum (`user`/`assistant`), `MessageStatus` enum (`sent`/`answered`/`failed`), `AIFailureReason` enum (`invalidApiKey`/`rateLimited`/`network`/`providerError`/`unrecognizedResponse`), and the `AIMessage` entity (`id`, `conversationId`, `sender`, `content`, `status`, `failureReason?`, `groundingRefsJson?`, `createdAt`) in `lib/features/ai_assistant/domain/entities/ai_message.dart`, encoding data-model.md's validation rules verbatim: `content` MUST NOT be empty for a `sent`/`answered` message; a `failed` message MUST have a non-null `failureReason`; an `answered`/`sent` message MUST have a null `failureReason`.
- [X] T005 [P] Define the `AIAssistantSettings` entity (`id` fixed singleton, `isEnabled` default `false`, `providerId?`, `hasStoredCredential`, `consentAcceptedAt?`, `updatedAt`) in `lib/features/ai_assistant/domain/entities/ai_assistant_settings.dart`, encoding data-model.md's invariant verbatim: "`isEnabled = true` MUST imply `hasStoredCredential = true` AND `consentAcceptedAt != null`" — enforced by construction (no public setter can produce an invalid combination).
- [X] T006 [P] Define the `ToolResult` value object (`toolName`, `sourceUseCase`, `data: Map<String, Object?>`, `foundData`) in `lib/features/ai_assistant/domain/entities/tool_result.dart`, per data-model.md — ephemeral, never persisted independently.
- [X] T007 [P] Add `InvalidApiKeyFailure`, `RateLimitFailure`, `AINetworkFailure`, `AIProviderFailure`, `UnrecognizedAIResponseFailure` (each extending the core `Failure` from `lib/core/error/failure.dart`) in `lib/features/ai_assistant/domain/entities/ai_assistant_failures.dart`, per research.md Decision 6 — five distinct, mutually exclusive failure types, never a generic catch-all.
- [X] T008 Update `lib/core/database/app_database.dart`: add `AIConversations`, `AIMessages`, `AISettings` drift tables per data-model.md's Drift Schema Sketch, including the `INDEX` on `AIMessages(conversation_id, created_at)`; bump `schemaVersion` by 1 with an additive `onUpgrade` step (research.md Decision 8 — exact target version determined by whichever prior migration has already landed). **Zero changes to any existing table.** Run `dart run build_runner build --delete-conflicting-outputs`.
- [X] T009 Define the `AIAssistantRepository` abstract interface in `lib/features/ai_assistant/domain/repositories/ai_assistant_repository.dart` per `contracts/ai_assistant_repository.md` (all method signatures: `getSettings`, `enable`, `disable`, `updateCredentials`, `getMessages`, `appendMessage`, `clearConversation`).
- [X] T010 Define the `AIService` abstract interface plus its `AITurnResult`, `AITurnMessage`, `AIToolDeclaration`, `AIToolCallRequest` value objects in `lib/features/ai_assistant/domain/services/ai_service.dart` per `contracts/ai_service.md` — `sendTurn`'s five-way typed failure mapping documented verbatim in the doc comment.
- [X] T011 [P] Define the `SecureCredentialStore` abstract interface (`write(providerId, key)`, `read(providerId)`, `delete(providerId)`) in `lib/features/ai_assistant/domain/services/secure_credential_store.dart`, per research.md Decision 3 — never exposes the key value to any layer above the repository that calls it.
- [X] T012 [P] Define the fixed tool catalog (`getCategorySpend`, `getTopSpendingCategory`, `compareSpendingAcrossPeriods`, `getPersonBalance`, `getOwedOverview`, `getBudgetStatus`, `getSavingsGoalStatus`, `getSavingsProjection`, `getOccasionTotals`) as `AIToolDeclaration`s (name/description/argument schema, declarations only) in `lib/features/ai_assistant/domain/tools/tool_catalog.dart`, per `contracts/financial_query_tools.md` — implementations follow per-story below (T035).
- [X] T013 Register `lib/core/di/injection.dart` scanning confirmation for `lib/features/ai_assistant/` (DI annotations added incrementally per task below).

**Checkpoint**: Schema, entities, and interface boundaries exist. User story implementation can now begin.

---

## Phase 3: User Story 1 - Enable the Assistant (API Key + Consent) (Priority: P1) 🎯 MVP (part 1 of 3)

**Goal**: The assistant is off by default; enabling requires both a stored key and explicit consent, atomically.

**Independent Test**: Open setup, enter a provider+key without accepting consent — confirm the assistant remains unusable; accept consent — confirm it becomes enabled with `consentAcceptedAt` set (quickstart.md Scenarios 1-2).

### Tests for User Story 1 ⚠️

- [X] T014 [P] [US1] Unit test `EnableAIAssistant`: rejects an empty/malformed key with `ValidationFailure` before ever touching secure storage or the network (`contracts/ai_assistant_repository.md` note); only sets `isEnabled=true` when both a key and a consent timestamp are supplied, atomically — in `test/features/ai_assistant/domain/usecases/enable_ai_assistant_test.dart`.
- [X] T015 [P] [US1] Unit test `DisableAIAssistant`: sets `isEnabled=false`, clears `consentAcceptedAt`, and deletes the credential via `SecureCredentialStore` as one atomic operation (mock call-order verification) — in `test/features/ai_assistant/domain/usecases/disable_ai_assistant_test.dart`.
- [X] T016 [P] [US1] Unit test `UpdateProviderCredentials`: replaces the stored key without changing `isEnabled`/`consentAcceptedAt`; rejects an empty key — in `test/features/ai_assistant/domain/usecases/update_provider_credentials_test.dart`.
- [X] T017 [P] [US1] Repository test against an in-memory `NativeDatabase.memory()` + a faked `SecureCredentialStore`: `AIAssistantRepositoryImpl.getSettings`/`enable`/`disable`/`updateCredentials`, including the default disabled singleton row on first read — in `test/features/ai_assistant/data/repositories/ai_assistant_repository_impl_test.dart`.
- [X] T018 [P] [US1] `bloc_test` for `AISettingsCubit`: key-entered-but-no-consent leaves the assistant unusable; consent-after-key enables it; validation-error and duplicate-submit-guard paths (constitution Duplicate Action Protection) — in `test/features/ai_assistant/presentation/cubit/ai_settings_cubit_test.dart`.

### Implementation for User Story 1

- [X] T019 [US1] Implement `lib/features/ai_assistant/data/datasources/secure_credential_store_impl.dart` wrapping `flutter_secure_storage` (research.md Decision 3): a fixed logical key name per `providerId`, the value never logged or exposed in a `toString()`.
- [X] T020 [US1] Implement `lib/features/ai_assistant/data/datasources/ai_assistant_dao.dart` (drift DAO): `AISettings` singleton row read/upsert (conversation/message methods are added in US2/US4).
- [X] T021 [P] [US1] Implement `lib/features/ai_assistant/data/models/ai_settings_mapper.dart` mapping drift rows <-> `AIAssistantSettings` (T005).
- [X] T022 [US1] Implement `AIAssistantRepositoryImpl.getSettings`/`enable`/`disable`/`updateCredentials` in `lib/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart` (depends on T009, T019-T021).
- [X] T023 [P] [US1] Implement `lib/features/ai_assistant/domain/usecases/enable_ai_assistant.dart`, `disable_ai_assistant.dart`, `update_provider_credentials.dart`, wrapping T022.
- [X] T024 Annotate `AIAssistantRepositoryImpl`, `SecureCredentialStoreImpl`, `AIAssistantDao`, and the US1 use cases with `@injectable`/`@LazySingleton(as: ...)`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T019-T023).
- [X] T025 [US1] Implement `lib/features/ai_assistant/presentation/cubit/ai_settings_cubit.dart` + `ai_settings_state.dart`: setup flow (provider selection → key entry → consent acceptance → enable), disable action, update-credentials action, Save disabled immediately on tap (depends on T023, T024).
- [X] T026 [P] [US1] Implement `lib/features/ai_assistant/presentation/widgets/consent_disclosure_sheet.dart`: plain-language disclosure stating only minimal per-question structured data is ever sent, never a full data dump (FR-003/FR-004).
- [X] T027 [US1] Implement `lib/features/ai_assistant/presentation/pages/ai_settings_page.dart`: provider preset chips + a custom-entry fallback (research.md Decision 7), a masked API key field never redisplayed in full after entry (FR-004), `ConsentDisclosureSheet` gating Save, and a disable action with clear re-confirmation copy (depends on T025, T026).
- [X] T028 Register `/ai-assistant/settings` route in `lib/core/routing/app_router.dart` and a reachable entry point (Home quick action / persistent affordance) defaulting to the disabled/setup state (depends on T027).
- [X] T029 [P] [US1] Add `ar`/`en` ARB keys for setup/consent copy in `lib/core/l10n/app_en.arb`, `app_ar.arb` (FR-021).

**Checkpoint**: Enable/disable and consent gating are fully correct and testable on their own; the assistant answers nothing yet (US2).

---

## Phase 4: User Story 2 - Ask a Financial Question and Get a Grounded Answer (Priority: P1) 🎯 MVP (part 2 of 3)

**Goal**: An enabled assistant answers real questions using only values sourced from existing deterministic use cases, never its own arithmetic.

**Independent Test**: With seeded data and a faked `AIService` scripted to call the matching tool, ask a category-spend and a who-owes-whom question and confirm the stated figures exactly match the wrapped use cases' own return values (quickstart.md Scenarios 3-4).

### Tests for User Story 2 ⚠️

- [X] T030 [P] [US2] Unit test `getCategorySpend`/`getTopSpendingCategory`/`compareSpendingAcrossPeriods` tools: each returns its wrapped `GetFinanceSummary`/`GetCategoryBreakdown` (007) result unchanged, with zero arithmetic beyond `compareSpendingAcrossPeriods`'s one documented exception (research.md Decision 4 — a direct subtraction/percentage between two already-independently-sourced totals, never an estimate); `foundData=false` when no entries exist for the resolved period — in `test/features/ai_assistant/domain/tools/finance_tools_test.dart`.
- [X] T031 [P] [US2] Unit test `getPersonBalance`/`getOwedOverview` tools: pass through `GetPersonBalance`/`GetOverview` (001) results unchanged; `foundData=false` for an unmatched person name or zero people recorded — in `test/features/ai_assistant/domain/tools/people_tools_test.dart`.
- [ ] T032 [P] [US2] Unit test `getBudgetStatus`, `getSavingsGoalStatus`, `getSavingsProjection`, `getOccasionTotals` tools: each passes through `GetBudgetForMonth` (010) / `GetGoalDetail`+`GetSavingsOverview`+`CalculateWhatIfMonthlyContribution` (011) / `GetOccasionDetail`+`GetOccasionsList` (008) unchanged; `getSavingsProjection` never computes its own projection math; each `foundData=false` on a genuine no-match — in `test/features/ai_assistant/domain/tools/budget_savings_occasion_tools_test.dart`. — PARTIAL: savings tools blocked on feature 011
- [X] T033 [P] [US2] Unit test `AskFinancialQuestion`: dispatches each requested tool call exactly once, resubmits the real unmodified `ToolResult` to `AIService`, persists the final answer with `groundingRefsJson` naming every tool/use-case pair actually used, and sends only the bounded recent-message-window context (research.md Decision 5) — in `test/features/ai_assistant/domain/usecases/ask_financial_question_test.dart`.
- [X] T034 [P] [US2] `bloc_test` for `ChatCubit`: send → loading/typing state → grounded answer appended; a rapid duplicate send while a request is in flight is prevented (FR-019) — in `test/features/ai_assistant/presentation/cubit/chat_cubit_test.dart`.

### Implementation for User Story 2

- [ ] T035 [P] [US2] Implement the 9 tool functions in `lib/features/ai_assistant/domain/tools/` (`get_category_spend.dart`, `get_top_spending_category.dart`, `compare_spending_across_periods.dart`, `get_person_balance_tool.dart`, `get_owed_overview_tool.dart`, `get_budget_status_tool.dart`, `get_savings_goal_status_tool.dart`, `get_savings_projection_tool.dart`, `get_occasion_totals_tool.dart`) per `contracts/financial_query_tools.md`, each injecting and calling exactly the one existing use case it wraps: `GetFinanceSummary`/`GetCategoryBreakdown` from `lib/features/finance/domain/usecases/` (007), `GetPersonBalance`/`GetOverview` from `lib/features/transactions/domain/usecases/` (001), `GetBudgetForMonth` from `lib/features/budgets/domain/usecases/` (010), `GetGoalDetail`/`GetSavingsOverview`/`CalculateWhatIfMonthlyContribution` from `lib/features/savings/domain/usecases/` (011), `GetOccasionDetail`/`GetOccasionsList` from `lib/features/occasions/domain/usecases/` (008). — PARTIAL: savings tools blocked on feature 011
- [X] T036 [US2] Implement `lib/features/ai_assistant/domain/services/system_prompt_builder.dart`: the fixed instruction text sent as the system/context preamble on every turn — narrate only values returned by a tool call, state honestly when a tool returns `foundData=false`, never invent a figure (constitution Principle VIII/IX, FR-006/FR-008).
- [X] T037 [US2] Implement `lib/features/ai_assistant/data/services/ai_service_impl.dart`: an `http`-based adapter (research.md Decision 2) translating `AIService.sendTurn`'s normalized shape to/from the active `providerId`'s request/response format (research.md Decision 1 — one adapter per preset plus a generic OpenAI-compatible-chat-with-tool-calling adapter for custom entry), mapping every HTTP/parse outcome to exactly one of the five typed failures (research.md Decision 6).
- [X] T038 [US2] Implement `AIAssistantRepositoryImpl.appendMessage` (extends T022) and the conversation/message insert-and-query methods in `ai_assistant_dao.dart` (extends T020), creating the singleton `AIConversation` lazily on first use (data-model.md lifecycle).
- [X] T039 [US2] Implement `lib/features/ai_assistant/domain/usecases/ask_financial_question.dart`: reads `AIAssistantSettings`/credential first, builds the bounded context window (T036's preamble + the last-N messages via `getMessages`), calls `AIService.sendTurn`, dispatches any requested tool call(s) via T035's functions exactly once each, resubmits their results, and persists both the user's question and the final assistant message (including `groundingRefsJson`) via `appendMessage` (T038) (depends on T009, T010, T035-T038).
- [X] T040 Annotate `AIServiceImpl`, `SystemPromptBuilder`, all 9 tool functions, and `AskFinancialQuestion` with `@injectable`/`@LazySingleton(as: ...)`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T035-T039). _(Done for the 7 implemented tools; the 2 savings tools stay deferred with T032/T035 until feature 011 exists.)_
- [X] T041 [US2] Implement `lib/features/ai_assistant/presentation/cubit/chat_cubit.dart` + `chat_state.dart`: message list state, send action with a duplicate-in-flight guard (FR-019), a loading/typing indicator while awaiting the provider (depends on T039, T040).
- [X] T042 [P] [US2] Implement `lib/features/ai_assistant/presentation/widgets/chat_bubble.dart` (message alignment follows reading direction, never hardcoded left/right — FR-021) and `typing_indicator.dart`.
- [X] T043 [US2] Implement `lib/features/ai_assistant/presentation/pages/chat_page.dart`: message list (`ChatBubble`), input field, send action wired to `ChatCubit`, reachable only from the enabled state established in US1 (depends on T041, T042).
- [X] T044 Register `/ai-assistant/chat` route in `lib/core/routing/app_router.dart`, linked from the entry point (T028) (depends on T043).
- [X] T045 [P] [US2] Add `ar`/`en` ARB keys for chat UI strings in `lib/core/l10n/app_en.arb`, `app_ar.arb`.

**Checkpoint**: US1 + US2 together deliver "enable, then get a real grounded answer" — the core value proposition.

---

## Phase 5: User Story 3 - Assistant Honestly Declines Rather Than Fabricates (Priority: P1) 🎯 MVP (part 3 of 3)

**Goal**: A missing-data or out-of-scope question produces an honest decline, provably, not incidentally.

**Independent Test**: Ask about a nonexistent savings goal and, separately, ask for a record change or investment advice — confirm no fabricated figure appears and a clear decline is given (quickstart.md Scenarios 5-6).

### Tests for User Story 3 ⚠️

- [X] T046 [P] [US3] Unit test `AskFinancialQuestion`'s `foundData=false` path: the persisted assistant message's `content` contains no numeric figure attributable to the missing data, while `groundingRefsJson` still records which tool was called (so the decline itself remains traceable) — extends `test/features/ai_assistant/domain/usecases/ask_financial_question_test.dart` (T033).
- [X] T047 [P] [US3] Unit test `AskFinancialQuestion`'s no-tool-matched path: when `AIService` returns a final answer with zero tool calls (a decline or a clarifying question), the message is persisted with `groundingRefsJson = null` and is never mistakenly treated as grounded — extends the same test file.
- [X] T048 [P] [US3] `bloc_test` for `ChatCubit`: a decline/clarifying-question response renders as an ordinary answer bubble with no special-cased UI (honesty is enforced upstream in Domain, not in Presentation) — extends `test/features/ai_assistant/presentation/cubit/chat_cubit_test.dart` (T034).

### Implementation for User Story 3

- [X] T049 [US3] Extend `system_prompt_builder.dart` (T036) with explicit instructions: decline any request to create/edit/delete a record (no such tool exists to call, by construction — Principle IX); decline personalized investment/wealth-growth recommendations (spec Assumptions, project.txt §9 boundary); ask a clarifying follow-up rather than guessing which tool applies to an ambiguous question.
- [X] T050 [P] [US3] Add `ar`/`en` ARB keys for any Presentation-layer decline-adjacent copy (e.g. a static fallback shown only if `AIService` is unreachable and a write-like request must still never appear accepted) in `lib/core/l10n/app_en.arb`, `app_ar.arb`.

**Checkpoint**: US1-US3 constitute the full, safe MVP — enable, ask, and never be lied to.

---

## Phase 6: User Story 4 - Continuous Conversation History (Priority: P2)

**Goal**: One persistent, scrollable conversation the user can explicitly and irreversibly clear.

**Independent Test**: Ask across separate sessions and confirm persistence; clear the conversation and confirm it's empty and a new question still works on its own merits (quickstart.md Scenario 7).

### Tests for User Story 4 ⚠️

- [X] T051 [P] [US4] Unit test `GetConversation`/`ClearConversation` use cases: pagination (`limit`/`offset`) returns chronological order; clearing permanently removes every `AIMessage` row without touching `AIAssistantSettings` — in `test/features/ai_assistant/domain/usecases/get_clear_conversation_test.dart`.
- [X] T052 [P] [US4] Repository test: `AIAssistantRepositoryImpl.getMessages`/`clearConversation` against an in-memory drift DB, including a large synthetic message set for smooth-scroll pagination correctness — extends `test/features/ai_assistant/data/repositories/ai_assistant_repository_impl_test.dart` (T017).
- [X] T053 [P] [US4] `bloc_test` for `ChatCubit`: load-more-on-scroll pagination; the clear action resets the visible list to empty; a question asked immediately after clearing succeeds on its own merits — extends `test/features/ai_assistant/presentation/cubit/chat_cubit_test.dart` (T034).

### Implementation for User Story 4

- [X] T054 [P] [US4] Implement `lib/features/ai_assistant/domain/usecases/get_conversation.dart` and `clear_conversation.dart`, wrapping `AIAssistantRepository.getMessages`/`clearConversation` (T009).
- [X] T055 Annotate the US4 use cases with `@injectable`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T054).
- [X] T056 [US4] Extend `chat_cubit.dart`/`chat_state.dart` (T041) with paginated load-more and an explicit clear-conversation action (depends on T054, T055).
- [X] T057 [US4] Wire the existing `AppConfirmDialog` design-system component into `chat_page.dart` (T043) for the irreversible clear action, per FR-012 (depends on T056).
- [X] T058 Document, via a code comment on `ai_assistant_dao.dart`, that `AIConversations`/`AIMessages`/`AISettings` (excluding the secure-stored key, which is never exportable) are the integration point for the roadmap's future data-export/full-deletion feature (§V1.5.3, not yet specced) — satisfies FR-013's intent today by keeping this table shape export/delete-compatible with the existing per-table wipe pattern; no functional coupling exists yet since that feature doesn't exist.

**Checkpoint**: Conversation history is durable, scrollable, and cleanly clearable.

---

## Phase 7: User Story 5 - Disable the Assistant and Stop All Network Calls Immediately (Priority: P2)

**Goal**: Disabling is instant and absolute, including for a request already in flight.

**Independent Test**: Disable mid-request and confirm zero further `AIService` calls occur afterward, the in-flight question is shown interrupted, and the rest of the app is unaffected throughout (quickstart.md Scenario 8).

### Tests for User Story 5 ⚠️

- [X] T059 [P] [US5] Unit test `AskFinancialQuestion`'s enabled-check short-circuit: when `AIAssistantSettings.isEnabled=false` at call time, `AIService.sendTurn` is never invoked (mock verification: zero interactions) — extends `test/features/ai_assistant/domain/usecases/ask_financial_question_test.dart` (T033).
- [X] T060 [P] [US5] `bloc_test` for `ChatCubit`: disabling while a send is in flight marks that message `failed`/interrupted and prevents any further processing of its result; re-enabling afterward requires the full US1 key+consent flow again, never a silent resume — extends `test/features/ai_assistant/presentation/cubit/chat_cubit_test.dart` (T034).
- [X] T061 [P] [US5] Cross-Cubit test: after `AISettingsCubit.disable()`, a subsequent `ChatCubit.send()` attempt fails fast with zero `AIService` interactions, verified via a shared faked repository — in `test/features/ai_assistant/presentation/cubit/disable_stops_calls_test.dart`.

### Implementation for User Story 5

- [X] T062 [US5] Add an in-flight cancellation/guard mechanism to `chat_cubit.dart` (T041/T056): tracks the current in-flight `AskFinancialQuestion` call and, when disabled mid-flight, ignores/discards any late-arriving result instead of rendering it, marking the pending message as interrupted (depends on T025 for the disable trigger, T041).
- [X] T063 [US5] Verify `ai_settings_page.dart` (T027) requires the full enable flow (provider + key + consent) again after any disable — this is structural, not merely a UI rule, since `disable()` (T022) deletes the credential outright (data-model.md) (depends on T027, T022).

**Checkpoint**: Disable is provably instantaneous and total; the rest of the app is unaffected throughout.

---

## Phase 8: User Story 6 - Friendly, Typed Failure States (Priority: P2)

**Goal**: Every failure mode is distinct, localized, friendly, and retryable without retyping.

**Independent Test**: Simulate each of the five failure cases and confirm each produces its own distinct message; confirm the failed question is retryable without retyping (quickstart.md Scenario 9).

### Tests for User Story 6 ⚠️

- [X] T064 [P] [US6] Exhaustive unit test of `AIServiceImpl`'s failure mapping (T037): every simulated outcome (401/403-class, 429-class, a connectivity/timeout exception, a 5xx-class/provider-error envelope, malformed JSON or a reference to a tool name outside `availableTools`) maps to exactly the correct one of the five typed failures — never a raw exception escaping — in `test/features/ai_assistant/data/services/ai_service_impl_test.dart`.
- [X] T065 [P] [US6] Unit test `AskFinancialQuestion`'s failure-path message persistence: a failed turn persists the user's own question as `status=failed` with the correct `failureReason`, never silently dropping it — extends `test/features/ai_assistant/domain/usecases/ask_financial_question_test.dart` (T033).
- [X] T066 [P] [US6] `bloc_test` for `ChatCubit`: each of the five failure reasons renders via a distinct `AIFailureBanner` variant; retry re-sends the same failed message's existing content without requiring re-typing — extends `test/features/ai_assistant/presentation/cubit/chat_cubit_test.dart` (T034).

### Implementation for User Story 6

- [X] T067 [P] [US6] Implement `lib/features/ai_assistant/presentation/widgets/ai_failure_banner.dart`: five distinct localized variants (invalid/revoked key + link to update it; rate-limited + wait copy; network/offline + a distinct "needs an internet connection" message; provider error + retry; unrecognized response + generic retry copy) — never renders raw exception/provider text (FR-017).
- [X] T068 [US6] Extend `chat_cubit.dart`/`chat_state.dart` (T041/T056/T062) with a retry action that re-submits a `failed` message's existing content without requiring the user to retype it (FR-018).
- [X] T069 [US6] Wire `AIFailureBanner` (T067) into `chat_page.dart` (T043) per failed message, with its retry action bound to T068 (depends on T067, T068).
- [X] T070 [P] [US6] Add `ar`/`en` ARB keys for all five failure-state messages in `lib/core/l10n/app_en.arb`, `app_ar.arb` (FR-017/FR-021).

**Checkpoint**: US1-US6 deliver the full, trustworthy, resilient assistant.

---

## Phase 9: User Story 7 - Proactive Observation Surfaced in Conversation (Priority: P3)

**Goal**: An honest, non-repetitive proactive observation appears when one genuinely, meaningfully exists — never fabricated, never repeated unchanged.

**Independent Test**: With 2+ months of category data showing a real, notable change, opening the assistant surfaces it once; with too little history, it doesn't fabricate one (spec User Story 7 AC1-3).

### Tests for User Story 7 ⚠️

- [X] T071 [P] [US7] Unit test a new `getProactiveObservation` tool: wraps `compareSpendingAcrossPeriods`'s (T035) already-tested comparison logic; returns `foundData=false` when the change isn't meaningful (below a documented minimum-percentage threshold fixed in this task's implementation) or history is insufficient — in `test/features/ai_assistant/domain/tools/proactive_observation_tool_test.dart`.
- [X] T072 [P] [US7] Unit test `GetProactiveObservation`'s once-per-meaningful-change de-duplication: reopening the assistant without new qualifying data does not repeat the same observation (spec User Story 7 AC3) — in `test/features/ai_assistant/domain/usecases/get_proactive_observation_test.dart`.
- [X] T073 [P] [US7] `bloc_test` for `ChatCubit`: opening an enabled assistant with a qualifying observation appends it as an assistant-authored message with no preceding user question; a non-qualifying account shows none — extends `test/features/ai_assistant/presentation/cubit/chat_cubit_test.dart` (T034).

### Implementation for User Story 7

- [X] T074 [US7] Implement `lib/features/ai_assistant/domain/tools/get_proactive_observation_tool.dart` (T071) and `lib/features/ai_assistant/domain/usecases/get_proactive_observation.dart`, computed purely from T035's existing tools/use cases; records which comparison it last surfaced (e.g. a small marker field) to satisfy the no-repeat rule (T072) (depends on T035, T009).
- [X] T075 Annotate the US7 use case/tool with `@injectable`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T074).
- [X] T076 [US7] Extend `chat_cubit.dart` (T041) to check for a proactive observation when the assistant is opened (post-enable, per FR-020) and append it as an assistant message when one qualifies (depends on T074, T075).
- [X] T077 [P] [US7] Add `ar`/`en` ARB keys for the proactive-observation framing copy in `lib/core/l10n/app_en.arb`, `app_ar.arb`.

**Checkpoint**: All seven user stories are independently functional.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Quality gates spanning every user story above.

- [X] T078 [P] Run `flutter analyze` and `dart format` across `lib/features/ai_assistant/` and fix all warnings (constitution Code Quality Gates).
- [X] T079 [P] Accessibility pass on `ai_settings_page.dart`/`chat_page.dart`: semantic labels on icon-only actions (send, clear, retry); sufficient contrast on all five `AIFailureBanner` variants; every state distinguished by more than color alone.
- [X] T080 [P] Light/dark theme verification for every new widget (`ChatBubble`, `TypingIndicator`, `AIFailureBanner`, `ConsentDisclosureSheet`) — no hardcoded colors, only `core/design_system` tokens (constitution Principle XV).
- [X] T081 [P] RTL/LTR verification pass: chat bubble alignment, settings form layout, and every failure banner in both Arabic and English (spec SC-008).
- [X] T082 Implement `integration_test/ai_assistant_flows_test.dart` covering quickstart.md Scenarios 1-9 end-to-end against a fake `AIService` — never a real provider (plan.md Testing strategy).
- [X] T083 Execute quickstart.md Scenarios 10-11 (Arabic/English answer parity, RTL/theme) and record results (spec SC-007/SC-008). — Recorded in quickstart.md "Verification results (2026-09-24)"; a real model's reply language and live language/theme switching with a real key still need manual device testing.
- [X] T084 Security pass: confirm a test API key value never appears in logs, crash-report hooks, or any exported/serialized output anywhere in the codebase (constitution Principle XII, spec FR-004). — Also: "delete all my data" now purges the stored key via `PurgeAIAssistantCredentials`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories.
- **User Stories (Phase 3-9)**: All depend on Foundational phase completion.
  - US1, US2, US3 together form the MVP and are intended to be built in that order (US2 needs an enabled assistant to answer anything meaningfully; US3's honest-decline behavior is layered onto the same `AskFinancialQuestion`/`system_prompt_builder.dart` US2 builds).
  - US4 (history), US5 (disable), US6 (failure states) each extend `ChatCubit`/`chat_page.dart` established in US2 — they are independently testable but land most naturally after the MVP (US1-3).
  - US7 depends only on tools/use cases already built in US2 (T035) — it can be deferred indefinitely without affecting any other story.
- **Polish (Phase 10)**: Depends on all desired user stories being complete.

### User Story Dependencies

- **User Story 1 (P1)**: No dependency on any other story — fully independent after Foundational.
- **User Story 2 (P1)**: Requires an enabled assistant to be meaningfully testable end-to-end, but its own tool/`AskFinancialQuestion`/`AIServiceImpl` code has no hard code-dependency on US1's files beyond reading `AIAssistantSettings` (already defined in Foundational).
- **User Story 3 (P1)**: Extends `system_prompt_builder.dart` and `AskFinancialQuestion` from US2 — sequenced immediately after it.
- **User Story 4 (P2)**: Extends `ChatCubit`/`chat_page.dart` from US2 — independently testable via `AIAssistantRepository` directly even before US2's UI exists.
- **User Story 5 (P2)**: Extends `ChatCubit` from US2 and `AISettingsCubit` from US1 — needs both to exist for its cross-Cubit test (T061), though its own guard logic (T062) only touches `ChatCubit`.
- **User Story 6 (P2)**: Extends `AIServiceImpl` from US2 — its failure-mapping tests exercise code already written in US2; only the `AIFailureBanner` UI and retry wiring are net-new.
- **User Story 7 (P3)**: Depends only on US2's tools (T035) and `AIAssistantSettings`/`ChatCubit` — no dependency on US1/US3-US6's own files.

### Within Each User Story

- Tests MUST be written and FAIL before implementation.
- Entities/interfaces before repositories/services.
- Repositories/services before use cases.
- Use cases before Cubits.
- Cubits before pages/widgets.
- Story complete before moving to the next priority (recommended, not enforced — see Parallel Team Strategy below).

### Parallel Opportunities

- T002 (dependencies) can run alongside T001 (directory skeleton).
- All `[P]`-marked Foundational tasks (T003-T007, T011, T012) can run in parallel once T001/T002 are done.
- Once Foundational completes, US1 and US7's tool-catalog groundwork (T012, already Foundational) allow US2's tool tasks (T035) to be drafted in parallel with US1's settings work, though US2's `AskFinancialQuestion` (T039) itself depends on both T035 and the Foundational interfaces.
- All test tasks marked `[P]` within a story phase can run in parallel (different files).
- US4, US6, and US7 can be developed in parallel by different contributors once US2 lands, since each extends a different, largely non-overlapping slice of `ChatCubit`/`AIServiceImpl`/`tools/`.

---

## Parallel Example: User Story 2

```bash
# Launch all tool-wrapper tests for User Story 2 together:
Task: "Unit test getCategorySpend/getTopSpendingCategory/compareSpendingAcrossPeriods tools in test/features/ai_assistant/domain/tools/finance_tools_test.dart"
Task: "Unit test getPersonBalance/getOwedOverview tools in test/features/ai_assistant/domain/tools/people_tools_test.dart"
Task: "Unit test getBudgetStatus/getSavingsGoalStatus/getSavingsProjection/getOccasionTotals tools in test/features/ai_assistant/domain/tools/budget_savings_occasion_tools_test.dart"

# Launch the 9 tool implementations together (independent files, same interface pattern):
Task: "Implement get_category_spend.dart wrapping GetCategoryBreakdown"
Task: "Implement get_person_balance_tool.dart wrapping GetPersonBalance"
Task: "Implement get_budget_status_tool.dart wrapping GetBudgetForMonth"
# ...and the remaining 6 tool files
```

---

## Implementation Strategy

### MVP First (User Stories 1-3 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories).
3. Complete Phase 3: User Story 1 (enable/disable/consent).
4. Complete Phase 4: User Story 2 (grounded answers).
5. Complete Phase 5: User Story 3 (honest decline).
6. **STOP and VALIDATE**: run quickstart.md Scenarios 1-6 against a fake `AIService`. This is the smallest release that is simultaneously useful and constitutionally safe — a version with US1-US2 but without US3 would be a real product-safety gap, not a smaller MVP.

### Incremental Delivery

1. Setup + Foundational → foundation ready.
2. US1 + US2 + US3 → MVP: enable, ask, never be lied to → validate → demo.
3. Add US4 (history) → validate → demo.
4. Add US5 (disable guarantees) → validate → demo.
5. Add US6 (typed failure polish) → validate → demo.
6. Add US7 (proactive observation) → validate → demo.
7. Phase 10 polish after whichever stories are in scope for a given release.

### Parallel Team Strategy

With multiple developers, after Foundational:

- Developer A: US1 (settings/consent) → then US5 (disable guarantees, extends US1).
- Developer B: US2 (tools/AskFinancialQuestion/chat) → the critical path; US3 lands immediately after as the same developer or a close handoff, since it extends the same `system_prompt_builder.dart`.
- Developer C: once US2's `ChatCubit` skeleton exists, US4 (history) and US6 (failure states) can proceed in parallel on different files.
- US7 can be picked up by anyone once US2's tools (T035) exist — it has no other dependency.

---

## Notes

- `[P]` tasks = different files, no dependencies.
- `[Story]` label maps task to specific user story for traceability.
- Every tool in `domain/tools/` (T035, T074) is independently verified to contain zero arithmetic beyond the one documented exception (`compareSpendingAcrossPeriods`) — this is the feature's core constitutional guarantee (Principle VIII) and is tested, not merely asserted in a comment.
- No test in this feature ever contacts a real AI provider — every test and the entire `integration_test/ai_assistant_flows_test.dart` (T082) uses a fake `AIService` implementation, consistent with the app's existing fully-deterministic, non-flaky test suite.
- Commit after each task or logical group.
- Stop at any checkpoint to validate a story independently.
- Avoid: vague tasks, same-file conflicts, cross-story dependencies that break independence.
