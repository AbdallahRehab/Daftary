import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

/// A person's relationship status, derived solely from the sign of their
/// net balance (FR-009) — never stored independently.
enum RelationshipStatus { theyOweYou, youOweThem, settled }

/// The net financial position between the user and a [Person], computed
/// entirely from that person's non-deleted [MoneyTransaction] rows: sum of
/// `given` minus sum of `received` (FR-008). Positive ⇒ they owe you,
/// negative ⇒ you owe them, zero ⇒ settled.
class PersonBalance extends Equatable {
  const PersonBalance({required this.personId, required this.net});

  final String personId;
  final Money net;

  RelationshipStatus get status {
    if (net.isPositive) return RelationshipStatus.theyOweYou;
    if (net.isNegative) return RelationshipStatus.youOweThem;
    return RelationshipStatus.settled;
  }

  @override
  List<Object?> get props => [personId, net];
}
