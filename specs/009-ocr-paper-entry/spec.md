# Feature Specification: OCR Paper-to-Transaction Entry

**Feature Branch**: `009-ocr-paper-entry`

**Created**: 2026-09-22

**Status**: Draft

**Input**: User description: "Roadmap V1.5 — OCR Paper-to-Transaction Entry. Ground this in docs/project.txt section 3 (PAPER / IMAGE → AUTOMATIC TRANSACTION ENTRY) and constitution Principle X (OCR Is an Uncertain Input Source Requiring Confirmation). Users often have a physical paper with a list of names and amounts (e.g. a wedding cash-gift list, a debt notebook page). They should be able to photograph or upload that paper, crop/rotate/enhance the image, have the app OCR the text and parse it into candidate entries (person name, amount, direction, date, occasion, notes), and see all candidates on a mandatory review screen with per-field confidence indicators where available, where they confirm or correct each one before anything is saved as a real transaction. The app must never auto-save financial transactions from OCR without explicit user confirmation — this must be a hard, testable requirement, not an implementation detail. Ground extraction targets in the existing 001-money-relationships-tracking transaction model and, where the user tags a scan to an occasion, the 008-occasions-social-money model."

## Clarifications

*No outstanding [NEEDS CLARIFICATION] markers — ambiguities below were resolved with reasonable, documented defaults in Assumptions, following the pattern established in prior specs.*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Scan a Paper and Get Candidate Entries (Priority: P1)

A user has a physical piece of paper — a wedding cash-gift list, a page from a debt notebook, a handwritten IOU list — and wants the app to read it instead of typing every name and amount by hand.

**Why this priority**: This is the entire value proposition of the feature — turning a photo into structured candidate data. Without it, nothing downstream (review, confirmation, saving) has anything to act on.

**Independent Test**: Can be fully tested by photographing (or uploading) a paper with several name/amount lines, running it through capture → enhance → OCR → parse, and confirming that a non-empty list of candidate entries is produced, each with a best-effort person name and amount.

**Acceptance Scenarios**:

1. **Given** the user chooses to scan a paper, **When** they take a photo with the in-app camera, **Then** the captured image is shown for the next step (crop/rotate/enhance).
2. **Given** the user chooses to scan a paper, **When** they instead pick an existing image from their device's gallery, **Then** that image is used identically to a freshly captured photo.
3. **Given** a captured or uploaded image, **When** the user proceeds, **Then** they can crop the image to the relevant area, rotate it to correct orientation, and apply a basic contrast/brightness enhancement before OCR runs.
4. **Given** an enhanced image containing a list such as "Ahmed — 1000 / Mohamed — 500 / Mahmoud — 2000 / Omar — 750", **When** OCR and parsing complete, **Then** the system produces one candidate entry per recognizable name/amount line, each pre-filled with a best-effort person name and amount.
5. **Given** the image also contains a date or an occasion-like heading (e.g. "Ahmed's Wedding — 15/9/2026"), **When** parsing completes, **Then** the system pre-fills the corresponding candidate entries' date and/or offers to tag the whole batch to that occasion name, without requiring the user to retype it.
6. **Given** the image is blurry, has no readable text, or contains no recognizable name/amount pattern, **When** OCR/parsing completes, **Then** the user is clearly told no entries could be extracted and is offered to retry, re-crop/enhance, or enter transactions manually instead — never shown a silently empty review screen with no explanation.

---

### User Story 2 - Review, Correct, and Confirm Before Anything Is Saved (Priority: P1)

A user has a batch of candidate entries produced from a scan and needs to check, correct, and explicitly approve each one — because OCR and parsing are never fully trustworthy — before any of it becomes a real, permanent transaction.

**Why this priority**: This is the safety-critical core of the feature and a direct, non-negotiable requirement of the product's engineering constitution. It must ship together with User Story 1 — a version of this feature that could auto-save from OCR is not a smaller version of the product, it is a different, unacceptable product.

**Independent Test**: Can be fully tested by producing a batch of candidate entries (via User Story 1 or a seeded test batch), deliberately corrupting one field on each, correcting them on the review screen, confirming some rows and discarding others, and verifying that only the confirmed, corrected rows become real transactions — with zero transactions created for discarded or unconfirmed rows, and zero transactions created anywhere in the app from OCR output that bypassed this screen.

**Acceptance Scenarios**:

1. **Given** a batch of candidate entries from a scan, **When** the user opens the review screen, **Then** every candidate entry is shown with its detected person name, amount, direction, date, and notes/occasion (where available), each editable, and none are pre-selected as already "saved."
2. **Given** a candidate entry's detected name is wrong (e.g. "Ahmed" OCR'd as "Ahmad"), **When** the user edits the name field, **Then** the correction is applied to that entry only and the system runs the same possible-duplicate-person check used for manual entry.
3. **Given** a candidate entry's detected amount is wrong (e.g. "1000" OCR'd as "1O00"), **When** the user edits the amount field, **Then** the correction is applied and validated with the same rules as manual transaction entry (positive amount required, decimal precision preserved).
4. **Given** a candidate entry's direction (money given vs. received) was not confidently detected, **When** the user views the review screen, **Then** a direction is still shown (defaulted per the batch-level default set in User Story 1/setup) but is clearly editable per entry, and the entry cannot be confirmed while its required fields (person, amount, direction) are incomplete or invalid.
5. **Given** the review screen is showing several entries, **When** the user decides one entry doesn't belong (e.g. a misread line that isn't actually a name/amount pair), **Then** they can discard that single entry without affecting the others.
6. **Given** the user has reviewed and corrected all the entries they want to keep, **When** they tap the final confirm action, **Then** only the confirmed entries are saved as real transactions — in one atomic batch — and every discarded or never-confirmed entry results in zero saved data.
7. **Given** the user backs out of the review screen entirely (cancels the scan) before confirming, **When** they do so, **Then** no transactions are created and the source image is handled per the retention rule (Assumptions), with a confirmation prompt if any corrections had already been made so accidental loss is avoided.
8. **Given** the app is later inspected (e.g., via a transaction's detail view), **When** the user opens a transaction that originated from an OCR scan, **Then** it is clearly marked as OCR-sourced and links back to its originating scan for traceability.

---

### User Story 3 - See Confidence and Trust Signals While Reviewing (Priority: P2)

A user reviewing a batch of extracted entries wants a quick visual sense of which fields the system is fairly sure about and which ones it guessed at, so they know where to look most carefully before confirming.

**Why this priority**: Builds trust and speeds up review, but the feature is still safe and usable without it (User Story 2's mandatory review/edit/confirm gate is what actually protects data integrity) — this is a UX enhancement layered on top of that gate.

**Independent Test**: Can be fully tested by scanning a paper containing both clearly printed and ambiguous/smudged text, and confirming that fields the OCR engine reports low confidence for are visually flagged differently from high-confidence fields on the review screen.

**Acceptance Scenarios**:

1. **Given** the underlying text-recognition step reports a confidence score for a recognized name or amount, **When** the review screen renders that field, **Then** a visual indicator (e.g. color or icon) reflects low/medium/high confidence, and low-confidence fields are visually prioritized for the user's attention (e.g. sorted first, or highlighted).
2. **Given** a field's value was not directly read from the image but inferred or defaulted by the parsing step (e.g. a direction guessed from context, or a date defaulted to today because none was found), **When** the review screen renders that field, **Then** it is visually marked as "inferred/defaulted," distinctly from a genuine OCR confidence score, so the user is never shown a false sense of certainty about something the system guessed rather than read.
3. **Given** every field on a given candidate entry has high confidence, **When** the user views the review screen, **Then** that entry is visually calm/unobtrusive relative to lower-confidence entries, so attention is naturally drawn to what needs checking.

---

### User Story 4 - Recover From a Failed or Low-Quality Scan (Priority: P2)

A user's photo doesn't produce usable results — too blurry, wrong angle, poor lighting, unrecognizable handwriting — and needs a clear, fast way to try again without losing momentum or being stuck.

**Why this priority**: Real-world photos of handwritten Egyptian paper lists will frequently be imperfect; without a graceful recovery path, users will abandon the feature entirely after one bad scan.

**Independent Test**: Can be fully tested by feeding the OCR/parsing pipeline a deliberately unreadable image and confirming the user is shown a clear failure state with actionable next steps, never a crash, infinite spinner, or silently empty screen.

**Acceptance Scenarios**:

1. **Given** OCR produces no readable text at all, **When** processing completes, **Then** the user sees an explanation and is offered to retake the photo, adjust crop/enhancement and retry, or switch to manual transaction entry.
2. **Given** OCR produces some text but nothing matches a name/amount pattern, **When** processing completes, **Then** the user is told entries could not be structured from the text found, with the same recovery options.
3. **Given** the device denies camera or photo-library permission, **When** the user tries to start a scan, **Then** the system explains why the permission is needed and how to grant it, without crashing.
4. **Given** OCR processing is taking a noticeable amount of time on a slower device, **When** the user is waiting, **Then** a clear in-progress state is shown (never an indefinite spinner with no way to cancel).

---

### User Story 5 - Review Past Scans (Priority: P3)

A user wants to look back at a scan they did previously — to re-check what was on the original paper, or to see which transactions came from it.

**Why this priority**: A trust/reference nice-to-have; the core recording value is fully delivered by User Stories 1-2 without it.

**Independent Test**: Can be fully tested by completing a scan (with at least one confirmed entry), then opening a scan-history view and confirming the original image and the resulting transactions are both retrievable.

**Acceptance Scenarios**:

1. **Given** the user has completed one or more scans, **When** they open the scan history, **Then** each past scan is listed with its date, source image thumbnail, and how many entries were confirmed/discarded.
2. **Given** a past scan, **When** the user opens it, **Then** they can view the original (enhanced) image and the list of transactions that were created from it, each linking to its full transaction detail.
3. **Given** a past scan produced zero confirmed entries (fully discarded or abandoned), **When** the user views scan history, **Then** it is still listed (for reference/debugging their own scanning habits) but clearly marked as having produced nothing.

---

### Edge Cases

- What happens when the same physical paper is scanned twice (accidentally or deliberately)? The system does not attempt automatic duplicate-transaction detection across scans (OCR text alone cannot reliably prove two scans are "the same" transaction); instead, the existing per-person duplicate-name warning (from manual entry) still applies to any new person created during review, and the user is relied upon to recognize duplicate amounts during review — this is a documented limitation, not a bug.
- What happens when a name in the photo closely matches an existing person's name? The same possible-duplicate-person check used in manual entry (001, FR-003) runs during review, letting the user pick the existing person instead of creating a near-duplicate.
- What happens when the image contains mixed Arabic and English text, or Arabic-Indic and Western numerals in the same list? Both must be recognized where technically possible, and Arabic-Indic numerals are normalized identically to manual entry (consistent with 001, FR-023).
- What happens when a detected amount is ambiguous due to OCR character confusion (e.g. "0" vs "O", "1" vs "l")? The system does not attempt to silently guess; the field is shown for the user to visually verify against the source image (the enhanced image remains viewable during review) and correct if wrong.
- What happens when the user rotates/crops the image in a way that cuts off part of the list? Only what remains in the cropped image is processed; the user can re-crop and re-run OCR before proceeding to review.
- What happens when parsing detects more candidate lines than the user actually wants recorded (e.g. a subtotal or page header misread as a name/amount pair)? Any candidate entry can be individually discarded on the review screen without affecting the others (User Story 2).
- What happens if the user's device has no OCR capability available at all (very old/unsupported hardware)? The scan entry point clearly explains the feature is unavailable on this device and directs the user to manual entry, rather than presenting a broken flow.
- What happens when the user backgrounds the app mid-scan (e.g. takes a call during OCR processing)? Processing continues or resumes correctly when the app returns to the foreground; an in-progress scan is not silently lost.
- What happens when a candidate entry's amount would exceed the app's existing maximum-amount validation ceiling? It is rejected with the same validation message used in manual entry, and the entry cannot be confirmed until corrected.
- What happens when the user wants to tag the whole scan to an existing Occasion versus create a new one versus leave it untagged? All three are supported at review time; tagging to an Occasion changes the resulting transactions' kind to an occasion contribution (008) exactly as if they had been entered manually as occasion participants — never a separate, disconnected record.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to start a scan by either capturing a photo with the in-app camera or selecting an existing image from their device's photo library.
- **FR-002**: The system MUST let the user crop, rotate, and apply a basic enhancement (contrast/brightness) to the captured or selected image before text recognition runs, and MUST let the user redo this step and re-run recognition without restarting the entire scan from the camera.
- **FR-003**: The system MUST run on-device text recognition on the prepared image and parse the recognized text into zero or more candidate entries, each targeting: person name, amount, direction, date, occasion, and notes — matching the fields of the existing money-transaction model (001) plus the occasion link (008) where applicable.
- **FR-004**: When zero candidate entries can be produced (no readable text, or no text matching a recognizable name/amount pattern), the system MUST clearly explain this to the user and offer to retry capture, adjust crop/enhancement, or switch to manual transaction entry — never silently show an empty review screen.
- **FR-005**: The system MUST let the user set a batch-level default transaction direction (money received / money given) before or during review, applied to every candidate entry that doesn't have a confidently detected direction of its own, while remaining individually overridable per entry.
- **FR-006**: The system MUST present every candidate entry on a single review screen, showing all of its fields (person name, amount, direction, date, occasion if tagged, notes) in an editable form, before any entry can be confirmed.
- **FR-007**: The system MUST NEVER create, persist, or otherwise save a Money Transaction (or Occasion participant contribution) directly from OCR or parsing output. A transaction MAY be created only after the user has explicitly reviewed that specific candidate entry on the review screen and explicitly confirmed it (whether or not they made any corrections first). This requirement has no exceptions, including for high-confidence entries.
- **FR-008**: The system MUST let the user edit any field of any candidate entry (person, amount, direction, date, occasion, notes) before confirming it, applying the exact same validation rules already enforced for manual transaction entry (positive amount required, decimal precision with no rounding drift, maximum-amount ceiling, Arabic-Indic/Western numeral equivalence).
- **FR-009**: The system MUST run the existing possible-duplicate-person check (001, FR-003) whenever a candidate entry's person name would create a new person, and let the user pick the existing person instead, exactly as in manual entry.
- **FR-010**: The system MUST let the user discard any individual candidate entry from the review screen without affecting any other entry in the same batch.
- **FR-011**: The system MUST let the user confirm the batch, saving only the entries that were explicitly confirmed (not discarded, not left unconfirmed) as real transactions in a single atomic operation — either all confirmed entries are saved, or, on failure, none are, with a clear error and no partial silent save.
- **FR-012**: Every transaction created from a confirmed candidate entry MUST retain a durable reference back to its originating scan (source = OCR) and, where available, the confidence/inference metadata for its fields, satisfying the app's transaction-model's "OCR metadata"/"source" concept without altering how non-OCR transactions are created or displayed.
- **FR-013**: Where the underlying text-recognition step provides a confidence score for a recognized field, the review screen MUST visually indicate low/medium/high confidence for that field; where a field's value was inferred or defaulted rather than directly read (e.g. a defaulted date or a batch-default direction), the review screen MUST visually distinguish it as "inferred," never presenting an inferred value with the same visual trust signal as a genuinely high-confidence OCR read.
- **FR-014**: The system MUST let the user optionally tag an entire scan batch to a new or existing Occasion (008) at review time; when tagged, every confirmed entry from that batch is saved as an Occasion participant contribution (008's transaction kind) rather than a plain person-to-person transaction, exactly as if entered manually through the Occasions feature.
- **FR-015**: The system MUST let the user cancel a scan at any point before final confirmation with no transactions created; if the user had already made corrections on the review screen, the system MUST ask for confirmation before discarding that in-progress work.
- **FR-016**: The system MUST request camera and photo-library permissions contextually (only when the user initiates a scan), explain why each is needed, and handle a denial gracefully with a clear explanation and a path to manual entry — never a crash or a silently broken flow.
- **FR-017**: The system MUST show a clear, cancelable in-progress state while text recognition/parsing is running, and MUST handle the app being backgrounded during processing without losing or corrupting the in-progress scan.
- **FR-018**: The system MUST let the user view a history of past scans, each showing its date, source image, and the outcome (number of entries confirmed vs. discarded), and MUST let the user open a past scan to view its source image and the transactions that resulted from it.
- **FR-019**: The system MUST perform all image capture, cropping/enhancement, text recognition, and parsing entirely on-device, with no dependency on network connectivity, consistent with the app's offline-first operation and its privacy posture of not sending user photos to a third-party service without explicit, separate consent (out of scope for v1.5 — no such consent flow exists yet, so no image ever leaves the device in this feature).
- **FR-020**: The system MUST accept numeric input (both typed corrections and OCR-recognized digits) in both Arabic-Indic and Western numeral forms as equivalent values, consistent with 001's FR-023.
- **FR-021**: The system MUST prevent a single confirm action (including a rapid repeated tap) from saving the same batch of entries more than once.
- **FR-022**: The system MUST present all scan, crop/enhance, review, and scan-history screens fully localized in both Arabic and English, with correct RTL/LTR layout, number formatting, and date formatting per the active language, and correctly themed in both light and dark mode.
- **FR-023**: The system MUST retain the captured/enhanced source image locally for as long as its scan record exists (so past scans remain reviewable per User Story 5), store it only in the app's private sandboxed storage, and never upload it anywhere; the user MUST be able to delete a past scan (and its source image) from their device.
- **FR-024**: The system MUST cap the number of candidate entries produced from a single image at a documented practical ceiling (Assumptions) and, if more name/amount-like lines are detected than the ceiling, MUST inform the user that only the first N were parsed and suggest scanning the remainder as a separate batch, rather than silently truncating with no explanation.

### Key Entities *(include if feature involves data)*

- **OCR Scan**: A single user-initiated scanning session. Attributes: the source image reference (local file path, private storage only), capture/enhancement metadata (crop bounds, rotation applied), timestamp, processing status (processing / needs-review / confirmed / discarded / failed), and the list of Candidate Entries it produced. A Scan is the audit unit — every transaction that originated from OCR traces back to exactly one Scan.
- **Candidate Entry**: One proposed transaction extracted from a Scan, before any user confirmation. Attributes: detected/edited person name, amount, direction, date, occasion tag (optional), notes, a per-field confidence indicator (score where the recognition engine provides one, or an explicit "inferred/defaulted" marker where it does not), and a status (pending review / confirmed / discarded). A Candidate Entry becomes a real Money Transaction (or Occasion participant contribution) only upon explicit confirmation (FR-007) — until then it has no effect anywhere else in the app.
- **Money Transaction (extended, from 001)**: Gains a `source` concept (manual vs. OCR) and, for OCR-sourced transactions, a durable link back to the originating Scan/Candidate Entry, so the app's existing balance/history features display and audit OCR-originated money exactly like manually entered money, with full traceability of where it came from (FR-012). No change to how balances/history are computed for existing manually entered transactions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can go from opening the scan feature to seeing a populated review screen for a clearly printed list of 5 names/amounts in under 30 seconds, including capture and processing time.
- **SC-002**: 100% of transactions ever created by this feature were created only after passing through the review-and-confirm screen — verified with zero exceptions across all tested scan/review/confirm/discard/cancel paths, including forced-failure and rapid-repeat-tap scenarios.
- **SC-003**: In usability testing with realistically imperfect photos (varied lighting/angle, mixed Arabic/English, mixed numeral systems), at least 80% of clearly printed name/amount lines are correctly pre-filled (name and amount both readable as intended) without the user needing to fully retype them.
- **SC-004**: 0% of scans that produce zero usable candidates leave the user without a clear next step (retry, adjust, or manual entry) — verified across all tested failure scenarios.
- **SC-005**: A user can discard an individual unwanted candidate entry and confirm the rest of a batch in under 10 seconds of interaction once the review screen is open.
- **SC-006**: Zero duplicate transaction batches are ever produced from a single confirm action, including rapid repeated taps.
- **SC-007**: A user can locate, from scan history, the original photo and every transaction that resulted from a specific past scan, 100% of the time the scan is still retained on the device.

## Assumptions

- **On-device processing**: Text recognition runs entirely on-device (no cloud OCR service) for this feature, prioritizing privacy (no photo of a user's financial notes ever leaves the device without a separate, explicit consent flow that does not exist yet) and offline capability over the marginal accuracy a cloud vision model might add, consistent with the product's offline-first and privacy-first posture (docs/project.txt §16, §19). This is a deliberate v1.5 scope decision; a future, clearly consent-gated cloud/AI-assisted OCR mode is a possible later enhancement, not part of this spec.
- **Handwriting is best-effort, not guaranteed**: On-device recognition is materially better at printed text than handwriting, and Arabic handwritten text recognition in particular is currently the weakest case for any available on-device engine. This feature does not promise a minimum accuracy for handwritten input — the mandatory review/confirm gate (User Story 2, FR-007) exists specifically so that even poor recognition never produces bad data, only a slower manual-correction experience.
- **Direction is often not detectable from the source text alone**: A plain "Name — Amount" line carries no inherent direction. The batch-level default-direction control (FR-005) is the primary mechanism for handling this common case efficiently, with per-entry override for exceptions within the same photo (e.g. a list that's mostly money received but includes one line that was actually given back).
- **Scope boundary**: This feature covers image-to-candidate-entry extraction and the mandatory review/confirm gate only. It does not include an AI/LLM step of any kind (structuring is done by deterministic text-pattern parsing over the OCR engine's output, not an LLM) — the product's own roadmap places the AI assistant in a later tier, and constitution Principle IX (AI Isolation) and Principle X (OCR confirmation) both apply regardless, but no AI integration exists in this spec at all. Budgets, savings goals, and the AI assistant are out of scope.
- **Candidate ceiling**: The practical per-image ceiling (FR-024) is set at 50 candidate entries per scan, comfortably above a realistic single-page guest/debt list, to bound processing time and review-screen complexity on mid-range devices.
- **Relationship to Occasions (008)**: Tagging a scan batch to an Occasion (FR-014) reuses 008's existing Occasion participant contribution transaction kind and its `countsTowardBalance` default behavior unchanged (including the condolence-type default) — this feature does not introduce a second way to link a transaction to an occasion.
- **Image retention and deletion**: Source images are retained only as long as their Scan record exists; deleting a Scan (FR-023) deletes its image file. There is no separate, automatic image-retention time limit in this spec beyond explicit user deletion — a future privacy-hardening pass may add an auto-purge policy, but that is not required for v1.5.
- **No cross-scan duplicate detection**: As documented in Edge Cases, the system does not attempt to detect that two separate scans represent the same physical paper or the same real-world transaction; this is a reasonable, explicitly documented limitation rather than a gap to silently work around, since reliably solving it would require exactly the kind of unverified inference the OCR-confirmation principle exists to guard against.
