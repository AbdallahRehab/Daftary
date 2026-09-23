import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/media/attachment_picker_service.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../domain/entities/ocr_scan.dart';
import '../../domain/repositories/image_preparation_service.dart';
import '../../domain/usecases/cancel_scan.dart';
import '../../domain/usecases/run_ocr_extraction.dart';
import '../../domain/usecases/set_batch_default_direction.dart';
import '../../domain/usecases/start_scan.dart';
import 'image_prep_state.dart';

/// Drives everything between "we have a photo" and "there is something to
/// review": crop/rotate, enhance, then start the scan and run extraction
/// (FR-002, FR-003, FR-005, FR-017).
///
/// Crop and enhance stay separate, re-runnable steps rather than one
/// pipeline call, because FR-002 requires redoing them *without* going back
/// to the camera — the common recovery when a first scan reads badly
/// (User Story 4).
///
/// Nothing here can create money: the only writes are the scan record and
/// its candidate entries, and every path to a `MoneyTransaction` runs
/// through the review screen's confirm action (constitution Principle X).
@injectable
class ImagePrepCubit extends Cubit<ImagePrepState> {
  ImagePrepCubit(
    this._imagePreparation,
    this._startScan,
    this._runOcrExtraction,
    this._setBatchDefaultDirection,
    this._cancelScan,
  ) : super(const ImagePrepState());

  final ImagePreparationService _imagePreparation;
  final StartScan _startScan;
  final RunOcrExtraction _runOcrExtraction;
  final SetBatchDefaultDirection _setBatchDefaultDirection;
  final CancelScan _cancelScan;

  /// Set by [cancel] and read after every `await` in [process]. A flag
  /// rather than a real cancellation token because neither the recognizer
  /// nor the database exposes one: what we *can* honestly guarantee is
  /// that a cancelled run stops driving the UI and leaves no half-alive
  /// scan behind (FR-017).
  bool _cancelRequested = false;

  /// Whether a [process] run is still awaiting something. Distinguishes
  /// "backgrounded mid-processing and still working" from "processing
  /// state with nothing behind it", which is the only case where showing a
  /// spinner would be a lie (T059).
  bool _processingInFlight = false;

  /// Opens the preparation step over the freshly captured or picked image.
  void initialize(String imagePath) {
    emit(ImagePrepState(originalImagePath: imagePath, imagePath: imagePath));
  }

  /// FR-002: interactive crop/rotate.
  ///
  /// Always re-crops [ImagePrepState.originalImagePath], never the last
  /// result, so a user who cropped too tightly can widen the selection
  /// again instead of being trapped by their first attempt.
  Future<void> crop() async {
    if (state.isBusy || state.originalImagePath.isEmpty) return;
    emit(state.copyWith(status: ImagePrepStatus.cropping, clearFailure: true));

    final result = await _imagePreparation.cropAndRotate(
      state.originalImagePath,
    );
    if (isClosed) return;

    result.match(
      (failure) {
        // Backing out of the crop UI is a normal outcome: the screen
        // returns to where it was, with no error message.
        if (failure is PickerCancelledFailure) {
          emit(state.copyWith(status: ImagePrepStatus.idle));
          return;
        }
        emit(state.copyWith(status: ImagePrepStatus.failure, failure: failure));
      },
      (prepared) => emit(
        state.copyWith(
          status: ImagePrepStatus.idle,
          imagePath: prepared.imagePath,
          rotationDegrees: prepared.rotationDegrees,
          cropBounds: prepared.cropBounds,
          clearCropBounds: prepared.cropBounds == null,
          // The previous enhancement was applied to the previous crop's
          // output, which no longer exists in this pipeline.
          isEnhanced: false,
          hasCropped: true,
          clearScanId: true,
          clearFailure: true,
        ),
      ),
    );
  }

  /// FR-002: the deterministic brightness/contrast pass, applied to the
  /// current (cropped, if the user cropped) image.
  Future<void> enhance() async {
    if (state.isBusy || state.imagePath.isEmpty) return;
    emit(state.copyWith(status: ImagePrepStatus.enhancing, clearFailure: true));

    final result = await _imagePreparation.enhance(state.imagePath);
    if (isClosed) return;

    result.match(
      (failure) => emit(
        state.copyWith(status: ImagePrepStatus.failure, failure: failure),
      ),
      (enhancedPath) => emit(
        state.copyWith(
          status: ImagePrepStatus.idle,
          imagePath: enhancedPath,
          isEnhanced: true,
          clearScanId: true,
          clearFailure: true,
        ),
      ),
    );
  }

  /// Records the batch-level default direction (FR-005).
  ///
  /// Held in state before the scan exists and written through as soon as
  /// it does, so the choice survives whichever order the user does things
  /// in — set the toggle first, or process first and set it after.
  Future<void> setDefaultDirection(TransactionDirection direction) async {
    emit(state.copyWith(defaultDirection: direction, clearFailure: true));
    final scanId = state.scanId;
    if (scanId == null) return;

    final result = await _setBatchDefaultDirection(
      scanId: scanId,
      direction: direction,
    );
    if (isClosed) return;
    result.match(
      (failure) => emit(
        state.copyWith(status: ImagePrepStatus.failure, failure: failure),
      ),
      (_) {},
    );
  }

  /// Starts the scan and runs extraction over the prepared image
  /// (FR-003). Leaves the caller with a `scanId` to open the mandatory
  /// review screen with — never with a transaction.
  Future<void> process() async {
    if (state.isBusy || state.imagePath.isEmpty) return;

    _cancelRequested = false;
    _processingInFlight = true;
    emit(
      state.copyWith(
        status: ImagePrepStatus.processing,
        clearScanId: true,
        clearFailure: true,
      ),
    );

    try {
      final started = await _startScan(
        sourceImagePath: state.imagePath,
        rotationDegrees: state.rotationDegrees,
        cropBounds: state.cropBounds,
      );
      if (isClosed) return;

      final OcrScan? scan = started.match((failure) {
        emit(state.copyWith(status: ImagePrepStatus.failure, failure: failure));
        return null;
      }, (scan) => scan);
      if (scan == null) return;
      if (await _abandonIfCancelled(scan.id)) return;

      emit(state.copyWith(scanId: scan.id));

      // The batch default was chosen before there was a scan to hang it
      // on; now there is one (FR-005).
      final pendingDirection = state.defaultDirection;
      if (pendingDirection != null) {
        await _setBatchDefaultDirection(
          scanId: scan.id,
          direction: pendingDirection,
        );
        if (isClosed) return;
        if (await _abandonIfCancelled(scan.id)) return;
      }

      final extracted = await _runOcrExtraction(scan.id);
      if (isClosed) return;
      if (await _abandonIfCancelled(scan.id)) return;

      extracted.match(
        (failure) => emit(
          state.copyWith(status: ImagePrepStatus.failure, failure: failure),
        ),
        (_) => emit(
          state.copyWith(
            status: ImagePrepStatus.readyForReview,
            clearFailure: true,
          ),
        ),
      );
    } on Object {
      // An unexpected throw from the pipeline is the one case where we
      // genuinely do not know what happened. Say so and offer a retry
      // rather than inventing a reason or leaving the spinner up.
      if (isClosed) return;
      emit(state.copyWith(status: ImagePrepStatus.interrupted));
    } finally {
      _processingInFlight = false;
    }
  }

  /// FR-017: leave the in-progress state immediately.
  ///
  /// The UI is released right away — a cancel the user has to wait for is
  /// not a cancel — while the still-running step tidies up the scan record
  /// when it eventually returns.
  void cancel() {
    if (!state.isProcessing) return;
    _cancelRequested = true;
    emit(
      state.copyWith(
        status: ImagePrepStatus.idle,
        clearScanId: true,
        clearFailure: true,
      ),
    );
  }

  /// Called when the screen comes back to the foreground (T059).
  ///
  /// Either the run finished while we were away — in which case the state
  /// already says so — or it is genuinely still going, or there is nothing
  /// behind the spinner at all, which is reported as [ImagePrepStatus
  /// .interrupted] with a retry rather than left spinning forever.
  void onResumed() {
    if (isClosed || !state.isProcessing) return;
    if (_processingInFlight) return;
    emit(state.copyWith(status: ImagePrepStatus.interrupted));
  }

  /// Cleans up after a cancellation that landed mid-flight. Returns
  /// whether the run should stop here.
  Future<bool> _abandonIfCancelled(String scanId) async {
    if (!_cancelRequested) return false;
    await _cancelScan(scanId);
    if (isClosed) return true;
    emit(
      state.copyWith(
        status: ImagePrepStatus.idle,
        clearScanId: true,
        clearFailure: true,
      ),
    );
    return true;
  }
}
