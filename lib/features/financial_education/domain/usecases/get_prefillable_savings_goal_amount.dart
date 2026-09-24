import 'package:injectable/injectable.dart';

/// FR-014: the optional, read-only "start from my savings goal" convenience
/// for the compound-growth calculator.
///
/// This is the single reserved integration point between this feature and
/// Savings Goals (spec 011) — the ONLY place in financial_education that
/// may ever read another feature's data, and then only to copy one number
/// into an editable form field (research.md Decision 3). It must never
/// write anything.
///
/// **Current build: 011 is not present.** There is no `SavingsRepository`
/// in this codebase, so this use case takes the spec's graceful-degradation
/// path (Edge Cases: "degrades gracefully to unavailable") and always
/// resolves to `null`, which the calculator treats as "nothing to pre-fill"
/// and hides the pre-fill action entirely. The calculator stays fully
/// functional with manual entry.
///
/// When 011 ships, inject its `SavingsRepository` here (read-only) and
/// return the most-recently-created active goal's current saved amount in
/// minor units — or `null` when the user has no active goals or the read
/// fails. No caller needs to change: the contract is already `int?`.
@injectable
class GetPrefillableSavingsGoalAmount {
  const GetPrefillableSavingsGoalAmount();

  /// The amount (minor units) to offer as a pre-fill, or `null` when there
  /// is nothing to offer. Never throws, never returns a `Failure`.
  Future<int?> call() async => null;
}
