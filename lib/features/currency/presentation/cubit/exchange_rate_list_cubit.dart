import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/money/currency.dart';
import '../../../../core/utils/combine_latest.dart';
import '../../domain/entities/exchange_rate.dart';
import '../../domain/usecases/remove_exchange_rate.dart';
import '../../domain/usecases/watch_exchange_rates.dart';
import '../../domain/usecases/watch_primary_currency.dart';
import 'exchange_rate_list_state.dart';

/// Drives the exchange-rate list (US3, FR-006/FR-007).
///
/// 021: the list is a live subscription to [WatchPrimaryCurrency] and
/// [WatchExchangeRates], cancelled in [close] — a rate saved in the form
/// (or applied by sync) shows with no reload (FR-031).
@injectable
class ExchangeRateListCubit extends Cubit<ExchangeRateListState> {
  ExchangeRateListCubit(this._watchPrimary, this._watchRates, this._removeRate)
    : super(const ExchangeRateListState());

  final WatchPrimaryCurrency _watchPrimary;
  final WatchExchangeRates _watchRates;
  final RemoveExchangeRate _removeRate;

  StreamSubscription<void>? _subscription;
  Completer<void>? _firstResult;

  /// Subscribes to the primary currency and the rates, replacing any
  /// earlier subscription. The returned future completes on the first
  /// result.
  Future<void> subscribe() {
    _cancelSubscription();
    final firstResult = _firstResult = Completer<void>();
    _subscription =
        combineLatest2(
          _watchPrimary(),
          _watchRates(),
          (primary, rates) => (primary, rates),
        ).listen((results) {
          if (isClosed) return;
          final (primary, rates) = results;
          final setting = primary.toNullable();
          final list = rates.toNullable();
          if (setting == null || list == null) {
            emit(state.copyWith(status: ExchangeRateListStatus.loadFailure));
          } else {
            emit(
              state.copyWith(
                status: ExchangeRateListStatus.ready,
                primary: setting.currency,
                rates: _sorted(list, setting.currency),
              ),
            );
          }
          _completeFirstResult();
        });
    return firstResult.future;
  }

  /// Retry: subscribes again from scratch.
  Future<void> resubscribe() => subscribe();

  void _completeFirstResult() {
    final firstResult = _firstResult;
    if (firstResult != null && !firstResult.isCompleted) {
      firstResult.complete();
    }
  }

  void _cancelSubscription() {
    _subscription?.cancel();
    _subscription = null;
    _completeFirstResult();
  }

  @override
  Future<void> close() {
    _cancelSubscription();
    return super.close();
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
