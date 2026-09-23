import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_attachment.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_detail.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_failures.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_participant_row.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_summary.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/occasions/domain/repositories/occasions_repository.dart';
import 'package:daftary/features/occasions/domain/usecases/get_occasion_detail.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOccasionsRepository extends Mock implements OccasionsRepository {}

void main() {
  late MockOccasionsRepository repository;
  late GetOccasionDetail getOccasionDetail;

  Occasion buildOccasion() => Occasion(
    id: 'o1',
    idempotencyKey: 'key-1',
    name: 'Ahmed wedding',
    date: DateTime(2026, 3, 14),
    type: OccasionType.wedding,
    createdAt: DateTime(2026, 3, 1),
    updatedAt: DateTime(2026, 3, 1),
  );

  OccasionParticipantRow buildRow({
    required String transactionId,
    required String personId,
    required String personName,
    required int amountMinorUnits,
    required TransactionDirection direction,
    RelationshipStatus personOverallStatus = RelationshipStatus.settled,
    bool countsTowardBalance = true,
  }) {
    return OccasionParticipantRow(
      transactionId: transactionId,
      personId: personId,
      personName: personName,
      amount: Money.fromMinorUnits(amountMinorUnits),
      direction: direction,
      countsTowardBalance: countsTowardBalance,
      personOverallStatus: personOverallStatus,
    );
  }

  /// A summary built the way the repository builds it: SUM by direction over
  /// the same rows the detail carries, never a stored column.
  OccasionSummary summarize(List<OccasionParticipantRow> rows) {
    var received = Money.zero();
    var given = Money.zero();
    for (final row in rows) {
      if (row.direction == TransactionDirection.received) {
        received = received.add(row.amount);
      } else {
        given = given.add(row.amount);
      }
    }
    return OccasionSummary(
      occasionId: 'o1',
      totalReceived: received,
      totalGiven: given,
      participantCount: rows.map((row) => row.personId).toSet().length,
    );
  }

  OccasionDetail buildDetail(
    List<OccasionParticipantRow> rows, {
    List<OccasionAttachment> attachments = const [],
  }) {
    return OccasionDetail(
      occasion: buildOccasion(),
      summary: summarize(rows),
      participants: rows,
      attachments: attachments,
    );
  }

  void stubDetail(Either<Failure, OccasionDetail> response) {
    when(
      () => repository.getOccasionDetail(any()),
    ).thenAnswer((_) async => response);
  }

  setUp(() {
    repository = MockOccasionsRepository();
    getOccasionDetail = GetOccasionDetail(repository);
  });

  group('OccasionSummary value object (FR-007/FR-008)', () {
    test('nets received against given', () {
      const summary = OccasionSummary(
        occasionId: 'o1',
        totalReceived: Money.fromMinorUnits(120000),
        totalGiven: Money.fromMinorUnits(45000),
        participantCount: 3,
      );

      expect(summary.net, const Money.fromMinorUnits(75000));
    });

    test('is settled with a zero outstanding amount when net is zero', () {
      const summary = OccasionSummary(
        occasionId: 'o1',
        totalReceived: Money.fromMinorUnits(80000),
        totalGiven: Money.fromMinorUnits(80000),
        participantCount: 2,
      );

      expect(summary.settlementStatus, SettlementStatus.settled);
      expect(summary.outstanding, Money.zero());
    });

    test('reports moreReceived with a positive outstanding magnitude', () {
      const summary = OccasionSummary(
        occasionId: 'o1',
        totalReceived: Money.fromMinorUnits(120000),
        totalGiven: Money.fromMinorUnits(45000),
        participantCount: 3,
      );

      expect(summary.settlementStatus, SettlementStatus.moreReceived);
      expect(summary.outstanding, const Money.fromMinorUnits(75000));
      expect(summary.outstanding.isPositive, isTrue);
    });

    test('reports moreGiven with the magnitude carried unsigned, the '
        'direction carried by the label', () {
      const summary = OccasionSummary(
        occasionId: 'o1',
        totalReceived: Money.fromMinorUnits(20000),
        totalGiven: Money.fromMinorUnits(95000),
        participantCount: 4,
      );

      expect(summary.net, const Money.fromMinorUnits(-75000));
      expect(summary.settlementStatus, SettlementStatus.moreGiven);
      expect(summary.outstanding, const Money.fromMinorUnits(75000));
      expect(summary.outstanding.isNegative, isFalse);
    });

    test('an empty occasion is settled with no participants (FR-020)', () {
      final summary = OccasionSummary.empty('o1');

      expect(summary.participantCount, 0);
      expect(summary.net, Money.zero());
      expect(summary.settlementStatus, SettlementStatus.settled);
    });
  });

  group('through GetOccasionDetail', () {
    test('aggregates totalReceived/totalGiven/net over a mix of given and '
        'received rows (FR-007)', () async {
      final rows = [
        buildRow(
          transactionId: 't1',
          personId: 'p1',
          personName: 'Ahmed',
          amountMinorUnits: 50000,
          direction: TransactionDirection.received,
        ),
        buildRow(
          transactionId: 't2',
          personId: 'p2',
          personName: 'Mona',
          amountMinorUnits: 70000,
          direction: TransactionDirection.received,
        ),
        buildRow(
          transactionId: 't3',
          personId: 'p3',
          personName: 'Sara',
          amountMinorUnits: 45000,
          direction: TransactionDirection.given,
        ),
      ];
      stubDetail(Right(buildDetail(rows)));

      final summary = (await getOccasionDetail('o1')).toNullable()!.summary;

      expect(summary.totalReceived, const Money.fromMinorUnits(120000));
      expect(summary.totalGiven, const Money.fromMinorUnits(45000));
      expect(summary.net, const Money.fromMinorUnits(75000));
      expect(summary.settlementStatus, SettlementStatus.moreReceived);
      expect(summary.outstanding, const Money.fromMinorUnits(75000));
    });

    test('labels the occasion settled when received equals given '
        '(FR-008)', () async {
      final rows = [
        buildRow(
          transactionId: 't1',
          personId: 'p1',
          personName: 'Ahmed',
          amountMinorUnits: 60000,
          direction: TransactionDirection.received,
        ),
        buildRow(
          transactionId: 't2',
          personId: 'p2',
          personName: 'Mona',
          amountMinorUnits: 60000,
          direction: TransactionDirection.given,
        ),
      ];
      stubDetail(Right(buildDetail(rows)));

      final summary = (await getOccasionDetail('o1')).toNullable()!.summary;

      expect(summary.settlementStatus, SettlementStatus.settled);
      expect(summary.outstanding, Money.zero());
    });

    test('labels the occasion moreGiven when given exceeds received, with a '
        'positive outstanding magnitude (FR-008)', () async {
      final rows = [
        buildRow(
          transactionId: 't1',
          personId: 'p1',
          personName: 'Ahmed',
          amountMinorUnits: 20000,
          direction: TransactionDirection.received,
        ),
        buildRow(
          transactionId: 't2',
          personId: 'p2',
          personName: 'Mona',
          amountMinorUnits: 95000,
          direction: TransactionDirection.given,
        ),
      ];
      stubDetail(Right(buildDetail(rows)));

      final summary = (await getOccasionDetail('o1')).toNullable()!.summary;

      expect(summary.settlementStatus, SettlementStatus.moreGiven);
      expect(summary.outstanding, const Money.fromMinorUnits(75000));
    });

    test('counts distinct people, so two contributions from one person are '
        'one participant (FR-006/FR-020)', () async {
      final rows = [
        buildRow(
          transactionId: 't1',
          personId: 'p1',
          personName: 'Ahmed',
          amountMinorUnits: 50000,
          direction: TransactionDirection.received,
        ),
        buildRow(
          transactionId: 't2',
          personId: 'p1',
          personName: 'Ahmed',
          amountMinorUnits: 10000,
          direction: TransactionDirection.received,
        ),
      ];
      stubDetail(Right(buildDetail(rows)));

      final detail = (await getOccasionDetail('o1')).toNullable()!;

      expect(detail.participants, hasLength(2));
      expect(detail.summary.participantCount, 1);
    });

    test("each row's personOverallStatus is the person's FULL balance, not "
        'an occasion-scoped one (FR-009)', () async {
      // Ahmed gave 500 at this occasion, which on its own would read
      // "they owe you". His full history also holds a 900 received outside
      // this occasion, so his real overall status is "you owe them" — and
      // that is what the row must show.
      const ahmedFullBalance = PersonBalance(
        personId: 'p1',
        net: Money.fromMinorUnits(-40000),
      );
      final rows = [
        buildRow(
          transactionId: 't1',
          personId: 'p1',
          personName: 'Ahmed',
          amountMinorUnits: 50000,
          direction: TransactionDirection.given,
          personOverallStatus: ahmedFullBalance.status,
        ),
      ];
      stubDetail(Right(buildDetail(rows)));

      final detail = (await getOccasionDetail('o1')).toNullable()!;
      final row = detail.participants.single;

      expect(ahmedFullBalance.status, RelationshipStatus.youOweThem);
      expect(row.personOverallStatus, RelationshipStatus.youOweThem);
      // The occasion-scoped view of the same row points the other way — the
      // proof the status is not derived from this occasion's numbers.
      expect(detail.summary.settlementStatus, SettlementStatus.moreGiven);
    });

    test('a person who is settled within this occasion can still read as '
        'owing overall (FR-009)', () async {
      final rows = [
        buildRow(
          transactionId: 't1',
          personId: 'p1',
          personName: 'Ahmed',
          amountMinorUnits: 30000,
          direction: TransactionDirection.received,
          personOverallStatus: RelationshipStatus.theyOweYou,
        ),
        buildRow(
          transactionId: 't2',
          personId: 'p1',
          personName: 'Ahmed',
          amountMinorUnits: 30000,
          direction: TransactionDirection.given,
          personOverallStatus: RelationshipStatus.theyOweYou,
        ),
      ];
      stubDetail(Right(buildDetail(rows)));

      final detail = (await getOccasionDetail('o1')).toNullable()!;

      expect(detail.summary.settlementStatus, SettlementStatus.settled);
      for (final row in detail.participants) {
        expect(row.personOverallStatus, RelationshipStatus.theyOweYou);
      }
    });

    test('is a thin pass-through: one repository read, nothing '
        're-aggregated (FR-007)', () async {
      final detail = buildDetail(const []);
      stubDetail(Right(detail));

      final result = await getOccasionDetail('o1');

      expect(result.toNullable(), same(detail));
      verify(() => repository.getOccasionDetail('o1')).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('supplies the affected-contribution count DeleteOccasion needs '
        'confirmed first (FR-013)', () async {
      final rows = [
        buildRow(
          transactionId: 't1',
          personId: 'p1',
          personName: 'Ahmed',
          amountMinorUnits: 50000,
          direction: TransactionDirection.received,
        ),
        buildRow(
          transactionId: 't2',
          personId: 'p2',
          personName: 'Mona',
          amountMinorUnits: 30000,
          direction: TransactionDirection.received,
        ),
      ];
      stubDetail(Right(buildDetail(rows)));

      final detail = (await getOccasionDetail('o1')).toNullable()!;

      expect(detail.summary.participantCount, 2);
    });

    test('surfaces a deleted or unknown occasion as an '
        'OccasionNotFoundFailure', () async {
      stubDetail(const Left(OccasionNotFoundFailure('Occasion is gone')));

      final result = await getOccasionDetail('gone');

      expect(result.getLeft().toNullable(), isA<OccasionNotFoundFailure>());
    });
  });
}
