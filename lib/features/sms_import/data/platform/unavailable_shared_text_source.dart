import '../../domain/services/shared_text_source.dart';

/// The shared-text port where no Android share target exists: iOS (paste
/// only, no Share Extension), macOS and the host platform of
/// `flutter test`. Nothing is ever shared in.
///
/// No injectable annotation: `SmsPlatformModule` chooses it.
class UnavailableSharedTextSource implements SharedTextSource {
  const UnavailableSharedTextSource();

  @override
  Future<SharedText?> takeInitial() async => null;

  @override
  Stream<SharedText> get stream => const Stream.empty();
}
