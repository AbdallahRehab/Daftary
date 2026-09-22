# Implementation Plan: OCR Paper-to-Transaction Entry

**Branch**: `009-ocr-paper-entry` | **Date**: 2026-09-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/009-ocr-paper-entry/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Let the app's single local user photograph or upload a physical paper (e.g. a wedding cash-gift list), crop/rotate/enhance it, run fully on-device text recognition and deterministic (non-AI) text parsing to produce candidate entries (person, amount, direction, date, occasion, notes), and — critically — require the user to review, correct, and explicitly confirm each entry on a dedicated review screen before anything is persisted (constitution Principle X, spec FR-007). Confirmed entries are saved through the existing 001 `TransactionsRepository`/008 `OccasionsRepository` write paths (never a new, parallel save path), carrying a `source = ocr` marker and a durable link back to the originating `OcrScan`/`CandidateEntry` for audit. Implemented as one new Flutter clean-architecture feature (`ocr`) plus a small, additive extension to `transactions` (a `source`/`ocrScanId` field on `MoneyTransaction`, mirroring how 008 added `occasionId`), reusing `core/media`'s `AttachmentPickerService` (008) for capture/upload and adding a new `core/media` OCR/crop abstraction alongside it.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.47.0 (pinned via `fvm`, `.fvmrc`)

**Primary Dependencies**: `flutter_bloc`, `get_it` + `injectable`, `drift` + `sqlite3_flutter_libs` + `path_provider`, `fpdart`, `equatable`, `uuid`, `intl`, `go_router` (all existing, reused as-is). **New dependencies**: `google_mlkit_text_recognition` (on-device text recognition, Latin script model, Android + iOS, no network call — research.md Decision 1), `image_cropper` (native crop/rotate UI, Android + iOS), `image` (pure-Dart image processing, for the deterministic brightness/contrast enhancement step — research.md Decision 3). Reuses `core/media/AttachmentPickerService` (008) for the camera/gallery capture step itself rather than duplicating it. The new crop/enhance and text-recognition abstractions are **not** placed in `core/` (see Project Structure/Structure Decision — only genuinely multi-feature code belongs there per constitution Principle II, and today only this feature needs them).

**Storage**: Local SQLite via `drift`, same `AppDatabase`. Additive schema migration: (a) two new tables, `OcrScans` and `CandidateEntries`; (b) two additive, nullable columns on the existing `MoneyTransactions` table (`source` — defaulted `'manual'` for every existing/new non-OCR row — and `ocr_scan_id`), mirroring exactly how 008 added `occasion_id`/`counts_toward_balance`. `AppDatabase.schemaVersion` increments by 1 from whatever value it holds when this feature is implemented. Scan source images are stored as files in the app's private sandboxed storage directory (via `path_provider`, already used for the SQLite file and for 008's attachments) — never uploaded (FR-019, FR-023).

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail` (Cubit unit tests, with the OCR engine and cropper abstracted behind fakeable interfaces per research.md Decision 1/4), `integration_test` (capture/upload → crop/enhance → OCR → review → confirm; discard-then-confirm; cancel-with-unsaved-corrections; occasion-tagging; scan history).

**Target Platform**: Android and iOS mobile apps (existing app scope).

**Project Type**: mobile-app (Flutter, feature-first clean architecture)

**Performance Goals**: End-to-end capture-to-populated-review-screen in <30s for a clearly printed 5-line list on mid-range Android hardware (SC-001), dominated by OCR processing time (<5s of that budget) rather than UI overhead; review-screen interaction (edit/discard/confirm) has no perceptible lag for batches up to the 50-entry ceiling (FR-024).

**Constraints**: Fully offline-capable end-to-end — capture, crop, enhance, OCR, and parsing all run on-device with zero network calls (FR-019); money stored/computed as integer minor units via the existing `Money` type (constitution Principle VIII); the review/confirm gate is a hard, non-bypassable requirement with no code path that persists a `MoneyTransaction`/occasion contribution directly from OCR/parsing output (FR-007, constitution Principle X — this is the single most important constraint in this plan and is treated as a Constitution Check gate, not just a functional requirement); batch confirmation is atomic and idempotent against a rapid repeated tap (FR-011, FR-021); this feature performs zero AI/LLM inference of any kind — all parsing is deterministic regex/heuristic text-pattern matching (constitution Principle IX is trivially satisfied by having no AI integration at all in this feature).

**Scale/Scope**: Single user per device; up to 50 candidate entries per scan (FR-024), unbounded scan history retained until the user deletes a scan (FR-023); 1 new feature (`ocr`) plus a small additive change inside `transactions`; ~5-6 screens (scan entry/capture-or-upload, crop/enhance, review, scan history list, scan detail — capture and crop/enhance may be combined at implementation time, see Project Structure).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Clean Architecture Layering | `ocr` splits into `data/domain/presentation`; screens never touch the OCR/cropper plugins, `drift`, or file system directly — always through Domain-facing services/repositories | PASS |
| II. Feature-First Modularity | New code lives under `lib/features/ocr/`; the one cross-feature touch point (`MoneyTransaction` gaining `source`/`ocrScanId`) lives inside the existing `transactions` feature, mirroring 008's precedent exactly. The new crop/enhance (`ImagePreparationService`) and OCR (`TextRecognitionService`) abstractions are Domain interfaces defined inside `features/ocr/domain/`, not promoted to `core/` — only `AttachmentPickerService` (already genuinely shared with 008's photo attachments) stays in `core/media`; the other two are not yet used by a second feature, so Principle II keeps them local until one actually needs them | PASS |
| III. BLoC/Cubit Mandate | Cubits per screen/flow (`ScanCaptureCubit`, `ImagePrepCubit`, `ScanReviewCubit`, `ScanHistoryCubit`, `ScanDetailCubit`); no alternate state layer | PASS |
| IV. Immutable State | All Cubit states are `Equatable` value classes updated via `copyWith()`; the review screen's in-progress edits are held as an immutable `List<CandidateEntry>` replaced (never mutated in place) on every field edit/discard | PASS |
| V. Domain-Driven Business Logic | Use cases: `StartScan`, `PrepareImage` (crop/rotate/enhance), `RunOcrExtraction`, `ParseCandidateEntries`, `GetPossibleDuplicateForCandidate` (reuses 001's use case), `ConfirmScanBatch`, `DiscardCandidateEntry`, `CancelScan`, `GetScanHistory`, `GetScanDetail`, `DeleteScan` — each a meaningful, independently testable business action; `ConfirmScanBatch` is the single, carefully-reviewed choke point through which OCR data can ever become a real transaction (Principle X) | PASS |
| VI. Repository Pattern | Domain defines `OcrRepository` (scan/candidate persistence) and reuses `TransactionsRepository`/`OccasionsRepository` (extended) for the actual financial write — `ConfirmScanBatch` never writes a `MoneyTransaction` row itself; it delegates to the exact same repository methods manual/occasion entry already uses | PASS |
| VII. Explicit Error Handling | All repository/use-case calls return `Either<Failure, T>`; typed `OcrFailure` subtypes (`NoTextRecognizedFailure`, `NoCandidatesParsedFailure`, `ImageProcessingFailure`, `PermissionDeniedFailure`) added alongside the reused core `Failure`s — no empty catches, no raw plugin exceptions surfaced to the UI | PASS |
| VIII. Deterministic Financial Calculations | Amount parsing/validation reuses the existing `Money`/`numeral_parser` deterministic conversion exactly as manual entry does; candidate-entry parsing itself is deterministic regex/heuristic text matching, not probabilistic/AI-estimated | PASS |
| IX. AI Isolation | Not applicable — this feature performs zero AI/LLM inference; "parsing" is deterministic text-pattern matching over OCR output, explicitly documented as such (spec Assumptions) | PASS (N/A) |
| X. OCR Human-in-the-Loop | This is the feature that exists specifically to implement this principle. `ConfirmScanBatch` is the only method that can create a transaction from scan data, it is only reachable from the review screen after explicit per-entry confirmation, and there is no other code path (no auto-save timer, no "trust high-confidence entries" shortcut) — verified directly by the Phase 1 contract and by SC-002's "zero exceptions" test requirement | PASS |
| XI. Offline Resilience & Idempotent Sync | Feature has zero network dependency by construction (on-device OCR only); `ConfirmScanBatch` takes a caller-generated `idempotencyKey`, and the underlying per-entry `MoneyTransaction`/occasion-contribution inserts reuse 001/008's existing idempotency-key unique-index mechanism — a retried batch confirm cannot double-save | PASS |
| XII. Security & Secrets | No secrets/API keys (no cloud OCR call exists in this feature); scan source images live in the app's private sandboxed storage only, never uploaded; camera/gallery permissions requested contextually only when a scan starts (FR-016) | PASS |
| XIII. Localization & RTL/LTR | `gen_l10n` ARB additions for `ar`/`en` (scan flow, crop/enhance controls, review screen labels, confidence/inferred indicators, scan history); Arabic-Indic numeral parsing reused as-is from `core/money`; the spec's own documented Arabic-recognition-accuracy limitation (research.md Decision 1) is a data-quality limitation, not a localization/RTL gap — the UI itself is fully bilingual regardless of OCR accuracy | PASS |
| XIV. Dependency Injection | `get_it`/`injectable` wires the OCR engine wrapper, the cropper wrapper, the parser, the new DAO, repositories, use cases, and Cubits; nothing self-instantiated | PASS |
| XV. Design System | Reuses existing `core/design_system` components; a confidence-indicator chip/badge and a candidate-entry review card are the only genuinely new visual components, built inside `features/ocr/presentation/widgets/` first | PASS |
| XVI. Testability by Design | The OCR engine and cropper are wrapped behind Domain-facing interfaces (`TextRecognitionService`, `ImagePreparationService`) specifically so use cases/Cubits can be tested with fakes with no device camera/ML model involved; parser unit-tested extensively against a fixture table of real-world-shaped OCR output strings (clean, noisy, mixed-language, mixed-numeral); `integration_test` covers the flows in Scale/Scope | PASS |

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): The `ConfirmScanBatch` contract (contracts/ocr_repository.md) is written to make Principle X's requirement structurally true, not just behaviorally true — `CandidateEntry` rows have no code path to a `MoneyTransaction` row except through this one method, which itself requires each entry to be in a `confirmed` status set only by explicit user action on the review screen (data-model.md). Extending `MoneyTransaction` with `source`/`ocrScanId` (rather than a parallel ledger) is the same pattern 008 already established for `occasionId`, applied consistently for the same reason (one source of financial truth). No new dependency beyond the three justified above (all offline, on-device, no telemetry), no layering/state-management deviation. All gates above remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/009-ocr-paper-entry/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── database/                  # AppDatabase gains OcrScans + CandidateEntries tables, and
│   │                                # additive source/ocr_scan_id columns on MoneyTransactions;
│   │                                # schemaVersion incremented by 1, additive migration only
│   ├── design_system/              # reused as-is (confidence chip is the one new widget, built
│   │                                # in features/ocr/ first per Principle II)
│   ├── di/                         # gains ocr feature registrations
│   ├── error/                      # reused; gains OcrFailure subtypes
│   ├── l10n/                       # app_en.arb / app_ar.arb gain ocr-feature keys
│   ├── media/                      # UNCHANGED (from 008): AttachmentPickerService reused
│   │                                # verbatim for the capture/upload step
│   ├── money/                      # reused as-is (Money, EgpFormatter, numeral parser)
│   └── routing/                    # app_router.dart gains the ocr scan branch/routes
│
├── features/
│   ├── people/                     # UNCHANGED
│   ├── transactions/                # EXTENDED (additive only):
│   │   ├── domain/entities/money_transaction.dart   # gains TransactionSource enum
│   │   │                                              # (manual/ocr) + nullable ocrScanId
│   │   ├── domain/repositories/transactions_repository.dart  # gains addOcrSourcedTransaction()
│   │   ├── data/models/transaction_mapper.dart        # maps the two new columns
│   │   └── data/datasources/transactions_dao.dart      # insert path + query by ocr_scan_id
│   ├── occasions/                   # EXTENDED (additive only, mirrors transactions' extension):
│   │   └── domain/repositories/occasions_repository.dart  # addParticipantContribution gains
│   │                                                        # an optional source/ocrScanId pass-
│   │                                                        # through so an OCR-confirmed,
│   │                                                        # occasion-tagged entry is traceable
│   │                                                        # exactly like an OCR-confirmed
│   │                                                        # plain transaction
│   ├── settings/                    # UNCHANGED
│   ├── onboarding/                  # UNCHANGED
│   ├── finance/                     # UNCHANGED (007, if present) — no interaction
│   └── ocr/                         # NEW
│       ├── data/
│       │   ├── datasources/         # OcrDao (drift): scans + candidate entries queries
│       │   ├── models/              # OcrScanEntity/CandidateEntryEntity <-> domain mappers
│       │   ├── repositories/        # OcrRepositoryImpl (composes OcrDao + TransactionsRepository
│       │   │                          # + OccasionsRepository for ConfirmScanBatch)
│       │   ├── recognition/         # TextRecognitionServiceImpl (google_mlkit_text_recognition)
│       │   ├── preparation/         # ImagePreparationServiceImpl (image_cropper + `image` pkg)
│       │   └── parsing/             # CandidateEntryParser: deterministic regex/heuristic line
│       │                              # parser producing name/amount/direction/date/occasion
│       │                              # guesses + inferred-vs-read markers (pure Dart, unit-
│       │                              # testable with zero plugin dependency)
│       ├── domain/
│       │   ├── entities/            # OcrScan, CandidateEntry, FieldConfidence,
│       │   │                          # ScanStatus, CandidateEntryStatus
│       │   ├── repositories/         # OcrRepository, ImagePreparationService,
│       │   │                          # TextRecognitionService (all abstract; the latter two are
│       │   │                          # feature-local Domain interfaces, not core/ — Principle II)
│       │   └── usecases/             # StartScan, PrepareImage, RunOcrExtraction,
│       │   │                          # ParseCandidateEntries, EditCandidateEntry,
│       │   │                          # DiscardCandidateEntry, SetBatchDefaultDirection,
│       │   │                          # TagBatchToOccasion, ConfirmScanBatch, CancelScan,
│       │   │                          # GetScanHistory, GetScanDetail, DeleteScan
│       └── presentation/
│           ├── cubit/                # ScanCaptureCubit, ImagePrepCubit, ScanReviewCubit,
│           │                          # ScanHistoryCubit, ScanDetailCubit
│           ├── pages/                 # ScanCapturePage, ImagePrepPage, ScanReviewPage,
│           │                          # ScanHistoryPage, ScanDetailPage
│           └── widgets/               # CandidateEntryCard, ConfidenceIndicator,
│                                       # DirectionDefaultToggle, OccasionTagPicker,
│                                       # ScanProcessingOverlay, ScanFailureState
│
└── main.dart                          # UNCHANGED

test/
├── features/
│   ├── transactions/domain/usecases/  # existing tests extended for source=ocr rows
│   └── ocr/
│       ├── data/parsing/               # CandidateEntryParser unit tests: large fixture table of
│       │                                # clean/noisy/mixed-language/mixed-numeral OCR output
│       ├── domain/usecases/            # unit tests, faked repositories/services
│       ├── data/repositories/          # OcrRepositoryImpl tests against an in-memory drift DB
│       └── presentation/cubit/         # bloc_test + mocktail, faked TextRecognitionService/
│                                        # ImagePreparationService (no real plugin/device needed)
└── widget/                             # ScanReviewPage, CandidateEntryCard widget tests

integration_test/
└── ocr_flows_test.dart                 # capture/upload → prepare → extract → review → confirm;
                                         # edit + duplicate-person check on a candidate; discard one
                                         # entry, confirm the rest; cancel with unsaved corrections;
                                         # tag batch to an occasion; failed/empty-OCR recovery path;
                                         # scan history + scan detail; rapid double-confirm-tap
```

**Structure Decision**: Standard single Flutter app (Option 1 shape), one new feature-first module `lib/features/ocr/` added alongside the existing features, per constitution Principle II. `ocr` depends on `transactions`' and `occasions`' public Domain layers (repository interfaces + entities) for the actual financial write, the same composition-through-stable-contract pattern 008 already established for `transactions` — `ConfirmScanBatch` is intentionally the *only* place in the entire codebase where an `OcrScan`/`CandidateEntry` and a real `MoneyTransaction` meet. Unlike `AttachmentPickerService` (008, genuinely shared, lives in `core/media`), the new `ImagePreparationService` and `TextRecognitionService` interfaces are defined inside `features/ocr/domain/` — they are still abstracted behind Domain interfaces (so they remain swappable, e.g. for a future consented cloud-OCR mode, and fakeable for tests per Principle XVI), but Principle II's "only promote to `core/` once genuinely shared across two or more features" keeps them feature-local until a second feature actually needs one. No `backend/`/`api/` split. Tests mirror `lib/` under `test/`, plus one new `integration_test/` file.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally omitted.
