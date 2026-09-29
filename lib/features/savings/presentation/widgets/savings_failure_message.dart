import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../domain/entities/savings_failures.dart';

/// A user-facing, localized explanation for a savings [failure].
///
/// The savings-specific failures get their own wording; everything else —
/// validation, storage errors and 018's `RatesMissingFailure` (which names
/// the missing rates) — goes through the app-wide [FailureMessage] mapping.
/// Lives in the feature, like `budgetFailureMessage`, because `core/` never
/// imports a feature.
String savingsFailureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      GoalNotFoundFailure() => l10n.savingsGoalNotFoundError,
      WithdrawalExceedsBalanceFailure() =>
        l10n.savingsWithdrawalExceedsBalanceError,
      GoalHasHistoryFailure() => l10n.savingsGoalHasHistoryError,
      InvalidTargetDateFailure() => l10n.savingsInvalidTargetDateError,
      GoalArchivedFailure() => l10n.savingsGoalArchivedError,
      GoalAlreadyAchievedFailure() => l10n.savingsWhatIfAchievedMessage,
      _ => l10n.messageFor(failure),
    };
