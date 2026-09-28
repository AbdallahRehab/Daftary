import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Always-on foreground screenshot / screen-recording protection
/// (015 FR-020/FR-021, research.md Decision 1). Enabled unconditionally at
/// startup — independent of whether App Lock itself is ever turned on.
///
/// Never interferes with the app's own share-sheet exports (FR-022): the
/// platform side only blocks *capture of this window*, not data the app
/// hands to another app.
abstract class ScreenshotProtectionService {
  /// Android: sets `FLAG_SECURE`. iOS: arms the app-switcher privacy overlay
  /// and the screen-recording overlay.
  Future<void> enable();

  /// Reverses [enable].
  Future<void> disable();

  /// Whether the screen is currently being recorded/mirrored. Always `false`
  /// on Android, where `FLAG_SECURE` already blanks any recording.
  Future<bool> isScreenCaptured();

  /// Emits whenever screen recording/mirroring starts (`true`) or stops
  /// (`false`). A broadcast stream; iOS only emits real changes.
  Stream<bool> get screenCaptureChanges;
}

/// [ScreenshotProtectionService] over the in-app `SecurityPlugin` platform
/// channels (`android/.../SecurityPlugin.kt`, `ios/Runner/SecurityPlugin.swift`).
///
/// Platform errors are logged (debug builds) and swallowed into a no-op —
/// protection is best-effort hardening and must never crash startup (e.g.
/// on a platform without the plugin, such as widget tests or desktop).
@LazySingleton(as: ScreenshotProtectionService)
class PlatformScreenshotProtectionService
    implements ScreenshotProtectionService {
  PlatformScreenshotProtectionService({
    @ignoreParam MethodChannel? methodChannel,
    @ignoreParam EventChannel? eventChannel,
  }) : _methods = methodChannel ?? const MethodChannel(methodChannelName),
       _events = eventChannel ?? const EventChannel(eventChannelName);

  static const String methodChannelName = 'com.daftary.daftary/security';
  static const String eventChannelName =
      'com.daftary.daftary/security/recording';

  final MethodChannel _methods;
  final EventChannel _events;
  Stream<bool>? _captureChanges;

  @override
  Future<void> enable() => _invoke('enable');

  @override
  Future<void> disable() => _invoke('disable');

  @override
  Future<bool> isScreenCaptured() async {
    try {
      return await _methods.invokeMethod<bool>('isCaptured') ?? false;
    } on PlatformException catch (e) {
      _log('isCaptured', e.code);
      return false;
    } on MissingPluginException {
      _log('isCaptured', 'missingPlugin');
      return false;
    }
  }

  @override
  Stream<bool> get screenCaptureChanges => _captureChanges ??= _events
      .receiveBroadcastStream()
      .map((event) => event == true)
      .handleError((Object error) {
        _log('screenCaptureChanges', error.runtimeType.toString());
      })
      .asBroadcastStream();

  Future<void> _invoke(String method) async {
    try {
      await _methods.invokeMethod<void>(method);
    } on PlatformException catch (e) {
      _log(method, e.code);
    } on MissingPluginException {
      _log(method, 'missingPlugin');
    }
  }

  void _log(String operation, String code) {
    if (kDebugMode) {
      debugPrint('ScreenshotProtectionService.$operation failed: $code');
    }
  }
}
