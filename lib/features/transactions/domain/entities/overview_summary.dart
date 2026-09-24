import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

/// One person's contribution to the consolidated overview (FR-013).
///
/// 018: mirrors `PersonBalance` — [net] is in the primary currency, or
/// `null` when this person's balance is blocked on a missing exchange rate,
/// in which case [nativeNets]/[missingRatesFor] describe what is known.
class PersonSummary extends Equatable {
  const PersonSummary({
    required this.personId,
    required this.name,
    required this.net,
    required this.isArchived,
    this.nativeNets = const [],
    this.missingRatesFor = const [],
  });

  final String personId;
  final String name;
  final Money? net;
  final bool isArchived;
  final List<Money> nativeNets;
  final List<Currency> missingRatesFor;

  bool get isBlocked => net == null;

  @override
  List<Object?> get props => [
    personId,
    name,
    net,
    isArchived,
    nativeNets,
    missingRatesFor,
  ];
}

/// Consolidated totals/groupings across all people, active and archived
/// (FR-013, FR-024). Archived people with a non-zero balance are included
/// in both totals and their respective list (Clarifications).
///
/// 018: both totals are in the primary currency. A total is `null` (blocked,
/// FR-009) when any balance feeding it involves a currency without an
/// exchange rate; [missingRatesFor] names every such currency. A blocked
/// person whose per-currency nets point in opposite directions has no
/// knowable status and is listed in [peopleRateNeeded] instead of either
/// directional list.
class OverviewSummary extends Equatable {
  const OverviewSummary({
    required this.totalOwedToUser,
    required this.totalUserOwes,
    required this.peopleTheyOweYou,
    required this.peopleYouOweThem,
    required this.settledCount,
    this.peopleRateNeeded = const [],
    this.missingRatesFor = const [],
  });

  final Money? totalOwedToUser;
  final Money? totalUserOwes;
  final List<PersonSummary> peopleTheyOweYou;
  final List<PersonSummary> peopleYouOweThem;
  final List<PersonSummary> peopleRateNeeded;
  final int settledCount;

  /// Distinct, first-seen order, across both totals.
  final List<Currency> missingRatesFor;

  bool get isBlocked => missingRatesFor.isNotEmpty;

  bool get isAllSettled =>
      peopleTheyOweYou.isEmpty &&
      peopleYouOweThem.isEmpty &&
      peopleRateNeeded.isEmpty;

  @override
  List<Object?> get props => [
    totalOwedToUser,
    totalUserOwes,
    peopleTheyOweYou,
    peopleYouOweThem,
    peopleRateNeeded,
    settledCount,
    missingRatesFor,
  ];
}
