import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as mlkit;
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/field_confidence.dart';
import '../../domain/entities/ocr_failures.dart';
import '../../domain/repositories/text_recognition_service.dart';

/// Wraps Google ML Kit's on-device Latin-script recognizer (research.md
/// Decision 1) and converts its result into the feature's own plain-Dart
/// model.
///
/// Nothing from `google_mlkit_text_recognition` appears in a public
/// signature here: every ML Kit type is confined to [_toDomain], so the
/// parser and everything above it stay device-free and testable
/// (research.md Decision 6).
@LazySingleton(as: TextRecognitionService)
class TextRecognitionServiceImpl implements TextRecognitionService {
  TextRecognitionServiceImpl();

  @override
  Future<Either<Failure, RecognizedText>> recognize(String imagePath) async {
    if (!await isAvailable()) {
      return const Left(
        OcrUnavailableFailure(
          'Text recognition is not available on this device',
        ),
      );
    }

    // A recognizer per call, closed in `finally`, rather than one long-lived
    // instance: scanning is a rare, user-initiated burst, and holding a
    // native detector open for the life of the app would keep its model
    // resident for nothing. This also means the service has no disposal
    // contract for callers to get wrong.
    final recognizer = mlkit.TextRecognizer(
      script: mlkit.TextRecognitionScript.latin,
    );
    try {
      final result = await recognizer.processImage(
        mlkit.InputImage.fromFilePath(imagePath),
      );
      final recognized = _toDomain(result);
      if (recognized.isEmpty) {
        return const Left(
          NoTextRecognizedFailure('No readable text was found in that photo'),
        );
      }
      return Right(recognized);
    } on PlatformException catch (e) {
      // A missing or undownloaded model is not something a retry fixes, so
      // it is reported as unavailable rather than as a processing error
      // (009 Edge Cases).
      if (_isModelUnavailable(e)) {
        return Left(
          OcrUnavailableFailure(
            'The text recognition model is not available: ${e.message}',
          ),
        );
      }
      return Left(
        ImageProcessingFailure('Could not read that photo: ${e.message}'),
      );
    } catch (e) {
      return Left(UnknownFailure('Text recognition failed: $e'));
    } finally {
      await recognizer.close();
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    // The plugin has no desktop or web build; calling it anywhere else
    // throws a missing-plugin error rather than returning an empty result.
    return Platform.isAndroid || Platform.isIOS;
  }

  RecognizedText _toDomain(mlkit.RecognizedText result) {
    return RecognizedText(
      blocks: [
        for (final block in result.blocks)
          RecognizedBlock(
            lines: [
              for (final line in block.lines)
                RecognizedLine(
                  text: line.text,
                  confidence: _levelFor(line.confidence),
                ),
            ],
          ),
      ],
    );
  }

  /// Buckets the engine's per-line score into three steps.
  ///
  /// Coarse on purpose (research.md Decision 4): ML Kit reports this score
  /// only on Android — iOS returns `null` — and even there it is a model
  /// internal, not a calibrated probability that a human would read the same
  /// characters. Surfacing it as a precise percentage would overstate what
  /// the app actually knows, so `null` maps to [FieldConfidenceLevel.medium]
  /// (neither a claim of certainty nor an unearned warning) and everything
  /// else falls into low/medium/high.
  FieldConfidenceLevel _levelFor(double? confidence) {
    if (confidence == null) return FieldConfidenceLevel.medium;
    if (confidence < 0.5) return FieldConfidenceLevel.low;
    if (confidence < 0.8) return FieldConfidenceLevel.medium;
    return FieldConfidenceLevel.high;
  }

  bool _isModelUnavailable(PlatformException e) {
    const unavailableCodes = {'MissingPluginException', 'ModelNotDownloaded'};
    if (unavailableCodes.contains(e.code)) return true;
    final message = e.message?.toLowerCase() ?? '';
    return message.contains('model') &&
        (message.contains('not available') ||
            message.contains('unavailable') ||
            message.contains('download'));
  }
}
