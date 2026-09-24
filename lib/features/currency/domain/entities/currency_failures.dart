import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';

/// A zero or negative exchange rate was submitted (FR-006).
class InvalidExchangeRateFailure extends Failure {
  const InvalidExchangeRateFailure()
    : super('Exchange rate must be greater than zero');
}

/// Switching the primary currency would strand existing records in the
/// outgoing primary currency with no rate to the new one (FR-012). The
/// caller prompts for a rate for [previousPrimary] and retries.
class RateRequiredForSwitchFailure extends Failure {
  RateRequiredForSwitchFailure(this.previousPrimary)
    : super('A rate for ${previousPrimary.code} is required to switch');

  final Currency previousPrimary;

  @override
  List<Object?> get props => [message, previousPrimary];
}

/// A currency code outside the bundled catalog.
class CurrencyNotFoundFailure extends Failure {
  const CurrencyNotFoundFailure(String code) : super('Unknown currency: $code');
}
