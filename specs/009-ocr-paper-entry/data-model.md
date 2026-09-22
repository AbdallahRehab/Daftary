# Phase 1 Data Model: OCR Paper-to-Transaction Entry

Derived from the spec's Key Entities section and the Phase 0 research decisions (extend `MoneyTransaction`/occasion contribution rather than a parallel ledger, coarse confidence + explicit inferred marker, deterministic parser). All money fields are integer minor units (piastres) via the existing `Money` type; all timestamps are UTC `DateTime`. Fields inherited unchanged from 001/008 are noted, not restated — see those specs' data-model.md for the authoritative baseline.

## Entity: OcrScan (NEW)

A single user-initiated scanning session.

| Field | Type | Rules |
|---|---|---|
| `id` | `String` (UUID) | Primary key, generated client-side when the scan starts |
| `idempotencyKey` | `String` (UUID) | **Unique index.** Generated once per confirm action; see `ConfirmScanBatch` (FR-021) |
| `sourceImagePath` | `String` | Local file-system path to the final (cropped/rotated/enhanced) image, within the app's private sandboxed storage directory (FR-023) |
| `cropBounds` | `String?` | Serialized crop-rectangle metadata applied by `image_cropper`, kept for audit/re-review (not for re-processing) |
| `rotationDegrees` | `int` | Default `0`; rotation applied during preparation (FR-002) |
| `status` | enum `processing` \| `needsReview` \| `confirmed` \| `discarded` \| `failed` | See Lifecycle below |
| `occasionId` | `String?` (FK → `Occasion.id`, 008) | Set when the user tags the whole batch to an occasion at review time (FR-014); applies to every entry confirmed from this scan |
| `defaultDirection` | `TransactionDirection?` | The batch-level default direction set in User Story 1/setup (FR-005); `null` means the user has not chosen one yet (required before any entry can be confirmed if that entry's own direction is unset) |
| `createdAt` | `DateTime` | Set once when the scan starts |
| `completedAt` | `DateTime?` | Set when the batch reaches `confirmed` or `discarded` |
| `deletedAt` | `DateTime?` | Soft-delete tombstone; set when the user deletes a past scan (FR-023), which also deletes `sourceImagePath`'s file |

**Validation rules**:
- `sourceImagePath` MUST reference a file the app itself wrote into its own sandboxed directory (same rule as 008's `OccasionAttachment.filePath`).
- A scan cannot move to `confirmed` while any of its non-discarded `CandidateEntry` rows lack a valid, complete state (data-model.md's `CandidateEntry` validation rules) — enforced by `ConfirmScanBatch`, not left to the UI alone.

**Lifecycle**: `processing → needsReview → (confirmed | discarded)`. `failed` is reachable from `processing` (no text recognized / no candidates parsed / an unrecoverable processing error) and always offers the recovery paths in FR-004/User Story 4. A scan may also be abandoned by the user before reaching a terminal state (FR-015); an abandoned scan without explicit corrections is hard-deleted immediately (nothing meaningful to retain); an abandoned scan where the user had already made review-screen corrections is kept as `discarded` after the confirmation prompt in FR-015, so the user's effort is not silently and irreversibly lost without at least a warning.

## Entity: CandidateEntry (NEW)

One proposed transaction extracted from a scan, before confirmation.

| Field | Type | Rules |
|---|---|---|
| `id` | `String` (UUID) | Primary key |
| `scanId` | `String` (FK → `OcrScan.id`) | Required |
| `status` | enum `pendingReview` \| `confirmed` \| `discarded` | Default `pendingReview`. Only a `confirmed` entry is eligible to become a `MoneyTransaction` (FR-007) |
| `personName` | `String` | Editable; starts as the parser's best-effort read (may be empty if nothing was recognized on that line, in which case it cannot be confirmed until the user fills it in — FR-008) |
| `personNameConfidence` | `FieldConfidence` | See value object below |
| `matchedPersonId` | `String?` (FK → `Person.id`, 001) | Set once the user resolves the entry to an existing person (directly, or via the duplicate-check flow, FR-009); `null` means "create a new person" at confirm time, exactly like manual entry |
| `amountMinorUnits` | `int?` | Editable; `null`/`<= 0` cannot be confirmed (FR-008, same rule as 001 FR-005) |
| `amountConfidence` | `FieldConfidence` | See value object below |
| `direction` | `TransactionDirection?` | Editable; falls back to `OcrScan.defaultDirection` for display when unset (FR-005), but the *effective* direction used at confirm time is resolved and stored explicitly on the entry the moment the user doesn't override it, so what gets saved is never ambiguous |
| `directionConfidence` | `FieldConfidence` | Almost always `inferred` in practice per research.md Decision 3's finding that plain lines rarely carry directional cues |
| `date` | `DateTime?` | Editable; defaults to `OcrScan.createdAt`'s date if neither read from the image nor set by the user (marked `inferred` when defaulted) |
| `dateConfidence` | `FieldConfidence` | — |
| `notes` | `String?` | Editable, optional |
| `rawOcrText` | `String` | The original, unedited line(s) of recognized text this entry was parsed from, kept for audit/debugging and so the user can compare against the source image during review |
| `createdAt` | `DateTime` | Set once when parsing produces this entry |
| `editedAt` | `DateTime?` | Set on any field edit during review (mirrors 001's `MoneyTransaction.editedAt` "was this touched" pattern) |

**Validation rules**:
- Cannot transition to `confirmed` unless: `personName` non-empty (trimmed), `amountMinorUnits` present and `> 0` (same ceiling as 001), an effective `direction` is resolvable (own value or batch default), and `date` is resolvable (own value or default-to-scan-date) — see FR-008.
- `amountMinorUnits`, once entered/edited, is validated with the exact same rules as 001's `MoneyTransaction.amount` (positive, decimal-precise, ceiling-checked, Arabic-Indic/Western numeral equivalence).

**Lifecycle**: `pendingReview → (confirmed | discarded)`, set only by explicit user action on the review screen (User Story 2) — there is no automatic transition based on confidence level, however high (FR-007's "no exceptions").

## Value Object: FieldConfidence *(embedded, not a separate table)*

| Field | Type | Derivation |
|---|---|---|
| `kind` | enum `read` \| `inferred` | `read` = a direct per-token OCR result exists for this field; `inferred` = the parser derived or defaulted this value (research.md Decision 3/4) |
| `level` | enum `low` \| `medium` \| `high` \| `none` | A coarse mapping from whatever signal the recognition engine exposes for a `read` field (research.md Decision 4); always `none` for an `inferred` field — an inferred field is never assigned a confidence level, by construction, so the UI cannot accidentally render it as if it were a confident OCR read |

**Rule**: `kind = inferred` and `level != none` can never both be true — enforced by the type itself (a smart constructor / factory pair: `FieldConfidence.read(level)` and `FieldConfidence.inferred()`), not by a runtime check callers must remember.

## Entity: MoneyTransaction (EXTENDED — see 001/008 for the unchanged baseline)

Two new fields, additive to 008's own extension.

| Field | Type | Rules |
|---|---|---|
| `source` | enum `manual` \| `ocr` | Default `manual` for every pre-existing and every non-OCR-created row (FR-012) |
| `ocrScanId` | `String?` (FK → `OcrScan.id`) | Non-null only when `source = ocr`. `null` for every manually entered or occasion-manually-entered row |

**Validation rules (additive)**:
- If `source = ocr`, `ocrScanId` MUST be non-null and MUST reference a real `OcrScan`.
- If `source = manual`, `ocrScanId` MUST be `null`.
- An OCR-sourced row may simultaneously have `kind = occasionContribution` and a non-null `occasionId` (008) when the scan was tagged to an occasion (FR-014) — the two extensions (008's and this one) compose without conflict, since they add independent nullable columns.

## Relationships

```
OcrScan (1) ──< (many) CandidateEntry
OcrScan (0..1) ──> (0..1) Occasion            [FR-014 batch tagging, 008]
CandidateEntry (1) ──confirm──> (0..1) MoneyTransaction   [only for status=confirmed entries]
MoneyTransaction (many) ──> (0..1) OcrScan     [source=ocr rows only]
```

- A `CandidateEntry` does not itself reference a `MoneyTransaction` row by FK (no schema column) — the relationship is established one-way, from the created `MoneyTransaction.ocrScanId` back to the scan; the review screen's in-memory state is what connects a specific entry to the transaction it produced during the single `ConfirmScanBatch` call, which is sufficient since a `CandidateEntry` is never edited again after confirmation.
- Deleting an `OcrScan` (FR-023) does **not** cascade-delete the `MoneyTransaction` rows it produced — those are real, independent financial records by that point (exactly like 008's contributions are independent of the occasion only until the occasion itself is deleted). Deleting a scan removes the scan record, its `CandidateEntry` rows, and its source image file only; transactions it already produced remain, simply losing their scan-detail traceability link's target (the `ocrScanId` FK is left pointing at a now-deleted scan id — the transaction itself still correctly shows "OCR" as its source via the `source` field, only the "view original scan" affordance becomes unavailable, which is the correct, expected consequence of the user explicitly deleting that scan).

## Drift Schema Sketch (for Phase 2 task planning, not exhaustive DDL)

```
Table OcrScans (
  id TEXT PRIMARY KEY,
  idempotency_key TEXT NOT NULL,
  source_image_path TEXT NOT NULL,
  crop_bounds TEXT NULL,
  rotation_degrees INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL,                     -- 'processing'|'needsReview'|'confirmed'|'discarded'|'failed'
  occasion_id TEXT NULL REFERENCES Occasions(id),
  default_direction TEXT NULL,              -- 'given'|'received'
  created_at INTEGER NOT NULL,
  completed_at INTEGER NULL,
  deleted_at INTEGER NULL
)
UNIQUE INDEX idx_ocr_scans_idempotency_key ON OcrScans(idempotency_key)
INDEX idx_ocr_scans_status ON OcrScans(status, deleted_at)

Table CandidateEntries (
  id TEXT PRIMARY KEY,
  scan_id TEXT NOT NULL REFERENCES OcrScans(id),
  status TEXT NOT NULL DEFAULT 'pendingReview',
  person_name TEXT NOT NULL,
  person_name_confidence_kind TEXT NOT NULL,      -- 'read'|'inferred'
  person_name_confidence_level TEXT NOT NULL,     -- 'low'|'medium'|'high'|'none'
  matched_person_id TEXT NULL REFERENCES People(id),
  amount_minor_units INTEGER NULL,
  amount_confidence_kind TEXT NOT NULL,
  amount_confidence_level TEXT NOT NULL,
  direction TEXT NULL,
  direction_confidence_kind TEXT NOT NULL,
  direction_confidence_level TEXT NOT NULL,
  date INTEGER NULL,
  date_confidence_kind TEXT NOT NULL,
  date_confidence_level TEXT NOT NULL,
  notes TEXT NULL,
  raw_ocr_text TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  edited_at INTEGER NULL
)
INDEX idx_candidate_entries_scan_id ON CandidateEntries(scan_id)

-- Additive columns on the EXISTING MoneyTransactions table (001, already extended by 008):
ALTER TABLE MoneyTransactions ADD COLUMN source TEXT NOT NULL DEFAULT 'manual';
ALTER TABLE MoneyTransactions ADD COLUMN ocr_scan_id TEXT NULL REFERENCES OcrScans(id);
INDEX idx_transactions_ocr_scan_id ON MoneyTransactions(ocr_scan_id, deleted_at)
```
