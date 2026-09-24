import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/exchange_rate.dart';
import '../repositories/currency_repository.dart';

/// Every configured exchange rate (FR-006/FR-007).
@injectable
class GetExchangeRates {
  const GetExchangeRates(this._repository);

  final CurrencyRepository _repository;

  Future<Either<Failure, List<ExchangeRate>>> call() =>
      _repository.getExchangeRates();
}
