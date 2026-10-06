import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../currency/domain/entities/primary_currency_setting.dart';
import '../../../currency/domain/usecases/watch_primary_currency.dart';
import '../../../people/domain/entities/person.dart';
import '../../../people/domain/usecases/watch_person.dart';
import '../../domain/entities/money_transaction.dart';
import '../../domain/entities/person_balance.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../../domain/services/deletion_impact.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/preview_transaction_deletion.dart';
import '../../domain/usecases/watch_person_balance.dart';
import '../../domain/usecases/watch_person_history.dart';
import 'person_detail_state.dart';

/// A person's balance + full history together (US2).
///
/// 021: every part of the page is a live subscription — the person, their
/// balance, their history, the occasion names labelling it (008) and the
/// primary currency — so adding, editing or
/// deleting a transaction (here, on another screen, or through sync)
/// updates the page with no refresh (FR-014, FR-031). All subscriptions are
/// cancelled in [close].
@injectable
class PersonDetailCubit extends Cubit<PersonDetailState> {
  PersonDetailCubit(
    this._watchPerson,
    this._watchPersonBalance,
    this._watchPersonHistory,
    this._deleteTransaction,
    this._watchPrimaryCurrency,
    this._transactionsRepository,
    this._previewDeletion,
  ) : super(const PersonDetailState());

  final WatchPerson _watchPerson;
  final WatchPersonBalance _watchPersonBalance;
  final WatchPersonHistory _watchPersonHistory;
  final DeleteTransaction _deleteTransaction;
  final WatchPrimaryCurrency _watchPrimaryCurrency;

  /// Read directly rather than through a use case: occasion names are a
  /// pure labelling detail of the history already fetched, carrying no
  /// business rule of their own.
  final TransactionsRepository _transactionsRepository;
  final PreviewTransactionDeletion _previewDeletion;
  var _requestingDelete = false;

  String? _personId;
  final _subscriptions = <StreamSubscription<void>>[];
  Completer<void>? _firstResult;

  Either<Failure, Person>? _person;
  Either<Failure, PersonBalance>? _balance;
  Either<Failure, List<MoneyTransaction>>? _history;
  Either<Failure, PrimaryCurrencySetting>? _primary;
  Either<Failure, Map<String, String>>? _occasionNames;

  /// Subscribes to everything the page shows for [personId], replacing any
  /// earlier subscription. The returned future completes once the first
  /// complete result has been emitted.
  Future<void> subscribe(String personId) {
    _cancelSubscriptions();
    _personId = personId;
    _person = null;
    _balance = null;
    _history = null;
    _primary = null;
    _occasionNames = null;
    emit(state.copyWith(status: PersonDetailStatus.loading));

    final firstResult = _firstResult = Completer<void>();
    _subscriptions.addAll([
      _watchPerson(
        personId,
      ).listen((result) => _update(() => _person = result)),
      _watchPersonBalance(
        personId,
      ).listen((result) => _update(() => _balance = result)),
      _watchPersonHistory(
        personId,
      ).listen((result) => _update(() => _history = result)),
      _watchPrimaryCurrency().listen(
        (result) => _update(() => _primary = result),
      ),
      _transactionsRepository
          .watchOccasionNamesForPerson(personId)
          .listen((result) => _update(() => _occasionNames = result)),
    ]);
    return firstResult.future;
  }

  /// Retry: subscribes again, from scratch, to the displayed person.
  Future<void> resubscribe() {
    final personId = _personId;
    if (personId == null) return Future.value();
    return subscribe(personId);
  }

  /// Records [change], then emits once every part has arrived.
  void _update(void Function() change) {
    if (isClosed) return;
    change();
    final person = _person;
    final balance = _balance;
    final history = _history;
    final primary = _primary;
    final occasionNames = _occasionNames;
    if (person == null ||
        balance == null ||
        history == null ||
        primary == null ||
        occasionNames == null) {
      return;
    }

    final failure = [
      person,
      balance,
      history,
    ].map((result) => result.getLeft().toNullable()).nonNulls.firstOrNull;
    if (failure != null) {
      emit(
        state.copyWith(status: PersonDetailStatus.failure, failure: failure),
      );
    } else {
      emit(
        state.copyWith(
          status: PersonDetailStatus.success,
          person: person.toNullable(),
          balance: balance.toNullable(),
          history: history.toNullable(),
          // Only decides which history rows get a currency chip — a failed
          // read keeps the previous value rather than failing the page.
          primaryCurrency: primary.match(
            (_) => state.primaryCurrency,
            (setting) => setting.currency,
          ),
          // A missing name is a label, not a balance: the history stays
          // readable without it, so a failure here degrades to no badge
          // rather than failing the whole screen.
          occasionNames: occasionNames.getOrElse((_) => const {}),
        ),
      );
    }
    _completeFirstResult();
  }

  /// 022 E6: works out what deleting [transaction] would leave (later
  /// repayments and the resulting balance) and exposes it as
  /// `state.pendingDelete` for the confirmation (a plain confirmation with
  /// no impact while the balance is still loading). Ignored while another
  /// request is open or in flight.
  // Known limitation: the confirmation shows the impact computed when it
  // was requested. If the balance changes while the dialog is open (a
  // sync), the open dialog is not refreshed; the delete itself is still
  // correct because the repository re-reads everything.
  Future<void> requestDelete(MoneyTransaction transaction) async {
    final balance = state.balance;
    if (_requestingDelete || state.pendingDelete != null) return;
    if (balance == null) {
      // The balance has not loaded yet: ask the plain "cannot be undone"
      // question with no impact preview rather than ignoring the tap.
      emit(
        state.copyWith(
          pendingDelete: PendingDelete(
            transaction: transaction,
            impact: const DeletionImpact(
              laterRepaymentCount: 0,
              resultingNet: null,
            ),
          ),
        ),
      );
      return;
    }
    _requestingDelete = true;
    try {
      final result = await _previewDeletion(transaction, balance);
      if (isClosed) return;
      result.match(
        (failure) => emit(state.copyWith(failure: failure)),
        (impact) => emit(
          state.copyWith(
            pendingDelete: PendingDelete(
              transaction: transaction,
              impact: impact,
            ),
          ),
        ),
      );
    } finally {
      _requestingDelete = false;
    }
  }

  void cancelDelete() {
    if (isClosed) return;
    emit(state.copyWith(clearPendingDelete: true));
  }

  /// The user confirmed the pending delete.
  Future<void> confirmDelete() async {
    if (isClosed) return;
    final pending = state.pendingDelete;
    if (pending == null) return;
    emit(state.copyWith(clearPendingDelete: true));
    await deleteTransaction(pending.transaction.id);
  }

  /// Soft-deletes [transactionId] (after the caller has already shown the
  /// "cannot be undone" confirmation, FR-016). The live subscriptions then
  /// recalculate the balance and drop the row (US6 Acceptance Scenario 2).
  Future<void> deleteTransaction(String transactionId) async {
    final result = await _deleteTransaction(transactionId);
    if (isClosed) return;
    result.match(
      // Deliberately keeps `status` as-is (rather than `failure`) so the
      // already-loaded balance/history stay visible; the page surfaces
      // `failure` via a transient snackbar instead of a full-page error.
      (failure) => emit(state.copyWith(failure: failure)),
      (_) {},
    );
  }

  void _completeFirstResult() {
    final firstResult = _firstResult;
    if (firstResult != null && !firstResult.isCompleted) {
      firstResult.complete();
    }
  }

  void _cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _completeFirstResult();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
