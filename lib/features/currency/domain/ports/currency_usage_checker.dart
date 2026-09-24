import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

/// Read-only answer to "is any live record denominated in this currency?" —
/// the one cross-feature read in 018, used solely by `SetPrimaryCurrency`
/// for FR-012's forced-rate check (contracts/currency_converter.md,
/// mirroring 017's single-narrow-exception isolation pattern).
///
/// Never writes, never makes a network call.
abstract class CurrencyUsageChecker {
  Future<Either<Failure, bool>> isCurrencyInUse(String currencyCode);
}
