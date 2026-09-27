import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/primary_currency_setting.dart';
import '../repositories/currency_repository.dart';

/// 021: the live primary currency (FR-005, FR-031).
@injectable
class WatchPrimaryCurrency {
  const WatchPrimaryCurrency(this._repository);

  final CurrencyRepository _repository;

  Stream<Either<Failure, PrimaryCurrencySetting>> call() =>
      _repository.watchPrimaryCurrency();
}
