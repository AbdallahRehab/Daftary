import 'package:equatable/equatable.dart';

/// Text shared into the app with Android `ACTION_SEND text/plain`
/// (FR-016). Available on every Android build; an empty source elsewhere.
abstract class SharedTextSource {
  /// Cold-start share, returned once.
  Future<SharedText?> takeInitial();

  /// Warm shares. Single-subscription, buffered by the platform until
  /// listened to.
  Stream<SharedText> get stream;
}

/// One shared text. It exists only in memory until consumed (FR-016a).
class SharedText extends Equatable {
  const SharedText({required this.text, this.truncated = false});

  /// Never logged, never in [toString].
  final String text;

  /// Truncated by the platform at 10,001 characters, so Dart can report
  /// "too long" precisely (FR-017).
  final bool truncated;

  @override
  List<Object?> get props => [text, truncated];

  @override
  String toString() =>
      'SharedText(length: ${text.length}, truncated: $truncated)';
}
