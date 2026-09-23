import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/occasions/domain/usecases/create_occasion.dart';
import 'package:daftary/features/occasions/domain/usecases/edit_occasion.dart';
import 'package:daftary/features/occasions/presentation/cubit/occasion_form_cubit.dart';
import 'package:daftary/features/occasions/presentation/cubit/occasion_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateOccasion extends Mock implements CreateOccasion {}

class MockEditOccasion extends Mock implements EditOccasion {}

/// T021 — the create/edit-occasion form (FR-001/FR-002/FR-012/FR-019).
void main() {
  late MockCreateOccasion createOccasion;
  late MockEditOccasion editOccasion;

  final now = DateTime(2026, 9, 15);

  final wedding = Occasion(
    id: 'o1',
    idempotencyKey: 'key-1',
    name: "Ahmed's Wedding",
    date: now,
    type: OccasionType.wedding,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    createOccasion = MockCreateOccasion();
    editOccasion = MockEditOccasion();
  });

  OccasionFormCubit build() => OccasionFormCubit(createOccasion, editOccasion);

  void stubCreateSuccess() {
    when(
      () => createOccasion(
        idempotencyKey: any(named: 'idempotencyKey'),
        name: any(named: 'name'),
        date: any(named: 'date'),
        type: any(named: 'type'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => Right(wedding));
  }

  test('opens with a fresh idempotency key, so the first save is never '
      'mistaken for a retry of someone else\'s (FR-019)', () {
    final first = build().state.idempotencyKey;
    final second = build().state.idempotencyKey;

    expect(first, isNotEmpty);
    expect(first, isNot(second));
  });

  blocTest<OccasionFormCubit, OccasionFormState>(
    'saves a valid occasion and reports success',
    build: () {
      stubCreateSuccess();
      return build();
    },
    act: (cubit) async {
      cubit.nameChanged("Ahmed's Wedding");
      cubit.typeChanged(OccasionType.wedding);
      cubit.dateChanged(now);
      await cubit.submit();
    },
    verify: (cubit) {
      expect(cubit.state.isSuccess, isTrue);
      expect(cubit.state.savedOccasion, wedding);
      verify(
        () => createOccasion(
          idempotencyKey: any(named: 'idempotencyKey'),
          name: "Ahmed's Wedding",
          date: now,
          type: OccasionType.wedding,
          notes: null,
        ),
      ).called(1);
    },
  );

  blocTest<OccasionFormCubit, OccasionFormState>(
    'rejects an empty-after-trim name without calling the use case (FR-001)',
    build: build,
    act: (cubit) async {
      cubit.nameChanged('   ');
      cubit.typeChanged(OccasionType.wedding);
      await cubit.submit();
    },
    verify: (cubit) {
      expect(cubit.state.nameInvalid, isTrue);
      expect(cubit.state.isSuccess, isFalse);
      verifyZeroInteractions(createOccasion);
    },
  );

  blocTest<OccasionFormCubit, OccasionFormState>(
    'rejects a missing type without calling the use case (FR-002)',
    build: build,
    act: (cubit) async {
      cubit.nameChanged("Ahmed's Wedding");
      await cubit.submit();
    },
    verify: (cubit) {
      expect(cubit.state.typeInvalid, isTrue);
      verifyZeroInteractions(createOccasion);
    },
  );

  blocTest<OccasionFormCubit, OccasionFormState>(
    'a rapid double-tap saves exactly once (FR-019)',
    build: () {
      stubCreateSuccess();
      return build();
    },
    act: (cubit) async {
      cubit.nameChanged("Ahmed's Wedding");
      cubit.typeChanged(OccasionType.wedding);
      // Deliberately not awaited: this is the real shape of a double-tap,
      // where the second call lands before the first has resolved.
      final first = cubit.submit();
      final second = cubit.submit();
      await Future.wait([first, second]);
    },
    verify: (_) {
      verify(
        () => createOccasion(
          idempotencyKey: any(named: 'idempotencyKey'),
          name: any(named: 'name'),
          date: any(named: 'date'),
          type: any(named: 'type'),
          notes: any(named: 'notes'),
        ),
      ).called(1);
    },
  );

  blocTest<OccasionFormCubit, OccasionFormState>(
    'a second deliberate create after a success uses a NEW key, so the '
    'repository does not swallow it as a retry (FR-019)',
    build: () {
      stubCreateSuccess();
      return build();
    },
    act: (cubit) async {
      cubit.nameChanged("Ahmed's Wedding");
      cubit.typeChanged(OccasionType.wedding);
      await cubit.submit();
    },
    verify: (cubit) {
      final keysUsed = verify(
        () => createOccasion(
          idempotencyKey: captureAny(named: 'idempotencyKey'),
          name: any(named: 'name'),
          date: any(named: 'date'),
          type: any(named: 'type'),
          notes: any(named: 'notes'),
        ),
      ).captured;
      expect(cubit.state.idempotencyKey, isNot(keysUsed.single));
    },
  );

  blocTest<OccasionFormCubit, OccasionFormState>(
    'surfaces a repository failure typed, without claiming success',
    build: () {
      when(
        () => createOccasion(
          idempotencyKey: any(named: 'idempotencyKey'),
          name: any(named: 'name'),
          date: any(named: 'date'),
          type: any(named: 'type'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('disk full')));
      return build();
    },
    act: (cubit) async {
      cubit.nameChanged("Ahmed's Wedding");
      cubit.typeChanged(OccasionType.wedding);
      await cubit.submit();
    },
    verify: (cubit) {
      expect(cubit.state.status, OccasionFormStatus.failure);
      expect(cubit.state.failure, isA<CacheFailure>());
      expect(cubit.state.isSuccess, isFalse);
    },
  );

  group('edit mode (FR-012)', () {
    blocTest<OccasionFormCubit, OccasionFormState>(
      'prefills from the occasion and routes the save to EditOccasion',
      build: () {
        when(
          () => editOccasion(
            occasionId: any(named: 'occasionId'),
            name: any(named: 'name'),
            date: any(named: 'date'),
            type: any(named: 'type'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer((_) async => Right(wedding));
        return build();
      },
      act: (cubit) async {
        cubit.loadForEdit(wedding);
        cubit.nameChanged("Ahmed & Sara's Wedding");
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.isEditMode, isTrue);
        expect(cubit.state.editingOccasionId, 'o1');
        verify(
          () => editOccasion(
            occasionId: 'o1',
            name: "Ahmed & Sara's Wedding",
            date: now,
            type: OccasionType.wedding,
            notes: null,
          ),
        ).called(1);
        verifyZeroInteractions(createOccasion);
      },
    );

    blocTest<OccasionFormCubit, OccasionFormState>(
      'a future date is accepted — an occasion may be recorded before it '
      'happens (spec Edge Cases)',
      build: () {
        stubCreateSuccess();
        return build();
      },
      act: (cubit) async {
        final future = DateTime.now().add(const Duration(days: 60));
        cubit.nameChanged('Cousin wedding');
        cubit.typeChanged(OccasionType.wedding);
        cubit.dateChanged(future);
        await cubit.submit();
        expect(cubit.state.isSuccess, isTrue);
      },
    );
  });
}
