# Phase 12d: T158 integration flows, T161 docs, consistency re-check

Date: 2026-10-12. Branch `023-bank-sms-import`. Toolchain: fvm Flutter 3.47.0. No lib/ files were edited.

## T158: `integration_test/sms_import_flows_test.dart`

### Approach
- The test follows the conventions of `app_lock_flows_test.dart` and `ocr_flows_test.dart`. It uses the real DI graph (`configureDependencies`), the real router, `DaftaryApp`, `AppLockGate`, Cubits, use cases, parser, HMAC, AES-GCM vault, staging repository and `SmsImportRepositoryImpl.confirm`.
- Only OS-facing ports are replaced, through `getIt.unregister`/`register` after `configureDependencies`:
  - `SmsInboxGateway`
  - `SmsPermissionService`
  - `SharedTextSource`
  - `AppLifecycleStateSource`
  - `BiometricService`
  - `PinHasher` (5 iterations)
  - `AppLockRepository` and `AppLifecycleObserver`, both with a hand-moved clock
  - `LockScreenCubit`
  - `AppDatabase`, replaced by in-memory drift
  - `FlutterSecureStorage`, replaced by `setMockInitialValues`
- Because the Android behaviour sits behind these ports, every case runs on the macOS desktop. No case needed a `skip:`.
- The fakes are local to the file. Existing integration tests never import from `test/`, so I kept that boundary.
- Every message is synthetic: invented merchants, card `****0000`/`4821`, and dates relative to today.

### Cases
1. Paste → review → Add. One recognized message goes straight to its review (`pushReplacement`, ui-contract §3.5). Nothing is saved before Add. After Add there is exactly one `finance_entries` row with `import_source = 'sms'` and 12550 minor EGP, the pending row is `added` with `raw_blob` NULL and `saved_record_id` set, there are no person transactions, and the app is back on the hub.
2. Capability build scan with the fake gateway (`/bank-messages?scan=now`), then Ignore. The summary card is shown, the unknown sender is never staged, there are no permission prompts, and the row ends `ignored` with `raw_blob` NULL and nothing saved.
3. Duplicate warning. A manual expense with the same amount a day earlier causes: banner on open → Add opens the side-by-side sheet (not a save) → "same" → row `duplicate`, `raw_blob` NULL, and the finance entry count stays at 1.
4. Permission off. With the feature enabled and `revoked`, the revoked banner shows, there is no Scan now, the pending card is still reviewable and Add is enabled, and there are 0 prompts and 0 inbox queries.
5. Feature off with `denied`. The "Turn on" card shows, there is no scan, and there are 0 prompts and 0 queries.
6. Glass-ON reachability (see the finding below). Add and Ignore on the review must be hit-testable with Liquid Glass ON, which is the shipped default.
7. Share with App Lock, cold then warm.
   - Cold: the share is not routed or parsed while locked, then lands on review after the PIN. `origin = 'share'`.
   - Warm: the app is backgrounded past the timeout, the share arrives while the lock screen shows, the router location stays `/overview`, and the row count is unchanged. After the PIN, the second item is on review. Nothing is saved.

### Run (macOS desktop, `fvm flutter test integration_test/sms_import_flows_test.dart -d macos`)
- **6 passed, 1 failed** (7 tests). Cases 1–5 and 7 pass. Case 6 fails because of a production layout bug (below). Final run: `00:28 +6 -1`.
- Cases 1–5 and 7 call `bootApp(glass: false)`, which runs `SettingsCubit.setGlassEnabled(false)`. With glass ON the bug below makes Ignore untappable, and case 6 covers that layout separately.
- `fvm flutter analyze` (whole project): no issues. `dart format`: clean.
- **T158 is left `[ ]`** because the file does not fully pass. Once the bug below is fixed, re-run the test, and T158 can be checked if it is 7/7.

### Production bug found (not fixed; lib/ is out of my slice, and the presentation pages are owned by the concurrent T156 agent)
- **Where:** 023 pages under the shell use a `ListView` with an explicit `padding: const EdgeInsetsDirectional.all(AppSpacing.md)` and `SafeArea(bottom: false)`, and never add `AppGlassInsets.of(context)`. The `AppScaffold` contract (`lib/core/design_system/glass/app_scaffold.dart` doc: "Scrollables with an explicit `padding:` add `AppGlassInsets.of(context)`") requires it. The OCR review, savings, budgets and settings pages all add it.
- **Affected:** `import_review_page.dart:274-275` (and the skeleton at 1205-1207), `paste_bank_message_page.dart:144-145`, `bank_messages_page.dart:275` and 479, `ignored_imports_page.dart:99` and 273, `enable_bank_messages_page.dart:330`, `bank_messages_settings_page.dart:167`, and likely the muted and learned pages too.
- **Effect:** With Liquid Glass ON (the default, `GlassAppearance.defaults`) the body extends behind the shell's bottom navigation bar. The last controls in the list can't be scrolled above it.
  - On a 390×844 phone, the review's **Ignore** button sits under the bottom bar. The tap lands on a nav item: the hit test resolved to the nav bar `RenderFlex` at y=808.
  - **Add** is reachable, but only barely: it sits just above Ignore.
  - On shorter screens, or with large text, Add may also be covered.
- **Fix (one line per list):** `padding: const EdgeInsetsDirectional.all(AppSpacing.md).resolve(Directionality.of(context)) + AppGlassInsets.of(context)`, or the `EdgeInsets.all(...) + AppGlassInsets.of(context)` form used by `scan_review_page.dart:167`.
- **Why the widget tests missed it:** `pumpSmsPage` mounts pages in a bare `MaterialApp.router` with no shell and no `AppGlassScope`.

### Ambiguities and choices
- The task text says "paste → review". The app skips the paste result panel for a single recognized message and opens the review directly. The test asserts the actual (spec'd) behaviour and does not tap "Open list".
- In the warm share, the share is delivered after the lock screen shows, which models Android delivering `onNewIntent` on resume. A share delivered while still `paused`, before the resume lock evaluation, is a race the fake can't reproduce faithfully. It is left to the T160 device walkthrough.
- After a branch switch, the warm-share "not routed" check uses the router location, not the widget tree. The People branch keeps the earlier review offstage, so a `skipOffstage: false` finder would be a false positive.
- What this cannot prove, and stays with T160: the real READ_SMS dialog, Android 15 restricted settings, the real Messages share intent, and "no second MainActivity".
- A hang I found: `StreamController.close()` on a single-subscription controller that never had a listener never completes. `tearDown` therefore uses `unawaited(shares.close())`. This is a test-only concern.

## T161: docs

- `PRODUCT.md` (additive):
  - One "Bank message import (023)" bullet under Implemented modules: on-device only, deterministic, confirm per item with no Add all, iOS/macOS paste only, Android `READ_SMS` only in the `DAFTARY_SMS_IMPORT` capability build, share in every Android build, masked/encrypted/purged.
  - One constraint bullet under Capabilities and Constraints.
- `README.md` (additive):
  - A 🏦 Features row.
  - A "Bank messages on Android" note under *Try it*: the release APK is the SMS build, there is no startup prompt, the Play Protect warning/block is not worked around and paste/share remain, and the Android 15+ restricted-settings path is App info → ⋮ → Allow restricted settings, with OEM wording varying.
  - A "Bank SMS import build switch" subsection before *Releasing the Android APK*: `DAFTARY_SMS_IMPORT=true` / `-Pdaftary.smsImport=true`, READ_SMS only, the SMS-free build is paste/share only, `tool/check_merged_manifest.sh`, and release workflow verification.
- I wrote "Android 15 and later" for restricted settings, following research.md Decision 2 / S4 (`sdkInt >= 35`).
- **T161 is marked `[X]`.** Formally it depends on owner task T160 (device walkthrough). **The device-caveat wording in README.md must be re-checked after T160**, specifically:
  - the Play Protect behaviour on an Egyptian-market device (OQ5). If OQ5 fails and the two-APK matrix is adopted, the "release APK is the SMS build" sentence must change to describe both APKs.
  - the exact restricted-settings steps and Android versions (OQ6/S4).
- Not changed: the README testing counts ("~380 … / 21 integration test flows") are now stale. There are 23 integration test files including the 023 flows and the benchmark. I left them as they are because they aren't 023 copy. The owner can refresh them.

## Lightweight consistency re-check (spec FRs ↔ tasks ↔ code), in the spirit of /speckit-analyze. The spec, plan and contracts were not edited.

Method: I extracted the 121 FR ids from spec.md, counted word matches in tasks.md, and counted files that reference each id in lib/, test/, integration_test/, android/, tool/ and .github/. I then spot-checked the ones with no hits.

1. **tasks.md cites FRs sparsely by id.** Only 35 distinct FR ids appear. Traceability runs through user stories and the coverage table instead. This is not a gap, but it limits automated tracing (LOW).
2. **FRs with no explicit id in code/tests, and their real status:**
   - FR-037 (Arabic normalization): implemented in `sms_text_normalizer.dart` (tatweel and alef/ya/ta-marbuta folding). Covered by tests but not tagged.
   - FR-082/083/084 (offline, local-first, no partial save): covered by `test/features/sms_import/offline_flows_test.dart` (T153) and the confirm transaction tests. Not tagged.
   - FR-085/087 (staging never syncs; cross-device duplicate via synced records): covered by the table classification guard and the duplicate lookup over the shared transaction tables. Not tagged by id.
   - FR-089 (l10n parity): `l10n_parity_test.dart` and `hardcoded_string_guard_test.dart`.
   - FR-092–FR-096 (RTL/theme, screen-reader labels, 48dp/contrast, large text, announcements): covered in part by per-page tests. The consolidated RTL/theme/a11y pass is **T156, still open (`[ ]`)**. **Gap remains until T156 closes.** The glass-ON layout bug above is in the same family (FR-095, operable without clipping/overlap).
   - FR-074/FR-103: privacy leak suite (T152) and static guards. FR-103 is future-only.
   - FR-013a and FR-071 are retired.
3. **FR-095 / ui-contract §3.4 vs code (MEDIUM):** the review's Ignore is covered by the shell bottom bar with glass ON (see T158). The integration test case "review actions are reachable … Liquid Glass ON" currently fails.
4. **Open tasks blocking full coverage:**
   - Spikes T010–T014 and T163 (device, NOT RUN by orchestrator decision)
   - T156 (l10n/a11y/RTL, in progress by another agent)
   - T157 (regression run)
   - T158 (this file, 6/7)
   - Owner-only tasks: T160, T162, T166, T167
5. **FR-003 vs release workflow:** consistent. `release-android.yml` builds with `DAFTARY_SMS_IMPORT=true` and verifies READ_SMS present and RECEIVE_SMS/SEND_SMS/READ_PHONE_STATE absent. The OQ5 fallback (two APKs) is not built; it is conditional on T160.
6. **FR-050 (entry points):** `kBankMessageImportFeatureEnabled = true` gates the Home card/quick action, consistent with the binding orchestrator decision (CHK013).
7. **FR-049:** the note is never prefilled. "Use merchant as note" exists only as a user tap (`ImportReviewCubit.useMerchantAsNote`). Consistent.
8. Nothing found in code contradicts rule 5 (no auto-create). Every flow in the integration test confirms that no record exists until the explicit Add.

## Fix: glass-ON insets on the 023 pages (follow-up to the T158 finding)

Date: 2026-10-12.

- **Change:** every scrollable 023 page body now follows the `AppScaffold` contract: `padding: const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context)`, the same form `scan_review_page.dart:167` uses. `EdgeInsetsDirectional.all` → `EdgeInsets.all` is equivalent because the value is symmetric. The change covers:
  - review: `_Form` and `_Skeleton`
  - paste
  - hub: ready list and skeleton
  - ignored: list and skeleton
  - enable: the explain `ListView` and `_Scroll`
  - settings: ready list and skeleton
  - muted senders list
  - learned categories list
- **Hub context bug:** the hub's `_body(context, …)` received the `BlocConsumer` builder's context, which sits *above* the page's `AppScaffold`. There `AppGlassInsets.of` sees the shell's bottom inset but not the app bar's. `_body` is now built through a `Builder` under the scaffold.
- **Hub empty state:** this state is a non-scrolling `Column` (scan header + `AppEmptyView`). It is now wrapped in `Padding(padding: AppGlassInsets.of(context))`, so the header clears the glass top bar and the action clears the bottom bar.
- **No bottom-pinned action bars exist in sms_import.** The review's Add/Ignore are the last items of its list, so the list padding covers them. The sheets (`probable_duplicate_sheet`, skipped list, restricted guidance) are modal sheets, not `AppScaffold` bodies, and are unchanged. Pages whose `SafeArea` keeps `bottom: true` (paste, enable, settings) already consumed the bottom inset. For them the fix adds the missing top inset under the glass app bar.
- **Glass OFF:** `AppGlassInsets.of` is `EdgeInsets.zero`, so the layout is unchanged (SC-003).
- **Regression test:** `test/features/sms_import/presentation/glass_insets_test.dart` (9 tests).
  - Each page is mounted in the shell frame (`AppScaffold` + `AppNavigationBar`) on a 390×844 surface, with an `AppGlassScope` at the Medium ON style (`onStyle` from the glass test harness).
  - Each test asserts that the first list item starts below the app bar, and that after scrolling to the end the last item ends above the bottom bar.
  - For the review, it also asserts that Add and Ignore are above the bar and hit-testable, and that tapping Ignore does not reach the bar.
  - Verified to fail when the review's inset is removed (first item at y=16 < 56).
  - `pumpSmsPage` gained two optional, additive params: `glass` and `frame`.
  - Skeleton states are not mounted by the test, because they are transient. They use the same one-line pattern.
- **Results:**
  - `fvm flutter test integration_test/sms_import_flows_test.dart -d macos`: **7/7 passed**, with no change to that file. **T158 is now marked `[X]`.**
  - `fvm flutter analyze`: no issues.
  - `fvm flutter test test/features/sms_import test/features/dashboard test/widget`: 2436 passed, 0 failed.
