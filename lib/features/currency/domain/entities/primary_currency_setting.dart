import 'package:equatable/equatable.dart';

import '../../../../core/money/currency.dart';

/// The single, device-wide primary currency every aggregate total is
/// expressed in (FR-005). Defaults to EGP when never set; [updatedAt] is
/// null in that never-set case.
class PrimaryCurrencySetting extends Equatable {
  const PrimaryCurrencySetting({required this.currency, this.updatedAt});

  static const PrimaryCurrencySetting defaultSetting = PrimaryCurrencySetting(
    currency: Currency.egp,
  );

  final Currency currency;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [currency, updatedAt];
}
