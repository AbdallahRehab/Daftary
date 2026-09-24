import 'dart:io';

import 'package:daftary/core/media/attachment_picker_service.dart';
import 'package:daftary/features/ocr/data/preparation/image_preparation_service_impl.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;

import '../../../../core/security/helpers/test_app_lifecycle_observer.dart';

/// Stands in for the native crop UI, which no unit test can open.
class _FakeCropperClient implements ImageCropperClient {
  _FakeCropperClient({this.result, this.throws});

  /// `null` models the user backing out of the crop screen.
  final CroppedFile? result;
  final Object? throws;

  @override
  Future<CroppedFile?> crop(String sourcePath) async {
    if (throws != null) throw throws!;
    return result;
  }
}

/// Points every write at a temp directory instead of the real platform
/// documents directory, which no unit test can reach.
class _FakeDocumentsDirectory implements DocumentsDirectory {
  _FakeDocumentsDirectory(this.directory);

  final Directory directory;

  @override
  Future<Directory> resolve() async => directory;
}

/// T012 — the preparation step is the feature's only pre-OCR transform, and
/// the pipeline above it only stays explainable if two promises hold: the
/// enhancement is byte-for-byte reproducible (research.md Decision 2), and
/// neither a cancelled nor a crashed crop UI can ever reach the caller as a
/// thrown exception (constitution Principle VII).
void main() {
  late Directory documentsDir;
  late Directory sourceDir;

  setUp(() {
    documentsDir = Directory.systemTemp.createTempSync('daftary_ocr_docs');
    sourceDir = Directory.systemTemp.createTempSync('daftary_ocr_src');
  });

  tearDown(() {
    if (documentsDir.existsSync()) documentsDir.deleteSync(recursive: true);
    if (sourceDir.existsSync()) sourceDir.deleteSync(recursive: true);
  });

  ImagePreparationServiceImpl serviceWith(ImageCropperClient cropper) =>
      ImagePreparationServiceImpl(
        cropper,
        _FakeDocumentsDirectory(documentsDir),
        testAppLifecycleObserver(),
      );

  /// A small, uneven, low-contrast fixture generated in code rather than
  /// checked in as a binary: the stretch has something real to widen, and
  /// the test stays readable about what it is feeding in.
  File writeFixtureImage({String name = 'page.png'}) {
    final image = img.Image(width: 16, height: 16);
    for (var y = 0; y < 16; y++) {
      for (var x = 0; x < 16; x++) {
        // Bunched into the 90..150 band, so an un-stretched copy and a
        // stretched one cannot possibly be confused.
        final value = 90 + ((x * 3 + y * 1) % 61);
        image.setPixelRgb(x, y, value, value, value);
      }
    }
    final file = File(p.join(sourceDir.path, name))
      ..writeAsBytesSync(img.encodePng(image));
    return file;
  }

  group('enhance', () {
    test('produces byte-identical output for the same input', () async {
      final source = writeFixtureImage();
      final service = serviceWith(_FakeCropperClient());

      final first = await service.enhance(source.path);
      final firstBytes = File(first.getRight().toNullable()!).readAsBytesSync();

      // A second, independent service instance: determinism must come from
      // the transform, not from anything cached on the first one.
      final second = await serviceWith(
        _FakeCropperClient(),
      ).enhance(source.path);
      final secondBytes = File(
        second.getRight().toNullable()!,
      ).readAsBytesSync();

      expect(secondBytes, equals(firstBytes));
    });

    test('writes a new file inside the documents directory', () async {
      final source = writeFixtureImage();
      final service = serviceWith(_FakeCropperClient());

      final result = await service.enhance(source.path);
      final path = result.getRight().toNullable();

      expect(path, isNotNull);
      expect(path, isNot(source.path));
      expect(p.isWithin(documentsDir.path, path!), isTrue);
      expect(File(path).existsSync(), isTrue);
    });

    test('actually widens the tonal range of a flat photo', () async {
      final source = writeFixtureImage();
      final service = serviceWith(_FakeCropperClient());

      final result = await service.enhance(source.path);
      final enhanced = img.decodeImage(
        File(result.getRight().toNullable()!).readAsBytesSync(),
      )!;

      var min = 255;
      var max = 0;
      for (var y = 0; y < enhanced.height; y++) {
        for (var x = 0; x < enhanced.width; x++) {
          final value = enhanced.getPixel(x, y).r.round();
          if (value < min) min = value;
          if (value > max) max = value;
        }
      }
      expect(max - min, greaterThan(150));
    });

    test(
      'returns ImageProcessingFailure for a file that is not an image',
      () async {
        final garbage = File(p.join(sourceDir.path, 'notes.txt'))
          ..writeAsStringSync('this is not an image at all');
        final service = serviceWith(_FakeCropperClient());

        final result = await service.enhance(garbage.path);

        expect(result.getLeft().toNullable(), isA<ImageProcessingFailure>());
      },
    );

    test('returns ImageProcessingFailure for a missing file', () async {
      final service = serviceWith(_FakeCropperClient());

      final result = await service.enhance(
        p.join(sourceDir.path, 'does_not_exist.png'),
      );

      expect(result.getLeft().toNullable(), isA<ImageProcessingFailure>());
    });
  });

  group('cropAndRotate', () {
    test('maps a cancelled crop to PickerCancelledFailure', () async {
      final service = serviceWith(_FakeCropperClient());

      final result = await service.cropAndRotate('anything.jpg');

      expect(result.getLeft().toNullable(), isA<PickerCancelledFailure>());
    });

    test('maps a thrown plugin error to ImageProcessingFailure without '
        'throwing', () async {
      final service = serviceWith(
        _FakeCropperClient(throws: Exception('crop activity died')),
      );

      final result = await service.cropAndRotate('anything.jpg');

      expect(result.getLeft().toNullable(), isA<ImageProcessingFailure>());
    });

    test('copies the plugin result into the app-owned directory', () async {
      final cropped = writeFixtureImage(name: 'cropper_cache.png');
      final service = serviceWith(
        _FakeCropperClient(result: CroppedFile(cropped.path)),
      );

      final result = await service.cropAndRotate(cropped.path);
      final prepared = result.getRight().toNullable();

      expect(prepared, isNotNull);
      expect(p.isWithin(documentsDir.path, prepared!.imagePath), isTrue);
      expect(File(prepared.imagePath).existsSync(), isTrue);
      // The plugin exposes no rotation, so nothing may be invented here.
      expect(prepared.rotationDegrees, 0);

      // The returned copy must survive the OS purging its picker cache.
      cropped.deleteSync();
      expect(File(prepared.imagePath).existsSync(), isTrue);
    });
  });
}
