import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/ocr/domain/entities/candidate_entry.dart';
import 'package:daftary/features/ocr/domain/entities/field_confidence.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_scan.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_scan_detail.dart';
import 'package:daftary/features/ocr/domain/usecases/cancel_scan.dart';
import 'package:daftary/features/ocr/domain/usecases/confirm_scan_batch.dart';
import 'package:daftary/features/ocr/domain/usecases/discard_candidate_entry.dart';
import 'package:daftary/features/ocr/domain/usecases/edit_candidate_entry.dart';
import 'package:daftary/features/ocr/domain/usecases/get_candidate_entries.dart';
import 'package:daftary/features/ocr/domain/usecases/get_possible_duplicate_for_candidate.dart';
import 'package:daftary/features/ocr/domain/usecases/get_scan_detail.dart';
import 'package:daftary/features/ocr/domain/usecases/set_batch_default_direction.dart';
import 'package:daftary/features/ocr/domain/usecases/tag_batch_to_occasion.dart';
import 'package:daftary/features/ocr/presentation/cubit/scan_review_cubit.dart';
import 'package:daftary/features/ocr/presentation/cubit/scan_review_state.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetScanDetail extends Mock implements GetScanDetail {}

class _MockGetCandidateEntries extends Mock implements GetCandidateEntries {}

class _MockEditCandidateEntry extends Mock implements EditCandidateEntry {}

class _MockDiscardCandidateEntry extends Mock
    implements DiscardCandidateEntry {}

class _MockConfirmScanBatch extends Mock implements ConfirmScanBatch {}

class _MockCancelScan extends Mock implements CancelScan {}

class _MockSetBatchDefaultDirection extends Mock
    implements SetBatchDefaultDirection {}

class _MockTagBatchToOccasion extends Mock implements TagBatchToOccasion {}

class _MockGetPossibleDuplicate extends Mock
    implements GetPossibleDuplicateForCandidate {}

void main() {
  late _MockGetScanDetail getScanDetail;
  late _MockGetCandidateEntries getCandidateEntries;
  late _MockEditCandidateEntry editCandidateEntry;
  late _MockDiscardCandidateEntry discardCandidateEntry;
  late _MockConfirmScanBatch confirmScanBatch;
  late _MockCancelScan cancelScan;
  late _MockSetBatchDefaultDirection setBatchDefaultDirection;
  late _MockTagBatchToOccasion tagBatchToOccasion;
  late _MockGetPossibleDuplicate getPossibleDuplicate;

  const scanId = 'scan-1';

  OcrScan scan({
    TransactionDirection? defaultDirection = TransactionDirection.received,
    ScanStatus status = ScanStatus.needsReview,
  }) => OcrScan(
    id: scanId,
    idempotencyKey: 'seed',
    sourceImagePath: '/tmp/scan.png',
    rotationDegrees: 0,
    status: status,
    defaultDirection: defaultDirection,
    createdAt: DateTime(2026, 3, 1),
  );

  CandidateEntry entry({
    required String id,
    String personName = 'Ahmed',
    int? amountMinorUnits = 50000,
    CandidateEntryStatus status = CandidateEntryStatus.pendingReview,
    FieldConfidence? amountConfidence,
    DateTime? editedAt,
  }) => CandidateEntry(
    id: id,
    scanId: scanId,
    status: status,
    personName: personName,
    personNameConfidence: FieldConfidence.read(FieldConfidenceLevel.high),
    amountConfidence:
        amountConfidence ?? FieldConfidence.read(FieldConfidenceLevel.high),
    directionConfidence: const FieldConfidence.inferred(),
    dateConfidence: const FieldConfidence.inferred(),
    amountMinorUnits: amountMinorUnits,
    rawOcrText: '$personName 500',
    createdAt: DateTime(2026, 3, 1),
    editedAt: editedAt,
  );

  MoneyTransaction transaction(String id) => MoneyTransaction(
    id: id,
    idempotencyKey: 'k-$id',
    personId: 'p-$id',
    amount: const Money.fromMinorUnits(50000),
    direction: TransactionDirection.received,
    kind: TransactionKind.initialExchange,
    source: TransactionSource.ocr,
    ocrScanId: scanId,
    date: DateTime(2026, 3, 1),
    createdAt: DateTime(2026, 3, 1),
  );

  /// Wires the mocks for a scan that is ready to confirm, so each test only
  /// has to state the one thing it is actually about.
  void stubLoad({OcrScan? withScan, List<CandidateEntry>? withEntries}) {
    final loaded = withScan ?? scan();
    final entries = withEntries ?? [entry(id: 'e1'), entry(id: 'e2')];
    when(() => getScanDetail(any())).thenAnswer(
      (_) async => Right(
        OcrScanDetail(scan: loaded, entries: entries, transactions: const []),
      ),
    );
    when(
      () => getCandidateEntries(any()),
    ).thenAnswer((_) async => Right(entries));
  }

  ScanReviewCubit build() => ScanReviewCubit(
    getScanDetail,
    getCandidateEntries,
    editCandidateEntry,
    discardCandidateEntry,
    confirmScanBatch,
    cancelScan,
    setBatchDefaultDirection,
    tagBatchToOccasion,
    getPossibleDuplicate,
    EgpFormatter(),
  );

  setUpAll(() {
    registerFallbackValue(TransactionDirection.received);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    getScanDetail = _MockGetScanDetail();
    getCandidateEntries = _MockGetCandidateEntries();
    editCandidateEntry = _MockEditCandidateEntry();
    discardCandidateEntry = _MockDiscardCandidateEntry();
    confirmScanBatch = _MockConfirmScanBatch();
    cancelScan = _MockCancelScan();
    setBatchDefaultDirection = _MockSetBatchDefaultDirection();
    tagBatchToOccasion = _MockTagBatchToOccasion();
    getPossibleDuplicate = _MockGetPossibleDuplicate();
    when(
      () => getPossibleDuplicate(any()),
    ).thenAnswer((_) async => const Right([]));
  });

  group('load', () {
    blocTest<ScanReviewCubit, ScanReviewState>(
      'loads the scan and its entries into a ready state',
      setUp: stubLoad,
      build: build,
      act: (cubit) => cubit.load(scanId),
      verify: (cubit) {
        expect(cubit.state.status, ScanReviewStatus.ready);
        expect(cubit.state.entries, hasLength(2));
        expect(cubit.state.scan?.id, scanId);
        expect(cubit.state.canConfirm, isTrue);
      },
    );

    blocTest<ScanReviewCubit, ScanReviewState>(
      'a load failure never reports a confirmable batch',
      setUp: () {
        when(
          () => getScanDetail(any()),
        ).thenAnswer((_) async => const Left(NotFoundFailure('gone')));
      },
      build: build,
      act: (cubit) => cubit.load(scanId),
      verify: (cubit) {
        expect(cubit.state.status, ScanReviewStatus.loadFailure);
        expect(cubit.state.canConfirm, isFalse);
      },
    );
  });

  group('confirm eligibility (FR-008/FR-011)', () {
    blocTest<ScanReviewCubit, ScanReviewState>(
      'an entry with no amount blocks the whole batch, not just itself',
      setUp: () => stubLoad(
        withEntries: [
          entry(id: 'e1'),
          entry(id: 'e2', amountMinorUnits: null),
        ],
      ),
      build: build,
      act: (cubit) => cubit.load(scanId),
      verify: (cubit) {
        expect(cubit.state.canConfirm, isFalse);
        expect(cubit.state.ineligibleEntryIds, {'e2'});
      },
    );

    blocTest<ScanReviewCubit, ScanReviewState>(
      'with no batch default and no per-entry direction, nothing is '
      'confirmable — the app never guesses which way the money went',
      setUp: () => stubLoad(withScan: scan(defaultDirection: null)),
      build: build,
      act: (cubit) => cubit.load(scanId),
      verify: (cubit) {
        expect(cubit.state.canConfirm, isFalse);
        expect(cubit.state.ineligibleEntryIds, {'e1', 'e2'});
      },
    );

    blocTest<ScanReviewCubit, ScanReviewState>(
      'a discarded entry is excluded from eligibility rather than blocking '
      'the batch (FR-010)',
      setUp: () => stubLoad(
        withEntries: [
          entry(id: 'e1'),
          entry(
            id: 'e2',
            amountMinorUnits: null,
            status: CandidateEntryStatus.discarded,
          ),
        ],
      ),
      build: build,
      act: (cubit) => cubit.load(scanId),
      verify: (cubit) {
        expect(cubit.state.activeEntries.map((e) => e.id), ['e1']);
        expect(cubit.state.canConfirm, isTrue);
      },
    );
  });

  group('low-confidence ordering (FR-013)', () {
    blocTest<ScanReviewCubit, ScanReviewState>(
      'entries carrying a low-confidence read are shown first, and equally '
      'risky entries keep the order the parser produced',
      setUp: () => stubLoad(
        withEntries: [
          entry(id: 'calm1'),
          entry(
            id: 'risky1',
            amountConfidence: FieldConfidence.read(FieldConfidenceLevel.low),
          ),
          entry(id: 'calm2'),
          entry(
            id: 'risky2',
            amountConfidence: FieldConfidence.read(FieldConfidenceLevel.low),
          ),
        ],
      ),
      build: build,
      act: (cubit) => cubit.load(scanId),
      verify: (cubit) {
        expect(cubit.state.orderedEntries.map((e) => e.id), [
          'risky1',
          'risky2',
          'calm1',
          'calm2',
        ]);
      },
    );
  });

  group('discard (FR-010)', () {
    blocTest<ScanReviewCubit, ScanReviewState>(
      'discarding one entry leaves its siblings alone',
      setUp: () {
        stubLoad();
        when(
          () => discardCandidateEntry(any()),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.load(scanId);
        await cubit.discardEntry('e1');
      },
      verify: (cubit) {
        verify(() => discardCandidateEntry('e1')).called(1);
        expect(cubit.state.activeEntries.map((e) => e.id), ['e2']);
      },
    );
  });

  group('confirm — the gate (constitution Principle X, FR-007/FR-021)', () {
    blocTest<ScanReviewCubit, ScanReviewState>(
      'a successful confirm reports exactly what was created',
      setUp: () {
        stubLoad();
        when(
          () => confirmScanBatch(
            idempotencyKey: any(named: 'idempotencyKey'),
            scanId: any(named: 'scanId'),
          ),
        ).thenAnswer(
          (_) async => Right([transaction('t1'), transaction('t2')]),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.load(scanId);
        await cubit.confirm();
      },
      verify: (cubit) {
        expect(cubit.state.status, ScanReviewStatus.success);
        expect(cubit.state.savedTransactions, hasLength(2));
      },
    );

    test('a double-tapped confirm calls ConfirmScanBatch exactly once '
        '(FR-021)', () async {
      stubLoad();
      when(
        () => confirmScanBatch(
          idempotencyKey: any(named: 'idempotencyKey'),
          scanId: any(named: 'scanId'),
        ),
      ).thenAnswer((_) async {
        // A real save is not instantaneous; the second tap lands during it,
        // which is exactly the window FR-021 is about.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return Right([transaction('t1')]);
      });
      final cubit = build();
      await cubit.load(scanId);

      await Future.wait([cubit.confirm(), cubit.confirm()]);

      verify(
        () => confirmScanBatch(
          idempotencyKey: any(named: 'idempotencyKey'),
          scanId: any(named: 'scanId'),
        ),
      ).called(1);
      await cubit.close();
    });

    test(
      'each confirm attempt carries its own idempotency key, so a retry '
      'after a failure is a new attempt rather than a swallowed one',
      () async {
        stubLoad();
        final keys = <String>[];
        when(
          () => confirmScanBatch(
            idempotencyKey: any(named: 'idempotencyKey'),
            scanId: any(named: 'scanId'),
          ),
        ).thenAnswer((invocation) async {
          keys.add(invocation.namedArguments[#idempotencyKey] as String);
          return const Left(CacheFailure('disk full'));
        });
        final cubit = build();
        await cubit.load(scanId);

        await cubit.confirm();
        await cubit.confirm();

        expect(keys, hasLength(2));
        expect(keys.first, isNot(keys.last));
        await cubit.close();
      },
    );

    blocTest<ScanReviewCubit, ScanReviewState>(
      'a ValidationFailure names the incomplete entries and reports nothing '
      'as saved (FR-011, all-or-nothing)',
      setUp: () {
        stubLoad();
        when(
          () => confirmScanBatch(
            idempotencyKey: any(named: 'idempotencyKey'),
            scanId: any(named: 'scanId'),
          ),
        ).thenAnswer((_) async => const Left(ValidationFailure('incomplete')));
        // The repository's refusal means this screen's picture was stale,
        // so it reloads — and the reload is what reveals the bad entry.
        when(() => getCandidateEntries(any())).thenAnswer(
          (_) async =>
              Right([entry(id: 'e1'), entry(id: 'e2', amountMinorUnits: null)]),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.load(scanId);
        await cubit.confirm();
      },
      verify: (cubit) {
        expect(cubit.state.status, ScanReviewStatus.ready);
        expect(cubit.state.savedTransactions, isEmpty);
        expect(cubit.state.validationFailureEntryIds, contains('e2'));
      },
    );

    blocTest<ScanReviewCubit, ScanReviewState>(
      'confirm is refused outright while any entry is incomplete — the use '
      'case is never even reached',
      setUp: () =>
          stubLoad(withEntries: [entry(id: 'e1', amountMinorUnits: null)]),
      build: build,
      act: (cubit) async {
        await cubit.load(scanId);
        await cubit.confirm();
      },
      verify: (cubit) {
        verifyNever(
          () => confirmScanBatch(
            idempotencyKey: any(named: 'idempotencyKey'),
            scanId: any(named: 'scanId'),
          ),
        );
        expect(cubit.state.validationFailureEntryIds, {'e1'});
      },
    );
  });

  group('cancel (FR-015)', () {
    blocTest<ScanReviewCubit, ScanReviewState>(
      'cancelling an untouched batch abandons it without a prompt',
      setUp: () {
        stubLoad();
        when(
          () => cancelScan(any()),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.load(scanId);
        await cubit.cancel();
      },
      verify: (cubit) {
        verify(() => cancelScan(scanId)).called(1);
        expect(cubit.state.requiresCancelConfirmation, isFalse);
      },
    );

    blocTest<ScanReviewCubit, ScanReviewState>(
      'cancelling a batch the user corrected asks first, and does not '
      'abandon anything until they confirm',
      setUp: () {
        stubLoad(
          withEntries: [
            entry(id: 'e1', editedAt: DateTime(2026, 3, 2)),
            entry(id: 'e2'),
          ],
        );
        when(
          () => cancelScan(any()),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.load(scanId);
        await cubit.cancel();
      },
      verify: (cubit) {
        expect(cubit.state.hasUnsavedCorrections, isTrue);
        expect(cubit.state.requiresCancelConfirmation, isTrue);
        verifyNever(() => cancelScan(any()));
      },
    );

    blocTest<ScanReviewCubit, ScanReviewState>(
      'confirming the prompt is what actually abandons the scan',
      setUp: () {
        stubLoad(
          withEntries: [entry(id: 'e1', editedAt: DateTime(2026, 3, 2))],
        );
        when(
          () => cancelScan(any()),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.load(scanId);
        await cubit.cancel();
        await cubit.confirmCancel();
      },
      verify: (cubit) {
        verify(() => cancelScan(scanId)).called(1);
        expect(cubit.state.status, ScanReviewStatus.cancelled);
      },
    );
  });
}
