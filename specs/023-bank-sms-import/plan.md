# Implementation Plan: Bank SMS Transaction Import

**Branch**: `023-bank-sms-import` | **Date**: 2026-10-06 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/023-bank-sms-import/spec.md`; decisions in [research.md](research.md) (authoritative, Decisions 1-15); design artifacts [data-model.md](data-model.md) and `contracts/` (`sms-platform-channel.md`, `parser-contract.md`, `domain-interfaces.md`, `sync-wire-027.md`, `ui-contract.md`). This plan names files and sequencing; it does not restate entity fields, channel payloads, parser grammar, interface signatures, wire shapes or screen specs, which live in those documents.

## Summary

Daftary reads bank SMS **on the device**, turns each recognized message into a **pending import** (a local-only suggestion), and lets the user review, edit, categorize, link a person, then explicitly **Add** or **Ignore**. Nothing is saved without a per-item Add (Principle X, which the pre-approval amendment below names for SMS). Android gets an opt-in inbox scan plus a foreground catch-up (READ_SMS only, no receiver, no background work) and a plain-text share target (a dedicated `ShareTargetActivity` in every Android build); iOS and any Android build without the capability get Paste. One pipeline serves every path: recognize, normalize, parse, validate, classify, duplicate-check, stage.

Technical approach (research.md): a new feature module `lib/features/sms_import/` in the OCR layout; a pure-Dart rule-based parser with a Dart-const bank-profile registry and a fixture corpus as the accuracy gate; an in-house Kotlin `SmsPlugin` (sender filter inside the content-provider selection, READ_SMS request, install source, share-text hand-off), registered in every Android build, behind Dart gateway interfaces; a READ_SMS manifest overlay toggled by one Gradle switch `DAFTARY_SMS_IMPORT` (AGP static manifest file if spike S3 confirms it, else a manifest-only `:sms_capability` module), capability derived at runtime from `readSmsDeclared && Platform.isAndroid`, plus a CI merged-manifest assertion; Drift schema 12 -> 13 with four local-only tables, one settings singleton and a nullable `import_source` on the two synced tables; raw text masked then AES-256-GCM encrypted (`pointycastle`) with a random key in the existing secure storage, fingerprints as per-install HMACs computed once from the unmasked text; provenance synced as an optional field via additive server migration **027** (replaces `sync_push` only), deployed 025 -> 026 -> (v1.1.0) -> 027 -> v1.2.0.

Baseline: `main` at app `1.1.0+3` (`pubspec.yaml:19`, untagged; 022 ships as v1.1.0 first, 023 releases as **v1.2.0** with `version: 1.2.0+4`), schema 12 (v1.0.1 shipped schema 11), migrations through 026. Four on-device spikes (S1-S4) run first because they can overturn Decisions 1-4 (S1 now only verifies the share path; the constitution amendment is a pre-approval gate, not a step).

## Technical Context

**Language/Version**: Dart ^3.10, Flutter 3.47.0 (fvm, `.fvmrc`); Kotlin (Android plugin and `ShareTargetActivity`, minSdk 24 / targetSdk 36 per `FlutterExtension`); SQL for migration 027; no new Swift.

**Primary Dependencies**: existing `flutter_bloc`, `get_it` + `injectable`, `drift`, `go_router`, `fpdart`, `equatable`, `intl`, `crypto`, `flutter_secure_storage`, `app_settings` (imported `as app_settings` where the Drift `AppSettings` data class is in scope), `supabase_flutter`. One new `pubspec.yaml` entry, `pointycastle: ^4.0.0` (already resolved transitively, zero new packages in `pubspec.lock`). No `permission_handler`, no telephony package.

**Storage**: Local Drift/SQLite (`AppDatabase`, schema 12 -> 13). Staging tables are local-only (see "Data plan"). Encryption keys in the existing secure-storage singleton. Server: Supabase Postgres, migration 027 adds `import_source` to `money_transactions` and `finance_entries`.

**Testing**: `flutter test` (unit, Cubit, widget, RTL/theme, corpus, privacy, performance), `integration_test/` (device, not in CI), pgTAP via `supabase test db`, a CI shell check of the merged Android manifest, `aapt` assertion on release APKs, a channel/lifecycle fake for the foreground-only scan rule.

**Target Platform**: Android (SMS inbox, share target, paste) and iOS (paste only); macOS runner must keep building (the feature compiles to "unavailable" there).

**Project Type**: Flutter mobile app, local-first, optional cloud sync.

**Performance Goals**: SC-005 scan of 500 messages (recognized and unrecognized senders) in <= 5 s on a <= 4 GB RAM 2022 device; sender filtering is in the provider query so non-bank bodies are never read. Existing `test/performance/*` budgets must not regress.

**Constraints**: Offline for every capability (FR-082). Foreground-only work (FR-008a). Integer minor units. No raw text or financial content in logs, sync payloads, CSV, notes or crash output (FR-074). Never edit applied migrations. Server change is migration 027 only; v1.0.1+ apps must keep syncing. The user runs `supabase db push`.

**Scale/Scope**: 7 bank profiles + generic (final list per OQ3, each gated by SC-001), 8 new screens and 8 Cubits (`ui-contract.md`), 5 new local tables, 1 Kotlin plugin file plus `ShareTargetActivity.kt`, 1 manifest overlay (or one manifest-only Gradle module), 1 SQL migration, roughly 60-80 new Dart files. No NEEDS CLARIFICATION remain: every open technical question is resolved by research.md or is a scheduled spike with a pre-decided fallback (S1-S4, step 0). Product-side open questions (OQ1-OQ7: Repayment, real samples, bank list, wallets, Play Protect Egypt, restricted-settings flow, duplicate windows) are inputs and release gates, not planning blockers.

## Constitution Check

*GATE: pre-design verdict is against spec.md plus research.md Phase 0; post-design verdict is against data-model.md, contracts/ and the structure below.*

| Item | Pre-design | Post-design | Justification |
|---|---|---|---|
| I Clean layering | PASS | PASS | Domain holds entities, ports, pure rules (confidence, classifier, masker interfaces, duplicate tiers) with no Flutter, Drift or platform types. `data/` holds parser, DAO, repository impl, platform gateway impl, crypto. Presentation talks to use cases only. The parser is pure Dart but lives in `data/parsing/` exactly like `CandidateEntryParser` (it is an input adapter, not a business rule). |
| II Feature-first | PASS (with promotion) | PASS | New code is `lib/features/sms_import/`. `FieldConfidence*` and `ConfidenceIndicator` are now shared by OCR and SMS, so they are promoted to `lib/core/confidence/` and `lib/core/design_system/`; `ImportProvenance` (read by transactions and finance) lives in `lib/core/provenance/` and the `ImportedFromSmsLabel` in `lib/core/design_system/` (two-feature rule). Arabic folding stays inside `sms_import` until a second feature needs it. `NumeralParser` already lives in core and gains U+06F0-06F9. |
| III Cubit | PASS | PASS | Eight Cubits per `ui-contract.md` (`BankMessagesCubit`, `EnableFlowCubit`, `ImportReviewCubit`, `PasteCubit`, `IgnoredImportsCubit`, `MutedSendersCubit`, `LearnedCategoriesCubit`, `BankMessagesSettingsCubit`); each defines idle/loading/success/failure, single-flight on scan and Add. No second paradigm. `SmsCatchUpTrigger` is a lifecycle observer calling a use case, like `NotificationRecomputeTrigger`. |
| IV Immutable state | PASS | PASS | Equatable states with `copyWith`; lists are unmodifiable copies; `buildWhen`/`BlocSelector` on the pending list; review draft is a value object replaced per edit. |
| V Domain logic | PASS | PASS | Use cases carrying real logic: `SmsIngestionService`, `RunInboxScan`, `RunCatchUpScan`, `ImportPastedText`, `AddImportedTransaction`, `CheckDuplicates`, `ReparsePending`; the mapping defaults are the pure `suggestFor`. The single-call wrappers (`GetSmsCapability`, `OpenSmsAppInfo`, `ReadClipboardText`, `UpdateSmsImportPreferences`, the `Watch*` set) exist so Cubits depend on use cases only and tests swap fakes; the justification is recorded in Complexity Tracking. |
| VI Repository | PASS | PASS | `SmsImportRepository` (domain) and `SmsImportRepositoryImpl` (data); SMS-sourced writes go through new methods on the existing `TransactionsRepository`/`FinanceRepository` ("only the SMS repository calls this", precedent `addOcrSourcedTransaction`). Presentation never sees `*Impl`. |
| VII Errors | PASS | PASS | `SmsImportFailure` hierarchy over `Failure`; platform errors cross as typed codes mapped to `Failure`; `Either` throughout; one private `_ConfirmAborted` rollback idiom as in OCR confirm; no empty catch; per-message parser failure is isolated and counted (FR-098). |
| VIII Deterministic money | PASS | PASS | Amounts parsed to integer minor units through `CurrencyFormatter.parse` (throws on >2 decimals or >12 whole digits -> "unreadable", never clamped). No doubles, no AI (NG4, FR-027). |
| IX AI isolation | PASS | PASS | Zero AI surface: no SMS-derived data reaches `ai_assistant` (FR-081). A guard test asserts `sms_import` has no import of `ai_assistant` and vice versa. |
| X OCR/uncertain input | PASS by analogy | PASS (constitution v1.1.0, amended 2026-10-07, names SMS) | Pipeline Receive, Parse, Validate, Review, Confirm, Persist; never auto-create (SC-002). The spec (Governance Alignment) requires Principle X to name SMS before plan approval, so the amendment is the owner's pre-approval gate below, not an implementation step. |
| XI Offline and idempotent | PASS | PASS | All flows offline. Idempotency key `sms-import:<pendingId>` on both tables, status guard inside the same transaction (FR-075a). Fingerprint uniqueness makes ingestion idempotent. Sync of saved rows is the existing outbox; provenance is optional on the wire. |
| XII Security | PASS | PASS | READ_SMS requested contextually after an explanation, never at startup (FR-002). Raw text masked then encrypted, keys in secure storage, purged on decision/expiry, no logging in the feature at all (static guard incl. Kotlin `println(`, `printStackTrace(`, `System.out`), no telemetry (FR-100). See "Security plan". |
| XIII l10n/RTL | PASS | PASS | `smsImport*` ARB keys in both languages with ICU plural/select, parity test, hardcoded-string guard, RTL/theme tests per screen, original text shown in its own direction. |
| XIV DI | PASS | PASS | injectable registration; gateways, vault, hasher, key store, clock, trigger injected; tests swap fakes. Cubits get use cases only. |
| XV Design system | PASS | PASS | Existing tokens and shared widgets reused (`AppCard`, `AppTextField`, `AppDateField`, `AppConfirmDialog`, `AppEmptyView`, `CurrencyPicker`, promoted `ConfidenceIndicator`). No new raw colors. New shared widget promoted to core only if a second feature uses it. |
| XVI Testability | PASS | PASS | Corpus-driven parser gate, fakes for every port, privacy leak suite, v13 migration test, legacy mapper compat test, pgTAP file, integration journeys. Kotlin is kept thin because the repo has no Kotlin test harness (research Decision 14). |
| Eng. Standards: performance | PASS | PASS (benchmark gated) | Keyset-paged queries, in-memory duplicate maps per batch, `ListView.builder`, benchmark clone of `ocr_batch_scale_test.dart` decides whether pages go to `compute`. |
| Eng. Standards: accessibility | PASS | PASS | 48dp targets, semantics on confidence/duplicate/warning indicators, no color-only meaning, announcements for progress/error, large-text tests (FR-093-096). |
| Eng. Standards: navigation/permissions/lifecycle | PASS | PASS | Routes in `app_router.dart`; unsaved-edit prompt (FR-047); share text routed after unlock, never in URL; permission requested only from the enable flow; revocation detected on resume. |
| Eng. Standards: duplicate-action protection | PASS | PASS | Add is single-flight per item; transactional status guard; no "add all" exists. |
| Eng. Standards: complete UI states | PASS | PASS | Every screen has loading, empty, error, success (see Presentation plan). |
| Financial Domain Override | PASS | PASS (one caveat) | No silent creation or modification of any financial record; refunds never touch saved records (FR-024a). Traceability: `created` audit row plus durable `import_source`. **Caveat**: audit tables have no source column (research Spec feedback 4), so SC-013 is measured as exactly one `created` audit row plus a non-null `import_source` (spec US1-8 and SC-013 now say so). |
| Pre-Implementation Checklist | PASS | PASS | Owner: new `sms_import` feature. Layers as above. Entities, use cases, repository, data sources, Cubit shapes: data-model.md and `contracts/domain-interfaces.md`. Reused components: listed in Presentation plan. Errors, offline, Arabic/RTL, slow devices (benchmark), tests, security, simplification (no new tables for mappings beyond what lookups need; no remote rules; no background work) are each answered in the matching plan section. |

**Result**: no unjustified violations; Principle X is satisfied (amendment applied 2026-10-07). Deviations needing recorded justification are in Complexity Tracking. Re-check after step 5 (schema) and step 10 (gate) because those are the two places design may shift.

### Pre-approval gate: constitution amendment (owner action)

**Status: applied on 2026-10-07 (constitution v1.1.0).** The text below is kept for the record.

The owner applies this amendment via `/speckit.constitution` **before `/speckit.tasks` or implementation**. It is a documentation-only change that this plan does not make and no implementation step performs (spec lines 60, 527 and 628 require it before plan approval). Until it lands, the Principle X row above stays "PASS conditional on amendment".

Proposed text for `.specify/memory/constitution.md`, Principle X:

> ### X. OCR and Bank Messages Are Uncertain Inputs Requiring Confirmation
> OCR-derived and SMS-derived data (bank messages read on the device, pasted or shared) MUST flow through: Input → Preprocessing/Normalization → Parsing → Validation → User Review → Confirmation → Persistence. The application MUST NEVER auto-create financial transactions directly from OCR or SMS output without explicit per-item user confirmation. Extracted values MUST be shown clearly and MUST be correctable before saving.

Also in the same change: set Version `1.1.0` (MINOR: it expands scope and narrows nothing), Last Amended `2026-10-06`, and add a Sync Impact Report entry.

## Project Structure

### Documentation (this feature)

```text
specs/023-bank-sms-import/
├── spec.md
├── research.md                  # Phase 0 (authoritative)
├── plan.md                      # this file
├── data-model.md                # Phase 1: entities, tables, state machine, indexes
├── quickstart.md                # Phase 1: runnable validation scenarios
├── contracts/
│   ├── sms-platform-channel.md  # Kotlin <-> Dart channel and share-intent contract
│   ├── parser-contract.md       # normalization, profile, template, confidence rules
│   ├── domain-interfaces.md     # ports, use cases, failures
│   ├── sync-wire-027.md         # import_source wire and migration 027 behavior
│   └── ui-contract.md           # screens, states, routes, strings
├── checklists/requirements.md
└── tasks.md                     # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
lib/features/sms_import/
├── domain/
│   ├── entities/            # (new) PendingSmsImport, ParsedTransaction/ParseResult, ParseConfidence, tombstone, settings, ScanSummary, SmsCapability {readSmsDeclared, isAndroid}, SmsPermissionStatus, enums (SmsImportStatus, SmsSource, SmsKind, SuggestedRecordType), sms_import_failures.dart (domain-interfaces §1 set)
│   ├── services/            # (new) ports: SmsInboxGateway, SmsPermissionService, SharedTextSource, SmsMessageParser, SmsTextNormalizer, SmsMasker, SmsMessageSplitter, RawTextVault, FingerprintHasher, SmsKeyStore, ClipboardReader, ReviewLeaseRegistry, LockStatus, ExternalActivityRunner; sms_ingestion_service.dart (SmsIngestionService)
│   ├── rules/               # (new) overall_confidence.dart, classify_sms_permission.dart (pure)
│   ├── repositories/        # (new) sms_import_repository.dart, sms_import_settings_repository.dart, sms_duplicate_lookup.dart (SmsDuplicateLookup)
│   └── usecases/            # (new) per contracts/domain-interfaces.md §5:
│                            #   get_sms_capability, get_sms_permission_status, request_sms_permission, open_sms_app_info, enable_sms_import, disable_sms_import, update_sms_import_preferences,
│                            #   parse_messages, run_inbox_scan, run_catch_up_scan, import_pasted_text, import_shared_text, read_clipboard_text,
│                            #   get_pending_imports, watch_pending_imports (+ count), get_pending_import, get_expired_notice, acknowledge_expired_notice, show_original_message,
│                            #   check_duplicates, add_imported_transaction, ignore_import, close_as_duplicate, undo_ignore, watch_undo_list,
│                            #   mute_sender, unmute_sender, watch_muted_senders, watch_learned_mappings, remove_learned_mapping, clear_learned_mappings, get_scan_counts,
│                            #   expire_pending_imports, reparse_pending, clear_sms_import_data, purge_sms_import_keys
├── data/
│   ├── parsing/             # (new) sms_text_normalizer, sms_masker_impl, sms_message_splitter, rule_based_sms_parser, sms_parser_registry, select_parse, suggest_for (pure mapping defaults), bank_profile, sms_template, generic_profile
│   │   └── profiles/        #       nbe_, banque_misr_, cib_, qnb_alahli_, banque_du_caire_, aaib_, instapay_profile
│   ├── crypto/              # (new) aes_gcm_raw_text_vault, hmac_fingerprint_hasher, secure_storage_sms_key_store (caches keys per process to minimize secure-storage reads)
│   ├── platform/            # (new) sms_channel_client, platform_sms_inbox_gateway, platform_sms_permission_service (imports app_settings `as app_settings`), platform_shared_text_source, system_clipboard_reader, unavailable_* stubs (UnavailableSharedTextSource for iOS/macOS only; Unavailable inbox/permission for iOS/macOS)
│   ├── datasources/         # (new) sms_import_dao.dart, sms_duplicate_dao.dart (implements SmsDuplicateLookup)
│   ├── models/              # (new) pending_import_mapper, tombstone_mapper, settings_mapper
│   └── repositories/        # (new) sms_import_repository_impl, sms_import_settings_repository_impl
└── presentation/
    ├── routes.dart          # (new) BankMessagesRoutes constants
    ├── cubit/               # (new) bank_messages_cubit, enable_flow_cubit, import_review_cubit, paste_cubit, ignored_imports_cubit, muted_senders_cubit, learned_categories_cubit, bank_messages_settings_cubit (+ *_state)
    ├── pages/               # (new) bank_messages_page, enable_bank_messages_page, import_review_page, paste_bank_message_page, ignored_imports_page, muted_senders_page, learned_categories_page, bank_messages_settings_page
    ├── widgets/             # (new) pending_import_card, import_type_selector, sms_permission_banner, duplicate_comparison_card, probable_duplicate_sheet (ProbableDuplicateSheet), bidi_text; review sections, restricted-settings guide and original-message view are private widgets of their pages
    ├── sms_catch_up_trigger.dart   # (new) lifecycle observer, sibling of NotificationRecomputeTrigger
    └── shared_text_router.dart     # (new) SharedTextRouter + in-memory SharedTextInbox; routes after unlock (precedent NotificationTapRouter)

lib/core/confidence/field_confidence.dart            # (moved from features/ocr/domain/entities/, git mv; no behavior change)
lib/core/design_system/confidence_indicator.dart     # (moved from features/ocr/presentation/widgets/)
lib/core/design_system/imported_from_sms_label.dart  # (new) ImportedFromSmsLabel, shared by transactions and finance history
lib/core/provenance/import_provenance.dart           # (new) ImportProvenance {sms, unknown}, shared by transactions and finance
lib/core/money/numeral_parser.dart                   # touched: add U+06F0-06F9 (own commit)
lib/core/config/feature_flags.dart                   # touched: kBankMessageImportFeatureEnabled (no capability const; capability is runtime)
lib/core/database/app_database.dart                  # touched: 5 tables, 2 columns, schemaVersion 13, onUpgrade `from < 13`
lib/core/database/migrations/v13_sms_import.dart     # (new)
lib/core/database/migrations/migration_guards.dart   # touched: add ensureColumn
lib/core/sync/sync_entity_type.dart                  # touched: localOnlyTables (line ~55) += 5
lib/core/database/data_wipe.dart                     # touched: delete the 5 tables
lib/core/di/injection.config.dart                    # regenerated (build_runner)
lib/core/routing/app_router.dart                     # touched: /bank-messages, /bank-messages/enable, /bank-messages/paste, /bank-messages/ignored, /bank-messages/senders, /bank-messages/learned, /bank-messages/review/:importId, /settings/bank-messages
lib/core/l10n/failure_message.dart                   # touched: SmsImportFailure -> smsImportError* mapping
lib/core/security/app_lifecycle_observer.dart        # untouched (consumed through the existing ValueListenable isLocked)
lib/core/sync/sync_mapper_registry.dart              # untouched (SyncWire reused)
lib/core/l10n/app_en.arb, app_ar.arb                 # touched: smsImport* keys, added per screen step (steps 13-17)
lib/main.dart                                        # touched: start SmsCatchUpTrigger and SharedTextRouter in the startup.whenReady block

lib/features/transactions/
├── domain/entities/money_transaction.dart           # touched: ImportProvenance? importSource + derived `provenance` getter (analysis M8)
├── domain/repositories/transactions_repository.dart # touched: addSmsSourcedTransaction
├── data/repositories/transactions_repository_impl.dart  # touched: SMS-sourced write path + created audit row
├── data/sync/money_transaction_sync_mapper.dart     # touched: import_source in toWire (non-null only) and fromWire (never downgrade non-null local to null)
└── presentation/widgets/ (list tile, history)       # touched: ImportedFromSmsLabel from importSource
lib/features/finance/
├── domain/entities/finance_entry.dart               # touched: importSource
├── domain/repositories/finance_repository.dart      # touched: addSmsSourcedEntry
├── data/repositories/finance_repository_impl.dart   # touched: SMS-sourced write path + created audit row
├── data/sync/finance_entry_sync_mapper.dart         # touched: same as transactions mapper
└── presentation/widgets/finance_entry_list_tile.dart # touched: ImportedFromSmsLabel
lib/features/settings/presentation/pages/settings_page.dart       # touched: "Bank messages" entry (next to notifications entry)
lib/features/dashboard/presentation/{widgets/quick_action_row.dart,widgets/bank_messages_home_card.dart,pages/home_page.dart}  # touched: quick action + count/onboarding cards below the people summary
lib/features/data_privacy/domain/usecases/delete_all_user_data.dart  # touched: call PurgeSmsImportKeys (beside PurgeAIAssistantCredentials)
lib/features/data_privacy/domain/usecases/export_user_data.dart      # untouched (regression test only)
lib/features/ocr/**                                   # touched: import paths for promoted FieldConfidence/ConfidenceIndicator only (the transactions `DuplicateWarningSheet` is not touched)
pubspec.yaml                                          # touched: pointycastle (annotated), version 1.2.0+4 at release
PRODUCT.md                                            # touched: add 023 to the module list ("on-device only, confirm per item")

android/app/src/main/kotlin/com/daftary/daftary/SmsPlugin.kt           # (new) registered in every Android build
android/app/src/main/kotlin/com/daftary/daftary/ShareTargetActivity.kt # (new) baseline share path (translucent, noHistory, excludeFromRecents)
android/app/src/main/kotlin/com/daftary/daftary/MainActivity.kt        # touched: register SmsPlugin next to SecurityPlugin; launch mode untouched
android/app/src/main/AndroidManifest.xml                                # touched: ShareTargetActivity with the SEND text/plain filter, tools:node="remove" markers
android/app/build.gradle.kts                                            # touched: S3 outcome: androidComponents.onVariants static manifest file, or conditional implementation(project(":sms_capability"))
android/app/sms_capability/AndroidManifest.xml                          # (new, preferred, S3) READ_SMS overlay; fallback: android/sms_capability/{build.gradle.kts,src/main/AndroidManifest.xml} + settings.gradle.kts include
ios/Runner/*                                                            # untouched (paste is pure Dart; asserted in review)
supabase/migrations/20261006100000_027_import_source.sql                # (new)
supabase/tests/027_import_source.test.sql                               # (new)
tool/check_merged_manifest.sh                                           # (new)
.github/workflows/ci.yml                                                # touched: android-manifest job; legacy sync dir in the UTC re-run
.github/workflows/release-android.yml                                   # touched: DAFTARY_SMS_IMPORT env, aapt assertion step

test/features/sms_import/{domain,data/parsing,data/crypto,data/platform,data/repositories,presentation/{cubit,pages,widgets},privacy,helpers}/   # (new); presentation/shared_text_router_test.dart waits for unlock and consumes once
test/fixtures/sms/<bankId>/*.txt|json, _noise/, _paste/, _cross/, _hostile/                          # (new, synthetic only)
test/core/database/v13_migration_test.dart                        # (new: 11->13 in one open and 12->13); v12_migration_test.dart touched
test/core/sync/table_classification_guard_test.dart, test/core/database/data_wipe_test.dart           # touched
test/core/sync/legacy/{v101_mappers.dart,v101_pull_compat_test.dart}    # (new; v101_mappers.dart also freezes the SyncWire helpers the v1.0.1 fromWire calls, e.g. parseInstant)
test/core/confidence/field_confidence_test.dart, test/core/money/numeral_parser_test.dart            # moved / extended
test/performance/sms_ingest_scale_test.dart                       # (new)
integration_test/sms_import_flows_test.dart                       # (new)
```

**Structure Decision**: the OCR feature layout (`data/parsing`, repository impl, pure parser, Cubits, pages/widgets) is the proven shape for "uncertain input to confirmed record", so SMS copies it and reuses its review pattern rather than the manual transaction forms. Platform code (Kotlin) lives in the app module, not a package, because no reviewed package meets FR-020 and the surface is small (Decision 1).

## Complexity Tracking

| Deviation | Why needed | Simpler alternative rejected because |
|---|---|---|
| In-house Kotlin `SmsPlugin` instead of a pub package | FR-020 requires the sender filter in the provider selection before any body is read; READ_SMS request, install-source and share-text hand-off share one `ActivityAware` file | `telephony`/`another_telephony`/`flutter_sms_inbox`/`readsms` all either filter after reading bodies, add forbidden permissions (RECEIVE_SMS, ACCESS_COARSE_LOCATION) or are discontinued (Decision 1) |
| READ_SMS manifest overlay behind one Gradle switch (`DAFTARY_SMS_IMPORT`); capability derived at runtime, no Dart const | FR-001: the off build must have no SMS permission in the merged manifest, including from dependencies, with no change to how the app is built or signed. S3 first tries AGP `androidComponents.onVariants { it.sources.manifests.addStaticManifestFile(...) }` (one overlay file, no module, no hard-coded `compileSdk`); the manifest-only `:sms_capability` module is the fallback. One switch only: `available = readSmsDeclared && Platform.isAndroid`, so a READ_SMS-shipped-but-feature-dark mismatch (which `aapt` cannot detect) cannot exist | Product flavors change `--flavor`, APK names, IDE configs and iOS schemes; source-set overlays clobber debug/profile manifests; placeholders resolve after merge; a second `--dart-define` knob can disagree with the manifest (Decision 3) |
| New direct dependency `pointycastle` | AES-256-GCM at rest for raw text, in pure Dart, unit-testable, identical on every platform | A new package (`cryptography`, `encrypt`) adds a lockfile entry; native Keystore/CryptoKit adds Swift and untestable native code (Decision 6). Net lockfile change is zero |
| Promote `FieldConfidence`/`ConfidenceIndicator` to core | Second consumer (SMS) arrived; Principle II mandates promotion over duplication | Copying creates two divergent read-vs-inferred contracts (Decision 8). Cost: a `git mv` and 8 lib + 10 test import updates, no behavior change |
| Local staging in the main DB with five tables | Atomic Add (FR-075a) needs record save and status update in one transaction | A second DB file breaks atomicity and doubles migrations and wipe (clarify review) |
| Dedicated review screen instead of the manual forms | FR-044 forbids opening or modifying the manual forms; SMS needs inferred markers, duplicate sheet and show-original | Reusing `FinanceEntryFormCubit`/`TransactionFormPage` couples to forms that must not change (SC-012) |
| `SmsCatchUpTrigger` sibling observer | Keeps SMS work out of the security-only `AppLifecycleObserver` (Decision 12) | Hooking the observer mixes security and SMS and makes `core` aware of a feature |
| `ShareTargetActivity` as the baseline share path (not conditional on S1) | `MainActivity` is `singleTop` with `taskAffinity=""`, so a share from Messages can run a second engine: two isolates with two Drift connections on one SQLite file (stream invalidation does not cross isolates, writes can hit "database is locked"), duplicate `SyncScheduler` and notification triggers, and a Daftary screen inside the Messages task. The trampoline puts `EXTRA_TEXT` into an in-process holder read by `SmsPlugin`, starts `MainActivity` with `NEW_TASK \| CLEAR_TOP \| SINGLE_TOP` and finishes; `MainActivity`'s launch mode is untouched so notification taps carry no regression risk. App Lock itself is not bypassed (a second engine locks at cold launch, `app_lifecycle_observer.dart:68-70`) | Changing `MainActivity` to `singleTask` risks notification-tap and cold-start regressions; accepting a second engine is the hazard above. S1 only verifies the instance count is 1 |
| Single-call use-case wrappers (`GetSmsCapability`, `OpenSmsAppInfo`, `ReadClipboardText`, `UpdateSmsImportPreferences`, `Watch*`) | Principle V says no trivial pass-through. These stay thin so Cubits depend on use cases only (Principle III/XIV) and tests swap fakes for the platform and clipboard ports; the settings writes are already folded into one `UpdateSmsImportPreferences` | Cubits calling repositories or `app_settings`/`Clipboard` directly would break the layer rule and make the clipboard-zero-reads and permission tests need platform channels |

## Domain plan

Entities, enums, state machine and field lists are in `data-model.md`; port signatures and failures in `contracts/domain-interfaces.md`. This section fixes the rules that cut across them.

- **Entities** (all `lib/features/sms_import/domain/entities/`, pure Dart, Equatable): pending import with its parsed fields and per-field confidence, import tombstone, sender mute, learned merchant mapping, import settings, scan summary (content-free counts), permission state, `ImportProvenance` (`sms` or `unknown`, `lib/core/provenance/import_provenance.dart`) living on `MoneyTransaction` and `FinanceEntry`.
- **Status machine**: `pending -> added | ignored | duplicate | expired`; `ignored` and `expired` can return to `pending` only through re-scan or re-paste after Undo removes the tombstone (FR-068); `added` and `duplicate` are terminal. All transitions are repository-owned inside one DB transaction.
- **Ports** (domain `services/`): `SmsInboxGateway`, `SmsPermissionService`, `SharedTextSource`, `SmsMessageParser`, `SmsTextNormalizer`, `SmsMasker`, `SmsMessageSplitter`, `RawTextVault`, `FingerprintHasher`, `SmsKeyStore`, `ClipboardReader`, `ReviewLeaseRegistry`, `LockStatus`, `ExternalActivityRunner`, plus existing `AppClock`; the shared `SmsIngestionService` and the `SmsDuplicateLookup` repository contract complete the set. The platform, crypto and parsing implementations are `data/` classes; the domain never imports `dart:io`, Drift or channels.
- **Pure rules in domain**: `overallConfidence(fields, {capMedium})` (lowest read level among required read fields; any inferred required field caps at Medium; generic and paste/share cap at Medium; FR-039-042) and `classifySmsPermission(result, previouslyRequested)` -> `granted | denied | permanentlyDenied | restrictedBlocked | revoked`. Both are table-tested with no framework.
- **Duplicate tiers** (FR-059b order): (1) fingerprint exact; (2) same bank + `ref_hash` + amount + direction via `ref_amount_hash` exact; (3) both reference hashes present and different -> legitimately similar, stop; (4) probable: same currency, same minor-unit amount, direction group (expense = given, income = received), date within one calendar day, against saved own-money and people-ledger rows of any source. Tier 2 applies only to banks with `refIsUnique`; otherwise it also needs a date within one day. The probable tier also compares a stated original-currency amount, ranks candidates by merchant/note similarity then date, and flags `possibleOwnTransfer` for an opposite-direction equal-amount pair across banks within one day (FR-051d). `CheckDuplicates` over `SmsDuplicateLookup` is new and SMS-specific; the person-scoped `FindPossibleDuplicate` is not modified (FR-060).
- **Mapping defaults** (spec table, FR-051..51c) live in one pure function `suggestFor` (`data/parsing/suggest_for.dart`, parser-contract §8): kind -> suggested action, category by learned mapping, then keyword rules, then "other"; person suggestion only on an existing-name match; cash-withdrawal preference read from settings. Suggestions are values, never writes.
- **Failures** (`SmsImportFailure extends Failure`, the set of `contracts/domain-interfaces.md` §1): `SmsCapabilityUnavailableFailure`, `SmsPermissionFailure(status)`, `SmsInboxQueryFailure`, `InputTooLargeFailure`, `NotRecognizedFailure`, `ImportAlreadyDecidedFailure`, `ImportIncompleteFailure`, `ProbableDuplicateFailure`, `OriginalUnavailableFailure`, `ScanNotAllowedFailure`; save and storage errors reuse `CacheFailure`. Messages map in `lib/core/l10n/failure_message.dart` to `smsImportError*` ARB keys; none carries message content.

## Data plan

**Persisted (main Drift DB, schema 13)** per research Decision 9 and `data-model.md`:

| Object | Content | Lifetime | Synced |
|---|---|---|---|
| `pending_sms_imports` | parsed fields, `confidence_json`, warnings, hashes, `rule_version`, status, `raw_blob` (masked + AES-GCM) | pending 30 days; decided rows kept 30 days then purged, blob nulled on decision. Added/duplicate rows are scrubbed to an identity shell (incl. `sender_id`); ignored/expired rows keep only `amount_minor_units`, `currency_code`, `occurred_on`, `merchant`/`counterparty`, `bank_id`, `kind` for the Undo list (`card_last4`, `time_minutes`, `merchant_key`, `sender_id`, `suggested_*`, `confidence_json`, `warnings_json` are nulled) | No (local-only) |
| `sms_import_tombstones` | fingerprint, outcome, bank id, `ref_hash`, `ref_amount_hash`, saved record id/type, `purge_after` | >= 97 days | No |
| `sms_sender_mutes`, `sms_merchant_category_mappings` | sender id; merchant key -> category id (no FK) | until user clears | No |
| `sms_import_settings` singleton | enabled, dismissals, window, cursor `(date,id)`, last scan/catch-up, cash-withdrawal preference, `permission_requested`, content-free counters | life of install | No |
| `money_transactions.import_source`, `finance_entries.import_source` | `'sms'` or NULL | life of the saved record | **Yes**, optional field, server migration 027 |
| Secure storage | `sms_import.enc_key.v1`, `sms_import.mac_key.v1` (random 32 bytes each); `SmsKeyStore` caches keys per process to minimize reads | until Delete-all or key loss | No, never backed up readable |

**Transient (memory only, never persisted)**: pasted and shared text before staging (held in `SharedTextInbox` / the paste Cubit, cleared on consume or screen exit); the decrypted original while "Show original" is open; the review draft; the in-flight scan page; unrecognized paste/share content (FR-018, stored nowhere); the unmasked normalized body used once to compute the fingerprint and hashes; non-transactional skip counts (counted, not listed with text).

**Never stored**: full card/account numbers, balances, OTPs (FR-031, FR-077); raw text after decision; any amount on a tombstone; SMS content in the saved record's `note` (FR-049, FR-088).

**Migration v13** (`v13_sms_import.dart`, called under `if (from < 13)`): one transaction; `ensureTable`/`ensureIndex` plus new `ensureColumn`; no existing row read or rewritten; existing rows get `import_source = NULL`. v1.0.1 users are on schema 11, so both 11 -> 13 in one open and 12 -> 13 are tested. Local-only classification (`lib/core/sync/sync_entity_type.dart`), `DataWipe` and `@DriftDatabase(tables: [...])` updated in the same step so `test/core/sync/table_classification_guard_test.dart` and `data_wipe_test` stay green.

**Reads for duplicates**: no new index in v13; `SmsDuplicateDao` uses the existing `(date, deleted_at)` indexes, one batched load per scan, in-memory tier evaluation; benchmark decides if partial indexes arrive in a later migration (Decision 11).

## Platform plan

### Android

- **`SmsPlugin.kt`** (channel `com.daftary.daftary/sms`, event channel `.../sms/shared_text`; payloads in `contracts/sms-platform-channel.md`): `getCapabilities`, `getPermissionState`, `requestPermission`, `queryInbox` (selection `UPPER(address) IN (...) AND (date > ? OR (date = ? AND _id > ?))`, `date ASC, _id ASC`, at most 200 rows read from the cursor), `getInitialSharedText`, share events. Registered in **every** Android build next to `SecurityPlugin` in `MainActivity.configureFlutterEngine` (sharing needs no permission, FR-001/FR-011). No logging, no message content in exceptions, typed error codes only.
- **Abstractions**: Dart sees only `SmsInboxGateway`, `SmsPermissionService`, `SharedTextSource`. `PlatformSms*` implementations wrap the channel (injectable channels as in `PlatformScreenshotProtectionService`); `UnavailableSmsInboxGateway`/`UnavailableSmsPermissionService` are registered on iOS and macOS; on Android the `Platform*` adapters check `getCapabilities().readSmsDeclared` and short-circuit inbox and permission calls when it is false, so the capability-off build behaves as "scan unavailable, paste/share available". `SharedTextSource` availability is `Platform.isAndroid` only: `UnavailableSharedTextSource` is registered for iOS and macOS only, never for a capability-off Android build.
- **Permission flow**: enable flow shows the FR-005 explanation, then `RequestSmsPermission` wraps `requestPermission()` in `AppLifecycleObserver.runExternalActivity`; the pure classifier yields the state; `restrictedBlocked` shows step-by-step guidance and opens App info through `app_settings` (default `ACTION_APPLICATION_DETAILS_SETTINGS`, not wrapped; imported `as app_settings` in `PlatformSmsPermissionService` because the package's `AppSettings` collides with the Drift `AppSettings` data class). `RefreshSmsPermission` is prompt-free and runs on resume to detect revocation (FR-070).
- **Capability gate**: one switch, `DAFTARY_SMS_IMPORT=true`, read by `android/app/build.gradle.kts` (provider-based, `-Pdaftary.smsImport=true` fallback). It adds a READ_SMS-only manifest overlay: S3 first checks AGP 8.11 `androidComponents.onVariants { it.sources.manifests.addStaticManifestFile(...) }` (one overlay file, no module); if that does not work, the manifest-only `:sms_capability` module (its `compileSdk` hard-coded to 36 and re-checked against `FlutterExtension`). There is no `--dart-define` and no Dart const: the runtime capability is `readSmsDeclared && Platform.isAndroid` (`getCapabilities`), so the two-knob mismatch (READ_SMS shipped, feature dark) cannot occur. The main manifest carries `tools:node="remove"` for RECEIVE_SMS, SEND_SMS, RECEIVE_MMS, RECEIVE_WAP_PUSH, WRITE_SMS, READ_PHONE_STATE.
- **Share target (baseline, not conditional on S1)**: a translucent `ShareTargetActivity` (`noHistory`, `excludeFromRecents`) carries the `ACTION_SEND text/plain` filter in every build; it puts `EXTRA_TEXT` into an in-process holder read by `SmsPlugin` (cold start: `getInitialSharedText`, once and cleared; warm: event channel), starts `MainActivity` with `NEW_TASK | CLEAR_TOP | SINGLE_TOP` and calls `finish()`. `MainActivity`'s launch mode stays untouched. Dart `SharedTextRouter` waits for unlock before routing to `/bank-messages/paste` with no text in the URL. S1 only verifies the instance count is 1.
- **Catch-up**: Dart-side only (`SmsCatchUpTrigger`); Kotlin offers no background entry point. Two APKs built with and without the overlay share one `versionCode`, so installing one over the other is allowed and pending rows survive it.
- **No SMS receiver, no service and no WorkManager for this feature** (FR-008a). CI asserts there is no `SMS_RECEIVED`, `SMS_DELIVER` or `WAP_PUSH_DELIVER` intent filter and no receiver or service declared by the SMS code. The app's existing `flutter_local_notifications` receivers (`AndroidManifest.xml:59-60`) are unrelated and stay. Catch-up and scans also stop between pages whenever the lifecycle state is not `resumed` (see Application layer plan).

### iOS

- **No native change.** `SecurityPlugin.swift`, `Info.plist`, entitlements and the Runner project stay untouched (NG11, no App Group). Capability is false; `Unavailable*` ports (inbox, permission and shared text) are registered.
- **Paste**: multi-line editable field (system edit-menu paste, no iOS paste prompt) plus a Paste button calling `Clipboard.getData(Clipboard.kTextPlain)` only inside `onPressed`; no read on open, resume, focus or route push (FR-015). Empty or non-text yields the "nothing to paste" state pointing at the field.
- macOS runner: compiles with the same `Unavailable*` ports (shared text included); no manifest or channel work.

## Application layer plan

One pipeline, many entries (FR-021): `RunInboxScan`, `RunCatchUpScan`, `ImportPastedText` (also share, via `ImportSharedText`) all call `SmsIngestionService`.

1. **Recognize/parse**: splitter (bounds 10,000 chars, 50 messages) then `SmsMessageParser.parse` (`selectParse(text, sender)`) (sender+signature, signature only, generic) -> normalized parse or `NotRecognized` / `AmountUnreadable`. Per-message failure is caught, counted content-free, and the batch continues (FR-098).
2. **Validate/classify**: non-transactional kinds are counted and dropped (FR-024); no amount -> unreadable (FR-039a); no determinable direction -> incomplete, not ready (FR-033); any absent required field gives overall confidence Low (FR-039; paste without a date or currency is therefore always Low, which is intended); refund credit -> Ignore suggested with the fixed hint; authorization reversal -> pending item, Ignore suggested, hint plus the matched saved record (FR-024b); an in-message fee -> a second pending fee item linked to its parent (FR-030a). Paste and share input is stripped of messaging-app envelope lines before splitting (FR-017a).
3. **Fingerprint**: computed once from the frozen `FingerprintNormalizer` v1 output of the unmasked body (independent of the parser's matching normalization, so rule updates never change it, FR-023), plus `ref_hash` and `ref_amount_hash`, never recomputed (re-parse cannot recover masked references); then mask (digit runs of 12+ and Egyptian mobile numbers, all but the last four) and seal raw text.
4. **Duplicate gate** (`SmsImportRepository.findKnown`, `CheckDuplicates`): fingerprint or tier-2 hit against pending rows and tombstones collapses silently; tiers 3 and 4 attach a warning to the pending item (re-run at review open and on Add).
5. **Stage**: insert the pending row in a batch transaction; unique `(fingerprint)` makes a repeat a no-op. Never touches transactions or finance tables (asserted by test: zero saved records without a confirm call, SC-002).
6. **Catch-up**: `SmsCatchUpTrigger` (single-flight, sharing a `ScanCoordinator` mutex with the explicit scan so the two never run together, 60 s debounce, defers while locked, checks capability, enabled and permission between pages), 24 h cursor overlap, then expire/purge and rule-version re-parse. **Foreground only (FR-008a)**: `RunCatchUpScan` and `RunInboxScan` also stop between pages when the lifecycle state is not `resumed` (an explicit scan cancels with `cancelled=true` and keeps its cursor). **App Lock race**: `AppLifecycleObserver._onResumed` locks asynchronously when the timeout read has not resolved (`:143-147`), so the trigger waits for a post-frame callback before reading `isLocked` and re-checks it between pages. Scan and enable flow bypass the debounce, are cancellable and leave staged items intact on cancel (FR-007).
7. **Review/save**: `AddImportedTransaction` -> `SmsImportRepository.confirm` runs one DB transaction: re-read row and require `pending`, call `addSmsSourcedTransaction` or `addSmsSourcedEntry` with key `sms-import:<pendingId>`, write the tombstone, mark `added`, null `raw_blob`, update the learned mapping if the category differs from the suggestion. A `Left` throws `_ConfirmAborted` to roll back everything (FR-075a, FR-099). Probable-duplicate re-check (`CheckDuplicates`) with edited values runs before the transaction; a new match returns a result the UI turns into the side-by-side sheet.
8. **Ignore / duplicate-decision / mute / undo**: `IgnoreImport` (single or selection, tombstone + null blob), `CloseAsDuplicate`, `MuteSender` (deletes that sender's pending rows in the same transaction, no tombstones as in FR-078; repository test), `UndoIgnore` (removes tombstone, message returns only on re-scan/re-paste; the UI says so).
9. **Retry**: a failed Add leaves the row pending and enables retry with the same idempotency key; an interrupted scan reports processed count and resumes from the stored cursor; transient `StorageUnavailable` is retryable without partial state.
10. **Permission management**: `EnableSmsImport` (explanation acknowledged -> `RequestSmsPermission` -> classify -> set `is_enabled`), `DisableSmsImport` (stops catch-up immediately, offers delete-all-pending), `GetSmsPermissionStatus` on resume (revoked -> UI "off" state, pending kept reviewable, no re-prompt, FR-012).
11. **Maintenance**: `ExpirePendingImports` (30-day expiry creates tombstone, nulls blob, retains only the six Undo-list fields on ignored/expired rows; deletes decided rows after 30 days and tombstones after `purge_after`), `ReparsePending` (compares `rule_version`, re-parses only readable pending rows, replaces parsed-field columns only, skips an item leased by an open review via `ReviewLeaseRegistry`; a masked amount is treated as unreadable, never as a different value).

## Presentation plan

- **Screens** (specs in `contracts/ui-contract.md`; 8 pages, 8 Cubits): `BankMessagesPage` (pending list, scan summary, permission/state banner), `EnableBankMessagesPage`, `ImportReviewPage`, `PasteBankMessagePage`, `IgnoredImportsPage` (Undo), `MutedSendersPage`, `LearnedCategoriesPage`, `BankMessagesSettingsPage` (`/settings/bank-messages`: window 7/30/90, cash-withdrawal preference, counters, delete pending). Entry points: Settings tile, Home quick action (flag `kBankMessageImportFeatureEnabled`), Home count card shown only while pending items exist, one-time onboarding card. **Home ordering (PRODUCT principle 2/73, people come first)**: the three new Home surfaces (quick action, count card, onboarding card) sit below the people summary; a dashboard ordering test asserts it.
- **Permission UI** (`SmsPermissionBanner`, `EnableBankMessagesPage`): explanation sheet before the system prompt (what is read, what is never done, how to turn off); distinct cards for denied (can ask once more), permanently denied and restricted-by-OS (numbered steps for Android 15 plus "Open App info"), revoked (automatic import is off; pending kept; re-enable or paste); never auto-prompting. Paste/share fallback is always offered.
- **Review decision (reuse vs full form)**: build a **dedicated review screen** composed of existing field widgets, not the manual transaction or finance entry forms. Reused: `AppTextField` (note, amount with `CurrencyFormatter.parse` like `CandidateEntryCard`), `AppDateField`, `CurrencyPicker`, `CategoryPickerField`, `PersonPickerField`, `AppCard`, `AppConfirmDialog`, promoted `ConfidenceIndicator`, new core `ImportedFromSmsLabel` (copy "Imported from a bank message", Arabic "مستورد من رسالة بنكية"; the single wire value stays `'sms'`). Not reused: `FinanceEntryFormPage`/`TransactionFormPage` and their Cubits. Justification: FR-044 forbids opening or modifying them, SC-012 requires their behavior unchanged, and review needs states the forms lack (inferred markers, per-field confidence, read-only time, show-original, duplicate sheet, advance-to-next). Validation is reused by calling the same domain validators the write paths enforce, so rules are not duplicated (FR-044).
- **Editing**: type switch expense/income/given/received swaps the required field (category vs person); Repayment and occasion contribution are not offered; amounts and currencies follow the existing limits; the note is never prefilled with raw text (optional "use merchant" action); the SMS time of day is shown read-only with the "only the day is saved" statement (FR-058); original-currency context is read-only (FR-053).
- **Duplicate warning**: a new `ProbableDuplicateSheet` (ui-contract §3.6; renamed away from `DuplicateWarningSheet`) shows the existing record (type, amount, date, source label) beside the pending item with three actions: Add anyway (override, not a failure, FR-063), It's the same - don't add, Cancel. The existing `DuplicateWarningSheet` in `lib/features/transactions/presentation/widgets/` is person-scoped and is not changed; it is only visually referenced. Re-check on Add can raise the sheet late.
- **States**: loading (scan progress with count and cancel; skeleton rows), empty (explains what appears here and how to get items: scan, paste, share), error (typed, localized, retry where useful, never content), success (scan summary with content-free counts; after Add advance to next item, snackbar with Undo is not offered because Add is not undoable here; the saved record is edited through normal history), offline is not a distinct failure because nothing needs the network.
- **Lists and batch**: `ListView.builder`, stable keys by pending id, low-confidence first ordering, multi-select for Ignore only (FR-046, FR-064), confirm dialog for batch ignore. If `BankMessagesCubit` grows beyond list, scan and selection, selection moves to a child Cubit.
- **Paste field privacy**: the paste `TextField` sets `enableIMEPersonalizedLearning: false`, `autocorrect: false`, `enableSuggestions: false` so the keyboard never learns message content; Paste and review state classes override `toString` to redact.
- **Cross-cutting**: screens covered by screen-capture protection and App Lock (FR-079); `WidgetsBinding` side effects only through `BlocListener`; unsaved-edit prompt (FR-047).

## Security plan

- **Data minimization**: sender filter inside the Android query selection (non-bank bodies never read); unrecognized paste/share stores nothing; only last four digits retained; balances and OTPs never persisted; tombstones hold two keyed hashes and no content.
- **Raw SMS**: masked (`SmsMasker`: digit runs of 12+ in ASCII, Arabic-Indic or Eastern Arabic-Indic digits joined by single spaces or hyphens, and every Egyptian mobile number, keep only the last four; the mobile regex runs on a digit-normalized shadow copy with an index map; masker tests cover amount-adjacent runs such as `EGP 1500 01012345678`) then sealed with AES-256-GCM, AAD = pending id, format version byte, random nonce; blob is opened only for "Show original" and re-parse (hashes were taken before masking and are immutable); nulled on Add, Ignore, duplicate decision and expiry.
- **Keys**: two independent random 32-byte keys in the existing secure storage (Android: RSA-OAEP-wrapped AES-GCM under a non-exportable Keystore key; iOS: `first_unlock_this_device` Keychain items, so no backup restores a usable key), generated lazily and single-flight, cached per process by `SmsKeyStore`, and stored in a **dedicated** `FlutterSecureStorage` instance with `resetOnError: false`, so an SMS key error can never wipe the PIN hash, cloud session or AI key (analysis M7). Key loss (any secure-storage error or GCM tag failure) means purged: blob nulled on first failure, "Show original" unavailable, parsed fields kept (FR-074a, FR-045). Both keys deleted by `PurgeSmsImportKeys` in Delete-all-data.
- **Logs and leak paths**: the feature performs no logging at all; a static guard test fails on `print(`, `debugPrint(`, `developer.log`, `Log.` in `lib/features/sms_import` and, for Kotlin (`SmsPlugin.kt`, `ShareTargetActivity.kt`), also `println(`, `printStackTrace(` and `System.out`. Counts are persisted, not logged. Exceptions crossing the channel carry codes only. `CurrencyFormatter.parse` throws `FormatException('Invalid amount: $input')`: the parser swallows it into `Unreadable` and never copies `e.message` into a Failure. The leak suite captures `Zone` `print`, `FlutterError.onError` and `debugPrint`, and asserts `AppDatabase` is not opened with `logStatements` (the app has no `BlocObserver`). Channel and logcat carry codes only (activity-manager logs show "(has extras)" without values); backups hold parsed fields only, accepted by the spec.
- **Analytics and crash reporting**: none exist for this feature and none are added (FR-100). The app has no crash-reporting SDK; the guard test also asserts `sms_import` imports none. Diagnostics are the content-free counters of FR-102.
- **Sync**: staging tables are `localOnlyTables`; `SyncOutbox` payloads after Add carry only confirmed fields plus `import_source`; `note` stays null unless the user typed it; mapper tests assert the exact shape.
- **Deletion**: Delete-all wipes the five tables and both keys; disabling offers delete-pending; CSV export is untouched and a regression test fails if `ExportUserData` gains an SMS dependency or a provenance header.
- **Permission lifecycle**: READ_SMS only (FR-073); never at startup (FR-002); revocation detected on resume; the off build contains no SMS permission (CI manifest and APK assertions) yet still has the share target; no receiver, no `RECEIVE_SMS`.
- **Exposure**: share target exposes nothing to other apps (FR-080); the text travels `ShareTargetActivity` -> in-process holder -> `SmsPlugin` and is never put in the `MainActivity` Intent, a route URL or restoration state; App Lock gates display; secure-flag screen protection on list, review and paste. Android Auto Backup restore behavior (secure-storage reset) is a pre-existing effect, documented under Unresolved Risks.

## Localization plan

- Keys prefixed `smsImport` in `app_en.arb` (template) and `app_ar.arb`, each with `@key` descriptions and typed placeholders, **added in the same step as the screen that uses them** (steps 13-17, so each step ends green with the hardcoded-string guard); step 18 is a review pass only. Parity test cloned from the AI one, extended to compare plural/select category sets for `smsImport*` keys only (the existing `syncStatusPending`, `app_ar.arb:368`, lacks `many`; it is left alone and filed as a separate follow-up).
- **Plurals**: ICU `plural` with `=0/=1/other` in English and full `=0/=1/=2/few/many/other` in Arabic (every new key writes all six; the full-set precedent is `app_ar.arb:284`) for scan summary ("N bank messages found, M need review"), "N suggestions expired", "N selected", paste summary (recognized/skipped), batch-ignore confirm. ICU `select` for type-dependent copy (given/received/expense/income).
- **Numbers, dates, currency**: amounts only through `CurrencyFormatter(currency, locale)` (Western digits in Arabic by existing decision); dates and the read-only message time through `AppDateFormatter`/`numeralLocaleFor`; no concatenation. Eastern Arabic-Indic digits normalized in parsing (step 1), never relied on for display.
- **Direction**: app RTL/LTR from locale; original message text rendered in its own direction via first-strong detection, independent of app locale (FR-091); mixed Arabic/English merchant names wrapped with the existing bidi isolation pattern; icons that imply direction mirrored.
- **Errors and permission copy**: one ARB key per row of the spec's error table and per permission state (denied, permanently denied, restricted by OS with Android 15 steps, revoked); no technical text, no content.
- **Guards**: hardcoded-string source-grep over `presentation/`, RTL+dark widget test per screen, large-text and 48dp checks.

## Testing plan

| Layer | What | Where |
|---|---|---|
| Unit: parsing | normalization (digits incl. U+06F0, separators, tatweel/alef/ya/ta marbuta, bidi controls), amounts (exact minor units, >2 decimals, >12 digits), currencies (word and symbol map, unknown ISO), dates (Arabic Egyptian and Levantine months, 2-digit year, year inference at year edge, 12/24 h), masking (separators, Arabic digits, grouped amounts untouched, amount-adjacent runs such as `EGP 1500 01012345678`, mobile rule on Arabic-Indic digits and `010 1234 5678`, hashes unchanged by re-parse and a masked amount re-parses as unreadable), splitter bounds | `test/features/sms_import/data/parsing/` |
| Parser fixtures (corpus) | one loader iterates `test/fixtures/sms/**`; per-bank accuracy gate (>= 95% of amount/currency/direction/date, 100% noise rejected), `synthetic: true` on every file, no 16-digit run or real-looking mobile number, cross-bank non-match invariant, pinned `rule_version` | `test/features/sms_import/data/parsing/corpus_test.dart` |
| Bank fixtures | per-bank Arabic, English and mixed samples for each kind (card purchase, ATM, transfer in/out, InstaPay, salary, bill, refund, fee), OTP, promo, decline, balance inquiry, pending authorization; malformed: empty, truncated, mixed language, huge, missing amount/date, ambiguous direction, multiple amounts, unknown currency, spoofed sender, unsupported bank | `test/fixtures/sms/<bank>/`, `_noise`, `_paste`, `_cross` |
| Domain | confidence calibration (incl. missing required field -> Low, paste without date/currency always Low), permission classifier table, duplicate tiers 1-4 and edge of the one-day window, mapping defaults, suggestion priority, status machine | `test/features/sms_import/domain/` |
| Data | v13 migration (committed v11 fixture: 11 -> 13 in one open and 12 -> 13; no existing row changed; idempotent re-open), table classification, data wipe, DAO/repository (idempotent staging, atomic confirm rollback on inner `Left`, retry after type switch, expiry, undo, purge, `MuteSender` deletes that sender's pending rows without tombstones, undo-list scrub: ignored/expired keep six fields, added/duplicate shells keep none), crypto round trip with fixed keys/nonces, tamper/AAD-mismatch, key-loss purge, HMAC determinism | `test/core/database/`, `test/features/sms_import/data/` |
| Channel contract | `PlatformSmsInboxGateway` argument shaping, page boundaries, `permission_denied`, empty page; share events once-only; `PlatformSharedTextSource` works in a capability-off Android build (no inbox/permission call made) | `test/features/sms_import/data/platform/` |
| Lifecycle | fake lifecycle reports `paused` mid-scan and no further `queryInbox` call happens (explicit scan: `cancelled=true`, cursor kept); trigger waits for a post-frame callback before `isLocked` and re-checks between pages; `shared_text_router_test.dart` waits for unlock and consumes once | `test/features/sms_import/presentation/`, `.../data/` |
| Cubit | enable/permission, pending list (ordering, selection, batch ignore), review (edit, validate, type switch, double-tap Add, unsaved prompt, advance), paste, ignored/undo; exact state transitions | `test/features/sms_import/presentation/cubit/` |
| Widget | each screen's loading/empty/error/success; permission cards incl. restricted guidance; paste reads clipboard only on tap (mocked `flutter/platform` channel records zero calls before tap); duplicate sheet; confidence/duplicate semantics labels; 48dp; RTL x LTR x light x dark; large text | `test/features/sms_import/presentation/` |
| Permission | denied, permanently denied, restricted-blocked inference, revoked on resume, no prompt at startup, only READ_SMS | classifier + cubit + manifest script |
| Duplicate | re-scan, re-paste, re-share, byte-identical bodies, fee SMS sharing a reference not collapsed, probable across manual/OCR/SMS, both-refs-different no warning, re-check on Add | domain + repository tests |
| Offline | every flow with no connectivity fake; Add then sync later | repository + `SyncHarness` |
| Sync | `import_source` mapper shape (non-null only), pull preserves local value when key absent **and when present but null** (same through `ConflictResolver.keepTheirs`), v1.0.1 frozen mappers (with their `SyncWire` helpers frozen too) accept post-027 rows, two-device provenance, legacy edit-push keeps field; pgTAP 027 | `test/core/sync/legacy/`, `test/features/*/data/sync/`, `supabase/tests/027_*` |
| Security/leak | sentinel message through scan, paste, share, review, Add, Ignore, expiry, re-parse: captured logs (`debugPrint`, `Zone` print, `FlutterError.onError`), `AppDatabase` not opened with `logStatements`, outbox rows, CSV export, `SELECT *` over every table (TEXT and BLOB), `raw_blob` NULL after decision and not plaintext while pending; static no-logging guard (Dart plus Kotlin `println(`/`printStackTrace(`/`System.out`); masking; paste `TextField` privacy flags; redacting `toString`; Delete-all clears all new tables and both keys; no `ai_assistant` coupling | `test/features/sms_import/privacy/` |
| RTL and l10n | ARB parity (+ plural category sets), hardcoded-string guard, per-screen RTL/theme | `test/features/sms_import/presentation/` |
| Performance | 500-message scan <= 5 s budget; duplicate maps; a profile-mode run on the reference device for SC-005 | `test/performance/sms_ingest_scale_test.dart`, `integration_test/sms_ingest_device_benchmark_test.dart` |
| Analysis remediation | golden fingerprints across rule changes; cross-path fingerprint with captured envelopes; reversal hint + matched record; in-message fee item; own-transfer pair; foreign-amount probable match; paste year rollover; DST and time-zone day; dashboard totals per kind; SC-014 90-day re-scan; `ScanCoordinator` exclusion | `test/features/sms_import/**`, `test/features/dashboard/` |
| Regression | dashboard ordering (new cards below the people summary), `NumeralParser` whole-suite run with the U+06F0-06F9 cases, manual transaction/finance forms, OCR flow and its moved confidence tests, `FindPossibleDuplicate`, export, delete-all, notification-tap routing, App Lock gate | existing suites must pass unchanged (SC-012) |
| Integration (device) | paste -> review -> Add; Android scan with fake gateway -> Ignore; duplicate warning; permission-off state; share cold/warm with App Lock | `integration_test/sms_import_flows_test.dart` |

## Implementation Order

Dependency-aware; steps 5-6 can run in parallel with 3-4, and 10-11 in parallel with 5-9, because they meet only at ports and fakes. Each step ends green on `flutter analyze` and `flutter test`. Risk: L/M/H. The constitution amendment is the pre-approval gate above, not a step.

### Step 0: Spikes S1-S4
- **Objective**: Settle the four device-only unknowns before the dependent steps.
- **Files**: throwaway branch of `AndroidManifest.xml`/`SmsPlugin.kt`/`ShareTargetActivity.kt`; notes recorded in a short addendum to research.md (no production code kept).
- **Depends on**: none. (The constitution amendment is an owner gate before `/speckit.tasks`, not part of this step.)
- **Details**: S1 share while the app is backgrounded from Google Messages through the baseline `ShareTargetActivity`; verify `dumpsys activity activities` shows exactly one `MainActivity` instance. S2 on API 26-36 emulators and one real device, test `UPPER(address) IN (...)`, then `COLLATE NOCASE`, `LIKE`, two-phase read. S3 confirm the merged-manifest path for `processReleaseMainManifest`, and whether AGP 8.11 `androidComponents.onVariants { it.sources.manifests.addStaticManifestFile(...) }` works (then use one overlay file and no module; else the manifest-only `:sms_capability` module). S4 on Android 14/15 real devices (incl. an Egyptian-market OEM) check the "no dialog shown" inference and restricted-settings steps; check whether Play Protect enhanced fraud protection applies in Egypt (OQ5). S5 capture copy and share output from Google Messages, Samsung Messages and iOS Messages (single and multi-select) and re-author the formats as synthetic fixtures (FR-017a).
- **Tests**: spike results written down with device/OS list.
- **Risk**: M, S2 or S4 may change Decisions 1 and 2 and the release shape.
- **Rollback**: discard spike branch.

### Step 1: Promote FieldConfidence and fix NumeralParser
- **Objective**: Shared confidence model in core and Eastern Arabic-Indic digits support, with no behavior change elsewhere.
- **Files**: `lib/features/ocr/domain/entities/field_confidence.dart` -> `lib/core/confidence/field_confidence.dart`; `confidence_indicator.dart` -> `lib/core/design_system/`; 8 lib importers (candidate entry mapper/parser/entity, text recognition service and impl, repository impl, candidate_entry_card) and 10 test importers; `lib/core/money/numeral_parser.dart`.
- **Depends on**: none (parallel with step 0).
- **Details**: `git mv`, fix imports only; extend `toWesternDigits` to U+06F0-06F9 keeping separator mapping, as its **own commit**. `NumeralParser` has 23 importers in two roles: input parsing (8 form cubits, OCR, rate input), which becomes strictly more permissive, and post-processing of `intl` output, which never emits U+06F0 for the supported `en`/`ar`/`ar_u_nu_latn` locales. No test or source contains U+06F0-06F9 today. Move `confidence_indicator_test` and the confidence tests under core.
- **Tests**: all OCR suites unchanged; new `numeral_parser_test` cases for `۱۲۳٫۴۵`, mixed scripts and an unchanged Western string; `ocr_rtl_theme_test` still passes; run the whole suite.
- **Risk**: L (the U+06F0 change is strictly more permissive and has no existing user), mechanical.
- **Rollback**: revert the commit (two independent commits: promotion, numerals).

### Step 2: Domain entities, enums and ports
- **Objective**: The pure domain skeleton so every later step compiles against stable contracts.
- **Files**: `lib/features/sms_import/domain/**` (entities, services, rules, repositories, use-case shells), `lib/core/provenance/import_provenance.dart` (`ImportProvenance`), `importSource` on the transactions and finance entities.
- **Depends on**: 1 (confidence types), data-model.md and `contracts/domain-interfaces.md`.
- **Details**: entities and failures as specified there; `overallConfidence` and `classifySmsPermission` implemented here (pure, test-first); no Drift or Flutter import in domain (guard test greps imports).
- **Tests**: confidence calibration tables, classifier table, status machine, entity equality.
- **Risk**: L.
- **Rollback**: delete the feature folder; entity field additions are optional/null.

### Step 3: Normalization, masking, parser engine, corpus harness
- **Objective**: A deterministic engine and the corpus loader that gates every bank.
- **Files**: `data/parsing/{sms_text_normalizer,sms_masker_impl,sms_message_splitter,rule_based_sms_parser,sms_parser_registry,select_parse,suggest_for,bank_profile,sms_template,generic_profile}.dart`; `test/features/sms_import/data/parsing/*`; `test/fixtures/sms/_noise|_paste|_cross`.
- **Depends on**: 1, 2, `contracts/parser-contract.md`.
- **Details**: test-first. Normalization pipeline (bidi/zero-width strip, whitespace, digits, Arabic folding for matching, lowercase); masker (mobile regex on a digit-normalized shadow copy with an index map, single-space/hyphen separators, amount-adjacent-run tests); amounts via `CurrencyFormatter.parse` (the `FormatException` is swallowed into `Unreadable`, `e.message` never copied); manual date construction with round-trip check, year inference through `AppClock`; classification; generic profile capped at Medium; precedence function with no field merging; corpus loader that asserts `synthetic: true`, no 16-digit runs, cross-bank invariant, pinned versions.
- **Tests**: everything in the parsing and corpus rows of the testing plan, noise and malformed cases (huge, truncated, hostile input must not throw out of the engine).
- **Risk**: M, regex over hostile or huge input (catastrophic backtracking); mitigated by the 10,000-char bound, anchored non-nested quantifiers and a worst-case timing test.
- **Rollback**: pure code, no persisted effects; remove registry entries.

### Step 4: Bank profiles, one at a time
- **Objective**: Ship only banks that pass SC-001 on the corpus.
- **Files**: `data/parsing/profiles/<bank>_profile.dart` and `test/fixtures/sms/<bank>/`.
- **Depends on**: 3; real anonymized samples from the owner (OQ2/OQ3).
- **Details**: order by sample availability (NBE, Banque Misr, CIB first; then QNB Alahli, Banque du Caire, AAIB, InstaPay). Per bank: sender IDs, signatures, templates (Arabic, English, mixed), kind rules, merchant keyword rules, `maskThreshold`, `defaultCurrency`, `dateOrder`; version 1. A bank that misses the gate stays out of the registry and falls to generic.
- **Tests**: per-bank accuracy gate, noise rejection 100%, cross-bank non-match, version pin.
- **Risk**: H, accuracy depends on real-world sample quality and bank template drift; mitigated by the gate, versioning and generic fallback.
- **Rollback**: remove one registry line; items already staged re-parse on next rule change.

### Step 5: Drift v13, migration, local-only, data wipe
- **Objective**: Persist staging safely with an additive migration.
- **Files**: `app_database.dart` (5 tables, `import_source` on two tables, `schemaVersion = 13`), `migrations/v13_sms_import.dart`, `migration_guards.dart` (`ensureColumn`), `lib/core/sync/sync_entity_type.dart` (`localOnlyTables`), `data_wipe.dart`, regenerated `app_database.g.dart`.
- **Depends on**: 2, `data-model.md`.
- **Details**: one transaction, every object guarded, no row read; update table classification and wipe in the same change; leave `v12_finance_entry_audits.dart` alone; update `schemaVersion` assertions in existing tests.
- **Tests**: `v13_migration_test` (v11 fixture to 13 in one open, 12 -> 13, idempotent, rows untouched, new columns NULL), `test/core/sync/table_classification_guard_test.dart`, `data_wipe_test`, `watch_tables_test`.
- **Risk**: M, schema change on a live user DB; mitigated by additive guarded steps and the fixture upgrade test.
- **Rollback**: pre-release only: revert the commit. After release, never edit v13; fix forward with v14.

### Step 6: Crypto, key store, masking integration
- **Objective**: At-rest protection and keyed hashes behind ports.
- **Files**: `data/crypto/{aes_gcm_raw_text_vault,hmac_fingerprint_hasher,secure_storage_sms_key_store}.dart`; `pubspec.yaml` (`pointycastle` annotated); `PurgeSmsImportKeys` use case.
- **Depends on**: 2.
- **Details**: blob format `0x01 | nonce(12) | ciphertext | tag(16)`, AAD = pending id; two keys generated single-flight with write-then-read-back; any failure maps to "unreadable -> purge"; run `dart pub deps` to confirm 4.0.0 resolves; fixed-key/nonce test hooks.
- **Tests**: round trip, tamper, AAD mismatch, key loss, concurrent first use, HMAC vectors, determinism across paths.
- **Risk**: M, crypto misuse and secure-storage behavior after backup restore; mitigated by vectors and the in-memory storage with throw switch.
- **Rollback**: revert; no data exists before step 7 writes.

### Step 7: SmsImportRepository, duplicate lookup, ingestion pipeline
- **Objective**: Stage messages idempotently with all duplicate tiers.
- **Files**: `data/datasources/{sms_import_dao,sms_duplicate_dao}.dart`, `data/models/*`, `data/repositories/*`, `SmsIngestionService`, `ParseMessages`, `CheckDuplicates`, `SmsDuplicateLookup` impl.
- **Depends on**: 3, 5, 6.
- **Details**: batch in-memory duplicate maps over `[minDate-1d, maxDate+1d]`; calendar-arithmetic date window; unique fingerprint insert; mask-then-seal; tombstone checks for tiers 1-3; direction group matching in Dart; never writes to transactions or finance (asserted).
- **Tests**: duplicate tier tests, idempotent re-ingest across origins, malformed message isolation, SC-002 "zero saved without confirm", benchmark skeleton.
- **Risk**: M, subtle duplicate semantics (tier 3 stop rule, fee SMS with shared reference).
- **Rollback**: revert; staged rows are local-only and purgeable.

### Step 8: SMS-sourced write paths, provenance, audit
- **Objective**: The single review gate into saved records.
- **Files**: `transactions_repository.dart`/`_impl.dart` (`addSmsSourcedTransaction`), `finance_repository.dart`/`_impl.dart` (`addSmsSourcedEntry`), `money_transaction.dart`, `finance_entry.dart`, `AddImportedTransaction` and `SmsImportRepository.confirm`.
- **Depends on**: 5, 7.
- **Details**: modeled on `addOcrSourcedTransaction`; written in the caller's transaction; idempotency key `sms-import:<pendingId>`; `created` audit row identical to manual creation; `import_source = 'sms'`; people-ledger rows keep `source = 'manual'` (FR-086); documented "only the SMS repository calls this"; `_ConfirmAborted` rollback.
- **Tests**: atomic confirm (kill-before/after commit simulation), double-tap Add, retry after type switch, audit row present, existing form/OCR tests unchanged.
- **Risk**: H, touches the two core money write paths; mitigated by additive methods only and full regression suite.
- **Rollback**: revert; no existing method signature changed.

### Step 9: Sync mapper provenance, migration 027, compat tests
- **Objective**: Provenance travels optionally without breaking v1.0.1.
- **Files**: both sync mappers; `supabase/migrations/20261006100000_027_import_source.sql`; `supabase/tests/027_import_source.test.sql`; `test/core/sync/legacy/*`; `ci.yml` UTC re-run list.
- **Depends on**: 8 (column semantics), `contracts/sync-wire-027.md`.
- **Details**: 027 = column + check on both tables, `create or replace sync_push` equal to 026 plus `'import_source'` in the two `v_business` arrays, comment naming 027; pull functions unchanged. Mappers add the key only when non-null and read it as `importSource: Value((json['import_source'] as String?) ?? existingLocal?.importSource)` in both mappers: a non-null local value is never downgraded to null (provenance is never legitimately cleared), so a post-027 pull of a pre-027 row (key present, null) or a `keepTheirs` cannot wipe the local label. Freeze v1.0.1 `fromWire` bodies verbatim from `c86e2df` **together with the `SyncWire` helpers they call** (v1.0.1 uses `SyncWire.parseInstant(json['occurred_at'])`, current code uses `parseLocalDay`) in `test/core/sync/legacy/v101_mappers.dart`, or the "verbatim" test silently runs current semantics.
- **Tests**: pgTAP (a) upsert persists, (b) v1.0.1-shaped update leaves value intact, (c) old rows NULL, (d) check rejects `'x'`, (e) pull includes key; legacy compat test with an invented future key; mapper tests "pull with key present and null keeps local `'sms'`" and the same case through `ConflictResolver.keepTheirs`; two-device `SyncHarness` test; exact-shape mapper tests stay green.
- **Risk**: H, server change on a live DB and a bad `sync_push` replacement would affect every device; mitigated by diff against 026 body, pgTAP, and deploy order.
- **Rollback**: forward-fix only (a follow-up migration restores 026's function body; the column may stay). App-side revert is a mapper revert. If the app ships before 027, rows saved in that window lose provenance on other devices: an accepted, written-down loss (cosmetic, no data lost; the re-enqueue repair is not built in v1, see sync-wire-027 §4).

### Step 10: Capability gate and CI manifest assertion
- **Objective**: FR-001 enforced mechanically; this step also declares READ_SMS, which step 11's device verification needs.
- **Files**: `android/app/build.gradle.kts`, the READ_SMS overlay (S3 outcome: `android/app/sms_capability/AndroidManifest.xml` through `androidComponents.onVariants`, or the manifest-only `android/sms_capability/*` module with an `android/settings.gradle.kts` include), `tool/check_merged_manifest.sh`, `.github/workflows/{ci,release-android}.yml`, `SmsCapability` derivation (`readSmsDeclared && Platform.isAndroid`).
- **Depends on**: 0 (S3 only).
- **Details**: one switch, `DAFTARY_SMS_IMPORT`, provider-based env read with `-P` fallback; no Dart const and no `--dart-define` (so no two-knob mismatch); CI job runs the script with env unset and set; release workflow sets the env and asserts with `aapt` on both APKs that READ_SMS is present and RECEIVE_SMS/SEND_SMS/READ_PHONE_STATE absent; also asserts no SMS receiver and the SEND filter on `ShareTargetActivity` present. Both APKs share a `versionCode`, so installing one over the other is allowed and pending rows survive it.
- **Tests**: the script itself in CI; capability derivation unit test; `feature_flags_test` for `kBankMessageImportFeatureEnabled`.
- **Risk**: M, Gradle/AGP path drift and release pipeline edits; mitigated by running the script in PR CI.
- **Rollback**: remove the env from the release workflow to ship an SMS-free APK; the overlay stays inert.

### Step 11: Android Kotlin plugin and share target
- **Objective**: Inbox, permission and share-text hand-off behind the gateways.
- **Files**: `SmsPlugin.kt`, `ShareTargetActivity.kt`, `MainActivity.kt` registration only (launch mode untouched), `AndroidManifest.xml` (`ShareTargetActivity` with the SEND filter, `tools:node="remove"` markers), `data/platform/*`, `contracts/sms-platform-channel.md` conformance.
- **Depends on**: 0 (S1, S2, S4 outcomes), 2, 10 (READ_SMS must be declared to verify `queryInbox` and `requestPermission` on a device).
- **Details**: thin Kotlin (OS calls, argument shaping); selection per S2 outcome; request code 0x5A11; `dialogShown` from activity pause; install source helper; `SmsPlugin` registered in every Android build and the share path never depends on the capability; share text once-only with 10,001-char truncation flag through the in-process holder; no logging; typed error codes.
- **Tests**: Dart channel contract tests with canned replies (including a capability-off build where sharing still works); device quickstart scenarios; static no-logging guard on both Kotlin files.
- **Risk**: H, only device-verifiable and OEM-variable.
- **Rollback**: unregister the plugin; `Unavailable*` gateways keep the app working with paste.

### Step 12: Use cases, catch-up trigger, shared-text router
- **Objective**: Application workflow and lifecycle wiring.
- **Files**: remaining use cases, `presentation/sms_catch_up_trigger.dart`, `presentation/shared_text_router.dart`, DI registration, `lib/main.dart` startup block.
- **Depends on**: 7, 8, 11 (ports; fakes suffice for tests).
- **Details**: single-flight, 60 s debounce, run-on-unlock via injected `LockStatus` (post-frame callback before checking `isLocked`, re-check between pages), precondition chain, stop between pages on disable, revocation or a lifecycle state other than `resumed`; router waits for unlock then `go('/bank-messages/paste')` with text only in `SharedTextInbox`; `MuteSender` deletes that sender's pending rows in the same transaction.
- **Tests**: trigger tests with fake lifecycle and gateway (no run while locked, off, revoked; single-flight; debounce; a fake lifecycle reports `paused` mid-scan and no further `queryInbox` call happens), `shared_text_router_test.dart` (waits for unlock, consumes once), use-case tests for ignore/undo/mute (pending rows deleted, no tombstones)/expire/re-parse/enable/disable.
- **Risk**: M, lifecycle races with App Lock and startup (App Lock may lock asynchronously after resume) and a scan continuing after `paused`; mitigated by the post-frame check, between-page re-checks and the lifecycle test.
- **Rollback**: remove the two `start()` calls in `main.dart`.

### Step 13: Cubits
- **Objective**: Presentation state per screen.
- **Files**: `presentation/cubit/*` (the 8 Cubits of `ui-contract.md`), `lib/core/l10n/failure_message.dart` mapping, `smsImportError*` ARB keys.
- **Depends on**: 12.
- **Details**: immutable states (Paste and review states override `toString` to redact), single-flight Add and scan, review draft value object, duplicate sheet request as a state flag consumed through `BlocListener`, advance-to-next; the `SmsImportFailure` mapping and its ARB keys (en and ar, full Arabic plural set) land here.
- **Tests**: exact transition tests incl. double-tap, race on an already-decided item (`ImportAlreadyDecidedFailure`), cancellation; failure-to-message mapping; l10n parity for the new keys.
- **Risk**: M.
- **Rollback**: revert; no UI depends yet.

### Step 14: Settings entry and enable flow
- **Objective**: The opt-in path and permission UI.
- **Files**: `settings_page.dart`, `bank_messages_settings_page.dart`, `enable_bank_messages_page.dart`, `sms_permission_banner.dart`, `muted_senders_page.dart`, `learned_categories_page.dart`, routes, `smsImportSettings*`/`smsImportEnable*`/`smsImportPermission*`/`smsImportRestricted*`/`smsImportMute*`/`smsImportMappings*` ARB keys.
- **Depends on**: 13, 10, 11.
- **Details**: tile hidden when capability unavailable (paste entry remains); explanation sheet, request, state banners, App info deep link (`app_settings` imported with a prefix), onboarding card dismissal, mutes and learned-mapping management (mute confirms that pending items from that sender are removed), window selector, cash-withdrawal toggle, disable with delete-pending option. Keys are added in this step.
- **Tests**: widget tests for each permission state, no prompt at startup, tile visibility by capability, hardcoded-string guard green.
- **Risk**: M, restricted-settings UX is device-dependent (release gate).
- **Rollback**: hide tile through `kBankMessageImportFeatureEnabled`.

### Step 15: Paste screen
- **Objective**: The only iOS entry and the Android fallback/share landing.
- **Files**: `paste_bank_message_page.dart`, `paste_cubit.dart`, `smsImportPaste*`/`smsImportShare*` ARB keys.
- **Depends on**: 13, 12.
- **Details**: editable field with `enableIMEPersonalizedLearning: false`, `autocorrect: false`, `enableSuggestions: false`; Paste button (clipboard read inside `onPressed` only), bounds message, multi-message summary (recognized/skipped), not-recognized state with manual-entry link, shared text consumed from `SharedTextInbox` after unlock. Keys are added in this step.
- **Tests**: zero clipboard reads before tap, empty clipboard state, bounds, not-recognized stores nothing, RTL, keyboard-privacy flags, string guard green.
- **Risk**: L.
- **Rollback**: remove route and Home action.

### Step 16: Pending list, review screen, duplicate sheet
- **Objective**: The core review-and-Add experience.
- **Files**: `bank_messages_page.dart`, `import_review_page.dart`, `pending_import_card.dart`, `import_type_selector.dart`, `duplicate_comparison_card.dart`, `probable_duplicate_sheet.dart`, `bidi_text.dart`, `smsImportPending*`/`smsImportScan*`/`smsImportReview*`/`smsImportKind*`/`smsImportSuggest*`/`smsImportWarning*`/`smsImportDuplicate*`/`smsImportSemantics*` ARB keys.
- **Depends on**: 13, 8.
- **Details**: low-confidence-first list, tile semantics, review fields per the decision above, show-original with own direction, Add disabled until required fields valid, late duplicate sheet, advance to next, unsaved-edit prompt, scan progress with cancel. Keys are added in this step.
- **Tests**: widget tests for every state, semantics labels, 48dp, large text, RTL/dark; cubit tests already cover logic; string guard green.
- **Risk**: M, largest UI surface.
- **Rollback**: revert page files; staged data remains harmless.

### Step 17: Ignored/Undo list, Home entry and provenance label
- **Objective**: Reversibility, discoverability and the provenance label.
- **Files**: `ignored_imports_page.dart`, `ignored_imports_cubit.dart`, `quick_action_row.dart`, `home_page.dart`, `bank_messages_home_card.dart`, `lib/core/design_system/imported_from_sms_label.dart`, transaction and finance list/detail tiles, `smsImportIgnored*`/`smsImportHome*`/`smsImportProvenance*` ARB keys.
- **Depends on**: 13, 16.
- **Details**: 30-day list (ignored and expired, six retained fields only, no raw text), Undo with the "returns after re-scan or re-paste" copy; Home quick action (Paste on iOS, Bank messages on Android) behind `kBankMessageImportFeatureEnabled`; count-only card and onboarding card placed below the people summary (PRODUCT principle 2/73); `ImportedFromSmsLabel` reads "Imported from a bank message" for the single wire value `'sms'`. Keys are added in this step.
- **Tests**: dashboard widget tests (card absent at zero), dashboard ordering test, quick action routing, Undo removes tombstone, label semantics.
- **Risk**: L, Home is a high-traffic screen; keep dashboard cubit untouched (isolation test).
- **Rollback**: flag off.

### Step 18: Localization, accessibility and RTL review pass
- **Objective**: Parity and quality gates across all new screens. Keys already exist (added in steps 13-17); this is a review pass only.
- **Files**: `app_en.arb`, `app_ar.arb` (copy and plural corrections only), parity and string-guard tests, RTL/theme tests.
- **Depends on**: 14-17.
- **Details**: verify Arabic plural forms in full (`=0/=1/=2/few/many/other`) for every `smsImport*` plural, error-table and permission copy, announcements for progress and duplicate states, contrast checks in both themes; run `flutter gen-l10n`.
- **Tests**: parity (+ plural categories for `smsImport*` keys only; `syncStatusPending` is left alone and filed as a separate follow-up), hardcoded-string guard, per-screen RTL/theme, semantics.
- **Risk**: M, Arabic copy quality needs native review.
- **Rollback**: n/a (strings only).

### Step 19: Integration, privacy leak, performance, regression
- **Objective**: Prove the feature end to end and prove nothing else regressed.
- **Files**: `integration_test/sms_import_flows_test.dart`, `test/features/sms_import/privacy/*`, `test/performance/sms_ingest_scale_test.dart`, export/delete-all regression tests.
- **Depends on**: 0-18.
- **Details**: sentinel leak suite (incl. `Zone` print, `FlutterError.onError`, `logStatements` assertion), journeys, benchmark (decide `compute` vs UI isolate; add partial indexes only if missed), static guards (no logging in Dart and Kotlin, no AI coupling), quickstart.md walkthrough on Android 14/15 and iOS.
- **Tests**: this step is the tests; full `flutter test` and `flutter analyze`.
- **Risk**: M, performance on a low-end device may need isolate offload.
- **Rollback**: n/a; findings reopen earlier steps.

### Step 20: Release
- **Objective**: Ship in the binding order with the gates cleared.
- **Files**: `pubspec.yaml` version `1.2.0+4`, release workflow, `README.md` (feature, sideload and Play Protect notes), `PRODUCT.md` (add 023 to the module list: "on-device only, confirm per item"), release notes, quickstart.
- **Depends on**: 9 (server), 10, 19, gates OQ5/OQ6; 022 already released as v1.1.0.
- **Details**: (1) 025 -> 026 pushed and v1.1.0 (022) released first; (2) user pushes 027 (`supabase db push`; pushing it earlier together with 025/026 is harmless because the column is optional); (3) verify 027 with the pgTAP file against the target; (4) bump to 1.2.0+4 and tag v1.2.0 (it passes `app_version_at_least(...,'1.1.0')`; keep `DAFTARY_APP_VERSION` plain `x.y.z`); (5) CI builds both APKs with the capability and asserts permissions; (6) real-device checks of Play Protect (Egypt) and Android 15 restricted settings; (7) publish. Fallback if the Egypt check fails: two APKs (see Release Considerations).
- **Tests**: release checklist; manifest assertions in CI.
- **Risk**: H, Play Protect or OEM install blocking could stop installs and updates for all users.
- **Rollback**: stop the release or ship the SMS-free APK by unsetting the env; server 027 is additive and can stay.

## Architecture Decisions

All Phase 0 decisions stand as written in research.md (1-15). The ones that shape the plan, with their ADR-level reason:

1. **In-house Kotlin plugin over packages**: only way to filter by sender inside the provider selection (FR-020) with no extra permissions.
2. **Pure-Dart rule engine with Dart-const profiles**: compile-checked, diff-reviewable, testable without a device; rules ship with the app (no remote rules in v1).
3. **Corpus as the accuracy gate**: SC-001 is a `flutter test`, bank by bank.
4. **Staging in the main DB, raw text only as an encrypted blob**: preserves atomic Add and keeps parsed data as sensitive as saved transactions.
5. **Provenance as a new optional wire field, never a new `source` value**: old mappers throw on unknown enum values (022 P0 rule).
6. **Dedicated review screen reusing field widgets**: protects the manual forms (SC-012) while reusing validation.
7. **Sibling catch-up trigger**: keeps SMS work out of security code and `core` free of features.
8. **Capability by one Gradle switch and a READ_SMS manifest overlay, derived at runtime**: smallest mechanism that changes the merged manifest, is mechanically assertable and cannot disagree with the Dart side (no const, no `--dart-define`).
9. **Tombstones as keyed hashes (two: `ref_hash`, `ref_amount_hash`)**: needed so tiers 2 and 3 work without storing content.
10. **Plan-level additions**: the constitution amendment is an owner pre-approval gate (not a step); the `created` audit row plus `import_source` is the SC-013 traceability mechanism; the Egyptian mobile masking rule is adopted; `ShareTargetActivity` is the baseline share path; 023 releases as v1.2.0.

## Dependency Changes

| Change | Detail |
|---|---|
| `pubspec.yaml` | add `pointycastle: ^4.0.0` with the annotation from research Decision 15; `pubspec.lock` unchanged except the direct-dependency marker; verify with `dart pub deps`; version `1.2.0+4` at release |
| Pub packages added | none (no `permission_handler`, telephony, sharing-intent or crypto package) |
| Existing packages newly used by the feature | `crypto` (HMAC), `flutter_secure_storage`, `app_settings` (imported `as app_settings` to avoid the Drift `AppSettings` collision) |
| Gradle | READ_SMS manifest overlay: AGP `androidComponents` static manifest file if S3 confirms it, else the in-repo manifest-only `:sms_capability` module; no new Maven dependency; no test dependencies |
| Android manifest | `ShareTargetActivity` carrying the SEND `text/plain` filter (all builds); `tools:node="remove"` for six never-wanted permissions; READ_SMS only via the overlay |
| iOS / macOS | none |
| CI | new `android-manifest` job; `release-android.yml` env and `aapt` step (no dart-define); legacy sync tests added to the UTC re-run |
| Tooling | `build_runner` regeneration for Drift and injectable; `supabase test db` for 027 |

## Migration Requirements

**Client (Drift v13)**: schema 12 -> 13, additive, one guarded transaction (`ensureTable`, `ensureIndex`, new `ensureColumn`), five new local-only tables, nullable `import_source` on `money_transactions` and `finance_entries`, no default, no backfill, no index. Existing rows untouched and read as "not SMS". Local-only list, `DataWipe` and the guard tests update in the same commit. Tested by upgrading the committed v11 fixture to 13 in one open, by 12 -> 13, and by re-opening (idempotency).

**Server (migration 027)**: `supabase/migrations/20261006100000_027_import_source.sql`, additive: nullable `import_source text check (import_source in ('sms'))` on both tables; `create or replace function public.sync_push` equal to 026's body with `'import_source'` appended to the two `v_business` arrays; `sync_pull`/`sync_pull_v2` untouched (they already emit `to_jsonb(t)`). Never edits 021-026. Details in `contracts/sync-wire-027.md`.

**Deploy order (binding)**: 025 -> 026 -> (v1.1.0, 022) -> 027 -> v1.2.0 (023). 025/026 may still be undeployed (state at time of writing); 027 only needs their function text and its column is optional, so it may be pushed with them in one `supabase db push`, but v1.2.0 must not release before 027 is live. The user runs `db push`; the agent never does.

**Older apps (v1.0.1+) keep syncing**: pushes without `import_source` leave the column unchanged; pulls carry an extra key that v1.0.1 mappers ignore (they read named keys and no enum changed); proved by the frozen v1.0.1 mapper test and pgTAP case (b). If the app ships before 027, pushes still succeed (unknown key dropped), the record syncs without provenance, no data is lost (cosmetic; an accepted, written-down loss, no repair built). Pulls never erase local provenance (the mapper keeps a non-null local value over a null or absent key).

## Platform-Specific Work

- **Android**: `SmsPlugin.kt`, `ShareTargetActivity.kt` (baseline), manifest share filter and remove markers, READ_SMS overlay (S3: AGP static manifest file or `:sms_capability` module) with Gradle env wiring, CI manifest script, install-source and restricted-settings handling (S4), R8/proguard needs none (no reflection).
- **iOS**: none native; paste behavior and `Info.plist` untouched, verified by a review checklist item and the quickstart iOS check.
- **macOS**: compile-time "unavailable" ports only.
- **Build/release**: version bump to 1.2.0+4, APK permission assertions, Play Protect and restricted-settings gates.

## Testing Strategy (summary)

Test-first for the parser; corpus-gated banks; every port has a fake; Kotlin kept thin and verified by Dart channel-contract tests plus device quickstart; privacy proven by a sentinel leak suite across logs, outbox, CSV and a full-DB scan, and by static no-logging/no-AI-coupling guards; sync proven by frozen v1.0.1 mappers (with their `SyncWire` helpers), a two-device harness test, null-does-not-downgrade mapper tests and pgTAP 027; manifest proven by a CI script and an `aapt` check; RTL, l10n parity and accessibility per screen; 500-message benchmark; regression suites for forms, OCR, export, delete-all and App Lock must pass unchanged. Integration tests run on device, not in CI (existing convention). Full matrix: "Testing plan" above; runnable commands: `quickstart.md`.

## Release Considerations

- **Distribution**: the GitHub-release sideloaded APK is built with `DAFTARY_SMS_IMPORT=true` (FR-003); paste/share (the `ShareTargetActivity` and `SmsPlugin`) is in every Android build; Google Play is not a v1 target and READ_SMS approval there is not assumed.
- **Play Protect Egypt gate (OQ5)**: before release verify whether enhanced fraud protection blocks installing or updating an internet-sideloaded APK declaring SMS permissions on devices in Egypt. If it does, do not ship SMS in the only APK.
- **Android 15 restricted settings (OQ6)**: verify the App info -> overflow -> "Allow restricted settings" flow and the inference on real Android 14/15/16 devices incl. Egyptian-market OEMs; SC-015 (80% finish the enable flow in 2 minutes) is a usability gate.
- **Fallback: two APKs**: a standard SMS-free APK (env unset) and a "with bank SMS" APK (env set), built by a matrix in `release-android.yml` with distinct artifact names; same signing key, applicationId and `versionCode`, so installing one over the other is allowed and pending rows survive; each asserted by `aapt`. In the SMS-free APK sharing still works. Needs a note in README and release text; update path for existing users stays the standard APK.
- **Developer verification**: re-check Google's sideload developer-verification requirement for the signing identity before release.
- **Version bump (decided)**: `1.1.0+3` is untagged and 1.1.0 (022) is blocked only on 025/026, so bundling 023 would tie the 022 trust fixes to the Play Protect and Android 15 gates. 022 ships as **v1.1.0** first; 023 releases as **v1.2.0** (`version: 1.2.0+4`). 1.2.0 passes `app_version_at_least(...,'1.1.0')`; `DAFTARY_APP_VERSION` stays plain `x.y.z` (the savings-conflict gate in 025 depends on it).
- **Documentation**: README gets a feature note and the sideload caveats; `PRODUCT.md` lists 023 ("on-device only, confirm per item"). The constitution amendment is the pre-approval owner gate in the Constitution Check section, not a release item.
- **Server order**: 025 -> 026 -> (1.1.0) -> 027 -> 1.2.0; recorded in the release checklist and quickstart.

## Unresolved Risks

1. **Play Protect in Egypt (OQ5)** may block the sideloaded APK once it declares SMS; outcome unknown until verified, fallback is two APKs.
2. **Restricted-settings inference (OQ6/S4)** is a heuristic from an activity pause, varies by OS and OEM; wrong inference gives bad guidance.
3. **Real bank samples (OQ2/OQ3)** are not in hand; accuracy and the final bank list depend on owner-supplied anonymized messages. Banks that miss the gate ship as generic.
4. **Share launch path**: `ShareTargetActivity` is the baseline, so the second-engine hazard (two isolates, two Drift connections on one SQLite file, duplicate triggers) is designed out; S1 only verifies that exactly one `MainActivity` instance exists after a background share. An OEM that mishandles the trampoline's `NEW_TASK|CLEAR_TOP|SINGLE_TOP` start is the residual risk.
5. **S2 provider selection grammar** on OEM SMS providers; fallback ladder ends with a two-phase read that weakens the FR-020 wording.
6. **RCS/RBM** bank messages are unreadable through SMS permissions; coverage ceiling unknown.
7. **Android Auto Backup restore** resets all secure-storage entries (cloud session, PIN hash, AI key) because the manifest has no backup rules; pre-existing, out of scope, recommend a separate fix. `resetOnError: true` also means any secure-storage read failure wipes every entry (cloud session, PIN hash, AI key); `SmsKeyStore` caches keys per process to minimize reads.
8. **Bank template drift** decays accuracy; mitigated by versioned rules and fallback, not eliminated.
9. **Performance on low-end devices** (SC-005) is unmeasured; may need `compute` offload or indexes.
10. **Spec wording**: corrected by the 2026-10-07 analysis remediation (FR-001, FR-013, FR-016, FR-050, FR-059a/b), together with the new rules FR-017a, FR-024b, FR-030a and FR-051d (research "Analysis remediation").
11. **Foreground-only discipline (FR-008a)**: a scan could keep running in the isolate after `paused`; mitigated by stopping between pages when the lifecycle state is not `resumed` and by the lifecycle test (step 12).
12. **Catch-up racing App Lock**: `AppLifecycleObserver._onResumed` locks asynchronously when the timeout read has not resolved (`:143-147`); mitigated by a post-frame `isLocked` check and between-page re-checks (step 12).
13. **Two-APK fallback**: both APKs share a `versionCode`; users who switch between them keep pending rows, but a sideload downgrade of capability is possible and is documented in the release notes.
