import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/occasions/domain/usecases/add_participant_contribution.dart';
import 'package:daftary/features/occasions/domain/usecases/edit_participant_contribution.dart';
import 'package:daftary/features/occasions/presentation/cubit/participant_form_cubit.dart';
import 'package:daftary/features/occasions/presentation/cubit/participant_form_state.dart';
import 'package:daftary/features/people/domain/entities/people_failures.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/create_person.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

class MockCreatePerson extends Mock implements CreatePerson {}

class MockAddParticipantContribution extends Mock
    implements AddParticipantContribution {}

class MockEditParticipantContribution extends Mock
    implements EditParticipantContribution {}

/// T022 — the add/edit-contribution form (FR-004/FR-010/FR-018/FR-019 and
/// FR-022's Arabic-Indic numeral input).
void main() {
  late MockPeopleRepository peopleRepository;
  late MockCreatePerson createPerson;
  late MockAddParticipantContribution addContribution;
  late MockEditParticipantContribution editContribution;
  late EgpFormatter egpFormatter;

  final now = DateTime(2026, 9, 15);
  const occasionId = 'o1';

  final ahmed = Person(
    id: 'p1',
    name: 'Ahmed',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );
  final ahmedHassan = Person(
    id: 'p2',
    name: 'Ahmed Hassan',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );

  final saved = MoneyTransaction(
    id: 't1',
    idempotencyKey: 'key-1',
    personId: 'p1',
    amount: Money.fromMinorUnits(200000),
    direction: TransactionDirection.received,
    kind: TransactionKind.occasionContribution,
    occasionId: occasionId,
    date: now,
    createdAt: now,
  );

  setUpAll(() {
    // `any(named: 'amount')`/`any(named: 'date')` need a fallback instance
    // for each non-primitive type mocktail cannot construct itself.
    registerFallbackValue(Money.zero());
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(TransactionDirection.received);
  });

  setUp(() {
    peopleRepository = MockPeopleRepository();
    createPerson = MockCreatePerson();
    addContribution = MockAddParticipantContribution();
    editContribution = MockEditParticipantContribution();
    egpFormatter = EgpFormatter();
  });

  ParticipantFormCubit build() => ParticipantFormCubit(
    peopleRepository,
    createPerson,
    addContribution,
    editContribution,
    egpFormatter,
  );

  void stubAddSuccess() {
    when(
      () => addContribution(
        idempotencyKey: any(named: 'idempotencyKey'),
        occasionId: any(named: 'occasionId'),
        personId: any(named: 'personId'),
        amount: any(named: 'amount'),
        direction: any(named: 'direction'),
        date: any(named: 'date'),
        countsTowardBalance: any(named: 'countsTowardBalance'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Right(saved));
  }

  blocTest<ParticipantFormCubit, ParticipantFormState>(
    'records a contribution against the selected person',
    build: () {
      stubAddSuccess();
      return build();
    },
    act: (cubit) async {
      cubit.initialize(
        occasionId: occasionId,
        occasionType: OccasionType.wedding,
      );
      cubit.selectExistingPerson(ahmed);
      cubit.amountChanged('2000');
      cubit.dateChanged(now);
      await cubit.submit();
    },
    verify: (cubit) {
      expect(cubit.state.isSuccess, isTrue);
      verify(
        () => addContribution(
          idempotencyKey: any(named: 'idempotencyKey'),
          occasionId: occasionId,
          personId: 'p1',
          amount: Money.fromMinorUnits(200000),
          direction: TransactionDirection.received,
          date: now,
          countsTowardBalance: true,
          note: null,
        ),
      ).called(1);
    },
  );

  blocTest<ParticipantFormCubit, ParticipantFormState>(
    'rejects a zero amount without calling the use case (FR-004)',
    build: build,
    act: (cubit) async {
      cubit.initialize(
        occasionId: occasionId,
        occasionType: OccasionType.wedding,
      );
      cubit.selectExistingPerson(ahmed);
      cubit.amountChanged('0');
      await cubit.submit();
    },
    verify: (cubit) {
      expect(cubit.state.amountInvalid, isTrue);
      verifyZeroInteractions(addContribution);
    },
  );

  blocTest<ParticipantFormCubit, ParticipantFormState>(
    'rejects a negative amount without calling the use case (FR-004)',
    build: build,
    act: (cubit) async {
      cubit.initialize(
        occasionId: occasionId,
        occasionType: OccasionType.wedding,
      );
      cubit.selectExistingPerson(ahmed);
      cubit.amountChanged('-500');
      await cubit.submit();
    },
    verify: (cubit) {
      expect(cubit.state.amountInvalid, isTrue);
      verifyZeroInteractions(addContribution);
    },
  );

  blocTest<ParticipantFormCubit, ParticipantFormState>(
    'blocks a save with no person selected rather than inventing one',
    build: build,
    act: (cubit) async {
      cubit.initialize(
        occasionId: occasionId,
        occasionType: OccasionType.wedding,
      );
      cubit.amountChanged('2000');
      await cubit.submit();
    },
    verify: (cubit) {
      expect(cubit.state.personSelectionRequired, isTrue);
      verifyZeroInteractions(addContribution);
    },
  );

  blocTest<ParticipantFormCubit, ParticipantFormState>(
    'accepts Arabic-Indic digits as the same amount as Western ones '
    '(FR-022)',
    build: () {
      stubAddSuccess();
      return build();
    },
    act: (cubit) async {
      cubit.initialize(
        occasionId: occasionId,
        occasionType: OccasionType.wedding,
      );
      cubit.selectExistingPerson(ahmed);
      cubit.amountChanged('٢٠٠٠');
      await cubit.submit();
    },
    verify: (_) {
      verify(
        () => addContribution(
          idempotencyKey: any(named: 'idempotencyKey'),
          occasionId: any(named: 'occasionId'),
          personId: any(named: 'personId'),
          amount: Money.fromMinorUnits(200000),
          direction: any(named: 'direction'),
          date: any(named: 'date'),
          countsTowardBalance: any(named: 'countsTowardBalance'),
          note: any(named: 'note'),
        ),
      ).called(1);
    },
  );

  group('the condolence balance default (FR-018)', () {
    test('a condolence occasion defaults the toggle off, every other type '
        'defaults it on', () {
      expect(
        ParticipantFormCubit.defaultCountsTowardBalance(
          OccasionType.condolence,
        ),
        isFalse,
      );
      for (final type in OccasionType.standardValues.where(
        (t) => t != OccasionType.condolence,
      )) {
        expect(
          ParticipantFormCubit.defaultCountsTowardBalance(type),
          isTrue,
          reason: '$type is an ordinary reciprocal exchange',
        );
      }
    });

    blocTest<ParticipantFormCubit, ParticipantFormState>(
      'saves a condolence contribution as not counting toward the balance',
      build: () {
        stubAddSuccess();
        return build();
      },
      act: (cubit) async {
        cubit.initialize(
          occasionId: occasionId,
          occasionType: OccasionType.condolence,
        );
        expect(cubit.state.countsTowardBalance, isFalse);
        cubit.selectExistingPerson(ahmed);
        cubit.amountChanged('500');
        await cubit.submit();
      },
      verify: (_) {
        verify(
          () => addContribution(
            idempotencyKey: any(named: 'idempotencyKey'),
            occasionId: any(named: 'occasionId'),
            personId: any(named: 'personId'),
            amount: any(named: 'amount'),
            direction: any(named: 'direction'),
            date: any(named: 'date'),
            countsTowardBalance: false,
            note: any(named: 'note'),
          ),
        ).called(1);
      },
    );

    blocTest<ParticipantFormCubit, ParticipantFormState>(
      'an explicit override wins over the default',
      build: () {
        stubAddSuccess();
        return build();
      },
      act: (cubit) async {
        cubit.initialize(
          occasionId: occasionId,
          occasionType: OccasionType.condolence,
        );
        cubit.selectExistingPerson(ahmed);
        cubit.amountChanged('500');
        cubit.countsTowardBalanceChanged(true);
        await cubit.submit();
      },
      verify: (_) {
        verify(
          () => addContribution(
            idempotencyKey: any(named: 'idempotencyKey'),
            occasionId: any(named: 'occasionId'),
            personId: any(named: 'personId'),
            amount: any(named: 'amount'),
            direction: any(named: 'direction'),
            date: any(named: 'date'),
            countsTowardBalance: true,
            note: any(named: 'note'),
          ),
        ).called(1);
      },
    );
  });

  group('inline person creation reuses 001\'s duplicate flow', () {
    blocTest<ParticipantFormCubit, ParticipantFormState>(
      'a possible duplicate surfaces the warning instead of inserting',
      build: () {
        when(
          () => createPerson(
            name: any(named: 'name'),
            phoneNumber: any(named: 'phoneNumber'),
            avatarPath: any(named: 'avatarPath'),
            relationshipTag: any(named: 'relationshipTag'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer(
          (_) async => Left(PossibleDuplicateFailure([ahmedHassan])),
        );
        return build();
      },
      act: (cubit) async {
        cubit.initialize(
          occasionId: occasionId,
          occasionType: OccasionType.wedding,
        );
        await cubit.createNewPerson('Ahmed Hasan');
      },
      verify: (cubit) {
        expect(cubit.state.duplicateMatches, [ahmedHassan]);
        expect(cubit.state.pendingPersonName, 'Ahmed Hasan');
        // Nothing was inserted, and nothing was selected behind the
        // warning's back.
        expect(cubit.state.selectedPerson, isNull);
      },
    );

    blocTest<ParticipantFormCubit, ParticipantFormState>(
      'picking the existing match selects it and dismisses the warning',
      build: () {
        when(
          () => createPerson(
            name: any(named: 'name'),
            phoneNumber: any(named: 'phoneNumber'),
            avatarPath: any(named: 'avatarPath'),
            relationshipTag: any(named: 'relationshipTag'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer(
          (_) async => Left(PossibleDuplicateFailure([ahmedHassan])),
        );
        return build();
      },
      act: (cubit) async {
        cubit.initialize(
          occasionId: occasionId,
          occasionType: OccasionType.wedding,
        );
        await cubit.createNewPerson('Ahmed Hasan');
        cubit.pickDuplicateMatch(ahmedHassan);
      },
      verify: (cubit) {
        expect(cubit.state.selectedPerson, ahmedHassan);
        expect(cubit.state.duplicateMatches, isEmpty);
      },
    );

    blocTest<ParticipantFormCubit, ParticipantFormState>(
      'a clean name is created and selected straight away',
      build: () {
        when(
          () => createPerson(
            name: any(named: 'name'),
            phoneNumber: any(named: 'phoneNumber'),
            avatarPath: any(named: 'avatarPath'),
            relationshipTag: any(named: 'relationshipTag'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer((_) async => Right(ahmed));
        return build();
      },
      act: (cubit) async {
        cubit.initialize(
          occasionId: occasionId,
          occasionType: OccasionType.wedding,
        );
        await cubit.createNewPerson('Ahmed');
      },
      verify: (cubit) => expect(cubit.state.selectedPerson, ahmed),
    );
  });

  blocTest<ParticipantFormCubit, ParticipantFormState>(
    'a rapid double-tap records exactly one contribution (FR-019)',
    build: () {
      stubAddSuccess();
      return build();
    },
    act: (cubit) async {
      cubit.initialize(
        occasionId: occasionId,
        occasionType: OccasionType.wedding,
      );
      cubit.selectExistingPerson(ahmed);
      cubit.amountChanged('2000');
      final first = cubit.submit();
      final second = cubit.submit();
      await Future.wait([first, second]);
    },
    verify: (_) {
      verify(
        () => addContribution(
          idempotencyKey: any(named: 'idempotencyKey'),
          occasionId: any(named: 'occasionId'),
          personId: any(named: 'personId'),
          amount: any(named: 'amount'),
          direction: any(named: 'direction'),
          date: any(named: 'date'),
          countsTowardBalance: any(named: 'countsTowardBalance'),
          note: any(named: 'note'),
        ),
      ).called(1);
    },
  );

  blocTest<ParticipantFormCubit, ParticipantFormState>(
    'a second contribution from the same open form gets a new key — a '
    'top-up is not a retry (spec Edge Cases)',
    build: () {
      stubAddSuccess();
      return build();
    },
    act: (cubit) async {
      cubit.initialize(
        occasionId: occasionId,
        occasionType: OccasionType.wedding,
      );
      cubit.selectExistingPerson(ahmed);
      cubit.amountChanged('2000');
      await cubit.submit();
    },
    verify: (cubit) {
      final used = verify(
        () => addContribution(
          idempotencyKey: captureAny(named: 'idempotencyKey'),
          occasionId: any(named: 'occasionId'),
          personId: any(named: 'personId'),
          amount: any(named: 'amount'),
          direction: any(named: 'direction'),
          date: any(named: 'date'),
          countsTowardBalance: any(named: 'countsTowardBalance'),
          note: any(named: 'note'),
        ),
      ).captured.single;
      expect(cubit.state.idempotencyKey, isNot(used));
    },
  );

  blocTest<ParticipantFormCubit, ParticipantFormState>(
    'edit mode routes to EditParticipantContribution and keeps the flag the '
    'row was saved with, never recomputing it (FR-010, Decision 3)',
    build: () {
      when(
        () => editContribution(
          transactionId: any(named: 'transactionId'),
          amount: any(named: 'amount'),
          direction: any(named: 'direction'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => Right(saved));
      return build();
    },
    act: (cubit) async {
      cubit.loadForEdit(
        // Saved under a wedding as non-counting by explicit override; the
        // form must carry that forward rather than re-deriving `true`.
        transaction: MoneyTransaction(
          id: 't1',
          idempotencyKey: 'key-1',
          personId: 'p1',
          amount: Money.fromMinorUnits(200000),
          direction: TransactionDirection.received,
          kind: TransactionKind.occasionContribution,
          occasionId: occasionId,
          countsTowardBalance: false,
          date: now,
          createdAt: now,
        ),
        person: ahmed,
        occasionType: OccasionType.wedding,
      );
      expect(cubit.state.countsTowardBalance, isFalse);
      cubit.amountChanged('2200');
      await cubit.submit();
    },
    verify: (cubit) {
      expect(cubit.state.isEditMode, isTrue);
      verify(
        () => editContribution(
          transactionId: 't1',
          amount: Money.fromMinorUnits(220000),
          direction: TransactionDirection.received,
          date: now,
          note: null,
        ),
      ).called(1);
      verifyZeroInteractions(addContribution);
    },
  );

  blocTest<ParticipantFormCubit, ParticipantFormState>(
    'surfaces a repository failure typed, without claiming success',
    build: () {
      when(
        () => addContribution(
          idempotencyKey: any(named: 'idempotencyKey'),
          occasionId: any(named: 'occasionId'),
          personId: any(named: 'personId'),
          amount: any(named: 'amount'),
          direction: any(named: 'direction'),
          date: any(named: 'date'),
          countsTowardBalance: any(named: 'countsTowardBalance'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('disk full')));
      return build();
    },
    act: (cubit) async {
      cubit.initialize(
        occasionId: occasionId,
        occasionType: OccasionType.wedding,
      );
      cubit.selectExistingPerson(ahmed);
      cubit.amountChanged('2000');
      await cubit.submit();
    },
    verify: (cubit) {
      expect(cubit.state.status, ParticipantFormStatus.failure);
      expect(cubit.state.failure, isA<CacheFailure>());
    },
  );
}
