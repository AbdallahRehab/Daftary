import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_scan.dart';
import 'package:daftary/features/ocr/domain/usecases/delete_scan.dart';
import 'package:daftary/features/ocr/domain/usecases/watch_scan_history.dart';
import 'package:daftary/features/ocr/presentation/cubit/scan_history_cubit.dart';
import 'package:daftary/features/ocr/presentation/cubit/scan_history_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/watch_stubs.dart';
import '../../helpers/ocr_watch_stubs.dart';

class MockDeleteScan extends Mock implements DeleteScan {}

/// T062/T066 — scan history (User Story 5, FR-018, FR-023).
void main() {
  late MockOcrRepository repository;
  late FakeTableChanges changes;
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
    repository = MockOcrRepository();
    changes = FakeTableChanges();
    stubOcrWatches(repository, changes);
    deleteScan = MockDeleteScan();
  });

  tearDown(() => changes.close());

  ScanHistoryCubit build() =>
      ScanHistoryCubit(WatchScanHistory(repository), deleteScan);

  blocTest<ScanHistoryCubit, ScanHistoryState>(
    'loads scans in the order the repository returned them — newest first, '
    'never re-sorted here (FR-018)',
    build: () {
      when(
        repository.getScanHistory,
      ).thenAnswer((_) async => Right([newest, middle, oldest]));
      return build();
    },
    act: (cubit) => cubit.subscribe(),
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
      when(repository.getScanHistory).thenAnswer((_) async => const Right([]));
      return build();
    },
    act: (cubit) => cubit.subscribe(),
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
      when(repository.getScanHistory).thenAnswer(
        (_) async => const Left(CacheFailure('scan history unreadable')),
      );
      return build();
    },
    act: (cubit) => cubit.subscribe(),
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
    'deleting a scan lets the live list drop it rather than trusting a '
    'local removal (021 FR-031)',
    build: () {
      var deleted = false;
      when(repository.getScanHistory).thenAnswer(
        (_) async =>
            deleted ? Right([newest, oldest]) : Right([newest, middle, oldest]),
      );
      when(() => deleteScan('s2')).thenAnswer((_) async {
        // The cascade writes `ocr_scans`; only the notification follows.
        deleted = true;
        changes.notify();
        return const Right(unit);
      });
      return build();
    },
    act: (cubit) async {
      await cubit.subscribe();
      await cubit.deleteScan('s2');
    },
    wait: const Duration(milliseconds: 10),
    verify: (cubit) {
      verify(() => deleteScan('s2')).called(1);
      verify(repository.getScanHistory).called(2);
      expect(cubit.state.scans.map((s) => s.id), ['s3', 's1']);
      expect(cubit.state.status, ScanHistoryStatus.success);
    },
  );

  blocTest<ScanHistoryCubit, ScanHistoryState>(
    'a failed delete reports the failure and does not re-read',
    build: () {
      when(
        repository.getScanHistory,
      ).thenAnswer((_) async => Right([newest, middle]));
      when(
        () => deleteScan('s2'),
      ).thenAnswer((_) async => const Left(CacheFailure('delete failed')));
      return build();
    },
    act: (cubit) async {
      await cubit.subscribe();
      await cubit.deleteScan('s2');
    },
    verify: (cubit) {
      expect(cubit.state.hasFailed, isTrue);
      expect(cubit.state.failure, const CacheFailure('delete failed'));
      verify(repository.getScanHistory).called(1);
    },
  );

  test('a scan finished or deleted on another screen updates the open '
      'history with no reload (021 FR-031)', () async {
    var scans = [newest];
    when(repository.getScanHistory).thenAnswer((_) async => Right(scans));
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.subscribe();
    expect(cubit.state.scans.map((s) => s.id), ['s3']);

    scans = [newest, middle];
    changes.notify();
    await pumpEventQueue();
    expect(cubit.state.scans.map((s) => s.id), ['s3', 's2']);

    scans = [middle];
    changes.notify();
    await pumpEventQueue();
    expect(cubit.state.scans.map((s) => s.id), ['s2']);
  });

  test('close cancels the subscription', () async {
    when(repository.getScanHistory).thenAnswer((_) async => Right([newest]));
    final cubit = build();
    await cubit.subscribe();
    await cubit.close();

    changes.notify();
    await pumpEventQueue();
    verify(repository.getScanHistory).called(1);
  });
}
