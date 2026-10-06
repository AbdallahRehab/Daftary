import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/find_possible_duplicate.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockFindPossibleDuplicate extends Mock implements FindPossibleDuplicate {}

/// A [FindPossibleDuplicate] that answers [match] (default: no duplicate).
MockFindPossibleDuplicate findPossibleDuplicateReturning([
  MoneyTransaction? match,
]) {
  final finder = MockFindPossibleDuplicate();
  stubFindPossibleDuplicate(finder, match);
  return finder;
}

void stubFindPossibleDuplicate(
  MockFindPossibleDuplicate finder,
  MoneyTransaction? match,
) {
  registerFallbackValue(const Money.egp(0));
  registerFallbackValue(TransactionDirection.given);
  registerFallbackValue(DateTime(2026));
  when(
    () => finder(
      personId: any(named: 'personId'),
      amount: any(named: 'amount'),
      direction: any(named: 'direction'),
      date: any(named: 'date'),
    ),
  ).thenAnswer((_) async => Right(match));
}
