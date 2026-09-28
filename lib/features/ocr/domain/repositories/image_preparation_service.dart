import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

/// The result of the crop/rotate step: a new image file the app owns, plus
/// the transform that produced it, kept so a past scan stays explainable
/// (009 FR-002).
class PreparedImage extends Equatable {
  const PreparedImage({
    required this.imagePath,
    required this.rotationDegrees,
    this.cropBounds,
  });

  final String imagePath;
  final int rotationDegrees;

  /// Serialized crop rectangle, `null` when the user cropped nothing.
  final String? cropBounds;

  @override
  List<Object?> get props => [imagePath, rotationDegrees, cropBounds];
}

/// Turns a raw captured photo into something worth handing to the
/// recognizer: cropped and rotated by the user, then evened out.
///
/// A Domain-facing interface with the plugin hidden behind it, for two
/// reasons: use cases and Cubits can be tested with a fake instead of a
/// real crop UI (constitution Principle XVI), and the crop implementation
/// can be swapped without anything above Data noticing.
///
/// Deliberately feature-local rather than promoted to `core/` — only this
/// feature needs it today (constitution Principle II, plan.md Structure
/// Decision).
abstract class ImagePreparationService {
  /// Opens the interactive crop/rotate UI over [imagePath] and returns the
  /// resulting app-owned image (009 FR-002).
  ///
  /// Returns [ImageProcessingFailure] when the step could not produce a
  /// usable image, and [PickerCancelledFailure] when the user simply backed
  /// out — a normal outcome the caller should handle silently, not an
  /// error worth a message.
  Future<Either<Failure, PreparedImage>> cropAndRotate(String imagePath);

  /// Applies the deterministic brightness/contrast pass (research.md
  /// Decision 2) and returns the path of the enhanced copy.
  ///
  /// Deterministic by contract: the same input bytes always produce the
  /// same output bytes. Nothing here is ML-based or adaptive, so a scan's
  /// result can always be explained and re-derived.
  Future<Either<Failure, String>> enhance(String imagePath);

  /// Whether this device can run the preparation step at all. `false`
  /// drives the "not supported on this device" state that points the user
  /// at manual entry instead of a retry that can never work (Edge Cases).
  Future<bool> isAvailable();
}
