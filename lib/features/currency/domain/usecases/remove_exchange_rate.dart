import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/currency_repository.dart';

/// Removes the rate(s) converting from [currencyCode]. No record is ever
/// modified; totals that needed the rate become blocked again.
@injectable
class RemoveExchangeRate {
  const RemoveExchangeRate(this._repository);

  final CurrencyRepository _repository;

  Future<Either<Failure, Unit>> call(String currencyCode) =>
      _repository.removeExchangeRate(currencyCode);
}
