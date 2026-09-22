# Quickstart: Validate OCR Paper-to-Transaction Entry

This is a run/validation guide, not an implementation reference — see `data-model.md` and `contracts/` for structure, and `tasks.md` (Phase 2) for build steps.

## Prerequisites

- Flutter 3.47.0 / Dart 3.10 SDK via `fvm` (`fvm flutter --version` to confirm).
- Dependencies installed and code regenerated once the migration/new DI registrations and the new `google_mlkit_text_recognition`/`image_cropper`/`image` dependencies land:
  ```bash
  fvm flutter pub get
  fvm dart run build_runner build --delete-conflicting-outputs   # drift + injectable codegen
  ```
- A physical Android/iOS device or an emulator/simulator with a usable camera (or a set of sample images in the gallery) — text-recognition accuracy on an emulator's synthetic camera feed is not representative; prefer a real device for manual validation.
- A few real or printed test images prepared in advance: (1) a clearly printed English name/amount list, (2) a list with Arabic names, (3) a list with Arabic-Indic numerals, (4) a deliberately blurry/unreadable photo, (5) a list with more lines than the 50-entry ceiling (optional, for FR-024).

## Run the app

```bash
fvm flutter run
```

On first launch after this feature ships, the migration creates `OcrScans`/`CandidateEntries` and adds the `source`/`ocr_scan_id` columns to `MoneyTransactions` automatically — no manual setup or network configuration needed (feature is entirely on-device/offline, research.md Decision 1).

## Automated verification

```bash
fvm flutter analyze                # static analysis gate (constitution: must be clean)
fvm flutter test                   # unit + Cubit + widget tests, including the parser fixture suite
fvm flutter test integration_test  # end-to-end flows (requires a running device/emulator)
```

## Manual validation scenarios

Each scenario maps directly to a spec acceptance scenario; use as a scripted smoke test after implementation.

### 1. Scan and get candidates (User Story 1)
1. Start a scan, capture test image (1) with the in-app camera.
   - **Expect**: crop/rotate/enhance screen appears with the captured image.
2. Crop to just the list area, confirm.
   - **Expect**: processing indicator, then a populated review screen with one candidate per line.
3. Repeat by picking test image (1) from the gallery instead of the camera.
   - **Expect**: identical downstream behavior.
4. Run test image (4) (blurry/unreadable).
   - **Expect**: a clear "couldn't read this" state with retry/re-crop/manual-entry options — never a silent empty review screen.

### 2. Review, correct, confirm (User Story 2 — the critical path)
1. On the review screen from scenario 1.2, deliberately edit one entry's name and another's amount to fix an OCR misread.
   - **Expect**: edits apply only to that entry; validation rules match manual entry (e.g. try saving amount `0`, expect a block).
2. Edit a name to something matching an existing person closely.
   - **Expect**: the same possible-duplicate warning as manual entry appears.
3. Discard one entry.
   - **Expect**: it disappears from the batch; other entries unaffected.
4. Confirm the remaining entries.
   - **Expect**: exactly those entries become real transactions, visible immediately in the relevant people's profiles; discarded/never-confirmed entries produce zero transactions anywhere.
5. Rapid double-tap the confirm button (or simulate it).
   - **Expect**: exactly one batch save, never duplicated transactions (SC-006).
6. Start a new scan, make an edit, then cancel before confirming.
   - **Expect**: prompted to confirm discarding the in-progress correction; after confirming cancellation, zero transactions exist from that scan.
7. Open a confirmed transaction's detail view.
   - **Expect**: clearly marked as OCR-sourced, with a link back to its originating scan.

### 3. Confidence and inferred indicators (User Story 3)
1. Run test image (2) (Arabic names) through scan + review.
   - **Expect**: Arabic name fields show visibly lower confidence indicators than English/digit fields on the same batch (research.md Decision 1's documented limitation should be visible here, not hidden).
2. Check a field the parser defaulted (e.g. date, if not present in the image) or a direction that was never read from the text.
   - **Expect**: shown as "inferred," visually distinct from a genuine OCR confidence level — never implying false certainty.

### 4. Recovery paths (User Story 4)
1. Deny camera permission when prompted.
   - **Expect**: clear explanation, path to grant or use manual entry, no crash.
2. Run an image with text that produces zero name/amount-shaped candidates (e.g. a photo of a blank page).
   - **Expect**: "nothing could be structured from this" message with recovery options, distinct from the "nothing readable at all" message in scenario 1.4.
3. Background the app during OCR processing, then foreground it again.
   - **Expect**: processing completes or resumes correctly; nothing is lost or corrupted.

### 5. Scan history (User Story 5)
1. Open scan history after completing at least one confirmed and one cancelled/discarded scan.
   - **Expect**: both listed, each showing date, thumbnail, and outcome (confirmed count vs. discarded).
2. Open the confirmed scan's detail.
   - **Expect**: original image viewable, and every transaction it produced is listed and links to its full detail.
3. Delete a past scan.
   - **Expect**: it disappears from history and its image file is removed; any transactions it already produced remain intact and still show "OCR-sourced" (their link to view the original scan becomes unavailable, per data-model.md's documented Relationships behavior).

### 6. Occasion tagging (FR-014, cross-feature with 008)
1. Run a scan, and at review time tag the batch to an existing occasion (or create a new one inline).
   - **Expect**: confirming the batch creates occasion participant contributions (008) rather than plain transactions; opening that occasion afterward shows the new participants and updated totals.

### 7. Localization and theming (FR-022)
1. Switch the app language to Arabic and repeat scenario 1-2 fully in RTL.
   - **Expect**: correct RTL layout, numeral/date formatting, no truncation on the review screen's denser field layout.
2. Switch between light and dark mode on the scan/review/history screens.
   - **Expect**: confidence indicators and the scan-processing overlay remain legible and correctly themed.
