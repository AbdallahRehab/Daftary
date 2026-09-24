import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/money/currency.dart';
import '../../domain/entities/exchange_rate.dart';
import '../../domain/usecases/get_exchange_rates.dart';
import '../../domain/usecases/get_primary_currency.dart';
import '../../domain/usecases/remove_exchange_rate.dart';
import 'exchange_rate_list_state.dart';

/// Drives the exchange-rate list (US3, FR-006/FR-007).
@injectable
class ExchangeRateListCubit extends Cubit<ExchangeRateListState> {
  ExchangeRateListCubit(this._getPrimary, this._getRates, this._removeRate)
    : super(const ExchangeRateListState());

  final GetPrimaryCurrency _getPrimary;
  final GetExchangeRates _getRates;
  final RemoveExchangeRate _removeRate;

  Future<void> load() async {
    final primary = await _getPrimary();
    final rates = await _getRates();
    if (primary.isLeft() || rates.isLeft()) {
      emit(state.copyWith(status: ExchangeRateListStatus.loadFailure));
      return;
    }
    final primaryCurrency = primary.getRight().toNullable()!.currency;
    emit(
      state.copyWith(
        status: ExchangeRateListStatus.ready,
        primary: primaryCurrency,
        rates: _sorted(rates.getRight().toNullable()!, primaryCurrency),
      ),
    );
  }

  /// Removes every rate converting FROM [currencyCode]. Records are never
  /// touched; dependent totals become blocked again.
  Future<void> remove(String currencyCode) async {
    if (state.status != ExchangeRateListStatus.ready || state.isRemoving) {
      return;
    }
    emit(state.copyWith(removingCode: currencyCode, isRemoveFailing: false));
    final result = await _removeRate(currencyCode);
    if (result.isLeft()) {
      emit(state.copyWith(clearRemoving: true, isRemoveFailing: true));
      return;
    }
    emit(
      state.copyWith(
        clearRemoving: true,
        rates: [
          for (final rate in state.rates)
            if (rate.currency.code != currencyCode) rate,
        ],
      ),
    );
  }

  static List<ExchangeRate> _sorted(
    List<ExchangeRate> rates,
    Currency primary,
  ) {
    int group(ExchangeRate r) => r.relativeTo == primary ? 0 : 1;
    return [...rates]..sort((a, b) {
      final byGroup = group(a).compareTo(group(b));
      if (byGroup != 0) return byGroup;
      final byTarget = a.relativeTo.code.compareTo(b.relativeTo.code);
      if (byTarget != 0) return byTarget;
      return a.currency.code.compareTo(b.currency.code);
    });
  }
}
