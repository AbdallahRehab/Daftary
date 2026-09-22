# Phase 0 Research: AI Financial Assistant

All decisions below resolve the Technical Context and close every ambiguity the spec's Assumptions section deliberately left to planning time. No `NEEDS CLARIFICATION` markers remain.

## Decision 1: Provider integration shape — a normalized internal protocol, not one hardcoded provider SDK

**Decision**: `AIService` (Domain interface) exposes one normalized method shape — `sendTurn(conversationContext, availableTools) -> AIResponse` — where `AIResponse` is either a final text answer, or one-or-more tool calls to execute and re-submit. The Data-layer implementation translates this normalized shape to/from the specific JSON request/response format of whichever provider the user selected (read from `AISettings.providerId`), via one small adapter per supported provider preset plus a generic "OpenAI-compatible chat-completions + tool-calling" adapter for the free-text/custom entry path, since that request shape is the de-facto common denominator most bring-your-own-key chat/tool-calling providers already support.

**Rationale**: Keeps every layer above `AIService` (use cases, Cubits, UI) completely provider-agnostic — swapping or adding a provider touches exactly one adapter file, never Domain or Presentation (constitution Principle IX). Matches the plan's `AIService` abstraction already declared in the Constitution Check.

**Alternatives considered**:
- *Hardcode a single mandated provider's SDK throughout the app* — rejected outright; directly contradicts the product owner's confirmed bring-your-own-key decision.
- *A generic "raw JSON passthrough" with no normalization* — rejected: would leak provider-specific response shapes into Domain/Presentation, violating Principle IX's isolation requirement and making the typed-failure mapping (FR-017) inconsistent per provider.

## Decision 2: HTTP client — minimal `http` package, not `dio`

**Decision**: Use the `http` package for the single outbound request shape this feature needs (one POST per conversation turn, no file uploads, no complex interceptor chain, no cookie jar).

**Rationale**: `dio`'s interceptor/retry/cancellation machinery solves problems this feature doesn't have — one endpoint, one request shape, explicit no-silent-retry policy (spec Assumptions: "No silent automatic retries on failure"). A minimal client keeps the dependency footprint honest for what is already flagged as this app's very first network dependency (ROADMAP-PLAN.md §1).

**Alternatives considered**:
- *`dio`* — more features than needed; its automatic-retry defaults would need to be explicitly disabled to honor the spec's no-silent-retry requirement, adding configuration risk for no benefit here.
- *Raw `dart:io HttpClient`* — rejected: no timeout/JSON ergonomics, more boilerplate for the same five failure states this feature must distinguish (FR-017).

## Decision 3: Secure key storage — `flutter_secure_storage`, referenced by an opaque id, never embedded in `drift`

**Decision**: The API key is written to `flutter_secure_storage` under a single fixed logical key name; `AISettings` (in `drift`) stores only non-secret metadata (`isEnabled`, `providerId`, `consentAcceptedAt`) plus a boolean `hasStoredCredential`, never the key value or even a hash of it.

**Rationale**: Direct implementation of constitution Principle XII — a secret must never live in the same on-disk SQLite file as ordinary app data, and must never appear in the data-export flow (FR-013 explicitly scopes export/deletion to conversation history + settings metadata, not the key). `flutter_secure_storage` is the standard Flutter-ecosystem wrapper over iOS Keychain / Android Keystore, exactly as already anticipated in ROADMAP-PLAN.md §V2.5 and reused later by V3.1 App Lock.

**Alternatives considered**:
- *Store the key encrypted inside `drift`* — rejected: reinvents OS-provided secure storage with a weaker, app-managed encryption key, and risks the key surviving inside the same file targeted by data export/backup flows.
- *Require re-entry of the key every session (no persistence)* — rejected: contradicts spec FR-005 ("update or replace at any time") implying persistence, and would make the feature unusably frictional for a "someone who remembers my money for me" product.

## Decision 4: Tool-calling grounding boundary — one 1:1 wrapper function per existing use case, zero arithmetic in the wrapper

**Decision**: Every tool exposed to the model lives in `ai_assistant/domain/tools/` as a thin function with the shape `Future<Either<Failure, ToolResult>> call(ToolArgs args)` that does nothing but: (1) validate/coerce the model-supplied arguments into the exact parameter types the wrapped existing use case expects, (2) invoke that existing use case unchanged, (3) map its return value into a small structured JSON-serializable result. No tool function contains a `+`, `-`, `*`, `/`, percentage, or date-math expression of its own — any such operation is by definition missing from an existing use case and is therefore not something this feature is allowed to compute; if a question needs it, either an existing use case already computes it (use that) or the assistant must decline (spec User Story 3). See `contracts/financial_query_tools.md` for the exact tool list wired in this iteration.

**Rationale**: This is the literal, testable form of docs/project.txt §20's explicit instruction ("instead of asking an LLM 'how much does Ahmed owe me,' use a deterministic financial calculation service and provide the result to the AI") and constitution Principle VIII. Keeping the wrapper intentionally forbidden from containing arithmetic (rather than merely "discouraged") makes this constraint enforceable in code review and in the unit tests specified in Project Structure (`domain/tools/` tests assert pass-through-unchanged behavior).

**Alternatives considered**:
- *Let the model call a generic "query" tool with a free-form filter and compute derived figures itself* — rejected outright; this is precisely the anti-pattern the spec (FR-006, User Story 2/3) and the constitution are designed to prevent.
- *Send the model a full data export and let it answer from context (RAG-less full-context approach)* — rejected: violates FR-007 (minimal, per-question data only), balloons every request's cost regardless of what was asked, and increases the chance the model narrates a plausible-looking but wrong number from a huge context instead of an exact tool result.

## Decision 5: Conversation context sent per request — bounded recent window, full history stored and viewable

**Decision**: `AskFinancialQuestion` assembles the context sent to the provider from only the most recent N messages of the single conversation (a configuration constant decided at implementation time, e.g. the last ~20 turns), plus the current question and available tool definitions. The full conversation remains stored in `drift` and fully scrollable/viewable in the UI regardless of N.

**Rationale**: Matches the spec's own Assumption ("only a recent, bounded portion... is assumed to be included as active context... to keep each request minimal and cost-controlled") while satisfying FR-011 (full continuous history persists and is visible). Keeps provider request payload size and per-question cost predictable regardless of how long a user has been using the assistant.

**Alternatives considered**:
- *Send the entire conversation history every time* — rejected: unbounded cost growth and unbounded latency as history grows, explicitly the failure mode the spec's own Edge Cases section calls out ("conversation history grows very large").
- *Summarize older history into a compressed context blob* — rejected for this iteration: introduces a second, non-deterministic AI-generated artifact (a summary) that itself would need grounding/validation; unnecessary complexity for a V1 read-only Q&A feature. A reasonable future enhancement, not required here.

## Decision 6: Failure taxonomy and mapping — five distinct typed `Failure`s, one deterministic mapping rule set

**Decision**: Introduce exactly five new `Failure` subclasses (extending the existing `core/error/failure.dart` hierarchy): `InvalidApiKeyFailure`, `RateLimitFailure`, `AINetworkFailure`, `AIProviderFailure`, `UnrecognizedAIResponseFailure`. `AIServiceImpl` maps every possible outcome (HTTP status code, connectivity exception, JSON-parse exception, provider-specific error envelope) into exactly one of these five — never lets a raw `Exception`, `SocketException`, or provider error body reach `ChatCubit`.

**Rationale**: Direct implementation of spec FR-017/FR-018/SC-006 and constitution Principle VII. Five is the minimum set that lets the UI (`AIFailureBanner`) show a genuinely distinct, actionable message per case (fix the key / wait and retry / check connection / provider is down / try again later), matching User Story 6's acceptance scenarios one-to-one.

**Alternatives considered**:
- *A single generic `AIFailure(message)`* — rejected: cannot distinguish "fix your key" from "just wait," which the spec explicitly requires to be distinct (User Story 6, FR-017).
- *Reuse the app's existing generic `NetworkFailure`/`ServerFailure` names verbatim* — the existing `core/error/failure.dart` (checked during planning) does not currently define a `NetworkFailure`/`ServerFailure`; only `ValidationFailure`, `CacheFailure`, `NotFoundFailure`, `UnknownFailure` exist today (all pre-dating any networked feature). New, feature-appropriate names are added rather than overloading `UnknownFailure` for every AI-specific case, since `UnknownFailure` is reserved for genuinely unexpected conditions per its existing doc comment.

## Decision 7: Provider preset list — a small curated set plus free-text/custom entry, decided at implementation time

**Decision**: `AISettingsPage` offers a short list (exact members decided at task/implementation time, not fixed by this plan) of well-known chat-completion-with-tool-calling providers as one-tap presets (pre-filling the correct API base endpoint for that adapter from Decision 1), plus a "custom provider" option where the user supplies their own endpoint/base URL and key for any other OpenAI-compatible provider. This keeps the product spec's own Assumption ("short list of presets... exact list is a planning/implementation detail") satisfied without this plan prematurely committing to specific third-party names that may change before implementation.

**Rationale**: Avoids hardcoding a "mandated provider" (explicitly disallowed by the confirmed architecture decision) while still giving most users a fast, low-friction setup path; the custom/free-text fallback keeps the feature genuinely bring-your-own-key for any provider, not just the curated list.

**Alternatives considered**:
- *Free-text-only, no presets* — rejected: worse first-run UX for the common case (a user with a well-known provider's key still has to know/paste a base URL correctly).
- *Presets only, no custom entry* — rejected: directly contradicts "bring-your-own-key... the user picks/enters their own provider" from the confirmed architecture decision.

## Decision 8: Schema migration sequencing

**Decision**: `AIConversations`, `AIMessages`, and `AISettings` are added as three new tables in one additive `drift` `schemaVersion` bump, `onUpgrade`-only (no existing table altered), following the exact precedent of every prior additive migration in `app_database.dart` (currently at `schemaVersion` 4). Because specs 008/009/010/011 are sequenced ahead of this feature in the roadmap and are each expected to consume their own schema version bump first, this plan does not hardcode a specific target version number — the exact `schemaVersion` this migration lands on is whatever is next at the time `/speckit-implement` actually runs for this feature, determined by which prior migrations have already landed.

**Rationale**: Matches constitution's additive-migration convention and every prior feature's own plan.md precedent (007 declared "v4→v5" only because it was next in line at its own planning time); hardcoding a number here that later turns out wrong (because 008-011 implement first, as the roadmap requires) would be actively misleading rather than merely imprecise.

**Alternatives considered**: None meaningfully different — this is a process/sequencing note, not a design choice with real alternatives.
