import 'package:equatable/equatable.dart';

/// An exact amount of Egyptian Pounds, stored as a signed count of piastres
/// (1 EGP = 100 piastres). Every arithmetic operation stays in the integer
/// domain — there is no floating-point representation anywhere in this type,
/// per the constitution's deterministic-financial-calculation requirement.
class Money extends Equatable implements Comparable<Money> {
  const Money.fromMinorUnits(this.minorUnits);

  factory Money.zero() => const Money.fromMinorUnits(0);

  /// The exact amount, in piastres (1/100th of an EGP).
  final int minorUnits;

  static const int minorUnitsPerMajorUnit = 100;

  bool get isZero => minorUnits == 0;
  bool get isPositive => minorUnits > 0;
  bool get isNegative => minorUnits < 0;

  Money add(Money other) => Money.fromMinorUnits(minorUnits + other.minorUnits);

  Money subtract(Money other) =>
      Money.fromMinorUnits(minorUnits - other.minorUnits);

  Money negate() => Money.fromMinorUnits(-minorUnits);

  Money abs() => Money.fromMinorUnits(minorUnits.abs());

  @override
  int compareTo(Money other) => minorUnits.compareTo(other.minorUnits);

  bool operator <(Money other) => minorUnits < other.minorUnits;
  bool operator <=(Money other) => minorUnits <= other.minorUnits;
  bool operator >(Money other) => minorUnits > other.minorUnits;
  bool operator >=(Money other) => minorUnits >= other.minorUnits;

  @override
  List<Object?> get props => [minorUnits];

  @override
  String toString() => 'Money($minorUnits piastres)';
}
