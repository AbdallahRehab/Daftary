import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../entities/currency_failures.dart';
import '../ports/currency_usage_checker.dart';
import '../repositories/currency_repository.dart';
import 'set_exchange_rate.dart';

/// Changes the device-wide primary currency, enforcing FR-012
/// (contracts/currency_converter.md):
///
///  - switching to the current primary is a no-op success;
///  - if any live record is still denominated in the outgoing primary and
///    no rate (outgoing → new) exists, the switch is refused with
///    [RateRequiredForSwitchFailure] — unless [rateForPreviousPrimary] is
///    supplied, in which case that rate is validated and stored first and
///    the switch then completes.
///
/// Rates stay stored with their explicit `relativeTo` currency, so rates
/// quoted against the OLD primary survive a switch but no longer feed
/// aggregate totals (`CurrencyConverter` only uses direct X → primary
/// rates). That is by design: the rate list shows each rate's full pair,
/// and any total that now lacks a rate shows the "rate needed" state.
///
/// The "is this currency used" check is the feature's one cross-feature
/// read, isolated behind [CurrencyUsageChecker] (read-only).
@injectable
class SetPrimaryCurrency {
  const SetPrimaryCurrency(
    this._repository,
    this._usageChecker,
    this._setExchangeRate,
  );

  final CurrencyRepository _repository;
  final CurrencyUsageChecker _usageChecker;
  final SetExchangeRate _setExchangeRate;

  Future<Either<Failure, Unit>> call({
    required String newPrimaryCurrencyCode,
    double? rateForPreviousPrimary,
  }) async {
    if (Currency.tryFromCode(newPrimaryCurrencyCode) == null) {
      return Left(CurrencyNotFoundFailure(newPrimaryCurrencyCode));
    }
    final current = await _repository.getPrimaryCurrency();
    return current.fold(Left.new, (setting) async {
      final previous = setting.currency;
      if (previous.code == newPrimaryCurrencyCode) return const Right(unit);

      if (rateForPreviousPrimary != null) {
        final saved = await _setExchangeRate(
          currencyCode: previous.code,
          relativeToCurrencyCode: newPrimaryCurrencyCode,
          rate: rateForPreviousPrimary,
        );
        if (saved.isLeft()) {
          return Left(saved.getLeft().toNullable()!);
        }
        return _repository.setPrimaryCurrency(newPrimaryCurrencyCode);
      }

      final inUse = await _usageChecker.isCurrencyInUse(previous.code);
      return inUse.fold(Left.new, (used) async {
        if (used) {
          final rates = await _repository.getExchangeRates();
          final Either<Failure, bool> hasRate = rates.map(
            (all) => all.any(
              (r) =>
                  r.currency == previous &&
                  r.relativeTo.code == newPrimaryCurrencyCode,
            ),
          );
          final blocked = hasRate.fold<Failure?>(
            (failure) => failure,
            (exists) => exists ? null : RateRequiredForSwitchFailure(previous),
          );
          if (blocked != null) return Left(blocked);
        }
        return _repository.setPrimaryCurrency(newPrimaryCurrencyCode);
      });
    });
  }
}
