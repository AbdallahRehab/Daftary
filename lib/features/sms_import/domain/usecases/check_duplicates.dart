import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../entities/pending_sms_import.dart';
import '../entities/review_draft.dart';
import '../entities/sms_import_enums.dart';
import '../entities/sms_value_types.dart';
import '../repositories/sms_duplicate_lookup.dart';
import '../rules/calendar_days.dart';
import '../services/bank_reference_policy.dart';

/// The SMS-specific duplicate check (FR-059..FR-063, FR-051d, FR-024b).
///
/// Evaluated in the fixed FR-059b order on the DRAFT's current values
/// (FR-060):
///
/// 1. exact: another pending row or a tombstone with the same fingerprint;
/// 2. exact: the same bank + reference + amount + direction (its
///    reference-amount hash), only while the draft's amount, currency and
///    direction group still equal the parsed ones (the hash was computed
///    from those). For a bank whose references are not unique the other
///    message must also be dated within one calendar day; a tombstone keeps
///    no date, so it never collapses such a bank's message;
/// 3. legitimately similar: an otherwise matching SMS-sourced saved record
///    whose reference hash is present and differs from this item's is
///    skipped (FR-059a), and evaluation of it stops;
/// 4. probable: a saved record of any source and either aggregate with the
///    same currency and minor-unit amount (or the stated original-currency
///    amount, FR-059), the same direction group (expense = given, income =
///    received) and a date within one calendar day; then the 10-minute
///    pending pair. The best candidate is returned: most similar
///    merchant/note first, then the closest date (analysis M4).
///
/// It also flags a possible own transfer (FR-051d), and for an
/// authorization reversal returns the matched saved expense or Given record
/// in [DuplicateFinding.matchedRecord] with tier `none`, so the review shows
/// it without ever blocking or treating it as a duplicate (FR-024b).
///
/// A finding never blocks (FR-063): only `AddImportedTransaction` turns a
/// probable finding into the side-by-side choice. A lookup failure is
/// returned as is. The person-scoped `FindPossibleDuplicate` is unchanged.
@injectable
class CheckDuplicates {
  CheckDuplicates(this._lookup, this._policy);

  final SmsDuplicateLookup _lookup;
  final BankReferencePolicy _policy;

  Future<Either<Failure, DuplicateFinding>> call({
    required PendingSmsImport item,
    required ReviewDraft draft,
  }) async {
    try {
      return Right(await _check(item, draft));
    } on _LookupFailed catch (e) {
      return Left(e.failure);
    }
  }

  Future<T> _run<T>(Future<Either<Failure, T>> query) async =>
      (await query).fold((f) => throw _LookupFailed(f), (value) => value);

  Future<DuplicateFinding> _check(
    PendingSmsImport item,
    ReviewDraft draft,
  ) async {
    // The draft's current values only (FR-060): a field the user cleared
    // has nothing to compare.
    final money = draft.money;
    final date = draft.date;
    final type = _effectiveType(item, draft);
    final moneyOut = type == null ? null : _isMoneyOut(type);

    // --- tiers 1 and 2 ----------------------------------------------------
    final tier2 =
        item.refAmountHash != null &&
        money != null &&
        money == item.amount &&
        moneyOut != null &&
        _directionMatches(item.direction, moneyOut);
    final keyMatches = await _run(
      _lookup.findKeyMatches(
        excludeId: item.id,
        fingerprint: item.fingerprint,
        refAmountHash: tier2 ? item.refAmountHash : null,
      ),
    );
    // An exact finding does not end the check: the saved-record tier below
    // still runs, and its probable finding wins, so a match against money
    // already saved is never hidden behind a pending-row match (SC-007).
    DuplicateFinding? exact;
    for (final match in keyMatches) {
      if (match.pendingId != item.id && match.fingerprint == item.fingerprint) {
        exact = DuplicateFinding(
          tier: DuplicateTier.exact,
          exactBasis: ExactBasis.fingerprint,
          matchedPendingId: match.pendingId,
        );
        break;
      }
    }
    if (exact == null && tier2) {
      final unique = _policy.refIsUnique(item.bankId);
      for (final match in keyMatches) {
        if (match.pendingId == item.id ||
            match.refAmountHash != item.refAmountHash ||
            match.bankId != item.bankId) {
          continue;
        }
        final otherDate = match.occurredOn;
        final dated =
            date != null &&
            otherDate != null &&
            withinOneCalendarDay(date, otherDate);
        if (unique || dated) {
          exact = DuplicateFinding(
            tier: DuplicateTier.exact,
            exactBasis: ExactBasis.bankReferenceAmountDirection,
            matchedPendingId: match.pendingId,
          );
          break;
        }
      }
    }

    if (money == null || date == null) return exact ?? DuplicateFinding.none;

    // --- authorization reversal (FR-024b) -------------------------------
    if (item.kind == SmsKind.authorizationReversal) {
      if (exact != null) return exact;
      return DuplicateFinding(
        tier: DuplicateTier.none,
        matchedRecord: await _reversalMatch(item, money, date),
      );
    }
    if (type == null || moneyOut == null) return exact ?? DuplicateFinding.none;

    final ownTransfer = await _possibleOwnTransfer(item, money, date, moneyOut);

    // --- tiers 3 and 4: saved records -----------------------------------
    final amounts = <Money>{money, ?item.foreignAmount};
    final candidates = <String, DuplicateRecordRef>{};
    for (final amount in amounts) {
      final refs = await _run(
        _lookup.findSavedMatches(amount: amount, date: date, type: type),
      );
      for (final ref in refs) {
        if (amounts.contains(ref.amount) &&
            _isMoneyOut(ref.type) == moneyOut &&
            withinOneCalendarDay(ref.date, date)) {
          candidates[ref.id] = ref;
        }
      }
    }
    var similarOnly = false;
    final probable = <DuplicateRecordRef>[];
    for (final ref in candidates.values) {
      final ours = item.refHash;
      if (ours != null && (ref.importProvenance?.isSms ?? false)) {
        final theirs = await _run(_lookup.refHashForSavedRecord(ref.id));
        if (theirs != null && theirs != ours) {
          similarOnly = true;
          continue;
        }
      }
      probable.add(ref);
    }
    if (probable.isNotEmpty) {
      return DuplicateFinding(
        tier: DuplicateTier.probable,
        probableBasis: ProbableBasis.savedRecord,
        matchedRecord: _best(probable, item, date),
        possibleOwnTransfer: ownTransfer,
      );
    }

    if (exact != null) return exact;

    // --- tier 4: the 10-minute pending pair -----------------------------
    final pair = await _run(_lookup.findPendingPair(item));
    if (pair != null && pair.id != item.id) {
      return DuplicateFinding(
        tier: DuplicateTier.probable,
        probableBasis: ProbableBasis.pendingPair,
        matchedPendingId: pair.id,
        possibleOwnTransfer: ownTransfer,
      );
    }

    return DuplicateFinding(
      tier: similarOnly
          ? DuplicateTier.legitimatelySimilar
          : DuplicateTier.none,
      possibleOwnTransfer: ownTransfer,
    );
  }

  /// The draft's savable type, else the one the parsed direction implies.
  static SuggestedRecordType? _effectiveType(
    PendingSmsImport item,
    ReviewDraft draft,
  ) {
    final chosen = draft.type;
    if (chosen != null && chosen.isSavable) return chosen;
    return switch (item.direction) {
      SmsDirection.debit => SuggestedRecordType.expense,
      SmsDirection.credit => SuggestedRecordType.income,
      SmsDirection.unknown => null,
    };
  }

  /// Direction group: expense and given are money out.
  static bool _isMoneyOut(SuggestedRecordType type) =>
      type == SuggestedRecordType.expense || type == SuggestedRecordType.given;

  static bool _directionMatches(SmsDirection direction, bool moneyOut) =>
      moneyOut
      ? direction == SmsDirection.debit
      : direction == SmsDirection.credit;

  /// The saved expense or Given record a reversal cancels: the same
  /// reference hash, else the same amount within one calendar day.
  Future<DuplicateRecordRef?> _reversalMatch(
    PendingSmsImport item,
    Money money,
    DateTime date,
  ) async {
    final refHash = item.refHash;
    if (refHash != null) {
      final byRef = [
        for (final ref in await _run(_lookup.savedRecordsForRefHash(refHash)))
          if (_isMoneyOut(ref.type)) ref,
      ];
      if (byRef.isNotEmpty) return _best(byRef, item, date);
    }
    final byAmount = [
      for (final ref in await _run(
        _lookup.findSavedMatches(
          amount: money,
          date: date,
          type: SuggestedRecordType.expense,
        ),
      ))
        if (_isMoneyOut(ref.type) &&
            ref.amount == money &&
            withinOneCalendarDay(ref.date, date))
          ref,
    ];
    return byAmount.isEmpty ? null : _best(byAmount, item, date);
  }

  /// FR-051d: a transfer-out and a transfer-in or deposit of the same
  /// amount and currency within one calendar day from a different bank or
  /// channel, among pending items and SMS-sourced saved records.
  Future<bool> _possibleOwnTransfer(
    PendingSmsImport item,
    Money money,
    DateTime date,
    bool moneyOut,
  ) async {
    if (!_transferLike(item.kind, moneyOut: moneyOut)) return false;
    final pending = await _run(
      _lookup.findPendingWithAmount(money, excludeId: item.id),
    );
    for (final other in pending) {
      final otherDate = other.occurredOn;
      if (other.id != item.id &&
          other.amount == money &&
          other.bankId != item.bankId &&
          otherDate != null &&
          withinOneCalendarDay(otherDate, date) &&
          _directionMatches(other.direction, !moneyOut) &&
          _transferLike(other.kind, moneyOut: !moneyOut)) {
        return true;
      }
    }
    final opposite = moneyOut
        ? SuggestedRecordType.income
        : SuggestedRecordType.expense;
    final saved = await _run(
      _lookup.findSavedMatches(amount: money, date: date, type: opposite),
    );
    for (final ref in saved) {
      if (!(ref.importProvenance?.isSms ?? false) ||
          ref.amount != money ||
          _isMoneyOut(ref.type) == moneyOut ||
          !withinOneCalendarDay(ref.date, date)) {
        continue;
      }
      final bank = await _run(_lookup.bankForSavedRecord(ref.id));
      if (bank != null && bank != item.bankId) return true;
    }
    return false;
  }

  static bool _transferLike(SmsKind kind, {required bool moneyOut}) => moneyOut
      ? kind == SmsKind.transferOut
      : kind == SmsKind.transferIn || kind == SmsKind.otherDeposit;

  /// Most similar merchant/note first, then the closest date, then the id
  /// (deterministic).
  static DuplicateRecordRef _best(
    List<DuplicateRecordRef> refs,
    PendingSmsImport item,
    DateTime date,
  ) {
    final words = _words('${item.merchant ?? ''} ${item.counterparty ?? ''}');
    int score(DuplicateRecordRef ref) =>
        _words(ref.note ?? '').intersection(words).length;
    final sorted = [...refs]
      ..sort((a, b) {
        final bySimilarity = score(b).compareTo(score(a));
        if (bySimilarity != 0) return bySimilarity;
        final byDate = calendarDaysApart(
          a.date,
          date,
        ).compareTo(calendarDaysApart(b.date, date));
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    return sorted.first;
  }

  static final RegExp _word = RegExp(r'[\p{L}\p{N}]{3,}', unicode: true);

  static Set<String> _words(String text) => {
    for (final match in _word.allMatches(text.toLowerCase())) match[0]!,
  };
}

/// Carries a lookup failure out of the evaluation; never escapes [CheckDuplicates.call].
class _LookupFailed implements Exception {
  const _LookupFailed(this.failure);

  final Failure failure;

  @override
  String toString() => '_LookupFailed()';
}
