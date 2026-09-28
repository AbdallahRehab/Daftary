import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../entities/tool_result.dart';

/// One financial query tool the provider may call (research.md Decision 4,
/// contracts/financial_query_tools.md).
///
/// Every implementation is a thin wrapper around exactly one existing use
/// case: it validates the model-supplied [call] arguments, invokes that use
/// case unchanged, and copies the figures it returned into a minimal
/// [ToolResult]. No implementation performs arithmetic of its own — the one
/// documented exception is `CompareSpendingAcrossPeriodsTool`.
///
/// Malformed arguments yield a `ValidationFailure`; a failure from the
/// wrapped use case is passed through as-is. A legitimate "nothing to
/// report" is a successful result with `foundData: false`, never a failure
/// and never a fabricated zero.
abstract class AITool {
  const AITool();

  /// The `AIToolNames` value this tool is declared and dispatched under.
  String get name;

  Future<Either<Failure, ToolResult>> call(Map<String, Object?> arguments);
}

/// A requested tool name that is not one of the dispatchable tools. The
/// model asked for something the app never declared, so there is nothing
/// to run — never a reason to improvise an answer.
class UnknownAIToolFailure extends Failure {
  const UnknownAIToolFailure(this.toolName)
    : super('Unknown AI tool: $toolName');

  final String toolName;

  @override
  List<Object?> get props => [message, toolName];
}

/// Keys every tool result shares, so the model can narrate amounts in the
/// right unit without being told separately per tool.
abstract final class AIToolDataKeys {
  static const String currency = 'currency';
  static const String amountUnit = 'amountUnit';
  static const String minorUnitsPerMajorUnit = 'minorUnitsPerMajorUnit';

  /// Why `foundData` is `false` (one of [AIToolNoDataReasons]).
  static const String reason = 'reason';

  /// For an ambiguous name: the names that matched, so the model can ask
  /// the user which one they meant instead of guessing.
  static const String candidates = 'candidates';

  /// ISO 4217 codes that need an exchange rate (with
  /// [AIToolNoDataReasons.exchangeRateMissing]).
  static const String missingRatesFor = 'missingRatesFor';

  /// One amount's minor units inside [aiNativeAmountsData].
  static const String amountMinorUnits = 'amountMinorUnits';

  /// Per-currency amounts that could not be converted (018).
  static const String nativeAmounts = 'nativeAmounts';
}

/// Values of [AIToolDataKeys.reason].
abstract final class AIToolNoDataReasons {
  static const String noEntriesForPeriod = 'noEntriesForPeriod';
  static const String categoryNotFound = 'categoryNotFound';
  static const String ambiguousCategory = 'ambiguousCategory';
  static const String personNotFound = 'personNotFound';
  static const String ambiguousPerson = 'ambiguousPerson';
  static const String noPeopleRecorded = 'noPeopleRecorded';
  static const String noBudgetForMonth = 'noBudgetForMonth';
  static const String occasionNotFound = 'occasionNotFound';
  static const String ambiguousOccasion = 'ambiguousOccasion';
  static const String noOccasionsRecorded = 'noOccasionsRecorded';
  static const String insufficientHistory = 'insufficientHistory';
  static const String belowThreshold = 'belowThreshold';

  /// 018: the figure needs an exchange rate the user has not set, so it is
  /// not known; [AIToolDataKeys.missingRatesFor] names the currencies. The
  /// model must say so, never estimate one.
  static const String exchangeRateMissing = 'exchangeRateMissing';
}

/// The money-unit metadata merged into every tool result's data: amounts
/// are integer minor units of [currency] — the primary currency the wrapped
/// use cases converted into (018) — exactly as they return them
/// (`Money.minorUnits`).
Map<String, Object?> aiToolMoneyUnits(Currency currency) => {
  AIToolDataKeys.currency: currency.code,
  AIToolDataKeys.amountUnit: 'minorUnits',
  AIToolDataKeys.minorUnitsPerMajorUnit: currency.minorUnitsPerMajor,
};

/// The data of a result whose figure is blocked on missing exchange rates
/// (018 FR-009): no amount at all, only which rates are needed.
Map<String, Object?> aiRatesMissingData(List<Currency> missingRatesFor) => {
  AIToolDataKeys.reason: AIToolNoDataReasons.exchangeRateMissing,
  AIToolDataKeys.missingRatesFor: [for (final c in missingRatesFor) c.code],
};

/// Amounts that could not be converted into the primary currency (018),
/// each labelled with its own currency — real recorded values, reported as
/// they are rather than summed across currencies.
List<Map<String, Object?>> aiNativeAmountsData(List<Money> amounts) => [
  for (final amount in amounts)
    {
      AIToolDataKeys.currency: amount.currency.code,
      AIToolDataKeys.amountMinorUnits: amount.minorUnits,
      AIToolDataKeys.minorUnitsPerMajorUnit: amount.currency.minorUnitsPerMajor,
    },
];
