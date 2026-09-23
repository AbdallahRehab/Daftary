import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

/// Whether an occasion's money came out even, or which side is still ahead
/// (FR-008).
enum SettlementStatus { settled, moreReceived, moreGiven }

/// An occasion's money totals, derived on demand from its non-deleted
/// `kind = occasionContribution` rows — never cached as columns on
/// `Occasions`, so a total can never silently drift out of sync with the
/// rows it summarizes (research.md Decision 4, constitution Principle VIII).
class OccasionSummary extends Equatable {
  const OccasionSummary({
    required this.occasionId,
    required this.totalReceived,
    required this.totalGiven,
    required this.participantCount,
  });

  factory OccasionSummary.empty(String occasionId) => OccasionSummary(
    occasionId: occasionId,
    totalReceived: Money.zero(),
    totalGiven: Money.zero(),
    participantCount: 0,
  );

  final String occasionId;

  /// `SUM(amount WHERE direction = received)` (FR-007).
  final Money totalReceived;

  /// `SUM(amount WHERE direction = given)` (FR-007).
  final Money totalGiven;

  /// Distinct `personId` count among the linked rows, which drives the
  /// "no participants yet" empty state (FR-020).
  final int participantCount;

  /// `totalReceived − totalGiven` (FR-007).
  Money get net => totalReceived.subtract(totalGiven);

  SettlementStatus get settlementStatus {
    if (net.isZero) return SettlementStatus.settled;
    return net.isPositive
        ? SettlementStatus.moreReceived
        : SettlementStatus.moreGiven;
  }

  /// The magnitude to show next to the settlement label — always positive,
  /// with the direction carried by [settlementStatus] instead of a sign
  /// (FR-008).
  Money get outstanding => net.abs();

  @override
  List<Object?> get props => [
    occasionId,
    totalReceived,
    totalGiven,
    participantCount,
  ];
}
