import 'package:equatable/equatable.dart';

import 'currency.dart';

export 'currency.dart';

/// An exact amount of one [Currency], stored as a signed count of that
/// currency's minor units (e.g. piastres for EGP). Every arithmetic operation
/// stays in the integer domain — there is no floating-point representation
/// anywhere in this type, per the constitution's deterministic-financial-
/// calculation requirement.
///
/// 018: the currency is part of the value and always explicit (research.md
/// Decision 2) — there is no implicit-EGP default. Arithmetic across two
/// different currencies throws; only `CurrencyConverter` may bridge them.
class Money extends Equatable implements Comparable<Money> {
  const Money.fromMinorUnits(this.minorUnits, this.currency);

  /// Shorthand for an explicitly-EGP amount.
  const Money.egp(this.minorUnits) : currency = Currency.egp;

  factory Money.zero(Currency currency) => Money.fromMinorUnits(0, currency);

  /// The exact amount, in [currency]'s minor units.
  final int minorUnits;

  final Currency currency;

  /// EGP's divisor. Prefer `currency.minorUnitsPerMajor` for non-EGP amounts.
  static const int minorUnitsPerMajorUnit = 100;

  bool get isZero => minorUnits == 0;
  bool get isPositive => minorUnits > 0;
  bool get isNegative => minorUnits < 0;

  Money add(Money other) {
    _assertSameCurrency(other);
    return Money.fromMinorUnits(minorUnits + other.minorUnits, currency);
  }

  Money subtract(Money other) {
    _assertSameCurrency(other);
    return Money.fromMinorUnits(minorUnits - other.minorUnits, currency);
  }

  Money negate() => Money.fromMinorUnits(-minorUnits, currency);

  Money abs() => Money.fromMinorUnits(minorUnits.abs(), currency);

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'Cannot combine ${currency.code} and ${other.currency.code} amounts '
        'directly — convert through CurrencyConverter first.',
      );
    }
  }

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  List<Object?> get props => [minorUnits, currency];

  @override
  String toString() => 'Money($minorUnits ${currency.code} minor units)';
}
