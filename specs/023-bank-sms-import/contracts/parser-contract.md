# Contract: SMS Parser

**Feature**: 023 Bank SMS Import · **Research**: Decisions 7, 8, 14 · **Requirements**: FR-020, FR-021, FR-024, FR-024a, FR-027..FR-042, FR-051..FR-056, FR-091, FR-097, FR-098; SC-001; Testing Strategy (golden corpus)

The parser is **pure Dart**, deterministic and synchronous: no Flutter, no `dart:io`, no network, no randomness, no wall-clock (time comes from the injected `AppClock`), no AI (NG4, FR-027, FR-081). It lives in `lib/features/sms_import/data/parsing/` behind the domain interface `SmsMessageParser`, exactly like `CandidateEntryParser` is exercised from a fixture table. The same code parses scan, catch-up, paste and share text (FR-021).

## 1. Interfaces

```dart
/// Domain port (lib/features/sms_import/domain/services/sms_message_parser.dart).
abstract class SmsMessageParser {
  /// Never throws. Any internal exception becomes
  /// Unreadable(UnreadableReason.parserError) (FR-098).
  ParseResult parse(SmsParseInput input);

  /// Rule versions currently shipped: {profileId: version}.
  Map<String, int> get currentVersions;

  /// Allow-list handed to the inbox query: union of profile senders,
  /// canonical upper-case, no spaces (FR-020).
  Set<String> get allowedSenders;
}

class SmsParseInput extends Equatable {
  final String rawText;        // as received; never persisted by the parser
  final String? sender;        // null for paste/share
  final DateTime? receivedAt;  // null for paste/share
  final SmsSource source;
  // `now` and locale-independent settings come from the injected AppClock
  // and ParserOptions (countCashWithdrawals, learned mappings, people names).
}

class ParserOptions {
  final bool countCashWithdrawals;                 // FR-051b
  final Map<(String merchantKey, String type), String> learnedCategoryIds;
  final Set<String> activeCategoryKeysByType;      // resolves seed keys -> ids
  final List<PersonNameRef> peopleNames;           // existing-name match only (FR-054)
}
```

`ParseMessages` (use case) is the only caller; it normalizes once, calls `SmsMessageParser.parse`, then computes hashes and masks (section 3) so the parser never sees keys or storage.

## 2. BankProfile rule-set structure

One Dart const object per bank in `data/parsing/profiles/<bank>_profile.dart`, registered in `SmsParserRegistry` as an **ordered const list** (order is the final tie-break), plus `generic_profile.dart`. Regexes are compiled once (`static final`). Not JSON assets (research Decision 8).

```dart
class BankProfile {
  final String id;                    // 'nbe' | 'banque_misr' | 'cib' | 'qnb' | 'banque_du_caire' | 'aaib' | 'instapay' | 'generic'
  final int version;                  // bumped on any rule change; corpus test pins it
  String get ruleVersion => '$id@$version';

  final Set<String> senders;          // canonical sender IDs; empty only for generic
  final List<ContentSignature> signatures;   // content must match >= 1 to select this profile
  final List<SmsTemplate> templates;         // transaction templates, ordered
  final List<NonTransactionalRule> nonTransactionalRules; // profile-specific OTP/promo/decline/etc.
  final List<MerchantKeywordRule> merchantKeywordRules;   // keyword -> seeded category key
  final List<KeywordSet> ownAccountKeywords;       // FR-051c explicit only
  final List<KeywordSet> cardSettlementKeywords;   // credit-card payment, installment, conversion, loan
  final RegExp? messageStart;         // optional: line prefix that begins a new message (paste splitter)
  final int maskThreshold;            // default 12; may only be lowered, never raised (research Decision 7)
  final String? defaultCurrency;      // 'EGP' for Egyptian banks; null for generic
  final DateOrder dateOrder;          // dayMonth (all v1 profiles) | monthDay
  final bool isGeneric;               // caps every field at Medium; never High (FR-041)
  final bool refIsUnique;             // true only when the bank's reference IDs are unique per transaction (verified on the corpus);
                                      // false -> duplicate tier 2 also requires a date within one day (FR-059b). Generic: false
}

class ContentSignature {
  final RegExp pattern;               // matched on the FOLDED text (section 3, step 4)
  final SmsLanguage language;         // ar | en | any (informational; matching is per message)
}

class SmsTemplate {
  final String name;                  // stable id for tests, e.g. 'purchase_en_1'
  final SmsKind kind;
  final SmsDirection direction;       // debit | credit (fixed by the template)
  final SmsLanguage language;
  final RegExp pattern;               // named groups, all optional except `amount`:
                                      //  amount, currency, date, time, merchant,
                                      //  counterparty, last4, ref, balance, fee,
                                      //  foreignAmount, foreignCurrency
  final bool anchored;                // true: `amount` is adjacent to the debit/credit/purchase verb
}

class NonTransactionalRule {
  final NonTransactionalReason reason;  // otp | promotion | balanceInquiry | declined | pendingAuthorization
  final RegExp pattern;
}
```

Rules for rule authors (enforced by tests):

1. **Per-field patterns for Arabic and English**: every supported bank has at least one Arabic and one English template per kind it supports; a profile may match an Arabic, English or mixed body regardless of the app locale (FR-091). A template contains no locale-dependent construct.
2. No nested quantifiers or unbounded alternation over `.*`; every pattern is run in a **backtracking guard test** against a 10,000-character adversarial string and must finish in under 50 ms.
3. `amount` is the amount adjacent to the debit/credit/purchase verb (`anchored = true`). The `balance` group is read only to be excluded and is never stored (FR-030, FR-031). `fee` is parsed as a separate amount and becomes its own pending item at ingestion (FR-030a).
4. The profile `senders` set is the per-bank allow-list; the union minus mutes goes to the inbox query (FR-020).
5. A rule change without a `version` bump fails `parser_versions_pinned_test` (it compares `currentVersions` with `test/fixtures/sms/_versions.json`).

## 3. Normalization pipeline (`SmsTextNormalizer`, pure)

Input: the original text. Outputs: `NormalizedText { String forMatching, String forDisplay }`.

| Step | Operation | Output used by |
|---|---|---|
| 1 | Strip bidi controls (`U+200E`, `U+200F`, `U+061C`, `U+202A-202E`, `U+2066-2069`) and zero-width characters (`U+200B-200D`, `U+FEFF`) | both |
| 2 | Collapse whitespace runs to a single space; trim; normalize line breaks to `\n` for the splitter only | both |
| 3 | Digits: `NumeralParser.toWesternDigits`, **extended to cover Eastern Arabic-Indic `U+06F0-06F9`** (today only `U+0660-0669`, `numeral_parser.dart:8`; FR-034, research Spec feedback 1), keeping the separator mapping `٫` -> `.`, `٬` -> `,` | both (this is `forDisplay`) |
| 4 | Arabic letter folding **for matching only**: strip tatweel `U+0640` and harakat `U+064B-065F`; fold alef forms `أإآٱ` -> `ا`, `ى` -> `ي`, `ة` -> `ه`; `ؤ`/`ئ` conservatively | `forMatching` only |
| 5 | Lower-case Latin letters | `forMatching` only |

- **Fingerprint input** is **not** `forMatching`. It is the output of a separate, frozen `FingerprintNormalizer` v1 (`data/parsing/fingerprint_normalizer.dart`): a fixed copy of steps 1-3 only (bidi and zero-width removal, whitespace collapse, digit normalization), with no letter folding and no lower-casing, hashed as `HMAC(macKey, "fp1|" + text)`. It never imports or calls `SmsTextNormalizer`, so parser, folding or rule changes can never change a fingerprint (FR-023, analysis H1). A golden test pins the fingerprint of every fixture (`test/fixtures/sms/_fingerprints.json`, computed with a fixed test key). Changing `FingerprintNormalizer` requires a new prefix (`fp2|`) and a migration that matches both versions; it is out of scope for v1. Sender and received time are never inputs.
- **Merchant display text** and the **amount capture** come from `forDisplay` (unfolded), so a merchant is shown as the bank wrote it.
- **Masking** (`SmsMasker`) runs on the **original** text, not on `forDisplay`, so "Show original" keeps the message's own characters and direction. Rules: a digit group is a run of ASCII, Arabic-Indic or Eastern Arabic-Indic digits optionally joined by single spaces or hyphens between digit groups; groups of **>= `maskThreshold` (default 12)** digits are replaced by `•` for all but the last four digits, separators kept; commas and periods are not group separators (so `1,234,567.50` is never masked); already-masked tokens (`XXXX1234`, `****1234`, `...1234`) are untouched; Egyptian mobile numbers `(\+?20|0)1[0125]\d{8}` are masked all but the last four (research Spec feedback 9). The mobile regex is **not** run on raw text (it would miss Arabic-Indic digits and `010 1234 5678`): it runs on a digit-normalized shadow copy of the original with an index map back to the original characters, and allows single-space or hyphen separators. Space-joining can merge an amount with a neighbouring number (`EGP 1500 01012345678` becomes one 15-digit group and the amount would be masked), so masker tests cover amount-adjacent runs, and re-parse treats a masked amount as unreadable, never as a different value.
- **Order of operations in `ParseMessages`**: split -> normalize -> classify/parse (unmasked) -> hash (fingerprint, `ref_hash`, `ref_amount_hash` from the unmasked normalized body and reference) -> mask original -> seal -> persist. Hashes are computed **once**, before masking, and never recomputed by re-parse (immutable on the row).

Paste and share splitting (`SmsMessageSplitter`): (0) strip **envelope lines** that messaging apps add when copying or sharing (FR-017a), using the app-level table `data/parsing/sms_envelope_rules.dart` built from the formats captured in spike S5 (Google Messages, Samsung Messages, iOS Messages): a line that is only a sender name and/or a date-time stamp, a bracketed header such as `[12/03/2026 10:15] NBE:` at the start of a chunk (the prefix is removed, the body kept), and separator lines; the table is versioned and tested with re-authored fixtures in `test/fixtures/sms/_paste/envelopes/`, and stripping runs before fingerprinting so a pasted message fingerprints like the inbox copy; (1) reject input over **10,000 characters** (`InputTooLargeFailure(characters)`; nothing is stored, FR-017; the Kotlin bound of 10,001 exists only to detect this); (2) split on runs of blank lines; (3) inside a chunk, split again at every line matching a profile `messageStart` when two or more such lines exist; (4) more than **50** messages -> `InputTooLargeFailure(messages)`. A single message longer than 4,000 characters is `Unreadable(tooLong)` and counted. Empty chunks are dropped silently (not counted).

## 4. `ParseResult`

```dart
sealed class ParseResult extends Equatable {}

class ParsedTransaction extends ParseResult {
  final String bankId;                 // profile id, or 'generic'
  final String parserId;               // == bankId of the winning profile
  final String ruleVersion;            // 'nbe@3'
  final SmsKind kind;
  final SmsDirection direction;        // debit | credit | unknown
  final Money? amount;                 // null only when currency outside catalog or ambiguous candidates (section 5)
  final List<int> amountCandidatesMinor;   // empty unless ambiguous (FR-030)
  final String? currencyCodeRead;      // as read, even if outside catalog (drives FR-053 state)
  final DateTime? occurredOn;          // date-only local; null for paste/share with no date
  final int? timeMinutes;
  final String? merchant;
  final String? merchantKey;           // FR-055 normalization
  final String? counterparty;
  final String? cardLast4;
  final String? referenceId;           // TRANSIENT: only to compute hashes; never persisted or logged
  final String? foreignAmountText;     // FR-053 context, display only
  final Money? fee;                    // in-message fee: ingestion stages it as its own pending fee item (FR-030a); a fee SMS is its own item
  final Money? foreignAmount;          // original-currency amount when stated and parsable; used by the probable-duplicate check (FR-059)
  final SuggestedRecordType suggestedType;
  final String? suggestedCategoryKeyOrId;   // resolved id when active, else null
  final String? suggestedPersonId;
  final ParseConfidence confidence;
  final Set<SmsWarning> warnings;
}

class NonTransactional extends ParseResult {
  final NonTransactionalReason reason;   // otp | promotion | balanceInquiry | declined | pendingAuthorization | other
  final String? bankId;                  // for per-bank counts only
}

class Unreadable extends ParseResult {
  final UnreadableReason reason;         // noAmount | amountUnreadable | tooLong | empty | nonText | parserError
  final String? bankId;
}
```

`ParsedTransaction` never carries the balance, a full account/card number, or an OTP: those are consumed inside the parser and dropped (FR-031, FR-077). `referenceId` is the one transient sensitive value, passed to the hasher in the same call and discarded.

Outcome handling by callers: `ParsedTransaction` -> candidate for a pending item; `NonTransactional` -> counted (`ScanSummary.nonTransactional`), **nothing stored** (FR-024); `Unreadable` -> counted, nothing stored, shown as "could not read, enter manually" for paste/share (FR-039a). Counts only, never content.

## 5. Eligibility classification

Evaluated on `forMatching` in this fixed order; the first hit decides. Profile rules run before the generic rules of the same step.

| Step | Class | Detection (illustrative keywords; the profiles hold the real lists in Arabic and English) | Result |
|---|---|---|---|
| 0 | Empty, whitespace-only, non-text, or > 4,000 characters | length / emptiness | `Unreadable(empty | nonText | tooLong)` |
| 1 | **OTP** | `otp`, `one time`, `verification code`, `do not share`, `رمز`, `كود التحقق`, `لا تشارك` | `NonTransactional(otp)`. **Wins over everything below**: an OTP message is never parsed further (FR-024, edge case) |
| 2 | **Declined / failed authorization** | `declined`, `failed`, `insufficient`, `unsuccessful`, `مرفوض`, `فشل`, `رصيد غير كاف` | `NonTransactional(declined)` |
| 3 | **Pending authorization** | `authorization`, `pre-auth`, `on hold`, `قيد التنفيذ`, `حجز` without a posted verb. Calibrated per bank: a bank whose purchase messages are sent at authorization time matches its own `cardPurchase` template first (profile rules run before generic ones), and its corpus must contain such samples (FR-024b) | `NonTransactional(pendingAuthorization)` |
| 4 | **Authorization reversal / cancellation** of money that never posted | `authorization reversed`, `hold released`, `إلغاء الحجز` | `ParsedTransaction(kind: authorizationReversal, direction: credit, suggestedType: ignore, warnings: {reversalHint})` (FR-024b): it becomes a pending item because the user may already have added the purchase |
| 5 | **Promotion** | offer/discount/installment-offer vocabulary with no posted debit/credit verb, or a URL plus marketing words | `NonTransactional(promotion)` |
| 6 | **Balance inquiry** | balance verbs with no debit/credit verb | `NonTransactional(balanceInquiry)` |
| 7 | **Transaction** | first matching `SmsTemplate` of the selected profile | continue to field extraction |
| 8 | Posted-money refund / reversal credit | profile `refund` templates (money that posted and is returned) | `ParsedTransaction(kind: refund, suggestedType: ignore, warnings: {refundHint})` (FR-024a) |
| 9 | No template matches but an amount-like token exists next to a debit/credit verb | generic templates | `ParsedTransaction` from the generic profile |
| 10 | Nothing amount-like | | `Unreadable(noAmount)` |

When in doubt between step 4 (authorization reversal) and step 8 (refund), the parser chooses **refund**; both suggest Ignore, so the choice only changes the hint. Steps 1-3, 5 and 6 never produce a pending item.

**Amount extraction rules** (inside a matched template): capture `\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?` from `forDisplay`; strip commas; `CurrencyFormatter(currency: ..., locale: 'en').parse(captured)` yields exact minor units; a `FormatException` (more than 2 decimals, more than 12 whole digits) becomes `Unreadable(amountUnreadable)`, never a clamped value (FR-039a). If two non-fee candidates remain (not balance), `amount = null`, both listed in `amountCandidatesMinor`, amount confidence `Low` (FR-030). Fee candidates are parsed separately (`fee`). An in-message fee is staged by `SmsIngestionService` as a second pending item (`kind: fee`, direction debit, `suggestedType: expense`, warning `feeFromMessage`, `parent_import_id` = the transaction's pending id) with fingerprint `HMAC(macKey, "fp1|fee|" + fingerprintInput)` and no reference hashes; it is never added to the transaction amount (FR-030a). A following **fee SMS is its own item** even when it shares the withdrawal's reference ID (FR-059b).

**Currency**: const table maps `EGP`, `LE`, `L.E.`, `ج.م`, `جنيه`, `USD`, `$`, ... to ISO codes. Resolution: stated + in catalog (EGP, USD, EUR, SAR, AED, GBP) -> read; stated + outside the catalog -> `amount = null`, `currencyCodeRead` set, `unsupportedCurrency` warning (FR-053: user chooses a catalog currency and re-enters; the number is never reinterpreted); not stated -> profile `defaultCurrency` as **inferred** (`currencyInferred`), generic/paste/share leaves it empty (required). Foreign purchase on a local card: the billed account-currency amount is `amount`; the original goes to `foreignAmountText` (read-only context, not stored on the saved record) and, when its currency is in the catalog, to `foreignAmount`, which the probable-duplicate check also compares against saved records (FR-059).

**Dates**: regex plus manual `DateTime(y, m, d)` with a round-trip validity check (the `SyncWire.parseLocalDay` idiom); no `intl` parsing. Month names: const normalized tables, English (full and 3-letter) and Arabic Egyptian and Levantine spellings, keyed after alef folding. Two-digit year -> `2000 + yy`. Year-less date: year of `receivedAt` minus one if that date would be after it; paste/share use the current year from `AppClock`, minus one if that date would be after today; always `FieldConfidence.inferred()` (FR-036). Order is the profile's `dateOrder` (generic: day-month). No date stated: `receivedAt`'s local calendar day, inferred (scan, catch-up); paste/share: `occurredOn = null` (FR-038). 12-hour and 24-hour times parse to `timeMinutes`.

## 6. Confidence calculation

Reuses the OCR model, **promoted** to `lib/core/confidence/` (data-model.md 2.6): a field is `read(level)` or `inferred()`; inferred always has level `none`.

**Per-field level** (for a field read from text):

| Condition | Level |
|---|---|
| Captured by an `anchored` template of a bank profile, single unambiguous candidate | `high` |
| Captured by a bank profile template with `anchored = false`, or a secondary pattern of the same profile | `medium` |
| Two non-fee amount candidates remain; or the value passed a plausibility check only weakly (for example last-four with no `card` keyword) | `low` |
| Any field from the generic profile | at most `medium` (clamped) |

Fields that are **inferred** (value derived or defaulted): date from `receivedAt` or year inferred; currency from the bank default; direction implied only by a fallback keyword; suggested category and person (never "read").

**Overall** — pure function `overallConfidence(Map<SmsField, FieldConfidence> fields, {required bool isGeneric, required SmsSource source})` in `sms_import/domain`:

```
required = { amount, currency, direction, date }
if any required field is absent or unset   -> low              // contract decision D-C1 (see note)
reads    = levels of required fields with kind == read
overall  = min(reads)                                          // low < medium < high
if any required field is inferred          -> overall = min(overall, medium)   // FR-039
if isGeneric or source in {paste, share}   -> overall = min(overall, medium)   // FR-039, FR-041, FR-020
```

- Confidence never changes a decision: it affects presentation and ordering only (low first), never blocks Add by itself, never auto-adds (FR-042). Generic parser items are never `high` (FR-041).
- **D-C1**: a missing required field yields `low` overall (now stated in spec FR-039: "If any required field is absent, overall confidence is Low"); it only affects ordering and the label, since Add is already disabled for an incomplete item (FR-043a). A paste/share without a date or currency is therefore always Low, which is intended. Confidence calibration tests assert it.
- Display strings are derived from the level (Low / Medium / High) with icon and label, inferred fields get the distinct "Inferred, not read" treatment (FR-040); never a percentage.

Persisted as `confidence_json` (`{"overall":"medium","fields":{"amount":"read:high","date":"inferred"}}`).

## 7. Multi-parser precedence (`selectParse(input)`)

Pure function over the registry (FR-028):

1. Candidates = profiles whose `senders` contain the normalized sender **and** whose `signatures` match the content.
2. If the input has **no sender** (paste/share): candidates = profiles whose `signatures` match (content-only).
3. If there are no candidates: the **generic** profile. A recognized sender whose content matches no signature also falls here, so spoofed or look-alike senders land at lower confidence (edge case; FR-020).
4. Several candidates: parse with each, pick the highest **overall** confidence; ties resolve by registry order. **No field-level merging** between profiles.
5. A profile that matched but whose template pass found no amount does not win over a candidate with an amount; if none has an amount the result is `Unreadable(noAmount)` (the generic profile gets a last try only if it was not already the candidate).

Corpus invariant (test): for every pair of supported banks, no sample of A matches a signature of B (`_cross/`), and a bank sample with a spoofed look-alike sender falls to generic.

## 8. Mapping to suggested record type and category

Pure function `suggestFor(kind, direction, source, ParserOptions, merchantKey, counterparty)`. Suggestions only; the user decides in review (FR-051). It never creates a new transaction, refund, transfer or debt type, a category, or a person.

| `SmsKind` | `suggestedType` | Category suggestion | Warnings / notes |
|---|---|---|---|
| `cardPurchase` | `expense` | learned mapping, then merchant keyword rule, else seed `other` | |
| `atmWithdrawal` | `ignore`; `expense` (with seed `other`) when `countCashWithdrawals` is on | `other` when expense | `atmIgnoredByDefault` (UI shows one-line link to the preference, FR-051b) |
| `cardOrLoanSettlement` | `ignore` | none | `cardSettlementSuggestedIgnore`; the "N of M" installment text is not stored |
| `billPayment` | `expense` | keyword -> seed electricity / water / phone / internet, else `other` | |
| `fee` | `expense` | learned mapping, else `other` (no new category) | `feeSeparateItem` for a fee SMS; `feeFromMessage` for a fee split from its parent message (FR-030a) |
| `salary` | `income` | seed `salary` | |
| `otherDeposit` | `unset` (user chooses Income or Ignore) | none until chosen | |
| `transferOut` (named counterparty) | `expense`; `given` only when the counterparty name matches an existing person (one tap, person pre-selected) | learned, else `other` | `suggestedPersonId` set only on exact existing-name match; multiple matches -> no person, review shows the existing similar-name choice (FR-054) |
| `transferIn` | `income`; `received` only on a person-name match | seed `other_income` | |
| `refund` | `ignore` | none | `refundHint` (FR-024a); Income only if the user explicitly switches |
| `authorizationReversal` | `ignore` | none | `reversalHint` (FR-024b); review shows a matching saved record side by side with "Open it"; Income only if the user explicitly switches |
| `ownAccountTransfer` | `ignore` | none | `ownAccountSuggestedIgnore`; detected **only** from explicit keywords (`own account`, `between your accounts`, `savings`, `card payment`, ...; FR-051c), otherwise a named transfer |
| `unknown` with direction `unknown` | `unset` | none | FR-033 |
| `unknown` debit | `expense` | learned, else `other` | confidence capped by generic rules |

Category resolution order (FR-055): (a) `learnedCategoryIds[(merchantKey, type)]`, (b) `MerchantKeywordRule` for the profile and the shared Arabic/English keyword table, (c) the seed key (`other`, `other_income`, `salary`). Seeds are resolved **by stable key** (`finance_category_seed.dart`: `groceries, restaurants, electricity, water, phone, internet, family, other, salary, other_income, ...`) to the user's current category id; an archived or missing category is **never suggested** and falls to the next step; if no active category of the required type exists, no category is suggested and Add stays disabled until the user chooses (FR-055). `merchantKey` = merchant text after FR-037 folding, lower-cased, digits and punctuation removed, whitespace collapsed; matching is exact.

Person matching: existing `Person.normalizedName` style matching only (name-based, no phone matching); never creates a person (FR-054).

`suggestFor` never sets `possibleOwnTransfer`: that warning comes from `CheckDuplicates` (FR-051d), because it needs other pending items and saved records.

## 9. Corpus fixtures and anonymization

Location: `test/fixtures/sms/<bankId>/<case>.txt` + `<case>.json`; folders `_noise/` (OTP, promo, decline, balance, pending authorization, authorization reversal), `_paste/` (multi-message and bounds), `_cross/` (cross-bank non-match), `_hostile/` (huge, binary-ish, bidi-heavy, regex-adversarial), plus `_versions.json` (`{"nbe":3,...}`).

- `<case>.txt`: the synthetic message **exactly as received**, UTF-8, no trailing normalization; multi-message paste cases use blank-line separators.
- `<case>.json`:

```json
{
  "synthetic": true,
  "sender": "NBE",
  "receivedAt": "2026-03-04T10:15:00+02:00",
  "source": "scan",
  "classification": "transaction",
  "kind": "card_purchase",
  "amountMinor": 12550,
  "currency": "EGP",
  "direction": "debit",
  "date": "2026-03-04",
  "dateInferred": false,
  "timeMinutes": 615,
  "merchant": "Example Cafe",
  "last4": "1234",
  "refPresent": true,
  "suggestion": { "type": "expense", "categoryKey": "restaurants" },
  "warnings": [],
  "confidence": { "overall": "high", "amount": "read:high", "currency": "read:high", "direction": "read:high", "date": "read:high" }
}
```

  Non-transactional: `{"synthetic": true, "sender": "CIB", "classification": "non_transactional", "reason": "otp"}`. Unreadable: `{"synthetic": true, "classification": "unreadable", "reason": "no_amount"}`. Paste: `"sender": null, "source": "paste"`, and an `"expectedItems": [...]` array for multi-message cases with `"skipped": n`. Every expected key is optional; only present keys are asserted.
- **One loader test** iterates the tree (adding a case adds no code), asserts `synthetic: true` on every file, computes per-bank accuracy and **fails below the SC-001 gate** (>= 95% of amount, currency, direction and date per supported bank; 100% of `_noise/` rejected), asserts the FR-028 cross-bank invariant, and asserts `_versions.json` equals `currentVersions`.
- **Anonymization rules** (enforced by a guard test that fails the build): (1) every number is invented: amounts, balances, dates, times, card last-fours (use `0000`-style or obviously invented fours), reference IDs; (2) no real person, merchant tied to a real customer, or real account; merchants are generic or well-known public brands used generically; (3) no digit run of 16 digits and none that looks like a real Egyptian mobile (`(\+?20|0)1[0125]\d{8}`); for transfers the counterparty is an invented first name and any phone number is written already masked; (4) sender IDs are the banks' **public** alphanumeric sender names, confirmed by OQ2 from the product owner, never a customer's number; (5) no real message is committed, even edited (OQ2: the owner provides anonymized *formats*; the committed text is re-authored).
- Test layers beyond the corpus: normalizer unit tests (digit scripts, bidi, folding), masker tests (separators, Arabic-Indic digits, grouped amounts untouched, mobile rule), amount/date/currency unit tables, calibration tests (generic and paste/share never `high`; lowest-read-field capping; inferred cap; missing-field low), `selectParse` precedence tests, regex backtracking guard, and a never-throws property test over random and hostile strings (FR-098).

## 10. Invariants (tested)

1. `parse` is total and deterministic: same input and options, same output; never throws.
2. Output never contains a balance, an OTP, or more than four digits of a card/account number.
3. An OTP message yields `NonTransactional(otp)` regardless of any other content.
4. Generic parser and paste/share results are never `OverallConfidence.high`.
5. Supported banks' samples never match another bank's signatures.
6. A rule change requires a `version` bump (corpus pin).
7. The parser makes no network, file or platform call (pure-Dart import guard on `data/parsing`).
8. Every fixture's fingerprint equals its pinned value in `_fingerprints.json`, whatever the profile versions (FR-023); `fingerprint_normalizer.dart` imports nothing from the parser.
9. The same message yields the same fingerprint through scan, catch-up, paste and share, including every captured envelope format (FR-017a).
10. A message with an in-message fee stages exactly two pending items; the transaction amount never includes the fee (FR-030a).
