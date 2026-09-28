import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../transactions/domain/entities/money_transaction.dart';

/// Where the crop/enhance/process step is (FR-002, FR-005, FR-017).
///
/// [interrupted] is separate from [failure] on purpose: it means the
/// pipeline stopped without telling us why (a crash, a kill while the app
/// was backgrounded), so the honest thing to show is "that didn't finish —
/// try again", not a made-up reason and certainly not a spinner that never
/// ends (User Story 4, T059).
enum ImagePrepStatus {
  idle,
  cropping,
  enhancing,
  processing,
  readyForReview,
  interrupted,
  failure,
}

/// Immutable state for `ImagePrepCubit` (constitution Principle IV).
class ImagePrepState extends Equatable {
  const ImagePrepState({
    this.status = ImagePrepStatus.idle,
    this.originalImagePath = '',
    this.imagePath = '',
    this.rotationDegrees = 0,
    this.cropBounds,
    this.isEnhanced = false,
    this.hasCropped = false,
    this.scanId,
    this.defaultDirection,
    this.failure,
  });

  final ImagePrepStatus status;

  /// The image as it came out of capture. Every crop starts from this file
  /// rather than from the last crop's output, so redoing the crop widens
  /// the selection again instead of cropping a crop (FR-002).
  final String originalImagePath;

  /// The image as it currently stands after crop/rotate and enhancement —
  /// the file that will be handed to `StartScan`.
  final String imagePath;
  final int rotationDegrees;

  /// Serialized crop rectangle, kept so a past scan stays explainable.
  final String? cropBounds;
  final bool isEnhanced;
  final bool hasCropped;

  /// Set once the scan record exists. Also what the review route is opened
  /// with.
  final String? scanId;

  /// The batch-level fallback direction (FR-005). Chosen here, before
  /// review, and persisted as soon as there is a scan to persist it
  /// against.
  final TransactionDirection? defaultDirection;
  final Failure? failure;

  bool get isBusy =>
      status == ImagePrepStatus.cropping ||
      status == ImagePrepStatus.enhancing ||
      status == ImagePrepStatus.processing;
  bool get isProcessing => status == ImagePrepStatus.processing;
  bool get isReadyForReview => status == ImagePrepStatus.readyForReview;

  ImagePrepState copyWith({
    ImagePrepStatus? status,
    String? originalImagePath,
    String? imagePath,
    int? rotationDegrees,
    String? cropBounds,
    bool clearCropBounds = false,
    bool? isEnhanced,
    bool? hasCropped,
    String? scanId,
    bool clearScanId = false,
    TransactionDirection? defaultDirection,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ImagePrepState(
      status: status ?? this.status,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      imagePath: imagePath ?? this.imagePath,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      cropBounds: clearCropBounds ? null : (cropBounds ?? this.cropBounds),
      isEnhanced: isEnhanced ?? this.isEnhanced,
      hasCropped: hasCropped ?? this.hasCropped,
      scanId: clearScanId ? null : (scanId ?? this.scanId),
      defaultDirection: defaultDirection ?? this.defaultDirection,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    originalImagePath,
    imagePath,
    rotationDegrees,
    cropBounds,
    isEnhanced,
    hasCropped,
    scanId,
    defaultDirection,
    failure,
  ];
}
