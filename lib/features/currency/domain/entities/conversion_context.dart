import 'package:equatable/equatable.dart';

import '../../../../core/money/currency.dart';
import 'exchange_rate.dart';

/// Everything an aggregation call site needs to hand `CurrencyConverter`:
/// the current primary currency (the target of every aggregate total) and
/// every configured rate. Fetched once per aggregation.
class ConversionContext extends Equatable {
  const ConversionContext({required this.primary, required this.rates});

  /// EGP with no rates — the pre-018 world, and the EGP-only user's world.
  static const ConversionContext egpOnly = ConversionContext(
    primary: Currency.egp,
    rates: [],
  );

  final Currency primary;
  final List<ExchangeRate> rates;

  @override
  List<Object?> get props => [primary, rates];
}
