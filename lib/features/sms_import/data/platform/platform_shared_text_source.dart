import '../../domain/services/shared_text_source.dart';
import 'sms_channel_client.dart';

/// The Android share target's text (sms-platform-channel §2.5, §2.6,
/// §6). Selected by `SmsPlatformModule` whenever `Platform.isAndroid`,
/// **including a build without the READ_SMS capability**: sharing needs no
/// permission, and this adapter never calls an inbox or permission method.
///
/// - [takeInitial] drains the cold-start share, which the plugin returns
///   once and clears.
/// - [stream] maps the warm-share events.
/// - Each payload may carry a monotonic `seq`; a payload whose `seq` was
///   already delivered (by either path) is dropped, so one share is never
///   handed over twice.
/// - Malformed payloads and channel failures are dropped. Nothing is
///   logged, and the text is never kept here.
///
/// No injectable annotation: `SmsPlatformModule` chooses it.
class PlatformSharedTextSource implements SharedTextSource {
  PlatformSharedTextSource(this._channel);

  final SmsChannelClient _channel;
  int _lastSeq = 0;

  @override
  Future<SharedText?> takeInitial() async {
    final reply = await _channel.getInitialSharedText();
    return reply.match((_) => null, (map) => map == null ? null : _decode(map));
  }

  @override
  Stream<SharedText> get stream => _channel
      .sharedTextEvents()
      .map(_decode)
      .where((shared) => shared != null)
      .cast<SharedText>();

  SharedText? _decode(Map<String, Object?> payload) {
    final text = payload['text'];
    if (text is! String || text.isEmpty) return null;
    final seq = payload['seq'];
    if (seq is int) {
      if (seq <= _lastSeq) return null;
      _lastSeq = seq;
    }
    final truncated = payload['truncated'];
    return SharedText(text: text, truncated: truncated is bool && truncated);
  }

  @override
  String toString() => 'PlatformSharedTextSource()';
}
