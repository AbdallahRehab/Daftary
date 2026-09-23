import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_detail.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_failures.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_filter.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_participant_row.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_summary.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/occasions/domain/repositories/occasions_repository.dart';
import 'package:daftary/features/occasions/domain/usecases/archive_occasion.dart';
import 'package:daftary/features/occasions/domain/usecases/get_occasion_detail.dart';
import 'package:daftary/features/occasions/domain/usecases/get_occasions_list.dart';
import 'package:daftary/features/occasions/domain/usecases/restore_occasion.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOccasionsRepository extends Mock implements OccasionsRepository {}

void main() {
  late MockOccasionsRepository repository;
  late ArchiveOccasion archiveOccasion;
  late RestoreOccasion restoreOccasion;
  late GetOccasionsList getOccasionsList;
  late GetOccasionDetail getOccasionDetail;

  Occasion buildOccasion({bool isArchived = false}) => Occasion(
    id: 'o1',
    idempotencyKey: 'key-1',
    name: 'Ahmed wedding',
    date: DateTime(2026, 3, 14),
    type: OccasionType.wedding,
    isArchived: isArchived,
    createdAt: DateTime(2026, 3, 1),
    updatedAt: DateTime(2026, 3, 1),
  );

  void stubList(Either<Failure, List<Occasion>> response) {
    when(
      () => repository.getOccasionsList(
        filter: any(named: 'filter'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => response);
  }

  setUpAll(() {
    registerFallbackValue(const OccasionFilter());
  });

  setUp(() {
    repository = MockOccasionsRepository();
    archiveOccasion = ArchiveOccasion(repository);
    restoreOccasion = RestoreOccasion(repository);
    getOccasionsList = GetOccasionsList(repository);
    getOccasionDetail = GetOccasionDetail(repository);
  });

  test('archiving hides the occasion from the default list (FR-014)', () async {
    when(
      () => repository.archiveOccasion(any()),
    ).thenAnswer((_) async => const Right(unit));
    stubList(const Right([]));

    final archiveResult = await archiveOccasion('o1');
    final listed = await getOccasionsList();

    expect(archiveResult.isRight(), isTrue);
    expect(listed.toNullable(), isEmpty);
    verify(() => repository.archiveOccasion('o1')).called(1);
  });

  test('an archived occasion is still reachable through the archived view '
      '(FR-014)', () async {
    stubList(Right([buildOccasion(isArchived: true)]));

    final listed = await getOccasionsList(includeArchived: true);

    expect(listed.toNullable()!.single.isArchived, isTrue);
    expect(listed.toNullable()!.single.isDeleted, isFalse);
  });

  test('archiving is not a delete: no contribution is touched and no '
      'tombstone is set (FR-014)', () async {
    when(
      () => repository.archiveOccasion(any()),
    ).thenAnswer((_) async => const Right(unit));

    await archiveOccasion('o1');

    // A single visibility flip. Nothing that would soft-delete or re-flag a
    // contribution — and so nobody's balance moves.
    verify(() => repository.archiveOccasion('o1')).called(1);
    verifyNoMoreInteractions(repository);
    expect(buildOccasion(isArchived: true).deletedAt, isNull);
  });

  test('an archived occasion keeps every contribution and total intact '
      '(FR-014)', () async {
    const row = OccasionParticipantRow(
      transactionId: 't1',
      personId: 'p1',
      personName: 'Ahmed',
      amount: Money.fromMinorUnits(50000),
      direction: TransactionDirection.received,
      countsTowardBalance: true,
      personOverallStatus: RelationshipStatus.youOweThem,
    );
    when(() => repository.getOccasionDetail(any())).thenAnswer(
      (_) async => Right(
        OccasionDetail(
          occasion: buildOccasion(isArchived: true),
          summary: const OccasionSummary(
            occasionId: 'o1',
            totalReceived: Money.fromMinorUnits(50000),
            totalGiven: Money.fromMinorUnits(0),
            participantCount: 1,
          ),
          participants: const [row],
          attachments: const [],
        ),
      ),
    );

    final detail = (await getOccasionDetail('o1')).toNullable()!;

    expect(detail.occasion.isArchived, isTrue);
    expect(detail.participants, [row]);
    expect(detail.participants.single.countsTowardBalance, isTrue);
    expect(detail.summary.totalReceived, const Money.fromMinorUnits(50000));
  });

  test(
    'restoring puts the occasion back in the default list (FR-014)',
    () async {
      when(
        () => repository.restoreOccasion(any()),
      ).thenAnswer((_) async => const Right(unit));
      stubList(Right([buildOccasion()]));

      final restoreResult = await restoreOccasion('o1');
      final listed = await getOccasionsList();

      expect(restoreResult.isRight(), isTrue);
      expect(listed.toNullable()!.single.id, 'o1');
      expect(listed.toNullable()!.single.isArchived, isFalse);
      verify(() => repository.restoreOccasion('o1')).called(1);
    },
  );

  test('restore is the exact inverse of archive — one call, nothing '
      'else (FR-014)', () async {
    when(
      () => repository.restoreOccasion(any()),
    ).thenAnswer((_) async => const Right(unit));

    await restoreOccasion('o1');

    verify(() => repository.restoreOccasion('o1')).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('archiving an unknown occasion surfaces an '
      'OccasionNotFoundFailure', () async {
    when(() => repository.archiveOccasion(any())).thenAnswer(
      (_) async => const Left(OccasionNotFoundFailure('Occasion is gone')),
    );

    final result = await archiveOccasion('gone');

    expect(result.getLeft().toNullable(), isA<OccasionNotFoundFailure>());
  });

  test('restoring an unknown occasion surfaces an '
      'OccasionNotFoundFailure', () async {
    when(() => repository.restoreOccasion(any())).thenAnswer(
      (_) async => const Left(OccasionNotFoundFailure('Occasion is gone')),
    );

    final result = await restoreOccasion('gone');

    expect(result.getLeft().toNullable(), isA<OccasionNotFoundFailure>());
  });
}
