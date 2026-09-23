import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../../people/domain/entities/person.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../domain/entities/candidate_entry.dart';
import '../../domain/usecases/cancel_scan.dart';
import '../../domain/usecases/confirm_scan_batch.dart';
import '../../domain/usecases/discard_candidate_entry.dart';
import '../../domain/usecases/edit_candidate_entry.dart';
import '../../domain/usecases/get_candidate_entries.dart';
import '../../domain/usecases/get_possible_duplicate_for_candidate.dart';
import '../../domain/usecases/get_scan_detail.dart';
import '../../domain/usecases/set_batch_default_direction.dart';
import '../../domain/usecases/tag_batch_to_occasion.dart';
import 'scan_review_state.dart';

/// Drives the review screen — the one gate between OCR output and money
/// (constitution Principle X, FR-007).
///
/// Two rules shape almost everything below:
///
/// * **It decides nothing about validity itself.** Whether an entry may
///   become a transaction is [CandidateEntry.isConfirmEligible], defined
///   once on the entity and evaluated here against the batch default. A
///   second copy of that rule living in the cubit could only ever disagree
///   in the direction of "the UI let something through".
/// * **It never writes money.** Corrections go through `EditCandidateEntry`
///   against candidate rows; the only call that can create a
///   `MoneyTransaction` is [confirm], and it is guarded by an
///   immediately-emitted submitting status so a second tap cannot reach it.
@injectable
class ScanReviewCubit extends Cubit<ScanReviewState> {
  ScanReviewCubit(
    this._getScanDetail,
    this._getCandidateEntries,
    this._editCandidateEntry,
    this._discardCandidateEntry,
    this._confirmScanBatch,
    this._cancelScan,
    this._setBatchDefaultDirection,
    this._tagBatchToOccasion,
    this._getPossibleDuplicateForCandidate,
    this._egpFormatter,
  ) : super(const ScanReviewState());

  final GetScanDetail _getScanDetail;
  final GetCandidateEntries _getCandidateEntries;
  final EditCandidateEntry _editCandidateEntry;
  final DiscardCandidateEntry _discardCandidateEntry;
  final ConfirmScanBatch _confirmScanBatch;
  final CancelScan _cancelScan;
  final SetBatchDefaultDirection _setBatchDefaultDirection;
  final TagBatchToOccasion _tagBatchToOccasion;
  final GetPossibleDuplicateForCandidate _getPossibleDuplicateForCandidate;
  final EgpFormatter _egpFormatter;

  /// Loads the batch: the scan (for its default direction and occasion tag)
  /// and its candidate entries in review order (FR-008).
  Future<void> load(String scanId) async {
    emit(
      state.copyWith(
        scanId: scanId,
        status: ScanReviewStatus.loading,
        clearFailure: true,
      ),
    );

    final detailResult = await _getScanDetail(scanId);
    if (isClosed) return;
    Failure? failure;
    final scan = detailResult.match((f) {
      failure = f;
      return null;
    }, (detail) => detail.scan);
    if (scan == null) {
      emit(
        state.copyWith(status: ScanReviewStatus.loadFailure, failure: failure),
      );
      return;
    }

    final entriesResult = await _getCandidateEntries(scanId);
    if (isClosed) return;
    entriesResult.match(
      (f) => emit(
        state.copyWith(status: ScanReviewStatus.loadFailure, failure: f),
      ),
      (entries) => emit(
        state.copyWith(
          status: ScanReviewStatus.ready,
          scan: scan,
          entries: List.unmodifiable(entries),
        ),
      ),
    );
  }

  // --- Per-entry corrections (FR-008) -------------------------------------

  /// Applies a name correction to one entry and re-runs the very same
  /// possible-duplicate check manual entry runs, so the page can offer
  /// 001's duplicate-warning flow (FR-009).
  Future<void> personNameChanged(String entryId, String name) async {
    // Clearing the resolved person is the point: the name no longer refers
    // to whoever was matched before, and silently keeping the old link
    // would file the money against the wrong person.
    final result = await _editCandidateEntry(
      entryId: entryId,
      personName: name,
      clearMatchedPersonId: true,
    );
    if (isClosed) return;
    result.match(
      (f) => emit(state.copyWith(failure: f)),
      (entry) => emit(state.copyWith(entries: _replaced(entry))),
    );

    final duplicates = await _getPossibleDuplicateForCandidate(name);
    if (isClosed) return;
    duplicates.match(
      (f) => emit(state.copyWith(personLookupFailure: f)),
      (matches) => emit(
        state.copyWith(
          duplicateMatches: {...state.duplicateMatches, entryId: matches},
          clearPersonLookupFailure: true,
        ),
      ),
    );
  }

  /// Resolves an entry to an existing person — the "use the one I already
  /// have" half of the duplicate flow.
  Future<void> personSelected(String entryId, Person person) async {
    final result = await _editCandidateEntry(
      entryId: entryId,
      personName: person.name,
      matchedPersonId: person.id,
    );
    if (isClosed) return;
    result.match((f) => emit(state.copyWith(failure: f)), (entry) {
      emit(
        state.copyWith(
          entries: _replaced(entry),
          duplicateMatches: _withoutMatches(entryId),
        ),
      );
    });
  }

  /// The user looked at the matches and decided this really is somebody
  /// new. Nothing is written now — the person is created at confirm time,
  /// exactly as manual entry behaves — so all this does is stop offering
  /// the matches.
  void dismissDuplicateMatches(String entryId) {
    if (!state.duplicateMatches.containsKey(entryId)) return;
    emit(state.copyWith(duplicateMatches: _withoutMatches(entryId)));
  }

  /// Applies an amount correction, accepting Arabic-Indic and Western
  /// digits as equivalent input (FR-008) and refusing a non-positive
  /// amount exactly as the manual transaction form does.
  Future<void> amountChanged(String entryId, String text) async {
    final Money amount;
    try {
      final parsed = _egpFormatter.parse(NumeralParser.toWesternDigits(text));
      if (!parsed.isPositive) {
        throw const FormatException('Amount must be greater than zero');
      }
      amount = parsed;
    } on FormatException {
      emit(
        state.copyWith(
          invalidAmountEntryIds: {...state.invalidAmountEntryIds, entryId},
        ),
      );
      return;
    }

    final result = await _editCandidateEntry(
      entryId: entryId,
      amountMinorUnits: amount.minorUnits,
    );
    if (isClosed) return;
    result.match(
      (f) => emit(state.copyWith(failure: f)),
      (entry) => emit(
        state.copyWith(
          entries: _replaced(entry),
          invalidAmountEntryIds: {...state.invalidAmountEntryIds}
            ..remove(entryId),
        ),
      ),
    );
  }

  Future<void> directionChanged(
    String entryId,
    TransactionDirection direction,
  ) async {
    final result = await _editCandidateEntry(
      entryId: entryId,
      direction: direction,
    );
    if (isClosed) return;
    result.match(
      (f) => emit(state.copyWith(failure: f)),
      (entry) => emit(state.copyWith(entries: _replaced(entry))),
    );
  }

  Future<void> dateChanged(String entryId, DateTime date) async {
    final result = await _editCandidateEntry(entryId: entryId, date: date);
    if (isClosed) return;
    result.match(
      (f) => emit(state.copyWith(failure: f)),
      (entry) => emit(state.copyWith(entries: _replaced(entry))),
    );
  }

  Future<void> notesChanged(String entryId, String notes) async {
    final result = await _editCandidateEntry(entryId: entryId, notes: notes);
    if (isClosed) return;
    result.match(
      (f) => emit(state.copyWith(failure: f)),
      (entry) => emit(state.copyWith(entries: _replaced(entry))),
    );
  }

  /// Drops one misread line from the batch without touching its siblings
  /// (FR-010).
  Future<void> discardEntry(String entryId) async {
    final result = await _discardCandidateEntry(entryId);
    if (isClosed) return;
    result.match((f) => emit(state.copyWith(failure: f)), (_) {
      final index = state.entries.indexWhere((entry) => entry.id == entryId);
      if (index < 0) return;
      emit(
        state.copyWith(
          entries: _replaced(
            state.entries[index].copyWith(
              status: CandidateEntryStatus.discarded,
            ),
          ),
          duplicateMatches: _withoutMatches(entryId),
          invalidAmountEntryIds: {...state.invalidAmountEntryIds}
            ..remove(entryId),
        ),
      );
    });
  }

  // --- Batch-level controls ----------------------------------------------

  /// Sets the direction every entry without one of its own falls back to
  /// (FR-005). Entries that carry their own direction are untouched by the
  /// repository, so a correction is never undone by a later default.
  Future<void> setDefaultDirection(TransactionDirection direction) async {
    final result = await _setBatchDefaultDirection(
      scanId: state.scanId,
      direction: direction,
    );
    if (isClosed) return;
    result.match(
      (f) => emit(state.copyWith(failure: f)),
      (scan) => emit(state.copyWith(scan: scan, clearFailure: true)),
    );
  }

  /// Tags — or, with `null`, untags — the whole batch to an occasion
  /// (FR-014).
  Future<void> tagToOccasion(String? occasionId) async {
    final result = await _tagBatchToOccasion(
      scanId: state.scanId,
      occasionId: occasionId,
    );
    if (isClosed) return;
    result.match(
      (f) => emit(state.copyWith(failure: f)),
      (scan) => emit(state.copyWith(scan: scan, clearFailure: true)),
    );
  }

  // --- The gate ----------------------------------------------------------

  /// Confirms the batch (FR-007, FR-011, FR-021).
  ///
  /// The single-flight guard is the first statement and the submitting
  /// status is emitted *before* the first `await`, so a second tap arriving
  /// in the same frame — before any widget has rebuilt — is already looking
  /// at `isSubmitting == true` and returns without calling the use case.
  /// The freshly generated idempotency key is the second line of defence:
  /// it belongs to this attempt only, so a genuine retry after a failure is
  /// a new attempt rather than a silently swallowed duplicate.
  Future<void> confirm() async {
    if (state.isSubmitting || state.isSuccess) return;
    if (!state.canConfirm) {
      emit(state.copyWith(validationFailureEntryIds: state.ineligibleEntryIds));
      return;
    }

    final idempotencyKey = const Uuid().v4();
    emit(
      state.copyWith(
        status: ScanReviewStatus.submitting,
        idempotencyKey: idempotencyKey,
        validationFailureEntryIds: const {},
        clearFailure: true,
      ),
    );

    final result = await _confirmScanBatch(
      idempotencyKey: idempotencyKey,
      scanId: state.scanId,
    );
    if (isClosed) return;

    await result.match(
      (failure) async {
        emit(state.copyWith(status: ScanReviewStatus.ready, failure: failure));
        // The repository refused the batch as incomplete while this screen
        // believed it complete — so the screen's picture is the stale one.
        // Reload and recompute rather than parsing entry ids out of a
        // message, and say nothing was saved (FR-011, all-or-nothing).
        if (failure is ValidationFailure) await _surfaceIncompleteEntries();
      },
      (transactions) async {
        emit(
          state.copyWith(
            status: ScanReviewStatus.success,
            savedTransactions: List.unmodifiable(transactions),
          ),
        );
      },
    );
  }

  Future<void> _surfaceIncompleteEntries() async {
    final entriesResult = await _getCandidateEntries(state.scanId);
    if (isClosed) return;
    entriesResult.match(
      (_) {
        // Keep the confirm failure already on screen: a follow-up read
        // failing tells the user nothing new, and replacing the message
        // would hide why the save was refused.
      },
      (entries) {
        final refreshed = state.copyWith(entries: List.unmodifiable(entries));
        emit(
          refreshed.copyWith(
            validationFailureEntryIds: refreshed.ineligibleEntryIds,
          ),
        );
      },
    );
  }

  // --- Cancellation (FR-015) ---------------------------------------------

  /// Requests cancellation. When corrections exist, this only raises
  /// [ScanReviewState.requiresCancelConfirmation] — the scan is not
  /// abandoned until [confirmCancel], so work the user put in never
  /// vanishes on a stray back-tap.
  Future<void> cancel() async {
    if (state.isSubmitting) return;
    if (state.hasUnsavedCorrections) {
      emit(state.copyWith(requiresCancelConfirmation: true));
      return;
    }
    await confirmCancel();
  }

  /// Abandons the scan for real, after the prompt (when one was needed).
  Future<void> confirmCancel() async {
    emit(state.copyWith(requiresCancelConfirmation: false, clearFailure: true));
    final result = await _cancelScan(state.scanId);
    if (isClosed) return;
    result.match(
      (f) => emit(state.copyWith(failure: f)),
      (_) => emit(state.copyWith(status: ScanReviewStatus.cancelled)),
    );
  }

  void dismissCancelConfirmation() {
    if (!state.requiresCancelConfirmation) return;
    emit(state.copyWith(requiresCancelConfirmation: false));
  }

  // --- Helpers ------------------------------------------------------------

  /// Builds a brand-new list with [updated] in place of its predecessor.
  /// Never `entries[i] = updated` — the list inside state is not ours to
  /// write to (constitution Principle IV).
  List<CandidateEntry> _replaced(CandidateEntry updated) => List.unmodifiable([
    for (final entry in state.entries)
      if (entry.id == updated.id) updated else entry,
  ]);

  Map<String, List<Person>> _withoutMatches(String entryId) =>
      {...state.duplicateMatches}..remove(entryId);
}
