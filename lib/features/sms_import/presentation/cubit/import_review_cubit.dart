import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/domain/usecases/get_categories.dart';
import '../../../people/domain/entities/people_failures.dart';
import '../../../people/domain/entities/person.dart';
import '../../../people/domain/repositories/people_repository.dart';
import '../../../people/domain/usecases/create_person.dart';
import '../../../people/domain/usecases/find_possible_duplicate_person.dart';
import '../../domain/entities/pending_sms_import.dart';
import '../../domain/entities/review_draft.dart';
import '../../domain/entities/sms_import_enums.dart';
import '../../domain/entities/sms_import_failures.dart';
import '../../domain/entities/sms_value_types.dart';
import '../../domain/services/review_lease_registry.dart';
import '../../domain/usecases/add_imported_transaction.dart';
import '../../domain/usecases/check_duplicates.dart';
import '../../domain/usecases/close_as_duplicate.dart';
import '../../domain/usecases/get_pending_import.dart';
import '../../domain/usecases/get_pending_imports.dart';
import '../../domain/usecases/ignore_import.dart';
import '../../domain/usecases/mute_sender.dart';
import '../../domain/usecases/show_original_message.dart';
import '../../domain/usecases/watch_sms_import_settings.dart';
import 'import_review_state.dart';

/// Review of ONE pending import (T078, ui-contract §3.4).
///
/// It coordinates use cases only. The draft is a value object validated
/// by the domain rule `ReviewDraft.validate()`; Add calls
/// `AddImportedTransaction`, the only path that turns an import into money
/// (FR-052), single-flight. While open it holds a review lease so a
/// re-parse never replaces fields under the user (research Decision 7).
///
/// T132: Ignore and "Stop suggesting from this sender" close the item
/// without adding anything. Their use cases are named parameters so the
/// existing direct constructions keep compiling; DI always passes them,
/// and without one the page does not offer that action.
///
/// T138: the transfer and people suggestions (FR-051a/b, FR-054). The
/// settings reader is optional for the same reason; without it an ATM item
/// keeps its parsed suggestion.
@injectable
class ImportReviewCubit extends Cubit<ImportReviewState> {
  ImportReviewCubit(
    this._getPending,
    this._getPendingList,
    this._addImported,
    this._checkDuplicates,
    this._showOriginal,
    this._leases,
    this._getCategories,
    this._people,
    this._createPerson,
    this._closeAsDuplicate, {
    IgnoreImport? ignoreImport,
    MuteSender? muteSender,
    WatchSmsImportSettings? watchSettings,
  }) : _ignoreImport = ignoreImport,
       _muteSender = muteSender,
       _watchSettings = watchSettings,
       super(ImportReviewState());

  final GetPendingImport _getPending;
  final GetPendingImports _getPendingList;
  final AddImportedTransaction _addImported;
  final CheckDuplicates _checkDuplicates;
  final ShowOriginalMessage _showOriginal;
  final ReviewLeaseRegistry _leases;
  final GetCategories _getCategories;
  final PeopleRepository _people;
  final CreatePerson _createPerson;
  final CloseAsDuplicate _closeAsDuplicate;
  final IgnoreImport? _ignoreImport;
  final MuteSender? _muteSender;
  final WatchSmsImportSettings? _watchSettings;

  /// Whether Ignore is offered.
  bool get canIgnore => _ignoreImport != null;

  /// Whether "Stop suggesting from this sender" is offered: only for an
  /// item with a sender (scan and catch-up, never paste or share, FR-065).
  bool get canMuteSender =>
      _muteSender != null && (state.item?.senderId?.trim() ?? '').isNotEmpty;

  /// How long edits settle before the duplicate check re-runs.
  static const Duration duplicateCheckDebounce = Duration(milliseconds: 300);

  ReviewLease? _lease;
  Timer? _debounce;
  int _checkGeneration = 0;

  // ------------------------------------------------------------------ load

  Future<void> load(String importId) async {
    emit(
      state.copyWith(
        status: ImportReviewStatus.loading,
        pendingId: importId,
        clearFailure: true,
      ),
    );
    _lease?.release();
    _lease = _leases.acquire(importId);

    final result = await _getPending(importId);
    if (isClosed) return;
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(
        state.copyWith(
          status: failure is NotFoundFailure
              ? ImportReviewStatus.alreadyHandled
              : ImportReviewStatus.loadFailure,
          failure: failure,
        ),
      );
      return;
    }
    final item = result.getOrElse((_) => throw StateError('unreachable'));
    if (!item.isPending) {
      _releaseLease();
      emit(state.copyWith(status: ImportReviewStatus.alreadyHandled));
      return;
    }

    final countCash = await _readCountCash();
    if (isClosed) return;
    final draft = initialDraftFor(item, countCashWithdrawals: countCash);
    emit(
      state.copyWith(
        status: ImportReviewStatus.ready,
        item: item,
        countCashWithdrawals: countCash,
        clearCountCash: countCash == null,
        draft: draft,
        initialDraft: draft,
        amountInput: draft.amountMinorUnits == null
            ? ''
            : formatMinor(draft.amountMinorUnits!),
      ),
    );

    await Future.wait([
      _loadCategoriesFor(draft.type),
      _loadSuggestedPerson(draft.personId),
      _loadParent(item.parentImportId),
      _loadSimilarPeople(item),
    ]);
    if (isClosed) return;
    // The draft after category/person reconciliation is the baseline.
    emit(state.copyWith(initialDraft: state.draft));
    await runDuplicateCheck();
  }

  /// The draft as first shown: the parsed suggestion, never a decision.
  ///
  /// - type: the suggested type when it is savable; `ignore`/`unset` show
  ///   none selected (FR-033);
  /// - amount: the parsed amount; with no amount but exactly one candidate
  ///   (no stated currency, FR-053) the candidate is pre-filled and the
  ///   currency stays empty and required; two candidates give one-tap
  ///   chips and no amount (FR-030);
  /// - category/person: the suggestion for the type; note: never prefilled
  ///   (FR-049).
  ///
  /// [countCashWithdrawals] is the CURRENT "count cash withdrawals as
  /// spending" preference (FR-051b): it decides an ATM item's default even
  /// when the preference changed after the message was parsed. `null`
  /// (unknown) keeps the parsed suggestion.
  static ReviewDraft initialDraftFor(
    PendingSmsImport item, {
    bool? countCashWithdrawals,
  }) {
    final suggested = ImportReviewState.suggestionFor(
      item,
      countCashWithdrawals,
    );
    final type = suggested.isSavable ? suggested : null;
    final amount = item.amount;
    final candidates = item.amountCandidates;
    return ReviewDraft(
      type: type,
      amountMinorUnits:
          amount?.minorUnits ??
          (candidates.length == 1 ? candidates.single : null),
      currencyCode: amount?.currency.code,
      date: item.occurredOn,
      categoryId: type != null && type == item.suggestedType
          ? item.suggestedCategoryId
          : null,
      personId: type != null && type.isPersonTransaction
          ? item.suggestedPersonId
          : null,
    );
  }

  /// The cash preference, or `null` when it can't be read.
  Future<bool?> _readCountCash() async {
    final watch = _watchSettings;
    if (watch == null) return null;
    final result = await watch.current();
    return result.match((_) => null, (s) => s.countCashWithdrawals);
  }

  /// After the user came back from the cash-withdrawal preference (the ATM
  /// link, FR-051b): re-reads it and, while the draft is untouched, applies
  /// the new default. Edits are never replaced.
  Future<void> refreshCashPreference() async {
    final item = state.item;
    if (item == null || item.kind != SmsKind.atmWithdrawal) return;
    final countCash = await _readCountCash();
    if (isClosed || countCash == null) return;
    if (countCash == state.countCashWithdrawals) return;
    if (state.status != ImportReviewStatus.ready || state.isDirty) {
      emit(state.copyWith(countCashWithdrawals: countCash));
      return;
    }
    final draft = initialDraftFor(item, countCashWithdrawals: countCash);
    emit(
      state.copyWith(
        countCashWithdrawals: countCash,
        draft: draft,
        initialDraft: draft,
      ),
    );
    await _loadCategoriesFor(draft.type);
    if (isClosed) return;
    emit(state.copyWith(initialDraft: state.draft));
    _scheduleDuplicateCheck();
  }

  /// Amounts are entered in major units; every catalog currency has 100
  /// minor units (asserted by the parser tests).
  static String formatMinor(int minor) {
    final whole = minor ~/ 100;
    final fraction = (minor % 100).toString().padLeft(2, '0');
    return '$whole.$fraction';
  }

  Future<void> _loadCategoriesFor(SuggestedRecordType? type) async {
    if (type == null || !type.isFinanceEntry) {
      emit(state.copyWith(categories: const [], categoriesLoading: false));
      return;
    }
    emit(state.copyWith(categoriesLoading: true));
    final result = await _getCategories(
      type: type == SuggestedRecordType.income
          ? FinanceEntryType.income
          : FinanceEntryType.expense,
    );
    if (isClosed) return;
    final categories = result.getOrElse((_) => const []);
    var draft = state.draft;
    // A suggested category that is archived or gone is cleared rather
    // than blocking (FR-055).
    final selected = draft?.categoryId;
    if (draft != null &&
        selected != null &&
        !categories.any((c) => c.id == selected)) {
      draft = draft.copyWith(clearCategory: true);
    }
    emit(
      state.copyWith(
        categories: categories,
        categoriesLoading: false,
        draft: draft,
      ),
    );
  }

  Future<void> _loadSuggestedPerson(String? personId) async {
    if (personId == null) return;
    final result = await _people.getPersonById(personId);
    if (isClosed) return;
    result.match(
      (_) => emit(
        state.copyWith(
          draft: state.draft?.copyWith(clearPerson: true),
          clearSelectedPerson: true,
        ),
      ),
      (person) => emit(
        state.copyWith(selectedPerson: person, personQuery: person.name),
      ),
    );
  }

  /// The existing similar-name choice (FR-054): for a named transfer with
  /// no single exact match, the people whose names could match the
  /// counterparty under the app's duplicate-name rule. Offered only when
  /// more than one person could match. Read-only: nobody is created.
  Future<void> _loadSimilarPeople(PendingSmsImport item) async {
    final name = item.counterparty?.trim() ?? '';
    if (name.isEmpty ||
        item.suggestedPersonId != null ||
        (item.kind != SmsKind.transferIn && item.kind != SmsKind.transferOut)) {
      return;
    }
    final result = await _people.searchActivePeople();
    if (isClosed) return;
    final people = result.getOrElse((_) => const []);
    final matches = const FindPossibleDuplicatePerson()(name, people);
    if (matches.length > 1) {
      emit(state.copyWith(similarPeople: matches));
    }
  }

  Future<void> _loadParent(String? parentId) async {
    if (parentId == null) return;
    final result = await _getPending(parentId);
    if (isClosed) return;
    final parent = result.toNullable();
    if (parent != null && parent.isPending) {
      emit(state.copyWith(parent: parent));
    }
  }

  // ----------------------------------------------------------------- edits

  void _edit(ReviewDraft draft, {String? amountInput}) {
    if (state.status != ImportReviewStatus.ready) return;
    emit(
      state.copyWith(
        draft: draft,
        amountInput: amountInput,
        clearFailure: true,
      ),
    );
    _scheduleDuplicateCheck();
  }

  /// Switches between expense/income (category) and given/received
  /// (person), swapping the required field (FR-048). Repayment and
  /// occasion contribution are never values.
  Future<void> typeChanged(SuggestedRecordType type) async {
    final draft = state.draft;
    final item = state.item;
    if (draft == null || item == null || !type.isSavable) return;
    if (draft.type == type) return;
    final previous = draft.type;
    var next = draft.copyWith(type: type);
    if (type.isFinanceEntry) {
      next = next.copyWith(clearPerson: true, clearCategory: true);
      if (type == item.suggestedType && item.suggestedCategoryId != null) {
        next = next.copyWith(categoryId: item.suggestedCategoryId);
      }
    } else {
      next = next.copyWith(clearCategory: true);
      final personId = state.selectedPerson?.id ?? item.suggestedPersonId;
      next = personId == null
          ? next.copyWith(clearPerson: true)
          : next.copyWith(personId: personId);
    }
    _edit(next);
    final financeChanged = previous != type && type.isFinanceEntry;
    if (financeChanged) {
      await _loadCategoriesFor(type);
    }
    if (type.isPersonTransaction && state.selectedPerson == null) {
      await _loadSuggestedPerson(next.personId);
      if (isClosed) return;
      // The counterparty's name fills the search, so the user can pick a
      // match or, only by tapping, create the person (FR-054). Searching
      // creates nothing.
      final name = item.counterparty?.trim() ?? '';
      if (state.selectedPerson == null &&
          state.personQuery.isEmpty &&
          name.isNotEmpty) {
        await personQueryChanged(name);
      }
    }
  }

  /// The one-tap "Record as Given/Received" for a named transfer whose
  /// counterparty matched an existing person (FR-054).
  Future<void> acceptSuggestedPerson() async {
    final item = state.item;
    if (item == null || item.suggestedPersonId == null) return;
    final type = item.direction == SmsDirection.credit
        ? SuggestedRecordType.received
        : SuggestedRecordType.given;
    await typeChanged(type);
    if (state.draft?.personId == null) {
      final draft = state.draft?.copyWith(personId: item.suggestedPersonId);
      if (draft != null) _edit(draft);
      await _loadSuggestedPerson(item.suggestedPersonId);
    }
  }

  /// "Choose the person" for a named transfer that several people could
  /// match (FR-054): switches to Given/Received and shows the existing
  /// similar-name choice (pick one, or explicitly create a new person).
  Future<void> chooseFromSimilarPeople() async {
    final item = state.item;
    final matches = state.similarPeople;
    if (item == null || matches.length < 2) return;
    if (state.status != ImportReviewStatus.ready) return;
    final type = item.direction == SmsDirection.credit
        ? SuggestedRecordType.received
        : SuggestedRecordType.given;
    await typeChanged(type);
    if (isClosed) return;
    emit(
      state.copyWith(
        personDuplicateMatches: matches,
        pendingPersonName: item.counterparty?.trim(),
      ),
    );
  }

  /// Parses the typed amount the same way the manual forms do (Arabic-Indic
  /// digits accepted, at most 12 whole digits, > 0). An unreadable amount
  /// clears it, so Add stays disabled. No exception text is kept.
  void amountChanged(String text) {
    final draft = state.draft;
    if (draft == null) return;
    final minor = _parseMinor(text, draft.currency);
    _edit(
      minor == null
          ? draft.copyWith(clearAmount: true)
          : draft.copyWith(amountMinorUnits: minor),
      amountInput: text,
    );
  }

  static int? _parseMinor(String text, Currency? currency) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    try {
      final money = CurrencyFormatter(
        currency: currency ?? Currency.egp,
      ).parse(NumeralParser.toWesternDigits(trimmed));
      return money.isPositive ? money.minorUnits : null;
    } catch (_) {
      return null;
    }
  }

  /// One of the two amount candidates (FR-030).
  void amountCandidateChosen(int minor) {
    final draft = state.draft;
    if (draft == null || minor <= 0) return;
    _edit(
      draft.copyWith(amountMinorUnits: minor),
      amountInput: formatMinor(minor),
    );
  }

  void currencyChanged(Currency currency) {
    final draft = state.draft;
    if (draft == null) return;
    var next = draft.copyWith(currencyCode: currency.code);
    final minor = _parseMinor(state.amountInput, currency);
    if (state.amountInput.trim().isNotEmpty) {
      next = minor == null
          ? next.copyWith(clearAmount: true)
          : next.copyWith(amountMinorUnits: minor);
    }
    _edit(next);
  }

  void dateChanged(DateTime date) {
    final draft = state.draft;
    if (draft == null) return;
    _edit(draft.copyWith(date: DateTime(date.year, date.month, date.day)));
  }

  void categorySelected(String categoryId) {
    final draft = state.draft;
    if (draft == null) return;
    _edit(draft.copyWith(categoryId: categoryId));
  }

  void noteChanged(String note) {
    final draft = state.draft;
    if (draft == null) return;
    _edit(
      note.isEmpty
          ? draft.copyWith(clearNote: true)
          : draft.copyWith(note: note),
    );
  }

  /// Copies the merchant (or counterparty) name into the note, only on the
  /// user's tap (FR-049).
  void useMerchantAsNote() {
    final item = state.item;
    final name = item?.merchant ?? item?.counterparty;
    if (name == null || name.isEmpty) return;
    noteChanged(name);
  }

  // ---------------------------------------------------------------- person

  Future<void> personQueryChanged(String query) async {
    final draft = state.draft;
    if (draft == null) return;
    final keepsSelection = state.selectedPerson?.name == query;
    emit(
      state.copyWith(
        personQuery: query,
        clearSelectedPerson: !keepsSelection,
        draft: keepsSelection ? draft : draft.copyWith(clearPerson: true),
      ),
    );
    if (query.trim().isEmpty) {
      emit(state.copyWith(personResults: const []));
      return;
    }
    final result = await _people.searchActivePeople(nameQuery: query);
    if (isClosed) return;
    emit(state.copyWith(personResults: result.getOrElse((_) => const [])));
  }

  void personSelected(Person person) {
    final draft = state.draft;
    if (draft == null) return;
    emit(
      state.copyWith(
        selectedPerson: person,
        personQuery: person.name,
        personResults: const [],
        personDuplicateMatches: const [],
        clearPendingPersonName: true,
      ),
    );
    _edit(draft.copyWith(personId: person.id));
  }

  /// Creates a person only on the user's tap, through the existing
  /// `CreatePerson`; a similar name shows the existing choice instead
  /// (FR-054).
  Future<void> createPerson(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final result = await _createPerson(name: trimmed);
    if (isClosed) return;
    result.match((failure) {
      if (failure is PossibleDuplicateFailure) {
        emit(
          state.copyWith(
            personDuplicateMatches: failure.matches,
            pendingPersonName: trimmed,
          ),
        );
      }
    }, personSelected);
  }

  /// The user confirmed the similar name is a different person.
  Future<void> confirmCreatePersonDespiteDuplicate() async {
    final name = state.pendingPersonName;
    if (name == null) return;
    final result = await _people.confirmCreateDespiteDuplicate(name: name);
    if (isClosed) return;
    result.match((_) {}, personSelected);
  }

  void dismissPersonDuplicates() => emit(
    state.copyWith(
      personDuplicateMatches: const [],
      clearPendingPersonName: true,
    ),
  );

  // ------------------------------------------------------------ duplicates

  void _scheduleDuplicateCheck() {
    _debounce?.cancel();
    _debounce = Timer(duplicateCheckDebounce, () {
      if (!isClosed) unawaited(runDuplicateCheck());
    });
  }

  /// Re-checks duplicates on the draft's current values (FR-060). A stale
  /// result (an edit happened meanwhile) is dropped; a lookup failure
  /// leaves the previous finding.
  Future<void> runDuplicateCheck() async {
    final item = state.item;
    final draft = state.draft;
    if (item == null || draft == null) return;
    final generation = ++_checkGeneration;
    final result = await _checkDuplicates(item: item, draft: draft);
    if (isClosed || generation != _checkGeneration) return;
    final finding = result.toNullable();
    if (finding == null) return;
    final matchedPending = await _matchedPending(finding);
    if (isClosed || generation != _checkGeneration) return;
    emit(
      state.copyWith(
        finding: finding,
        duplicatePending: matchedPending,
        clearDuplicatePending: matchedPending == null,
      ),
    );
  }

  /// The other pending item of a probable pending-pair finding, while it
  /// is still pending; otherwise `null`.
  Future<PendingSmsImport?> _matchedPending(DuplicateFinding finding) async {
    final id = finding.matchedPendingId;
    if (!finding.isProbable || id == null || id == state.pendingId) {
      return null;
    }
    final result = await _getPending(id);
    final other = result.toNullable();
    return other != null && other.isPending ? other : null;
  }

  void consumeDuplicateRequest() =>
      emit(state.copyWith(clearDuplicateRequest: true));

  /// "Compare" on the duplicate banner: opens the side-by-side choice for
  /// the current probable finding (ui-contract §3.4 item 8).
  void compareDuplicate() {
    final finding = state.finding;
    if (state.status != ImportReviewStatus.ready ||
        finding == null ||
        !finding.isProbable) {
      return;
    }
    emit(state.copyWith(duplicateRequest: finding));
  }

  /// "It's the same, don't add" (FR-061): closes this ONE item as a
  /// duplicate. Nothing is added and no saved record is touched. Single-
  /// flight like [add]; on success the review advances to the next pending
  /// item (FR-046).
  Future<void> closeAsDuplicate() async {
    if (state.status != ImportReviewStatus.ready) return;
    emit(
      state.copyWith(
        status: ImportReviewStatus.submitting,
        clearFailure: true,
        clearDuplicateRequest: true,
      ),
    );
    final result = await _closeAsDuplicate(state.pendingId);
    if (isClosed) return;
    final failure = result.getLeft().toNullable();
    if (failure == null) {
      _releaseLease();
      final next = await _nextPendingId();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ImportReviewStatus.closedAsDuplicate,
          nextImportId: next,
          originalSection: OriginalSection.collapsed,
          clearOriginal: true,
        ),
      );
      return;
    }
    if (failure is ImportAlreadyDecidedFailure || failure is NotFoundFailure) {
      _releaseLease();
      emit(
        state.copyWith(
          status: ImportReviewStatus.alreadyHandled,
          clearOriginal: true,
        ),
      );
      return;
    }
    emit(state.copyWith(status: ImportReviewStatus.ready, failure: failure));
  }

  // ---------------------------------------------------- ignore and mute

  /// Ignore this ONE item (FR-064): nothing is added; it moves to the
  /// 30-day Undo list. Single-flight; advances like Add (FR-046).
  Future<void> ignore() async {
    final ignoreImport = _ignoreImport;
    if (ignoreImport == null || state.status != ImportReviewStatus.ready) {
      return;
    }
    await _settleBy(
      () => ignoreImport(ids: {state.pendingId}),
      ImportReviewStatus.ignored,
    );
  }

  /// "Stop suggesting from this sender" (FR-065), after the page's
  /// confirmation: mutes the sender and removes its pending items, this
  /// one included. Nothing is added. Single-flight.
  Future<void> muteSender() async {
    final mute = _muteSender;
    final sender = state.item?.senderId;
    if (mute == null ||
        sender == null ||
        !canMuteSender ||
        state.status != ImportReviewStatus.ready) {
      return;
    }
    var removed = 0;
    await _settleBy(() async {
      final result = await mute(sender);
      removed = result.getOrElse((_) => 0);
      return result.map((_) => unit);
    }, ImportReviewStatus.senderMuted);
    if (!isClosed && state.status == ImportReviewStatus.senderMuted) {
      emit(state.copyWith(mutedRemovedCount: removed));
    }
  }

  /// Runs [action]; on success releases the lease and settles in [done]
  /// with the next pending item; a decided or missing item shows "already
  /// handled"; any other failure stays on the form with the message.
  Future<void> _settleBy(
    Future<Either<Failure, Unit>> Function() action,
    ImportReviewStatus done,
  ) async {
    emit(
      state.copyWith(
        status: ImportReviewStatus.submitting,
        clearFailure: true,
        clearDuplicateRequest: true,
      ),
    );
    final result = await action();
    if (isClosed) return;
    final failure = result.getLeft().toNullable();
    if (failure == null) {
      _releaseLease();
      final next = await _nextPendingId();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: done,
          nextImportId: next,
          originalSection: OriginalSection.collapsed,
          clearOriginal: true,
        ),
      );
      return;
    }
    if (failure is ImportAlreadyDecidedFailure || failure is NotFoundFailure) {
      _releaseLease();
      emit(
        state.copyWith(
          status: ImportReviewStatus.alreadyHandled,
          clearOriginal: true,
        ),
      );
      return;
    }
    emit(state.copyWith(status: ImportReviewStatus.ready, failure: failure));
  }

  // ------------------------------------------------------------- original

  /// Expands or collapses "Show original message" (FR-045). Collapsing
  /// drops the text from the state.
  Future<void> toggleOriginal() async {
    switch (state.originalSection) {
      case OriginalSection.loading:
        return;
      case OriginalSection.shown:
      case OriginalSection.unavailable:
        emit(
          state.copyWith(
            originalSection: OriginalSection.collapsed,
            clearOriginal: true,
          ),
        );
        return;
      case OriginalSection.collapsed:
        break;
    }
    emit(state.copyWith(originalSection: OriginalSection.loading));
    final result = await _showOriginal(state.pendingId);
    if (isClosed) return;
    result.match(
      (_) => emit(
        state.copyWith(
          originalSection: OriginalSection.unavailable,
          clearOriginal: true,
        ),
      ),
      (original) => emit(
        state.copyWith(
          originalSection: OriginalSection.shown,
          original: original,
        ),
      ),
    );
  }

  // ------------------------------------------------------------------- add

  /// The explicit Add on this one item (FR-046). Single-flight: the guard
  /// is the first statement and `submitting` is emitted before any await,
  /// so a second tap in the same frame does nothing.
  Future<void> add({bool duplicateOverride = false}) async {
    if (state.status != ImportReviewStatus.ready) return;
    final draft = state.draft;
    if (draft == null || draft.validate().isNotEmpty) return;
    emit(
      state.copyWith(
        status: ImportReviewStatus.submitting,
        clearFailure: true,
        clearDuplicateRequest: true,
      ),
    );

    final result = await _addImported(
      pendingId: state.pendingId,
      draft: draft,
      duplicateOverride: duplicateOverride,
    );
    if (isClosed) return;
    final failure = result.getLeft().toNullable();
    if (failure == null) {
      _releaseLease();
      final next = await _nextPendingId();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ImportReviewStatus.success,
          nextImportId: next,
          originalSection: OriginalSection.collapsed,
          clearOriginal: true,
        ),
      );
      return;
    }
    switch (failure) {
      case ProbableDuplicateFailure(:final finding):
        // Raised late (FR-060): the sheet opens instead of failing.
        final matchedPending = await _matchedPending(finding);
        if (isClosed) return;
        emit(
          state.copyWith(
            status: ImportReviewStatus.ready,
            duplicateRequest: finding,
            finding: finding,
            duplicatePending: matchedPending,
            clearDuplicatePending: matchedPending == null,
          ),
        );
      case ImportAlreadyDecidedFailure() || NotFoundFailure():
        _releaseLease();
        emit(
          state.copyWith(
            status: ImportReviewStatus.alreadyHandled,
            clearOriginal: true,
          ),
        );
      default:
        emit(
          state.copyWith(status: ImportReviewStatus.ready, failure: failure),
        );
    }
  }

  Future<String?> _nextPendingId() async {
    final result = await _getPendingList();
    final items = result.getOrElse((_) => const []);
    for (final item in items) {
      if (item.id != state.pendingId) return item.id;
    }
    return null;
  }

  // ----------------------------------------------------------------- leave

  /// Leaving review: without edits it is allowed at once (the item stays
  /// pending, untouched); with edits it asks first (FR-047).
  bool requestLeave() {
    if (state.isSettled || !state.isDirty) return true;
    emit(state.copyWith(requiresDiscardConfirmation: true));
    return false;
  }

  void confirmDiscard() => emit(
    state.copyWith(
      requiresDiscardConfirmation: false,
      leaveApproved: true,
      clearOriginal: true,
      originalSection: OriginalSection.collapsed,
    ),
  );

  void keepEditing() =>
      emit(state.copyWith(requiresDiscardConfirmation: false));

  void _releaseLease() {
    _lease?.release();
    _lease = null;
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _releaseLease();
    return super.close();
  }
}
