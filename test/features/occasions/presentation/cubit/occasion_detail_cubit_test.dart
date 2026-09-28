import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/media/attachment_picker_service.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_attachment.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_detail.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_participant_row.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_summary.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/occasions/domain/usecases/add_occasion_attachment.dart';
import 'package:daftary/features/occasions/domain/usecases/archive_occasion.dart';
import 'package:daftary/features/occasions/domain/usecases/delete_occasion.dart';
import 'package:daftary/features/occasions/domain/usecases/get_occasion_detail.dart';
import 'package:daftary/features/occasions/domain/usecases/remove_occasion_attachment.dart';
import 'package:daftary/features/occasions/domain/usecases/remove_participant_contribution.dart';
import 'package:daftary/features/occasions/domain/usecases/restore_occasion.dart';
import 'package:daftary/features/occasions/presentation/cubit/occasion_detail_cubit.dart';
import 'package:daftary/features/occasions/presentation/cubit/occasion_detail_state.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetOccasionDetail extends Mock implements GetOccasionDetail {}

class MockRemoveParticipantContribution extends Mock
    implements RemoveParticipantContribution {}

class MockAddOccasionAttachment extends Mock implements AddOccasionAttachment {}

class MockRemoveOccasionAttachment extends Mock
    implements RemoveOccasionAttachment {}

class MockArchiveOccasion extends Mock implements ArchiveOccasion {}

class MockRestoreOccasion extends Mock implements RestoreOccasion {}

class MockDeleteOccasion extends Mock implements DeleteOccasion {}

class MockAttachmentPickerService extends Mock
    implements AttachmentPickerService {}

/// T053/T076 — the occasion detail screen: totals that recalculate on every
/// change (FR-007), and an attachment flow whose failure modes never take
/// the occasion down with them (FR-017 Edge Cases).
void main() {
  late MockGetOccasionDetail getOccasionDetail;
  late MockRemoveParticipantContribution removeParticipant;
  late MockAddOccasionAttachment addAttachment;
  late MockRemoveOccasionAttachment removeAttachment;
  late MockArchiveOccasion archiveOccasion;
  late MockRestoreOccasion restoreOccasion;
  late MockDeleteOccasion deleteOccasion;
  late MockAttachmentPickerService picker;

  final now = DateTime(2026, 9, 15);
  const occasionId = 'o1';

  final occasion = Occasion(
    id: occasionId,
    idempotencyKey: 'key-1',
    name: "Ahmed's Wedding",
    date: now,
    type: OccasionType.wedding,
    createdAt: now,
    updatedAt: now,
  );

  OccasionParticipantRow row(String id, String name, int minorUnits) =>
      OccasionParticipantRow(
        transactionId: id,
        personId: 'p_$id',
        personName: name,
        amount: Money.egp(minorUnits),
        direction: TransactionDirection.received,
        countsTowardBalance: true,
        personOverallStatus: RelationshipStatus.settled,
      );

  OccasionDetail detailWith(
    List<OccasionParticipantRow> rows, {
    List<OccasionAttachment> attachments = const [],
  }) => OccasionDetail(
    occasion: occasion,
    summary: OccasionSummary(
      occasionId: occasionId,
      totalReceived: Money.egp(
        rows.fold(0, (sum, r) => sum + r.amount.minorUnits),
      ),
      totalGiven: Money.zero(Currency.egp),
      participantCount: rows.map((r) => r.personId).toSet().length,
    ),
    participants: rows,
    attachments: attachments,
  );

  final twoParticipants = detailWith([
    row('t1', 'Ahmed', 200000),
    row('t2', 'Mohamed', 100000),
  ]);
  final oneParticipant = detailWith([row('t2', 'Mohamed', 100000)]);

  setUp(() {
    getOccasionDetail = MockGetOccasionDetail();
    removeParticipant = MockRemoveParticipantContribution();
    addAttachment = MockAddOccasionAttachment();
    removeAttachment = MockRemoveOccasionAttachment();
    archiveOccasion = MockArchiveOccasion();
    restoreOccasion = MockRestoreOccasion();
    deleteOccasion = MockDeleteOccasion();
    picker = MockAttachmentPickerService();
  });

  OccasionDetailCubit build() => OccasionDetailCubit(
    getOccasionDetail,
    removeParticipant,
    addAttachment,
    removeAttachment,
    archiveOccasion,
    restoreOccasion,
    deleteOccasion,
    picker,
  );

  void stubDetail(OccasionDetail detail) {
    when(() => getOccasionDetail(any())).thenAnswer((_) async => Right(detail));
  }

  blocTest<OccasionDetailCubit, OccasionDetailState>(
    'loads the occasion with its totals and rows in one read, so the card '
    'and the list beneath it can never disagree (FR-007)',
    build: () {
      stubDetail(twoParticipants);
      return build();
    },
    act: (cubit) => cubit.load(occasionId),
    verify: (cubit) {
      expect(cubit.state.status, OccasionDetailStatus.success);
      expect(cubit.state.detail!.summary.totalReceived.minorUnits, 300000);
      expect(cubit.state.participantCount, 2);
      expect(cubit.state.hasParticipants, isTrue);
    },
  );

  blocTest<OccasionDetailCubit, OccasionDetailState>(
    'removing a participant re-reads the totals rather than patching the '
    'list in memory, so they recalculate immediately (FR-007/FR-011)',
    build: () {
      var removed = false;
      when(() => getOccasionDetail(any())).thenAnswer(
        (_) async => Right(removed ? oneParticipant : twoParticipants),
      );
      when(() => removeParticipant(any())).thenAnswer((_) async {
        removed = true;
        return const Right(unit);
      });
      return build();
    },
    act: (cubit) async {
      await cubit.load(occasionId);
      await cubit.removeParticipant('t1');
    },
    verify: (cubit) {
      verify(() => removeParticipant('t1')).called(1);
      expect(cubit.state.detail!.summary.totalReceived.minorUnits, 100000);
      expect(cubit.state.participantCount, 1);
    },
  );

  blocTest<OccasionDetailCubit, OccasionDetailState>(
    'an occasion with no participants reports the empty state rather than '
    'a failure (FR-020)',
    build: () {
      stubDetail(detailWith(const []));
      return build();
    },
    act: (cubit) => cubit.load(occasionId),
    verify: (cubit) {
      expect(cubit.state.hasParticipants, isFalse);
      expect(cubit.state.status, OccasionDetailStatus.success);
      expect(cubit.state.failure, isNull);
    },
  );

  group('attachments (FR-017)', () {
    final attachment = OccasionAttachment(
      id: 'a1',
      occasionId: occasionId,
      filePath: '/docs/attachments/a1.jpg',
      createdAt: now,
    );

    blocTest<OccasionDetailCubit, OccasionDetailState>(
      'a successful pick is persisted and appears in state',
      build: () {
        var attached = false;
        when(() => getOccasionDetail(any())).thenAnswer(
          (_) async => Right(
            detailWith(
              const [],
              attachments: attached ? [attachment] : const [],
            ),
          ),
        );
        when(
          () => picker.pickFromGallery(),
        ).thenAnswer((_) async => const Right('/tmp/picked.jpg'));
        when(
          () => addAttachment(
            occasionId: any(named: 'occasionId'),
            filePath: any(named: 'filePath'),
          ),
        ).thenAnswer((_) async {
          attached = true;
          return Right(attachment);
        });
        return build();
      },
      act: (cubit) async {
        await cubit.load(occasionId);
        await cubit.attachFromGallery();
      },
      verify: (cubit) {
        verify(
          () => addAttachment(
            occasionId: occasionId,
            filePath: '/tmp/picked.jpg',
          ),
        ).called(1);
        expect(cubit.state.detail!.attachments, [attachment]);
        expect(cubit.state.attachmentStatus, AttachmentStatus.idle);
        expect(cubit.state.attachmentFailure, isNull);
      },
    );

    blocTest<OccasionDetailCubit, OccasionDetailState>(
      'a denied camera permission surfaces a typed, explainable failure and '
      'leaves the occasion fully usable (FR-017 Edge Cases)',
      build: () {
        stubDetail(twoParticipants);
        when(() => picker.pickFromCamera()).thenAnswer(
          (_) async =>
              const Left(PermissionDeniedFailure('Camera access was denied')),
        );
        return build();
      },
      act: (cubit) async {
        await cubit.load(occasionId);
        await cubit.attachFromCamera();
      },
      verify: (cubit) {
        expect(cubit.state.attachmentFailure, isA<PermissionDeniedFailure>());
        // The occasion itself is untouched — no error screen, no lost data.
        expect(cubit.state.status, OccasionDetailStatus.success);
        expect(cubit.state.failure, isNull);
        expect(cubit.state.detail, twoParticipants);
        expect(cubit.state.attachmentStatus, AttachmentStatus.idle);
        verifyNever(
          () => addAttachment(
            occasionId: any(named: 'occasionId'),
            filePath: any(named: 'filePath'),
          ),
        );
      },
    );

    blocTest<OccasionDetailCubit, OccasionDetailState>(
      'a cancellation is silent — backing out of the picker is a choice, '
      'not an error to apologize for',
      build: () {
        stubDetail(twoParticipants);
        when(() => picker.pickFromGallery()).thenAnswer(
          (_) async => const Left(PickerCancelledFailure('No photo selected')),
        );
        return build();
      },
      act: (cubit) async {
        await cubit.load(occasionId);
        await cubit.attachFromGallery();
      },
      verify: (cubit) {
        expect(cubit.state.attachmentFailure, isNull);
        expect(cubit.state.attachmentStatus, AttachmentStatus.idle);
      },
    );

    blocTest<OccasionDetailCubit, OccasionDetailState>(
      'clears the surfaced attachment error once the page has shown it, so '
      'it is explained once rather than on every rebuild',
      build: () {
        stubDetail(twoParticipants);
        when(() => picker.pickFromCamera()).thenAnswer(
          (_) async => const Left(PermissionDeniedFailure('denied')),
        );
        return build();
      },
      act: (cubit) async {
        await cubit.load(occasionId);
        await cubit.attachFromCamera();
        cubit.attachmentFailureShown();
      },
      verify: (cubit) => expect(cubit.state.attachmentFailure, isNull),
    );

    blocTest<OccasionDetailCubit, OccasionDetailState>(
      'removing an attachment re-reads the occasion',
      build: () {
        var removed = false;
        when(() => getOccasionDetail(any())).thenAnswer(
          (_) async => Right(
            detailWith(
              const [],
              attachments: removed ? const [] : [attachment],
            ),
          ),
        );
        when(() => removeAttachment(any())).thenAnswer((_) async {
          removed = true;
          return const Right(unit);
        });
        return build();
      },
      act: (cubit) async {
        await cubit.load(occasionId);
        await cubit.removeAttachment('a1');
      },
      verify: (cubit) => expect(cubit.state.detail!.attachments, isEmpty),
    );
  });

  group('occasion-level actions', () {
    blocTest<OccasionDetailCubit, OccasionDetailState>(
      'archiving reloads rather than popping — the occasion is still there '
      'to look at, just off the default list (FR-014)',
      build: () {
        stubDetail(twoParticipants);
        when(
          () => archiveOccasion(any()),
        ).thenAnswer((_) async => const Right(unit));
        return build();
      },
      act: (cubit) async {
        await cubit.load(occasionId);
        await cubit.archive();
      },
      verify: (cubit) {
        verify(() => archiveOccasion(occasionId)).called(1);
        expect(cubit.state.isDeleted, isFalse);
      },
    );

    blocTest<OccasionDetailCubit, OccasionDetailState>(
      'deleting marks the occasion gone so the page pops instead of '
      'reloading a tombstone (FR-013)',
      build: () {
        stubDetail(twoParticipants);
        when(
          () => deleteOccasion(any()),
        ).thenAnswer((_) async => const Right(unit));
        return build();
      },
      act: (cubit) async {
        await cubit.load(occasionId);
        // The count the confirmation names comes from the already-loaded
        // summary, not a second read that could disagree with it.
        expect(cubit.state.participantCount, 2);
        await cubit.delete();
      },
      verify: (cubit) {
        verify(() => deleteOccasion(occasionId)).called(1);
        expect(cubit.state.isDeleted, isTrue);
      },
    );

    blocTest<OccasionDetailCubit, OccasionDetailState>(
      'a failed delete leaves the occasion open with the reason shown',
      build: () {
        stubDetail(twoParticipants);
        when(
          () => deleteOccasion(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('write failed')));
        return build();
      },
      act: (cubit) async {
        await cubit.load(occasionId);
        await cubit.delete();
      },
      verify: (cubit) {
        expect(cubit.state.isDeleted, isFalse);
        expect(cubit.state.failure, isA<CacheFailure>());
      },
    );
  });
}
