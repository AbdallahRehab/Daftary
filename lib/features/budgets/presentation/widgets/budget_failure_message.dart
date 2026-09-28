import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/budget_failures.dart';

/// A user-facing, localized explanation for a budgets [failure] (FR-020).
///
/// The budgets-specific failures get their own wording; anything else
/// (validation from the repository, storage errors) falls back to the
/// failure's own message, and an empty one to the generic error.
String budgetFailureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      BudgetAlreadyExistsForMonthFailure() => l10n.budgetAlreadyExistsError,
      DuplicateBudgetAllocationFailure() => l10n.budgetDuplicateCategoryError,
      BudgetNotFoundFailure() => l10n.budgetNotFoundError,
      _ when failure.message.trim().isNotEmpty => failure.message,
      _ => l10n.errorUnknown,
    };
