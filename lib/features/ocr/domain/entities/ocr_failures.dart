import '../../../../core/error/failure.dart';

/// Base type for the failures only this feature can produce. Grouped under
/// one parent so a caller can catch "the scan pipeline could not give me
/// anything usable" without enumerating every reason, while the UI can
/// still switch on the specific subtype to offer the right recovery action
/// (009 FR-004, User Story 4).
abstract class OcrFailure extends Failure {
  const OcrFailure(super.message);
}

/// Text recognition ran and found no text at all in the image — a blurry
/// photo, a blank page, a picture of something that is not a document.
/// Recovery: retake the photo.
class NoTextRecognizedFailure extends OcrFailure {
  const NoTextRecognizedFailure(super.message);
}

/// Text was recognized, but none of it looked like a name/amount line, so
/// the parser produced zero candidate entries — a page of prose, a receipt
/// in an unexpected shape, a heavily misread list. Recovery: re-crop to
/// just the list, or fall back to manual entry.
class NoCandidatesParsedFailure extends OcrFailure {
  const NoCandidatesParsedFailure(super.message);
}

/// The crop/rotate/enhance step could not produce a usable image — a
/// cancelled or crashed crop UI, an unreadable or unwritable file.
class ImageProcessingFailure extends OcrFailure {
  const ImageProcessingFailure(super.message);
}

/// Neither text recognition nor image preparation is available on this
/// device (missing ML model, unsupported platform). Distinct from the
/// failures above because retrying will never help: the only honest
/// recovery is manual entry (009 Edge Cases).
class OcrUnavailableFailure extends OcrFailure {
  const OcrUnavailableFailure(super.message);
}
