import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/exchange_rate.dart';
import '../repositories/currency_repository.dart';

/// 021: every configured rate, live (FR-006, FR-007, FR-031).
@injectable
class WatchExchangeRates {
  const WatchExchangeRates(this._repository);

  final CurrencyRepository _repository;

  Stream<Either<Failure, List<ExchangeRate>>> call() =>
      _repository.watchExchangeRates();
}
