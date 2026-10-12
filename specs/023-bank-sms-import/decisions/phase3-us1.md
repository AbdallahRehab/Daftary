# Phase 3 (US1) decisions: review and confirm

Written by the orchestrator from the Phase 3 agent's report. The tail of Phase 3 (T084 tile tests, T085, T086) was finished by a parallel session in the same working tree. Verified by the orchestrator on 2026-10-11: `fvm flutter analyze` clean; full `fvm flutter test` 5060 passed, 1 skipped, 0 failed.

| Topic | Choice | Why |
|---|---|---|
| Ignore on the review page | Not added in US1. Ignore and close actions arrive with later stories. | US1 scope is review, edit, Add. Fewer actions means fewer write paths to verify. |
| Probable duplicate at Add | `showAppConfirmDialog` until the US5 `ProbableDuplicateSheet` exists (T101/T102 replace it). | Never block silently; ask the user explicitly. |
| Duplicate tiers that block | Only `probable` returns `ProbableDuplicateFailure` at Add; the other tiers are informational. | FR-059b: duplicate checks never block on their own. |
| Bank shown on the card and review page | The bank id, not a display name. | Bank display names come with the US2 profile work. |
| Empty state | Explanation only, with no scan or paste actions. | Scan (US2) and paste (US4) don't exist yet; those phases add the actions. |
| `ReparsePending` | Not wired in US1. | Not needed for the review flow; reparse comes with the parser-version work. |
| Person check in confirm | Checks that the person exists, not whether they are archived. | Mirrors what the manual add path checks; doesn't change existing behaviour. |
| Add button | Not sticky; sits at the end of the form. | Matches the existing form pages. |
| Confirm failures | Every inner `Left` aborts the db transaction (`_ConfirmAborted`) and maps to a fixed, content-free failure. | Briefing rule: SQLite errors can contain bound parameters (SMS data). |
| Idempotency | `sms-import:<pendingId>` key; `import_source = 'sms'`; `source` stays `manual`. | Re-tapping Add can't create two records, and existing source semantics are unchanged. |
