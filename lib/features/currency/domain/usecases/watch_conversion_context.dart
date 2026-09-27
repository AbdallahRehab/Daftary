import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/combine_latest.dart';
import '../../../../core/utils/either_equality.dart';
import '../entities/conversion_context.dart';
import '../entities/exchange_rate.dart';
import '../entities/primary_currency_setting.dart';
import '../repositories/currency_repository.dart';

/// 021: the live form of `GetConversionContext` — the primary currency and
/// every rate, re-emitted when either changes. For watched aggregates that
/// convert in the Domain (e.g. `WatchFinanceSummary`).
@injectable
class WatchConversionContext {
  const WatchConversionContext(this._repository);

  final CurrencyRepository _repository;

  Stream<Either<Failure, ConversionContext>> call() => combineLatest2(
    _repository.watchPrimaryCurrency(),
    _repository.watchExchangeRates(),
    (
      Either<Failure, PrimaryCurrencySetting> primary,
      Either<Failure, List<ExchangeRate>> rates,
    ) => primary.flatMap(
      (setting) => rates.map(
        (rates) => ConversionContext(primary: setting.currency, rates: rates),
      ),
    ),
  ).distinct(sameResult);
}
