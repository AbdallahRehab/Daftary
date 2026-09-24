import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/primary_currency_setting.dart';
import '../repositories/currency_repository.dart';

/// The current primary currency (FR-005) — also the default every
/// amount-entry form's `CurrencyPicker` starts on (FR-003).
@injectable
class GetPrimaryCurrency {
  const GetPrimaryCurrency(this._repository);

  final CurrencyRepository _repository;

  Future<Either<Failure, PrimaryCurrencySetting>> call() =>
      _repository.getPrimaryCurrency();
}
