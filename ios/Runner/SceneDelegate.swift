import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  // Holds a weak reference to Flutter's UIWindow so that AppDelegate's
  // key-window guard can restore it reliably.
  static weak var flutterWindow: UIWindow?

  // Strong reference to keep the MethodChannel alive for the app's lifetime.
  private var keyboardFixChannel: FlutterMethodChannel?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // After super runs, self.window is set by FlutterSceneDelegate.
    SceneDelegate.flutterWindow = window
    setupKeyboardFixChannel()
  }

  /// Sets up the MethodChannel that Dart calls on every text-field tap
  /// to guarantee Flutter's UIWindow is the key window before UIKit
  /// tries to show the software keyboard.
  ///
  /// This MUST live here (not in AppDelegate.didInitializeImplicitFlutterEngine)
  /// because the implicit engine's pluginRegistry.registrar(forPlugin:) returns
  /// nil for ad-hoc plugin keys — so the channel was never created there.
  private func setupKeyboardFixChannel() {
    guard let flutterVC = window?.rootViewController as? FlutterViewController else { return }
    let engine = flutterVC.engine

    let channel = FlutterMethodChannel(
      name: "com.budgie/ios_keyboard_fix",
      binaryMessenger: engine.binaryMessenger
    )
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard call.method == "makeFlutterWindowKey" else {
        result(FlutterMethodNotImplemented)
        return
      }
      if let fw = SceneDelegate.flutterWindow, !fw.isKeyWindow {
        fw.makeKeyAndVisible()
      }
      result(nil)
    }
    keyboardFixChannel = channel
  }

  // Required for supabase_flutter (app_links) to process deep link callbacks on iOS 13+.
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    super.scene(scene, openURLContexts: URLContexts)
  }

  // Required for Universal Links (if used in the future).
  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    super.scene(scene, continue: userActivity)
  }
}
