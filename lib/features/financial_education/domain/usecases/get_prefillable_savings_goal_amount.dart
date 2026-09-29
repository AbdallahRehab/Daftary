import 'package:injectable/injectable.dart';

import '../../../../core/money/currency.dart';
import '../../../savings/domain/entities/savings_overview.dart';
import '../../../savings/domain/usecases/get_savings_overview.dart';

/// FR-014: the optional, read-only "start from my savings goal" convenience
/// for the compound-growth calculator.
///
/// This is the single integration point between this feature and Savings
/// Goals (spec 011) — the ONLY place in financial_education that reads
/// another feature's data, and then only to copy one number into an
/// editable form field (research.md Decision 3). It reads through 011's
/// Domain use case [GetSavingsOverview] (never its data layer) and has no
/// way to write anything.
///
/// Returns the current saved amount (minor units) of the most recently
/// created active goal, or `null` — "nothing to pre-fill", so the calculator
/// hides the action and manual entry works as always — when:
/// - the user has no active goal (spec Edge Cases);
/// - that goal has nothing saved yet (an empty starting value is no
///   convenience);
/// - that goal is not in [calculatorCurrency]: the calculator shows every
///   amount in EGP, and copying another currency's figure into it would
///   silently relabel it — a conversion would make it an app-chosen number
///   rather than the goal's own figure (FR-014 "purely a numeric copy");
/// - reading the goals fails. Never throws, never returns a `Failure`.
@injectable
class GetPrefillableSavingsGoalAmount {
  const GetPrefillableSavingsGoalAmount(this._getSavingsOverview);

  final GetSavingsOverview _getSavingsOverview;

  /// The currency the compound-growth calculator formats its amounts in.
  static const Currency calculatorCurrency = Currency.egp;

  /// The amount (minor units) to offer as a pre-fill, or `null` when there
  /// is nothing to offer.
  Future<int?> call() async {
    try {
      final overview = await _getSavingsOverview();
      return overview.fold<int?>((_) => null, _amountToOffer);
    } on Object {
      // An optional convenience must never break the calculator.
      return null;
    }
  }

  static int? _amountToOffer(SavingsOverview overview) {
    GoalOverviewLine? newest;
    for (final line in overview.goals) {
      if (line.goal.isArchived) continue;
      if (newest == null ||
          line.goal.createdAt.isAfter(newest.goal.createdAt)) {
        newest = line;
      }
    }
    if (newest == null) return null;
    final progress = newest.progress;
    if (progress.currency != calculatorCurrency) return null;
    final saved = progress.currentAmountMinorUnits;
    return saved > 0 ? saved : null;
  }
}
