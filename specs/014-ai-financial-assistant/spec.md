# Feature Specification: AI Financial Assistant

**Feature Branch**: `014-ai-financial-assistant`

**Created**: 2026-09-22

**Status**: Draft

**Input**: User description: "Roadmap V2.5 — AI Financial Assistant. Ground this in docs/project.txt section 7 (Financial AI Assistant), section 8 (AI Should Also Proactively Help), section 16 (Privacy), and section 20 (AI Architecture), and in constitution Principles VIII (Deterministic Financial Calculations) and IX (AI Integration Is Isolated and Non-Authoritative). A user wants to ask natural-language questions, in Arabic or English, about their own real local financial data and get an answer sourced entirely from real, already-computed values, never from the model's own arithmetic or invention. Architecture: bring-your-own-key, no Daftary-hosted backend, function/tool-calling only against existing deterministic use cases, never raw data access. Read-only in this iteration — the assistant can answer and proactively surface a real computed observation but cannot create, edit, or delete any record. One continuous, clearable local conversation history. Off by default; enabling requires an API key plus explicit data-sharing consent. Disabling stops all outbound calls immediately. Typed, localized, friendly failure states for every network/provider failure mode."

## Clarifications

*No outstanding [NEEDS CLARIFICATION] markers — the provider/backend architecture question was already confirmed by the product owner (bring-your-own-key, no backend); remaining ambiguities below were resolved with reasonable, documented defaults in Assumptions, following the pattern established in prior specs (010, 011).*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enable the Assistant (API Key + Consent) (Priority: P1)

A user who wants to try asking questions about their money must first turn the assistant on: choose or enter their own AI provider, enter their own API key for it, and explicitly agree to a plain-language disclosure of what limited data will be sent to that provider when they ask a question.

**Why this priority**: Nothing else in this feature can happen until the assistant is enabled — this is the mandatory, privacy-respecting front door to every other story, and it is the concrete implementation of the feature being "off by default."

**Independent Test**: Can be fully tested by opening AI Assistant settings while the feature is off, entering a provider and API key, reading and accepting the consent disclosure, and confirming the assistant becomes available; and by attempting to skip the consent step and confirming the assistant remains unavailable.

**Acceptance Scenarios**:

1. **Given** the assistant has never been enabled, **When** the user opens the app, **Then** no AI-related network call is ever made and no assistant entry point suggests otherwise.
2. **Given** the user opens AI Assistant setup, **When** they enter a valid-looking API key for their chosen provider but have not yet accepted the data-sharing consent disclosure, **Then** the assistant remains disabled and cannot be used until consent is explicitly accepted.
3. **Given** the user has entered an API key and accepted consent, **When** they finish setup, **Then** the assistant becomes available from its entry point and the key is never displayed again in full, logged, or shown in plain text after entry.
4. **Given** the user wants to see exactly what will be shared, **When** they view the consent disclosure, **Then** it plainly states that only the minimal data needed to answer a specific question (not a full data dump) is sent to the user's own chosen provider, and to no one else.
5. **Given** the user later wants to change their provider or key, **When** they update it in settings, **Then** the previous key is fully replaced/discarded and the new one takes effect for all subsequent questions.

---

### User Story 2 - Ask a Financial Question and Get a Grounded Answer (Priority: P1)

A user asks a natural-language question in Arabic or English about their own money — spending by category, who owes whom, budget status, or savings projections — and receives an answer that states a real number the app has actually computed, phrased conversationally.

**Why this priority**: This is the entire value proposition of the feature — without a correct, grounded answer, enabling the assistant (User Story 1) has no payoff.

**Independent Test**: Can be fully tested by enabling the assistant with real existing data (recorded expenses, a person balance, a budget, a savings goal), asking a question that requires one of those specific figures, and confirming the number stated by the assistant exactly matches the value already shown elsewhere in the app for the same data and period.

**Acceptance Scenarios**:

1. **Given** the user has recorded food-category expenses this month, **When** they ask "how much did I spend on food this month?" (in Arabic or English), **Then** the assistant states the exact amount already shown in the app's own category breakdown for food this month — never a recalculated or independently estimated figure.
2. **Given** the user has multiple expense categories with different totals, **When** they ask "where do I spend the most?", **Then** the assistant correctly identifies the highest category using the app's own existing category totals, not its own comparison of unverified numbers.
3. **Given** the user has both this month's and last month's spending recorded, **When** they ask "did my spending increase compared to last month?", **Then** the assistant answers using the app's own totals for both months and states the correct direction and, when available, the size of the change.
4. **Given** a person owes the user money and the user owes another person money, **When** they ask "who still owes me money?" and separately "who do I still owe?", **Then** the assistant answers each using the app's existing per-person balance calculation, never its own guess.
5. **Given** the user has an active budget for the current month, **When** they ask about their budget status, **Then** the assistant states the planned/actual/remaining figures exactly as already computed by the budget feature.
6. **Given** the user has an active savings goal, **When** they ask "how much do I need to save monthly to reach my goal?" or a similar projection question, **Then** the assistant states the figure exactly as already computed by the savings projection calculation, never performing its own arithmetic on the target/current amounts.
7. **Given** the user asks a broad question like "give me a financial summary for the month," **When** the assistant responds, **Then** every figure in the summary traces back to an existing computed value (income, expenses, net, notable category changes), assembled and phrased by the assistant but not invented by it.
8. **Given** the user asks the same underlying question once in Arabic and once in English, **When** they receive both answers, **Then** the stated figures are identical and the meaning is equivalent.

---

### User Story 3 - Assistant Honestly Declines Rather Than Fabricates (Priority: P1)

A user asks a question the app genuinely cannot answer — because the relevant data doesn't exist yet, the question is outside what any available calculation covers, or it would require the assistant to invent or estimate a number itself — and the assistant says so honestly instead of producing a plausible-sounding but false answer.

**Why this priority**: This is the direct, testable form of the product's own explicit warning ("the AI must NOT pretend to know things that are not available in the user's data") and the constitution's non-authoritative-AI principle. Without this guarantee, User Story 2's correctness has no floor — a model that is right most of the time but silently fabricates the rest is worse than not having the feature at all for a financial app.

**Independent Test**: Can be fully tested by asking, on an account with little or no data, a question requiring a figure that doesn't exist (e.g. a savings goal that was never created), and confirming the assistant clearly states it doesn't have that information rather than producing any number; and by asking a question outside the assistant's available calculations (e.g. a personalized investment recommendation) and confirming it declines rather than answers.

**Acceptance Scenarios**:

1. **Given** the user has never created a savings goal, **When** they ask "how long until I reach my savings goal?", **Then** the assistant clearly states it has no savings goal on record and does not invent a target, current amount, or timeline.
2. **Given** the user asks about a specific person by name who does not exist in their contacts, **When** the assistant responds, **Then** it states it cannot find that person rather than guessing a balance.
3. **Given** the user asks a question no available calculation covers (e.g. a hypothetical unrelated to their own data, or a request for a personalized investment recommendation), **When** the assistant responds, **Then** it clearly declines and explains what it can help with instead, never fabricating a confident-sounding answer.
4. **Given** the user asks a vague or ambiguous question, **When** the assistant cannot determine which existing calculation applies, **Then** it asks a clarifying follow-up rather than guessing and presenting a possibly-wrong figure as fact.
5. **Given** the assistant is mid-conversation, **When** the user asks it to create, edit, delete, or otherwise change any record (a transaction, a budget, a goal, a person), **Then** it clearly states it cannot make changes in this version and explains where in the app the user can do that themselves.

---

### User Story 4 - Continuous Conversation History (Priority: P2)

A user wants their questions and the assistant's answers to remain visible as one ongoing conversation they can scroll back through, and wants a simple, clear way to erase that history entirely when they want a clean slate.

**Why this priority**: Makes the assistant feel like a persistent, trustworthy presence rather than a stateless one-off tool, and gives the user control over their own conversation data — but the core Q&A value (User Stories 2-3) is already fully delivered without it.

**Independent Test**: Can be fully tested by asking several questions across separate app sessions, confirming the full conversation remains visible on return, then clearing it and confirming the conversation is completely and irreversibly gone.

**Acceptance Scenarios**:

1. **Given** the user has asked several questions in previous sessions, **When** they reopen the assistant, **Then** the full prior conversation is still visible, in order, exactly as before.
2. **Given** the user wants to start fresh, **When** they choose to clear the conversation, **Then** the system asks for confirmation (this is irreversible) and, once confirmed, removes the entire local conversation history immediately.
3. **Given** the user has just cleared their conversation, **When** they ask a new question, **Then** the assistant answers it correctly on its own merits, without needing or referencing the erased history.
4. **Given** the conversation is stored only locally, **When** the user exports or deletes all their app data (existing Reports & Data/Privacy Controls), **Then** the AI conversation history is included in that export/deletion exactly like any other user data.

---

### User Story 5 - Disable the Assistant and Stop All Network Calls Immediately (Priority: P2)

A user who enabled the assistant decides to turn it off — for privacy, cost, or any other reason — and expects that action to immediately and completely stop any further data from being sent to the AI provider.

**Why this priority**: This is a direct, explicit privacy requirement (project.txt §16) and the natural counterpart to User Story 1; without a trustworthy "off" switch, the "off by default" guarantee of User Story 1 means little over time.

**Independent Test**: Can be fully tested by enabling the assistant, disabling it, and confirming (a) no further AI-related network call occurs afterward under any interaction, and (b) the rest of the app continues to work normally and immediately.

**Acceptance Scenarios**:

1. **Given** the assistant is enabled and in active use, **When** the user disables it, **Then** no further outbound call to the AI provider occurs from that moment on, including from any question the user attempts to ask afterward.
2. **Given** a question is being answered (a call is in flight) at the moment the user disables the assistant, **When** the disable action completes, **Then** no further follow-up calls for that question are made and the assistant clearly indicates the answer was interrupted, rather than silently continuing in the background.
3. **Given** the assistant is disabled, **When** the user views the rest of the app (People, Transactions, Finance, Budgets, Savings, Occasions), **Then** every other feature continues to work exactly as before, completely unaffected.
4. **Given** the assistant is disabled, **When** the user later wants to use it again, **Then** they must re-enter an API key and re-accept the consent disclosure (User Story 1) rather than it silently resuming with previously stored credentials without confirmation.

---

### User Story 6 - Friendly, Typed Failure States (Priority: P2)

A user encounters a problem while trying to use the assistant — no internet connection, an invalid or revoked API key, the provider is rate-limiting requests, the provider itself is having an error, or the provider sent back something the app doesn't understand — and sees a clear, specific, localized explanation of what went wrong and what to do next, never a raw technical error.

**Why this priority**: This is the one feature in the app that depends on an external, imperfect third party (the user's own chosen provider) and on network connectivity the rest of the app doesn't need — trustworthy failure handling here is what keeps a provider-side hiccup from looking like the app itself is broken.

**Independent Test**: Can be fully tested by simulating each failure condition (no connection, invalid key, rate limit, provider error, unrecognized response) and confirming each produces a distinct, friendly, localized message with an appropriate next action (retry, fix the key, wait) — never a raw exception or provider error string.

**Acceptance Scenarios**:

1. **Given** the device has no internet connection, **When** the user tries to ask a question, **Then** they see a clear "needs an internet connection" message distinct from every other failure type, and the rest of the app remains fully usable.
2. **Given** the stored API key is invalid or has been revoked by the provider, **When** the user tries to ask a question, **Then** they see a clear message explaining the key isn't working and a direct path to update it, never a raw authentication error.
3. **Given** the provider is rate-limiting the user's requests, **When** this occurs, **Then** the user sees a clear "too many requests, try again shortly" message rather than a generic failure or a raw HTTP status.
4. **Given** the provider itself returns an error or is unavailable, **When** this occurs, **Then** the user sees a clear "the AI provider is having a problem" message with a retry option, never the provider's raw error text.
5. **Given** the provider returns a response the app cannot interpret, **When** this occurs, **Then** the user sees a clear, generic "something went wrong understanding the response" message rather than a crash or a blank/broken message bubble.
6. **Given** any of the above failures occurs, **When** the user views the message list, **Then** their own question remains visible and clearly marked as failed/unanswered, and they can retry it without retyping it.

---

### User Story 7 - Proactive Observation Surfaced in Conversation (Priority: P3)

A user opens the assistant and, without having asked anything yet, sees it offer a real, already-computed observation about their recent finances — such as a notable category increase — phrased conversationally rather than as a raw number dump.

**Why this priority**: A genuinely valuable "someone who remembers my money for me" touch that differentiates the feature from a plain Q&A tool, but the assistant is already fully useful (User Stories 1-3) as a pure question-answering tool without it, and it depends on enough historical data existing to be meaningful.

**Independent Test**: Can be fully tested by enabling the assistant on an account with at least two months of category spending showing a real, notable change, opening the assistant, and confirming it proactively surfaces that specific, correctly-computed change without the user having to ask.

**Acceptance Scenarios**:

1. **Given** the user's restaurant spending this month is meaningfully higher than last month (per the app's own category breakdown), **When** they open the assistant, **Then** it proactively offers this observation, stating the real percentage or amount already computed by the app.
2. **Given** the user has too little history for any notable observation to exist yet, **When** they open the assistant, **Then** it does not fabricate an observation and simply presents its normal ready-to-ask state.
3. **Given** a proactive observation has already been shown once in the current conversation, **When** the user reopens the assistant without new data having changed meaningfully, **Then** it does not repeat the same observation on every open.

---

### Edge Cases

- What happens when the user asks a question mixing Arabic and English in the same sentence? The assistant still answers correctly using the same grounded data, in a naturally matching mixed or dominant-language response, rather than failing or ignoring part of the question.
- What happens when the user's account has zero data at all (brand-new install, nothing recorded anywhere)? The assistant clearly explains it has nothing to report yet and suggests what kind of data to add first, rather than answering with zeros presented as if they were meaningful.
- What happens when the user asks a question that legitimately requires two or more existing calculations combined (e.g. "how much can I save this month?" needing both income/expense totals and existing budget/savings data)? The assistant combines only values obtained from those existing calculations and clearly shows its reasoning is grounded in them, never estimating a gap itself.
- What happens when the user asks the assistant to explain investment or wealth-growth strategy? It declines to give a personalized recommendation and, if relevant, is honest that this app does not offer investment advice, consistent with the product's own explicit caution about this topic.
- What happens if the same question is asked twice in a row? Each is answered independently and honestly; the assistant does not assume the first answer was wrong just because it was asked again, but if the underlying data changed in between (e.g. a new expense was added), the second answer reflects the updated figures.
- What happens if the user double-taps "send" or submits while a previous question is still being answered? Only one request is in flight at a time; a duplicate rapid submission is prevented rather than firing a second overlapping request.
- What happens when the device goes offline in the middle of waiting for an answer? The in-flight question is marked as failed with the "needs an internet connection" state (User Story 6), not left in an indefinite loading state.
- What happens when the app is closed or backgrounded while a question is in flight? On return, the question is not left silently pending forever — it either has completed, or is clearly shown as failed/interrupted and retryable.
- What happens when the user changes the app's language mid-conversation? Existing messages keep the language they were originally given in; new questions and answers use the new language; layout (including RTL/LTR bubble alignment) updates correctly with no broken text direction.
- What happens when the conversation history grows very large over a long period of use? The user can still scroll through their full history smoothly, and clearing it (User Story 4) always removes all of it, not just a recent portion.
- What happens when the user revokes/deletes the API key directly with the provider (outside the app) while it's still stored in the app? The very next question fails with the "invalid/revoked key" state (User Story 6) rather than the app assuming the key is still good.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The AI Assistant MUST be off/disabled by default for every user and MUST make no AI-related network call until explicitly enabled.
- **FR-002**: The system MUST require the user to provide their own API key for their own chosen AI provider before the assistant can be enabled; the app MUST NOT ship with, embed, or default to any pre-configured provider key.
- **FR-003**: The system MUST require the user to explicitly accept a plain-language data-sharing consent disclosure — describing that only the minimal data needed to answer a specific question is sent to the user's chosen provider, and to no one else — before the assistant becomes usable; entering a key alone MUST NOT be sufficient to enable it.
- **FR-004**: The system MUST store the user's API key using the device's secure credential storage, MUST NOT display it in full after initial entry, and MUST NEVER include it in logs, crash reports, or exported data.
- **FR-005**: Users MUST be able to update or replace their provider/API key at any time, with the previous key fully discarded once replaced.
- **FR-006**: The system MUST answer every financial question exclusively using values obtained from the app's own existing, already-implemented deterministic calculations (e.g. category spend, person balances, budget status, savings projections, occasion totals); the assistant MUST NEVER perform its own arithmetic on raw figures and MUST NEVER have direct access to the underlying database.
- **FR-007**: The system MUST supply the assistant only the specific, minimal structured data relevant to a given question — never an unstructured dump of the user's full financial data — and MUST NOT include other people's data beyond what a specific question's answer requires.
- **FR-008**: When a question requires data the user does not have (e.g. a savings goal that doesn't exist, a person not on record) or requires a capability the assistant does not have (e.g. an estimate no existing calculation produces, a personalized investment recommendation), the system MUST have the assistant clearly and honestly say so rather than produce a fabricated or guessed answer.
- **FR-009**: The system MUST support asking and answering questions in both Arabic and English, and MUST respond in a manner consistent with the language of the question asked.
- **FR-010**: The assistant MUST be strictly read-only in this iteration: it MUST NOT create, edit, or delete any record (transaction, person, budget, savings goal, occasion, category, or any other user data), and MUST clearly explain this limitation if the user asks it to make a change.
- **FR-011**: The system MUST maintain one continuous, chronological, locally-stored conversation history (not multiple separate threads) that persists across app sessions until the user clears it.
- **FR-012**: Users MUST be able to explicitly and permanently clear their entire conversation history, with a confirmation step given that the action is irreversible.
- **FR-013**: The conversation history MUST be included alongside other user data in the app's existing data export and full data deletion flows.
- **FR-014**: Users MUST be able to disable the assistant at any time; disabling MUST immediately stop any further outbound AI provider calls, including preventing any additional calls related to a request that was already in flight at the moment of disabling.
- **FR-015**: The rest of the application MUST remain fully functional and completely unaffected regardless of the assistant's enabled/disabled state or its connectivity/failure state.
- **FR-016**: Re-enabling the assistant after it has been disabled MUST require the user to provide a key and accept the consent disclosure again (FR-002, FR-003), not silently resume from previously stored credentials without a fresh confirmation.
- **FR-017**: The system MUST detect and clearly distinguish, with a friendly and localized message for each: no network connectivity, an invalid or revoked API key, provider rate-limiting, a provider-side error/outage, and a provider response the app cannot interpret — and MUST NEVER show a raw exception, stack trace, or raw provider error string to the user.
- **FR-018**: Each failure state (FR-017) MUST leave the user's own question visible and clearly marked as failed/unanswered, with a way to retry it without retyping it.
- **FR-019**: The system MUST prevent a duplicate/overlapping request from being sent while a previous question is still awaiting a response (e.g. from a rapid repeated send action).
- **FR-020**: The system MAY proactively surface, only within the conversation itself, an already-computed observation about the user's recent finances (e.g. a notable category spending change) when one genuinely exists; it MUST NOT fabricate an observation when the underlying data does not support one, and MUST NOT repeat the same unchanged observation every time the assistant is opened.
- **FR-021**: The system MUST present the AI Assistant fully localized in both Arabic and English, with correct RTL/LTR layout including message-bubble alignment following reading direction (not a hardcoded left/right), correct number/currency/date formatting, and correct theming in both light and dark mode.
- **FR-022**: The system MUST keep every other part of the app working with no network connection; the AI Assistant is explicitly the sole feature in the app permitted to require connectivity, and its offline state MUST be visually and textually distinct from its other failure states (FR-017).
- **FR-023**: The system MUST NOT alter, migrate, or affect any existing data or calculation from any other feature (People/Transactions, 007 Income & Expense, 008 Occasions, 010 Budgets, 011 Savings) — the assistant only reads through those features' existing, already-deterministic calculations and never writes to them.

### Key Entities *(include if feature involves data)*

- **AI Conversation**: The single, continuous, locally-stored conversation between the user and the assistant. Attributes: creation timestamp, last-activity timestamp. There is exactly one per user in this iteration (no multi-thread).
- **AI Message**: One turn within the AI Conversation — either the user's question or the assistant's response. Attributes: sender (user/assistant), content, timestamp, delivery status (e.g. sent, answered, failed), and, for an assistant response, a reference to which existing calculation(s) grounded its stated figures (so a response is always traceable back to a real computed value, never opaque).
- **AI Assistant Settings**: The user's assistant configuration. Attributes: enabled/disabled state, chosen provider identity, a reference to the securely-stored API key (never the key value itself as an attribute here), and the timestamp the data-sharing consent was accepted. Disabling clears the enabled state; re-enabling requires re-establishing both the key and consent (FR-016).
- **Financial Query Capability** *(conceptual, not a stored entity)*: One of the assistant's available question types, each mapped one-to-one to an existing, already-implemented deterministic calculation elsewhere in the app (category spend, person balance, budget status, savings projection, occasion totals, and similar). The assistant can only ever answer using the result of one or more of these — it has no other source of financial figures.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can enable the assistant — entering a provider, an API key, and accepting the consent disclosure — in under 60 seconds.
- **SC-002**: For any question whose answer requires a figure the app already computes (category spend, person balance, budget status, savings projection), the number the assistant states exactly matches the value already shown elsewhere in the app for the same data and period, with zero discrepancies across at least 20 varied test questions covering every available calculation type.
- **SC-003**: When asked a question requiring data that does not exist in the user's own records, or a capability outside what any existing calculation covers, the assistant honestly says so in 100% of tested cases, with zero fabricated figures produced.
- **SC-004**: Disabling the assistant results in zero further outbound network calls being observed afterward, verified across scenarios including one where a request was already in flight at the moment of disabling.
- **SC-005**: A user can locate and fully clear their conversation history, with confirmation, in under 15 seconds.
- **SC-006**: 100% of simulated failure scenarios (offline, invalid/revoked key, rate limit, provider error, unrecognized response) produce a distinct, friendly, localized message — zero raw exceptions or raw provider error strings are ever shown.
- **SC-007**: A user asking the same underlying financial question once in Arabic and once in English receives answers stating identical figures and equivalent meaning in both languages, verified across at least 10 paired questions.
- **SC-008**: Switching the app's language between Arabic and English, or switching between light and dark mode, produces zero layout, alignment, or truncation defects in the assistant's conversation view, including message-bubble direction.
- **SC-009**: Across at least 15 adversarial or out-of-scope test questions (asking the assistant to modify data, give personalized investment advice, or answer something no available calculation covers), the assistant declines appropriately in 100% of cases rather than attempting the request or fabricating a plausible answer.

## Assumptions

- **Tool-calling shape is a planning-time decision**: This spec requires only that each question-answering capability maps one-to-one to an existing deterministic calculation and returns structured, minimal data (FR-006/FR-007) — the exact technical shape of that mapping (e.g. how many distinct capabilities are exposed, their precise input/output shape) is a `/speckit-plan`-time architecture decision, not a product requirement.
- **Provider selection**: The assistant offers a short list of well-known AI provider presets for quick setup, plus a way to enter a different/custom provider and key manually, so the user is never limited to a single hardcoded provider (consistent with the confirmed bring-your-own-key decision). The exact preset list is a planning/implementation detail, not fixed by this spec.
- **Conversation retention**: The full conversation history persists locally, unbounded in this iteration, until the user explicitly clears it (FR-012) or performs a full data deletion (FR-013); only a recent, bounded portion of that history is assumed to be included as active context sent to the provider with each new question, to keep each request minimal and cost-controlled (FR-007) — the full history remains visible to the user regardless of how much of it is actively used as context.
- **Response language matching**: The assistant responds in the same language as the question by default, consistent with the app's Arabic-first design principle (constitution Principle XIII); it does not require a separate language selector for the assistant itself.
- **Proactive observations stay inside the chat for this iteration**: Per the roadmap's own Home Dashboard note ("Insights arrive once the AI Assistant is set up"), a proactively-surfaced observation (User Story 7 / FR-020) is shown only within the assistant's own conversation in this iteration, not as a push notification or a separate Home dashboard card — that integration is a reasonable future enhancement, not required here.
- **No personalized investment advice**: Consistent with the product's own explicit caution (docs/project.txt §9) and this feature's read-only, deterministic-grounding scope, the assistant declines personalized investment or wealth-growth recommendations even if asked; a separate, future "Financial Education & Wealth Planning" feature is the intended home for that topic, not this one.
- **Currency**: Single currency (EGP), consistent with the rest of the app; every figure the assistant states is already formatted/computed in EGP by the calculation it draws from.
- **Scope boundary — no write/action capability, no multi-thread, no voice input**: All explicitly out of scope for this iteration, consistent with the roadmap's own V2 scope note; each is a reasonable, low-risk future extension once this read-only Q&A capability is proven, not something this spec invents or partially implements.
- **Re-consent on re-enable, not on every question**: The consent disclosure (FR-003) is accepted once per enable/re-enable cycle (FR-016), not re-shown before every individual question — repeated re-confirmation for every message would be excessive friction inconsistent with a "someone who remembers my money for me" product feel, while still ensuring the user consciously re-confirms every time they choose to turn the feature back on.
- **No silent automatic retries on failure**: Consistent with cost-consciousness and avoiding unexpected provider charges, a failed request (FR-017/FR-018) is retried only when the user explicitly chooses to retry it, never automatically and silently in the background.
