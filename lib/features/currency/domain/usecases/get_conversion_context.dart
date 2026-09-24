import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/conversion_context.dart';
import '../repositories/currency_repository.dart';

/// Primary currency + all rates in one call — what every aggregation use
/// case composes with `CurrencyConverter.sumToTargetCurrency`.
@injectable
class GetConversionContext {
  const GetConversionContext(this._repository);

  final CurrencyRepository _repository;

  Future<Either<Failure, ConversionContext>> call() async {
    final primary = await _repository.getPrimaryCurrency();
    return primary.fold(left, (setting) async {
      final rates = await _repository.getExchangeRates();
      return rates.map(
        (rates) => ConversionContext(primary: setting.currency, rates: rates),
      );
    });
  }
}
