import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../error/failure.dart';

/// Resolves the app's private documents directory on demand.
///
/// A collaborator rather than a direct `getApplicationDocumentsDirectory()`
/// call inside the picker, for two reasons: nothing blocks startup on a
/// platform-channel call that only the attachment flow needs, and a test can
/// substitute a temp directory without a platform channel at all.
@lazySingleton
class DocumentsDirectory {
  const DocumentsDirectory();

  Future<Directory> resolve() => getApplicationDocumentsDirectory();
}

/// Captures or selects one image and hands back a path to a copy the app
/// itself owns.
///
/// Lives in `core/` rather than inside `features/occasions/` because the
/// upcoming OCR feature's first step is the same capture/pick flow — the
/// sharing is concrete and already planned, not speculative (constitution
/// Principle II, 008 research.md Decision 7).
///
/// Implementations MUST copy the picked file into the app's own private
/// storage before returning, so the returned path stays valid after the OS
/// clears its picker cache.
abstract class AttachmentPickerService {
  /// Opens the camera. Returns the local path of the app-owned copy, or a
  /// typed failure the UI can explain: [PermissionDeniedFailure] when the
  /// user declined camera access, [PickerCancelledFailure] when they simply
  /// backed out.
  Future<Either<Failure, String>> pickFromCamera();

  /// Opens the system photo picker, with the same contract as
  /// [pickFromCamera].
  Future<Either<Failure, String>> pickFromGallery();
}

/// The user declined (or has permanently denied) camera or photo-library
/// access. Distinct from [PickerCancelledFailure] because it is the one case
/// worth explaining and offering a path to Settings for — a cancellation
/// needs no message at all.
class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure(super.message);
}

/// The user backed out of the camera or picker without choosing anything.
/// A normal outcome, not an error: callers should return the UI to its prior
/// state silently rather than showing a message.
class PickerCancelledFailure extends Failure {
  const PickerCancelledFailure(super.message);
}
