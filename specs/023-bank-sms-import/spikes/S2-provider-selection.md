# Spike S2: SMS provider selection grammar (T011)

**Status: NOT RUN — device required.** No emulator or device is available in this environment. Nothing below was observed. T011 stays unchecked.

## Question

Does the Android SMS content provider (`Telephony.Sms.Inbox.CONTENT_URI`) accept a selection with `UPPER(address) IN (?,...)` on API 26-36 and on real OEM providers, so the sender filter runs inside the query and no non-bank body is ever read (FR-020)?

## Default approach (already designated; adopted as the primary choice for T106)

Source: research.md Decision 1, contracts/sms-platform-channel.md §2.4.

- Projection: `_id, address, date, body`.
- Selection: `UPPER(address) IN (?,?,...) AND (date > ? OR (date = ? AND _id > ?))`, with every value passed as a bind argument (never concatenated).
- Sort: `date ASC, _id ASC`. Read at most `limit` (<= 200) rows from the cursor; no SQL `LIMIT` and no `sortOrder` hack (minSdk 24).
- `senders` arrive from Dart already canonical upper-case with no spaces (allow-list minus muted), 1..200 entries of 1..32 characters; an empty list is `invalid_args`.
- Bodies are truncated in Kotlin at 4,000 characters with `truncated: true`.

## Fallback ladder (pre-decided, in order)

1. `address COLLATE NOCASE IN (?,?,...)`
2. `address LIKE ?` per sender, OR-joined (case-insensitive for ASCII in SQLite; bind values must escape `%` and `_`).
3. Two-phase read: query `_id, address` (no body) for the time window, filter in Kotlin against the allow-list, then read bodies by `_id IN (...)`. This never reads a non-bank body but does read non-bank metadata, so taking it **requires amending contracts/sms-platform-channel.md §2.4 and the FR-020 wording in the same change** (contract §2.4).

On first selection failure in production, Kotlin must surface `query_failed` with no content; it must not silently fall through to a less strict query at runtime. The rung is chosen at build time from this spike.

## What must be verified on a device

| # | Check | Expected |
|---|---|---|
| 1 | Query with `UPPER(address) IN (...)` on API 26, 28, 30, 33, 34, 35, 36 emulators | Returns only allow-listed rows; no `IllegalArgumentException` / `SQLiteException` |
| 2 | Same on one real device with an OEM SMS provider (Samsung and/or an Egyptian-market OEM) | Same; note whether the OEM uses a non-AOSP provider |
| 3 | Mixed-case sender IDs stored by the provider (e.g. `Bank` vs `BANK`) | Matched by the upper-cased bind values |
| 4 | Keyset paging across equal `date` values | No row skipped or repeated across pages |
| 5 | Large inbox (several thousand rows, ~200 allow-listed) | Page time acceptable for SC-005; record timings |
| 6 | If rung 0 fails: repeat 1-4 for each fallback rung in order | First rung that passes is the one T106 uses |

Record the device list, API levels and the rung chosen.

## Result

Not available. Until a device run, T106 implements rung 0 (`UPPER(address) IN (...)`) as designated.
