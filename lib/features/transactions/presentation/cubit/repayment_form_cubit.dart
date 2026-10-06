import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../../../core/error/failure.dart';
import '../../../currency/domain/entities/conversion_context.dart';
import '../../../currency/domain/usecases/get_primary_currency.dart';
import '../../../currency/domain/usecases/watch_conversion_context.dart';
import '../../../people/domain/entities/person.dart';
import '../../../people/domain/usecases/watch_person.dart';
import '../../domain/entities/person_balance.dart';
import '../../domain/services/repayment_preview.dart';
import '../../domain/usecases/record_repayment.dart';
import '../../domain/usecases/watch_person_balance.dart';
import 'repayment_form_state.dart';

/// Pre-bound to a known [personId] (opened from that person's detail page),
/// with its own idempotency key (FR-020 — same guarantee as
/// [TransactionFormCubit], independently).
@injectable
class RepaymentFormCubit extends Cubit<RepaymentFormState> {
  RepaymentFormCubit(
    this._recordRepayment,
    this._getPrimaryCurrency,
    this._watchPersonBalance,
    this._watchConversionContext,
    this._watchPerson,
    @factoryParam String personId, {
    @ignoreParam void Function(String message, {Object? error})? log,
  }) : _log = log ?? _developerLog,
       super(
         RepaymentFormState(
           personId: personId,
           idempotencyKey: const Uuid().v4(),
         ),
       );

  final RecordRepayment _recordRepayment;
  final GetPrimaryCurrency _getPrimaryCurrency;
  final WatchPersonBalance _watchPersonBalance;
  final WatchConversionContext _watchConversionContext;
  final WatchPerson _watchPerson;
  final void Function(String message, {Object? error}) _log;

  static void _developerLog(String message, {Object? error}) =>
      developer.log(message, name: 'daftary.repayment', error: error);

  final _subscriptions = <StreamSubscription<void>>[];
  Either<Failure, PersonBalance>? _balance;
  Either<Failure, ConversionContext>? _context;

  /// 022 A2: follows the live balance and conversion rates so the form can
  /// show what is outstanding and what a repayment would leave. Cancelled
  /// in [close].
  void subscribe() {
    // A retry starts from "loading": drop the last results and any failed
    // read so the form shows its spinner until fresh data arrives.
    _balance = null;
    _context = null;
    emit(
      state.copyWith(
        balanceLoaded: false,
        clearFailure: true,
        status: state.status == RepaymentFormStatus.failure
            ? RepaymentFormStatus.editing
            : null,
      ),
    );
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    _subscriptions
      ..clear()
      ..addAll([
        _watchPersonBalance(state.personId).listen(
          (result) {
            _balance = result;
            _refresh();
          },
          onError: (Object error) {
            _balance = Left(CacheFailure('Failed to read balance: $error'));
            _refresh();
          },
        ),
        _watchConversionContext().listen(
          (result) {
            _context = result;
            _refresh();
          },
          onError: (Object error) {
            _context = Left(CacheFailure('Failed to read rates: $error'));
            _refresh();
          },
        ),
        _watchPerson(state.personId).listen(
          (result) => result.match(
            (failure) => _logPersonFailure(failure.message),
            (Person person) => emit(state.copyWith(personName: person.name)),
          ),
          // The name only labels the preview, so the generic label stays;
          // the failure is logged rather than shown.
          onError: (Object error) => _logPersonFailure(error),
        ),
      ]);
  }

  void _logPersonFailure(Object error) => _log(
    'RepaymentFormCubit: could not read the person name; keeping the '
    'generic label',
    error: error,
  );

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    return super.close();
  }

  Money? _typedAmount([String? text, Currency? currency]) {
    try {
      final parsed = CurrencyFormatter(
        currency: currency ?? state.currency,
      ).parse(NumeralParser.toWesternDigits(text ?? state.amountInput));
      return parsed.isPositive ? parsed : null;
    } on FormatException {
      return null;
    }
  }

  /// Recomputes the loaded flag and the preview from the latest inputs.
  void _refresh({String? amountInput, Currency? currency}) {
    if (isClosed) return;
    final balance = _balance;
    final context = _context;
    if (balance == null || context == null) return;
    final known = balance.toNullable();
    final contextValue = context.toNullable();
    // A failed read must be visible, and saving stays off until both reads
    // succeed, so the flip confirmation can never be skipped.
    final failure =
        balance.getLeft().toNullable() ?? context.getLeft().toNullable();
    final amount = _typedAmount(amountInput, currency);
    final preview = known == null || contextValue == null || amount == null
        ? null
        : RepaymentPreview.of(known, amount, contextValue);
    emit(
      state.copyWith(
        balance: known,
        balanceLoaded: failure == null,
        preview: preview,
        clearPreview: preview == null,
        failure: failure,
        clearFailure:
            failure == null && state.status == RepaymentFormStatus.failure,
        status: failure != null
            ? RepaymentFormStatus.failure
            : (state.status == RepaymentFormStatus.failure
                  ? RepaymentFormStatus.editing
                  : null),
      ),
    );
  }

  /// Defaults the currency picker to the current primary currency (018
  /// FR-003). A no-op once the user has picked a currency.
  Future<void> loadDefaultCurrency() async {
    if (state.currencyChosenByUser) return;
    final result = await _getPrimaryCurrency();
    if (isClosed || state.currencyChosenByUser) return;
    result.match((_) {}, (setting) {
      emit(state.copyWith(currency: setting.currency));
      _refresh();
    });
  }

  void currencyChanged(Currency currency) {
    emit(
      state.copyWith(
        currency: currency,
        currencyChosenByUser: true,
        clearAmountError: true,
      ),
    );
    _refresh(currency: currency);
  }

  void amountChanged(String text) {
    emit(state.copyWith(amountInput: text, clearAmountError: true));
    _refresh(amountInput: text);
  }

  void dateChanged(DateTime date) {
    emit(state.copyWith(date: date));
  }

  void noteChanged(String note) {
    emit(state.copyWith(note: note));
  }

  Future<void> submit() async {
    if (state.isSubmitting || !state.balanceLoaded) return;

    final Money amount;
    try {
      final normalized = NumeralParser.toWesternDigits(state.amountInput);
      final parsed = CurrencyFormatter(
        currency: state.currency,
      ).parse(normalized);
      if (!parsed.isPositive) {
        throw const FormatException('Amount must be greater than zero');
      }
      amount = parsed;
    } on FormatException {
      emit(state.copyWith(amountInvalid: true));
      return;
    }

    if (state.preview?.flips ?? false) {
      // Over-repaying reverses who owes whom: ask first (022 A2).
      emit(state.copyWith(needsFlipConfirmation: true));
      return;
    }
    await _save(amount);
  }

  /// The user accepted the balance reversal; saves with the same
  /// idempotency key as the first attempt.
  Future<void> confirmFlip() async {
    final amount = _typedAmount();
    emit(state.copyWith(needsFlipConfirmation: false));
    if (amount == null || state.isSubmitting) return;
    await _save(amount);
  }

  void cancelFlip() => emit(state.copyWith(needsFlipConfirmation: false));

  Future<void> _save(Money amount) async {
    emit(
      state.copyWith(
        status: RepaymentFormStatus.submitting,
        clearFailure: true,
      ),
    );

    final result = await _recordRepayment(
      idempotencyKey: state.idempotencyKey,
      personId: state.personId,
      amount: amount,
      date: state.date,
      note: state.note,
    );

    if (isClosed) return;
    result.match(
      (failure) => emit(
        state.copyWith(status: RepaymentFormStatus.failure, failure: failure),
      ),
      (_) => emit(state.copyWith(status: RepaymentFormStatus.success)),
    );
  }
}
