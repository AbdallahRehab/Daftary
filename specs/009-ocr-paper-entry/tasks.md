---

description: "Task list for OCR Paper-to-Transaction Entry (feature 009)"
---

# Tasks: OCR Paper-to-Transaction Entry

**Input**: Design documents from `/specs/009-ocr-paper-entry/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included, consistent with 001/008's precedent (constitution Principle XVI). Each user story's tests are written before its implementation tasks (TDD ordering). Given this feature's safety-critical requirement (constitution Principle X / FR-007), User Story 2's tests are treated as release-blocking, not optional coverage.

**Organization**: Tasks are grouped by user story (spec.md priorities P1-P3) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no unmet dependencies)
- **[Story]**: Maps to spec.md user stories (US1-US5)
- File paths follow plan.md's Project Structure exactly

## Path Conventions

Single Flutter app, feature-first per constitution Principle II: `lib/core/`, `lib/features/ocr/{data,domain,presentation}`, plus additive extensions inside `lib/features/transactions/` and `lib/features/occasions/`; `test/` mirrors `lib/`; `integration_test/` for end-to-end flows.

---

## Phase 1: Setup

**Purpose**: Add the new dependencies and directory skeleton this feature needs.

- [X] T001 Add `google_mlkit_text_recognition`, `image_cropper`, and `image` to `pubspec.yaml` dependencies, pinned to their latest stable versions compatible with Flutter 3.47.0; run `fvm flutter pub get` to confirm resolution (research.md Decisions 1-2).
- [X] T002 [P] Create the directory skeleton: `lib/features/ocr/{data/{datasources,models,repositories,recognition,preparation,parsing},domain/{entities,repositories,usecases},presentation/{cubit,pages,widgets}}/`, mirrored under `test/features/ocr/{data/parsing,domain/usecases,data/repositories,presentation/cubit}/`.
- [X] T003 [P] Confirm/extend the camera and photo-library permission declarations from 008 (`AndroidManifest.xml`, `Info.plist`) cover this feature's reuse of the same capture step; no new permission type is required (FR-016 reuses 008's `AttachmentPickerService`).

**Checkpoint**: Dependencies resolve, directories exist.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema/entity changes and the two new feature-local service abstractions every user story depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 Extend `lib/features/transactions/domain/entities/money_transaction.dart`: add `TransactionSource` enum (`manual`/`ocr`, default `manual`) and `ocrScanId` (`String?`, FK → `OcrScan.id`, non-null only when `source = ocr`) fields to `MoneyTransaction`; update `props`/constructor. Additive only — 001/008 behavior unchanged.
- [X] T005 [P] Define the `OcrScan` entity (`id`, `idempotencyKey`, `sourceImagePath`, `cropBounds?`, `rotationDegrees`, `status` enum, `occasionId?`, `defaultDirection?`, `createdAt`, `completedAt?`, `deletedAt?`) in `lib/features/ocr/domain/entities/ocr_scan.dart`, per data-model.md.
- [X] T006 [P] Define the `FieldConfidence` value object (`kind` enum `read`/`inferred`, `level` enum `low`/`medium`/`high`/`none`) in `lib/features/ocr/domain/entities/field_confidence.dart` with smart constructors `FieldConfidence.read(level)`/`FieldConfidence.inferred()` that make `kind=inferred ⇒ level=none` structurally guaranteed (data-model.md's "Rule").
- [X] T007 [P] Define the `CandidateEntry` entity and `CandidateEntryStatus` enum in `lib/features/ocr/domain/entities/candidate_entry.dart`, per data-model.md's field table and validation rules (confirm-eligibility check as a pure `bool get isConfirmEligible` getter, reused by both the Cubit and the repository so the rule is defined once).
- [X] T008 [P] Add `NoTextRecognizedFailure`, `NoCandidatesParsedFailure`, `ImageProcessingFailure`, `PermissionDeniedFailure` (as `OcrFailure` subtypes) to `lib/features/ocr/domain/entities/ocr_failures.dart`, extending the core `Failure`.
- [X] T009 Update `lib/core/database/app_database.dart`: add `OcrScans` and `CandidateEntries` drift tables per data-model.md's Drift Schema Sketch (`UNIQUE INDEX idx_ocr_scans_idempotency_key`, `INDEX idx_ocr_scans_status`, `INDEX idx_candidate_entries_scan_id`); add `source TEXT NOT NULL DEFAULT 'manual'` and `ocr_scan_id TEXT NULL REFERENCES OcrScans(id)` columns to `MoneyTransactions`; add `INDEX idx_transactions_ocr_scan_id`; bump `schemaVersion` by 1 with the additive `onUpgrade` step. Run `dart run build_runner build --delete-conflicting-outputs`.
- [X] T010 [P] Define `lib/features/ocr/domain/repositories/image_preparation_service.dart`: abstract `ImagePreparationService` (`cropAndRotate(String imagePath) -> Either<Failure, PreparedImage>` capturing crop bounds/rotation; `enhance(String imagePath) -> Either<Failure, String newPath>`) — a feature-local Domain interface, not `core/` (plan.md Structure Decision).
- [X] T011 [P] Implement `lib/features/ocr/data/preparation/image_preparation_service_impl.dart`: wraps `image_cropper` for crop/rotate and the `image` package for a deterministic brightness/contrast linear-stretch enhancement (research.md Decision 2); maps plugin/file-I/O exceptions to `ImageProcessingFailure`.
- [X] T012 [P] Unit test `ImagePreparationServiceImpl` against fixture images and a faked cropper boundary: enhancement is deterministic (same input → same output bytes), failure paths return typed failures, never throw — in `test/features/ocr/data/preparation/image_preparation_service_impl_test.dart`.
- [X] T013 [P] Define `lib/features/ocr/domain/repositories/text_recognition_service.dart`: abstract `TextRecognitionService` (`recognize(String imagePath) -> Either<Failure, RecognizedText>`, where `RecognizedText` is a plain-Dart model of lines/blocks + per-element text + optional coarse confidence signal, with no plugin type leaking into the Domain layer) — feature-local, not `core/`.
- [X] T014 [P] Implement `lib/features/ocr/data/recognition/text_recognition_service_impl.dart`: wraps `google_mlkit_text_recognition` (Latin script recognizer, research.md Decision 1), maps its result into the plain `RecognizedText` model, maps plugin exceptions to `NoTextRecognizedFailure`/`UnknownFailure`.
- [X] T015 [P] Implement `lib/features/ocr/data/parsing/candidate_entry_parser.dart`: pure-Dart deterministic parser (research.md Decision 3) taking `RecognizedText` and producing a `List<CandidateEntry>` (unsaved, in-memory) — numeric-token amount extraction reusing `core/money/numeral_parser.dart`, remainder-as-name, whole-block date/occasion-heading detection, `FieldConfidence.read`/`.inferred()` assignment per field per Decision 4. Zero plugin dependency in its signature (constitution Principle XVI/testability).
- [X] T016 [P] Build a fixture table (at least 20 cases: clean printed English, clean printed with Arabic-Indic numerals, noisy/character-confusion cases like "1O00", mixed Arabic/English on one line, a subtotal/header line that should NOT parse as a candidate, an empty/whitespace-only line, a date-shaped token, an occasion-heading line) and exhaustively unit test `CandidateEntryParser` against it in `test/features/ocr/data/parsing/candidate_entry_parser_test.dart` (depends on T015).
- [X] T017 Define the `OcrRepository` abstract interface in `lib/features/ocr/domain/repositories/ocr_repository.dart` per `contracts/ocr_repository.md` (all method signatures — implemented incrementally across US1-US5).
- [X] T018 Define the `TransactionsRepository.addOcrSourcedTransaction` and `OccasionsRepository.addParticipantContribution`'s new optional `ocrScanId` parameter, per `contracts/transactions_repository_extension.md` (signatures only — implemented in US1/US2).

**Checkpoint**: Schema, entities, the parser, and both service abstractions exist and are independently unit-tested. User story implementation can now begin.

---

## Phase 3: User Story 1 - Scan a Paper and Get Candidate Entries (Priority: P1) 🎯 MVP (part 1 of 2)

**Goal**: Capture/upload → crop/rotate/enhance → OCR → parse produces a populated, editable batch of candidate entries, with a clear failure state when nothing usable is found.

**Independent Test**: Photograph/upload a paper with several name/amount lines; confirm a non-empty candidate list is produced.

### Tests for User Story 1 ⚠️

- [X] T019 [P] [US1] Unit test `StartScan`: persists a new `OcrScan` with `status = processing` and the given image/crop/rotation metadata — in `test/features/ocr/domain/usecases/start_scan_test.dart`.
- [X] T020 [P] [US1] Unit test `RunOcrExtraction`: on a faked `TextRecognitionService` returning recognizable text, produces `CandidateEntry` rows and moves the scan to `needsReview`; on a faked service returning no text, returns `NoTextRecognizedFailure` and moves the scan to `failed`; on text with no name/amount-shaped lines, returns `NoCandidatesParsedFailure` (FR-004) — in `test/features/ocr/domain/usecases/run_ocr_extraction_test.dart`.
- [X] T021 [P] [US1] Unit test `SetBatchDefaultDirection`: sets `OcrScan.defaultDirection`, does not overwrite any entry that already has its own explicit direction (FR-005) — in `test/features/ocr/domain/usecases/set_batch_default_direction_test.dart`.
- [X] T022 [P] [US1] Repository test against an in-memory `NativeDatabase.memory()`: `OcrRepositoryImpl.startScan`/`runExtraction` persistence round-trip — in `test/features/ocr/data/repositories/ocr_repository_impl_test.dart`.
- [X] T023 [P] [US1] `bloc_test` for `ScanCaptureCubit`/`ImagePrepCubit`: capture-or-upload selection, crop/rotate/enhance invocation, transition to processing, permission-denial path (FR-016) — in `test/features/ocr/presentation/cubit/scan_capture_cubit_test.dart` and `image_prep_cubit_test.dart`.

### Implementation for User Story 1

- [X] T024 [US1] Implement `lib/features/ocr/data/datasources/ocr_dao.dart` (drift DAO): insert/query `OcrScan` (idempotency-guarded on `startScan`... — note: `startScan` itself is not the idempotency-guarded call per contracts, only `confirmScanBatch` is; this DAO method is a plain insert) and bulk-insert `CandidateEntry` rows produced by the parser.
- [X] T025 [P] [US1] Implement `lib/features/ocr/data/models/ocr_scan_mapper.dart` and `candidate_entry_mapper.dart`: map between drift rows and domain entities, including `FieldConfidence`'s `kind`/`level` pair (T006).
- [X] T026 [US1] Implement `OcrRepositoryImpl.startScan`/`runExtraction`/`setBatchDefaultDirection` in `lib/features/ocr/data/repositories/ocr_repository_impl.dart`: `runExtraction` composes `TextRecognitionService.recognize` (T014) → `CandidateEntryParser` (T015) → persists via `OcrDao` (T024), setting `status` per outcome (depends on T017, T024, T025).
- [X] T027 [P] [US1] Implement `lib/features/ocr/domain/usecases/start_scan.dart`, `run_ocr_extraction.dart`, `set_batch_default_direction.dart`, wrapping the T026 repository methods.
- [X] T028 Annotate `OcrRepositoryImpl`/`OcrDao`, `ImagePreparationServiceImpl`, `TextRecognitionServiceImpl`, and the US1 use cases with `@injectable`/`@LazySingleton(as: ...)`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T011, T014, T026, T027).
- [X] T029 [US1] Implement `lib/features/ocr/presentation/cubit/scan_capture_cubit.dart` + state: delegates to `core/media/AttachmentPickerService` (008) for camera/gallery selection, surfaces `PermissionDeniedFailure` with a clear explanation (FR-016) (depends on T027).
- [X] T030 [US1] Implement `lib/features/ocr/presentation/cubit/image_prep_cubit.dart` + state: drives `ImagePreparationService.cropAndRotate`/`.enhance`, allows redo without restarting capture (FR-002), then calls `StartScan` + `RunOcrExtraction`, exposing a cancelable in-progress state (FR-017) (depends on T027, T028).
- [X] T031 [P] [US1] Implement `lib/features/ocr/presentation/widgets/scan_processing_overlay.dart` and `scan_failure_state.dart`: in-progress indicator with cancel affordance; failure state with retry/re-crop/manual-entry actions (FR-004, FR-017).
- [X] T032 [US1] Implement `lib/features/ocr/presentation/pages/scan_capture_page.dart` (camera/gallery entry point) and `image_prep_page.dart` (crop/rotate/enhance UI wired to `image_cropper`, batch-default-direction control) (depends on T029, T030, T031).
- [X] T033 Register `/ocr/scan`, `/ocr/scan/prepare` routes in `lib/core/routing/app_router.dart`, and add a reachable entry point from the app's main navigation ("Scan Paper," per docs/project.txt §12 Quick Actions) (depends on T032).

**Checkpoint**: A photo/upload reliably produces a reviewable (or clearly failed) candidate batch. User Story 1 alone is not yet safe to ship — proceed directly to US2.

---

## Phase 4: User Story 2 - Review, Correct, and Confirm Before Anything Is Saved (Priority: P1) 🎯 MVP (part 2 of 2, release-blocking)

**Goal**: The mandatory review/edit/discard/confirm gate — the feature's core safety requirement (constitution Principle X, FR-007).

**Independent Test**: Produce a batch, corrupt one field per entry, correct on review, confirm some and discard others; verify only confirmed+corrected entries become transactions, zero exceptions.

### Tests for User Story 2 ⚠️ — release-blocking, write and pass before any other US2/US3/US4/US5 work is considered complete

- [X] T034 [P] [US2] Unit test `EditCandidateEntry`: applies field edits with the same validation as manual transaction entry (amount `<= 0` rejected, ceiling enforced, Arabic-Indic/Western numeral equivalence via `numeral_parser`); setting `matchedPersonId` resolves a duplicate match — in `test/features/ocr/domain/usecases/edit_candidate_entry_test.dart`.
- [X] T035 [P] [US2] Unit test `GetPossibleDuplicateForCandidate` (thin wrapper reusing 001's `FindPossibleDuplicatePerson`): triggers the same bidirectional match rule as manual entry when a candidate's `personName` is edited (FR-009) — in the same test file or a dedicated one.
- [X] T036 [P] [US2] Unit test `DiscardCandidateEntry`: marks one entry `discarded`, does not affect sibling entries or the scan's status — in `test/features/ocr/domain/usecases/discard_candidate_entry_test.dart`.
- [X] T037 [US2] **Critical-path unit test** `ConfirmScanBatch`: (a) creates exactly one `MoneyTransaction` per `confirmed`-eligible, non-discarded entry, with `source = ocr` and the correct `ocrScanId`; (b) creates zero transactions for discarded or still-`pendingReview` entries; (c) returns `ValidationFailure` and creates **zero** transactions when any non-discarded entry is not confirm-eligible (all-or-nothing, FR-011); (d) a retried call with the same `idempotencyKey` returns the already-created list rather than creating a second batch (FR-021, SC-006); (e) when `scan.occasionId` is set, delegates to `OccasionsRepository.addParticipantContribution` instead of the plain path — in `test/features/ocr/domain/usecases/confirm_scan_batch_test.dart`. This test file is the primary automated evidence for SC-002 and must include an explicit test asserting that no other method in `OcrRepository`/`TransactionsRepository`/`OccasionsRepository` can be reached from Presentation without going through a `confirmed` `CandidateEntry` status transition first (a static/code-path assertion or, at minimum, a documented manual audit note if a runtime test cannot express it).
- [X] T038 [P] [US2] Unit test `CancelScan`: no transactions created; entries with `editedAt != null` require the caller to have shown a confirmation prompt first (tested at the Cubit level, T042) — in `test/features/ocr/domain/usecases/cancel_scan_test.dart`.
- [X] T039 [P] [US2] Repository test against an in-memory `NativeDatabase.memory()`: `OcrRepositoryImpl.confirmScanBatch`'s idempotency-key unique index makes a retried insert a no-op — extend `test/features/ocr/data/repositories/ocr_repository_impl_test.dart` (T022).
- [X] T040 [P] [US2] Widget test for `CandidateEntryCard`: renders editable fields, discard action, duplicate-warning surfacing — in `test/widget/candidate_entry_card_test.dart`.
- [X] T041 [P] [US2] `bloc_test` for `ScanReviewCubit`: edit/discard/confirm state transitions, confirm-button disabled while any entry is invalid, disabled immediately on tap to prevent a double-confirm (FR-021), cancel-with-unsaved-corrections prompt (FR-015) — in `test/features/ocr/presentation/cubit/scan_review_cubit_test.dart`.

### Implementation for User Story 2

- [X] T042 [US2] Implement `TransactionsRepositoryImpl.addOcrSourcedTransaction` in `lib/features/transactions/data/repositories/transactions_repository_impl.dart`, per `contracts/transactions_repository_extension.md` (depends on T004, T018).
- [X] T043 [US2] Extend `OccasionsRepositoryImpl.addParticipantContribution` (008) to accept and persist the optional `ocrScanId` parameter, setting `source = ocr` on the created row (depends on T004, T018, and 008's existing implementation).
- [X] T044 [US2] Implement `OcrRepositoryImpl.editCandidateEntry`/`discardCandidateEntry`/`cancelScan` in `lib/features/ocr/data/repositories/ocr_repository_impl.dart` (depends on T026).
- [X] T045 [US2] Implement `OcrRepositoryImpl.confirmScanBatch`: validates every non-discarded entry's confirm-eligibility (data-model.md rules via `CandidateEntry.isConfirmEligible`, T007), and — in one DB transaction — marks each eligible entry `confirmed` and calls `TransactionsRepositoryImpl.addOcrSourcedTransaction` (T042) or, if `scan.occasionId` is set, `OccasionsRepositoryImpl.addParticipantContribution` (T043) per entry, then sets the scan's `status = confirmed`/`completedAt`. Guarded by the `idempotency_key` unique index on `OcrScans` (reusing the scan's own `idempotencyKey`, generated fresh per confirm attempt by the Cubit) (depends on T042, T043, T044).
- [X] T046 [P] [US2] Implement `lib/features/ocr/domain/usecases/edit_candidate_entry.dart`, `get_possible_duplicate_for_candidate.dart` (thin wrapper around 001's `FindPossibleDuplicatePerson`), `discard_candidate_entry.dart`, `confirm_scan_batch.dart`, `cancel_scan.dart`, wrapping the T044/T045 repository methods.
- [X] T047 Annotate the US2 use cases with `@injectable`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T046).
- [X] T048 [US2] Implement `lib/features/ocr/presentation/cubit/scan_review_cubit.dart` + `scan_review_state.dart`: loads the batch, applies edits (re-running the duplicate check via T046 when `personName` changes), tracks discard state, computes overall confirm-eligibility, generates a fresh idempotency key per confirm attempt, disables confirm immediately on tap (FR-021), shows the "discard corrections?" prompt on cancel when any entry has been edited (FR-015) (depends on T046, T047).
- [X] T049 [P] [US2] Implement `lib/features/ocr/presentation/widgets/candidate_entry_card.dart`: editable name/amount/direction/date/notes fields, reuses `PersonPickerField`/`DuplicateWarningSheet` (001) for the name field, discard action, per-field confidence rendering wired in US3 (placeholder styling here) (depends on T007).
- [X] T050 [US2] Implement `lib/features/ocr/presentation/pages/scan_review_page.dart`: renders the `CandidateEntryCard` list, the confirm action, loading/success/error states, and the cancel-with-confirmation flow (depends on T048, T049).
- [X] T051 Register `/ocr/scan/review` route in `lib/core/routing/app_router.dart` (depends on T050).

**Checkpoint**: User Stories 1-2 together deliver the safe MVP — scans reliably produce candidates, and nothing is ever saved without explicit per-entry review and confirmation. **This is the release gate for the feature; do not consider it shippable before T037 and T041 pass.**

---

## Phase 5: User Story 3 - See Confidence and Trust Signals While Reviewing (Priority: P2)

**Goal**: Visually distinguish OCR-confident, OCR-low-confidence, and inferred/defaulted fields on the review screen.

**Independent Test**: Scan a paper with both clear and ambiguous text; confirm low-confidence fields are visually flagged differently from high-confidence ones.

### Tests for User Story 3 ⚠️

- [X] T052 [P] [US3] Unit test confirming `CandidateEntryParser` (T015) correctly assigns `FieldConfidence.inferred()` (never a `level`) to every defaulted/derived field (direction default, defaulted date, occasion guess) and `FieldConfidence.read(level)` to every directly-parsed token — extend `test/features/ocr/data/parsing/candidate_entry_parser_test.dart` (T016).
- [X] T053 [P] [US3] Widget test for `ConfidenceIndicator`: renders distinct visuals for `low`/`medium`/`high` read-confidence and a distinct "inferred" visual, never conflating the two — in `test/widget/confidence_indicator_test.dart`.

### Implementation for User Story 3

- [X] T054 [P] [US3] Implement `lib/features/ocr/presentation/widgets/confidence_indicator.dart`: color/icon-coded low/medium/high indicator plus a visually distinct "inferred" badge, per FR-013's no-false-certainty requirement (depends on T006).
- [X] T055 [US3] Wire `ConfidenceIndicator` (T054) into `CandidateEntryCard` (T049) for each field (name/amount/direction/date), and sort or highlight low-confidence entries first in `ScanReviewCubit`/`scan_review_page.dart` (FR-013 Acceptance Scenario 1) (depends on T048, T054).

**Checkpoint**: Review screen clearly communicates what the system is sure about vs. guessed.

---

## Phase 6: User Story 4 - Recover From a Failed or Low-Quality Scan (Priority: P2)

**Goal**: Clear, actionable failure/recovery states for no-text, no-candidates, permission-denial, and slow-processing cases.

**Independent Test**: Feed an unreadable image through the pipeline; confirm a clear failure state with actionable next steps, never a crash or infinite spinner.

### Tests for User Story 4 ⚠️

- [X] T056 [P] [US4] Widget test for `ScanFailureState` (T031, extended): renders distinct messaging for `NoTextRecognizedFailure` vs. `NoCandidatesParsedFailure` vs. `PermissionDeniedFailure`, each with correct recovery actions (FR-004 Acceptance Scenarios 1-2) — extend `test/widget/` coverage.
- [X] T057 [P] [US4] `bloc_test` for `ImagePrepCubit`'s cancel-during-processing and app-backgrounded-during-processing behavior (FR-017) — extend `test/features/ocr/presentation/cubit/image_prep_cubit_test.dart` (T023).

### Implementation for User Story 4

- [X] T058 [US4] Extend `ScanFailureState` (T031) with the three distinct failure-reason renderings and their recovery actions (retry capture / re-crop-and-retry / manual entry) (depends on T031).
- [X] T059 [US4] Extend `ImagePrepCubit`/`scan_processing_overlay.dart` to support cancellation mid-processing and correct resume/continue behavior across an app background/foreground cycle (Flutter lifecycle handling per constitution Engineering Standards) (depends on T030, T031).
- [X] T060 [US4] Add a "device unsupported" explanatory state to `scan_capture_page.dart`, shown if `TextRecognitionService`/`ImagePreparationService` report unavailability on the current device, directing the user to manual entry (Edge Cases) (depends on T032).

**Checkpoint**: Every realistic failure mode has a clear, actionable UI response.

---

## Phase 7: User Story 5 - Review Past Scans (Priority: P3)

**Goal**: Scan history list and scan detail (original image + resulting transactions).

**Independent Test**: Complete a scan with at least one confirmed entry; confirm it's retrievable with its image and resulting transactions from scan history.

### Tests for User Story 5 ⚠️

- [X] T061 [P] [US5] Unit test `GetScanHistory`/`GetScanDetail`/`DeleteScan`: newest-first ordering, detail includes source image + `CandidateEntry` list + linked `MoneyTransaction`s (via `ocr_scan_id`), delete removes the scan/entries/image file but leaves already-created transactions intact (data-model.md Relationships) — in `test/features/ocr/domain/usecases/scan_history_test.dart`.
- [X] T062 [P] [US5] `bloc_test` for `ScanHistoryCubit`/`ScanDetailCubit` — in `test/features/ocr/presentation/cubit/scan_history_cubit_test.dart` and `scan_detail_cubit_test.dart`.

### Implementation for User Story 5

- [X] T063 [US5] Implement `OcrRepositoryImpl.getScanHistory`/`getScanDetail`/`deleteScan` in `lib/features/ocr/data/repositories/ocr_repository_impl.dart`, `deleteScan` removing the `OcrScans`/`CandidateEntries` rows and the source image file (not any already-produced `MoneyTransaction`) (depends on T026).
- [X] T064 [P] [US5] Implement `lib/features/ocr/domain/usecases/get_scan_history.dart`, `get_scan_detail.dart`, `delete_scan.dart`, wrapping T063.
- [X] T065 Annotate the US5 use cases with `@injectable`; re-run `dart run build_runner build --delete-conflicting-outputs` (depends on T064).
- [X] T066 [US5] Implement `lib/features/ocr/presentation/cubit/scan_history_cubit.dart` and `scan_detail_cubit.dart` (depends on T064, T065).
- [X] T067 [P] [US5] Implement `lib/features/ocr/presentation/pages/scan_history_page.dart` (list with thumbnail/date/outcome, empty state) and `scan_detail_page.dart` (image viewer + linked transactions list, each linking to its full 001 transaction detail) (depends on T066).
- [X] T068 Register `/ocr/history` and `/ocr/history/:scanId` routes in `lib/core/routing/app_router.dart`, and link to it from the scan review confirmation/success state and the app's main navigation (depends on T067).

**Checkpoint**: All five user stories complete — the full OCR feature is usable end-to-end.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Localization, theming, performance, and end-to-end validation across the whole feature.

- [X] T069 [P] Add all OCR-feature strings (capture/upload, crop/enhance controls, review screen labels, confidence/inferred indicators, failure states, scan history/detail, permission explanations) to `lib/core/l10n/app_en.arb` and `app_ar.arb`; regenerate `AppLocalizations` (FR-022).
- [X] T070 [P] RTL/LTR and theme pass: verify scan/prep/review/history/detail screens, confidence indicators, and failure states render correctly in Arabic RTL and English LTR, and in both light and dark mode (FR-022).
- [X] T071 [P] Performance check: run the pipeline against a 50-line fixture image (FR-024 ceiling) and confirm the "only first N parsed" messaging triggers correctly for an image with more lines, and that the review screen remains responsive at 50 entries (plan.md Performance Goals).
- [X] T072 Write `integration_test/ocr_flows_test.dart` covering: capture/upload → prepare → extract → review → confirm (US1+US2 critical path); edit + duplicate-person check on a candidate; discard one entry, confirm the rest; cancel with unsaved corrections; tag batch to an occasion (008 cross-feature); failed/empty-OCR recovery path; scan history + scan detail + delete; rapid double-confirm-tap — per quickstart.md's manual scenarios.
- [X] T073 Run `fvm flutter analyze` and `fvm flutter format`, fix all warnings (no `// ignore` suppressions without a documented reason).
- [ ] T074 Run the full `fvm flutter test` suite and `fvm flutter test integration_test`; confirm all pass, with special attention to T037's critical-path test.
  - **Unit/widget half: DONE.** `fvm flutter test` → 750/750 pass, including T037's critical-path group in `test/features/ocr/data/repositories/ocr_repository_impl_test.dart`.
  - **Integration half: BLOCKED on the environment, not on this feature.** `integration_test/ocr_flows_test.dart` is written and analyzer-clean but has not been executed. iOS Simulator: ML Kit ships no arm64 simulator slice (research.md §7). iOS device: the only one attached is wireless, and `flutter test` has no `--publish-port`. Android emulator: Gradle 8.14 rejects the Java 25 JDK Flutter resolves from Android Studio, which `JAVA_HOME` does not override — a repo/machine toolchain decision left to its owner rather than pinned here. Run this task on a USB-tethered iPhone, or after the Android toolchain is settled.
- [X] T075 Code-review pass against the constitution's Definition of Done checklist, with explicit sign-off on constitution Principle X: manually trace and document (in the PR description) every code path capable of creating a `MoneyTransaction`/occasion contribution from this feature, confirming `confirmScanBatch` is the only one and that it is unreachable without a `confirmed` `CandidateEntry` status.

---

## Dependencies & Execution Order

- **Setup (Phase 1)** → **Foundational (Phase 2)**: strictly sequential; Foundational blocks every user story.
- **US1 (Phase 3)** depends only on Foundational, but is **not independently shippable** — it produces candidate data with no safe path to persistence until US2 lands.
- **US2 (Phase 4)** depends on US1 (needs candidates to review) and is release-blocking; together US1+US2 are the MVP (spec: "must ship together").
- **US3 (Phase 5)** depends on US2 (the review screen and `CandidateEntry`/`FieldConfidence` model must exist).
- **US4 (Phase 6)** depends on US1 (capture/prep flow) and benefits from US2 existing (review-screen-adjacent failure states), but its core failure-state work can start once US1's `ScanFailureState` skeleton (T031) exists.
- **US5 (Phase 7)** depends on US1 (scans exist) and US2 (confirmed transactions exist to link to); independent of US3/US4 otherwise.
- **Polish (Phase 8)** depends on all prior phases.

## Parallel Execution Examples

- Within Foundational: T005-T008 (entities/value objects/failures) can run in parallel; T010-T012 (image prep) and T013-T016 (recognition + parser) are independent of each other and can run in parallel once T009's schema lands.
- Within US1: T019-T023 (tests) can run in parallel before implementation; T027 (use cases) can run in parallel once T026 lands.
- Within US2: T034-T041 (tests) can run in parallel; T046 (use cases) can run in parallel once T044/T045 land. T037 (the `ConfirmScanBatch` critical-path test) should be written and reviewed with extra care before T045 is considered done, given its release-blocking status.

## Implementation Strategy

**MVP first**: Phases 1-4 (Setup, Foundational, US1, US2) are the entire safe MVP — a version of this feature without US2 is not a smaller product, it is an unacceptable one (constitution Principle X). Do not demo, release, or consider "done" any build that includes US1 without US2.

**Incremental delivery**: US3 (confidence/trust signals) and US4 (failure recovery polish) are the next-highest-value increments, in either order. US5 (scan history) is the lowest-priority, safely deferrable increment.
