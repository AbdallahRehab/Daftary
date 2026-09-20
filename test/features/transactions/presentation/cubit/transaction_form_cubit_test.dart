import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/people/domain/entities/people_failures.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/create_person.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/add_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/edit_transaction.dart';
import 'package:daftary/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:daftary/features/transactions/presentation/cubit/transaction_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

class MockCreatePerson extends Mock implements CreatePerson {}

class MockAddTransaction extends Mock implements AddTransaction {}

class MockEditTransaction extends Mock implements EditTransaction {}

void main() {
  late MockPeopleRepository peopleRepository;
  late MockCreatePerson createPerson;
  late MockAddTransaction addTransaction;
  late MockEditTransaction editTransaction;
  late EgpFormatter egpFormatter;

  final now = DateTime(2026, 1, 1);
  final ahmed = Person(
    id: 'p1',
    name: 'Ahmed',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );
  final savedTransaction = MoneyTransaction(
    id: 't1',
    idempotencyKey: 'ignored-in-test',
    personId: 'p1',
    amount: const Money.fromMinorUnits(200000),
    direction: TransactionDirection.given,
    kind: TransactionKind.initialExchange,
    date: now,
    createdAt: now,
  );

  setUpAll(() {
    registerFallbackValue(const Money.fromMinorUnits(0));
    registerFallbackValue(TransactionDirection.given);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    peopleRepository = MockPeopleRepository();
    createPerson = MockCreatePerson();
    addTransaction = MockAddTransaction();
    editTransaction = MockEditTransaction();
    egpFormatter = EgpFormatter();
  });

  TransactionFormCubit buildCubit() => TransactionFormCubit(
    peopleRepository,
    createPerson,
    addTransaction,
    editTransaction,
    egpFormatter,
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'submit without a selected person surfaces a person error',
    build: buildCubit,
    act: (cubit) async {
      cubit.amountChanged('200');
      await cubit.submit();
    },
    expect: () => [
      isA<TransactionFormState>().having(
        (s) => s.amountInput,
        'amountInput',
        '200',
      ),
      isA<TransactionFormState>().having(
        (s) => s.personSelectionRequired,
        'personSelectionRequired',
        isTrue,
      ),
    ],
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'submit with a zero amount surfaces an amount error (FR-005)',
    build: buildCubit,
    seed: () => TransactionFormState(
      idempotencyKey: 'key-1',
      selectedPerson: ahmed,
      amountInput: '0',
    ),
    act: (cubit) => cubit.submit(),
    expect: () => [
      isA<TransactionFormState>().having(
        (s) => s.amountInvalid,
        'amountInvalid',
        isTrue,
      ),
    ],
    verify: (_) {
      verifyNever(
        () => addTransaction(
          idempotencyKey: any(named: 'idempotencyKey'),
          personId: any(named: 'personId'),
          amount: any(named: 'amount'),
          direction: any(named: 'direction'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      );
    },
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'happy path: valid person + amount saves the transaction',
    build: buildCubit,
    seed: () => TransactionFormState(
      idempotencyKey: 'key-1',
      selectedPerson: ahmed,
      amountInput: '2000',
    ),
    setUp: () {
      when(
        () => addTransaction(
          idempotencyKey: any(named: 'idempotencyKey'),
          personId: any(named: 'personId'),
          amount: any(named: 'amount'),
          direction: any(named: 'direction'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => Right(savedTransaction));
    },
    act: (cubit) => cubit.submit(),
    expect: () => [
      isA<TransactionFormState>().having(
        (s) => s.status,
        'status',
        TransactionFormStatus.submitting,
      ),
      isA<TransactionFormState>().having(
        (s) => s.status,
        'status',
        TransactionFormStatus.success,
      ),
    ],
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'a rapid double-tap only ever invokes AddTransaction once (FR-020)',
    build: buildCubit,
    seed: () => TransactionFormState(
      idempotencyKey: 'key-1',
      selectedPerson: ahmed,
      amountInput: '2000',
    ),
    setUp: () {
      when(
        () => addTransaction(
          idempotencyKey: any(named: 'idempotencyKey'),
          personId: any(named: 'personId'),
          amount: any(named: 'amount'),
          direction: any(named: 'direction'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => Right(savedTransaction));
    },
    act: (cubit) async {
      final firstTap = cubit.submit();
      final secondTap = cubit.submit(); // fired before the first resolves
      await Future.wait([firstTap, secondTap]);
    },
    verify: (_) {
      verify(
        () => addTransaction(
          idempotencyKey: any(named: 'idempotencyKey'),
          personId: any(named: 'personId'),
          amount: any(named: 'amount'),
          direction: any(named: 'direction'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).called(1);
    },
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'creating a new person surfaces a duplicate-name warning (FR-003)',
    build: buildCubit,
    setUp: () {
      when(
        () => createPerson(
          name: 'Ahmed',
          phoneNumber: null,
          avatarPath: null,
          relationshipTag: null,
          notes: null,
        ),
      ).thenAnswer((_) async => Left(PossibleDuplicateFailure([ahmed])));
    },
    act: (cubit) => cubit.createNewPerson('Ahmed'),
    expect: () => [
      isA<TransactionFormState>()
          .having((s) => s.duplicateMatches, 'duplicateMatches', [ahmed])
          .having((s) => s.pendingPersonName, 'pendingPersonName', 'Ahmed'),
    ],
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'picking the existing duplicate match selects it and clears the warning',
    build: buildCubit,
    seed: () => TransactionFormState(
      idempotencyKey: 'key-1',
      duplicateMatches: [ahmed],
      pendingPersonName: 'Ahmed',
    ),
    act: (cubit) => cubit.pickDuplicateMatch(ahmed),
    expect: () => [
      isA<TransactionFormState>().having(
        (s) => s.selectedPerson,
        'selectedPerson',
        ahmed,
      ),
      isA<TransactionFormState>()
          .having((s) => s.duplicateMatches, 'duplicateMatches', isEmpty)
          .having((s) => s.pendingPersonName, 'pendingPersonName', isNull),
    ],
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'confirming despite the duplicate warning creates a new distinct person',
    build: buildCubit,
    seed: () => TransactionFormState(
      idempotencyKey: 'key-1',
      duplicateMatches: [ahmed],
      pendingPersonName: 'Ahmed 2',
    ),
    setUp: () {
      final newPerson = Person(
        id: 'p2',
        name: 'Ahmed 2',
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => peopleRepository.confirmCreateDespiteDuplicate(
          name: 'Ahmed 2',
          phoneNumber: null,
          avatarPath: null,
          relationshipTag: null,
          notes: null,
        ),
      ).thenAnswer((_) async => Right(newPerson));
    },
    act: (cubit) => cubit.confirmCreateDespitePendingDuplicate(),
    expect: () => [
      isA<TransactionFormState>().having(
        (s) => s.selectedPerson?.id,
        'selectedPerson.id',
        'p2',
      ),
      isA<TransactionFormState>()
          .having((s) => s.duplicateMatches, 'duplicateMatches', isEmpty)
          .having((s) => s.pendingPersonName, 'pendingPersonName', isNull),
    ],
  );
}
