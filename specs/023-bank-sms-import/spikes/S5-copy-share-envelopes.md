# Spike S5: copy and share envelope formats (T163)

**Status: NOT RUN — device required.** Capturing real copy/share output needs Google Messages and Samsung Messages on Android devices and Messages on an iPhone. Nothing below was observed. T163 stays unchecked.

**Every format in this file is a best-known assumption, labeled UNVERIFIED.** No real message content is used. Placeholders: `<SENDER>` (sender ID or contact name), `<DATE>` (localized date, possibly with weekday or month name, Western or Arabic-Indic digits), `<TIME>` (12 h with AM/PM or ص/م, or 24 h), `<BODY>` (the message text exactly as stored in the inbox), `⏎` (line break), `⏎⏎` (blank line).

## Question

When a user copies or shares one message, or several messages (multi-select), from Google Messages, Samsung Messages and iOS Messages, what text does Daftary receive? Specifically: sender lines, date/time headers, bracketed prefixes, separators, line breaks; and is a single-message copy byte-identical to the inbox body?

## Default approach (already designated; adopted as the primary choice for T046/T047)

Source: contracts/parser-contract.md §3 (splitter step 0), spec FR-017a, research.md Decision 5 (iOS: paste only, `Clipboard.getData` on tap, system edit-menu paste in the text field) and Decision 4 (Android share: `ACTION_SEND text/plain`, `EXTRA_TEXT`).

`SmsMessageSplitter` step (0) strips envelope lines using the versioned app-level table `data/parsing/sms_envelope_rules.dart` before splitting and before fingerprinting, so a pasted or shared message fingerprints like the inbox copy. The rule classes below (E0-E5) are what that table should contain until S5 runs on devices.

## Envelope table (UNVERIFIED)

| App | Mode | Expected text received by Daftary (UNVERIFIED) | Rule classes needed | Single body byte-identical to inbox? |
|---|---|---|---|---|
| Google Messages | Copy, one message (long-press → Copy text) | `<BODY>` | E0 | Expected yes, modulo line endings and bidi/zero-width marks (absorbed by FingerprintNormalizer steps 1-2) |
| Google Messages | Share, one message (long-press → Share) | `<BODY>` as `EXTRA_TEXT` | E0 | Expected yes, same caveat |
| Google Messages | Copy or share, several messages (multi-select) | Either not offered, or bodies joined: `<BODY>⏎⏎<BODY>` or `<BODY>⏎<BODY>`; a variant may add a `<SENDER>` and/or `<DATE> <TIME>` header line per message | E0, E1, E2, E3 | n/a (multi) |
| Samsung Messages | Copy, one message (long-press → Copy text) | `<BODY>` | E0 | Expected yes, same caveat |
| Samsung Messages | Share, one message (long-press → Share) | `<BODY>` as `EXTRA_TEXT` | E0 | Expected yes, same caveat |
| Samsung Messages | Copy or share, several messages (multi-select) | Per message a header then the body, e.g. `<SENDER>⏎<DATE> <TIME>⏎<BODY>⏎⏎…`, or a bracketed prefix `[<DATE> <TIME>] <SENDER>: <BODY>`, possibly with separator lines between messages | E0, E1, E2, E3, E4, E5 | n/a (multi) |
| iOS Messages | Copy, one message (long-press → Copy) | `<BODY>` | E0 | Expected yes, same caveat |
| iOS Messages | Several messages | No multi-copy in Messages (multi-select is "More…" → Forward into a new compose). The user pastes one message at a time, or several single copies joined by hand with blank lines | E0 | n/a |
| iOS Messages | Share | Not applicable: iOS has no Daftary share extension (NG11, Decision 5). Paste only | — | — |

Notes:
- Android 13+ shows a clipboard preview toast; it does not change the clipboard text.
- Contact names may replace sender IDs in E1/E3 lines when the user saved the bank as a contact.
- `<DATE>`/`<TIME>` follow the device locale: Arabic month names, Arabic-Indic digits, ص/م, "Today"/"Yesterday" (اليوم/أمس) are all possible.

## Rule classes for `sms_envelope_rules.dart`

| Rule | Shape (applied to a shadow copy of the line with bidi/zero-width marks removed and digits normalized; the kept text is the original) | Where it applies | Action |
|---|---|---|---|
| E0 | Line endings `\r\n` and `\r` → `\n`; leading/trailing blank lines dropped | Whole input | Normalize (already splitter-only step 2 in §3) |
| E1 | Line that is only a sender: a registered profile sender ID (case-insensitive) or a short-code / phone-number shape, optionally followed by `:` | First non-blank line of a chunk, and only if a body line follows | Remove line |
| E2 | Line that is only a date and/or time stamp: numeric dates (`D/M/YYYY`, `D-M-YYYY`, `YYYY-MM-DD`, 2- or 4-digit year), month-name dates (English and Arabic, Egyptian and Levantine), optional weekday, `Today`/`Yesterday`/`اليوم`/`أمس`, times `H:MM`, `HH:MM[:SS]` with optional `AM`/`PM`/`ص`/`م`; joined by space, comma or `،` | Header position only: the first one or two non-blank lines of a chunk | Remove line |
| E3 | E1 and E2 on the same line in either order, joined by space, comma, `،`, `-` or `·` | Header position only | Remove line |
| E4 | Bracketed prefix `[<E2 stamp>] <SENDER>:` or `[<SENDER>] ` at the start of a line | Start of a chunk (and start of each message inside a chunk, see below) | Remove the prefix, keep the rest of the line as body |
| E5 | Separator line made only of 3 or more of `-` `—` `–` `_` `=` `*` `•` `~` (spaces allowed) | Anywhere | Treat as a blank line (message boundary) and remove |

Safety rules (conservative reading, to avoid stripping real body text):
1. E1-E3 apply **only in header position**. A date-only or sender-only line inside or at the end of a message body is kept, because some bank templates put the date on its own line; stripping it would lose the date and break the cross-path fingerprint.
2. A line is never stripped if it contains a currency token or matches any profile `signature` / `messageStart`.
3. A header line (E2/E3/E4 shape) inside a chunk is used as a message boundary only when the chunk's first line had the same header shape (a recurring per-message header, as in the assumed Samsung multi-select format). Otherwise it is body text.
4. Under-stripping is the safe failure: an unknown envelope leaves extra text, which can only lower confidence or miss a fingerprint match; duplicate tiers 2-3 (reference hash, probable match) still catch the duplicate. Over-stripping could silently drop body text, so unrecognized shapes are left alone.
5. The table is versioned (`envelopeRulesVersion`); changing it never changes stored fingerprints of already-staged items (hashes are immutable on the row).

## Fallback

If device capture shows formats outside E0-E5, add a rule class for that exact shape (versioned) with a re-authored synthetic fixture in `test/fixtures/sms/_paste/envelopes/`. If a single-message copy turns out not to be byte-identical to the inbox body in a way FingerprintNormalizer v1 does not absorb, record it; cross-path dedup then relies on tiers 2-3 for that app, and FingerprintNormalizer is **not** changed (that would need `fp2|`, out of v1 scope).

## What must be verified on a device

For each app (Google Messages, Samsung Messages on Android 13-16; iOS Messages on iOS 17+), in English and Arabic system language, 12 h and 24 h time:

| # | Check | Record |
|---|---|---|
| 1 | Copy one message; paste into a hex/escape viewer | Exact characters incl. line endings and any U+200E/U+200F/U+061C/U+2066-2069 marks; byte-identical to the provider `body`? |
| 2 | Share one message to Daftary (Android) | Exact `EXTRA_TEXT`; same comparison |
| 3 | Multi-select 2 and 3 messages; Copy (if offered) | Header lines, their order, date/time format, separators, blank lines between messages |
| 4 | Multi-select 2 and 3 messages; Share (if offered) | Same as 3; also whether `EXTRA_SUBJECT` or other extras are set |
| 5 | Same sender saved as a contact | Whether the name replaces the sender ID in headers |
| 6 | Messages from different days in one multi-select | Whether a date header appears once per day or once per message |

Re-author every captured shape as synthetic fixtures (placeholder bodies modeled on the synthetic bank profiles; no real card numbers, phone numbers or names).

## Result

Not available. Until a device run, T046/T047 implement E0-E5 with the safety rules above, and fixtures under `_paste/envelopes/` carry `synthetic: true` and an `unverifiedFormat: true` note.
