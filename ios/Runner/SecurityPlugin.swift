import Flutter
import UIKit

/// 015 screenshot/recording protection (research.md Decision 1).
///
/// iOS offers no FLAG_SECURE equivalent, so protection is two cooperating
/// behaviors, both active only while `enable` is in effect:
/// - a privacy overlay covers the window whenever the app resigns active, so
///   the app-switcher snapshot never shows financial data (FR-020);
/// - `UIScreen.capturedDidChangeNotification` raises the same overlay while
///   the screen is being recorded/mirrored, and reports the change to Dart
///   over the recording event channel (FR-021).
///
/// The privacy overlay is the app-switcher placeholder (FR-020): a
/// `.systemMaterial` blur under the OS's own app icon and name. Its Dart-side
/// owner is `lib/core/security/app_switcher_placeholder.dart`; keep the blur
/// style here in step with `AppSwitcherPlaceholder.iosBlurStyle`.
///
/// FR-022 — screenshots vs. the app's own data output. iOS cannot block a
/// screenshot at all; this plugin only *obscures this window's pixels* while
/// the app is being snapshotted for the app switcher or while the screen is
/// recorded/mirrored. It never touches data the app deliberately hands out:
/// - the CSV export (`SharePlusService`, `share_plus`) presents
///   `UIActivityViewController` with a *file* — the sheet is a separate view
///   controller that the user sees normally, and the receiving app gets the
///   file, not an image of Daftary. Presenting the sheet does not resign the
///   app active, so the overlay is not raised over it;
/// - the photo picker (`AttachmentPickerServiceImpl`) and the OCR cropper
///   (`ImagePreparationServiceImpl`) are likewise in-process view controllers
///   returning files.
/// None of these flows is, or is ever registered as, a screen capture from
/// the platform's perspective (verified by code review and quickstart.md
/// Scenario 5, step 4). Any future export must keep that shape — share a
/// generated file, never a capture of this window.
final class SecurityPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  static let methodChannelName = "com.daftary.daftary/security"
  static let eventChannelName = "com.daftary.daftary/security/recording"

  private var protectionEnabled = false
  private var isInBackgroundTransition = false
  private var eventSink: FlutterEventSink?
  private var overlay: UIView?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SecurityPlugin()
    let methods = FlutterMethodChannel(
      name: methodChannelName, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methods)
    let events = FlutterEventChannel(
      name: eventChannelName, binaryMessenger: registrar.messenger())
    events.setStreamHandler(instance)
    instance.observeLifecycle()
  }

  private func observeLifecycle() {
    let center = NotificationCenter.default
    center.addObserver(
      self, selector: #selector(willResignActive),
      name: UIApplication.willResignActiveNotification, object: nil)
    center.addObserver(
      self, selector: #selector(didBecomeActive),
      name: UIApplication.didBecomeActiveNotification, object: nil)
    center.addObserver(
      self, selector: #selector(willResignActive),
      name: UIScene.willDeactivateNotification, object: nil)
    center.addObserver(
      self, selector: #selector(didBecomeActive),
      name: UIScene.didActivateNotification, object: nil)
    center.addObserver(
      self, selector: #selector(capturedDidChange),
      name: UIScreen.capturedDidChangeNotification, object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - FlutterPlugin

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "enable":
      protectionEnabled = true
      refreshOverlay()
      result(nil)
    case "disable":
      protectionEnabled = false
      refreshOverlay()
      result(nil)
    case "isCaptured":
      result(isScreenCaptured)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    events(isScreenCaptured)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  // MARK: - Lifecycle

  @objc private func willResignActive() {
    isInBackgroundTransition = true
    refreshOverlay()
  }

  @objc private func didBecomeActive() {
    isInBackgroundTransition = false
    refreshOverlay()
  }

  @objc private func capturedDidChange() {
    eventSink?(isScreenCaptured)
    refreshOverlay()
  }

  private var isScreenCaptured: Bool {
    UIScreen.main.isCaptured
  }

  // MARK: - Overlay

  private func refreshOverlay() {
    let shouldShow = protectionEnabled && (isInBackgroundTransition || isScreenCaptured)
    if shouldShow {
      showOverlay()
    } else {
      hideOverlay()
    }
  }

  private func showOverlay() {
    guard overlay == nil, let window = keyWindow else { return }
    let cover = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    cover.frame = window.bounds
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(cover)
    overlay = cover
  }

  private func hideOverlay() {
    overlay?.removeFromSuperview()
    overlay = nil
  }

  private var keyWindow: UIWindow? {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
    return windows.first(where: { $0.isKeyWindow }) ?? windows.first
  }
}
