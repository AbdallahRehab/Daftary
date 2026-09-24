import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/money/currency.dart';
import '../../domain/entities/currency_failures.dart';
import '../../domain/usecases/get_primary_currency.dart';
import '../../domain/usecases/set_primary_currency.dart';
import 'primary_currency_state.dart';
import 'rate_input.dart';

/// Drives the primary-currency section of Currency settings (US3, FR-005,
/// FR-012). A switch refused for want of a rate surfaces as
/// [PrimaryCurrencyState.isRatePromptPending]; the page then asks for the
/// rate and calls [confirmSwitchWithRate] (or [cancelPendingSwitch]).
@injectable
class PrimaryCurrencyCubit extends Cubit<PrimaryCurrencyState> {
  PrimaryCurrencyCubit(this._getPrimary, this._setPrimary)
    : super(const PrimaryCurrencyState());

  final GetPrimaryCurrency _getPrimary;
  final SetPrimaryCurrency _setPrimary;

  Future<void> load() async {
    final result = await _getPrimary();
    result.fold(
      (_) => emit(state.copyWith(status: PrimaryCurrencyStatus.loadFailure)),
      (setting) => emit(
        state.copyWith(
          status: PrimaryCurrencyStatus.ready,
          primary: setting.currency,
        ),
      ),
    );
  }

  /// Requests a switch to [next]. No-op for the current primary or while a
  /// change is already in flight.
  Future<void> changePrimary(Currency next) async {
    if (state.status != PrimaryCurrencyStatus.ready || state.isSubmitting) {
      return;
    }
    if (next == state.primary) return;
    emit(
      state.copyWith(
        isSubmitting: true,
        clearPending: true,
        outcome: PrimaryCurrencyChangeOutcome.none,
      ),
    );
    final result = await _setPrimary(newPrimaryCurrencyCode: next.code);
    result.fold(
      (failure) {
        if (failure is RateRequiredForSwitchFailure) {
          emit(
            state.copyWith(
              isSubmitting: false,
              pendingTarget: next,
              rateRequiredFor: failure.previousPrimary,
            ),
          );
        } else {
          emit(
            state.copyWith(
              isSubmitting: false,
              outcome: PrimaryCurrencyChangeOutcome.failed,
            ),
          );
        }
      },
      (_) => emit(
        state.copyWith(
          isSubmitting: false,
          primary: next,
          outcome: PrimaryCurrencyChangeOutcome.changed,
        ),
      ),
    );
  }

  /// Completes a pending switch with the user-entered rate for the
  /// outgoing primary (FR-012). An unparseable or non-positive rate keeps
  /// the prompt pending and reports [PrimaryCurrencyChangeOutcome.invalidRate].
  Future<void> confirmSwitchWithRate(String rateText) async {
    final target = state.pendingTarget;
    if (!state.isRatePromptPending || state.isSubmitting || target == null) {
      return;
    }
    emit(
      state.copyWith(
        isSubmitting: true,
        outcome: PrimaryCurrencyChangeOutcome.none,
      ),
    );
    final rate = RateInput.parse(rateText);
    if (rate == null) {
      emit(
        state.copyWith(
          isSubmitting: false,
          outcome: PrimaryCurrencyChangeOutcome.invalidRate,
        ),
      );
      return;
    }
    final result = await _setPrimary(
      newPrimaryCurrencyCode: target.code,
      rateForPreviousPrimary: rate,
    );
    result.fold(
      // An invalid rate keeps the prompt open for another try; any other
      // failure abandons the switch (the primary stays unchanged).
      (failure) => emit(
        failure is InvalidExchangeRateFailure
            ? state.copyWith(
                isSubmitting: false,
                outcome: PrimaryCurrencyChangeOutcome.invalidRate,
              )
            : state.copyWith(
                isSubmitting: false,
                clearPending: true,
                outcome: PrimaryCurrencyChangeOutcome.failed,
              ),
      ),
      (_) => emit(
        state.copyWith(
          isSubmitting: false,
          primary: target,
          clearPending: true,
          outcome: PrimaryCurrencyChangeOutcome.changed,
        ),
      ),
    );
  }

  /// Abandons a pending switch; the primary currency is left unchanged.
  void cancelPendingSwitch() {
    if (!state.isRatePromptPending) return;
    emit(state.copyWith(clearPending: true));
  }
}
