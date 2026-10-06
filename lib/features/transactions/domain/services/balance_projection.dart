import '../../../../core/money/money.dart';
import '../../../currency/domain/entities/conversion_context.dart';
import '../entities/person_balance.dart';
import 'person_balance_calculator.dart';

/// Pure "what would the balance be if this amount were added" (022 A2/E6).
///
/// The change is applied to the matching per-currency net and the result is
/// re-totalled with [PersonBalanceCalculator] under the same
/// [ConversionContext], so a projection rounds exactly like the balance
/// that will be shown after the change is saved.
abstract final class BalanceProjection {
  /// The primary-currency net after adding [change] (signed, in its own
  /// currency) to [balance], or `null` when [balance] is blocked or the
  /// result needs a rate that is missing.
  static Money? afterChange(
    PersonBalance balance,
    Money change,
    ConversionContext context,
  ) {
    final net = balance.net;
    if (net == null) return null;
    final nets = <String, int>{
      for (final m
          in balance.currencyNets.isEmpty ? [net] : balance.currencyNets)
        m.currency.code: m.minorUnits,
    };
    nets.update(
      change.currency.code,
      (v) => v + change.minorUnits,
      ifAbsent: () => change.minorUnits,
    );
    return const PersonBalanceCalculator()
        .calculate(
          personId: balance.personId,
          nativeNetsByCode: nets,
          context: context,
        )
        .net;
  }
}
