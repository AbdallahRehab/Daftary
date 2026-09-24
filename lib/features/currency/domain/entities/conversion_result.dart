import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

/// The outcome of converting one amount (contracts/currency_converter.md).
/// A missing rate is a typed result — never a thrown error and never a
/// silent 1:1 fallback (FR-009).
sealed class ConversionResult extends Equatable {
  const ConversionResult();

  const factory ConversionResult.converted(Money value) = ConversionConverted;
  const factory ConversionResult.rateUnavailable(Currency missingRateFor) =
      ConversionRateUnavailable;
}

final class ConversionConverted extends ConversionResult {
  const ConversionConverted(this.value);

  final Money value;

  @override
  List<Object?> get props => [value];
}

final class ConversionRateUnavailable extends ConversionResult {
  const ConversionRateUnavailable(this.missingRateFor);

  final Currency missingRateFor;

  @override
  List<Object?> get props => [missingRateFor];
}

/// The outcome of converting-and-summing many amounts. All-or-nothing: if
/// any amount lacks a rate the whole sum is [SumBlocked], carrying every
/// currency that needs a rate — a partial sum is never presented as the
/// complete total (FR-009).
sealed class SumResult extends Equatable {
  const SumResult();

  const factory SumResult.total(Money value) = SumTotal;
  const factory SumResult.blocked(List<Currency> missingRatesFor) = SumBlocked;
}

final class SumTotal extends SumResult {
  const SumTotal(this.value);

  final Money value;

  @override
  List<Object?> get props => [value];
}

final class SumBlocked extends SumResult {
  const SumBlocked(this.missingRatesFor);

  /// Distinct, in first-seen order.
  final List<Currency> missingRatesFor;

  @override
  List<Object?> get props => [missingRatesFor];
}
