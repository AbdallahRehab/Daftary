import 'dart:io';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/media/attachment_picker_service.dart';
import 'package:daftary/core/media/attachment_picker_service_impl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

class _MockImagePicker extends Mock implements ImagePicker {}

/// Points the picker at a temp directory instead of the real platform
/// documents directory, which no unit test can reach.
class _FakeDocumentsDirectory implements DocumentsDirectory {
  _FakeDocumentsDirectory(this.directory);

  final Directory directory;

  @override
  Future<Directory> resolve() async => directory;
}

/// T013 — the picker is the one place this feature touches the OS, so its
/// three outcomes are pinned here: a successful pick must leave the app
/// owning a copy it controls, and neither a denied permission nor a plain
/// cancellation may ever reach the UI as a thrown exception (constitution
/// Principle VII).
void main() {
  late _MockImagePicker picker;
  late Directory documentsDir;
  late Directory sourceDir;
  late AttachmentPickerServiceImpl service;

  setUpAll(() {
    registerFallbackValue(ImageSource.gallery);
  });

  setUp(() {
    picker = _MockImagePicker();
    documentsDir = Directory.systemTemp.createTempSync('daftary_docs');
    sourceDir = Directory.systemTemp.createTempSync('daftary_picker_cache');
    service = AttachmentPickerServiceImpl(
      picker,
      _FakeDocumentsDirectory(documentsDir),
    );
  });

  tearDown(() {
    if (documentsDir.existsSync()) documentsDir.deleteSync(recursive: true);
    if (sourceDir.existsSync()) sourceDir.deleteSync(recursive: true);
  });

  /// Stands in for the transient OS picker cache: a real file that the test
  /// can then delete, to prove the returned path does not depend on it.
  File writeSourceFile({String name = 'photo.jpg'}) {
    final file = File(p.join(sourceDir.path, name))
      ..writeAsBytesSync([1, 2, 3, 4]);
    return file;
  }

  void stubPick(XFile? result) {
    when(
      () => picker.pickImage(source: any(named: 'source')),
    ).thenAnswer((_) async => result);
  }

  group('a successful pick', () {
    test('copies the file into the app documents directory and returns the '
        'copy, not the picker path', () async {
      final source = writeSourceFile();
      stubPick(XFile(source.path));

      final result = await service.pickFromGallery();

      final path = result.getOrElse((f) => fail('expected a path: $f'));
      expect(path, isNot(source.path));
      expect(p.dirname(path), p.join(documentsDir.path, 'attachments'));
      expect(File(path).readAsBytesSync(), [1, 2, 3, 4]);
    });

    test('leaves the copy readable after the picker cache is purged — the '
        'whole reason the file is copied at all', () async {
      final source = writeSourceFile();
      stubPick(XFile(source.path));

      final result = await service.pickFromCamera();
      final path = result.getOrElse((f) => fail('expected a path: $f'));

      sourceDir.deleteSync(recursive: true);

      expect(File(path).existsSync(), isTrue);
      expect(File(path).readAsBytesSync(), [1, 2, 3, 4]);
    });

    test('gives each attachment its own name, so picking the same source '
        'photo twice keeps both', () async {
      final source = writeSourceFile();
      stubPick(XFile(source.path));

      final first = (await service.pickFromGallery()).getOrElse(
        (f) => fail('$f'),
      );
      final second = (await service.pickFromGallery()).getOrElse(
        (f) => fail('$f'),
      );

      expect(first, isNot(second));
      expect(File(first).existsSync(), isTrue);
      expect(File(second).existsSync(), isTrue);
    });

    test('keeps the source extension, falling back to .jpg when there is '
        'none', () async {
      stubPick(XFile(writeSourceFile(name: 'shot.png').path));
      final withExtension = (await service.pickFromCamera()).getOrElse(
        (f) => fail('$f'),
      );
      expect(p.extension(withExtension), '.png');

      stubPick(XFile(writeSourceFile(name: 'shot').path));
      final without = (await service.pickFromCamera()).getOrElse(
        (f) => fail('$f'),
      );
      expect(p.extension(without), '.jpg');
    });

    test('routes camera and gallery to the matching ImageSource', () async {
      stubPick(XFile(writeSourceFile().path));

      await service.pickFromCamera();
      verify(() => picker.pickImage(source: ImageSource.camera)).called(1);

      await service.pickFromGallery();
      verify(() => picker.pickImage(source: ImageSource.gallery)).called(1);
    });
  });

  group('a denied permission', () {
    test('returns PermissionDeniedFailure rather than throwing', () async {
      when(() => picker.pickImage(source: any(named: 'source'))).thenThrow(
        PlatformException(code: 'camera_access_denied', message: 'denied'),
      );

      final result = await service.pickFromCamera();

      expect(result.getLeft().toNullable(), isA<PermissionDeniedFailure>());
    });

    test('is distinguished from an unrelated platform error, so the UI can '
        'explain one and only apologize for the other', () async {
      when(
        () => picker.pickImage(source: any(named: 'source')),
      ).thenThrow(PlatformException(code: 'no_available_camera'));

      final result = await service.pickFromGallery();

      final failure = result.getLeft().toNullable();
      expect(failure, isA<UnknownFailure>());
      expect(failure, isNot(isA<PermissionDeniedFailure>()));
    });
  });

  test('a cancellation returns PickerCancelledFailure — a normal outcome, '
      'not an error to apologize for', () async {
    stubPick(null);

    final result = await service.pickFromGallery();

    expect(result.getLeft().toNullable(), isA<PickerCancelledFailure>());
  });

  test('an unreadable source file surfaces as CacheFailure, never as an '
      'escaping exception', () async {
    stubPick(XFile(p.join(sourceDir.path, 'never_written.jpg')));

    final result = await service.pickFromCamera();

    expect(result.getLeft().toNullable(), isA<CacheFailure>());
  });
}
