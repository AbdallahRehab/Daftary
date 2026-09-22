# Phase 1 Data Model: AI Financial Assistant

Derived from the spec's Key Entities section, the Clarifications/Assumptions, and Phase 0 research decisions (bounded-context tool-calling, secure-storage-only secrets, five-way typed failure taxonomy). All money fields referenced by a tool result are integer minor units (piastres), inherited unchanged from whichever existing use case produced them — this feature never re-derives or reformats a money value beyond what the source use case already returns. All timestamps are UTC `DateTime`.

## Entity: AIConversation

The single, continuous, locally-stored conversation between the user and the assistant (spec Assumptions: not multi-thread in this iteration).

| Field | Type | Rules |
|---|---|---|
| `id` | `String` (UUID) | Primary key. Exactly one row ever exists per installation in this iteration — created lazily the first time the assistant is enabled (User Story 1), never user-creatable directly |
| `createdAt` | `DateTime` | Set once, at first-enable |
| `lastActivityAt` | `DateTime` | Updated whenever a new `AIMessage` is appended |

**Lifecycle**: `created` (on first enable) → grows via appended `AIMessage` rows → `cleared` (all its `AIMessage` rows are deleted, FR-012; the `AIConversation` row itself is either reset in place or recreated — an implementation detail, not user-visible either way) . Disabling the assistant (User Story 5) does **not** clear the conversation — only an explicit clear action (FR-012) or full data deletion (FR-013) does.

## Entity: AIMessage

One turn within the `AIConversation` — either the user's question or the assistant's response (spec Key Entities).

| Field | Type | Rules |
|---|---|---|
| `id` | `String` (UUID) | Primary key |
| `conversationId` | `String` (FK → `AIConversation.id`) | Required |
| `sender` | enum `user` \| `assistant` | Required (FR-011) |
| `content` | `String` | The question text (sender = user) or the assistant's final narrated answer text (sender = assistant). Never contains raw provider JSON or tool-call payloads — those live in `groundingRefsJson` below, kept separate from display text |
| `status` | enum `sent` \| `answered` \| `failed` | `user` messages: `sent` → `answered` (an assistant reply exists) or `failed` (User Story 6, FR-018 — retryable without retyping). `assistant` messages are always created already `answered` |
| `failureReason` | enum? `invalidApiKey` \| `rateLimited` \| `network` \| `providerError` \| `unrecognizedResponse` \| `null` | Set only when `status = failed`; mirrors the five typed failures from research.md Decision 6, drives which localized message/`AIFailureBanner` variant is shown |
| `groundingRefsJson` | `String?` | For an `assistant` message only: a JSON list of which tool(s) were called and which existing use case each wrapped (e.g. `[{"tool":"getCategorySpend","usesCase":"GetCategoryBreakdown"}]`), so every stated figure is traceable to a real computed value (spec Key Entities: "AI Message... a reference to which existing calculation(s) grounded its stated figures"). `null` for a message that needed no tool call (e.g. a pure decline/clarifying-question response per User Story 3) |
| `createdAt` | `DateTime` | Required |

**Validation rules**:
- `content` MUST NOT be empty for a `sent`/`answered` message (an empty question is rejected client-side before persistence).
- A `failed` message MUST have a non-null `failureReason`; an `answered`/`sent` message MUST have a null `failureReason`.
- `groundingRefsJson`, when present, MUST reference only tools defined in `contracts/financial_query_tools.md` — enforced by construction, since it is populated exclusively from the actual tool-dispatch result inside `AskFinancialQuestion`, never accepted as free-form input from the model.

**Rule (the single most important one in this feature)**: An `assistant` message's `content` MUST NEVER state a specific financial figure that does not appear, verbatim, in the structured result of one of the tool calls referenced by that same message's `groundingRefsJson`. This is enforced procedurally, not by a database constraint: `AskFinancialQuestion` constructs the prompt so the model may only narrate values it was actually handed by a tool result, and the model is never given standalone "compute this" latitude — see `contracts/financial_query_tools.md` and `contracts/ai_service.md`.

## Entity: AIAssistantSettings

The user's assistant configuration (spec Key Entities). Exactly one row per installation, created with defaults (`isEnabled = false`) at first app launch — never user-creatable, only updatable via `EnableAIAssistant`/`DisableAIAssistant`/`UpdateProviderCredentials`.

| Field | Type | Rules |
|---|---|---|
| `id` | `String` | Fixed singleton id (e.g. a constant, not a generated UUID — there is exactly one settings row) |
| `isEnabled` | `bool` | Default `false` (FR-001). Only `true` after both a key has been stored **and** consent has been accepted (FR-003) |
| `providerId` | `String?` | Identifies which provider adapter to use (a preset id, or a marker for "custom" — research.md Decision 7). `null` while disabled/never configured |
| `hasStoredCredential` | `bool` | `true` only when a key currently exists in secure storage for `providerId`. **Never** the key value itself — the key lives exclusively in `flutter_secure_storage` (research.md Decision 3) |
| `consentAcceptedAt` | `DateTime?` | Set when the user accepts the data-sharing disclosure (FR-003); cleared on disable (User Story 5, FR-016 — re-enabling requires re-accepting) |
| `updatedAt` | `DateTime` | Updated on every settings change |

**Validation rules**:
- `isEnabled = true` MUST imply `hasStoredCredential = true` AND `consentAcceptedAt != null` — enforced by `EnableAIAssistant` performing both writes atomically; there is no code path that sets `isEnabled = true` any other way.
- Disabling (`DisableAIAssistant`) always sets `isEnabled = false`, clears `consentAcceptedAt`, and deletes the credential from secure storage (`hasStoredCredential = false`) in one operation — never a partial disable that leaves the key resident (FR-014, FR-016).

**Never stored here**: the API key value (secure storage only, research.md Decision 3); any per-message content (that's `AIMessage`).

## Value Object: ToolResult *(ephemeral, not persisted independently)*

The structured, minimal return value of one tool call inside `contracts/financial_query_tools.md`, produced by wrapping exactly one existing use case's already-`Either<Failure, T>` result.

| Field | Type | Derivation |
|---|---|---|
| `toolName` | `String` | Which tool produced this (e.g. `getCategorySpend`) |
| `sourceUseCase` | `String` | Which existing use case's return value this is a direct, unmodified projection of (e.g. `GetCategoryBreakdown`) — this is what populates `AIMessage.groundingRefsJson` |
| `data` | `Map<String, Object?>` | The minimal structured fields the model needs to answer the specific question (e.g. `{"category":"Food","amountMinorUnits":350000,"period":"2026-09"}`) — never the full return object of the wrapped use case if it contains more than the question needs (FR-007) |
| `foundData` | `bool` | `false` when the wrapped use case legitimately found nothing (e.g. no savings goal exists, person not found) — this is what lets the model produce an honest "I don't have that" answer (User Story 3) instead of narrating an empty/zero result as if it were meaningful |

**Rule**: `ToolResult` is never itself stored as a standalone row — it exists only for the duration of one `AskFinancialQuestion` execution, after which its provenance is compressed into `AIMessage.groundingRefsJson` and its narrated content becomes part of `AIMessage.content`.

## Relationships

```
AIConversation (1) ──< (many) AIMessage
AIAssistantSettings (singleton, no relationship to AIConversation/AIMessage —
                       governs whether AskFinancialQuestion may run at all)
```

- `AskFinancialQuestion` reads `AIAssistantSettings` (must be `isEnabled = true`) and the secure credential before doing anything else; if either check fails, it returns a failure without ever constructing a provider request.
- Every `ToolResult` a given `AskFinancialQuestion` execution produces comes from calling into another feature's **existing, unmodified** Domain layer (`people`, `transactions`, `finance`/007, `occasions`/008, `budgets`/010, `savings`/011) — this feature never queries their `drift` tables directly and never duplicates their aggregation logic (constitution Principle VI, spec FR-023).

## Drift Schema Sketch (for Phase 2 task planning, not exhaustive DDL)

```
Table AIConversations (
  id TEXT PRIMARY KEY,
  created_at INTEGER NOT NULL,        -- epoch millis, UTC
  last_activity_at INTEGER NOT NULL
)

Table AIMessages (
  id TEXT PRIMARY KEY,
  conversation_id TEXT NOT NULL REFERENCES AIConversations(id),
  sender TEXT NOT NULL,               -- 'user' | 'assistant'
  content TEXT NOT NULL,
  status TEXT NOT NULL,               -- 'sent' | 'answered' | 'failed'
  failure_reason TEXT NULL,           -- nullable enum, see AIMessage.failureReason
  grounding_refs_json TEXT NULL,
  created_at INTEGER NOT NULL
)
-- indexed on (conversation_id, created_at) for chronological scroll

Table AISettings (
  id TEXT PRIMARY KEY,                -- fixed singleton value
  is_enabled INTEGER NOT NULL DEFAULT 0,   -- boolean
  provider_id TEXT NULL,
  has_stored_credential INTEGER NOT NULL DEFAULT 0,
  consent_accepted_at INTEGER NULL,
  updated_at INTEGER NOT NULL
)
```

No foreign key from `AIMessages`/`AIConversations`/`AISettings` points into any other feature's tables, and no other feature's table gains a column or foreign key pointing into these — consistent with FR-023 and the constitution's "no duplicated source of truth" rule already applied throughout the roadmap.
