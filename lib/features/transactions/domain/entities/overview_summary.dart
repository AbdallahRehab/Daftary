import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

/// One person's contribution to the consolidated overview (FR-013).
class PersonSummary extends Equatable {
  const PersonSummary({
    required this.personId,
    required this.name,
    required this.net,
    required this.isArchived,
  });

  final String personId;
  final String name;
  final Money net;
  final bool isArchived;

  @override
  List<Object?> get props => [personId, name, net, isArchived];
}

/// Consolidated totals/groupings across all people, active and archived
/// (FR-013, FR-024). Archived people with a non-zero balance are included
/// in both totals and their respective list (Clarifications).
class OverviewSummary extends Equatable {
  const OverviewSummary({
    required this.totalOwedToUser,
    required this.totalUserOwes,
    required this.peopleTheyOweYou,
    required this.peopleYouOweThem,
    required this.settledCount,
  });

  final Money totalOwedToUser;
  final Money totalUserOwes;
  final List<PersonSummary> peopleTheyOweYou;
  final List<PersonSummary> peopleYouOweThem;
  final int settledCount;

  bool get isAllSettled => peopleTheyOweYou.isEmpty && peopleYouOweThem.isEmpty;

  @override
  List<Object?> get props => [
    totalOwedToUser,
    totalUserOwes,
    peopleTheyOweYou,
    peopleYouOweThem,
    settledCount,
  ];
}
