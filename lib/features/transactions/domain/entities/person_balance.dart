import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

/// A person's relationship status, derived solely from the sign of their
/// net balance (FR-009) — never stored independently.
enum RelationshipStatus { theyOweYou, youOweThem, settled }

/// The net financial position between the user and a [Person], computed
/// entirely from that person's non-deleted [MoneyTransaction] rows: sum of
/// `given` minus sum of `received` (FR-008). Positive ⇒ they owe you,
/// negative ⇒ you owe them, zero ⇒ settled.
///
/// 018 (multi-currency): the net is always expressed in the primary
/// currency, converted from each record's own currency through
/// `CurrencyConverter`. When a currency involved has no exchange rate, the
/// balance is *blocked* ([PersonBalance.blocked]): [net] is `null`,
/// [missingRatesFor] names every currency that needs a rate, and
/// [nativeNets] carries the unconverted per-currency nets so the UI can
/// still show what is known. A blocked balance is never silently
/// converted at 1:1 nor partially summed (FR-009).
class PersonBalance extends Equatable {
  /// A fully-known balance, [net] in the primary currency.
  const PersonBalance({
    required this.personId,
    required Money this.net,
    this.currencyNets = const [],
  }) : nativeNets = const [],
       missingRatesFor = const [];

  /// A balance that cannot be totalled because [missingRatesFor] have no
  /// exchange rate into the primary currency.
  const PersonBalance.blocked({
    required this.personId,
    required this.nativeNets,
    required this.missingRatesFor,
  }) : net = null,
       currencyNets = nativeNets;

  final String personId;

  /// The net in the primary currency, or `null` when [isBlocked].
  final Money? net;

  /// Only populated when [isBlocked]: the non-zero per-currency nets, each
  /// in its own currency.
  final List<Money> nativeNets;

  /// Only populated when [isBlocked]: the distinct currencies lacking a
  /// rate into the primary currency.
  final List<Currency> missingRatesFor;

  /// The non-zero per-currency nets behind this balance, each in its own
  /// currency, for every balance (known or blocked). Lets a projection
  /// (a repayment preview, a delete warning) adjust one currency and
  /// re-total with `PersonBalanceCalculator` — so it rounds exactly as the
  /// saved balance will. Empty when unknown (hand-built balances): callers
  /// then fall back to [net].
  final List<Money> currencyNets;

  bool get isBlocked => net == null;

  /// The relationship status, or `null` when it genuinely cannot be known.
  ///
  /// A fully-known balance maps its sign as before. A blocked balance
  /// still has a well-defined status when every per-currency net points
  /// the same way (e.g. only USD lent out: they owe you, amount unknown in
  /// the primary currency). Only a blocked balance whose per-currency nets
  /// point in *opposite* directions has an unknown status (`null`) — it
  /// matches no status filter and shows a rate-needed indicator instead of
  /// a status badge.
  RelationshipStatus? get status {
    final known = net;
    if (known != null) return _statusOf(known.minorUnits);
    final anyPositive = nativeNets.any((m) => m.isPositive);
    final anyNegative = nativeNets.any((m) => m.isNegative);
    if (anyPositive && anyNegative) return null;
    if (anyPositive) return RelationshipStatus.theyOweYou;
    if (anyNegative) return RelationshipStatus.youOweThem;
    return RelationshipStatus.settled;
  }

  static RelationshipStatus _statusOf(int minorUnits) {
    if (minorUnits > 0) return RelationshipStatus.theyOweYou;
    if (minorUnits < 0) return RelationshipStatus.youOweThem;
    return RelationshipStatus.settled;
  }

  @override
  List<Object?> get props => [
    personId,
    net,
    nativeNets,
    missingRatesFor,
    currencyNets,
  ];
}
