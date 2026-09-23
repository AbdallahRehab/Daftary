import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/media/attachment_picker_service.dart';
import '../../domain/repositories/image_preparation_service.dart';
import '../../domain/repositories/text_recognition_service.dart';
import 'scan_capture_state.dart';

/// Drives the first step of a scan: get one image, from the camera or the
/// photo library (FR-001), and refuse to start at all on a device that
/// cannot finish the job (spec Edge Cases, T060).
///
/// Capture itself is delegated to `core/media/AttachmentPickerService`
/// rather than reimplemented here: 008 already owns the "pick an image and
/// copy it somewhere the app controls" contract, and a second copy of it
/// would be a second place for the permission handling to drift
/// (constitution Principle II).
@injectable
class ScanCaptureCubit extends Cubit<ScanCaptureState> {
  ScanCaptureCubit(this._picker, this._imagePreparation, this._textRecognition)
    : super(const ScanCaptureState());

  final AttachmentPickerService _picker;
  final ImagePreparationService _imagePreparation;
  final TextRecognitionService _textRecognition;

  /// Asks both on-device services whether they can run here, before the
  /// user is offered a camera button that would dead-end (T060).
  ///
  /// Both must be available: a device that can crop but cannot recognize
  /// text produces a prepared image and then nothing, which is exactly the
  /// broken flow the Edge Case forbids.
  Future<void> checkAvailability() async {
    emit(
      state.copyWith(
        status: ScanCaptureStatus.checkingAvailability,
        clearFailure: true,
      ),
    );
    final canPrepare = await _imagePreparation.isAvailable();
    final canRecognize = await _textRecognition.isAvailable();
    if (isClosed) return;
    emit(
      state.copyWith(
        status: canPrepare && canRecognize
            ? ScanCaptureStatus.idle
            : ScanCaptureStatus.unsupportedDevice,
        clearFailure: true,
      ),
    );
  }

  /// FR-001: capture a fresh photo of the paper.
  Future<void> captureFromCamera() => _pick(_picker.pickFromCamera);

  /// FR-001: use an existing photo instead — handled identically to a
  /// freshly captured one from here on (User Story 1, scenario 2).
  Future<void> pickFromGallery() => _pick(_picker.pickFromGallery);

  /// Returns the screen to its starting point, e.g. after the user comes
  /// back from the preparation screen and wants a different photo.
  void reset() => emit(const ScanCaptureState());

  Future<void> _pick(
    Future<Either<Failure, String>> Function() pickImage,
  ) async {
    // Nothing to gain from opening a camera whose output this device can
    // never process; the unsupported state stands until the screen is
    // rebuilt and re-checks.
    if (state.isUnsupported) return;

    emit(
      state.copyWith(
        status: ScanCaptureStatus.picking,
        clearFailure: true,
        clearImagePath: true,
      ),
    );
    final result = await pickImage();
    if (isClosed) return;

    result.match(
      (failure) {
        if (failure is PickerCancelledFailure) {
          // Backing out of the picker is a normal outcome, not an error:
          // the screen returns to idle with no message at all.
          emit(const ScanCaptureState());
          return;
        }
        emit(
          state.copyWith(
            status: failure is PermissionDeniedFailure
                ? ScanCaptureStatus.permissionDenied
                : ScanCaptureStatus.failure,
            failure: failure,
            clearImagePath: true,
          ),
        );
      },
      (imagePath) => emit(
        state.copyWith(
          status: ScanCaptureStatus.picked,
          imagePath: imagePath,
          clearFailure: true,
        ),
      ),
    );
  }
}
