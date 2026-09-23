import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fpdart/fpdart.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/media/attachment_picker_service.dart';
import '../../domain/entities/ocr_failures.dart';
import '../../domain/repositories/image_preparation_service.dart';

/// The one place `image_cropper` is actually called.
///
/// A seam, not an abstraction for its own sake: `ImageCropper.cropImage`
/// reaches a platform channel, so without something to substitute here the
/// whole preparation service would only be testable on a device
/// (constitution Principle XVI). The crop UI configuration lives inside the
/// client so the seam stays a single-argument call and no test has to know
/// the plugin's settings types.
@lazySingleton
class ImageCropperClient {
  const ImageCropperClient();

  /// Opens the native crop/rotate UI over [sourcePath]. Returns `null` when
  /// the user backed out.
  Future<CroppedFile?> crop(String sourcePath) {
    return ImageCropper().cropImage(
      sourcePath: sourcePath,
      // No `aspectRatio` and no locked presets: the user is cropping an
      // arbitrary sheet of paper, so forcing any ratio would cut off rows.
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 95,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop the list',
          lockAspectRatio: false,
          hideBottomControls: false,
          showCropGrid: true,
          initAspectRatio: CropAspectRatioPreset.original,
          aspectRatioPresets: const [CropAspectRatioPreset.original],
        ),
        IOSUiSettings(
          title: 'Crop the list',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
          aspectRatioPickerButtonHidden: true,
          rotateClockwiseButtonHidden: false,
        ),
      ],
    );
  }
}

/// Crop/rotate via the native plugin, then a deterministic brightness pass in
/// pure Dart (research.md Decision 2).
///
/// Both steps take ownership of their output the same way
/// `AttachmentPickerServiceImpl` does: the plugin writes into an OS cache the
/// system is free to purge, so the returned path is always a copy inside the
/// app's own documents directory.
@LazySingleton(as: ImagePreparationService)
class ImagePreparationServiceImpl implements ImagePreparationService {
  ImagePreparationServiceImpl(this._cropper, this._documentsDirectory);

  final ImageCropperClient _cropper;

  /// Injected rather than resolved inline so every file write below is
  /// exercisable against a temp directory, with no platform channel.
  final DocumentsDirectory _documentsDirectory;

  static const _uuid = Uuid();
  static const _scansDirName = 'ocr_scans';

  /// The share of the darkest and brightest pixels ignored when picking the
  /// stretch endpoints. Trimming the tails stops a single dust speck or a
  /// glare highlight from defining the whole range and flattening the page.
  static const _tailFraction = 0.02;

  @override
  Future<Either<Failure, PreparedImage>> cropAndRotate(String imagePath) async {
    final CroppedFile? cropped;
    try {
      cropped = await _cropper.crop(imagePath);
    } catch (e) {
      // A plugin exception must never escape: the caller's contract is
      // Either, and a crashed crop activity is an ordinary recoverable
      // outcome (009 FR-004).
      return Left(ImageProcessingFailure('Could not crop the photo: $e'));
    }

    if (cropped == null) {
      return const Left(PickerCancelledFailure('Cropping was cancelled'));
    }

    try {
      final target = await _copyIntoScansDirectory(cropped.path);
      return Right(
        PreparedImage(
          imagePath: target,
          // `image_cropper` returns only the resulting file — it exposes
          // neither the rotation the user applied nor the crop rectangle in
          // source coordinates. Recording 0 rather than inventing a number:
          // the transform is already baked into the pixels, and a fabricated
          // value would make a past scan look explainable when it is not.
          rotationDegrees: 0,
          cropBounds: _cropBoundsOrNull(cropped.path),
        ),
      );
    } catch (e) {
      return Left(
        ImageProcessingFailure('Could not save the cropped photo: $e'),
      );
    }
  }

  /// The plugin gives no crop rectangle, so the only honest thing recordable
  /// is the size of what came back. Returned as a small JSON string when the
  /// file can be measured, `null` when it cannot — never a guessed origin.
  String? _cropBoundsOrNull(String croppedPath) {
    try {
      final decoded = img.decodeImage(File(croppedPath).readAsBytesSync());
      if (decoded == null) return null;
      return jsonEncode({'width': decoded.width, 'height': decoded.height});
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Either<Failure, String>> enhance(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return const Left(
          ImageProcessingFailure('That file is not a readable image'),
        );
      }

      final enhanced = _grayscaleWithLinearStretch(decoded);
      final targetDir = await _scansDirectory();
      final targetPath = p.join(
        targetDir.path,
        '${p.basenameWithoutExtension(imagePath)}_enhanced.png',
      );
      // PNG, not JPEG: the stretch already pushed the page toward pure
      // black-on-white, and a lossy re-encode would reintroduce exactly the
      // ringing around glyph edges the recognizer struggles with.
      await File(targetPath).writeAsBytes(img.encodePng(enhanced));
      return Right(targetPath);
    } catch (e) {
      return Left(ImageProcessingFailure('Could not enhance the photo: $e'));
    }
  }

  /// Grayscale, then a linear stretch between the luminance histogram's low
  /// and high percentiles.
  ///
  /// Deliberately the simplest transform that helps: integer arithmetic over
  /// a fixed 256-bin histogram, no randomness, no wall-clock, no filename or
  /// device input. The same input bytes therefore always produce the same
  /// output bytes, which is what makes a past scan re-derivable and this
  /// whole step unit-testable (research.md Decision 2).
  img.Image _grayscaleWithLinearStretch(img.Image source) {
    final width = source.width;
    final height = source.height;
    final luminance = Uint8List(width * height);
    final histogram = List<int>.filled(256, 0);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = source.getPixel(x, y);
        final value = img
            .getLuminanceRgb(pixel.r, pixel.g, pixel.b)
            .round()
            .clamp(0, 255);
        luminance[y * width + x] = value;
        histogram[value]++;
      }
    }

    final total = width * height;
    final tail = (total * _tailFraction).floor();
    final low = _percentileBin(histogram, tail, fromDark: true);
    final high = _percentileBin(histogram, tail, fromDark: false);

    final output = img.Image(width: width, height: height, numChannels: 1);
    // A degenerate range (a blank or single-tone page) has nothing to
    // stretch; scaling by it would divide by zero or amplify sensor noise
    // into a false pattern, so the grayscale image is returned as-is.
    final span = high - low;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final value = luminance[y * width + x];
        final stretched = span <= 0
            ? value
            : (((value - low) * 255) ~/ span).clamp(0, 255);
        output.setPixelRgb(x, y, stretched, stretched, stretched);
      }
    }
    return output;
  }

  /// The bin at which [tail] pixels have been passed, scanning from the dark
  /// end when [fromDark] and from the bright end otherwise.
  int _percentileBin(List<int> histogram, int tail, {required bool fromDark}) {
    var seen = 0;
    if (fromDark) {
      for (var bin = 0; bin < histogram.length; bin++) {
        seen += histogram[bin];
        if (seen > tail) return bin;
      }
      return 0;
    }
    for (var bin = histogram.length - 1; bin >= 0; bin--) {
      seen += histogram[bin];
      if (seen > tail) return bin;
    }
    return 255;
  }

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    // `image_cropper` ships native crop UIs for Android and iOS only; on any
    // other platform the call would fail rather than show anything, and the
    // honest answer upstream is "use manual entry" (Edge Cases).
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<Directory> _scansDirectory() async {
    final documents = await _documentsDirectory.resolve();
    final dir = Directory(p.join(documents.path, _scansDirName));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// A fresh name per crop: the plugin reuses its cache filenames, so
  /// keeping the source basename would let a second crop silently overwrite
  /// the image an earlier scan still points at.
  Future<String> _copyIntoScansDirectory(String sourcePath) async {
    final dir = await _scansDirectory();
    final extension = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath);
    final targetPath = p.join(dir.path, '${_uuid.v4()}$extension');
    await File(sourcePath).copy(targetPath);
    return targetPath;
  }
}
