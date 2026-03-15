import Flutter
import UIKit
import AppTrackingTransparency

class SceneDelegate: FlutterSceneDelegate {

  // Holds a weak reference to Flutter's UIWindow so that AppDelegate's
  // key-window guard can restore it reliably.
  static weak var flutterWindow: UIWindow?

  // Strong references to keep MethodChannels alive for the app's lifetime.
  private var keyboardFixChannel: FlutterMethodChannel?
  private var attChannel: FlutterMethodChannel?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // After super runs, self.window is set by FlutterSceneDelegate.
    SceneDelegate.flutterWindow = window
    setupKeyboardFixChannel()
    setupATTChannel()
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
      switch call.method {
      case "makeFlutterWindowKey":
        if let fw = SceneDelegate.flutterWindow, !fw.isKeyWindow {
          fw.makeKeyAndVisible()
        }
        result(nil)
      case "suspendWindowReclaim":
        let seconds = (call.arguments as? [String: Any])?["seconds"] as? Int ?? 90
        AppDelegate.setWindowReclaimSuspended(for: TimeInterval(seconds))
        result(nil)
      case "resumeWindowReclaim":
        AppDelegate.clearWindowReclaimSuspension()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    keyboardFixChannel = channel
  }

  /// Sets up the ATT (App Tracking Transparency) MethodChannel.
  ///
  /// Called by AdService before initializing Google Mobile Ads SDK so the
  /// user sees the tracking consent dialog before any IDFA-dependent ads load.
  private func setupATTChannel() {
    guard let flutterVC = window?.rootViewController as? FlutterViewController else { return }
    let engine = flutterVC.engine

    let channel = FlutterMethodChannel(
      name: "com.budgiebreeding.tracker/att",
      binaryMessenger: engine.binaryMessenger
    )
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard call.method == "requestTracking" else {
        result(FlutterMethodNotImplemented)
        return
      }
      if #available(iOS 14, *) {
        ATTrackingManager.requestTrackingAuthorization { _ in
          DispatchQueue.main.async { result(nil) }
        }
      } else {
        result(nil)
      }
    }
    attChannel = channel
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
