import 'package:equatable/equatable.dart';

/// Why a calculator refused a set of inputs. Each value maps to one clear,
/// localized inline message in the Presentation layer (FR-008/FR-011/
/// FR-012) — never to a thrown exception.
enum CalculatorInputProblem {
  /// A monetary amount that must be strictly positive was zero or negative.
  nonPositiveAmount,

  /// A rate that may be zero was negative.
  negativeRate,

  /// A duration was zero or negative.
  nonPositiveDuration,

  /// An income figure was zero or negative (the savings-rate divisor).
  nonPositiveIncome,

  /// A rate that must be strictly positive (the doubling-time divisor) was
  /// zero or negative.
  nonPositiveRate,

  /// A savings amount was negative. Zero is allowed (a 0% savings rate).
  negativeSavings,

  /// The inputs are individually valid but the resulting figure cannot be
  /// represented exactly in minor units (it exceeds 2^53 piastres, roughly
  /// 90 trillion EGP). Only reachable with extreme amount/rate/duration
  /// combinations; reported instead of showing an imprecise or overflowed
  /// number.
  resultTooLarge,
}

/// Either a computed [T] on success, or a typed validation [problem].
///
/// Deliberately NOT an `Either<Failure, T>` from `core/error`: these are
/// pure, side-effect-free input-validation outcomes local to this feature's
/// calculators, not repository/I/O failures
/// (contracts/education_content_repository.md).
class CalculatorValidationResult<T> extends Equatable {
  const CalculatorValidationResult.success(T this.value) : problem = null;

  const CalculatorValidationResult.invalid(CalculatorInputProblem this.problem)
    : value = null;

  final T? value;
  final CalculatorInputProblem? problem;

  bool get isSuccess => problem == null;

  @override
  List<Object?> get props => [value, problem];
}
