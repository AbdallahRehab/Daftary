import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import '../../../currency/domain/entities/conversion_context.dart';
import '../entities/person_balance.dart';
import 'balance_projection.dart';

/// What a repayment would do to a person's balance, before it is saved
/// (022 A2). Pure and integer-only: the repayment is converted into the
/// primary currency with [CurrencyConverter] and the balance's own
/// [ConversionContext] — never 1:1. A missing rate makes the preview
/// [blocked] (no number), never a guess.
///
/// Signs follow [PersonBalance.net]: positive = they owe you.
class RepaymentPreview extends Equatable {
  const RepaymentPreview._({
    this.outstanding,
    this.resulting,
    this.flips = false,
    this.blocked = false,
  });

  factory RepaymentPreview.of(
    PersonBalance balance,
    Money amount,
    ConversionContext context,
  ) {
    final net = balance.net;
    if (net == null) return const RepaymentPreview._(blocked: true);
    final outstanding = Money.fromMinorUnits(
      net.minorUnits.abs(),
      net.currency,
    );
    // They owe you => you receive (the repayment's currency net falls);
    // otherwise you give (it rises), exactly as the repository infers the
    // direction. The change is applied in the repayment's own currency and
    // everything is re-totalled, so rounding matches the saved balance.
    final signed = net.minorUnits > 0 ? -amount.minorUnits : amount.minorUnits;
    final resulting = BalanceProjection.afterChange(
      balance,
      Money.fromMinorUnits(signed, amount.currency),
      context,
    );
    if (resulting == null) {
      return RepaymentPreview._(outstanding: outstanding, blocked: true);
    }
    return RepaymentPreview._(
      outstanding: outstanding,
      resulting: resulting,
      flips: net.minorUnits != 0 && (resulting.minorUnits * net.minorUnits) < 0,
    );
  }

  /// The absolute amount still owed in the primary currency, or `null`
  /// when the balance itself is blocked.
  final Money? outstanding;

  /// The signed balance after the repayment, or `null` when [blocked].
  final Money? resulting;

  /// Whether the repayment is larger than the outstanding amount, so the
  /// balance reverses direction.
  final bool flips;

  /// No number can be shown: the balance or the repayment has no rate.
  final bool blocked;

  @override
  List<Object?> get props => [outstanding, resulting, flips, blocked];
}
