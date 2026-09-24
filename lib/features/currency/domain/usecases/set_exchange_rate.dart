import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../entities/currency_failures.dart';
import '../entities/exchange_rate.dart';
import '../repositories/currency_repository.dart';

/// Upserts "1 [currencyCode] = [rate] [relativeToCurrencyCode]". Rejects
/// zero/negative/non-finite rates (FR-006) and unknown codes before touching
/// storage.
@injectable
class SetExchangeRate {
  const SetExchangeRate(this._repository);

  final CurrencyRepository _repository;

  Future<Either<Failure, ExchangeRate>> call({
    required String currencyCode,
    required String relativeToCurrencyCode,
    required double rate,
  }) async {
    if (!rate.isFinite || ExchangeRate.toMicros(rate) <= 0) {
      return left(const InvalidExchangeRateFailure());
    }
    for (final code in [currencyCode, relativeToCurrencyCode]) {
      if (Currency.tryFromCode(code) == null) {
        return left(CurrencyNotFoundFailure(code));
      }
    }
    if (currencyCode == relativeToCurrencyCode) {
      return left(const InvalidExchangeRateFailure());
    }
    return _repository.setExchangeRate(
      currencyCode: currencyCode,
      relativeToCurrencyCode: relativeToCurrencyCode,
      rate: rate,
    );
  }
}
