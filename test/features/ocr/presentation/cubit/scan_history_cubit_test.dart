import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_scan.dart';
import 'package:daftary/features/ocr/domain/usecases/delete_scan.dart';
import 'package:daftary/features/ocr/domain/usecases/get_scan_history.dart';
import 'package:daftary/features/ocr/presentation/cubit/scan_history_cubit.dart';
import 'package:daftary/features/ocr/presentation/cubit/scan_history_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetScanHistory extends Mock implements GetScanHistory {}

class MockDeleteScan extends Mock implements DeleteScan {}

/// T062/T066 — scan history (User Story 5, FR-018, FR-023).
void main() {
  late MockGetScanHistory getScanHistory;
  late MockDeleteScan deleteScan;

  OcrScan scan(String id, DateTime createdAt, {ScanStatus? status}) => OcrScan(
    id: id,
    idempotencyKey: 'key-$id',
    sourceImagePath: '/scans/$id.jpg',
    rotationDegrees: 0,
    status: status ?? ScanStatus.confirmed,
    createdAt: createdAt,
  );

  final newest = scan('s3', DateTime(2026, 9, 20));
  final middle = scan('s2', DateTime(2026, 5, 10), status: ScanStatus.failed);
  final oldest = scan('s1', DateTime(2026, 1, 5), status: ScanStatus.discarded);

  setUp(() {
    getScanHistory = MockGetScanHistory();
    deleteScan = MockDeleteScan();
  });

  blocTest<ScanHistoryCubit, ScanHistoryState>(
    'loads scans in the order the repository returned them — newest first, '
    'never re-sorted here (FR-018)',
    build: () {
      when(
        () => getScanHistory(),
      ).thenAnswer((_) async => Right([newest, middle, oldest]));
      return ScanHistoryCubit(getScanHistory, deleteScan);
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.scans.map((s) => s.id), ['s3', 's2', 's1']);
      expect(cubit.state.status, ScanHistoryStatus.success);
      expect(cubit.state.isEmpty, isFalse);
      expect(cubit.state.failure, isNull);
    },
  );

  blocTest<ScanHistoryCubit, ScanHistoryState>(
    'an empty history is a success state, not a permanent spinner',
    build: () {
      when(() => getScanHistory()).thenAnswer((_) async => const Right([]));
      return ScanHistoryCubit(getScanHistory, deleteScan);
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.isEmpty, isTrue);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.hasFailed, isFalse);
    },
  );

  blocTest<ScanHistoryCubit, ScanHistoryState>(
    'a read failure surfaces as a failure state carrying the Failure, never '
    'as an empty history',
    build: () {
      when(() => getScanHistory()).thenAnswer(
        (_) async => const Left(CacheFailure('scan history unreadable')),
      );
      return ScanHistoryCubit(getScanHistory, deleteScan);
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.hasFailed, isTrue);
      expect(
        cubit.state.failure,
        const CacheFailure('scan history unreadable'),
      );
      expect(cubit.state.isEmpty, isFalse);
    },
  );

  blocTest<ScanHistoryCubit, ScanHistoryState>(
    'deleting a scan re-reads the list rather than trusting a local removal',
    build: () {
      var call = 0;
      when(() => getScanHistory()).thenAnswer((_) async {
        call++;
        return call == 1
            ? Right([newest, middle, oldest])
            : Right([newest, oldest]);
      });
      when(() => deleteScan('s2')).thenAnswer((_) async => const Right(unit));
      return ScanHistoryCubit(getScanHistory, deleteScan);
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.deleteScan('s2');
    },
    verify: (cubit) {
      verify(() => deleteScan('s2')).called(1);
      verify(() => getScanHistory()).called(2);
      expect(cubit.state.scans.map((s) => s.id), ['s3', 's1']);
      expect(cubit.state.status, ScanHistoryStatus.success);
    },
  );

  blocTest<ScanHistoryCubit, ScanHistoryState>(
    'a failed delete reports the failure and does not reload',
    build: () {
      when(
        () => getScanHistory(),
      ).thenAnswer((_) async => Right([newest, middle]));
      when(
        () => deleteScan('s2'),
      ).thenAnswer((_) async => const Left(CacheFailure('delete failed')));
      return ScanHistoryCubit(getScanHistory, deleteScan);
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.deleteScan('s2');
    },
    verify: (cubit) {
      expect(cubit.state.hasFailed, isTrue);
      expect(cubit.state.failure, const CacheFailure('delete failed'));
      verify(() => getScanHistory()).called(1);
    },
  );
}
