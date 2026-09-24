import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
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
