import 'package:injectable/injectable.dart';

import '../entities/calculator_results.dart';
import '../entities/calculator_validation_result.dart';

/// Pure effective-savings-rate calculator (FR-012). No I/O, no repository
/// dependency (research.md Decision 3) — both figures are typed by the user.
abstract class SavingsRateCalculator {
  /// `savingsAmountMinorUnits / incomeMinorUnits × 100`.
  ///
  /// Rejects `incomeMinorUnits <= 0` ([CalculatorInputProblem
  /// .nonPositiveIncome], checked first) and `savingsAmountMinorUnits < 0`
  /// ([CalculatorInputProblem.negativeSavings]). A savings amount above the
  /// income is explicitly ACCEPTED and never clamped: it yields a rate
  /// above 100% (FR-012/Edge Cases).
  CalculatorValidationResult<SavingsRateResult> calculate({
    required int incomeMinorUnits,
    required int savingsAmountMinorUnits,
  });
}

/// The result is an unrounded `double` from a single deterministic
/// division; rounding for display is a Presentation concern.
@LazySingleton(as: SavingsRateCalculator)
class SavingsRateCalculatorImpl implements SavingsRateCalculator {
  const SavingsRateCalculatorImpl();

  @override
  CalculatorValidationResult<SavingsRateResult> calculate({
    required int incomeMinorUnits,
    required int savingsAmountMinorUnits,
  }) {
    if (incomeMinorUnits <= 0) {
      return const CalculatorValidationResult.invalid(
        CalculatorInputProblem.nonPositiveIncome,
      );
    }
    if (savingsAmountMinorUnits < 0) {
      return const CalculatorValidationResult.invalid(
        CalculatorInputProblem.negativeSavings,
      );
    }
    return CalculatorValidationResult.success(
      SavingsRateResult(
        savingsRatePercent: savingsAmountMinorUnits * 100 / incomeMinorUnits,
      ),
    );
  }
}
