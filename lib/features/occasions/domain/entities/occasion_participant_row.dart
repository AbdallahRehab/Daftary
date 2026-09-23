import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/domain/entities/person_balance.dart';

/// One row of an occasion's participant list (FR-016): a linked
/// `MoneyTransaction` joined with its `Person`.
class OccasionParticipantRow extends Equatable {
  const OccasionParticipantRow({
    required this.transactionId,
    required this.personId,
    required this.personName,
    required this.amount,
    required this.direction,
    required this.countsTowardBalance,
    required this.personOverallStatus,
    this.note,
  });

  /// The underlying `MoneyTransaction.id` — the same single row the person's
  /// own profile screen edits (FR-010). There is no second record here.
  final String transactionId;
  final String personId;
  final String personName;
  final Money amount;
  final TransactionDirection direction;

  /// Whether this contribution feeds the person's balance (FR-018). Shown so
  /// a condolence contribution that deliberately does not count reads as an
  /// intentional choice rather than a missing number.
  final bool countsTowardBalance;

  /// The person's whole-history `PersonBalance.status`, deliberately **not**
  /// an occasion-scoped balance: FR-009 requires the occasion view and the
  /// person's own profile to never disagree, so there is only ever one
  /// answer in the app to "does this person owe me".
  final RelationshipStatus personOverallStatus;
  final String? note;

  @override
  List<Object?> get props => [
    transactionId,
    personId,
    personName,
    amount,
    direction,
    countsTowardBalance,
    personOverallStatus,
    note,
  ];
}
