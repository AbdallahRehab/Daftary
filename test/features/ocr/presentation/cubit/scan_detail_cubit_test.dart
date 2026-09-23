import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/ocr/domain/entities/candidate_entry.dart';
import 'package:daftary/features/ocr/domain/entities/field_confidence.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_scan.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_scan_detail.dart';
import 'package:daftary/features/ocr/domain/usecases/delete_scan.dart';
import 'package:daftary/features/ocr/domain/usecases/get_scan_detail.dart';
import 'package:daftary/features/ocr/presentation/cubit/scan_detail_cubit.dart';
import 'package:daftary/features/ocr/presentation/cubit/scan_detail_state.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetScanDetail extends Mock implements GetScanDetail {}

class MockDeleteScan extends Mock implements DeleteScan {}

/// T067 — one past scan in full (User Story 5 AC2, FR-018, FR-023).
void main() {
  late MockGetScanDetail getScanDetail;
  late MockDeleteScan deleteScan;

  final createdAt = DateTime(2026, 9, 20);

  final scan = OcrScan(
    id: 's1',
    idempotencyKey: 'key-s1',
    sourceImagePath: '/scans/s1.jpg',
    rotationDegrees: 0,
    status: ScanStatus.confirmed,
    createdAt: createdAt,
  );

  CandidateEntry entry(String id, CandidateEntryStatus status) =>
      CandidateEntry(
        id: id,
        scanId: 's1',
        status: status,
        personName: 'Ahmed $id',
        personNameConfidence: FieldConfidence.read(FieldConfidenceLevel.high),
        amountConfidence: FieldConfidence.read(FieldConfidenceLevel.high),
        directionConfidence: const FieldConfidence.inferred(),
        dateConfidence: const FieldConfidence.inferred(),
        rawOcrText: 'Ahmed $id 1000',
        createdAt: createdAt,
        amountMinorUnits: 100000,
        direction: TransactionDirection.received,
      );

  MoneyTransaction transaction(String id) => MoneyTransaction(
    id: id,
    idempotencyKey: 'key-$id',
    personId: 'p-$id',
    amount: const Money.fromMinorUnits(100000),
    direction: TransactionDirection.received,
    kind: TransactionKind.initialExchange,
    date: createdAt,
    createdAt: createdAt,
    source: TransactionSource.ocr,
    ocrScanId: 's1',
  );

  final detail = OcrScanDetail(
    scan: scan,
    entries: [
      entry('e1', CandidateEntryStatus.confirmed),
      entry('e2', CandidateEntryStatus.discarded),
    ],
    transactions: [transaction('t1')],
  );

  setUp(() {
    getScanDetail = MockGetScanDetail();
    deleteScan = MockDeleteScan();
  });

  blocTest<ScanDetailCubit, ScanDetailState>(
    'loads the scan with its entries and the transactions it produced '
    '(FR-018)',
    build: () {
      when(() => getScanDetail('s1')).thenAnswer((_) async => Right(detail));
      return ScanDetailCubit(getScanDetail, deleteScan);
    },
    act: (cubit) => cubit.load('s1'),
    verify: (cubit) {
      expect(cubit.state.status, ScanDetailStatus.success);
      expect(cubit.state.detail?.entries.map((e) => e.id), ['e1', 'e2']);
      expect(cubit.state.detail?.transactions.single.id, 't1');
      expect(cubit.state.detail?.transactions.single.ocrScanId, 's1');
      expect(cubit.state.producedNoTransactions, isFalse);
    },
  );

  blocTest<ScanDetailCubit, ScanDetailState>(
    'a scan that produced nothing still loads, flagged as such rather than '
    'hidden (User Story 5, Acceptance Scenario 3)',
    build: () {
      when(() => getScanDetail('s1')).thenAnswer(
        (_) async => Right(
          OcrScanDetail(
            scan: scan,
            entries: [entry('e1', CandidateEntryStatus.discarded)],
            transactions: const [],
          ),
        ),
      );
      return ScanDetailCubit(getScanDetail, deleteScan);
    },
    act: (cubit) => cubit.load('s1'),
    verify: (cubit) {
      expect(cubit.state.status, ScanDetailStatus.success);
      expect(cubit.state.producedNoTransactions, isTrue);
    },
  );

  blocTest<ScanDetailCubit, ScanDetailState>(
    'a read failure surfaces as a failure state carrying the Failure',
    build: () {
      when(
        () => getScanDetail('s1'),
      ).thenAnswer((_) async => const Left(NotFoundFailure('no such scan')));
      return ScanDetailCubit(getScanDetail, deleteScan);
    },
    act: (cubit) => cubit.load('s1'),
    verify: (cubit) {
      expect(cubit.state.hasFailed, isTrue);
      expect(cubit.state.failure, const NotFoundFailure('no such scan'));
      expect(cubit.state.detail, isNull);
    },
  );

  blocTest<ScanDetailCubit, ScanDetailState>(
    'delete removes the loaded scan and leaves its transactions in state — '
    'the scan goes, the money does not (FR-023)',
    build: () {
      when(() => getScanDetail('s1')).thenAnswer((_) async => Right(detail));
      when(() => deleteScan('s1')).thenAnswer((_) async => const Right(unit));
      return ScanDetailCubit(getScanDetail, deleteScan);
    },
    act: (cubit) async {
      await cubit.load('s1');
      await cubit.delete();
    },
    verify: (cubit) {
      verify(() => deleteScan('s1')).called(1);
      expect(cubit.state.isDeleted, isTrue);
      expect(cubit.state.detail?.transactions.single.id, 't1');
    },
  );

  blocTest<ScanDetailCubit, ScanDetailState>(
    'delete before any load is a no-op — it can never target a scan other '
    'than the one on screen',
    build: () => ScanDetailCubit(getScanDetail, deleteScan),
    act: (cubit) => cubit.delete(),
    expect: () => <ScanDetailState>[],
    verify: (_) => verifyNever(() => deleteScan(any())),
  );

  blocTest<ScanDetailCubit, ScanDetailState>(
    'a failed delete reports the failure and keeps the scan on screen',
    build: () {
      when(() => getScanDetail('s1')).thenAnswer((_) async => Right(detail));
      when(
        () => deleteScan('s1'),
      ).thenAnswer((_) async => const Left(CacheFailure('delete failed')));
      return ScanDetailCubit(getScanDetail, deleteScan);
    },
    act: (cubit) async {
      await cubit.load('s1');
      await cubit.delete();
    },
    verify: (cubit) {
      expect(cubit.state.isDeleted, isFalse);
      expect(cubit.state.hasFailed, isTrue);
      expect(cubit.state.failure, const CacheFailure('delete failed'));
      expect(cubit.state.detail, detail);
    },
  );
}
