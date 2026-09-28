import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/data_privacy/domain/entities/export_result.dart';
import 'package:daftary/features/data_privacy/domain/services/share_service.dart';
import 'package:daftary/features/data_privacy/domain/usecases/export_user_data.dart';
import 'package:daftary/features/data_privacy/presentation/cubit/export_cubit.dart';
import 'package:daftary/features/data_privacy/presentation/cubit/export_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockExportUserData extends Mock implements ExportUserData {}

class MockShareService extends Mock implements ShareService {}

/// T020 — `ExportCubit`: idle → generating → ready on success, error with
/// retry on failure (FR-009–FR-011), and a dismissed share sheet is never
/// an error (spec Edge Cases).
void main() {
  late MockExportUserData exportUserData;
  late MockShareService shareService;

  final export = ExportResult(
    filePath: '/tmp/daftary-export.csv',
    generatedAt: DateTime(2026, 9, 24),
    sectionCounts: const {'People': 2, 'Transactions': 3},
  );
  final ready = ExportState(status: ExportStatus.ready, result: export);
  const generating = ExportState(status: ExportStatus.generating);
  const failed = ExportState(status: ExportStatus.error, errorMessage: 'disk');

  setUp(() {
    exportUserData = MockExportUserData();
    shareService = MockShareService();
  });

  ExportCubit build() => ExportCubit(exportUserData, shareService);

  void stubShare(Either<Failure, Unit> result) {
    when(
      () => shareService.shareFile(
        filePath: any(named: 'filePath'),
        subject: any(named: 'subject'),
      ),
    ).thenAnswer((_) async => result);
  }

  test('starts idle', () {
    expect(build().state, const ExportState());
  });

  group('generate', () {
    blocTest<ExportCubit, ExportState>(
      'idle → generating → ready, holding the result',
      setUp: () =>
          when(() => exportUserData()).thenAnswer((_) async => Right(export)),
      build: build,
      act: (cubit) => cubit.generate(),
      expect: () => [generating, ready],
    );

    blocTest<ExportCubit, ExportState>(
      'idle → generating → error on failure (FR-011)',
      setUp: () => when(
        () => exportUserData(),
      ).thenAnswer((_) async => const Left(CacheFailure('disk'))),
      build: build,
      act: (cubit) => cubit.generate(),
      expect: () => [generating, failed],
    );

    test('a second tap while generating runs the export only once', () async {
      final pending = Completer<Either<Failure, ExportResult>>();
      when(() => exportUserData()).thenAnswer((_) => pending.future);
      final cubit = build();
      addTearDown(cubit.close);

      final first = cubit.generate();
      await cubit.generate();
      pending.complete(Right(export));
      await first;

      verify(() => exportUserData()).called(1);
      expect(cubit.state, ready);
    });

    blocTest<ExportCubit, ExportState>(
      'regenerating from ready starts over cleanly',
      setUp: () =>
          when(() => exportUserData()).thenAnswer((_) async => Right(export)),
      build: build,
      seed: () => ready.copyWith(shareFailed: true),
      act: (cubit) => cubit.generate(),
      expect: () => [generating, ready],
    );
  });

  group('retry', () {
    blocTest<ExportCubit, ExportState>(
      're-runs the export cleanly from the error state',
      setUp: () =>
          when(() => exportUserData()).thenAnswer((_) async => Right(export)),
      build: build,
      seed: () => failed,
      act: (cubit) => cubit.retry(),
      expect: () => [generating, ready],
      verify: (_) => verify(() => exportUserData()).called(1),
    );
  });

  group('share', () {
    blocTest<ExportCubit, ExportState>(
      'presents the sheet for the generated file and returns to ready',
      setUp: () => stubShare(const Right(unit)),
      build: build,
      seed: () => ready,
      act: (cubit) => cubit.share(subject: 'Export'),
      expect: () => [ready.copyWith(isSharing: true), ready],
      verify: (_) => verify(
        () => shareService.shareFile(
          filePath: export.filePath,
          subject: 'Export',
        ),
      ).called(1),
    );

    // The service maps a dismissed sheet to Right(unit), so this is the same
    // path as above — asserted separately because it is the spec's named
    // edge case: back to ready, never an error.
    blocTest<ExportCubit, ExportState>(
      'a dismissed sheet leaves the screen ready, not in error',
      setUp: () => stubShare(const Right(unit)),
      build: build,
      seed: () => ready,
      act: (cubit) => cubit.share(),
      expect: () => [ready.copyWith(isSharing: true), ready],
    );

    blocTest<ExportCubit, ExportState>(
      'a sheet that cannot open flags shareFailed but keeps the export ready',
      setUp: () => stubShare(const Left(ShareFailure('no sheet'))),
      build: build,
      seed: () => ready,
      act: (cubit) => cubit.share(),
      expect: () => [
        ready.copyWith(isSharing: true),
        ready.copyWith(shareFailed: true),
      ],
    );

    blocTest<ExportCubit, ExportState>(
      'does nothing before an export is ready',
      build: build,
      act: (cubit) => cubit.share(),
      expect: () => <ExportState>[],
      verify: (_) => verifyZeroInteractions(shareService),
    );

    blocTest<ExportCubit, ExportState>(
      'does nothing while the sheet is already being presented',
      build: build,
      seed: () => ready.copyWith(isSharing: true),
      act: (cubit) => cubit.share(),
      expect: () => <ExportState>[],
      verify: (_) => verifyZeroInteractions(shareService),
    );
  });
}
