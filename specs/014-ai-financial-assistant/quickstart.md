# Quickstart: Validating the AI Financial Assistant

This guide proves the feature works end-to-end without a live provider — every scenario runs against a **fake `AIService`** (per `plan.md`'s Testing strategy: no test, automated or manual-during-development, should depend on a real network call or a real provider account). Prerequisites, setup, and expected outcomes only; implementation code belongs in `tasks.md`.

## Prerequisites

- App built and running on an emulator/device with the local `drift` database freshly migrated (includes `AIConversations`/`AIMessages`/`AISettings`, `research.md` Decision 8).
- At least one other feature has real seeded data to answer questions about — recommended minimum for a meaningful pass: a few `FinanceEntries` across 2+ categories spanning this month and last month (007), one `Person` with a nonzero balance (001), one `Budget` for the current month (010), one `SavingsGoal` with a monthly contribution set (011).
- The `AIService` implementation is swapped, via DI, for a fake/test double that returns scripted `AITurnResult`s (final answers and/or tool-call requests) without making any network call — this is the standard test setup described in `plan.md`'s Project Structure (`integration_test/ai_assistant_flows_test.dart`).

## Scenario 1 — Assistant is off by default (User Story 1, AC1)

1. Launch the app fresh (or with the feature never enabled).
2. Open the AI Assistant entry point.
3. **Expected**: the assistant shows its disabled/setup state; no AI-related network call has occurred (assert on the fake `AIService`'s call count = 0).

## Scenario 2 — Enable requires both key and consent (User Story 1, AC2-3)

1. Open AI Assistant setup.
2. Enter a provider and a non-empty API key, but do not accept the consent disclosure.
3. **Expected**: the assistant remains unusable; attempting to ask a question is blocked or the entry point stays in the setup state.
4. Now accept the consent disclosure.
5. **Expected**: the assistant becomes available; `AIAssistantSettings.isEnabled = true`, `consentAcceptedAt` is set (data-model.md validation rule).

## Scenario 3 — Grounded answer to a category-spend question (User Story 2, AC1)

1. With the assistant enabled and seeded food-category expenses for this month, ask "How much did I spend on food this month?" (try once in English, once in Arabic in a fresh conversation).
2. Script the fake `AIService` to request the `getCategorySpend` tool, then return a final answer narrating the result it's handed back.
3. **Expected**: the number in the assistant's answer exactly equals the amount `GetCategoryBreakdown` (007) returns for the food category this month — compare directly against the Finance feature's own category breakdown screen/use-case result for the same data (spec SC-002).

## Scenario 4 — Who-owes-whom question (User Story 2, AC4)

1. With a seeded `Person` whose balance is nonzero, ask "Who still owes me money?"
2. Script the fake `AIService` to call `getOwedOverview`.
3. **Expected**: the named person(s) and amount(s) in the answer match `GetOverview`'s own returned list exactly.

## Scenario 5 — Honest decline: no savings goal exists (User Story 3, AC1)

1. On an account/conversation with zero `SavingsGoal` rows, ask "How long until I reach my savings goal?"
2. Script the fake `AIService` to call `getSavingsGoalStatus`, which returns `foundData = false`.
3. **Expected**: the assistant's answer clearly states it has no savings goal on record — no target amount, current amount, or timeline appears anywhere in the response (spec SC-003: zero fabricated figures).

## Scenario 6 — Honest decline: out-of-scope request (User Story 3, AC3/AC5)

1. Ask the assistant to "add a 500 EGP expense for me" and, separately, "what stock should I invest in?"
2. **Expected**: both are declined with a clear explanation (no record is created; no personalized investment recommendation is given) — assert no write-capable use case is ever invoked (there is none reachable from this feature by construction, `plan.md` Constitution Check Principle IX row).

## Scenario 7 — Clear conversation (User Story 4, AC2)

1. With an existing multi-message conversation, choose to clear it.
2. Confirm the irreversible-action prompt.
3. **Expected**: `getMessages` returns an empty list immediately afterward; asking a new question afterward still works correctly on its own merits (Scenario 3-style check again, unaffected by the clear).

## Scenario 8 — Disable stops all further calls, including one in flight (User Story 5, AC1-2)

1. Enable the assistant and begin asking a question (a request is "in flight" — the fake `AIService` call has been made but not yet resolved, or is scripted with an artificial delay).
2. While it is in flight, disable the assistant.
3. **Expected**: no further calls to the fake `AIService` occur after the disable action; the in-flight question is shown as interrupted/failed rather than silently completing; every other feature (People, Finance, Budgets, Savings) remains fully usable throughout.

## Scenario 9 — Each typed failure state (User Story 6, AC1-5)

Run once per case, scripting the fake `AIService` to return the corresponding outcome:

| Case | Fake AIService behavior | Expected UI |
|---|---|---|
| Offline | simulate no connectivity before the call is even attempted | distinct "needs an internet connection" message |
| Invalid/revoked key | return `InvalidApiKeyFailure` | message explaining the key isn't working + path to update it |
| Rate limited | return `RateLimitFailure` | "too many requests, try again shortly" |
| Provider error | return `AIProviderFailure` | "the AI provider is having a problem" + retry |
| Unrecognized response | return `UnrecognizedAIResponseFailure` | generic "something went wrong understanding the response" |

**Expected for every row**: the user's own question remains visible, marked failed, retryable without retyping (FR-018); no raw exception/stack trace/provider string ever appears (spec SC-006).

## Scenario 10 — Arabic/English parity (User Story 2, AC8 / spec SC-007)

1. Ask the same underlying question ("How much did I spend on food this month?" / "أنا صرفت كام على الأكل الشهر ده؟") in both languages in two fresh conversations (or after clearing between them).
2. **Expected**: both answers state the identical `amountMinorUnits`-derived figure; response language matches the question's language (research.md-adjacent Assumption).

## Scenario 11 — RTL/LTR and theme check (spec SC-008)

1. With an existing conversation containing both user and assistant messages, switch the app language between Arabic and English, and switch between light/dark mode.
2. **Expected**: message-bubble alignment follows reading direction correctly in both languages; no layout, alignment, or truncation defects in either theme.

---

Passing all eleven scenarios is the acceptance bar for this feature per `spec.md`'s Success Criteria — `tasks.md` (Phase 2) breaks each into concrete unit/Cubit/widget/integration tasks.

## Verification results (2026-09-24)

Recorded for tasks.md T082/T083. No live provider and no real keychain were used anywhere.

**Scenarios 1-9 — automated, passing.** `integration_test/ai_assistant_flows_test.dart` (14 tests) ran on the macOS desktop target (`fvm flutter test integration_test/ai_assistant_flows_test.dart -d macos`): real DI, real on-device SQLite and real tools/use cases, with `AIService` swapped for a scripted fake and `SecureCredentialStore` for an in-memory one. Scenario 3 runs once in English and once in Arabic; Scenario 9 runs once per failure case. Scenario 5's savings step is **skipped** because feature 011 (Savings) is not built and `getSavingsGoalStatus` does not exist. The same honest-decline guarantee is checked with `getPersonBalance` for a person who does not exist (`foundData: false`, no figures in the reply). Running the suite also found and fixed a real bug: `ChatPage` read `Localizations` inside `BlocProvider.create`, so the routed chat page threw on open. The widget tests had missed it because they pump `ChatView` directly; `test/widget/ai_chat_page_test.dart` now has a regression test.

**Scenario 10 — Arabic/English parity.**
- Verified automatically:
  - Every one of the 88 `ai*` localization keys exists and is non-empty in both `app_en.arb` and `app_ar.arb`, with matching placeholders (`test/features/ai_assistant/presentation/l10n_parity_test.dart`).
  - The same scripted category-spend question gives the identical `amountMinorUnits`-derived figure in both languages, equal to `GetCategoryBreakdown` (integration Scenario 3, en + ar).
  - The system prompt tells the model to reply in the question's language (`system_prompt_builder_test.dart`).
- **Needs manual testing on a device with a real API key:** whether a real model actually replies in the question's language, and gives the same figure for both phrasings. A scripted fake cannot show this.

**Scenario 11 — RTL/LTR and theme.**
- Verified automatically by widget tests:
  - Chat bubbles follow reading direction: `ai_chat_widgets_test.dart`, `ai_chat_page_test.dart`.
  - An Arabic conversation containing a failure banner renders mirrored with no layout exceptions in both light and dark themes (`ai_chat_page_test.dart`).
  - The settings page in Arabic renders its setup form, custom-provider fields (kept LTR) and enabled summary without overflow in both themes (`ai_settings_page_test.dart`).
  - Every failure-banner variant renders in both languages and both themes (`ai_chat_widgets_test.dart`).
  - No hardcoded colors are used in the feature; only `ColorScheme`/`financeColors` tokens.
- **Needs manual testing on a device:** switching language and theme *live* while a real conversation is open, and a visual check for truncation with long, real model answers on small phones.
