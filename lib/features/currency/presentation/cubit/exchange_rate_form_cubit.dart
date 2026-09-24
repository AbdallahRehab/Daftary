import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/money/currency.dart';
import '../../domain/entities/currency_failures.dart';
import '../../domain/usecases/get_exchange_rates.dart';
import '../../domain/usecases/get_primary_currency.dart';
import '../../domain/usecases/set_exchange_rate.dart';
import 'exchange_rate_form_state.dart';
import 'rate_input.dart';

/// Drives the add/edit exchange-rate form (US3, FR-006). Save is disabled
/// from the moment it is tapped until the result is known.
@injectable
class ExchangeRateFormCubit extends Cubit<ExchangeRateFormState> {
  ExchangeRateFormCubit(this._getPrimary, this._getRates, this._setRate)
    : super(const ExchangeRateFormState());

  final GetPrimaryCurrency _getPrimary;
  final GetExchangeRates _getRates;
  final SetExchangeRate _setRate;

  /// Loads the form. With [editingCode], edits the stored rate
  /// ([editingCode] → [relativeToCode], defaulting to the primary currency);
  /// otherwise starts a new rate against the primary currency, optionally
  /// preselecting [initialCode].
  Future<void> load({
    String? editingCode,
    String? relativeToCode,
    String? initialCode,
  }) async {
    final primaryResult = await _getPrimary();
    final ratesResult = await _getRates();
    if (primaryResult.isLeft() || ratesResult.isLeft()) {
      emit(state.copyWith(status: ExchangeRateFormStatus.loadFailure));
      return;
    }
    final primary = primaryResult.getRight().toNullable()!.currency;
    final rates = ratesResult.getRight().toNullable()!;
    final editing = editingCode == null
        ? null
        : Currency.tryFromCode(editingCode);
    final relativeTo = editing != null && relativeToCode != null
        ? Currency.tryFromCode(relativeToCode) ?? primary
        : primary;
    final available = [
      for (final c in Currency.catalog)
        if (c != relativeTo) c,
    ];

    if (editing != null && editing != relativeTo) {
      final existing = rates
          .where((r) => r.currency == editing && r.relativeTo == relativeTo)
          .firstOrNull;
      emit(
        state.copyWith(
          status: ExchangeRateFormStatus.ready,
          isEditing: true,
          relativeTo: relativeTo,
          currency: editing,
          availableCurrencies: available,
          rateText: existing == null
              ? ''
              : RateInput.format(existing.rateMicros),
        ),
      );
      return;
    }

    final initial = initialCode == null
        ? null
        : Currency.tryFromCode(initialCode);
    emit(
      state.copyWith(
        status: ExchangeRateFormStatus.ready,
        relativeTo: relativeTo,
        currency: available.contains(initial) ? initial : available.firstOrNull,
        availableCurrencies: available,
      ),
    );
  }

  void selectCurrency(Currency currency) {
    if (state.isEditing || state.isSubmitting) return;
    if (!state.availableCurrencies.contains(currency)) return;
    emit(state.copyWith(currency: currency));
  }

  void rateChanged(String text) {
    emit(state.copyWith(rateText: text, showRateError: false));
  }

  Future<void> save() async {
    final currency = state.currency;
    if (!state.canSave || currency == null) return;
    emit(state.copyWith(isSubmitting: true, isSaveFailing: false));
    final rate = RateInput.parse(state.rateText);
    if (rate == null) {
      emit(state.copyWith(isSubmitting: false, showRateError: true));
      return;
    }
    final result = await _setRate(
      currencyCode: currency.code,
      relativeToCurrencyCode: state.relativeTo.code,
      rate: rate,
    );
    result.fold(
      (failure) => emit(
        failure is InvalidExchangeRateFailure
            ? state.copyWith(isSubmitting: false, showRateError: true)
            : state.copyWith(isSubmitting: false, isSaveFailing: true),
      ),
      (_) => emit(state.copyWith(isSubmitting: false, isSaved: true)),
    );
  }
}
