import 'package:equatable/equatable.dart';

import '../../../../core/money/currency.dart';

/// "1 unit of [currency] = [rate] units of [relativeTo]" (data-model.md).
///
/// The rate is held as a scaled integer ([rateMicros] = rate × 1,000,000)
/// rather than a `double`, so conversion arithmetic stays in the integer
/// domain (constitution Principle VIII). [relativeTo] is stored explicitly
/// so a rate stays interpretable after the primary currency changes.
class ExchangeRate extends Equatable {
  const ExchangeRate({
    required this.currency,
    required this.relativeTo,
    required this.rateMicros,
    required this.lastUpdatedAt,
  });

  static const int microsPerUnit = 1000000;

  final Currency currency;
  final Currency relativeTo;
  final int rateMicros;
  final DateTime lastUpdatedAt;

  /// The rate as a decimal, for display only — never used in arithmetic.
  double get rate => rateMicros / microsPerUnit;

  /// Converts a user-entered decimal rate to [rateMicros], rounding
  /// half-up at the sixth decimal place.
  static int toMicros(double rate) => (rate * microsPerUnit).round();

  @override
  List<Object?> get props => [currency, relativeTo, rateMicros, lastUpdatedAt];
}
