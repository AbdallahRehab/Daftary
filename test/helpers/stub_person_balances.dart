import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

/// Answers the batched `getPersonBalances` from whatever per-person
/// `getPersonBalance` stubs a test already sets up, so tests written
/// against the per-person API keep exercising the same balances. A person
/// whose balance fails is left out, as the People list always did.
void stubPersonBalancesFromSingle(TransactionsRepository repository) {
  registerFallbackValue(<String>[]);
  when(() => repository.getPersonBalances(any())).thenAnswer((
    invocation,
  ) async {
    final ids = invocation.positionalArguments.first as List<String>;
    final balances = <String, PersonBalance>{};
    for (final id in ids) {
      final result = await repository.getPersonBalance(id);
      if (result case Right(:final value)) balances[id] = value;
    }
    return Right(balances);
  });
}
