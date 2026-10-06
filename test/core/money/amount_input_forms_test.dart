import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/create_person.dart';
import 'package:daftary/features/transactions/domain/usecases/add_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/edit_transaction.dart';
import 'package:daftary/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:daftary/features/transactions/presentation/cubit/transaction_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../features/transactions/helpers/currency_test_doubles.dart';
import '../../features/transactions/helpers/duplicate_test_doubles.dart';

class _MockPeopleRepository extends Mock implements PeopleRepository {}

class _MockCreatePerson extends Mock implements CreatePerson {}

class _MockAddTransaction extends Mock implements AddTransaction {}

class _MockEditTransaction extends Mock implements EditTransaction {}

/// 022 Phase 2 (T011) — the real transaction form must reject the same
/// inputs the amount-input catalogue rejects (CHK136, CHK137).
void main() {
  final now = DateTime(2026, 1, 1);
  final ahmed = Person(
    id: 'p1',
    name: 'Ahmed',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );

  for (final input in ['', '0', '-5', '0.001']) {
    test('TransactionFormCubit rejects "$input" with amountInvalid', () async {
      final add = _MockAddTransaction();
      final cubit = TransactionFormCubit(
        _MockPeopleRepository(),
        _MockCreatePerson(),
        add,
        _MockEditTransaction(),
        getPrimaryCurrencyReturning(),
        findPossibleDuplicateReturning(),
      );
      addTearDown(cubit.close);
      // ignore: invalid_use_of_visible_for_testing_member
      cubit.emit(
        TransactionFormState(
          idempotencyKey: 'key-1',
          selectedPerson: ahmed,
          amountInput: input,
        ),
      );

      await cubit.submit();

      expect(cubit.state.amountInvalid, isTrue);
      verifyZeroInteractions(add);
    });
  }
}
