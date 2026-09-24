import 'dart:io';

import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../error/failure.dart';
import '../security/app_lifecycle_observer.dart';
import 'attachment_picker_service.dart';

/// Wraps `image_picker` and takes ownership of whatever it returns: the
/// picked file is copied into an `attachments/` subdirectory of the app's
/// documents directory — the same sandboxed, OS-protected location that
/// already holds `daftary.sqlite` — and only that copy's path is handed back.
///
/// The copy is the point. `image_picker` returns a path into an OS cache the
/// system is free to purge, so persisting it directly would produce
/// attachments that silently stop resolving days later.
///
/// The camera/gallery runs as an app-initiated external activity (015
/// FR-010): it backgrounds the app, which must not start App Lock's
/// inactivity timer and lock the user out mid-pick. This is the single
/// picker entry point for both occasion attachments and OCR scans.
@LazySingleton(as: AttachmentPickerService)
class AttachmentPickerServiceImpl implements AttachmentPickerService {
  AttachmentPickerServiceImpl(
    this._picker,
    this._documentsDirectory,
    this._lifecycle,
  );

  final ImagePicker _picker;

  /// Injected rather than called inline so the copy step is testable without
  /// a platform channel.
  final DocumentsDirectory _documentsDirectory;
  final AppLifecycleObserver _lifecycle;

  static const _uuid = Uuid();
  static const _attachmentsDirName = 'attachments';

  @override
  Future<Either<Failure, String>> pickFromCamera() => _pick(ImageSource.camera);

  @override
  Future<Either<Failure, String>> pickFromGallery() =>
      _pick(ImageSource.gallery);

  Future<Either<Failure, String>> _pick(ImageSource source) async {
    final XFile? picked;
    try {
      picked = await _lifecycle.runExternalActivity(
        () => _picker.pickImage(source: source),
      );
    } on PlatformException catch (e) {
      // `image_picker` reports a declined permission as a platform error
      // rather than a null result, so the two outcomes are distinguished
      // here — the UI explains one and silently ignores the other.
      if (_isPermissionError(e)) {
        return Left(
          PermissionDeniedFailure(
            source == ImageSource.camera
                ? 'Camera access was denied'
                : 'Photo library access was denied',
          ),
        );
      }
      return Left(UnknownFailure('Could not open the picker: ${e.message}'));
    } catch (e) {
      return Left(UnknownFailure('Could not open the picker: $e'));
    }

    if (picked == null) {
      return const Left(PickerCancelledFailure('No photo was selected'));
    }

    try {
      final documents = await _documentsDirectory.resolve();
      final targetDir = Directory(p.join(documents.path, _attachmentsDirName));
      if (!targetDir.existsSync()) {
        await targetDir.create(recursive: true);
      }
      final extension = p.extension(picked.path).isEmpty
          ? '.jpg'
          : p.extension(picked.path);
      final targetPath = p.join(targetDir.path, '${_uuid.v4()}$extension');
      await File(picked.path).copy(targetPath);
      return Right(targetPath);
    } catch (e) {
      return Left(CacheFailure('Could not save the photo: $e'));
    }
  }

  bool _isPermissionError(PlatformException e) {
    const permissionCodes = {
      'camera_access_denied',
      'photo_access_denied',
      'access_denied',
    };
    return permissionCodes.contains(e.code);
  }
}
