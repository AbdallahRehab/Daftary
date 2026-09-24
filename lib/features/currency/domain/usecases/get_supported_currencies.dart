import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../repositories/currency_repository.dart';

/// The bundled currency catalog (research.md Decision 1).
@injectable
class GetSupportedCurrencies {
  const GetSupportedCurrencies(this._repository);

  final CurrencyRepository _repository;

  Future<Either<Failure, List<Currency>>> call() =>
      _repository.getSupportedCurrencies();
}
