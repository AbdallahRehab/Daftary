import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/field_confidence.dart';

/// One recognized line of text, as the parser sees it.
///
/// Plain Dart on purpose: no plugin type appears anywhere in this file, so
/// [RecognizedText] can be built by hand in a test and the parser can be
/// exercised exhaustively with zero device, model, or platform channel
/// (research.md Decision 6).
class RecognizedLine extends Equatable {
  const RecognizedLine({
    required this.text,
    this.confidence = FieldConfidenceLevel.medium,
  });

  final String text;

  /// The recognizer's coarse confidence in this line. Coarse rather than a
  /// percentage because the underlying engine does not expose a meaningful
  /// per-token score, and a precise-looking number would overstate what the
  /// app knows (research.md Decision 4).
  final FieldConfidenceLevel confidence;

  @override
  List<Object?> get props => [text, confidence];
}

/// A recognized block — the engine's own grouping of nearby lines. Kept
/// because block structure is what separates a heading (a short line alone
/// at the top) from a list row.
class RecognizedBlock extends Equatable {
  const RecognizedBlock({required this.lines});

  final List<RecognizedLine> lines;

  @override
  List<Object?> get props => [lines];
}

/// Everything the recognizer found in one image.
class RecognizedText extends Equatable {
  const RecognizedText({required this.blocks});

  const RecognizedText.empty() : blocks = const [];

  final List<RecognizedBlock> blocks;

  /// Every line in reading order, flattened across blocks.
  List<RecognizedLine> get lines => [
    for (final block in blocks) ...block.lines,
  ];

  bool get isEmpty => lines.every((line) => line.text.trim().isEmpty);

  @override
  List<Object?> get props => [blocks];
}

/// Reads text off an image, entirely on this device.
///
/// Feature-local Domain interface (plan.md Structure Decision), wrapping the
/// on-device recognizer so nothing above Data depends on the plugin — and
/// so the whole pipeline above it is testable with a fake.
///
/// There is no network-backed implementation of this interface and no
/// configuration that would add one: this feature makes zero network calls
/// by construction (009 FR-019).
abstract class TextRecognitionService {
  /// Returns what was found in [imagePath], or [NoTextRecognizedFailure]
  /// when the image contained no readable text at all (009 FR-003).
  Future<Either<Failure, RecognizedText>> recognize(String imagePath);

  /// Whether on-device recognition is usable here. `false` means retrying
  /// will never help and the honest answer is manual entry (Edge Cases).
  Future<bool> isAvailable();
}
