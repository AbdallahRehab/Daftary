import 'package:equatable/equatable.dart';

import '../../../../core/money/currency.dart';
import '../../domain/entities/exchange_rate.dart';

enum ExchangeRateListStatus { loading, ready, loadFailure }

/// Immutable state for `ExchangeRateListCubit`.
class ExchangeRateListState extends Equatable {
  const ExchangeRateListState({
    this.status = ExchangeRateListStatus.loading,
    this.primary = Currency.egp,
    this.rates = const [],
    this.removingCode,
    this.isRemoveFailing = false,
  });

  final ExchangeRateListStatus status;
  final Currency primary;

  /// Rates quoted against [primary] first (the ones totals use), then any
  /// left over from an earlier primary; each group ordered by code.
  final List<ExchangeRate> rates;

  /// The currency whose rate is being removed; removal controls are
  /// disabled meanwhile (duplicate-action protection).
  final String? removingCode;

  /// `true` once the latest removal failed; reset on the next attempt.
  final bool isRemoveFailing;

  bool get isRemoving => removingCode != null;

  ExchangeRateListState copyWith({
    ExchangeRateListStatus? status,
    Currency? primary,
    List<ExchangeRate>? rates,
    String? removingCode,
    bool clearRemoving = false,
    bool? isRemoveFailing,
  }) {
    return ExchangeRateListState(
      status: status ?? this.status,
      primary: primary ?? this.primary,
      rates: rates ?? this.rates,
      removingCode: clearRemoving ? null : removingCode ?? this.removingCode,
      isRemoveFailing: isRemoveFailing ?? this.isRemoveFailing,
    );
  }

  @override
  List<Object?> get props => [
    status,
    primary,
    rates,
    removingCode,
    isRemoveFailing,
  ];
}
