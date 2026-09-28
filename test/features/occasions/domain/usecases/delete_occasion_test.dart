import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_detail.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_failures.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_participant_row.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_summary.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/occasions/domain/repositories/occasions_repository.dart';
import 'package:daftary/features/occasions/domain/usecases/delete_occasion.dart';
import 'package:daftary/features/occasions/domain/usecases/get_occasion_detail.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOccasionsRepository extends Mock implements OccasionsRepository {}

void main() {
  late MockOccasionsRepository repository;
  late DeleteOccasion deleteOccasion;
  late GetOccasionDetail getOccasionDetail;

  OccasionParticipantRow buildRow(String id, String personId) {
    return OccasionParticipantRow(
      transactionId: id,
      personId: personId,
      personName: 'Person $personId',
      amount: const Money.egp(50000),
      direction: TransactionDirection.received,
      countsTowardBalance: true,
      personOverallStatus: RelationshipStatus.youOweThem,
    );
  }

  OccasionDetail buildDetail(List<OccasionParticipantRow> rows) {
    return OccasionDetail(
      occasion: Occasion(
        id: 'o1',
        idempotencyKey: 'key-1',
        name: 'Ahmed wedding',
        date: DateTime(2026, 3, 14),
        type: OccasionType.wedding,
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1),
      ),
      summary: OccasionSummary(
        occasionId: 'o1',
        totalReceived: const Money.egp(150000),
        totalGiven: Money.zero(Currency.egp),
        participantCount: rows.map((row) => row.personId).toSet().length,
      ),
      participants: rows,
      attachments: const [],
    );
  }

  setUp(() {
    repository = MockOccasionsRepository();
    deleteOccasion = DeleteOccasion(repository);
    getOccasionDetail = GetOccasionDetail(repository);
  });

  test('delegates the whole cascade to the repository in one call '
      '(FR-013)', () async {
    when(
      () => repository.deleteOccasion(any()),
    ).thenAnswer((_) async => const Right(unit));

    final result = await deleteOccasion('o1');

    expect(result.isRight(), isTrue);
    verify(() => repository.deleteOccasion('o1')).called(1);
    // No per-contribution removal attempted here: the use case never walks
    // the participant list calling removeParticipantContribution, because a
    // failure part-way through that loop would leave the occasion behind
    // with some of its money already gone.
    verifyNever(() => repository.removeParticipantContribution(any()));
    verifyNoMoreInteractions(repository);
  });

  test('does not read the detail itself before deleting — the count for '
      'the confirmation is the caller\'s job (FR-013)', () async {
    when(
      () => repository.deleteOccasion(any()),
    ).thenAnswer((_) async => const Right(unit));

    await deleteOccasion('o1');

    verifyNever(() => repository.getOccasionDetail(any()));
  });

  test('the confirmation count comes from GetOccasionDetail before the '
      'destructive call (FR-013)', () async {
    when(() => repository.getOccasionDetail(any())).thenAnswer(
      (_) async => Right(
        buildDetail([
          buildRow('t1', 'p1'),
          buildRow('t2', 'p2'),
          buildRow('t3', 'p3'),
        ]),
      ),
    );
    when(
      () => repository.deleteOccasion(any()),
    ).thenAnswer((_) async => const Right(unit));

    final detail = (await getOccasionDetail('o1')).toNullable()!;
    final affected = detail.summary.participantCount;
    // The caller shows "3 contributions will be removed", then confirms.
    final result = await deleteOccasion('o1');

    expect(affected, 3);
    expect(result.isRight(), isTrue);
    verifyInOrder([
      () => repository.getOccasionDetail('o1'),
      () => repository.deleteOccasion('o1'),
    ]);
  });

  test('surfaces a failed cascade typed, without any partial cleanup of '
      'its own (FR-013)', () async {
    when(() => repository.deleteOccasion(any())).thenAnswer(
      (_) async => const Left(CacheFailure('Transaction rolled back')),
    );

    final result = await deleteOccasion('o1');

    expect(result.getLeft().toNullable(), isA<CacheFailure>());
    // The whole cascade is one DB transaction, so a failure leaves nothing
    // half-removed and there is nothing for this layer to undo.
    verifyNever(() => repository.removeParticipantContribution(any()));
    verify(() => repository.deleteOccasion('o1')).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('surfaces an already-deleted occasion as an '
      'OccasionNotFoundFailure', () async {
    when(() => repository.deleteOccasion(any())).thenAnswer(
      (_) async => const Left(OccasionNotFoundFailure('Occasion is gone')),
    );

    final result = await deleteOccasion('gone');

    expect(result.getLeft().toNullable(), isA<OccasionNotFoundFailure>());
    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });

  test('deleting an occasion with no contributions is still a single '
      'cascade call (FR-013)', () async {
    when(
      () => repository.getOccasionDetail(any()),
    ).thenAnswer((_) async => Right(buildDetail(const [])));
    when(
      () => repository.deleteOccasion(any()),
    ).thenAnswer((_) async => const Right(unit));

    final detail = (await getOccasionDetail('o1')).toNullable()!;
    final result = await deleteOccasion('o1');

    expect(detail.summary.participantCount, 0);
    expect(result.isRight(), isTrue);
    verify(() => repository.deleteOccasion('o1')).called(1);
  });
}
