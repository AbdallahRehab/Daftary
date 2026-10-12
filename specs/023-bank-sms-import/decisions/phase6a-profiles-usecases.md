# Decisions: Phase 6a — scan use cases (T108, T109) and bank profiles (T110-T117)

Slice: Lane B (Dart use cases against fakes) and Lane C (bank profiles, then registration). I did not own codegen, and I did not run build_runner. **Codegen is pending.** The new use cases carry `@injectable`, but `injection.config.dart` does not register them yet. `GetSmsCapability` already existed (the Phase 4 agent added it), so I reused it rather than adding a second one. No Android or iOS build was run. I did not touch `main.dart`, `android/**`, ARB/l10n, the router, routes, pages, dashboard widgets or `sms_platform_module.dart`.

## Results (observed)

| Task | Status | Evidence |
|---|---|---|
| T108 | [X] | `run_inbox_scan_test.dart` 21, `enable_sms_import_test.dart` 7, `request_sms_permission_test.dart` 5, `sms_settings_usecases_test.dart` 6: all pass. **Not strictly test-first**: the use cases were written just before their tests. To make up for that, I mutation-checked the tests. Removing the lifecycle check failed 2 tests, and removing the defensive sender re-check failed 1. |
| T109 | [X] | `GetSmsPermissionStatus`, `RequestSmsPermission`, `OpenSmsAppInfo`, `EnableSmsImport`, `UpdateSmsImportPreferences`, `GetScanCounts`, `RunInboxScan`. `GetSmsCapability` was reused. Tested with fakes only, with no DI. |
| T110-T116 | [X] | Seven profiles. Each passes its gate test (9 tests per profile, 63 total). |
| T117 | [X] | All seven are registered in `SmsParserRegistry.standard`. `_versions.json` pins them. `corpus_test.dart` and the new `sms_parser_registry_test.dart` are green. |

- `fvm dart format` was run on every touched file.
- `fvm flutter analyze`: **No issues found** (whole project).
- `fvm flutter test test/features/sms_import`: **1298 passed, 0 failed**.
- `test/features/sms_import/data/parsing`: 495 passed.

## Bank profiles

| # | Topic | Choice | Why |
|---|---|---|---|
| 1 | No real samples (OQ2/OQ3) | All 7 profiles are built from SYNTHETIC fixtures modeled on generic public phrasing, with `verified: false`. That caps every result at Medium and adds `unverified_profile`. Every fixture has `"synthetic": true` and contains no 16-digit runs and no mobile numbers. | Orchestrator decision. Flipping a profile to `verified: true` needs owner samples. |
| 2 | Template authoring | New `profiles/sms_template_kit.dart`. A source is written naturally, folded the same way as message text, then placeholders (`{amount}`, `{currency}`, `{date}`, `{merchant}`, `{last4}`, `{ref}`, `{fee}`, `{end}` …) are expanded into bounded named groups. Upper-case regex escapes are forbidden, because folding would lower-case them. | Keeps each profile readable and keeps the Arabic folding identical to the parser's. |
| 3 | CHK045 inside templates | `{amount}` captures the whole token, malformed tokens included (`100,50`, `1.234,50`), so `SmsAmountReader` rejects it as `amount_unreadable`. A shorter, wrong number is never read. Space grouping (`1 000`) and glued currency (`89.99EGP`, `EGP1,500`) parse. Each bank has a `decimal_comma_unreadable` fixture. | Never a silently wrong amount. |
| 4 | Signatures vs envelope safety rule 2 | A signature matches the bank name as a whole word, followed by an optional `:`/`,`, then a space and a letter. A bare sender line (`NBE`, `NBE:`, `NBE 05/03/2026 10:15`) never matches, so E1 stripping still works. This is tested per profile. | Resolves the 2c #24 note. |
| 5 | InstaPay vs banks | The InstaPay signature must **open** the message (`atStart`), because the other banks and the existing `_paste` fixtures mention InstaPay inside their own text. A bank's own InstaPay transfer is a `transfer_out` template of that bank. | Cross-bank non-match. |
| 6 | Kinds per bank | 6 banks: purchase, ATM (with optional in-message fee), transfer in/out, InstaPay, salary, bill, refund, fee. Each kind is covered in en/ar/mixed, plus a no-date case and a year-less case. InstaPay covers only transfer out, transfer in and bill, because it is a payment network (no card purchases, ATM or salary). It has 12 transaction fixtures instead of about 30. | Covers what the app sends. |
| 7 | `refIsUnique` | `false` for all. | Uniqueness can't be verified without real samples, so the conservative tier-2 rule (also needs a date within 1 day) applies. |
| 8 | Masker threshold (2d #13 flag) | Every profile keeps the default 12. Ingestion masks with 12, so nothing needs to be exposed on `ParsedTransaction` or the domain. A registry test pins `maskThreshold == 12`. | The smallest change. A future profile that lowers it must add the plumbing that 2d #13 describes. |
| 9 | Sender IDs | `NBE`, `NBEGYPT`, `BANQUEMISR`, `BMISR`, `CIB`, `CIBEGYPT`, `QNB`, `QNBALAHLI`, `BDC`, `BANQUEDUCAIRE`, `AAIB`, `INSTAPAY` (canonical, none shared). | Plausible alphanumeric IDs. **Unverified: the owner must confirm the real sender lists (FR-020)** before release, because they form the Android allow-list. |
| 10 | Year-less dashed date (`08-03`) | Not supported by `SmsDateReader` (`/` only). The Banque Misr fixture uses `08/03`. I did not change the shared date reader. | Out of slice. A real bank that writes `dd-mm` without a year would fall to the receipt date, flagged as inferred, which is safe. |
| 11 | Gate harness | `test/.../profiles/profile_gate.dart` runs each profile **in a registry of its own** (so the gate runs before registration). It checks: ≥95% on the four fields, every transaction read by the profile itself (never by the generic fallback), the per-fixture expectations, 100% noise (the bank's own noise, plus every `_noise` case re-run with the bank's sender), signature non-match against every other folder, the bare-sender-line rule, and every template and signature finishing under 50 ms on 10 adversarial 10k strings. A mutation check (wrong expected merchant) failed the gate as it should. | SC-001 and FR-028. |
| 12 | Registration side effects | `_versions.json` now pins all 8 versions. `_fingerprints.json` gained 222 entries through `SMS_FINGERPRINTS_ADD_MISSING=1`, and all 64 existing entries are byte-identical (checked). | The phase2c #26 rule. |
| 13 | **Edits to other slices' tests (minimal)** | (a) `rule_based_sms_parser_test.dart`: one test asserted that the shipped registry was generic-only. It now asserts the shipped registry equals `SmsParserRegistry.standard`, and that an empty registry is generic-only. The generic-only assertion is kept, on an explicit empty registry. (b) `corpus_test.dart` anonymization guard: a new HMAC hex digest in `_fingerprints.json` (`aaib/instapay_ar.txt`) happened to contain 16 decimal digits in a row, about a 1% chance per digest. That file is now checked differently: its keys are still digit-scanned, and every value must be exactly `^[0-9a-f]{64}$`. Every `.txt` and fixture `.json` is scanned as before. | (a) T117 changes the shipped registry by design. (b) It was a false positive on hashes, not message content. The new check is stricter for that file, because nothing but a digest can sit there. |

## Use cases

| # | Topic | Choice | Why |
|---|---|---|---|
| 14 | `RequestSmsPermission` order | Capability check, then persist `permissionRequested`, then `ExternalActivityRunner.run(request)`. A failed write stops the call before the dialog. | Channel contract: "persists … before invoking the platform". **Flag for T107**: the platform adapter cannot read the *pre-request* `permissionRequested` from settings, because it is already `true` by then. `classifySmsPermission`'s `previouslyRequested` must be captured another way, for example by the adapter reading it before the use case writes it, or by a port parameter added in T107. |
| 15 | `EnableSmsImport` already granted | Reads the status first. If already granted, it does not request again. Otherwise it calls `RequestSmsPermission`. It enables and saves the window only on `granted`. It never scans. Without `explanationAcknowledged` it returns `ValidationFailure('sms_import_explanation_required')` and writes nothing. | Avoids an unneeded system activity. The contract wording is "Calls RequestSmsPermission", so this is a conservative reading. |
| 16 | `RunInboxScan` failures | Capability off → `SmsCapabilityUnavailableFailure`. Disabled → `ScanNotAllowedFailure(disabled)`. Permission not granted → `SmsPermissionFailure(status)`, which drives the revoked/denied banner. Nothing is read in any of these cases. A gateway or ingestion `Left` is passed through, and items from pages already finished stay. | Content-free failures that already exist. |
| 17 | "Cursor reset" | An explicit scan always starts at `now − window` (calendar arithmetic) with a page cursor of its own. The stored cursor moves only through `ingest(advanceCursor: true)` per finished page. The repository never moves it backwards, and a cancelled page never advances it. No new repository method was added. | Matches 2d #9. |
| 18 | Stop conditions | Before every page the scan checks the token, then `isResumed`, then (from page 2 onward) `isEnabled`. Any of them gives `cancelled = true`. Created items are kept. | FR-007, FR-008a, and `DisableSmsImport` "stops a running scan". |
| 19 | `lastScanAt` | `recordScan(catchUp: false)` runs at the end, also after a cancel. It is best effort: a failed write never hides the scan result. | — |
| 20 | Coordinator | `runExclusive(ScanKind.explicit, token, …)`. A `null` (the token was cancelled while waiting) maps to `Right(ScanSummary(cancelled: true))`. A test proves that a running catch-up is cancelled and the scan then runs. | FR-013. |
| 21 | FR-002 guard | `request_sms_permission_test.dart` greps `lib/` and finds no other file that uses `SmsPermissionService` and calls `.request(`. | Contract invariant 1 (Dart side). |

## Not done / follow-ups

- **Codegen** for the six new `@injectable` use cases (orchestrator or the next codegen owner).
- T107 (`previouslyRequested`, #14). The owner must confirm the sender IDs and real phrasing, then flip `verified` (#9, #1).
- UI copy for `unverified_profile` (2c #14) is still owed by the presentation tasks.
