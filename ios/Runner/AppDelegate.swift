import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 017: lets flutter_local_notifications present notifications and
    // receive taps (per the plugin's iOS setup requirements).
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // 015: in-app screenshot/recording protection plugin (research.md
    // Decision 1) — not a pub package, so registered by hand.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SecurityPlugin") {
      SecurityPlugin.register(with: registrar)
    }
  }
}
