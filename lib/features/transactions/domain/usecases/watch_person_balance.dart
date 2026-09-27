import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/person_balance.dart';
import '../repositories/transactions_repository.dart';

/// 021: one person's live balance (FR-008, FR-009, FR-031).
@injectable
class WatchPersonBalance {
  const WatchPersonBalance(this._repository);

  final TransactionsRepository _repository;

  Stream<Either<Failure, PersonBalance>> call(String personId) =>
      _repository.watchPersonBalance(personId);
}
