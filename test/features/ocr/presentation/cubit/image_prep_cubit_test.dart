import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/media/attachment_picker_service.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_failures.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_scan.dart';
import 'package:daftary/features/ocr/domain/repositories/image_preparation_service.dart';
import 'package:daftary/features/ocr/domain/usecases/cancel_scan.dart';
import 'package:daftary/features/ocr/domain/usecases/run_ocr_extraction.dart';
import 'package:daftary/features/ocr/domain/usecases/set_batch_default_direction.dart';
import 'package:daftary/features/ocr/domain/usecases/start_scan.dart';
import 'package:daftary/features/ocr/presentation/cubit/image_prep_cubit.dart';
import 'package:daftary/features/ocr/presentation/cubit/image_prep_state.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockImagePreparationService extends Mock
    implements ImagePreparationService {}

class MockStartScan extends Mock implements StartScan {}

class MockRunOcrExtraction extends Mock implements RunOcrExtraction {}

class MockSetBatchDefaultDirection extends Mock
    implements SetBatchDefaultDirection {}

class MockCancelScan extends Mock implements CancelScan {}

/// T023/T057 — the crop → enhance → process pipeline (FR-002, FR-005,
/// FR-017) and its cancellation / background-resume behaviour.
void main() {
  late MockImagePreparationService imagePreparation;
  late MockStartScan startScan;
  late MockRunOcrExtraction runOcrExtraction;
  late MockSetBatchDefaultDirection setBatchDefaultDirection;
  late MockCancelScan cancelScan;

  const originalPath = '/app/docs/scan-1.jpg';
  const croppedPath = '/app/docs/scan-1-cropped.jpg';
  const enhancedPath = '/app/docs/scan-1-enhanced.jpg';
  const scanId = 'scan-1';

  final scan = OcrScan(
    id: scanId,
    idempotencyKey: 'key-1',
    sourceImagePath: croppedPath,
    rotationDegrees: 90,
    status: ScanStatus.processing,
    createdAt: DateTime(2026, 9, 22),
  );

  setUpAll(() {
    registerFallbackValue(TransactionDirection.received);
  });

  setUp(() {
    imagePreparation = MockImagePreparationService();
    startScan = MockStartScan();
    runOcrExtraction = MockRunOcrExtraction();
    setBatchDefaultDirection = MockSetBatchDefaultDirection();
    cancelScan = MockCancelScan();

    when(() => imagePreparation.cropAndRotate(any())).thenAnswer(
      (_) async => const Right(
        PreparedImage(
          imagePath: croppedPath,
          rotationDegrees: 90,
          cropBounds: '0,0,100,100',
        ),
      ),
    );
    when(
      () => imagePreparation.enhance(any()),
    ).thenAnswer((_) async => const Right(enhancedPath));
    when(
      () => startScan(
        sourceImagePath: any(named: 'sourceImagePath'),
        rotationDegrees: any(named: 'rotationDegrees'),
        cropBounds: any(named: 'cropBounds'),
      ),
    ).thenAnswer((_) async => Right(scan));
    when(() => runOcrExtraction(any())).thenAnswer(
      (_) async => Right(scan.copyWith(status: ScanStatus.needsReview)),
    );
    when(
      () => setBatchDefaultDirection(
        scanId: any(named: 'scanId'),
        direction: any(named: 'direction'),
      ),
    ).thenAnswer((_) async => Right(scan));
    when(() => cancelScan(any())).thenAnswer((_) async => const Right(unit));
  });

  ImagePrepCubit build() => ImagePrepCubit(
    imagePreparation,
    startScan,
    runOcrExtraction,
    setBatchDefaultDirection,
    cancelScan,
  );

  ImagePrepCubit initialized() => build()..initialize(originalPath);

  group('crop and enhance (FR-002)', () {
    blocTest<ImagePrepCubit, ImagePrepState>(
      'crop replaces the working image and keeps the original',
      build: initialized,
      act: (cubit) => cubit.crop(),
      expect: () => const [
        ImagePrepState(
          status: ImagePrepStatus.cropping,
          originalImagePath: originalPath,
          imagePath: originalPath,
        ),
        ImagePrepState(
          originalImagePath: originalPath,
          imagePath: croppedPath,
          rotationDegrees: 90,
          cropBounds: '0,0,100,100',
          hasCropped: true,
        ),
      ],
    );

    blocTest<ImagePrepCubit, ImagePrepState>(
      'a cancelled crop UI returns silently to idle',
      build: initialized,
      setUp: () {
        when(() => imagePreparation.cropAndRotate(any())).thenAnswer(
          (_) async => const Left(PickerCancelledFailure('cancelled')),
        );
      },
      act: (cubit) => cubit.crop(),
      expect: () => const [
        ImagePrepState(
          status: ImagePrepStatus.cropping,
          originalImagePath: originalPath,
          imagePath: originalPath,
        ),
        ImagePrepState(
          originalImagePath: originalPath,
          imagePath: originalPath,
        ),
      ],
    );

    blocTest<ImagePrepCubit, ImagePrepState>(
      'a redo of the crop re-crops the ORIGINAL, never the last crop, and '
      'needs no new capture',
      build: initialized,
      act: (cubit) async {
        await cubit.crop();
        await cubit.crop();
      },
      verify: (_) {
        verify(() => imagePreparation.cropAndRotate(originalPath)).called(2);
        verifyNever(() => imagePreparation.cropAndRotate(croppedPath));
      },
    );

    blocTest<ImagePrepCubit, ImagePrepState>(
      'enhance runs on the cropped image and clears any stale scan',
      build: initialized,
      act: (cubit) async {
        await cubit.crop();
        await cubit.enhance();
      },
      verify: (cubit) {
        verify(() => imagePreparation.enhance(croppedPath)).called(1);
        expect(cubit.state.imagePath, enhancedPath);
        expect(cubit.state.isEnhanced, isTrue);
      },
    );
  });

  group('process (FR-003, FR-005)', () {
    blocTest<ImagePrepCubit, ImagePrepState>(
      'crop → enhance → process ends ready for review with a scan id',
      build: initialized,
      act: (cubit) async {
        await cubit.crop();
        await cubit.enhance();
        await cubit.process();
      },
      verify: (cubit) {
        verify(
          () => startScan(
            sourceImagePath: enhancedPath,
            rotationDegrees: 90,
            cropBounds: '0,0,100,100',
          ),
        ).called(1);
        verify(() => runOcrExtraction(scanId)).called(1);
        expect(cubit.state.status, ImagePrepStatus.readyForReview);
        expect(cubit.state.scanId, scanId);
      },
    );

    blocTest<ImagePrepCubit, ImagePrepState>(
      'the batch default chosen before processing is persisted once the '
      'scan exists (FR-005)',
      build: initialized,
      act: (cubit) async {
        await cubit.setDefaultDirection(TransactionDirection.received);
        await cubit.process();
      },
      verify: (_) {
        verify(
          () => setBatchDefaultDirection(
            scanId: scanId,
            direction: TransactionDirection.received,
          ),
        ).called(1);
      },
    );

    blocTest<ImagePrepCubit, ImagePrepState>(
      'a parse failure surfaces the typed failure, not a spinner',
      build: initialized,
      setUp: () {
        when(() => runOcrExtraction(any())).thenAnswer(
          (_) async => const Left(NoCandidatesParsedFailure('no candidates')),
        );
      },
      act: (cubit) => cubit.process(),
      verify: (cubit) {
        expect(cubit.state.status, ImagePrepStatus.failure);
        expect(cubit.state.failure, isA<NoCandidatesParsedFailure>());
      },
    );

    blocTest<ImagePrepCubit, ImagePrepState>(
      'an unexpected throw ends in interrupted, never a stuck spinner',
      build: initialized,
      setUp: () {
        when(
          () => runOcrExtraction(any()),
        ).thenThrow(StateError('platform channel died'));
      },
      act: (cubit) => cubit.process(),
      verify: (cubit) =>
          expect(cubit.state.status, ImagePrepStatus.interrupted),
    );
  });

  group('cancellation and lifecycle (FR-017, T057/T059)', () {
    test('cancel leaves the spinner at once and cleans the scan up', () async {
      final extraction = Completer<Either<Failure, OcrScan>>();
      when(() => runOcrExtraction(any())).thenAnswer((_) => extraction.future);

      final cubit = initialized();
      final pending = cubit.process();
      // Let `startScan` resolve so there is a real scan to clean up.
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.isProcessing, isTrue);

      cubit.cancel();
      expect(cubit.state.status, ImagePrepStatus.idle);
      expect(cubit.state.scanId, isNull);

      extraction.complete(Right(scan));
      await pending;

      verify(() => cancelScan(scanId)).called(1);
      expect(cubit.state.status, ImagePrepStatus.idle);
      expect(cubit.state.isReadyForReview, isFalse);
      await cubit.close();
    });

    test('a resume mid-processing keeps the honest "still working" '
        'state', () async {
      final extraction = Completer<Either<Failure, OcrScan>>();
      when(() => runOcrExtraction(any())).thenAnswer((_) => extraction.future);

      final cubit = initialized();
      final pending = cubit.process();
      await Future<void>.delayed(Duration.zero);

      cubit.onResumed();
      expect(cubit.state.status, ImagePrepStatus.processing);

      extraction.complete(Right(scan));
      await pending;
      expect(cubit.state.status, ImagePrepStatus.readyForReview);
      await cubit.close();
    });

    test('nothing is emitted after close when the app is backgrounded '
        'mid-processing', () async {
      final extraction = Completer<Either<Failure, OcrScan>>();
      when(() => runOcrExtraction(any())).thenAnswer((_) => extraction.future);

      final cubit = initialized();
      final emitted = <ImagePrepState>[];
      final subscription = cubit.stream.listen(emitted.add);

      final pending = cubit.process();
      await Future<void>.delayed(Duration.zero);
      await cubit.close();

      extraction.complete(Right(scan));
      await pending;
      cubit.onResumed();

      expect(
        emitted.where((s) => s.status == ImagePrepStatus.readyForReview),
        isEmpty,
      );
      await subscription.cancel();
    });
  });
}
