import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
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

import '../../helpers/currency_test_doubles.dart';
import '../../helpers/duplicate_test_doubles.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

class MockCreatePerson extends Mock implements CreatePerson {}

class MockAddTransaction extends Mock implements AddTransaction {}

class MockEditTransaction extends Mock implements EditTransaction {}

void main() {
  late MockPeopleRepository peopleRepository;
  late MockCreatePerson createPerson;
  late MockAddTransaction addTransaction;
  late MockEditTransaction editTransaction;
  late MockFindPossibleDuplicate findPossibleDuplicate;

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
    amount: const Money.egp(200000),
    direction: TransactionDirection.given,
    kind: TransactionKind.initialExchange,
    date: now,
    createdAt: now,
  );

  setUpAll(() {
    registerFallbackValue(const Money.egp(0));
    registerFallbackValue(TransactionDirection.given);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    peopleRepository = MockPeopleRepository();
    createPerson = MockCreatePerson();
    addTransaction = MockAddTransaction();
    editTransaction = MockEditTransaction();
    findPossibleDuplicate = findPossibleDuplicateReturning();
  });

  TransactionFormCubit buildCubit() => TransactionFormCubit(
    peopleRepository,
    createPerson,
    addTransaction,
    editTransaction,
    getPrimaryCurrencyReturning(),
    findPossibleDuplicate,
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

  group('currency (018)', () {
    TransactionFormCubit buildWithPrimary(Currency primary) =>
        TransactionFormCubit(
          peopleRepository,
          createPerson,
          addTransaction,
          editTransaction,
          getPrimaryCurrencyReturning(primary),
          findPossibleDuplicate,
        );

    void stubAdd() {
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
    }

    blocTest<TransactionFormCubit, TransactionFormState>(
      'loadDefaultCurrency defaults the picker to the primary currency, and '
      'submit parses the amount in it (FR-003)',
      build: () => buildWithPrimary(Currency.usd),
      seed: () => TransactionFormState(
        idempotencyKey: 'key-1',
        selectedPerson: ahmed,
        amountInput: '12.5',
      ),
      setUp: stubAdd,
      act: (cubit) async {
        await cubit.loadDefaultCurrency();
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.currency, Currency.usd);
        verify(
          () => addTransaction(
            idempotencyKey: 'key-1',
            personId: 'p1',
            amount: const Money.fromMinorUnits(1250, Currency.usd),
            direction: any(named: 'direction'),
            date: any(named: 'date'),
            note: any(named: 'note'),
          ),
        ).called(1);
      },
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'a currency the user picked is used and never overwritten by a '
      'late-arriving primary default',
      build: () => buildWithPrimary(Currency.usd),
      seed: () => TransactionFormState(
        idempotencyKey: 'key-1',
        selectedPerson: ahmed,
        amountInput: '3',
      ),
      setUp: stubAdd,
      act: (cubit) async {
        cubit.currencyChanged(Currency.eur);
        await cubit.loadDefaultCurrency();
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.currency, Currency.eur);
        verify(
          () => addTransaction(
            idempotencyKey: any(named: 'idempotencyKey'),
            personId: any(named: 'personId'),
            amount: const Money.fromMinorUnits(300, Currency.eur),
            direction: any(named: 'direction'),
            date: any(named: 'date'),
            note: any(named: 'note'),
          ),
        ).called(1);
      },
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'editing keeps the record\'s own currency, even when it is not primary',
      build: () => buildWithPrimary(Currency.egp),
      act: (cubit) async {
        cubit.loadForEdit(
          MoneyTransaction(
            id: 't1',
            idempotencyKey: 'k',
            personId: 'p1',
            amount: const Money.fromMinorUnits(1999, Currency.gbp),
            direction: TransactionDirection.given,
            kind: TransactionKind.initialExchange,
            date: now,
            createdAt: now,
          ),
          ahmed,
        );
        await cubit.loadDefaultCurrency();
      },
      verify: (cubit) {
        expect(cubit.state.currency, Currency.gbp);
        expect(cubit.state.amountInput, '19.99');
      },
    );
  });

  group('E3 currency change while editing', () {
    final existing = MoneyTransaction(
      id: 't1',
      idempotencyKey: 'k',
      personId: 'p1',
      amount: const Money.egp(150000),
      direction: TransactionDirection.given,
      kind: TransactionKind.initialExchange,
      date: now,
      createdAt: now,
    );

    TransactionFormCubit editing() =>
        buildCubit()..loadForEdit(existing, ahmed);

    test('edit mode: picking another currency only sets pendingCurrency', () {
      final cubit = editing()..currencyChanged(Currency.usd);

      expect(cubit.state.pendingCurrency, Currency.usd);
      expect(cubit.state.currency, Currency.egp);
      cubit.close();
    });

    test('edit mode: picking the current currency sets nothing', () {
      final cubit = editing()..currencyChanged(Currency.egp);

      expect(cubit.state.pendingCurrency, isNull);
      cubit.close();
    });

    test('confirmCurrencyChange applies it and clears the pending one', () {
      final cubit = editing()
        ..currencyChanged(Currency.usd)
        ..confirmCurrencyChange();

      expect(cubit.state.currency, Currency.usd);
      expect(cubit.state.pendingCurrency, isNull);
      expect(cubit.state.amountInput, '1,500.00');
      cubit.close();
    });

    test('cancelCurrencyChange clears it and keeps the original', () {
      final cubit = editing()
        ..currencyChanged(Currency.usd)
        ..cancelCurrencyChange();

      expect(cubit.state.currency, Currency.egp);
      expect(cubit.state.pendingCurrency, isNull);
      cubit.close();
    });

    final small = MoneyTransaction(
      id: 't1',
      idempotencyKey: 'k',
      personId: 'p1',
      amount: const Money.egp(15050),
      direction: TransactionDirection.given,
      kind: TransactionKind.initialExchange,
      date: now,
      createdAt: now,
    );

    Future<Money> savedAfter(
      TransactionFormCubit cubit,
      void Function(TransactionFormCubit) steps,
    ) async {
      when(
        () => editTransaction(
          transactionId: any(named: 'transactionId'),
          amount: any(named: 'amount'),
          direction: any(named: 'direction'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => Right(savedTransaction));
      steps(cubit);
      await cubit.submit();
      return verify(
            () => editTransaction(
              transactionId: any(named: 'transactionId'),
              amount: captureAny(named: 'amount'),
              direction: any(named: 'direction'),
              date: any(named: 'date'),
              note: any(named: 'note'),
            ),
          ).captured.single
          as Money;
    }

    test(
      'edit 150.50 EGP, pick USD, confirm, submit saves 150.50 USD',
      () async {
        final cubit = buildCubit()..loadForEdit(small, ahmed);

        final saved = await savedAfter(
          cubit,
          (c) => c
            ..currencyChanged(Currency.usd)
            ..confirmCurrencyChange(),
        );

        expect(saved, const Money.fromMinorUnits(15050, Currency.usd));
        await cubit.close();
      },
    );

    test('submit while a currency is pending uses the original currency, '
        'never the pending one', () async {
      final cubit = buildCubit()..loadForEdit(small, ahmed);

      final saved = await savedAfter(
        cubit,
        (c) => c.currencyChanged(Currency.usd),
      );

      expect(saved, const Money.egp(15050));
      await cubit.close();
    });

    test('create mode: the currency is applied immediately', () {
      final cubit = buildCubit()..currencyChanged(Currency.usd);

      expect(cubit.state.currency, Currency.usd);
      expect(cubit.state.pendingCurrency, isNull);
      cubit.close();
    });
  });

  group('C4 possible duplicate', () {
    final match = MoneyTransaction(
      id: 'old',
      idempotencyKey: 'old-key',
      personId: 'p1',
      amount: const Money.egp(20000),
      direction: TransactionDirection.given,
      kind: TransactionKind.initialExchange,
      date: now,
      createdAt: now,
    );

    TransactionFormCubit ready() {
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
      return buildCubit()
        ..selectExistingPerson(ahmed)
        ..amountChanged('200');
    }

    void verifyAdds(int times, {String? key}) {
      Future<Object?> call() => addTransaction(
        idempotencyKey: key ?? any(named: 'idempotencyKey'),
        personId: any(named: 'personId'),
        amount: any(named: 'amount'),
        direction: any(named: 'direction'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      );
      if (times == 0) {
        verifyNever(call);
      } else {
        verify(call).called(times);
      }
    }

    test('a match in create mode emits possibleDuplicate and saves '
        'nothing yet', () async {
      stubFindPossibleDuplicate(findPossibleDuplicate, match);
      final cubit = ready();

      await cubit.submit();

      expect(cubit.state.possibleDuplicate, match);
      expect(cubit.state.isSubmitting, isFalse);
      verifyAdds(0);
      await cubit.close();
    });

    test('confirmDuplicate saves exactly one row with the same '
        'idempotency key', () async {
      stubFindPossibleDuplicate(findPossibleDuplicate, match);
      final cubit = ready();
      final key = cubit.state.idempotencyKey;

      await cubit.submit();
      await cubit.confirmDuplicate();

      expect(cubit.state.possibleDuplicate, isNull);
      expect(cubit.state.isSuccess, isTrue);
      verifyAdds(1, key: key);
      await cubit.close();
    });

    test('cancelDuplicate clears the prompt and saves nothing, and the '
        'form can be saved again (never blocked)', () async {
      stubFindPossibleDuplicate(findPossibleDuplicate, match);
      final cubit = ready();

      await cubit.submit();
      cubit.cancelDuplicate();

      expect(cubit.state.possibleDuplicate, isNull);
      verifyAdds(0);

      await cubit.submit();
      expect(cubit.state.possibleDuplicate, match);
      await cubit.confirmDuplicate();
      verifyAdds(1);
      await cubit.close();
    });

    test('no match saves straight away', () async {
      final cubit = ready();

      await cubit.submit();

      expect(cubit.state.isSuccess, isTrue);
      verifyAdds(1);
      await cubit.close();
    });

    test('a failed lookup never blocks the save', () async {
      when(
        () => findPossibleDuplicate(
          personId: any(named: 'personId'),
          amount: any(named: 'amount'),
          direction: any(named: 'direction'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('boom')));
      final cubit = ready();

      await cubit.submit();

      expect(cubit.state.isSuccess, isTrue);
      verifyAdds(1);
      await cubit.close();
    });

    test('CHK100: a rapid double tap still records exactly one row', () async {
      final cubit = ready();

      await Future.wait([cubit.submit(), cubit.submit()]);

      verifyAdds(1);
      await cubit.close();
    });

    test(
      'a rapid double tap on a duplicate asks once and saves nothing',
      () async {
        stubFindPossibleDuplicate(findPossibleDuplicate, match);
        final cubit = ready();

        await Future.wait([cubit.submit(), cubit.submit()]);
        await cubit.confirmDuplicate();
        await cubit.confirmDuplicate();

        verifyAdds(1);
        await cubit.close();
      },
    );

    test('edit mode never looks for a duplicate', () async {
      stubFindPossibleDuplicate(findPossibleDuplicate, match);
      when(
        () => editTransaction(
          transactionId: any(named: 'transactionId'),
          amount: any(named: 'amount'),
          direction: any(named: 'direction'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => Right(savedTransaction));
      final cubit = buildCubit()..loadForEdit(match, ahmed);

      await cubit.submit();

      verifyNever(
        () => findPossibleDuplicate(
          personId: any(named: 'personId'),
          amount: any(named: 'amount'),
          direction: any(named: 'direction'),
          date: any(named: 'date'),
        ),
      );
      expect(cubit.state.isSuccess, isTrue);
      await cubit.close();
    });
  });
}
