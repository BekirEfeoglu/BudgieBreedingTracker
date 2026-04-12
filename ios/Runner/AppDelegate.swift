import Flutter
import FirebaseCore
import UIKit
import UserNotifications
import AppTrackingTransparency

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Temporary kill-switch for key-window reclaim during OAuth. Some iOS
  // versions present auth UI in window/controller types that are not matched
  // by class-name heuristics, which can otherwise lead to a blank OAuth page.
  private static var windowReclaimSuspendedUntil: Date?

  static func setWindowReclaimSuspended(for duration: TimeInterval) {
    let clamped = max(1, duration)
    windowReclaimSuspendedUntil = Date().addingTimeInterval(clamped)
  }

  static func clearWindowReclaimSuspension() {
    windowReclaimSuspendedUntil = nil
  }

  private static var isWindowReclaimSuspended: Bool {
    guard let until = windowReclaimSuspendedUntil else { return false }
    if until > Date() {
      return true
    }
    windowReclaimSuspendedUntil = nil
    return false
  }

  private func configureFirebaseIfNeeded() {
    guard FirebaseApp.app() == nil else { return }
    guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return }
    FirebaseApp.configure()
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureFirebaseIfNeeded()

    // Required for flutter_local_notifications to show notifications in foreground
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Guard against any SDK (e.g. google_mobile_ads 7.x / UserMessagingPlatform)
    // that calls makeKeyAndVisible() on its own UIWindow during plugin
    // registration or early SDK setup. On iOS 14+ this steals key-window
    // status from Flutter, which prevents FlutterTextInputView from becoming
    // first responder — causing TextFormField taps to silently do nothing
    // (no keyboard appears). We detect the theft and immediately restore the
    // Flutter window as key window.
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onWindowBecameKey(_:)),
      name: UIWindow.didBecomeKeyNotification,
      object: nil
    )

    return result
  }

  @objc private func onWindowBecameKey(_ notification: Notification) {
    guard let newKey = notification.object as? UIWindow else { return }

    // If Flutter's own window became key, nothing to do.
    if let fw = SceneDelegate.flutterWindow, newKey === fw { return }
    if UIApplication.shared.applicationState != .active { return }
    if AppDelegate.isWindowReclaimSuspended { return }
    if shouldIgnoreWindowReclaim(for: newKey) { return }

    // A non-Flutter window became key. Restore Flutter's window after a
    // brief yield so any SDK transition can complete first.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      if self?.shouldIgnoreWindowReclaim(for: newKey) == true { return }
      // Try cached reference first; fall back to searching connected scenes
      // (handles the case where SceneDelegate.flutterWindow is nil because
      // the observer fires during super.scene() before our override sets it).
      let flutterWin = SceneDelegate.flutterWindow ?? self?.findFlutterWindow()
      flutterWin?.makeKeyAndVisible()
    }
  }

  /// Searches connected window scenes for the window whose root view
  /// controller hierarchy contains a FlutterViewController.
  private func findFlutterWindow() -> UIWindow? {
    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first { self.containsFlutterVC($0.rootViewController) }
  }

  private func containsFlutterVC(_ vc: UIViewController?) -> Bool {
    guard let vc = vc else { return false }
    if vc is FlutterViewController { return true }
    if containsFlutterVC(vc.presentedViewController) { return true }
    return vc.children.contains { containsFlutterVC($0) }
  }

  // System OAuth UIs (ASWebAuthenticationSession / SafariServices) must keep
  // their own key window while the user signs in. Reclaiming the window there
  // can produce an empty OAuth page.
  private func shouldIgnoreWindowReclaim(for window: UIWindow) -> Bool {
    return containsSystemAuthVC(window.rootViewController)
  }

  private func containsSystemAuthVC(_ vc: UIViewController?) -> Bool {
    guard let vc = vc else { return false }

    let className = String(describing: type(of: vc)).lowercased()
    let bundleId = Bundle(for: type(of: vc)).bundleIdentifier?.lowercased() ?? ""
    let isSystemAuthClass =
      className.contains("sfauthentication") ||
      className.contains("aswebauthentication") ||
      className.contains("sfsafari") ||
      className.contains("safari")
    let isSystemAuthBundle =
      bundleId.contains("safariservices") ||
      bundleId.contains("authenticationservices")

    if isSystemAuthClass || isSystemAuthBundle {
      return true
    }

    if containsSystemAuthVC(vc.presentedViewController) { return true }
    return vc.children.contains { containsSystemAuthVC($0) }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    configureFirebaseIfNeeded()
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // NOTE: The keyboard-fix and ATT MethodChannels are set up in
    // SceneDelegate (not here) because engineBridge.pluginRegistry
    // .registrar(forPlugin:) returns nil for ad-hoc plugin keys in the
    // implicit-engine pattern.
  }

  // Fallback URL handler for non-scene apps or when scene-based handling is bypassed.
  // Ensures app_links (used by supabase_flutter) can process deep links.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }
}
