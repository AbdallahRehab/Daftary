import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/media/attachment_picker_service.dart';
import 'package:daftary/features/ocr/domain/repositories/image_preparation_service.dart';
import 'package:daftary/features/ocr/domain/repositories/text_recognition_service.dart';
import 'package:daftary/features/ocr/presentation/cubit/scan_capture_cubit.dart';
import 'package:daftary/features/ocr/presentation/cubit/scan_capture_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAttachmentPickerService extends Mock
    implements AttachmentPickerService {}

class MockImagePreparationService extends Mock
    implements ImagePreparationService {}

class MockTextRecognitionService extends Mock
    implements TextRecognitionService {}

/// T023/T060 — the capture entry point (FR-001, FR-016, and the
/// unsupported-device Edge Case).
void main() {
  late MockAttachmentPickerService picker;
  late MockImagePreparationService imagePreparation;
  late MockTextRecognitionService textRecognition;

  const imagePath = '/app/docs/scan-1.jpg';

  setUp(() {
    picker = MockAttachmentPickerService();
    imagePreparation = MockImagePreparationService();
    textRecognition = MockTextRecognitionService();
    when(() => imagePreparation.isAvailable()).thenAnswer((_) async => true);
    when(() => textRecognition.isAvailable()).thenAnswer((_) async => true);
  });

  ScanCaptureCubit build() =>
      ScanCaptureCubit(picker, imagePreparation, textRecognition);

  group('availability (T060)', () {
    blocTest<ScanCaptureCubit, ScanCaptureState>(
      'settles on idle when both on-device services are available',
      build: build,
      act: (cubit) => cubit.checkAvailability(),
      expect: () => const [
        ScanCaptureState(status: ScanCaptureStatus.checkingAvailability),
        ScanCaptureState(),
      ],
    );

    blocTest<ScanCaptureCubit, ScanCaptureState>(
      'reports an unsupported device when recognition is unavailable',
      build: build,
      setUp: () {
        when(
          () => textRecognition.isAvailable(),
        ).thenAnswer((_) async => false);
      },
      act: (cubit) => cubit.checkAvailability(),
      expect: () => const [
        ScanCaptureState(status: ScanCaptureStatus.checkingAvailability),
        ScanCaptureState(status: ScanCaptureStatus.unsupportedDevice),
      ],
    );

    blocTest<ScanCaptureCubit, ScanCaptureState>(
      'reports an unsupported device when preparation is unavailable',
      build: build,
      setUp: () {
        when(
          () => imagePreparation.isAvailable(),
        ).thenAnswer((_) async => false);
      },
      act: (cubit) => cubit.checkAvailability(),
      expect: () => const [
        ScanCaptureState(status: ScanCaptureStatus.checkingAvailability),
        ScanCaptureState(status: ScanCaptureStatus.unsupportedDevice),
      ],
    );

    blocTest<ScanCaptureCubit, ScanCaptureState>(
      'never opens the camera on an unsupported device',
      build: build,
      setUp: () {
        when(
          () => textRecognition.isAvailable(),
        ).thenAnswer((_) async => false);
      },
      act: (cubit) async {
        await cubit.checkAvailability();
        await cubit.captureFromCamera();
      },
      expect: () => const [
        ScanCaptureState(status: ScanCaptureStatus.checkingAvailability),
        ScanCaptureState(status: ScanCaptureStatus.unsupportedDevice),
      ],
      verify: (_) => verifyNever(() => picker.pickFromCamera()),
    );
  });

  group('capture or upload (FR-001)', () {
    blocTest<ScanCaptureCubit, ScanCaptureState>(
      'camera capture ends on picked with the app-owned path',
      build: build,
      setUp: () {
        when(
          () => picker.pickFromCamera(),
        ).thenAnswer((_) async => const Right(imagePath));
      },
      act: (cubit) => cubit.captureFromCamera(),
      expect: () => const [
        ScanCaptureState(status: ScanCaptureStatus.picking),
        ScanCaptureState(
          status: ScanCaptureStatus.picked,
          imagePath: imagePath,
        ),
      ],
    );

    blocTest<ScanCaptureCubit, ScanCaptureState>(
      'a gallery pick is handled identically to a capture',
      build: build,
      setUp: () {
        when(
          () => picker.pickFromGallery(),
        ).thenAnswer((_) async => const Right(imagePath));
      },
      act: (cubit) => cubit.pickFromGallery(),
      expect: () => const [
        ScanCaptureState(status: ScanCaptureStatus.picking),
        ScanCaptureState(
          status: ScanCaptureStatus.picked,
          imagePath: imagePath,
        ),
      ],
      verify: (_) => verifyNever(() => picker.pickFromCamera()),
    );
  });

  group('failure handling (FR-016)', () {
    blocTest<ScanCaptureCubit, ScanCaptureState>(
      'a cancelled picker returns to idle with no error at all',
      build: build,
      setUp: () {
        when(() => picker.pickFromCamera()).thenAnswer(
          (_) async => const Left(PickerCancelledFailure('cancelled')),
        );
      },
      act: (cubit) => cubit.captureFromCamera(),
      expect: () => const [
        ScanCaptureState(status: ScanCaptureStatus.picking),
        ScanCaptureState(),
      ],
    );

    blocTest<ScanCaptureCubit, ScanCaptureState>(
      'a denied permission surfaces its own explainable state',
      build: build,
      setUp: () {
        when(() => picker.pickFromCamera()).thenAnswer(
          (_) async => const Left(PermissionDeniedFailure('camera denied')),
        );
      },
      act: (cubit) => cubit.captureFromCamera(),
      expect: () => const [
        ScanCaptureState(status: ScanCaptureStatus.picking),
        ScanCaptureState(
          status: ScanCaptureStatus.permissionDenied,
          failure: PermissionDeniedFailure('camera denied'),
        ),
      ],
    );

    blocTest<ScanCaptureCubit, ScanCaptureState>(
      'any other failure lands in the generic failure state',
      build: build,
      setUp: () {
        when(
          () => picker.pickFromGallery(),
        ).thenAnswer((_) async => const Left(UnknownFailure('boom')));
      },
      act: (cubit) => cubit.pickFromGallery(),
      expect: () => const [
        ScanCaptureState(status: ScanCaptureStatus.picking),
        ScanCaptureState(
          status: ScanCaptureStatus.failure,
          failure: UnknownFailure('boom'),
        ),
      ],
    );
  });

  test('emits nothing once closed mid-pick', () async {
    final completer = Completer<Either<Failure, String>>();
    when(() => picker.pickFromCamera()).thenAnswer((_) => completer.future);

    final cubit = build();
    final emitted = <ScanCaptureState>[];
    final subscription = cubit.stream.listen(emitted.add);

    final pending = cubit.captureFromCamera();
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
    completer.complete(const Right<Failure, String>(imagePath));
    await pending;

    expect(emitted.where((s) => s.status == ScanCaptureStatus.picked), isEmpty);
    await subscription.cancel();
  });
}
